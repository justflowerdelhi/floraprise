import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/models/dashboard_summary.dart';
import 'package:floraprise/models/workspace_destinations.dart';
import 'package:floraprise/providers/app_shell_controller.dart';
import 'package:floraprise/providers/dashboard_provider.dart';
import 'package:floraprise/providers/subscription_provider.dart';
import 'package:floraprise/screens/main_shell_screen.dart';
import 'package:floraprise/services/subscription_service.dart';
import 'package:floraprise/widgets/floraprise_brand.dart';
import 'package:provider/provider.dart';

import 'package:floraprise/l10n/app_localizations.dart';
import 'package:floraprise/models/license.dart';
import 'package:floraprise/models/storage_mode.dart';
import 'package:floraprise/providers/license_provider.dart';
import 'package:floraprise/providers/storage_mode_provider.dart';
import 'package:floraprise/services/storage_mode_service.dart';
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

DashboardSummary makeSummary({
  int pendingOrders = 0,
  int todayTaskCount = 0,
  int lowStockItems = 0,
  int outOfStockItems = 0,
  int unmarkedAttendanceCount = 0,
  int todayFollowUps = 0,
  int todayPurchaseListCount = 0,
}) {
  return DashboardSummary(
    todaySalesAmount: 0,
    todayOrderCount: 0,
    pendingOrders: pendingOrders,
    preparingOrders: 0,
    readyOrders: 0,
    outForDeliveryOrders: 0,
    todayDeliveryCount: 0,
    todayPickupCount: 0,
    todayTaskCount: todayTaskCount,
    lowStockItems: lowStockItems,
    outOfStockItems: outOfStockItems,
    todayBirthdays: 0,
    todayFollowUps: todayFollowUps,
    todayFestivalCount: 0,
    todayPendingPayments: 0,
    todayPurchaseListCount: todayPurchaseListCount,
    activeAssociates: 0,
    activeStaff: 0,
    unmarkedAttendanceCount: unmarkedAttendanceCount,
    todayExpenses: 0,
    lowStockList: const [],
    todaySchedule: const [],
  );
}

class _FakeDashboardProvider extends ChangeNotifier implements DashboardProvider {
  @override
  DashboardSummary get summary => makeSummary(
        pendingOrders: 3,
        todayTaskCount: 2,
        lowStockItems: 1,
        outOfStockItems: 1,
        unmarkedAttendanceCount: 4,
        todayFollowUps: 5,
        todayPurchaseListCount: 1,
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('WorkspaceNavigation Shared Source of Truth', () {
    test('contains all 5 grouped sections with 20 destinations plus Home (21 total)', () {
      expect(WorkspaceNavigation.sections.length, 5);

      final sectionTitles =
          WorkspaceNavigation.sections.map((s) => s.title).toList();
      expect(sectionTitles, [
        'SALES & ORDERS',
        'CATALOGUE & INVENTORY',
        'TEAM',
        'ACCOUNTING',
        'UTILITIES',
      ]);

      expect(WorkspaceNavigation.allDestinations.length, 21);

      // Section items count
      final salesSection = WorkspaceNavigation.sections[0];
      expect(salesSection.items.length, 6);
      expect(salesSection.items.map((i) => i.route).toList(), [
        '/walkin-sales',
        '/orders',
        '/scheduler',
        '/customers',
        '/associates',
        '/delivery-workspace',
      ]);

      final catalogueSection = WorkspaceNavigation.sections[1];
      expect(catalogueSection.items.length, 5);
      expect(catalogueSection.items.map((i) => i.route).toList(), [
        '/categories',
        '/products',
        '/my-designs',
        '/inventory',
        '/purchase-list',
      ]);

      final teamSection = WorkspaceNavigation.sections[2];
      expect(teamSection.items.length, 2);
      expect(teamSection.items.map((i) => i.route).toList(), [
        '/staff',
        '/attendance',
      ]);

      final accountingSection = WorkspaceNavigation.sections[3];
      expect(accountingSection.items.length, 5);
      expect(accountingSection.items.map((i) => i.route).toList(), [
        '/opening-cash',
        '/cash-book',
        '/expenses',
        '/day-closing',
        '/reports',
      ]);

      final utilitiesSection = WorkspaceNavigation.sections[4];
      expect(utilitiesSection.items.length, 2);
      expect(utilitiesSection.items.map((i) => i.route).toList(), [
        '/reminders',
        '/settings',
      ]);
    });

    test('findByRoute resolves every route correctly', () {
      for (final dest in WorkspaceNavigation.allDestinations) {
        final found = WorkspaceNavigation.findByRoute(dest.route);
        expect(found, isNotNull, reason: 'Route ${dest.route} should be found');
        expect(found!.id, dest.id);
      }
    });

    test('badge selectors return expected counts from dashboard summary', () {
      final summary = makeSummary(
        pendingOrders: 7,
        todayTaskCount: 3,
        lowStockItems: 2,
        outOfStockItems: 1,
        unmarkedAttendanceCount: 4,
        todayFollowUps: 5,
        todayPurchaseListCount: 6,
      );

      final ordersItem = WorkspaceNavigation.findByRoute('/orders')!;
      expect(ordersItem.getBadge(summary), 7);

      final inventoryItem = WorkspaceNavigation.findByRoute('/inventory')!;
      expect(inventoryItem.getBadge(summary), 3); // 2 + 1

      final attendanceItem = WorkspaceNavigation.findByRoute('/attendance')!;
      expect(attendanceItem.getBadge(summary), 4);

      final remindersItem = WorkspaceNavigation.findByRoute('/reminders')!;
      expect(remindersItem.getBadge(summary), 5);

      final tasksItem = WorkspaceNavigation.findByRoute('/scheduler')!;
      expect(tasksItem.getBadge(summary), 3);
    });
  });

  group('MainShellScreen Desktop Sidebar vs Mobile Navigation', () {
    Widget buildTestWidget({required Size screenSize}) {
      final storageMode = StorageModeProvider(_MockStorageModeService());
      storageMode.setMode(StorageMode.cloud);

      return MultiProvider(
        providers: [
          ChangeNotifierProvider<StorageModeProvider>.value(
            value: storageMode,
          ),
          ChangeNotifierProvider<AppShellController>(
            create: (_) => AppShellController(),
          ),
          ChangeNotifierProvider<DashboardProvider>(
            create: (_) => _FakeDashboardProvider(),
          ),
          ChangeNotifierProvider<SubscriptionProvider>(
            create: (_) => _ActiveSubscriptionProvider(),
          ),
          ChangeNotifierProvider<LicenseProvider>(
            create: (_) => _FakeLicenseProvider(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(size: screenSize),
            child: const MainShellScreen(initialRoute: '/backup-restore'),
          ),
        ),
      );
    }

    testWidgets('Desktop mode displays sidebar with section headers and no bottom navigation', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget(screenSize: const Size(1200, 800)));
      await tester.pumpAndSettle();

      // Verify branding in desktop sidebar
      expect(find.byType(FlorapriseBrand), findsOneWidget);
      expect(find.text('Pro Cloud'), findsOneWidget);

      // Verify section headers appear in desktop sidebar
      expect(find.text('SALES & ORDERS'), findsOneWidget);
      expect(find.text('CATALOGUE & INVENTORY'), findsOneWidget);
      expect(find.text('TEAM'), findsOneWidget);
      expect(find.text('ACCOUNTING'), findsOneWidget);
      expect(find.text('UTILITIES'), findsOneWidget);

      // Verify specific destinations in sidebar
      expect(find.text('Walk-in Sales'), findsOneWidget);
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Staff'), findsOneWidget);
      expect(find.text('Opening Cash'), findsOneWidget);
      expect(find.text('Reminders'), findsOneWidget);

      // Verify no bottom NavigationBar on desktop
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('Mobile mode displays bottom NavigationBar and no sidebar section headers', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget(screenSize: const Size(400, 800)));
      await tester.pumpAndSettle();

      // Verify bottom NavigationBar exists on mobile
      expect(find.byType(NavigationBar), findsOneWidget);

      // On mobile with non-dashboard route, the desktop sidebar is absent, so section headers are not rendered
      expect(find.text('SALES & ORDERS'), findsNothing);
      expect(find.text('CATALOGUE & INVENTORY'), findsNothing);
      expect(find.text('TEAM'), findsNothing);
      expect(find.text('ACCOUNTING'), findsNothing);
      expect(find.text('UTILITIES'), findsNothing);
    });
  });
}
