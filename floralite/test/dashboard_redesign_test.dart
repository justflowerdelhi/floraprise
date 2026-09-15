import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:floraprise/l10n/app_localizations.dart';
import 'package:floraprise/models/dashboard_summary.dart';
import 'package:floraprise/models/license.dart';
import 'package:floraprise/models/order_workspace_models.dart';
import 'package:floraprise/models/storage_mode.dart';
import 'package:floraprise/providers/app_shell_controller.dart';
import 'package:floraprise/providers/auth_provider.dart';
import 'package:floraprise/providers/dashboard_provider.dart';
import 'package:floraprise/providers/license_provider.dart';
import 'package:floraprise/providers/storage_mode_provider.dart';
import 'package:floraprise/providers/subscription_provider.dart';
import 'package:floraprise/screens/dashboard_screen.dart';
import 'package:floraprise/services/mobile_auth_service.dart';
import 'package:floraprise/services/storage_mode_service.dart';
import 'package:floraprise/services/subscription_service.dart';
import 'package:floraprise/widgets/dashboard/botanical_decorations.dart';
import 'package:floraprise/widgets/dashboard/dashboard_attention_section.dart';
import 'package:floraprise/widgets/dashboard/dashboard_deliveries_panel.dart';
import 'package:floraprise/widgets/dashboard/dashboard_hero_header.dart';
import 'package:floraprise/widgets/dashboard/dashboard_inventory_health.dart';
import 'package:floraprise/widgets/dashboard/dashboard_kpi_section.dart';
import 'package:floraprise/widgets/dashboard/dashboard_orders_stream.dart';

class _MockStorageModeService extends StorageModeService {
  StorageMode _mode = StorageMode.cloud;

  @override
  Future<StorageMode?> getCurrentMode() async => _mode;

  @override
  Future<void> setMode(StorageMode mode) async => _mode = mode;

  @override
  Future<bool> hasSelectedMode() async => true;

  @override
  Future<bool> isLocal() async => _mode == StorageMode.local;

  @override
  Future<bool> isCloud() async => _mode == StorageMode.cloud;
}

class _ActiveSubscriptionProvider extends SubscriptionProvider {
  _ActiveSubscriptionProvider() : super(SubscriptionService());

  @override
  bool get isLoading => false;

  @override
  bool get isLocked => false;

  @override
  bool get isGracePeriod => false;

  @override
  bool get hasWriteRestrictions => false;

  @override
  String get gracePeriodMessage => '';
}

class _FakeLicenseProvider extends ChangeNotifier implements LicenseProvider {
  @override
  LicenseProviderState get state => LicenseProviderState.valid;

  @override
  CloudLicenseCheckResult? get license => null;

  @override
  String? get message => null;

  @override
  bool get isLoading => false;

  @override
  bool get isRegistered => true;

  @override
  bool get blocksBusinessAccess => false;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> register(BusinessRegistrationInput input) async => true;

  @override
  Future<void> refresh() async {}

  @override
  Future<void> heartbeat() async {}
}

class _FakeDashboardProvider extends ChangeNotifier implements DashboardProvider {
  _FakeDashboardProvider({DashboardSummary? summary})
      : _summary = summary ?? _createDefaultSummary();

  final DashboardSummary _summary;

  @override
  DashboardSummary get summary => _summary;

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  Future<void> loadSummary({bool showLoading = true}) async {}

  @override
  Future<void> refresh({bool showLoading = false}) async {}

  static DashboardSummary _createDefaultSummary() {
    return const DashboardSummary(
      todaySalesAmount: 48500,
      todayOrderCount: 14,
      pendingOrders: 3,
      preparingOrders: 2,
      readyOrders: 4,
      outForDeliveryOrders: 1,
      todayDeliveryCount: 8,
      todayPickupCount: 6,
      todayTaskCount: 2,
      lowStockItems: 3,
      outOfStockItems: 1,
      todayBirthdays: 1,
      todayFollowUps: 2,
      todayFestivalCount: 0,
      todayPendingPayments: 5,
      todayPurchaseListCount: 1,
      activeAssociates: 3,
      activeStaff: 4,
      unmarkedAttendanceCount: 0,
      todayExpenses: 3200,
      lowStockList: [],
      todaySchedule: [],
    );
  }
}

Widget _wrapWithApp(Widget child, {DashboardSummary? summary}) {
  final storageMode = StorageModeProvider(_MockStorageModeService());
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: storageMode),
      ChangeNotifierProvider(create: (_) => AppShellController()),
      ChangeNotifierProvider(create: (_) => AuthProvider(MobileAuthService())),
      ChangeNotifierProvider<SubscriptionProvider>(create: (_) => _ActiveSubscriptionProvider()),
      ChangeNotifierProvider<LicenseProvider>(create: (_) => _FakeLicenseProvider()),
      ChangeNotifierProvider<DashboardProvider>(
        create: (_) => _FakeDashboardProvider(summary: summary),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Botanical Canvas Decorators', () {
    testWidgets('BotanicalHeroPainter paints gracefully without error', (tester) async {
      await tester.pumpWidget(
        const CustomPaint(
          size: Size(800, 200),
          painter: BotanicalHeroPainter(),
        ),
      );
      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('BotanicalPetalPainter paints gracefully without error', (tester) async {
      await tester.pumpWidget(
        const CustomPaint(
          size: Size(200, 200),
          painter: BotanicalPetalPainter(),
        ),
      );
      expect(find.byType(CustomPaint), findsOneWidget);
    });
  });

  group('DashboardHeroHeader Widget', () {
    testWidgets('renders greeting, shop name, florist studio badge, and quick action buttons', (
      tester,
    ) async {
      var walkInTapped = false;
      var newOrderTapped = false;
      var addProductTapped = false;
      var deliveryWorkspaceTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardHeroHeader(
              shopName: 'Blossom & Bloom',
              ownerName: 'Clara',
              onNewSale: () => walkInTapped = true,
              onNewOrder: () => newOrderTapped = true,
              onAddProduct: () => addProductTapped = true,
              onDeliveryMap: () => deliveryWorkspaceTapped = true,
            ),
          ),
        ),
      );

      // Greeting and identity
      expect(find.textContaining('Blossom & Bloom'), findsWidgets);
      expect(find.text('PRO CLOUD STUDIO'), findsOneWidget);

      // Quick actions
      expect(find.text('+ New Sale'), findsOneWidget);
      expect(find.text('+ New Order'), findsOneWidget);
      expect(find.text('+ Add Product'), findsOneWidget);
      expect(find.text('Delivery Workspace'), findsOneWidget);

      // Tap actions
      await tester.tap(find.text('+ New Sale'));
      expect(walkInTapped, isTrue);

      await tester.tap(find.text('+ New Order'));
      expect(newOrderTapped, isTrue);

      await tester.tap(find.text('+ Add Product'));
      expect(addProductTapped, isTrue);

      await tester.tap(find.text('Delivery Workspace'));
      expect(deliveryWorkspaceTapped, isTrue);
    });
  });

  group('DashboardKpiSection Widget', () {
    testWidgets('displays formatted sales, orders, AOV, deliveries, and expenses', (
      tester,
    ) async {
      var salesTapped = false;
      var ordersTapped = false;

      const testSummary = DashboardSummary(
        todaySalesAmount: 4850000,
        todayOrderCount: 14,
        pendingOrders: 3,
        preparingOrders: 2,
        readyOrders: 4,
        outForDeliveryOrders: 1,
        todayDeliveryCount: 8,
        todayPickupCount: 6,
        todayTaskCount: 2,
        lowStockItems: 3,
        outOfStockItems: 1,
        todayBirthdays: 1,
        todayFollowUps: 2,
        todayFestivalCount: 0,
        todayPendingPayments: 5,
        todayPurchaseListCount: 1,
        activeAssociates: 3,
        activeStaff: 4,
        unmarkedAttendanceCount: 0,
        todayExpenses: 320000,
        lowStockList: [],
        todaySchedule: [],
      );

      tester.view.physicalSize = const Size(1366, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DashboardKpiSection(
                summary: testSummary,
                onSalesTap: () => salesTapped = true,
                onOrdersTap: () => ordersTapped = true,
                onDeliveriesTap: () {},
                onExpensesTap: () {},
              ),
            ),
          ),
        ),
      );

      // Hero KPI
      expect(find.text("TODAY'S SALES"), findsOneWidget);
      expect(find.textContaining('48500'), findsOneWidget);

      // Secondary KPI cards
      expect(find.text("Today's Orders"), findsOneWidget);
      expect(find.text('14'), findsOneWidget);

      expect(find.text('Average Order Value'), findsOneWidget);
      // 48500 / 14 = 3464.28 -> ₹3464
      expect(find.textContaining('3464'), findsOneWidget);

      expect(find.text('Pending Deliveries'), findsOneWidget);
      expect(find.text("Today's Expenses"), findsOneWidget);

      // Interactions
      await tester.tap(find.text("TODAY'S SALES"));
      expect(salesTapped, isTrue);

      await tester.tap(find.text("Today's Orders"));
      expect(ordersTapped, isTrue);
    });
  });

  group('DashboardAttentionSection Widget', () {
    testWidgets('renders operational attention chips when items need florist care', (
      tester,
    ) async {
      const busySummary = DashboardSummary(
        todaySalesAmount: 10000,
        todayOrderCount: 5,
        pendingOrders: 2,
        preparingOrders: 3,
        readyOrders: 1,
        outForDeliveryOrders: 2,
        todayDeliveryCount: 4,
        todayPickupCount: 2,
        todayTaskCount: 1,
        lowStockItems: 4,
        outOfStockItems: 2,
        todayBirthdays: 0,
        todayFollowUps: 1,
        todayFestivalCount: 0,
        todayPendingPayments: 3,
        todayPurchaseListCount: 0,
        activeAssociates: 2,
        activeStaff: 3,
        unmarkedAttendanceCount: 0,
        todayExpenses: 500,
        lowStockList: [],
        todaySchedule: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardAttentionSection(
              summary: busySummary,
              onInventoryTap: () {},
              onOrdersTap: () {},
              onDeliveriesTap: () {},
              onPaymentsTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Needs Your Attention'), findsOneWidget);
      expect(find.text('Inventory Alert'), findsOneWidget);
      expect(find.text('Preparation Queue'), findsOneWidget);
      expect(find.text('Delivery Tracking'), findsOneWidget);
      expect(find.text('Payment Follow-up'), findsOneWidget);
    });

    testWidgets('renders reassuring florist empty state when all operations are healthy', (
      tester,
    ) async {
      final cleanSummary = DashboardSummary.empty();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardAttentionSection(
              summary: cleanSummary,
              onInventoryTap: () {},
              onOrdersTap: () {},
              onDeliveriesTap: () {},
              onPaymentsTap: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining("You're all caught up"), findsOneWidget);
      expect(
        find.textContaining('Studio operations, deliveries, and inventory levels are completely healthy.'),
        findsOneWidget,
      );
    });
  });

  group('DashboardOrdersStream Widget', () {
    testWidgets('displays empty state when orders list is empty', (tester) async {
      var walkInCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardOrdersStream(
              orders: const [],
              isLoading: false,
              onViewAllOrders: () {},
              onOrderTap: (_) {},
              onNewSale: () => walkInCalled = true,
            ),
          ),
        ),
      );

      expect(find.text("Today's Orders"), findsOneWidget);
      expect(
        find.text('Your first arrangement of the day is waiting.'),
        findsOneWidget,
      );
      expect(find.text('Start Walk-in Sale'), findsOneWidget);

      await tester.tap(find.text('Start Walk-in Sale'));
      expect(walkInCalled, isTrue);
    });

    testWidgets('renders order rows with customer name, mode, and rupee amount', (
      tester,
    ) async {
      final sampleOrders = [
        OrderListItem(
          id: 101,
          orderNo: 'ORD-101',
          customerName: 'Ananya Sharma',
          recipientName: 'Vikram Sharma',
          customerPhone: '9876543210',
          source: 'walk_in',
          fulfilmentType: 'delivery',
          status: 'preparing',
          grandTotalPaise: 250000,
          isPaid: 1,
          createdAt: DateTime(2026, 9, 15, 11, 30),
          scheduledAt: null,
        ),
      ];

      OrderListItem? tappedOrder;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardOrdersStream(
              orders: sampleOrders,
              isLoading: false,
              onViewAllOrders: () {},
              onOrderTap: (o) => tappedOrder = o,
              onNewSale: () {},
            ),
          ),
        ),
      );

      expect(find.text('Ananya Sharma'), findsOneWidget);
      expect(find.text('Delivery'), findsOneWidget);
      expect(find.text('Preparing'), findsOneWidget);
      expect(find.text('₹2500'), findsOneWidget);

      await tester.tap(find.text('Ananya Sharma'));
      expect(tappedOrder?.id, 101);
    });
  });

  group('DashboardDeliveriesPanel Widget', () {
    testWidgets('displays empty state when active deliveries list is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardDeliveriesPanel(
              deliveries: const [],
              isLoading: false,
              onViewWorkspace: () {},
            ),
          ),
        ),
      );

      expect(find.text("Today's Deliveries"), findsOneWidget);
      expect(find.text('All deliveries are on schedule.'), findsOneWidget);
    });
  });

  group('DashboardInventoryHealth Widget', () {
    testWidgets('renders stock health ratios and empty state when stock is healthy', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardInventoryHealth(
              products: const [],
              lowStockProducts: const [],
              isLoading: false,
              onViewInventory: () {},
            ),
          ),
        ),
      );

      expect(find.text('Inventory Health'), findsOneWidget);
      expect(find.text('Catalogue inventory active.'), findsOneWidget);
    });
  });

  group('DashboardScreen Desktop vs Mobile Viewport Layout', () {
    testWidgets('Desktop viewport (>= 800px) displays full SaaS sections and NO Workspaces grid', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1366, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_wrapWithApp(const DashboardScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Main SaaS components rendered
      expect(find.byType(DashboardHeroHeader), findsOneWidget);
      expect(find.byType(DashboardKpiSection), findsOneWidget);
      expect(find.byType(DashboardAttentionSection), findsOneWidget);
      expect(find.byType(DashboardOrdersStream), findsOneWidget);
      expect(find.byType(DashboardDeliveriesPanel), findsOneWidget);
      expect(find.byType(DashboardInventoryHealth), findsOneWidget);

      // Crucial: Workspace Navigation grid should NOT be present on desktop
      // (Workspaces title in _buildWorkspaces is 'Workspaces')
      expect(find.text('Workspaces'), findsNothing);
    });

    testWidgets('Mobile viewport (< 800px) preserves Workspaces grid fallback', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_wrapWithApp(const DashboardScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // On mobile (< 800px), Workspaces fallback is rendered for phone users
      expect(find.text('Workspaces'), findsOneWidget);
      expect(find.byType(DashboardHeroHeader), findsOneWidget);
    });
  });
}
