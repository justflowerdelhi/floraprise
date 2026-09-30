import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'dashboard_summary.dart';

/// Represents an individual navigation item shared between Home Workspaces
/// and Desktop Left Sidebar Navigation.
class WorkspaceDestination {
  const WorkspaceDestination({
    required this.id,
    required this.title,
    required this.route,
    required this.icon,
    this.selectedIcon,
    this.localizedTitleBuilder,
    this.badgeSelector,
    this.children = const [],
  });

  final String id;
  final String title;
  final String route;
  final IconData icon;
  final IconData? selectedIcon;
  final String Function(AppLocalizations l10n)? localizedTitleBuilder;
  final int Function(DashboardSummary summary)? badgeSelector;
  final List<WorkspaceDestination> children;

  bool get hasChildren => children.isNotEmpty;

  String getLabel(BuildContext context) {
    if (localizedTitleBuilder != null) {
      final l10n = AppLocalizations.of(context);
      if (l10n != null) {
        return localizedTitleBuilder!(l10n);
      }
    }
    return title;
  }

  int getBadge(DashboardSummary summary) {
    return badgeSelector != null ? badgeSelector!(summary) : 0;
  }
}

/// Represents a grouped section of workspace destinations.
class WorkspaceSectionData {
  const WorkspaceSectionData({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final List<WorkspaceDestination> items;
}

/// Authoritative single source of truth for all Floraprise Pro Web navigation.
class WorkspaceNavigation {
  const WorkspaceNavigation._();

  static const homeDestination = WorkspaceDestination(
    id: 'home',
    title: 'Home',
    route: '/dashboard',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
  );

  static final List<WorkspaceSectionData> sections = [
    WorkspaceSectionData(
      id: 'sales_and_orders',
      title: 'SALES & ORDERS',
      icon: Icons.shopping_bag_rounded,
      color: const Color(0xFFD97706),
      items: [
        WorkspaceDestination(
          id: 'pos',
          title: 'POS',
          route: '/walkin-sales',
          icon: Icons.point_of_sale_rounded,
          localizedTitleBuilder: (l10n) => 'POS',
        ),
        WorkspaceDestination(
          id: 'orders',
          title: 'Orders',
          route: '/orders',
          icon: Icons.receipt_long_rounded,
          localizedTitleBuilder: (l10n) => l10n.orders,
          badgeSelector: (s) => s.pendingOrders,
          children: [
            const WorkspaceDestination(
              id: 'orders_walkin',
              title: 'Walkin Orders',
              route: '/orders/walkin',
              icon: Icons.storefront_outlined,
              selectedIcon: Icons.storefront_rounded,
            ),
            WorkspaceDestination(
              id: 'orders_delivery',
              title: 'Delivery Orders',
              route: '/orders/delivery',
              icon: Icons.local_shipping_outlined,
              selectedIcon: Icons.local_shipping_rounded,
              badgeSelector: (s) => s.todayDeliveryCount,
            ),
            WorkspaceDestination(
              id: 'orders_pickup',
              title: 'Pickup Orders',
              route: '/orders/pickup',
              icon: Icons.shopping_bag_outlined,
              selectedIcon: Icons.shopping_bag_rounded,
              badgeSelector: (s) => s.todayPickupCount,
            ),
            const WorkspaceDestination(
              id: 'orders_search',
              title: 'Search Orders',
              route: '/orders/search',
              icon: Icons.search_rounded,
            ),
          ],
        ),
        WorkspaceDestination(
          id: 'scheduled_tasks',
          title: 'Scheduled Tasks',
          route: '/scheduler',
          icon: Icons.event_note_rounded,
          badgeSelector: (s) => s.todayTaskCount,
        ),
        const WorkspaceDestination(
          id: 'associates',
          title: 'Associates',
          route: '/associates',
          icon: Icons.business_rounded,
        ),
        const WorkspaceDestination(
          id: 'delivery_workspace',
          title: 'Delivery Workspace',
          route: '/delivery-workspace',
          icon: Icons.location_searching_rounded,
        ),
      ],
    ),
    WorkspaceSectionData(
      id: 'crm',
      title: 'CRM',
      icon: Icons.support_agent_rounded,
      color: const Color(0xFF0D9488),
      items: [
        WorkspaceDestination(
          id: 'crm_today',
          title: 'Today',
          route: '/crm',
          icon: Icons.today_outlined,
          selectedIcon: Icons.today_rounded,
          localizedTitleBuilder: (l10n) => l10n.crmToday,
          badgeSelector: (s) => s.todayFollowUps,
        ),
        WorkspaceDestination(
          id: 'crm_enquiries',
          title: 'Enquiries',
          route: '/crm/enquiries',
          icon: Icons.question_answer_outlined,
          selectedIcon: Icons.question_answer_rounded,
          localizedTitleBuilder: (l10n) => l10n.crmEnquiries,
        ),
        WorkspaceDestination(
          id: 'crm_customers',
          title: 'Customers',
          route: '/crm/customers',
          icon: Icons.people_outline_rounded,
          selectedIcon: Icons.people_rounded,
          localizedTitleBuilder: (l10n) => l10n.customers,
        ),
        WorkspaceDestination(
          id: 'crm_occasions',
          title: 'Occasions',
          route: '/crm/occasions',
          icon: Icons.cake_outlined,
          selectedIcon: Icons.cake_rounded,
          localizedTitleBuilder: (l10n) => l10n.crmOccasions,
        ),
      ],
    ),
    WorkspaceSectionData(
      id: 'catalogue_and_inventory',
      title: 'CATALOGUE & INVENTORY',
      icon: Icons.local_florist_rounded,
      color: const Color(0xFF059669),
      items: [
        const WorkspaceDestination(
          id: 'categories',
          title: 'Categories',
          route: '/categories',
          icon: Icons.category_rounded,
        ),
        WorkspaceDestination(
          id: 'products',
          title: 'Products',
          route: '/products',
          icon: Icons.spa_rounded,
          localizedTitleBuilder: (l10n) => l10n.products,
        ),
        const WorkspaceDestination(
          id: 'my_designs',
          title: 'My Designs',
          route: '/my-designs',
          icon: Icons.palette_rounded,
        ),
        WorkspaceDestination(
          id: 'inventory',
          title: 'Inventory',
          route: '/inventory',
          icon: Icons.inventory_2_rounded,
          localizedTitleBuilder: (l10n) => l10n.inventoryTitle,
          badgeSelector: (s) => s.lowStockItems + s.outOfStockItems,
        ),
        const WorkspaceDestination(
          id: 'production',
          title: 'Production',
          route: '/production',
          icon: Icons.precision_manufacturing_outlined,
          selectedIcon: Icons.precision_manufacturing_rounded,
        ),
        const WorkspaceDestination(
          id: 'ready_bouquets',
          title: 'Ready Bouquets',
          route: '/ready-bouquets',
          icon: Icons.local_florist_outlined,
          selectedIcon: Icons.local_florist_rounded,
        ),
        const WorkspaceDestination(
          id: 'library',
          title: 'Floraprise Library',
          route: '/library',
          icon: Icons.menu_book_rounded,
        ),
        WorkspaceDestination(
          id: 'purchase_list',
          title: 'Create Purchase List',
          route: '/purchase-list',
          icon: Icons.shopping_cart_rounded,
          badgeSelector: (s) => s.todayPurchaseListCount,
        ),
      ],
    ),
    WorkspaceSectionData(
      id: 'team',
      title: 'TEAM',
      icon: Icons.groups_2_rounded,
      color: const Color(0xFF2563EB),
      items: [
        WorkspaceDestination(
          id: 'staff',
          title: 'Staff',
          route: '/staff',
          icon: Icons.badge_rounded,
          localizedTitleBuilder: (l10n) => l10n.staff,
        ),
        WorkspaceDestination(
          id: 'attendance',
          title: 'Attendance',
          route: '/attendance',
          icon: Icons.event_available_rounded,
          localizedTitleBuilder: (l10n) => l10n.attendance,
          badgeSelector: (s) => s.unmarkedAttendanceCount,
        ),
      ],
    ),
    const WorkspaceSectionData(
      id: 'accounting',
      title: 'ACCOUNTING',
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFF7C3AED),
      items: [
        WorkspaceDestination(
          id: 'opening_cash',
          title: 'Opening Cash',
          route: '/opening-cash',
          icon: Icons.attach_money_rounded,
        ),
        WorkspaceDestination(
          id: 'cash_book',
          title: 'Cash Book',
          route: '/cash-book',
          icon: Icons.receipt_long_rounded,
        ),
        WorkspaceDestination(
          id: 'expenses',
          title: 'Expenses',
          route: '/expenses',
          icon: Icons.receipt_rounded,
        ),
        WorkspaceDestination(
          id: 'day_closing',
          title: 'Day Closing',
          route: '/day-closing',
          icon: Icons.nights_stay_rounded,
        ),
        WorkspaceDestination(
          id: 'reports',
          title: 'Reports',
          route: '/reports',
          icon: Icons.bar_chart_rounded,
        ),
      ],
    ),
    WorkspaceSectionData(
      id: 'utilities',
      title: 'UTILITIES',
      icon: Icons.tune_rounded,
      color: const Color(0xFF64748B),
      items: [
        WorkspaceDestination(
          id: 'reminders',
          title: 'Reminders',
          route: '/reminders',
          icon: Icons.notifications_rounded,
          localizedTitleBuilder: (l10n) => l10n.reminders,
          badgeSelector: (s) => s.todayFollowUps,
        ),
        WorkspaceDestination(
          id: 'settings',
          title: 'Settings',
          route: '/settings',
          icon: Icons.settings_rounded,
          localizedTitleBuilder: (l10n) => l10n.settingsTitle,
        ),
      ],
    ),
  ];

  /// Flat list of all workspace destinations (including Home and child destinations).
  static List<WorkspaceDestination> get allDestinations => [
        homeDestination,
        for (final section in sections)
          for (final item in section.items) ...[
            item,
            ...item.children,
          ],
      ];

  /// Find destination by route.
  static WorkspaceDestination? findByRoute(String route) {
    if (route == homeDestination.route) return homeDestination;
    for (final section in sections) {
      for (final item in section.items) {
        if (item.route == route) return item;
        for (final child in item.children) {
          if (child.route == route) return child;
        }
      }
    }
    return null;
  }
}
