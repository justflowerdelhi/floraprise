import 'package:floraprise/data/repositories/associate_repository.dart';
import 'package:floraprise/l10n/app_localizations.dart';
import 'package:floraprise/managers/order_manager.dart';
import 'package:floraprise/managers/order_workflow_manager.dart';
import 'package:floraprise/models/order_workspace_models.dart';
import 'package:floraprise/providers/order_provider.dart';
import 'package:floraprise/providers/order_workflow_provider.dart';
import 'package:floraprise/screens/order_detail_screen.dart';
import 'package:floraprise/screens/order_view_screen.dart';
import 'package:floraprise/screens/orders_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeOrderManager extends Fake implements OrderManager {
  final OrderDetailHeader header;
  final OrderDetailBundle bundle;
  final List<OrderListItem> ordersList;

  _FakeOrderManager({
    required this.header,
    required this.bundle,
    required this.ordersList,
  });

  @override
  Future<List<OrderListItem>> getOrdersForWorkspace({
    required String tab,
    String searchQuery = '',
    OrderWorkspaceFilters filters = OrderWorkspaceFilters.empty,
  }) async =>
      ordersList;

  @override
  Future<OrderDetailHeader?> getOrderDetailHeader(int orderId) async => header;

  @override
  Future<OrderDetailBundle?> getOrderDetailBundle(int orderId) async => bundle;
}

class _FakeOrderWorkflowManager extends Fake implements OrderWorkflowManager {
  @override
  Future<List<AssociateRecord>> getAssignableAssociates({bool? isCloud}) async => const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  final testHeader = OrderDetailHeader(
    id: 101,
    cloudOrderId: null,
    orderNo: 'ORD-POS-101',
    status: 'confirmed',
    customerName: 'Aarav Sharma',
    customerPhone: '9876543210',
    customerEmail: 'aarav@example.com',
    recipientName: 'Priya Verma',
    recipientPhone: '9123456789',
    fulfilmentType: 'delivery',
    source: 'walkIn',
    grandTotalPaise: 250000, // ₹2,500
    subtotalPaise: 240000,
    discountTotalPaise: 20000,
    gstTotalPaise: 15000,
    deliveryChargesPaise: 15000,
    roundOffPaise: 0,
    address: '123 MG Road, Bengaluru',
    deliveryLandmark: 'Opposite Metro Station',
    deliveryPincode: '560001',
    specialInstructions: 'Ring bell twice and leave with security',
    createdAt: DateTime(2026, 9, 20, 10, 30),
    scheduledAt: DateTime(2026, 9, 20, 16, 0),
    occasion: 'Anniversary',
    deliverySlot: '4:00 PM - 6:00 PM',
    cardMessage: 'Happy 5th Anniversary my love!',
    internalNotes: 'VIP customer, use fresh red roses',
    isPaid: 0,
    paidAmountPaise: 150000, // ₹1,500 paid, ₹1,000 outstanding
    rewardPointsEarned: 50,
    rewardPointsRedeemed: 20,
    rewardDiscountAmountPaise: 2000,
    designerName: 'Sunita (Florist)',
    deliveryName: 'Ramesh (Driver)',
  );

  final testBundle = OrderDetailBundle(
    header: testHeader,
    lines: [
      {
        'id': 1,
        'product_name': 'Luxury Red Rose Bouquet (24 Stems)',
        'description': 'Luxury Red Rose Bouquet (24 Stems)',
        'product_sku': 'FLR-ROSE-24',
        'qty': 1,
        'unit_price_paise': 180000,
        'discount_paise': 10000,
        'gst_percent': 12,
        'line_gst_paise': 20400,
        'line_subtotal_paise': 170000,
        'line_total_paise': 190400,
        'special_instructions': 'Add satin gold ribbon',
      },
      {
        'id': 2,
        'product_name': 'Ferrero Rocher Box (16 pcs)',
        'description': 'Ferrero Rocher Box (16 pcs)',
        'product_sku': 'CHOC-FR-16',
        'qty': 2,
        'unit_price_paise': 35000,
        'discount_paise': 5000,
        'gst_percent': 18,
        'line_gst_paise': 11700,
        'line_subtotal_paise': 65000,
        'line_total_paise': 76700,
        'special_instructions': null,
      },
    ],
    payments: [
      {
        'method': 'UPI',
        'amount_paise': 100000,
        'reference': 'UPI-REF-99214',
        'created_at': '2026-09-20T10:35:00',
      },
      {
        'method': 'Cash',
        'amount_paise': 50000,
        'reference': null,
        'created_at': '2026-09-20T10:36:00',
      },
    ],
    timeline: [],
    schedulerTasks: [],
    inventoryTransactions: [],
    receiptStatus: null,
    whatsappStatus: null,
    relayInfo: {},
    corporateInfo: {},
    marketplaceInfo: {},
  );

  final testOrderListItem = OrderListItem(
    id: 101,
    cloudOrderId: null,
    orderNo: 'ORD-POS-101',
    status: 'confirmed',
    customerName: 'Aarav Sharma',
    customerPhone: '9876543210',
    recipientName: 'Priya Verma',
    fulfilmentType: 'delivery',
    source: 'walkIn',
    grandTotalPaise: 250000,
    isPaid: 0,
    createdAt: DateTime(2026, 9, 20, 10, 30),
    scheduledAt: DateTime(2026, 9, 20, 16, 0),
    designerName: 'Sunita (Florist)',
    deliveryName: 'Ramesh (Driver)',
  );

  Widget createTestWidget({required Widget child}) {
    final fakeOrderManager = _FakeOrderManager(
      header: testHeader,
      bundle: testBundle,
      ordersList: [testOrderListItem],
    );
    final fakeWorkflowManager = _FakeOrderWorkflowManager();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<OrderProvider>(
          create: (_) => OrderProvider(fakeOrderManager),
        ),
        ChangeNotifierProvider<OrderWorkflowProvider>(
          create: (_) => OrderWorkflowProvider(fakeWorkflowManager),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: child,
        onGenerateRoute: (settings) {
          final uri = Uri.tryParse(settings.name ?? '');
          final path = uri?.path ?? settings.name ?? '';

          if (path == '/order-view') {
            final orderId = int.tryParse(uri?.queryParameters['orderId'] ?? '101') ?? 101;
            final cloudOrderId = uri?.queryParameters['cloudOrderId'];
            return MaterialPageRoute(
              builder: (_) => OrderViewScreen(orderId: orderId, cloudOrderId: cloudOrderId),
            );
          }

          if (path == '/order-detail') {
            final orderId = int.tryParse(uri?.queryParameters['orderId'] ?? '101') ?? 101;
            final cloudOrderId = uri?.queryParameters['cloudOrderId'];
            return MaterialPageRoute(
              builder: (_) => OrderDetailScreen(orderId: orderId, cloudOrderId: cloudOrderId),
            );
          }

          return null;
        },
      ),
    );
  }

  group('Order Action Menu & View Order Workflow Verification', () {
    testWidgets('Tapping order card in OrdersScreen opens Order Action Menu',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));

      await tester.pumpWidget(createTestWidget(child: const OrdersScreen()));
      await tester.pumpAndSettle();

      // Verify order is rendered
      expect(find.text('ORD-POS-101'), findsOneWidget);
      expect(find.text('Priya Verma'), findsOneWidget);

      // Tap order card
      await tester.tap(find.text('ORD-POS-101'));
      await tester.pumpAndSettle();

      // Verify Order Action Menu bottom sheet appears with actions
      expect(find.text('View Order'), findsOneWidget);
      expect(find.text('Edit Order'), findsOneWidget);
      expect(find.text('Change Status'), findsOneWidget);
      expect(find.text('Collect Payment'), findsOneWidget);
      expect(find.text('Print'), findsOneWidget);
      expect(find.text('WhatsApp / Share'), findsOneWidget);
      expect(find.text('Assign Designer'), findsOneWidget);
      expect(find.text('Assign Driver'), findsOneWidget);
      expect(find.text('Track Delivery'), findsOneWidget);
      expect(find.text('Cancel Order'), findsOneWidget);
    });

    testWidgets('Tapping View Order opens clean OrderViewScreen with complete submitted order details',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));

      await tester.pumpWidget(createTestWidget(child: const OrdersScreen()));
      await tester.pumpAndSettle();

      // Open Action Menu
      await tester.tap(find.text('ORD-POS-101'));
      await tester.pumpAndSettle();

      // Tap View Order
      await tester.tap(find.text('View Order'));
      await tester.pumpAndSettle();

      // Verify OrderViewScreen is displayed
      expect(find.byType(OrderViewScreen), findsOneWidget);

      // Verify Header & Customer / Recipient
      expect(find.text('ORD-POS-101'), findsWidgets);
      expect(find.text('Priya Verma'), findsOneWidget);
      expect(find.text('Aarav Sharma'), findsOneWidget);
      expect(find.text('9876543210'), findsOneWidget);
      expect(find.text('123 MG Road, Bengaluru'), findsOneWidget);
      expect(find.text('Anniversary'), findsOneWidget);

      // Verify Items
      expect(find.text('Luxury Red Rose Bouquet (24 Stems)'), findsOneWidget);
      expect(find.text('Ferrero Rocher Box (16 pcs)'), findsOneWidget);
      expect(find.text('SKU: FLR-ROSE-24'), findsOneWidget);
      expect(find.text('SKU: CHOC-FR-16'), findsOneWidget);

      // Verify Financial Summary
      expect(find.text('Grand Total'), findsOneWidget);
      expect(find.text('₹2500'), findsWidgets);
      expect(find.text('₹1500'), findsWidgets); // Paid
      expect(find.text('₹1000'), findsWidgets); // Balance

      // Verify Payments
      expect(find.text('UPI'), findsOneWidget);
      expect(find.text('CASH'), findsOneWidget);
      expect(find.text('Ref: UPI-REF-99214'), findsOneWidget);

      // Verify Message Card & Instructions
      expect(find.text('"Happy 5th Anniversary my love!"'), findsOneWidget);
      expect(find.text('Ring bell twice and leave with security'), findsOneWidget);

      // Verify Staff Assignments
      expect(find.text('Sunita (Florist)'), findsOneWidget);
      expect(find.text('Ramesh (Driver)'), findsOneWidget);

      // Confirm ERP debug noise is NOT present
      expect(find.text('Marketplace Information'), findsNothing);
      expect(find.text('Linkages & Sync Status'), findsNothing);
      expect(find.text('Scheduler Tasks'), findsNothing);
    });

    testWidgets('OrderViewScreen AppBar actions button invokes the Order Action Menu',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));

      await tester.pumpWidget(
        createTestWidget(child: const OrderViewScreen(orderId: 101)),
      );
      await tester.pumpAndSettle();

      // Find AppBar actions button
      final actionButton = find.byTooltip('Order Actions');
      expect(actionButton, findsOneWidget);

      // Tap actions button
      await tester.tap(actionButton);
      await tester.pumpAndSettle();

      // Verify same action menu opens
      expect(find.text('View Order'), findsOneWidget);
      expect(find.text('Edit Order'), findsOneWidget);
      expect(find.text('Change Status'), findsOneWidget);
      expect(find.text('Collect Payment'), findsOneWidget);
      expect(find.text('Print'), findsOneWidget);
      expect(find.text('WhatsApp / Share'), findsOneWidget);
    });

    testWidgets('Direct deep-link /order-detail?orderId=101 continues to resolve OrderDetailScreen',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));

      await tester.pumpWidget(
        createTestWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/order-detail?orderId=101'),
              child: const Text('Open Full ERP Details'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Full ERP Details'));
      await tester.pumpAndSettle();

      expect(find.byType(OrderDetailScreen), findsOneWidget);
    });
  });
}
