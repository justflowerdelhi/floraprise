import 'package:floraprise/data/repositories/associate_repository.dart';
import 'package:floraprise/l10n/app_localizations.dart';
import 'package:floraprise/managers/order_manager.dart';
import 'package:floraprise/managers/order_workflow_manager.dart';
import 'package:floraprise/models/order_workspace_models.dart';
import 'package:floraprise/providers/order_provider.dart';
import 'package:floraprise/providers/order_workflow_provider.dart';
import 'package:floraprise/screens/order_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeOrderManager extends Fake implements OrderManager {
  final OrderDetailHeader header;
  final OrderDetailBundle bundle;

  _FakeOrderManager({required this.header, required this.bundle});

  @override
  Future<OrderDetailHeader?> getOrderDetailHeader(int orderId) async => header;

  @override
  Future<OrderDetailBundle?> getOrderDetailBundle(int orderId) async => bundle;

  Future<OrderDetailHeader?> getCloudOrderDetailHeader(String cloudOrderId) async => header;

  Future<OrderDetailBundle?> getCloudOrderDetailBundle(String cloudOrderId) async => bundle;
}

class _FakeOrderWorkflowManager extends Fake implements OrderWorkflowManager {
  Future<List<Map<String, Object?>>> getWorkflowTimeline(int orderId) async => const [];

  @override
  Future<List<AssociateRecord>> getAssignableAssociates({bool? isCloud}) async => const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
    grandTotalPaise: 250000, // ₹2,500.00
    subtotalPaise: 240000,
    discountTotalPaise: 20000,
    gstTotalPaise: 15000,
    deliveryChargesPaise: 15000,
    roundOffPaise: 0,
    address: '123 MG Road, Bengaluru',
    deliveryLandmark: 'Opposite Metro Station',
    deliveryPincode: '560001',
    specialInstructions: 'Ring bell twice and leave with security if unavailable',
    createdAt: DateTime(2026, 9, 20, 10, 30),
    scheduledAt: DateTime(2026, 9, 20, 16, 0),
    occasion: 'Anniversary',
    deliverySlot: '4:00 PM - 6:00 PM',
    cardMessage: 'Happy 5th Anniversary my love!',
    internalNotes: 'VIP customer, use fresh red roses',
    isPaid: 0,
    paidAmountPaise: 150000, // ₹1,500.00 paid, ₹1,000.00 outstanding
    rewardPointsEarned: 50,
    rewardPointsRedeemed: 20,
    rewardDiscountAmountPaise: 2000,
    designerName: 'Sunita (Lead Florist)',
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
        'special_instructions': 'Add satin gold ribbon and extra gypsophila filler',
        'product_image_path': null,
      },
      {
        'id': 2,
        'product_name': 'Ferrero Rocher Box (16 pcs)',
        'description': 'Ferrero Rocher Box (16 pcs)',
        'product_sku': 'CHOC-FR-16',
        'qty': 1,
        'unit_price_paise': 60000,
        'discount_paise': 0,
        'gst_percent': 18,
        'line_gst_paise': 10800,
        'line_subtotal_paise': 60000,
        'line_total_paise': 70800,
        'product_image_path': null,
      },
    ],
    payments: [
      {
        'id': 1,
        'method': 'UPI',
        'amount_paise': 100000, // ₹1,000 SaleTender at checkout
        'payment_type': 'SaleTender',
        'reference': 'UPI-REF-998811',
        'created_at': '2026-09-20T10:30:00Z',
      },
      {
        'id': 2,
        'method': 'Cash',
        'amount_paise': 50000, // ₹500 CreditCollection later
        'payment_type': 'CreditCollection',
        'reference': 'CASH-REC-01',
        'created_at': '2026-09-20T14:15:00Z',
      },
    ],
    timeline: [
      OrderTimelineItem(
        status: 'confirmed',
        notes: 'Order confirmed and inventory reserved',
        createdAt: DateTime(2026, 9, 20, 10, 30),
      ),
      OrderTimelineItem(
        status: 'preparing',
        notes: 'Designer started arrangement',
        createdAt: DateTime(2026, 9, 20, 11, 0),
      ),
    ],
    schedulerTasks: const [],
    inventoryTransactions: const [],
    receiptStatus: 'printed',
    whatsappStatus: 'sent',
    relayInfo: const {},
    corporateInfo: const {},
    marketplaceInfo: const {},
  );

  Widget createTestWidget({
    required OrderDetailHeader header,
    required OrderDetailBundle bundle,
    Size screenSize = const Size(390, 844),
  }) {
    final fakeOrderManager = _FakeOrderManager(header: header, bundle: bundle);
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
        home: MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: OrderDetailScreen(orderId: header.id),
        ),
      ),
    );
  }

  group('Enhanced Order Details Screen Widget Tests', () {
    testWidgets('renders complete order header with status, date, source and grand total', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1200));
      await tester.pumpWidget(createTestWidget(header: testHeader, bundle: testBundle));
      await tester.pumpAndSettle();

      // Header information
      expect(find.text('ORD-POS-101'), findsOneWidget);
      expect(find.textContaining('Placed on 20/9/2026'), findsOneWidget);
      expect(find.text('Confirmed'), findsWidgets);
      expect(find.text('Partial'), findsWidgets);
      expect(find.text('Delivery'), findsWidgets);
      expect(find.text('Walk In'), findsWidgets);
      expect(find.text('Anniversary'), findsWidgets);

      // Prominent Grand total & Outstanding banner
      expect(find.text('Grand Total'), findsWidgets);
      expect(find.text('₹2500'), findsWidgets);
      expect(find.text('Outstanding'), findsWidgets);
      expect(find.text('₹1000'), findsWidgets);
    });

    testWidgets('renders customer and recipient details with quick actions', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1200));
      await tester.pumpWidget(createTestWidget(header: testHeader, bundle: testBundle));
      await tester.pumpAndSettle();

      // Customer details
      expect(find.text('Customer & Delivery Details'), findsOneWidget);
      expect(find.text('ORDERED BY'), findsOneWidget);
      expect(find.text('Aarav Sharma'), findsOneWidget);
      expect(find.text('9876543210'), findsOneWidget);
      expect(find.text('aarav@example.com'), findsOneWidget);

      // Recipient details
      expect(find.text('DELIVER TO / RECIPIENT'), findsOneWidget);
      expect(find.text('Priya Verma'), findsOneWidget);
      expect(find.text('9123456789'), findsOneWidget);
      expect(find.textContaining('123 MG Road, Bengaluru'), findsOneWidget);
      expect(find.textContaining('Landmark: Opposite Metro Station'), findsOneWidget);
      expect(find.textContaining('PIN: 560001'), findsOneWidget);

      // Quick action buttons
      expect(find.byIcon(Icons.phone), findsWidgets);
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsWidgets);
      expect(find.text('Navigate / Google Maps'), findsOneWidget);
    });

    testWidgets('renders rich order items with thumbnail placeholder, SKU, customization and line totals', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1200));
      await tester.pumpWidget(createTestWidget(header: testHeader, bundle: testBundle));
      await tester.pumpAndSettle();

      // Section header with item count
      expect(find.text('Order Items (2)'), findsOneWidget);

      // Line 1: Luxury Red Rose Bouquet
      expect(find.text('Luxury Red Rose Bouquet (24 Stems)'), findsOneWidget);
      expect(find.text('SKU: FLR-ROSE-24'), findsOneWidget);
      expect(find.textContaining('Qty: 1 × ₹1800'), findsOneWidget);
      expect(find.textContaining('Disc: -₹100'), findsOneWidget);
      expect(find.textContaining('GST 12% (₹204)'), findsOneWidget);
      expect(find.text('₹1904'), findsOneWidget);
      expect(find.text('Add satin gold ribbon and extra gypsophila filler'), findsOneWidget);

      // Line 2: Ferrero Rocher Box
      expect(find.text('Ferrero Rocher Box (16 pcs)'), findsOneWidget);
      expect(find.text('SKU: CHOC-FR-16'), findsOneWidget);
      expect(find.textContaining('Qty: 1 × ₹600'), findsOneWidget);
      expect(find.text('₹708'), findsOneWidget);

      // Product thumbnail fallback florist icons
      expect(find.byIcon(Icons.local_florist_rounded), findsWidgets);
    });

    testWidgets('renders financial summary with itemized breakdown', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1200));
      await tester.pumpWidget(createTestWidget(header: testHeader, bundle: testBundle));
      await tester.pumpAndSettle();

      expect(find.text('Financial Summary'), findsOneWidget);
      expect(find.text('Items Subtotal'), findsOneWidget);
      expect(find.text('Item Discounts'), findsOneWidget);
      expect(find.text('GST / Taxes'), findsOneWidget);
      expect(find.text('Delivery Charges'), findsOneWidget);
      expect(find.text('Reward Points (20 pts)'), findsOneWidget);
      expect(find.text('- ₹20'), findsOneWidget);
    });

    testWidgets('renders payment details with Stage 3 tender classification and Collect CTA', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1400));
      await tester.pumpWidget(createTestWidget(header: testHeader, bundle: testBundle));
      await tester.pumpAndSettle();

      expect(find.text('Payment Details'), findsOneWidget);
      expect(find.text('Order Total'), findsOneWidget);
      expect(find.text('Paid Amount'), findsOneWidget);
      expect(find.text('Balance Due'), findsOneWidget);

      // Collect Payment button with exact outstanding amount
      expect(find.text('Collect Payment (₹1000)'), findsOneWidget);

      // Stage 3 Tender classification
      expect(find.text('Tender Breakdown'), findsOneWidget);
      expect(find.text('Sale Tenders (Checkout)'), findsOneWidget);
      expect(find.text('UPI'), findsOneWidget);
      expect(find.text('Credit Created at Checkout'), findsOneWidget);
      expect(find.text('Credit Collections (Subsequent)'), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget);
    });

    testWidgets('renders fulfillment and staff assignments', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1400));
      await tester.pumpWidget(createTestWidget(header: testHeader, bundle: testBundle));
      await tester.pumpAndSettle();

      expect(find.text('Fulfillment & Staff'), findsOneWidget);
      expect(find.text('Sunita (Lead Florist)'), findsOneWidget);
      expect(find.text('Ramesh (Driver)'), findsOneWidget);
      expect(find.text('4:00 PM - 6:00 PM'), findsWidgets);
    });

    testWidgets('renders notes and card message cleanly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1400));
      await tester.pumpWidget(createTestWidget(header: testHeader, bundle: testBundle));
      await tester.pumpAndSettle();

      expect(find.text('Notes & Instructions'), findsOneWidget);
      expect(find.text('Card Message'), findsOneWidget);
      expect(find.text('Happy 5th Anniversary my love!'), findsOneWidget);
      expect(find.text('Ring bell twice and leave with security if unavailable'), findsOneWidget);
      expect(find.text('VIP customer, use fresh red roses'), findsOneWidget);
    });

    testWidgets('renders order timeline with chronological entries', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1600));
      await tester.pumpWidget(createTestWidget(header: testHeader, bundle: testBundle));
      await tester.pumpAndSettle();

      expect(find.text('Order Timeline'), findsOneWidget);
      expect(find.text('Order confirmed and inventory reserved'), findsOneWidget);
      expect(find.text('Designer started arrangement'), findsOneWidget);
    });

    testWidgets('renders quick actions grid', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1600));
      await tester.pumpWidget(createTestWidget(header: testHeader, bundle: testBundle));
      await tester.pumpAndSettle();

      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Collect Payment'), findsWidgets);
      expect(find.text('Adjust Payment'), findsWidgets);
      expect(find.text('Assign Designer'), findsWidgets);
      expect(find.text('Generate Start Delivery Link'), findsWidgets);
      expect(find.text('Print'), findsWidgets);
    });

    testWidgets('renders in dual-column layout on wide web/desktop viewport (>= 800px)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(createTestWidget(
        header: testHeader,
        bundle: testBundle,
        screenSize: const Size(1200, 900),
      ));
      await tester.pumpAndSettle();

      // Find the main Row that holds left and right columns
      expect(find.byType(Row), findsWidgets);
      expect(find.text('Customer & Delivery Details'), findsOneWidget);
      expect(find.text('Order Items (2)'), findsOneWidget);
      expect(find.text('Financial Summary'), findsOneWidget);
      expect(find.text('Payment Details'), findsOneWidget);
    });

    testWidgets('fully paid order shows Fully Paid badge and no Collect Payment CTA', (tester) async {
      final paidHeader = OrderDetailHeader(
        id: 202,
        orderNo: 'ORD-202',
        status: 'delivered',
        customerName: 'Meera Nair',
        customerPhone: '9888877777',
        recipientName: 'Meera Nair',
        recipientPhone: '9888877777',
        fulfilmentType: 'take_away',
        source: 'walkIn',
        grandTotalPaise: 50000,
        subtotalPaise: 50000,
        address: '-',
        scheduledAt: DateTime(2026, 9, 20),
        occasion: '-',
        deliverySlot: '-',
        cardMessage: '',
        isPaid: 1,
        paidAmountPaise: 50000,
      );

      final paidBundle = OrderDetailBundle(
        header: paidHeader,
        lines: const [],
        payments: [
          {
            'id': 10,
            'method': 'Cash',
            'amount_paise': 50000,
            'payment_type': 'SaleTender',
            'created_at': '2026-09-20T12:00:00Z',
          }
        ],
        timeline: const [],
        schedulerTasks: const [],
        inventoryTransactions: const [],
        receiptStatus: null,
        whatsappStatus: null,
        relayInfo: const {},
        corporateInfo: const {},
        marketplaceInfo: const {},
      );

      await tester.binding.setSurfaceSize(const Size(400, 1000));
      await tester.pumpWidget(createTestWidget(header: paidHeader, bundle: paidBundle));
      await tester.pumpAndSettle();

      expect(find.text('Fully Paid'), findsOneWidget);
      expect(find.textContaining('Collect Payment (₹'), findsNothing);
    });
  });
}
