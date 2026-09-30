import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/l10n/app_localizations.dart';
import 'package:floraprise/models/dashboard_summary.dart';
import 'package:floraprise/models/order_workspace_models.dart';
import 'package:floraprise/models/workspace_destinations.dart';
import 'package:floraprise/models/storage_mode.dart';
import 'package:floraprise/providers/app_shell_controller.dart';
import 'package:floraprise/providers/dashboard_provider.dart';
import 'package:floraprise/providers/license_provider.dart';
import 'package:floraprise/providers/order_provider.dart';
import 'package:floraprise/providers/storage_mode_provider.dart';
import 'package:floraprise/providers/subscription_provider.dart';
import 'package:floraprise/screens/main_shell_screen.dart';
import 'package:floraprise/screens/orders_screen.dart';
import 'package:floraprise/services/storage_mode_service.dart';
import 'package:floraprise/services/subscription_service.dart';
import 'package:floraprise/widgets/dashboard/dashboard_attention_section.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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

class _TestDashboardProvider extends ChangeNotifier implements DashboardProvider {
  @override
  DashboardSummary get summary => const DashboardSummary(
        todaySalesAmount: 0,
        todayOrderCount: 0,
        pendingOrders: 0,
        preparingOrders: 0,
        readyOrders: 0,
        outForDeliveryOrders: 0,
        todayDeliveryCount: 0,
        todayPickupCount: 0,
        todayTaskCount: 0,
        lowStockItems: 0,
        outOfStockItems: 0,
        todayBirthdays: 0,
        todayFollowUps: 0,
        todayFestivalCount: 0,
        todayPendingPayments: 4,
        todayPurchaseListCount: 0,
        activeAssociates: 0,
        activeStaff: 0,
        unmarkedAttendanceCount: 0,
        todayExpenses: 0,
        lowStockList: [],
        todaySchedule: [],
      );

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  Future<void> loadSummary({bool showLoading = true}) async {}

  @override
  Future<void> refresh({bool showLoading = false}) async {}
}

class _TrackingOrderProvider extends ChangeNotifier implements OrderProvider {
  OrderWorkspaceFilters _filters = OrderWorkspaceFilters.empty;

  @override
  String get activeTab => 'all';

  @override
  String get searchQuery => '';

  @override
  OrderWorkspaceFilters get filters => _filters;

  @override
  List<OrderListItem> get orders => const [];

  @override
  List<OrderListItem> get history => const [];

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  OrderDetailHeader? get detailHeader => null;

  @override
  OrderDetailBundle? get detailBundle => null;

  @override
  bool get isDetailLoading => false;

  @override
  Future<void> applyFilters(OrderWorkspaceFilters filters) async {
    _filters = filters;
    notifyListeners();
  }

  @override
  Future<void> loadTodayOrders() async {}

  @override
  Future<void> setSelectedDate(DateTime? date) async {}

  @override
  Future<void> loadOrdersForTab(String tab) async {}

  @override
  Future<void> setSearchQuery(String query) async {}

  @override
  Future<void> clearDateFilter() async {}

  @override
  Future<void> loadHistory({int limit = 100, int offset = 0}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Floraprise Event Sales Navigation & Orders Submenu Hierarchy', () {
    test('WorkspaceNavigation defines orders hierarchy with Event Sales at index 3', () {
      final orders = WorkspaceNavigation.findByRoute('/orders');
      expect(orders, isNotNull);
      expect(orders!.hasChildren, isTrue);
      expect(orders.children.length, 5);

      final childRoutes = orders.children.map((c) => c.route).toList();
      expect(childRoutes, [
        '/orders/walkin',
        '/orders/delivery',
        '/orders/pickup',
        '/orders/event-sales',
        '/orders/search',
      ]);

      final childTitles = orders.children.map((c) => c.title).toList();
      expect(childTitles, [
        'Walkin Orders',
        'Delivery Orders',
        'Pickup Orders',
        'Event Sales',
        'Search Orders',
      ]);

      final eventSalesDest = WorkspaceNavigation.findByRoute('/orders/event-sales');
      expect(eventSalesDest, isNotNull);
      expect(eventSalesDest!.id, 'orders_event_sales');
      expect(eventSalesDest.title, 'Event Sales');
      expect(eventSalesDest.icon, Icons.celebration_outlined);
      expect(eventSalesDest.selectedIcon, Icons.celebration_rounded);
    });

    testWidgets('MainShellScreen renders OrdersScreen with eventSale filter when route is /orders/event-sales', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final storageMode = StorageModeProvider(_MockStorageModeService());
      storageMode.setMode(StorageMode.cloud);
      final trackingOrderProvider = _TrackingOrderProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<StorageModeProvider>.value(value: storageMode),
            ChangeNotifierProvider<AppShellController>(create: (_) => AppShellController()),
            ChangeNotifierProvider<DashboardProvider>(create: (_) => _TestDashboardProvider()),
            ChangeNotifierProvider<OrderProvider>.value(value: trackingOrderProvider),
            ChangeNotifierProvider<SubscriptionProvider>(create: (_) => _ActiveSubscriptionProvider()),
            ChangeNotifierProvider<LicenseProvider>(create: (_) => _FakeLicenseProvider()),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MainShellScreen(initialRoute: '/orders/event-sales'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OrdersScreen), findsOneWidget);
      expect(trackingOrderProvider.filters.eventSale, isTrue);
      expect(find.text('Event Sales'), findsWidgets);
    });

    testWidgets('MainShellScreen renders OrdersScreen with eventSale filter when route is alias /orders/events', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final storageMode = StorageModeProvider(_MockStorageModeService());
      storageMode.setMode(StorageMode.cloud);
      final trackingOrderProvider = _TrackingOrderProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<StorageModeProvider>.value(value: storageMode),
            ChangeNotifierProvider<AppShellController>(create: (_) => AppShellController()),
            ChangeNotifierProvider<DashboardProvider>(create: (_) => _TestDashboardProvider()),
            ChangeNotifierProvider<OrderProvider>.value(value: trackingOrderProvider),
            ChangeNotifierProvider<SubscriptionProvider>(create: (_) => _ActiveSubscriptionProvider()),
            ChangeNotifierProvider<LicenseProvider>(create: (_) => _FakeLicenseProvider()),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MainShellScreen(initialRoute: '/orders/events'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OrdersScreen), findsOneWidget);
      expect(trackingOrderProvider.filters.eventSale, isTrue);
    });

    testWidgets('_OrdersTab workspace hub contains Event Sales action', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final storageMode = StorageModeProvider(_MockStorageModeService());
      storageMode.setMode(StorageMode.cloud);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<StorageModeProvider>.value(value: storageMode),
            ChangeNotifierProvider<AppShellController>(create: (_) => AppShellController()),
            ChangeNotifierProvider<DashboardProvider>(create: (_) => _TestDashboardProvider()),
            ChangeNotifierProvider<OrderProvider>(create: (_) => _TrackingOrderProvider()),
            ChangeNotifierProvider<SubscriptionProvider>(create: (_) => _ActiveSubscriptionProvider()),
            ChangeNotifierProvider<LicenseProvider>(create: (_) => _FakeLicenseProvider()),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MainShellScreen(initialRoute: '/_orders-tab'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Event Sales'), findsOneWidget);
      expect(find.text('Manage weddings, parties, and corporate events.'), findsOneWidget);
    });
  });

  group('Dashboard Payment Follow-up Routing to Pending Payments', () {
    testWidgets('DashboardAttentionSection displays Payment Follow-up card and routes via onPaymentsTap', (
      tester,
    ) async {
      String? routedPath;
      const summary = DashboardSummary(
        todaySalesAmount: 0,
        todayOrderCount: 0,
        pendingOrders: 0,
        preparingOrders: 0,
        readyOrders: 0,
        outForDeliveryOrders: 0,
        todayDeliveryCount: 0,
        todayPickupCount: 0,
        todayTaskCount: 0,
        lowStockItems: 0,
        outOfStockItems: 0,
        todayBirthdays: 0,
        todayFollowUps: 0,
        todayFestivalCount: 0,
        todayPendingPayments: 5,
        todayPurchaseListCount: 0,
        activeAssociates: 0,
        activeStaff: 0,
        unmarkedAttendanceCount: 0,
        todayExpenses: 0,
        lowStockList: [],
        todaySchedule: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/reports/pending-payments': (_) => const Scaffold(
                  body: Center(child: Text('Target: Pending Payments Screen')),
                ),
            '/reminders': (_) => const Scaffold(
                  body: Center(child: Text('Target: Reminders Screen')),
                ),
          },
          home: Builder(
            builder: (context) => Scaffold(
              body: DashboardAttentionSection(
                summary: summary,
                onInventoryTap: () => Navigator.pushNamed(context, '/inventory'),
                onOrdersTap: () => Navigator.pushNamed(context, '/orders'),
                onDeliveriesTap: () => Navigator.pushNamed(context, '/delivery-workspace'),
                onPaymentsTap: () {
                  routedPath = '/reports/pending-payments';
                  Navigator.pushNamed(context, '/reports/pending-payments');
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Payment Follow-up'), findsOneWidget);
      expect(find.text('5 customers with balance pending'), findsOneWidget);
      expect(find.text('View Accounts'), findsOneWidget);

      await tester.tap(find.text('View Accounts'));
      await tester.pumpAndSettle();

      expect(routedPath, '/reports/pending-payments');
      expect(find.text('Target: Pending Payments Screen'), findsOneWidget);
      expect(find.text('Target: Reminders Screen'), findsNothing);
    });
  });
}
