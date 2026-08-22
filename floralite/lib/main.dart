import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';

import 'data/repositories/customer_repository.dart';
import 'data/repositories/category_repository.dart';
import 'data/repositories/design_repository.dart';
import 'data/repositories/inventory_repository.dart';
import 'data/repositories/job_repository.dart';
import 'data/repositories/order_repository.dart';
import 'data/repositories/order_workflow_repository.dart';
import 'data/repositories/occasion_repository.dart';
import 'data/repositories/scheduler_repository.dart';
import 'data/repositories/purchase_repository.dart';
import 'data/repositories/associate_repository.dart';
import 'data/repositories/staff_repository.dart';
import 'data/repositories/attendance_repository.dart';
import 'screens/my_designs_screen.dart';
import 'screens/walkin_sales_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/staff_management_screen.dart';
import 'screens/reminders_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/reports/sales_report_screen.dart';
import 'screens/reports/order_status_report_screen.dart';
import 'screens/reports/top_customers_report_screen.dart';
import 'screens/reports/top_products_report_screen.dart';
import 'screens/reports/low_stock_report_screen.dart';
import 'screens/reports/expense_report_screen.dart';
import 'screens/reports/day_closing_report_screen.dart';
import 'screens/reports/wastage_report_screen.dart';
import 'screens/reports/production_report_screen.dart';
import 'screens/reports/rewards_report_screen.dart';
import 'screens/products_screen.dart';
import 'screens/scheduler_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/rewards_settings_screen.dart';
import 'screens/shop_details_screen.dart';
import 'screens/share_branding_settings_screen.dart';
import 'screens/about_screen.dart';
import 'screens/business_registration_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/license_subscription_required_screen.dart';
import 'screens/backup_restore_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/voice_stock_entry_screen.dart';
import 'screens/ready_bouquet_inventory_screen.dart';
import 'screens/bouquet_production_entry_screen.dart';
import 'screens/printer_settings_screen.dart';
import 'screens/printer_test_screen.dart';
import 'screens/barcode_screen.dart';
import 'screens/purchase_list_screen.dart';
import 'screens/opening_cash_screen.dart';
import 'screens/cash_book_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/day_closing_screen.dart';
import 'screens/draft_orders_screen.dart';
import 'screens/associates_screen.dart';
import 'screens/order_workflow_screen.dart';
import 'screens/attendance_home_screen.dart';
import 'screens/attendance_today_screen.dart';
import 'screens/attendance_mark_screen.dart';
import 'screens/attendance_monthly_summary_screen.dart';
import 'presentation/splash/splash_screen.dart';
import 'l10n/app_localizations.dart';
import 'managers/customer_manager.dart';
import 'managers/category_manager.dart';
import 'managers/dashboard_manager.dart';
import 'managers/inventory_manager.dart';
import 'managers/language_manager.dart';
import 'managers/occasion_manager.dart';
import 'managers/order_manager.dart';
import 'managers/order_workflow_manager.dart';
import 'managers/pricing_manager.dart';
import 'managers/scheduler_manager.dart';
import 'managers/walk_in_manager.dart';
import 'managers/associate_manager.dart';
import 'managers/staff_manager.dart';
import 'managers/purchase_manager.dart';
import 'providers/dashboard_provider.dart';
import 'providers/app_shell_controller.dart';
import 'providers/category_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/language_provider.dart';
import 'providers/occasion_provider.dart';
import 'providers/order_provider.dart';
import 'providers/order_workflow_provider.dart';
import 'providers/product_provider.dart';
import 'providers/scheduler_provider.dart';
import 'providers/voice_provider.dart';
import 'providers/walk_in_session_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/design_provider.dart';
import 'providers/purchase_provider.dart';
import 'providers/printer_provider.dart';
import 'providers/associate_provider.dart';
import 'providers/staff_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/license_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/subscription_provider.dart';
import 'data/repositories/product_repository.dart';
import 'services/order_print_service.dart';
import 'services/order_whatsapp_service.dart';
import 'services/license_service.dart';
import 'services/mobile_auth_service.dart';
import 'services/subscription_service.dart';
import 'services/app_route_observer.dart';
import 'services/business_data_event_bus.dart';
import 'services/printer/printer_manager.dart';
import 'services/scheduler_service.dart';
import 'screens/main_shell_screen.dart';
import 'screens/delivery_workspace_screen.dart';
import 'screens/live_delivery_tracking_screen.dart';
import 'screens/driver_delivery_screen.dart';
import 'screens/payment_history_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SchedulerService.instance.initialize();
  await SchedulerService.instance.restorePendingSchedules();
  runApp(const FlorapriseGoApp());
}

class FlorapriseGoApp extends StatefulWidget {
  const FlorapriseGoApp({super.key});

  @override
  State<FlorapriseGoApp> createState() => _FlorapriseGoAppState();
}

class _FlorapriseGoAppState extends State<FlorapriseGoApp> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    // Handle initial deep link if app was opened from a cold start
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      // Handle error
    }

    // Handle deep links while app is running
    _sub = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    }, onError: (err) {
      // Handle error
    });
  }

  void _handleDeepLink(Uri uri) {
    String? token;

    // Handle custom scheme: floraprise://driver/{token}
    if (uri.scheme == 'floraprise' && uri.host == 'driver') {
      token = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
    }
    // Handle HTTPS: https://api.floraprise.com/api/public/tracking/driver/{token}
    else if (uri.scheme == 'https' && uri.host == 'api.floraprise.com') {
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 5 &&
          pathSegments[0] == 'api' &&
          pathSegments[1] == 'public' &&
          pathSegments[2] == 'tracking' &&
          pathSegments[3] == 'driver') {
        token = pathSegments[4];
      }
    }

    if (token != null &&
        token.isNotEmpty &&
        _navigatorKey.currentContext != null) {
      Navigator.of(_navigatorKey.currentContext!).pushNamed(
        '/driver-delivery',
        arguments: {'token': token},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerRepository = CustomerRepository();
    final categoryRepository = CategoryRepository();
    final inventoryRepository = InventoryRepository();
    final designRepository = DesignRepository();
    final orderRepository = OrderRepository();
    final occasionRepository = OccasionRepository();
    final schedulerRepository = SchedulerRepository();
    final jobRepository = JobRepository();
    final purchaseRepository = PurchaseRepository();
    final associateRepository = AssociateRepository();
    final staffRepository = StaffRepository();
    final mobileAuthService = MobileAuthService();
    final schedulerManager = SchedulerManager(schedulerRepository);
    final languageManager = LanguageManager();
    final printerManager = PrinterManager();

    final orderManager = OrderManager(orderRepository, jobRepository);

    final orderWorkflowManager = OrderWorkflowManager(
      orderManager: orderManager,
      workflowRepository: const OrderWorkflowRepository(),
      associateRepository: associateRepository,
      schedulerManager: schedulerManager,
      whatsappService: OrderWhatsappService(
        orderManager: orderManager,
        jobRepository: jobRepository,
      ),
      printService: OrderPrintService(
        orderManager: orderManager,
        jobRepository: jobRepository,
        printerManager: printerManager,
      ),
    );
    final customerManager = CustomerManager(customerRepository);
    final categoryManager = CategoryManager(categoryRepository);
    final inventoryManager = InventoryManager(inventoryRepository);
    final occasionManager = OccasionManager(occasionRepository);
    final purchaseManager = PurchaseManager(purchaseRepository);
    final associateManager = AssociateManager(associateRepository);
    final staffManager = StaffManager(staffRepository);

    final dashboardManager = DashboardManager(
      orderManager,
      inventoryManager,
      customerManager,
      schedulerRepository,
      occasionManager,
      associateManager,
      staffManager,
    );

    final walkInManager = WalkInManager(
      customerManager: customerManager,
      pricingManager: PricingManager(),
      orderManager: orderManager,
      inventoryManager: inventoryManager,
      schedulerManager: schedulerManager,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => BusinessDataEventBus(),
        ),
        ChangeNotifierProvider(
          create: (_) => AppShellController(),
        ),
        ChangeNotifierProvider(
          create: (_) => LanguageProvider(languageManager)..loadSavedLanguage(),
        ),
        ChangeNotifierProvider(
          create: (_) => VoiceProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(mobileAuthService)..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => LicenseProvider(LicenseService())..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => SubscriptionProvider(
            SubscriptionService(mobileAuthService: mobileAuthService),
          )..initialize(),
        ),
        ChangeNotifierProvider(
          create: (context) => WalkInSessionProvider(
            walkInManager,
            context.read<BusinessDataEventBus>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => OrderProvider(orderManager),
        ),
        ChangeNotifierProvider(
          create: (_) => OrderWorkflowProvider(orderWorkflowManager),
        ),
        ChangeNotifierProvider(
          create: (context) => SchedulerProvider(
            schedulerManager,
            context.read<BusinessDataEventBus>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => DashboardProvider(
            dashboardManager,
            context.read<BusinessDataEventBus>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => OccasionProvider(occasionManager, customerRepository)
            ..loadInitial(),
        ),
        ChangeNotifierProvider(
          create: (context) => InventoryProvider(
            inventoryManager,
            context.read<BusinessDataEventBus>(),
          )..loadProducts(),
        ),
        ChangeNotifierProvider(
          create: (context) => CustomerProvider(
            customerManager,
            context.read<BusinessDataEventBus>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(categoryManager)..loadCategories(),
        ),
        ChangeNotifierProvider(
          create: (_) => DesignProvider(designRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(ProductRepository())..loadProducts(),
        ),
        ChangeNotifierProvider(
          create: (_) => PrinterProvider(
            printerManager,
            contextProvider: () => _navigatorKey.currentState?.overlay?.context,
          )..load(),
        ),
        ChangeNotifierProvider(
          create: (context) => PurchaseProvider(
            purchaseManager,
            context.read<BusinessDataEventBus>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => AssociateProvider(
            associateManager,
            context.read<BusinessDataEventBus>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => StaffProvider(staffManager),
        ),
        ChangeNotifierProvider(
          create: (_) => AttendanceProvider(AttendanceRepository()),
        ),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            title: 'Floraprise',
            debugShowCheckedModeBanner: false,
            locale: languageProvider.currentLocale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('hi'),
              Locale('gu'),
            ],
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF2E7D32),
                brightness: Brightness.light,
              ),
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: ZoomPageTransitionsBuilder(),
                  TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
                  TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
                  TargetPlatform.windows: ZoomPageTransitionsBuilder(),
                  TargetPlatform.linux: ZoomPageTransitionsBuilder(),
                },
              ),
              splashFactory: InkRipple.splashFactory,
              visualDensity: VisualDensity.standard,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
              ),
              bottomSheetTheme: const BottomSheetThemeData(
                showDragHandle: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
              ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            home: const SplashScreen(),
            navigatorKey: _navigatorKey,
            navigatorObservers: [appRouteObserver],
            onGenerateRoute: (settings) {
              if (settings.name == '/driver-delivery') {
                final args = settings.arguments as Map<String, dynamic>?;
                final token = args?['token'] as String?;
                if (token == null || token.isEmpty) {
                  return MaterialPageRoute(
                    builder: (context) => const Scaffold(
                      body: Center(
                        child: Text('Invalid delivery link'),
                      ),
                    ),
                  );
                }
                return MaterialPageRoute(
                  builder: (context) => DriverDeliveryScreen(token: token),
                );
              }
              if (settings.name == '/walkin-sales') {
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => _SubscriptionGate(
                    child: WalkinSalesScreen(
                      prefillCustomerId: args?['prefillCustomerId'],
                      prefillCustomerName: args?['prefillCustomerName'],
                      prefillCustomerPhone: args?['prefillCustomerPhone'],
                      prefillRecipientName: args?['prefillRecipientName'],
                      prefillOccasion: args?['prefillOccasion'],
                    ),
                  ),
                );
              }
              if (settings.name == '/order-workflow') {
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => _SubscriptionGate(
                    child: OrderWorkflowScreen(
                      orderId: args?['orderId'] as int,
                    ),
                  ),
                );
              }
              if (settings.name == '/public-delivery-tracking') {
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => LiveDeliveryTrackingScreen(
                    orderId: args?['orderId'] as int?,
                    assignmentId: args?['assignmentId'] as String?,
                    trackingLink: args?['trackingLink'] as String?,
                    publicView: true,
                  ),
                );
              }
              return null;
            },
            routes: {
              '/dashboard': (context) =>
                  const _SubscriptionGate(child: MainShellScreen()),
              '/business-registration': (context) =>
                  const BusinessRegistrationScreen(),
              '/mobile-register': (context) =>
                  const BusinessRegistrationScreen(),
              '/license-subscription-required': (context) =>
                  const LicenseSubscriptionRequiredScreen(),
              '/subscription': (context) => const SubscriptionScreen(),
              '/payment-history': (context) => const PaymentHistoryScreen(),
              '/backup-restore': (context) => const BackupRestoreScreen(),
              '/shop-details': (context) =>
                  const _SubscriptionGate(child: ShopDetailsScreen()),
              '/share-branding': (context) =>
                  const _SubscriptionGate(child: ShareBrandingSettingsScreen()),
              '/rewards-settings': (context) =>
                  const _SubscriptionGate(child: RewardsSettingsScreen()),
              '/about': (context) => const AboutScreen(),
              '/my-designs': (context) =>
                  const _SubscriptionGate(child: MyDesignsScreen()),
              '/orders': (context) =>
                  const _SubscriptionGate(child: OrdersScreen()),
              '/customers': (context) =>
                  const _SubscriptionGate(child: CustomersScreen()),
              '/staff': (context) =>
                  const _SubscriptionGate(child: StaffManagementScreen()),
              '/reminders': (context) =>
                  const _SubscriptionGate(child: RemindersScreen()),
              '/products': (context) =>
                  const _SubscriptionGate(child: ProductsScreen()),
              '/categories': (context) =>
                  const _SubscriptionGate(child: CategoriesScreen()),
              '/scheduler': (context) =>
                  const _SubscriptionGate(child: SchedulerScreen()),
              '/settings': (context) =>
                  const _SubscriptionGate(child: SettingsScreen()),
              '/inventory': (context) =>
                  const _SubscriptionGate(child: InventoryScreen()),
              '/inventory/voice-entry': (context) =>
                  const _SubscriptionGate(child: VoiceStockEntryScreen()),
              '/production': (context) => const _SubscriptionGate(
                  child: BouquetProductionEntryScreen()),
              '/ready-bouquets': (context) =>
                  const _SubscriptionGate(child: ReadyBouquetInventoryScreen()),
              '/printer-settings': (context) =>
                  const _SubscriptionGate(child: PrinterSettingsScreen()),
              '/printer-test': (context) =>
                  const _SubscriptionGate(child: PrinterTestScreen()),
              '/barcode': (context) =>
                  const _SubscriptionGate(child: BarcodeScreen()),
              '/purchase-list': (context) =>
                  const _SubscriptionGate(child: PurchaseListScreen()),
              '/delivery-workspace': (context) =>
                  const _SubscriptionGate(child: DeliveryWorkspaceScreen()),
              '/draft-orders': (context) =>
                  const _SubscriptionGate(child: DraftOrdersScreen()),
              '/associates': (context) =>
                  const _SubscriptionGate(child: AssociatesScreen()),
              '/attendance': (context) =>
                  const _SubscriptionGate(child: AttendanceHomeScreen()),
              '/attendance/today': (context) =>
                  const _SubscriptionGate(child: AttendanceTodayScreen()),
              '/attendance/mark': (context) =>
                  const _SubscriptionGate(child: AttendanceMarkScreen()),
              '/attendance/monthly': (context) => const _SubscriptionGate(
                  child: AttendanceMonthlySummaryScreen()),
              '/opening-cash': (context) =>
                  const _SubscriptionGate(child: OpeningCashScreen()),
              '/cash-book': (context) =>
                  const _SubscriptionGate(child: CashBookScreen()),
              '/expenses': (context) =>
                  const _SubscriptionGate(child: ExpensesScreen()),
              '/day-closing': (context) =>
                  const _SubscriptionGate(child: DayClosingScreen()),
              '/reports': (context) =>
                  const _SubscriptionGate(child: ReportsScreen()),
              '/reports/sales': (context) =>
                  const _SubscriptionGate(child: SalesReportScreen()),
              '/reports/order-status': (context) =>
                  const _SubscriptionGate(child: OrderStatusReportScreen()),
              '/reports/top-customers': (context) =>
                  const _SubscriptionGate(child: TopCustomersReportScreen()),
              '/reports/rewards': (context) =>
                  const _SubscriptionGate(child: RewardsReportScreen()),
              '/reports/top-products': (context) =>
                  const _SubscriptionGate(child: TopProductsReportScreen()),
              '/reports/low-stock': (context) =>
                  const _SubscriptionGate(child: LowStockReportScreen()),
              '/reports/expenses': (context) =>
                  const _SubscriptionGate(child: ExpenseReportScreen()),
              '/reports/day-closing': (context) =>
                  const _SubscriptionGate(child: DayClosingReportScreen()),
              '/reports/wastage': (context) =>
                  const _SubscriptionGate(child: WastageReportScreen()),
              '/reports/production': (context) =>
                  const _SubscriptionGate(child: ProductionReportScreen()),
            },
          );
        },
      ),
    );
  }
}

class _SubscriptionGate extends StatelessWidget {
  const _SubscriptionGate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Consumer<LicenseProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (provider.state == LicenseProviderState.expired ||
            provider.state == LicenseProviderState.suspended) {
          return const LicenseSubscriptionRequiredScreen();
        }
        return child;
      },
    );
  }
}
