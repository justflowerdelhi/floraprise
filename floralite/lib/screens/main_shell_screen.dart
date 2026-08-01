import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/app_shell_controller.dart';
import '../providers/dashboard_provider.dart';
import '../providers/subscription_provider.dart';
import '../widgets/common_widgets.dart';
import 'about_screen.dart';
import 'associates_screen.dart';
import 'attendance_home_screen.dart';
import 'attendance_mark_screen.dart';
import 'attendance_monthly_summary_screen.dart';
import 'attendance_today_screen.dart';
import 'backup_restore_screen.dart';
import 'barcode_screen.dart';
import 'cash_book_screen.dart';
import 'categories_screen.dart';
import 'customers_screen.dart';
import 'dashboard_screen.dart';
import 'day_closing_screen.dart';
import 'delivery_workspace_screen.dart';
import 'draft_orders_screen.dart';
import 'expenses_screen.dart';
import 'inventory_screen.dart';
import 'voice_stock_entry_screen.dart';
import 'my_designs_screen.dart';
import 'order_workflow_screen.dart';
import 'orders_screen.dart';
import 'opening_cash_screen.dart';
import 'payment_history_screen.dart';
import 'products_screen.dart';
import 'bouquet_production_entry_screen.dart';
import 'printer_settings_screen.dart';
import 'printer_test_screen.dart';
import 'purchase_list_screen.dart';
import 'ready_bouquet_inventory_screen.dart';
import 'reminders_screen.dart';
import 'reports/day_closing_report_screen.dart';
import 'reports/expense_report_screen.dart';
import 'reports/low_stock_report_screen.dart';
import 'reports/order_status_report_screen.dart';
import 'reports/production_report_screen.dart';
import 'reports/sales_report_screen.dart';
import 'reports/top_customers_report_screen.dart';
import 'reports/top_products_report_screen.dart';
import 'reports/wastage_report_screen.dart';
import 'reports_screen.dart';
import 'scheduler_screen.dart';
import 'settings_screen.dart';
import 'share_branding_settings_screen.dart';
import 'shop_details_screen.dart';
import 'staff_management_screen.dart';
import 'subscription_screen.dart';
import 'walkin_sales_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  DateTime? _lastBackPressedAt;

  static const _tabs = AppShellTab.values;
  static const _rootRoutes = [
    '/dashboard',
    '/_orders-tab',
    '/walkin-sales',
    '/_inventory-tab',
    '/_money-tab',
  ];

  static const Set<String> _readOnlyBlockedRoutes = {
    '/walkin-sales',
    '/inventory/voice-entry',
    '/production',
    '/purchase-list',
    '/attendance/mark',
    '/opening-cash',
    '/expenses',
    '/day-closing',
  };

  static const Set<String> _lockedAllowedRoutes = {
    '/dashboard',
    '/subscription',
    '/payment-history',
    '/backup-restore',
    '/about',
  };

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppShellController>();
    final selectedIndex = controller.selectedIndex;
    final subscriptionProvider = context.watch<SubscriptionProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: Scaffold(
        body: Column(
          children: [
            if (subscriptionProvider.isGracePeriod)
              _GracePeriodBanner(
                message: subscriptionProvider.gracePeriodMessage,
              ),
            Expanded(
              child: Navigator(
                key: _navigatorKey,
                initialRoute: _rootRoutes[AppShellTab.home.index],
                onGenerateRoute: _onGenerateRoute,
              ),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            final tab = _tabs[index];
            final rootRoute = _rootRoutes[index];
            if (tab == AppShellTab.home &&
                controller.selectedTab == AppShellTab.home) {
              context.read<DashboardProvider>().refresh();
              return;
            }
            controller.selectTab(tab);
            _navigatorKey.currentState?.pushNamedAndRemoveUntil(
              rootRoute,
              (route) => false,
            );
            if (tab == AppShellTab.home) {
              context.read<DashboardProvider>().refresh();
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt_rounded),
              label: 'Orders',
            ),
            NavigationDestination(
              icon: Icon(Icons.shopping_cart_outlined),
              selectedIcon: Icon(Icons.shopping_cart_rounded),
              label: 'POS',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2_rounded),
              label: 'Inventory',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Accounts',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleBackNavigation() async {
    final nestedNavigator = _navigatorKey.currentState;
    if (nestedNavigator == null) return;

    if (await nestedNavigator.maybePop()) {
      return;
    }

    if (!mounted) return;
    final controller = context.read<AppShellController>();
    if (controller.selectedTab != AppShellTab.home) {
      _goHome();
      return;
    }

    final now = DateTime.now();
    final shouldExit = _lastBackPressedAt != null &&
        now.difference(_lastBackPressedAt!) < const Duration(seconds: 2);
    if (shouldExit) {
      SystemNavigator.pop();
      return;
    }

    _lastBackPressedAt = now;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Press back again to exit Floraprise.')),
    );
  }

  void _goHome() {
    context.read<AppShellController>().selectTab(AppShellTab.home);
    _navigatorKey.currentState?.pushNamedAndRemoveUntil(
      _rootRoutes[AppShellTab.home.index],
      (route) => false,
    );
    context.read<DashboardProvider>().refresh();
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name;
    if (routeName == '/_orders-tab') {
      return _materialRoute(settings, const _OrdersTab());
    }
    if (routeName == '/_inventory-tab') {
      return _materialRoute(settings, const _InventoryTab());
    }
    if (routeName == '/_money-tab') {
      return _materialRoute(settings, const _MoneyTab());
    }
    return _businessRoute(settings);
  }

  MaterialPageRoute<dynamic> _businessRoute(RouteSettings settings) {
    final routeName = settings.name;
    final subscription = context.read<SubscriptionProvider>();
    if (routeName != null &&
        subscription.isLocked &&
        !_lockedAllowedRoutes.contains(routeName)) {
      return _materialRoute(settings, const SubscriptionScreen());
    }

    if (routeName != null &&
        subscription.hasWriteRestrictions &&
        _readOnlyBlockedRoutes.contains(routeName)) {
      return _materialRoute(settings, const SubscriptionScreen());
    }

    if (routeName == '/walkin-sales') {
      final args = settings.arguments as Map<String, dynamic>?;
      return _materialRoute(
        settings,
        WalkinSalesScreen(
          prefillCustomerId: args?['prefillCustomerId'],
          prefillCustomerName: args?['prefillCustomerName'],
          prefillCustomerPhone: args?['prefillCustomerPhone'],
          prefillRecipientName: args?['prefillRecipientName'],
          prefillOccasion: args?['prefillOccasion'],
        ),
      );
    }
    if (routeName == '/order-workflow') {
      final args = settings.arguments as Map<String, dynamic>?;
      return _materialRoute(
        settings,
        OrderWorkflowScreen(orderId: args?['orderId'] as int),
      );
    }

    return _materialRoute(
      settings,
      switch (routeName) {
        '/dashboard' => const DashboardScreen(),
        '/subscription' => const SubscriptionScreen(),
        '/payment-history' => const PaymentHistoryScreen(),
        '/backup-restore' => const BackupRestoreScreen(),
        '/shop-details' => const ShopDetailsScreen(),
        '/about' => const AboutScreen(),
        '/my-designs' => const MyDesignsScreen(),
        '/orders' => const OrdersScreen(),
        '/delivery-workspace' => const DeliveryWorkspaceScreen(),
        '/customers' => const CustomersScreen(),
        '/staff' => const StaffManagementScreen(),
        '/reminders' => const RemindersScreen(),
        '/products' => const ProductsScreen(),
        '/categories' => const CategoriesScreen(),
        '/scheduler' => const SchedulerScreen(),
        '/settings' => const SettingsScreen(),
        '/share-branding' => const ShareBrandingSettingsScreen(),
        '/inventory' => const InventoryScreen(),
        '/inventory/voice-entry' => const VoiceStockEntryScreen(),
        '/production' => const BouquetProductionEntryScreen(),
        '/ready-bouquets' => const ReadyBouquetInventoryScreen(),
        '/printer-settings' => const PrinterSettingsScreen(),
        '/printer-test' => const PrinterTestScreen(),
        '/barcode' => const BarcodeScreen(),
        '/purchase-list' => const PurchaseListScreen(),
        '/draft-orders' => const DraftOrdersScreen(),
        '/associates' => const AssociatesScreen(),
        '/attendance' => const AttendanceHomeScreen(),
        '/attendance/today' => const AttendanceTodayScreen(),
        '/attendance/mark' => const AttendanceMarkScreen(),
        '/attendance/monthly' => const AttendanceMonthlySummaryScreen(),
        '/opening-cash' => const OpeningCashScreen(),
        '/cash-book' => const CashBookScreen(),
        '/expenses' => const ExpensesScreen(),
        '/day-closing' => const DayClosingScreen(),
        '/reports' => const ReportsScreen(),
        '/reports/sales' => const SalesReportScreen(),
        '/reports/order-status' => const OrderStatusReportScreen(),
        '/reports/top-customers' => const TopCustomersReportScreen(),
        '/reports/top-products' => const TopProductsReportScreen(),
        '/reports/low-stock' => const LowStockReportScreen(),
        '/reports/expenses' => const ExpenseReportScreen(),
        '/reports/day-closing' => const DayClosingReportScreen(),
        '/reports/wastage' => const WastageReportScreen(),
        '/reports/production' => const ProductionReportScreen(),
        _ => const DashboardScreen(),
      },
    );
  }

  MaterialPageRoute<dynamic> _materialRoute(
    RouteSettings settings,
    Widget child,
  ) {
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (_) => child,
    );
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context) {
    return _WorkspaceHub(
      title: 'Orders',
      subtitle: 'Manage today\'s selling and customer orders.',
      children: [
        _WorkspaceAction(
          icon: Icons.point_of_sale_rounded,
          title: 'Walk-in Sales',
          subtitle: 'Start a counter sale.',
          onTap: () => Navigator.pushNamed(context, '/walkin-sales'),
        ),
        _WorkspaceAction(
          icon: Icons.local_shipping_rounded,
          title: 'Delivery Orders',
          subtitle: 'Create or review delivery work.',
          onTap: () => Navigator.pushNamed(context, '/walkin-sales'),
        ),
        _WorkspaceAction(
          icon: Icons.shopping_bag_rounded,
          title: 'Pickup Orders',
          subtitle: 'Create or review pickup work.',
          onTap: () => Navigator.pushNamed(context, '/walkin-sales'),
        ),
        _WorkspaceAction(
          icon: Icons.receipt_long_rounded,
          title: 'Order History',
          subtitle: 'Search and manage all orders.',
          onTap: () => Navigator.pushNamed(context, '/orders'),
        ),
        _WorkspaceAction(
          icon: Icons.search_rounded,
          title: 'Search Orders',
          subtitle: 'Find by customer, order number, or date.',
          onTap: () => Navigator.pushNamed(context, '/orders'),
        ),
        _WorkspaceAction(
          icon: Icons.location_searching_rounded,
          title: 'Delivery Workspace',
          subtitle: 'Track active, completed, and cancelled deliveries.',
          onTap: () => Navigator.pushNamed(context, '/delivery-workspace'),
        ),
      ],
    );
  }
}

class _InventoryTab extends StatelessWidget {
  const _InventoryTab();

  @override
  Widget build(BuildContext context) {
    return _WorkspaceHub(
      title: 'Inventory',
      subtitle: 'Products, stock, purchases, production, and suppliers.',
      children: [
        _WorkspaceAction(
          icon: Icons.inventory_2_rounded,
          title: 'Stock',
          subtitle: 'View stock and record stock actions.',
          onTap: () => Navigator.pushNamed(context, '/inventory'),
        ),
        _WorkspaceAction(
          icon: Icons.mic_outlined,
          title: 'Voice Stock Entry',
          subtitle: 'Add stock with voice: quantity, product, price.',
          onTap: () => Navigator.pushNamed(context, '/inventory/voice-entry'),
        ),
        _WorkspaceAction(
          icon: Icons.spa_rounded,
          title: 'Product List',
          subtitle: 'Manage product catalogue and barcodes.',
          onTap: () => Navigator.pushNamed(context, '/products'),
        ),
        _WorkspaceAction(
          icon: Icons.shopping_cart_rounded,
          title: 'Create Purchase List',
          subtitle: 'Prepare and track market purchase lists.',
          onTap: () => Navigator.pushNamed(context, '/purchase-list'),
        ),
        _WorkspaceAction(
          icon: Icons.precision_manufacturing_outlined,
          title: 'Production',
          subtitle: 'Produce bouquets from recipes.',
          onTap: () => Navigator.pushNamed(context, '/production'),
        ),
        _WorkspaceAction(
          icon: Icons.local_florist_rounded,
          title: 'Ready Bouquets',
          subtitle: 'Manage produced bouquets.',
          onTap: () => Navigator.pushNamed(context, '/ready-bouquets'),
        ),
        _WorkspaceAction(
          icon: Icons.delete_outline_rounded,
          title: 'Wastage',
          subtitle: 'Review wastage reports.',
          onTap: () => Navigator.pushNamed(context, '/reports/wastage'),
        ),
        _WorkspaceAction(
          icon: Icons.business_rounded,
          title: 'Suppliers',
          subtitle: 'Manage supplier and associate records.',
          onTap: () => Navigator.pushNamed(context, '/associates'),
        ),
      ],
    );
  }
}

class _MoneyTab extends StatelessWidget {
  const _MoneyTab();

  @override
  Widget build(BuildContext context) {
    return _WorkspaceHub(
      title: 'Accounts',
      subtitle: 'Expenses, cash, day close, and financial reports.',
      children: [
        _WorkspaceAction(
          icon: Icons.receipt_rounded,
          title: 'Expenses',
          subtitle: 'Add and review shop expenses.',
          onTap: () => Navigator.pushNamed(context, '/expenses'),
        ),
        _WorkspaceAction(
          icon: Icons.payments_rounded,
          title: 'Payments',
          subtitle: 'Review sales and pending payments.',
          onTap: () => Navigator.pushNamed(context, '/reports/sales'),
        ),
        _WorkspaceAction(
          icon: Icons.account_balance_wallet_rounded,
          title: 'Cash Book',
          subtitle: 'Track cash in and cash out.',
          onTap: () => Navigator.pushNamed(context, '/cash-book'),
        ),
        _WorkspaceAction(
          icon: Icons.nights_stay_rounded,
          title: 'Day Close',
          subtitle: 'Close and review the day.',
          onTap: () => Navigator.pushNamed(context, '/day-closing'),
        ),
        _WorkspaceAction(
          icon: Icons.bar_chart_rounded,
          title: 'Financial Reports',
          subtitle: 'Sales, expenses, day closing, and more.',
          onTap: () => Navigator.pushNamed(context, '/reports'),
        ),
        _WorkspaceAction(
          icon: Icons.print_rounded,
          title: 'Printer Settings',
          subtitle: 'Bluetooth printer, receipts, and print queue.',
          onTap: () => Navigator.pushNamed(context, '/printer-settings'),
        ),
      ],
    );
  }
}

class _WorkspaceHub extends StatelessWidget {
  const _WorkspaceHub({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<_WorkspaceAction> children;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset),
          children: [
            Text(
              subtitle,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ...children.expand(
              (child) => [child, const SizedBox(height: 12)],
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceAction extends StatelessWidget {
  const _WorkspaceAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _GracePeriodBanner extends StatelessWidget {
  const _GracePeriodBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        border: Border(
          bottom: BorderSide(color: Colors.amber.shade300, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Colors.amber.shade800, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.amber.shade900,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/subscription'),
            child: const Text('Renew Now'),
          ),
        ],
      ),
    );
  }
}
