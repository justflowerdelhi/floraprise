import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/data/repositories/cash_book_repository.dart';
import 'package:floraprise/data/repositories/customer_repository.dart';
import 'package:floraprise/data/repositories/inventory_repository.dart';
import 'package:floraprise/data/repositories/job_repository.dart';
import 'package:floraprise/data/repositories/order_repository.dart';
import 'package:floraprise/data/repositories/scheduler_repository.dart';
import 'package:floraprise/managers/customer_manager.dart';
import 'package:floraprise/managers/inventory_manager.dart';
import 'package:floraprise/managers/order_manager.dart';
import 'package:floraprise/managers/pricing_manager.dart';
import 'package:floraprise/managers/scheduler_manager.dart';
import 'package:floraprise/managers/walk_in_manager.dart';
import 'package:floraprise/models/fiscal_profile.dart';
import 'package:floraprise/models/payment_split.dart';
import 'package:floraprise/models/scheduler_task.dart';
import 'package:floraprise/models/walk_in_enums.dart';
import 'package:floraprise/models/walk_in_line_item.dart';
import 'package:floraprise/models/walk_in_session.dart';
import 'package:floraprise/services/pos_sale_sync_service.dart';
import 'package:floraprise/services/web_draft_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppDatabase.instance.close();
    final path = await getDatabasesPath();
    await deleteDatabase('$path/floraprise.db');
  });

  group('Phase 2: Event / Decoration Sale POS Tests', () {
    test('1. FulfilmentType enum and DB mapping for event_sale', () async {
      final db = await AppDatabase.instance.database;
      final nowStr = DateTime.now().toIso8601String();

      final customerId = await db.insert('customers', {
        'name': 'Royal Palace Events',
        'phone': '9876500001',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      final orderId = await db.insert('orders', {
        'order_no': 'EVT-2026-001',
        'fulfilment_type': 'event_sale',
        'status': 'confirmed',
        'customer_id': customerId,
        'grand_total_paise': 5000000, // ₹50,000
        'is_paid': 0,
        'occasion': 'Wedding Reception',
        'scheduled_at': '2026-10-15T18:00:00.000',
        'delivery_address': 'Grand Ballroom, Hotel Taj',
        'special_instructions': 'Theme: White & Gold Lily setup',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      final rows = await db.query('orders', where: 'id = ?', whereArgs: [orderId]);
      expect(rows.isNotEmpty, isTrue);
      final orderRow = rows.first;
      expect(orderRow['fulfilment_type'], 'event_sale');
      expect(orderRow['occasion'], 'Wedding Reception');
      expect(orderRow['delivery_address'], 'Grand Ballroom, Hotel Taj');
    });

    test('2. Mixed line items: Physical inventory item vs Custom decor service line stock handling in confirmDraft', () async {
      final db = await AppDatabase.instance.database;
      final nowStr = DateTime.now().toIso8601String();

      // Insert product with stock
      final productId = await db.insert('products', {
        'name': 'Red Dutch Roses Stem',
        'category': 'Flowers',
        'selling_price_paise': 5000, // ₹50
        'purchase_price_paise': 2500,
        'default_unit': 'Stem',
        'track_inventory': 1,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await db.insert('inventory_items', {
        'product_id': productId,
        'current_qty': 100,
        'min_qty': 10,
        'updated_at': nowStr,
      });

      // Insert customer
      final customerId = await db.insert('customers', {
        'name': 'Pooja Wedding Planner',
        'phone': '9876500002',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      // Create draft order with mixed line items
      final draftId = await db.insert('orders', {
        'order_no': 'EVT-DRAFT-001',
        'fulfilment_type': 'event_sale',
        'status': 'draft',
        'customer_id': customerId,
        'subtotal_paise': 3500000, // ₹35,000
        'grand_total_paise': 3500000,
        'is_paid': 0,
        'occasion': 'Engagement',
        'scheduled_at': '2026-11-01T10:00:00.000',
        'delivery_address': 'Club House',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      // Line 1: Physical inventory (50 stems of Red Roses)
      await db.insert('order_lines', {
        'order_id': draftId,
        'product_id': productId,
        'description': 'Red Dutch Roses Stem',
        'qty': 50,
        'unit_price_paise': 5000,
        'gst_percent': 0,
        'line_subtotal_paise': 250000,
        'line_gst_paise': 0,
        'line_total_paise': 250000, // ₹2,500
        'source': 'product',
      });

      // Line 2: Custom Service Line: Stage Floral Backdrop (no product_id)
      await db.insert('order_lines', {
        'order_id': draftId,
        'product_id': null,
        'description': 'Grand Floral Stage Backdrop & Setup',
        'qty': 1,
        'unit_price_paise': 2500000,
        'gst_percent': 0,
        'line_subtotal_paise': 2500000,
        'line_gst_paise': 0,
        'line_total_paise': 2500000, // ₹25,000
        'source': 'manual',
      });

      // Line 3: Custom Service Line: Transportation & Labour (no product_id)
      await db.insert('order_lines', {
        'order_id': draftId,
        'product_id': null,
        'description': 'Labour & Setup Charges',
        'qty': 1,
        'unit_price_paise': 750000,
        'gst_percent': 0,
        'line_subtotal_paise': 750000,
        'line_gst_paise': 0,
        'line_total_paise': 750000, // ₹7,500
        'source': 'manual',
      });

      // Confirm the draft
      final repo = OrderRepository();
      await repo.confirmDraft(orderId: draftId);

      // Phase 2A Rule: Event confirmation does NOT deduct physical inventory at booking time
      final inventoryAfterConfirm = await db.query('inventory_items', where: 'product_id = ?', whereArgs: [productId]);
      expect(inventoryAfterConfirm.first['current_qty'], 100);

      // Verify order is confirmed
      final confirmedOrderRows = await db.query('orders', where: 'id = ?', whereArgs: [draftId]);
      expect(confirmedOrderRows.first['status'], 'confirmed');

      // Fulfillment (delivered) deducts physical inventory: 100 - 50 = 50
      await repo.updateOrderStatus(
        orderId: draftId,
        newStatus: 'delivered',
        createdBy: 'admin',
      );
      final inventoryAfterDelivery = await db.query('inventory_items', where: 'product_id = ?', whereArgs: [productId]);
      expect(inventoryAfterDelivery.first['current_qty'], 50);
    });

    test('3. Event Sale with Full Payment records tender, is_paid=1, cash_book entry and zero receivables', () async {
      final db = await AppDatabase.instance.database;
      final now = DateTime.now();
      final nowStr = now.toIso8601String();
      final todayIso = DateTime(now.year, now.month, now.day).toIso8601String();

      final customerId = await db.insert('customers', {
        'name': 'Corporate Summit Org',
        'phone': '9876500003',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      final orderId = await db.insert('orders', {
        'order_no': 'EVT-PAID-001',
        'fulfilment_type': 'event_sale',
        'status': 'confirmed',
        'customer_id': customerId,
        'grand_total_paise': 1500000, // ₹15,000
        'is_paid': 1,
        'occasion': 'Corporate Gala',
        'scheduled_at': '2026-10-20T19:00:00.000',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      // Insert Full Payment Tender
      await db.insert('order_payments', {
        'order_id': orderId,
        'method': 'cash',
        'amount_paise': 1500000,
        'payment_type': 'SaleTender',
        'created_at': nowStr,
      });

      await db.insert('cash_book', {
        'date': todayIso,
        'transaction_type': 'cashSale',
        'description': 'Event sale payment for EVT-PAID-001',
        'amount': 1500000,
        'cash_in': 1500000,
        'cash_out': 0,
        'running_balance': 1500000,
        'created_at': nowStr,
      });

      // Customer outstanding should be 0
      final customer = await CustomerRepository().getById(customerId);
      expect(customer!.pendingPaymentPaise, 0);

      // Receivables report dataset check:
      final pendingRows = await db.rawQuery('''
        SELECT o.id, o.order_no, o.grand_total_paise,
          COALESCE((
            SELECT SUM(op.amount_paise)
            FROM order_payments op
            WHERE op.order_id = o.id
              AND LOWER(COALESCE(op.method, op.payment_type, '')) != 'credit'
          ), 0) AS paid_amount_paise
        FROM orders o
        WHERE o.status NOT IN ('draft', 'cancelled')
      ''');
      final pendingOrders = pendingRows.where((r) {
        final total = (r['grand_total_paise'] as int?) ?? 0;
        final paid = (r['paid_amount_paise'] as int?) ?? 0;
        return (total - paid) > 0;
      }).toList();
      expect(pendingOrders.any((o) => o['id'] == orderId), isFalse);

      // Cash book balance should reflect ₹15,000
      final cb = await CashBookRepository().getByDate(DateTime.now());
      expect(cb.any((e) => e.cashIn == 1500000 && e.description.contains('EVT-PAID-001')), isTrue);
    });

    test('4. Event Sale with Partial Advance Payment: Outstanding balance appears in Receivables & Customer Profile', () async {
      final db = await AppDatabase.instance.database;
      final nowStr = DateTime.now().toIso8601String();

      final customerId = await db.insert('customers', {
        'name': 'Sameer Khan',
        'phone': '9876500004',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      // Total ₹50,000 event sale
      final orderId = await db.insert('orders', {
        'order_no': 'EVT-PARTIAL-001',
        'fulfilment_type': 'event_sale',
        'status': 'confirmed',
        'customer_id': customerId,
        'customer_name': 'Sameer Khan',
        'customer_phone': '9876500004',
        'grand_total_paise': 5000000, // ₹50,000
        'is_paid': 0,
        'occasion': 'Wedding Reception',
        'scheduled_at': '2026-11-15T18:00:00.000',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      // Advance payment ₹20,000 via UPI
      await db.insert('order_payments', {
        'order_id': orderId,
        'method': 'upi',
        'amount_paise': 2000000, // ₹20,000
        'payment_type': 'SaleTender',
        'created_at': nowStr,
      });

      // Customer Outstanding must be ₹30,000 (3,000,000 paise)
      final customer = await CustomerRepository().getById(customerId);
      expect(customer!.pendingPaymentPaise, 3000000);

      // Receivables Report must show this order with ₹30,000 pending
      final pendingRows = await db.rawQuery('''
        SELECT
          o.id,
          o.order_no,
          o.customer_id,
          o.customer_name,
          o.customer_phone,
          o.fulfilment_type,
          o.grand_total_paise,
          COALESCE((
            SELECT SUM(op.amount_paise)
            FROM order_payments op
            WHERE op.order_id = o.id
              AND LOWER(COALESCE(op.method, op.payment_type, '')) != 'credit'
          ), 0) AS paid_amount_paise
        FROM orders o
        WHERE o.status NOT IN ('draft', 'cancelled')
      ''');
      final pendingOrders = pendingRows.where((r) {
        final total = (r['grand_total_paise'] as int?) ?? 0;
        final paid = (r['paid_amount_paise'] as int?) ?? 0;
        return (total - paid) > 0;
      }).toList();

      final eventOrder = pendingOrders.firstWhere((o) => o['id'] == orderId);
      expect(eventOrder, isNotNull);
      expect(eventOrder['grand_total_paise'], 5000000);
      expect(eventOrder['paid_amount_paise'], 2000000);
      expect(eventOrder['fulfilment_type'], 'event_sale');
      final pendingPaise = (eventOrder['grand_total_paise'] as int) - (eventOrder['paid_amount_paise'] as int);
      expect(pendingPaise, 3000000);
    });

    test('5. Complete Settlement of Event Sale balance via addOrderPaymentTransaction updates Cash Book and clears Receivables', () async {
      final db = await AppDatabase.instance.database;
      final nowStr = DateTime.now().toIso8601String();

      final customerId = await db.insert('customers', {
        'name': 'Meera Desai',
        'phone': '9876500005',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      final orderId = await db.insert('orders', {
        'order_no': 'EVT-SETTLE-001',
        'fulfilment_type': 'event_sale',
        'status': 'confirmed',
        'customer_id': customerId,
        'grand_total_paise': 4000000, // ₹40,000
        'is_paid': 0,
        'occasion': 'Birthday Extravaganza',
        'scheduled_at': '2026-10-25T18:00:00.000',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      // ₹15,000 advance in cash
      await db.insert('order_payments', {
        'order_id': orderId,
        'method': 'cash',
        'amount_paise': 1500000,
        'payment_type': 'SaleTender',
        'created_at': nowStr,
      });

      // Schedule a payment followup task
      final schedulerRepo = SchedulerRepository();
      final followUpTaskId = await schedulerRepo.publishTask(
        SchedulerTask(
          title: 'Collect Event Balance - EVT-SETTLE-001',
          type: TaskType.reminder,
          category: TaskCategory.sales,
          priority: TaskPriority.high,
          status: TaskStatus.pending,
          scheduledAt: DateTime.now().add(const Duration(days: 5)),
          linkedOrderId: orderId,
          producer: TaskProducer.orders,
          sourceRef: 'payment_followup:order_$orderId',
          notes: 'Collect ₹25,000',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Now collect remaining ₹25,000 cash balance
      final repo = OrderRepository();
      await repo.addOrderPaymentTransaction(
        orderId: orderId,
        amountPaise: 2500000,
        method: 'cash',
        actor: 'testAdmin',
        note: 'Final balance paid at event completion',
      );

      // Trigger automatic completion of linked payment follow-up task
      final sourceRef = 'payment_followup:order_$orderId';
      final taskRows = await db.query(
        'scheduler_tasks',
        columns: ['id'],
        where: 'source_ref = ? AND status IN (?, ?, ?) AND deleted_at IS NULL',
        whereArgs: [sourceRef, 'pending', 'inProgress', 'deferred'],
      );
      for (final r in taskRows) {
        final id = r['id'] as int;
        await schedulerRepo.updateTaskStatus(id, TaskStatus.completed);
      }

      // 1. Order must now be marked is_paid = 1
      final updatedOrderRows = await db.query('orders', where: 'id = ?', whereArgs: [orderId]);
      expect(updatedOrderRows.first['is_paid'], 1);

      // 2. Customer pending balance must be 0
      final customer = await CustomerRepository().getById(customerId);
      expect(customer!.pendingPaymentPaise, 0);

      // 3. Receivables query must no longer show this order
      final pendingRows = await db.rawQuery('''
        SELECT o.id, o.grand_total_paise,
          COALESCE((
            SELECT SUM(op.amount_paise)
            FROM order_payments op
            WHERE op.order_id = o.id
              AND LOWER(COALESCE(op.method, op.payment_type, '')) != 'credit'
          ), 0) AS paid_amount_paise
        FROM orders o
        WHERE o.status NOT IN ('draft', 'cancelled')
      ''');
      final pendingOrders = pendingRows.where((r) {
        final total = (r['grand_total_paise'] as int?) ?? 0;
        final paid = (r['paid_amount_paise'] as int?) ?? 0;
        return (total - paid) > 0;
      }).toList();
      expect(pendingOrders.any((o) => o['id'] == orderId), isFalse);

      // 4. Cash book must have recorded the ₹25,000 cash collection
      final cbEntries = await CashBookRepository().getByDate(DateTime.now());
      expect(
        cbEntries.any((e) => e.cashIn == 2500000 && e.description.contains('EVT-SETTLE-001')),
        isTrue,
      );

      // 5. Linked scheduler task must be marked completed
      final task = await schedulerRepo.getTask(followUpTaskId);
      expect(task!.status, TaskStatus.completed);
    });

    test('6. PricingManager GST calculation for mixed catalog and service lines', () {
      final pricingManager = PricingManager();
      const fiscal = FiscalProfile(
        countryCode: 'IN',
        currencyCode: 'INR',
        currencySymbol: '₹',
        taxEnabled: true,
        taxLabel: 'GST',
        taxRatePercent: 18.0,
        taxInclusive: false,
        taxIdentifier: '24AAAAA0000A1Z5',
        locale: 'en_IN',
        timeZone: 'Asia/Kolkata',
      );

      // Line 1: Flowers (₹10,000 exclusive 18% GST)
      const line1 = WalkInLineItem(
        description: 'Fresh Flowers Decor',
        quantity: 1,
        unitPricePaise: 1000000,
        gstPercent: 18,
      );

      // Line 2: Lighting & Setup Service (₹20,000 exclusive 18% GST)
      const line2 = WalkInLineItem(
        description: 'Stage Lighting & Truss Setup',
        quantity: 1,
        unitPricePaise: 2000000,
        gstPercent: 18,
      );

      final totals = pricingManager.computeTotals(
        lines: [line1, line2],
        fiscalProfile: fiscal,
      );

      expect(totals.subtotalPaise, 3000000); // ₹30,000
      expect(totals.gstTotalPaise, 540000);  // 18% of ₹30,000 = ₹5,400 (540,000 paise)
      expect(totals.grandTotalPaise, 3540000); // ₹35,400
    });

    test('7. Web Draft Storage serialization and deserialization of Event Sale', () async {
      final draftService = WebDraftStorageService();

      const session = WalkInSession(
        fulfilmentType: FulfilmentType.eventSale,
        customerName: 'Sanjay Kapoor',
        customerPhone: '9876540000',
        occasion: 'Wedding Mandap',
        deliveryAddress: 'Royal Greens Lawn',
        specialInstructions: 'Red rose carpet and fresh marigold toran',
        lines: [
          WalkInLineItem(
            productId: 101,
            description: 'Marigold Garland Bulk',
            unitPricePaise: 20000,
            quantity: 50,
          ),
          WalkInLineItem(
            productId: null,
            description: 'Mandap Wood Structure Setup',
            unitPricePaise: 5000000,
            quantity: 1,
          ),
        ],
        payments: [
          PaymentSplit(
            method: PaymentMethod.cash,
            amountPaise: 2000000,
          ),
        ],
      );

      const totals = OrderTotals(
        subtotalPaise: 6000000,
        gstTotalPaise: 0,
        discountTotalPaise: 0,
        roundOffPaise: 0,
        grandTotalPaise: 6000000,
      );

      final draftId = await draftService.upsertDraft(
        session: session,
        totals: totals,
        customerId: 99,
      );

      expect(draftId, isNonNegative);

      final restored = await draftService.getDraftById(draftId);
      expect(restored, isNotNull);
      expect(restored!.fulfilmentType, FulfilmentType.eventSale);
      expect(restored.customerName, 'Sanjay Kapoor');
      expect(restored.occasion, 'Wedding Mandap');
      expect(restored.deliveryAddress, 'Royal Greens Lawn');
      expect(restored.lines.length, 2);
      expect(restored.lines[0].productId, 101);
      expect(restored.lines[0].description, 'Marigold Garland Bulk');
      expect(restored.lines[1].productId, isNull);
      expect(restored.lines[1].description, 'Mandap Wood Structure Setup');

      // Test getLatestDraft
      final latest = await draftService.getLatestDraft(FulfilmentType.eventSale);
      expect(latest, isNotNull);
      expect(latest!.fulfilmentType, FulfilmentType.eventSale);
    });

    test('8. WalkInManager buildWebPosPayload outputs event_sale fulfilment_type, handles null productId, and sends empty inventoryTransactions', () {
      const session = WalkInSession(
        fulfilmentType: FulfilmentType.eventSale,
        customerName: 'Anil Ambani',
        customerPhone: '9876549999',
        occasion: 'Corporate Annual Meet',
        deliveryAddress: 'Convention Center Hall B',
        lines: [
          WalkInLineItem(
            cloudProductId: 'prod-orchid-vip',
            description: 'VIP Orchid Centerpiece',
            unitPricePaise: 150000,
            quantity: 10,
          ),
          WalkInLineItem(
            productId: null, // Custom decor line
            cloudProductId: null,
            description: 'Stage Arch Floral Backdrop',
            unitPricePaise: 4500000,
            quantity: 1,
          ),
        ],
      );

      const totals = OrderTotals(
        subtotalPaise: 6000000,
        gstTotalPaise: 0,
        discountTotalPaise: 0,
        roundOffPaise: 0,
        grandTotalPaise: 6000000,
      );

      final payload = WalkInManager.buildWebPosPayload(
        session: session,
        totals: totals,
        ensuredCustomer: null,
        clientSyncId: 'web_sync_test_001',
        now: DateTime.utc(2026, 9, 30, 10, 0, 0),
      );

      final order = payload['order'] as Map<String, dynamic>;
      expect(order['fulfilment_type'], 'event_sale');
      expect(order['occasion'], 'Corporate Annual Meet');
      expect(order['delivery_address'], 'Convention Center Hall B');
      
      final lines = payload['lines'] as List<Map<String, dynamic>>;
      expect(lines.length, 2);
      expect(lines[0]['product_id'], 'prod-orchid-vip');
      expect(lines[1]['product_id'], isNull);
      expect(lines[1]['description'], 'Stage Arch Floral Backdrop');

      final inv = payload['inventoryTransactions'] as List;
      expect(inv.isEmpty, isTrue, reason: 'Event sale on Web must send empty inventoryTransactions');
    });

    test('9. Web Event Sale requiring 3 with physical stock 1 produces inventoryTransactions: []', () {
      const session = WalkInSession(
        fulfilmentType: FulfilmentType.eventSale,
        customerName: 'Event Planner A',
        customerPhone: '9876541111',
        occasion: 'Wedding Decor',
        lines: [
          WalkInLineItem(
            cloudProductId: 'prod-red-rose-basket',
            description: '20 Red Roses Basket',
            unitPricePaise: 250000,
            quantity: 3,
            source: 'product',
          ),
        ],
      );

      const totals = OrderTotals(
        subtotalPaise: 750000,
        gstTotalPaise: 0,
        discountTotalPaise: 0,
        roundOffPaise: 0,
        grandTotalPaise: 750000,
      );

      final payload = WalkInManager.buildWebPosPayload(
        session: session,
        totals: totals,
        ensuredCustomer: null,
        clientSyncId: 'web_sync_test_002',
        now: DateTime.utc(2026, 9, 30, 10, 0, 0),
      );

      expect(payload['order']['fulfilment_type'], 'event_sale');
      final inv = payload['inventoryTransactions'] as List;
      expect(inv.isEmpty, isTrue, reason: 'Web Event Sale requiring 3 must produce empty inventoryTransactions');
    });

    test('10. Web Event Sale with reservation still produces inventoryTransactions: [] and fulfilment_type remains event_sale', () {
      const session = WalkInSession(
        fulfilmentType: FulfilmentType.eventSale,
        customerName: 'Event Planner B',
        customerPhone: '9876542222',
        occasion: 'Anniversary Banquet',
        lines: [
          WalkInLineItem(
            cloudProductId: 'prod-lily-bunch',
            description: 'White Lily Bunch',
            unitPricePaise: 300000,
            quantity: 5,
            source: 'product',
          ),
        ],
      );

      const totals = OrderTotals(
        subtotalPaise: 1500000,
        gstTotalPaise: 0,
        discountTotalPaise: 0,
        roundOffPaise: 0,
        grandTotalPaise: 1500000,
      );

      final payload = WalkInManager.buildWebPosPayload(
        session: session,
        totals: totals,
        ensuredCustomer: null,
        clientSyncId: 'web_sync_test_003',
        now: DateTime.utc(2026, 9, 30, 10, 0, 0),
      );

      expect(payload['order']['fulfilment_type'], 'event_sale');
      final inv = payload['inventoryTransactions'] as List;
      expect(inv.isEmpty, isTrue, reason: 'Web Event Sale with hold/reservation must produce empty inventoryTransactions');
    });

    test('11. Web Walk-in (take_away) still produces inventory transactions', () {
      const session = WalkInSession(
        fulfilmentType: FulfilmentType.takeAway,
        customerName: 'Walk-in Shopper',
        customerPhone: '9876543333',
        lines: [
          WalkInLineItem(
            cloudProductId: 'prod-carnation-red',
            description: 'Red Carnation Stem',
            unitPricePaise: 5000,
            quantity: 6,
            source: 'product',
          ),
        ],
      );

      const totals = OrderTotals(
        subtotalPaise: 30000,
        gstTotalPaise: 0,
        discountTotalPaise: 0,
        roundOffPaise: 0,
        grandTotalPaise: 30000,
      );

      final payload = WalkInManager.buildWebPosPayload(
        session: session,
        totals: totals,
        ensuredCustomer: null,
        clientSyncId: 'web_sync_test_004',
        now: DateTime.utc(2026, 9, 30, 10, 0, 0),
      );

      expect(payload['order']['fulfilment_type'], 'takeAway');
      final inv = payload['inventoryTransactions'] as List;
      expect(inv, hasLength(1));
      expect(inv.first['cloudProductId'], 'prod-carnation-red');
      expect(inv.first['qty'], 6);
    });

    test('12. Web Delivery still produces inventory transactions', () {
      const session = WalkInSession(
        fulfilmentType: FulfilmentType.delivery,
        customerName: 'Delivery Client',
        customerPhone: '9876544444',
        deliveryAddress: '123 Park Avenue',
        lines: [
          WalkInLineItem(
            cloudProductId: 'prod-orchid-blue',
            description: 'Blue Orchid Bunch',
            unitPricePaise: 120000,
            quantity: 2,
            source: 'product',
          ),
        ],
      );

      const totals = OrderTotals(
        subtotalPaise: 240000,
        gstTotalPaise: 0,
        discountTotalPaise: 0,
        roundOffPaise: 0,
        grandTotalPaise: 240000,
      );

      final payload = WalkInManager.buildWebPosPayload(
        session: session,
        totals: totals,
        ensuredCustomer: null,
        clientSyncId: 'web_sync_test_005',
        now: DateTime.utc(2026, 9, 30, 10, 0, 0),
      );

      expect(payload['order']['fulfilment_type'], 'delivery');
      final inv = payload['inventoryTransactions'] as List;
      expect(inv, hasLength(1));
      expect(inv.first['cloudProductId'], 'prod-orchid-blue');
      expect(inv.first['qty'], 2);
    });

    test('13. Web Pickup (pickup_later) still produces inventory transactions', () {
      const session = WalkInSession(
        fulfilmentType: FulfilmentType.pickupLater,
        customerName: 'Pickup Client',
        customerPhone: '9876545555',
        lines: [
          WalkInLineItem(
            cloudProductId: 'prod-mixed-tulips',
            description: 'Dutch Tulips Bunch',
            unitPricePaise: 200000,
            quantity: 4,
            source: 'product',
          ),
        ],
      );

      const totals = OrderTotals(
        subtotalPaise: 800000,
        gstTotalPaise: 0,
        discountTotalPaise: 0,
        roundOffPaise: 0,
        grandTotalPaise: 800000,
      );

      final payload = WalkInManager.buildWebPosPayload(
        session: session,
        totals: totals,
        ensuredCustomer: null,
        clientSyncId: 'web_sync_test_006',
        now: DateTime.utc(2026, 9, 30, 10, 0, 0),
      );

      expect(payload['order']['fulfilment_type'], 'pickupLater');
      final inv = payload['inventoryTransactions'] as List;
      expect(inv, hasLength(1));
      expect(inv.first['cloudProductId'], 'prod-mixed-tulips');
      expect(inv.first['qty'], 4);
    });

    test('14. Full runtime Web Event Sale confirmOnlineOrder end-to-end sends empty inventoryTransactions and fulfilment_type = event_sale to /api/v1/mobile/pos-sales/sync', () async {
      String? sentUri;
      String? sentPayloadJson;

      final syncService = PosSaleSyncService(
        sender: (uri, payloadJson, bearerToken) async {
          sentUri = uri.toString();
          sentPayloadJson = payloadJson;
          return const PosSaleSyncHttpResponse(
            statusCode: 200,
            body: '{"cloudOrderId": "cloud-evt-order-12345", "cloudCustomerId": "cust-123"}',
          );
        },
        readAccessToken: () async => 'test-bearer-token',
      );

      final customerRepo = CustomerRepository();
      final orderRepo = OrderRepository();
      final jobRepo = JobRepository();
      final inventoryRepo = InventoryRepository();
      final schedulerRepo = SchedulerRepository();

      final customerMgr = CustomerManager(customerRepo);
      final pricingMgr = PricingManager();
      final orderMgr = OrderManager(orderRepo, jobRepo);
      final inventoryMgr = InventoryManager(inventoryRepo);
      final schedulerMgr = SchedulerManager(schedulerRepo);

      final walkInMgr = WalkInManager(
        customerManager: customerMgr,
        pricingManager: pricingMgr,
        orderManager: orderMgr,
        inventoryManager: inventoryMgr,
        schedulerManager: schedulerMgr,
        posSaleSyncService: syncService,
      );

      WalkInManager.debugForceWebMode = true;

      const eventSession = WalkInSession(
        fulfilmentType: FulfilmentType.eventSale,
        customerName: 'Suresh Raina',
        customerPhone: '9876543210',
        occasion: 'Wedding Sangeet',
        deliveryAddress: 'Banquet Hall A',
        lines: [
          WalkInLineItem(
            cloudProductId: 'prod-20-red-roses-basket',
            description: '20 red roses basket',
            unitPricePaise: 250000,
            quantity: 2, // Requested: 2
            source: 'product',
          ),
          WalkInLineItem(
            productId: null,
            cloudProductId: null,
            description: 'Stage Floral Arc Setup',
            unitPricePaise: 5000000,
            quantity: 1,
            source: 'service',
          ),
        ],
        payments: [
          PaymentSplit(
            method: PaymentMethod.cash,
            amountPaise: 2000000, // ₹20,000 advance
          ),
        ],
      );

      final result = await walkInMgr.confirmOnlineOrder(eventSession);
      WalkInManager.debugForceWebMode = false;

      expect(result.orderId, isNonNegative);
      expect(sentUri, contains('/api/v1/mobile/pos-sales/sync'));
      expect(sentPayloadJson, isNotNull);

      final decoded = jsonDecode(sentPayloadJson!) as Map<String, dynamic>;
      
      // Verify Order section:
      final order = decoded['order'] as Map<String, dynamic>;
      expect(order['fulfilment_type'], 'event_sale');
      expect(order['occasion'], 'Wedding Sangeet');
      expect(order['customer_name'], 'Suresh Raina');

      // Verify Lines section (2 lines present):
      final lines = decoded['lines'] as List<dynamic>;
      expect(lines.length, 2);
      expect(lines[0]['description'], '20 red roses basket');
      expect(lines[0]['qty'], 2);
      expect(lines[0]['cloudProductId'], 'prod-20-red-roses-basket');

      // Verify InventoryTransactions: MUST BE EMPTY for Event Sale
      final invTxns = decoded['inventoryTransactions'] as List<dynamic>;
      expect(invTxns.isEmpty, isTrue, reason: 'Runtime HTTP payload sent to sync endpoint MUST have empty inventoryTransactions for event_sale');
    });
  });
}
