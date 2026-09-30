import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/data/repositories/customer_repository.dart';
import 'package:floraprise/data/repositories/enquiry_repository.dart';
import 'package:floraprise/data/repositories/order_repository.dart';
import 'package:floraprise/managers/pricing_manager.dart';
import 'package:floraprise/managers/business_settings_manager.dart';
import 'package:floraprise/managers/walk_in_manager.dart';
import 'package:floraprise/models/crm_models.dart';
import 'package:floraprise/models/gst_calculation_type.dart';
import 'package:floraprise/models/walk_in_enums.dart';
import 'package:floraprise/models/walk_in_line_item.dart';
import 'package:floraprise/models/walk_in_session.dart';
import 'package:floraprise/providers/crm_provider.dart';
import 'package:floraprise/screens/crm/crm_enquiries_screen.dart';
import 'package:floraprise/screens/crm/crm_quote_compose_dialog.dart';
import 'package:floraprise/screens/crm/crm_quote_preview_dialog.dart';
import 'package:floraprise/services/crm_service.dart';
import 'package:floraprise/services/pdf/pdf_document_service.dart';
import 'package:floraprise/services/pdf/pdf_quotation_builder.dart';
import 'package:floraprise/services/web_draft_storage_service.dart';
import 'package:floraprise/utils/whatsapp_phone_utils.dart';

class _FakeQuoteCrmService extends CrmService {
  _FakeQuoteCrmService({
    this.draftSessions = const {},
    this.enquiries = const [],
  });

  final Map<int, WalkInSession> draftSessions;
  final List<CrmEnquiryItem> enquiries;

  @override
  Future<CrmTodayData> getTodayData(DateTime now) async {
    return CrmTodayData.empty;
  }

  @override
  Future<WalkInSession?> getQuoteDraft(int draftOrderId) async {
    return draftSessions[draftOrderId];
  }

  @override
  Future<int> convertQuoteToWonOrder({
    required CrmEnquiryItem enquiry,
    WalkInManager? walkInManager,
  }) async {
    return enquiry.quoteOrderId ?? 1;
  }

  @override
  Future<List<CrmEnquiryItem>> listEnquiries({
    String? status,
    String? query,
    DateTime? eventDate,
    int page = 1,
    int pageSize = 50,
  }) async {
    var result = List<CrmEnquiryItem>.from(enquiries);
    if (status != null && status != 'all') {
      result = result.where((e) => e.status.toLowerCase() == status.toLowerCase()).toList();
    }
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      result = result.where((e) =>
          e.customerName.toLowerCase().contains(q) ||
          e.customerPhone.toLowerCase().contains(q) ||
          e.requirement.toLowerCase().contains(q)).toList();
    }
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('CRM Phase 2B-1: Quote Model & Serialization', () {
    test('CrmEnquiryItem quoteOrderId serialization and copyWith', () {
      final now = DateTime.now();
      final enquiry = CrmEnquiryItem(
        localId: 1,
        clientSyncId: 'sync-quote-1',
        customerId: 10,
        customerName: 'Rahul Verma',
        customerPhone: '9876543210',
        category: 'Wedding',
        requirement: 'Floral Mandap and stage decoration',
        status: 'new',
        createdAt: now,
      );

      expect(enquiry.quoteOrderId, isNull);
      expect(enquiry.status, 'new');

      // Update to quote_sent with draft ID 105
      final quotedEnquiry = enquiry.copyWith(
        quoteOrderId: 105,
        status: 'quote_sent',
        updatedAt: now,
      );

      expect(quotedEnquiry.quoteOrderId, 105);
      expect(quotedEnquiry.status, 'quote_sent');

      // SQLite round-trip
      final sqliteMap = quotedEnquiry.toSqlite();
      expect(sqliteMap['quote_order_id'], 105);
      expect(sqliteMap['status'], 'quote_sent');

      final fromDb = CrmEnquiryItem.fromSqlite(sqliteMap);
      expect(fromDb.quoteOrderId, 105);
      expect(fromDb.status, 'quote_sent');

      // Cloud JSON round-trip
      final cloudJson = quotedEnquiry.toCloudJson();
      expect(cloudJson['status'], 'quote_sent');

      final fromCloud = CrmEnquiryItem.fromCloudJson({
        'id': 'cloud-enq-1',
        'clientSyncId': 'sync-quote-1',
        'customerName': 'Rahul Verma',
        'customerPhone': '9876543210',
        'requirement': 'Mandap',
        'status': 'quote_sent',
        'quoteOrderId': 105,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });
      expect(fromCloud.quoteOrderId, 105);
      expect(fromCloud.status, 'quote_sent');
    });
  });

  group('CRM Phase 2B-1: SQLite Draft Order Persistence & Zero Inventory Impact', () {
    late AppDatabase appDb;
    late OrderRepository orderRepository;
    late EnquiryRepository enquiryRepository;

    setUp(() async {
      AppDatabase.useInMemoryForTests = true;
      AppDatabase.testDatabaseName =
          'test_crm_quote_${DateTime.now().microsecondsSinceEpoch}.db';
      appDb = AppDatabase.instance;
      await appDb.close();

      orderRepository = OrderRepository();
      enquiryRepository = EnquiryRepository();
    });

    tearDown(() async {
      await appDb.close();
      AppDatabase.useInMemoryForTests = false;
    });

    test('Creating a quote draft saves order with status=draft and does NOT create inventory transactions', () async {
      final db = await appDb.database;

      // 1. Seed Customer
      final custId = await db.insert('customers', {
        'name': 'Pooja Agarwal',
        'phone': '9811122233',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // 2. Seed Product
      final prodId = await db.insert('products', {
        'code': 'ROSE-RED',
        'name': 'Dutch Red Roses Bunch',
        'category': 'Roses',
        'default_unit': 'Bunch',
        'selling_price_paise': 45000,
        'gst_percent': 5,
        'gst_calculation_type': 'exclusive',
        'sku': 'SKU-ROSE-1',
        'manufacturer_barcode': '890111',
        'floraprise_barcode': 'FLP111',
        'active': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // 3. Compose Quote Session
      final lines = [
        WalkInLineItem(
          productId: prodId,
          description: 'Dutch Red Roses Bunch',
          quantity: 2,
          unitPricePaise: 45000, // ₹450 each = ₹900 subtotal
          gstPercent: 5,
          gstCalculationType: GstCalculationType.exclusive,
          source: 'catalog',
        ),
        const WalkInLineItem(
          description: 'Custom Stage Floral Arch Setup',
          quantity: 1,
          unitPricePaise: 350000, // ₹3,500
          gstPercent: 18,
          gstCalculationType: GstCalculationType.exclusive,
          source: 'manual',
        ),
      ];

      final pricingManager = PricingManager();
      final totals = pricingManager.computeTotals(lines: lines);

      final session = WalkInSession(
        fulfilmentType: FulfilmentType.delivery,
        lines: lines,
        customerPhone: '9811122233',
        customerName: 'Pooja Agarwal',
        occasion: 'Wedding',
        scheduledAt: DateTime(2026, 11, 20, 15, 0),
        deliveryAddress: 'Grand Palace Hall, Bangalore',
        specialInstructions: 'Setup must be ready by 2 PM',
      );

      // 4. Save Draft
      final draftId = await orderRepository.upsertDraft(
        session: session,
        totals: totals,
        customerId: custId,
      );

      expect(draftId, greaterThan(0));

      // 5. Verify orders table
      final orderRows = await db.query('orders', where: 'id = ?', whereArgs: [draftId]);
      expect(orderRows.length, 1);
      final savedOrder = orderRows.first;
      expect(savedOrder['status'], 'draft');
      expect(savedOrder['customer_id'], custId);
      expect(savedOrder['customer_name'], 'Pooja Agarwal');
      expect(savedOrder['customer_phone'], '9811122233');
      expect(savedOrder['fulfilment_type'], 'delivery');
      expect(savedOrder['delivery_address'], 'Grand Palace Hall, Bangalore');
      expect(savedOrder['grand_total_paise'], totals.grandTotalPaise);

      // 6. Verify order_lines table
      final lineRows = await db.query('order_lines', where: 'order_id = ?', whereArgs: [draftId]);
      expect(lineRows.length, 2);
      expect(lineRows[0]['description'], 'Dutch Red Roses Bunch');
      expect(lineRows[0]['qty'], 2);
      expect(lineRows[1]['description'], 'Custom Stage Floral Arch Setup');
      expect(lineRows[1]['qty'], 1);

      // 7. Verify ZERO inventory transactions
      final invRows = await db.query('inventory_transactions');
      expect(invRows.isEmpty, isTrue, reason: 'Quotation drafts must NEVER deduct or reserve inventory.');

      // 8. Test idempotent editing: Update the existing draft in-place
      final updatedLines = [
        lines[0].copyWith(quantity: 3), // Change quantity from 2 to 3
        lines[1],
      ];
      final updatedTotals = pricingManager.computeTotals(lines: updatedLines);
      final updatedSession = session.copyWith(
        draftOrderId: draftId,
        lines: updatedLines,
      );

      final updatedDraftId = await orderRepository.upsertDraft(
        session: updatedSession,
        totals: updatedTotals,
        customerId: custId,
      );

      expect(updatedDraftId, draftId, reason: 'Updating draft must preserve the same draft ID');

      final totalOrdersCount = Sqflite.firstIntValue(
        await db.rawQuery("SELECT COUNT(*) FROM orders WHERE status = 'draft'"),
      );
      expect(totalOrdersCount, 1, reason: 'Must not create duplicate draft orders');

      final reloadedLines = await db.query('order_lines', where: 'order_id = ?', whereArgs: [draftId]);
      expect(reloadedLines.length, 2);
      expect(reloadedLines[0]['qty'], 3);
    });

    test('Full CRM Provider enquiry -> quote draft lifecycle', () async {
      final db = await appDb.database;

      // 1. Seed Customer
      final custId = await db.insert('customers', {
        'name': 'Ananya Roy',
        'phone': '9900112233',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // 2. Create Enquiry in SQLite
      final enquiry = await enquiryRepository.create(
        CrmEnquiryItem(
          clientSyncId: 'sync-ananya-enq',
          customerId: custId,
          customerName: 'Ananya Roy',
          customerPhone: '9900112233',
          category: 'Anniversary',
          requirement: '50 Red Roses and Orchids Bouquet',
          eventDate: DateTime(2026, 10, 25),
          budgetPaise: 400000,
          status: 'new',
          createdAt: DateTime.now(),
        ),
      );

      expect(enquiry.localId, isNotNull);
      expect(enquiry.quoteOrderId, isNull);
      expect(enquiry.status, 'new');

      // 3. Setup CrmService & CrmProvider
      final crmService = CrmService(
        enquiryRepository: enquiryRepository,
        orderRepository: orderRepository,
      );
      final crmProvider = CrmProvider(
        crmService: crmService,
        customerRepository: CustomerRepository(),
      );

      await crmProvider.loadEnquiries();
      expect(crmProvider.enquiriesList.length, 1);

      // 4. Compose and Save Quote Draft via CrmProvider
      final lines = [
        const WalkInLineItem(
          description: '50 Red Roses & Orchids Premium Bouquet',
          quantity: 1,
          unitPricePaise: 380000,
          gstPercent: 5,
          gstCalculationType: GstCalculationType.exclusive,
          source: 'manual',
        ),
      ];
      final totals = PricingManager().computeTotals(lines: lines);
      final session = WalkInSession(
        fulfilmentType: FulfilmentType.pickupLater,
        lines: lines,
        customerPhone: enquiry.customerPhone,
        customerName: enquiry.customerName,
        occasion: enquiry.category,
        scheduledAt: enquiry.eventDate,
        specialInstructions: enquiry.requirement,
      );

      final draftId = await crmProvider.saveQuoteDraftForEnquiry(
        enquiry: enquiry,
        session: session,
        totals: totals,
      );

      expect(draftId, greaterThan(0));

      // 5. Verify Enquiry in Provider and Database
      await crmProvider.loadEnquiries();
      final updatedEnq = crmProvider.enquiriesList.firstWhere((e) => e.localId == enquiry.localId);
      expect(updatedEnq.quoteOrderId, draftId);
      expect(updatedEnq.status, 'quote_sent');

      // 6. Verify Quote Draft retrieval
      final loadedSession = await crmProvider.loadQuoteDraft(draftId);
      expect(loadedSession, isNotNull);
      expect(loadedSession!.draftOrderId, draftId);
      expect(loadedSession.customerName, 'Ananya Roy');
      expect(loadedSession.lines.length, 1);
      expect(loadedSession.lines.first.description, '50 Red Roses & Orchids Premium Bouquet');
      expect(loadedSession.lines.first.unitPricePaise, 380000);
    });
  });

  group('CRM Phase 2B-1: Web Draft Storage Compatibility', () {
    test('WebDraftStorageService upserts and retrieves quote draft correctly', () async {
      SharedPreferences.setMockInitialValues({});
      final webStorage = WebDraftStorageService();

      final lines = [
        const WalkInLineItem(
          description: 'Sunflower & Lily Centerpiece',
          quantity: 2,
          unitPricePaise: 150000,
          gstPercent: 12,
          gstCalculationType: GstCalculationType.inclusive,
          source: 'manual',
        ),
      ];

      final totals = PricingManager().computeTotals(lines: lines);
      final session = WalkInSession(
        fulfilmentType: FulfilmentType.delivery,
        lines: lines,
        customerPhone: '9888877777',
        customerName: 'Meera Nair',
        occasion: 'Corporate Dinner',
        deliveryAddress: 'Tech Park, Whitefield',
      );

      final draftId = await webStorage.upsertDraft(
        session: session,
        totals: totals,
        customerId: 5,
        cloudCustomerId: 'cloud-cust-55',
      );

      expect(draftId, greaterThan(0));

      final retrieved = await webStorage.getDraftById(draftId);
      expect(retrieved, isNotNull);
      expect(retrieved!.draftOrderId, draftId);
      expect(retrieved.customerName, 'Meera Nair');
      expect(retrieved.customerPhone, '9888877777');
      expect(retrieved.deliveryAddress, 'Tech Park, Whitefield');
      expect(retrieved.lines.length, 1);
      expect(retrieved.lines.first.description, 'Sunflower & Lily Centerpiece');
      expect(retrieved.lines.first.quantity, 2);

      // Verify updating web draft in place
      final updatedSession = retrieved.copyWith(
        specialInstructions: 'Deliver by 6 PM sharp',
      );

      final updatedDraftId = await webStorage.upsertDraft(
        session: updatedSession,
        totals: totals,
        customerId: 5,
      );

      expect(updatedDraftId, draftId);
      final reloaded = await webStorage.getDraftById(draftId);
      expect(reloaded!.specialInstructions, 'Deliver by 6 PM sharp');

      final count = await webStorage.countDraftOrders();
      expect(count, 1);
    });
  });

  group('CRM Phase 2B-1: Compose Dialog Widget Tests', () {
    testWidgets('CrmQuoteComposeDialog renders enquiry info, adds custom items, computes totals', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({});

      final enquiry = CrmEnquiryItem(
        localId: 5,
        clientSyncId: 'sync-widget-test',
        customerId: 2,
        customerName: 'Kavita Sundaram',
        customerPhone: '9777788888',
        category: 'Birthday',
        requirement: 'Carnations and Ferrero Rocher bouquet',
        eventDate: DateTime(2026, 12, 1),
        budgetPaise: 200000,
        location: 'Koramangala, Bangalore',
        notes: 'Include gold ribbon',
        status: 'new',
        createdAt: DateTime.now(),
      );

      final crmProvider = CrmProvider(
        crmService: CrmService(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<CrmProvider>.value(
            value: crmProvider,
            child: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => CrmQuoteComposeDialog.show(context, enquiry: enquiry),
                  child: const Text('Open Quote Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Quote Dialog'));
      await tester.pumpAndSettle();

      // Verify header and enquiry details
      expect(find.text('Create Quotation'), findsOneWidget);
      expect(find.textContaining('Kavita Sundaram'), findsWidgets);
      expect(find.textContaining('9777788888'), findsWidgets);
      expect(find.text('Birthday'), findsOneWidget);
      expect(find.textContaining('Carnations and Ferrero Rocher bouquet'), findsWidgets);

      // Verify empty state initially
      expect(find.text('No Items in Quotation'), findsOneWidget);

      // Attempt to save with 0 items -> should show error
      await tester.tap(find.text('Save Quote Draft'));
      await tester.pumpAndSettle();
      expect(find.text('Please add at least one line item to create a quote.'), findsOneWidget);

      // Add Custom Item
      await tester.tap(find.text('Custom Item'));
      await tester.pumpAndSettle();

      expect(find.text('Add Custom Item / Service'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'Item / Service Description *'),
        'Carnations & Chocolate Deluxe Bouquet',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Unit Price (₹) *'),
        '1800',
      );
      await tester.tap(find.text('Add Line Item'));
      await tester.pumpAndSettle();

      // Verify line item added
      expect(find.text('Carnations & Chocolate Deluxe Bouquet'), findsOneWidget);
      expect(find.text('₹1800.00'), findsWidgets);
      expect(find.text('Grand Total: ₹1800.00'), findsOneWidget);
    });
  });

  group('CRM Phase 2B-2: A4 Quotation PDF Generation', () {
    test('PdfQuotationBuilder produces valid PDF document with header, items, totals, and 7-day validity', () async {
      const builder = PdfQuotationBuilder();
      const business = BusinessSettings(
        shopName: 'Blossom Florist',
        ownerName: 'Priya Sharma',
        address: 'MG Road, Bangalore',
        phone: '9876500000',
        gstRegistered: true,
        gstNumber: '29ABCDE1234F1Z5',
        defaultDeliveryChargePaise: 0,
        minimumPreparationBufferMinutes: 30,
      );

      final enquiry = CrmEnquiryItem(
        localId: 12,
        clientSyncId: 'sync-pdf-test-1',
        customerId: 3,
        customerName: 'Ananya Sharma',
        customerPhone: '9876543210',
        category: 'Corporate Event',
        requirement: 'Stage backdrop decoration and floral centerpieces',
        eventDate: DateTime(2026, 11, 20),
        budgetPaise: 5000000,
        location: 'Taj West End, Bangalore',
        status: 'quote_sent',
        quoteOrderId: 108,
        createdAt: DateTime(2026, 11, 10, 10, 0),
        updatedAt: DateTime(2026, 11, 10, 10, 0),
      );

      const session = WalkInSession(
        draftOrderId: 108,
        fulfilmentType: FulfilmentType.delivery,
        specialInstructions: 'Setup required by 3 PM',
        lines: [
          WalkInLineItem(
            description: 'Grand Stage Backdrop Floral Arc',
            quantity: 1,
            unitPricePaise: 3500000, // ₹35,000
            gstPercent: 18,
            gstCalculationType: GstCalculationType.exclusive,
          ),
          WalkInLineItem(
            description: 'Table Centerpiece - Exotic Orchids',
            quantity: 10,
            unitPricePaise: 150000, // ₹1,500 each = ₹15,000
            discountPaise: 10000, // ₹100 discount per item = ₹1,000 total discount
            gstPercent: 18,
            gstCalculationType: GstCalculationType.exclusive,
          ),
        ],
      );

      final totals = PricingManager().computeTotals(lines: session.lines);

      final quotationDate = DateTime(2026, 11, 10);
      final validUntilDate = quotationDate.add(const Duration(days: 7));

      final bytes = await builder.build(
        business: business,
        enquiry: enquiry,
        session: session,
        totals: totals,
        quotationDate: quotationDate,
        validUntilDate: validUntilDate,
      );

      // Verify PDF byte header '%PDF-'
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(500));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('PdfDocumentService.generateQuotationPdf generates non-empty PDF bytes', () async {
      SharedPreferences.setMockInitialValues({});
      final service = PdfDocumentService();

      final enquiry = CrmEnquiryItem(
        localId: 1,
        clientSyncId: 'sync-doc-svc',
        customerId: 1,
        customerName: 'Meera Patel',
        customerPhone: '9822233344',
        category: 'Birthday',
        requirement: 'Rose bouquet',
        status: 'quote_sent',
        quoteOrderId: 55,
        createdAt: DateTime.now(),
      );

      const session = WalkInSession(
        draftOrderId: 55,
        fulfilmentType: FulfilmentType.takeAway,
        lines: [
          WalkInLineItem(
            description: 'Red Rose Bouquet',
            quantity: 1,
            unitPricePaise: 120000,
          ),
        ],
      );

      final totals = PricingManager().computeTotals(lines: session.lines);

      final bytes = await service.generateQuotationPdf(
        enquiry: enquiry,
        session: session,
        totals: totals,
      );

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });

  group('CRM Phase 2B-2: WhatsApp Quotation Message Formatting', () {
    test('WhatsApp message contains all required quotation fields and valid link', () {
      final enquiry = CrmEnquiryItem(
        localId: 8,
        clientSyncId: 'sync-wa-test',
        customerId: 4,
        customerName: 'Vikram Mehta',
        customerPhone: '9845012345',
        category: 'Anniversary',
        requirement: 'Heart shape red roses arrangement with fairy lights',
        status: 'quote_sent',
        quoteOrderId: 112,
        createdAt: DateTime(2026, 10, 1),
        updatedAt: DateTime(2026, 10, 1),
      );

      const amountPaise = 450000; // ₹4,500.00
      final amountStr = (amountPaise / 100).toStringAsFixed(2);
      final quoteRef = 'QUO-${enquiry.quoteOrderId}';
      final validUntil = enquiry.updatedAt.add(const Duration(days: 7));
      final validUntilStr = DateFormat('dd MMM yyyy').format(validUntil);
      const shopName = 'Floraprise Luxe';

      final message = 'Hello ${enquiry.customerName},\n\n'
          'Please find your quotation for ${enquiry.category} (${enquiry.requirement}):\n\n'
          '💰 Quotation Amount: ₹$amountStr\n'
          '📄 Quotation Ref: $quoteRef\n'
          '📅 Valid Until: $validUntilStr\n\n'
          'Thank you,\n'
          '$shopName';

      expect(message, contains('Vikram Mehta'));
      expect(message, contains('Anniversary'));
      expect(message, contains('Heart shape red roses'));
      expect(message, contains('₹4500.00'));
      expect(message, contains('QUO-112'));
      expect(message, contains('08 Oct 2026'));
      expect(message, contains('Floraprise Luxe'));

      final uri = WhatsAppPhoneUtils.buildUri(enquiry.customerPhone, message: message);
      expect(uri, isNotNull);
      expect(uri!.scheme, 'https');
      expect(uri.host, 'wa.me');
      expect(uri.path, '/919845012345');
      expect(uri.queryParameters['text'], contains('Vikram Mehta'));
      expect(uri.queryParameters['text'], contains('QUO-112'));
    });
  });

  group('CRM Phase 2B-2: Quotation Preview Dialog Widget Tests', () {
    testWidgets('CrmQuotePreviewDialog displays draft quotation summary and action buttons', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({});

      const draftSession = WalkInSession(
        draftOrderId: 101,
        fulfilmentType: FulfilmentType.takeAway,
        customerName: 'Sneha Kulkarni',
        customerPhone: '9880011223',
        specialInstructions: 'Wrap in luxury black craft paper',
        lines: [
          WalkInLineItem(
            description: 'Premium White Lilies Bunch',
            quantity: 2,
            unitPricePaise: 80000, // ₹800 each = ₹1600
          ),
          WalkInLineItem(
            description: 'Ferrero Rocher Box 16pcs',
            quantity: 1,
            unitPricePaise: 65000, // ₹650
          ),
        ],
      );

      final enquiry = CrmEnquiryItem(
        localId: 25,
        clientSyncId: 'sync-preview-widget',
        customerId: 10,
        customerName: 'Sneha Kulkarni',
        customerPhone: '9880011223',
        category: 'Housewarming',
        requirement: 'Fresh lily arrangements and chocolates',
        status: 'quote_sent',
        quoteOrderId: 101,
        createdAt: DateTime(2026, 10, 5),
        updatedAt: DateTime(2026, 10, 5),
      );

      final fakeService = _FakeQuoteCrmService(
        draftSessions: {101: draftSession},
        enquiries: [enquiry],
      );
      final crmProvider = CrmProvider(crmService: fakeService);

      await tester.pumpWidget(
        ChangeNotifierProvider<CrmProvider>.value(
          value: crmProvider,
          child: MaterialApp(
            home: Scaffold(
              body: CrmQuotePreviewDialog(enquiry: enquiry),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify preview header
      expect(find.textContaining('Quotation QUO-101'), findsOneWidget);
      expect(find.textContaining('Sneha Kulkarni'), findsWidgets);
      expect(find.textContaining('9880011223'), findsWidgets);

      // Verify enquiry & validity banner
      expect(find.textContaining('Housewarming — Fresh lily arrangements and chocolates'), findsOneWidget);
      expect(find.textContaining('Valid for 7 days until'), findsOneWidget);

      // Verify items
      expect(find.text('Premium White Lilies Bunch'), findsOneWidget);
      expect(find.text('Ferrero Rocher Box 16pcs'), findsOneWidget);

      // Verify totals: 1600 + 650 = 2250
      expect(find.text('₹2250.00'), findsWidgets);

      // Verify action buttons
      expect(find.text('Download PDF'), findsOneWidget);
      expect(find.text('Share WhatsApp'), findsOneWidget);
      expect(find.text('Edit Quote'), findsOneWidget);
      expect(find.text('Mark Won & Convert'), findsOneWidget);
    });
  });

  group('CRM Phase 2B-3: Won Conversion - SQLite Solo POS Order & Inventory Impact', () {
    late AppDatabase appDb;
    late OrderRepository orderRepository;
    late EnquiryRepository enquiryRepository;
    late CustomerRepository customerRepository;
    late CrmService crmService;
    late CrmProvider crmProvider;

    setUp(() async {
      AppDatabase.useInMemoryForTests = true;
      AppDatabase.testDatabaseName =
          'test_crm_won_solo_${DateTime.now().microsecondsSinceEpoch}.db';
      appDb = AppDatabase.instance;
      await appDb.close();

      orderRepository = OrderRepository();
      enquiryRepository = EnquiryRepository();
      customerRepository = CustomerRepository();
      crmService = CrmService(
        enquiryRepository: enquiryRepository,
        orderRepository: orderRepository,
      );
      crmProvider = CrmProvider(
        crmService: crmService,
        customerRepository: customerRepository,
      );
    });

    tearDown(() async {
      await appDb.close();
      AppDatabase.useInMemoryForTests = false;
    });

    test('Mark Won converts quotation draft to real POS confirmed order with inventory deduction', () async {
      final db = await appDb.database;

      // 1. Seed Customer & Catalog Product
      final custId = await db.insert('customers', {
        'name': 'Ramesh Singhania',
        'phone': '9876500111',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      final prodId = await db.insert('products', {
        'code': 'ORCHID-PURPLE',
        'name': 'Purple Orchid Stems (Pack of 10)',
        'category': 'Orchids',
        'default_unit': 'Pack',
        'selling_price_paise': 80000,
        'gst_percent': 5,
        'gst_calculation_type': 'exclusive',
        'active': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // 2. Create Enquiry in CRM
      final enquiry = await crmProvider.createEnquiry(
        customerPhone: '9876500111',
        customerName: 'Ramesh Singhania',
        requirement: 'Reception stage purple orchid decor',
        category: 'Reception',
        budgetPaise: 500000,
      );

      expect(enquiry.status, 'new');
      expect(enquiry.quoteOrderId, isNull);
      expect(enquiry.convertedOrderId, isNull);

      // 3. Compose Quote Session (2 packs of orchids = ₹1600 + GST)
      final lines = [
        WalkInLineItem(
          productId: prodId,
          description: 'Purple Orchid Stems (Pack of 10)',
          quantity: 2,
          unitPricePaise: 80000,
          gstPercent: 5,
          gstCalculationType: GstCalculationType.exclusive,
          source: 'catalog',
        ),
      ];
      final totals = PricingManager().computeTotals(lines: lines);
      final draftSession = WalkInSession(
        customerName: 'Ramesh Singhania',
        customerPhone: '9876500111',
        fulfilmentType: FulfilmentType.delivery,
        deliveryAddress: 'Leela Palace Ballroom, Bangalore',
        lines: lines,
      );

      // 4. Save Quote Draft for Enquiry
      final draftId = await crmProvider.saveQuoteDraftForEnquiry(
        enquiry: enquiry,
        session: draftSession,
        totals: totals,
      );

      final reloadedEnquiry = (await enquiryRepository.getById(enquiry.localId!))!;
      expect(reloadedEnquiry.status, 'quote_sent');
      expect(reloadedEnquiry.quoteOrderId, draftId);
      expect(reloadedEnquiry.convertedOrderId, isNull);

      // Verify ZERO inventory transactions exist at quote time
      final preWonInvRows = await db.query('inventory_transactions');
      expect(preWonInvRows.length, 0, reason: 'Zero inventory deduction during quote draft');

      // Verify orders table status is draft
      final preWonOrderRows = await db.query('orders', where: 'id = ?', whereArgs: [draftId]);
      expect(preWonOrderRows.first['status'], 'draft');

      // 5. MARK WON & CONVERT
      final confirmedOrderId = await crmProvider.convertQuoteToWonOrder(
        enquiry: reloadedEnquiry,
      );

      expect(confirmedOrderId, draftId);

      // 6. Verify CRM Enquiry is now 'won' with convertedOrderId populated
      final wonEnquiry = (await enquiryRepository.getById(enquiry.localId!))!;
      expect(wonEnquiry.status, 'won');
      expect(wonEnquiry.quoteOrderId, draftId);
      expect(wonEnquiry.convertedOrderId, confirmedOrderId);
      expect(wonEnquiry.nextAction, contains('Order #ORD-$confirmedOrderId confirmed'));

      // 7. Verify real Floraprise POS order in 'orders' table is confirmed
      final postWonOrderRows = await db.query('orders', where: 'id = ?', whereArgs: [draftId]);
      expect(postWonOrderRows.length, 1);
      final confirmedOrder = postWonOrderRows.first;
      expect(confirmedOrder['status'], 'confirmed');
      expect(confirmedOrder['confirmed_at'], isNotNull);
      expect((confirmedOrder['order_no'] as String).startsWith('ORD-'), isTrue);
      expect(confirmedOrder['customer_id'], custId);
      expect(confirmedOrder['fulfilment_type'], 'delivery');
      expect(confirmedOrder['delivery_address'], 'Leela Palace Ballroom, Bangalore');

      // 8. Verify order_timeline_events has 'confirmed' event
      final timelineRows = await db.query(
        'order_timeline_events',
        where: 'order_id = ? AND status = ?',
        whereArgs: [confirmedOrderId, 'confirmed'],
      );
      expect(timelineRows.length, 1);

      // 9. Verify EXACTLY ONE inventory transaction created with correct product and quantity
      final postWonInvRows = await db.query('inventory_transactions');
      expect(postWonInvRows.length, 1, reason: 'Inventory deducted exactly once upon Won confirmation');
      final invTx = postWonInvRows.first;
      expect(invTx['product_id'], prodId);
      expect(invTx['order_id'], confirmedOrderId);
      expect(invTx['qty'], 2);
    });
  });

  group('CRM Phase 2B-3: Won Conversion - Idempotency & Reconciliation', () {
    late AppDatabase appDb;
    late OrderRepository orderRepository;
    late EnquiryRepository enquiryRepository;
    late CustomerRepository customerRepository;
    late CrmService crmService;
    late CrmProvider crmProvider;

    setUp(() async {
      AppDatabase.useInMemoryForTests = true;
      AppDatabase.testDatabaseName =
          'test_crm_won_idempotency_${DateTime.now().microsecondsSinceEpoch}.db';
      appDb = AppDatabase.instance;
      await appDb.close();

      orderRepository = OrderRepository();
      enquiryRepository = EnquiryRepository();
      customerRepository = CustomerRepository();
      crmService = CrmService(
        enquiryRepository: enquiryRepository,
        orderRepository: orderRepository,
      );
      crmProvider = CrmProvider(
        crmService: crmService,
        customerRepository: customerRepository,
      );
    });

    tearDown(() async {
      await appDb.close();
      AppDatabase.useInMemoryForTests = false;
    });

    test('Repeated convertQuoteToWonOrder calls are idempotent and return same orderId without duplicating deductions', () async {
      final db = await appDb.database;

      await db.insert('customers', {
        'name': 'Kavita Menon',
        'phone': '9770011223',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      final prodId = await db.insert('products', {
        'code': 'TULIP-YELLOW',
        'name': 'Yellow Tulips Bunch',
        'category': 'Tulips',
        'default_unit': 'Bunch',
        'selling_price_paise': 120000,
        'active': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      final enquiry = await crmProvider.createEnquiry(
        customerPhone: '9770011223',
        customerName: 'Kavita Menon',
        requirement: 'Tulips bunch for anniversary',
      );

      final lines = [
        WalkInLineItem(
          productId: prodId,
          description: 'Yellow Tulips Bunch',
          quantity: 1,
          unitPricePaise: 120000,
          source: 'catalog',
        ),
      ];
      final totals = PricingManager().computeTotals(lines: lines);
      const draftSession = WalkInSession(
        customerName: 'Kavita Menon',
        customerPhone: '9770011223',
        fulfilmentType: FulfilmentType.takeAway,
        lines: [
          WalkInLineItem(
            productId: 1,
            description: 'Yellow Tulips Bunch',
            quantity: 1,
            unitPricePaise: 120000,
            source: 'catalog',
          ),
        ],
      );

      final draftId = await crmProvider.saveQuoteDraftForEnquiry(
        enquiry: enquiry,
        session: draftSession.copyWith(
          lines: lines,
        ),
        totals: totals,
      );

      final quoteSentEnquiry = (await enquiryRepository.getById(enquiry.localId!))!;

      // First conversion
      final orderId1 = await crmProvider.convertQuoteToWonOrder(enquiry: quoteSentEnquiry);
      expect(orderId1, draftId);

      final wonEnquiry = (await enquiryRepository.getById(enquiry.localId!))!;
      expect(wonEnquiry.status, 'won');
      expect(wonEnquiry.convertedOrderId, draftId);

      // Second conversion on already won enquiry (duplicate button tap simulation)
      final orderId2 = await crmProvider.convertQuoteToWonOrder(enquiry: wonEnquiry);
      expect(orderId2, draftId);

      // Third conversion with quote_sent status object but draft already confirmed in database (reconciliation)
      final orderId3 = await crmProvider.convertQuoteToWonOrder(enquiry: quoteSentEnquiry);
      expect(orderId3, draftId);

      // Verify inventory transactions is still exactly 1
      final invRows = await db.query('inventory_transactions');
      expect(invRows.length, 1);
    });

    test('Throws StateError if enquiry has no quoteOrderId', () async {
      final enquiryWithoutQuote = CrmEnquiryItem(
        localId: 99,
        clientSyncId: 'no-quote-test',
        customerName: 'Test Customer',
        customerPhone: '9999999999',
        requirement: 'Inquiry without quote',
        status: 'new',
        quoteOrderId: null,
        createdAt: DateTime.now(),
      );

      expect(
        () => crmProvider.convertQuoteToWonOrder(enquiry: enquiryWithoutQuote),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('CRM Phase 2B-3: Won Conversion - Web Mode Draft Lifecycle', () {
    test('Web draft storage converts draft and updates CRM Enquiry', () async {
      SharedPreferences.setMockInitialValues({});
      final webStorage = WebDraftStorageService();

      const lines = [
        WalkInLineItem(
          description: 'Luxury Cymbidium Orchid Box',
          quantity: 1,
          unitPricePaise: 450000,
          gstPercent: 12,
          gstCalculationType: GstCalculationType.exclusive,
          source: 'manual',
        ),
      ];
      final totals = PricingManager().computeTotals(lines: lines);

      const session = WalkInSession(
        customerName: 'Deepak Chopra',
        customerPhone: '9833344455',
        fulfilmentType: FulfilmentType.pickupLater,
        specialInstructions: 'Ready by 5 PM for store pickup',
        lines: lines,
      );

      final draftId = await webStorage.upsertDraft(
        session: session,
        totals: totals,
        customerId: 101,
      );
      expect(draftId, greaterThan(0));

      final loadedDraft = await webStorage.getDraftById(draftId);
      expect(loadedDraft, isNotNull);
      expect(loadedDraft!.lines.first.description, 'Luxury Cymbidium Orchid Box');

      final enquiry = CrmEnquiryItem(
        clientSyncId: 'web-enq-sync-1',
        customerName: 'Deepak Chopra',
        customerPhone: '9833344455',
        requirement: 'Luxury Cymbidium Orchid Box',
        status: 'quote_sent',
        quoteOrderId: draftId,
        createdAt: DateTime.now(),
      );

      final wonEnquiry = enquiry.copyWith(
        status: 'won',
        convertedOrderId: draftId,
        nextAction: 'Order #ORD-$draftId confirmed',
      );

      expect(wonEnquiry.status, 'won');
      expect(wonEnquiry.convertedOrderId, draftId);
    });
  });

  group('CRM Phase 2B-3: UI Widget Tests - Mark Won & Convert and Order View', () {
    testWidgets('CrmQuotePreviewDialog Mark Won & Convert button triggers conversion and shows success SnackBar', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({});

      const draftSession = WalkInSession(
        draftOrderId: 102,
        fulfilmentType: FulfilmentType.takeAway,
        customerName: 'Gauri Shinde',
        customerPhone: '9820011223',
        lines: [
          WalkInLineItem(
            description: 'Pink Carnations Basket',
            quantity: 1,
            unitPricePaise: 95000,
          ),
        ],
      );

      final enquiry = CrmEnquiryItem(
        localId: 42,
        clientSyncId: 'sync-ui-won-test',
        customerId: 12,
        customerName: 'Gauri Shinde',
        customerPhone: '9820011223',
        category: 'Birthday',
        requirement: 'Pink Carnations Basket',
        status: 'quote_sent',
        quoteOrderId: 102,
        createdAt: DateTime(2026, 10, 10),
        updatedAt: DateTime(2026, 10, 10),
      );

      final fakeService = _FakeQuoteCrmService(
        draftSessions: {102: draftSession},
        enquiries: [enquiry],
      );
      final crmProvider = CrmProvider(crmService: fakeService);

      await tester.pumpWidget(
        ChangeNotifierProvider<CrmProvider>.value(
          value: crmProvider,
          child: MaterialApp(
            home: Scaffold(
              body: CrmQuotePreviewDialog(enquiry: enquiry),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify 'Mark Won & Convert' button is visible
      final markWonFinder = find.text('Mark Won & Convert');
      expect(markWonFinder, findsOneWidget);

      // Tap 'Mark Won & Convert'
      await tester.tap(markWonFinder);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify SnackBar appears with order confirmation and View Order action
      expect(find.textContaining('Order created successfully — Order #ORD-102'), findsOneWidget);
      expect(find.text('View Order'), findsOneWidget);
    });

    testWidgets('CrmEnquiriesScreen renders View Order button for Won enquiries', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({});

      final wonEnquiry = CrmEnquiryItem(
        localId: 88,
        clientSyncId: 'sync-won-screen-test',
        customerId: 15,
        customerName: 'Arjun Kapoor',
        customerPhone: '9819988776',
        category: 'Corporate',
        requirement: 'Weekly floral desk decor',
        status: 'won',
        quoteOrderId: 301,
        convertedOrderId: 301,
        createdAt: DateTime(2026, 10, 15),
        updatedAt: DateTime(2026, 10, 15),
      );

      final fakeService = _FakeQuoteCrmService(
        enquiries: [wonEnquiry],
      );
      final crmProvider = CrmProvider(crmService: fakeService);

      await tester.pumpWidget(
        ChangeNotifierProvider<CrmProvider>.value(
          value: crmProvider,
          child: const MaterialApp(
            home: CrmEnquiriesScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Verify customer and Won status chip
      expect(find.text('Arjun Kapoor'), findsOneWidget);
      expect(find.text('Won'), findsWidgets);

      // Verify metadata shows 'Order #ORD-301'
      expect(find.text('Order #ORD-301'), findsOneWidget);

      // Verify 'View Order (#ORD-301)' button is rendered
      expect(find.text('View Order (#ORD-301)'), findsOneWidget);

      // Verify 'Create Quote' is NOT shown for won enquiry
      expect(find.text('Create Quote'), findsNothing);
    });
  });
}

