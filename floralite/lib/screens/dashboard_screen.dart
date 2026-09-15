import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repositories/cloud_order_repository.dart';
import '../data/repositories/order_repository.dart';
import '../data/repositories/ready_bouquet_repository.dart';
import '../data/repositories/scheduler_repository.dart';
import '../managers/business_settings_manager.dart';
import '../models/dashboard_summary.dart';
import '../models/order_workspace_models.dart';
import '../models/scheduler_task.dart';
import '../models/workspace_destinations.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/license_provider.dart';
import '../providers/storage_mode_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/app_route_observer.dart';
import '../services/delivery_tracking_service.dart';
import '../widgets/app_header.dart';
import '../widgets/common_widgets.dart';
import '../widgets/dashboard/dashboard_attention_section.dart';
import '../widgets/dashboard/dashboard_deliveries_panel.dart';
import '../widgets/dashboard/dashboard_hero_header.dart';
import '../widgets/dashboard/dashboard_inventory_health.dart';
import '../widgets/dashboard/dashboard_kpi_section.dart';
import '../widgets/dashboard/dashboard_orders_stream.dart';

const double _kSectionSpacing = 22;
const double _kGridSpacing = 16;

const Color _successColor = Color(0xFF2E7D32);
const Color _pendingColor = Color(0xFFEF6C00);
const Color _urgentColor = Color(0xFFC62828);
const Color _warningColor = Color(0xFFF57C00);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver, RouteAware {
  final DeliveryTrackingService _deliveryTrackingService =
      DeliveryTrackingService();
  final SchedulerRepository _schedulerRepository = SchedulerRepository();
  final BusinessSettingsManager _businessSettingsManager =
      BusinessSettingsManager();
  final CloudOrderRepository _cloudOrderRepository = CloudOrderRepository();
  final OrderRepository _orderRepository = OrderRepository();

  bool _subscribedToRouteObserver = false;
  String _shopName = '';

  List<OrderListItem> _todayOrders = const [];
  bool _ordersLoading = false;

  List<DeliveryWorkspaceRecord> _activeDeliveries = const [];
  bool _deliveriesLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          context.read<DashboardProvider>().loadSummary(showLoading: true);
        } catch (_) {}
        try {
          context.read<LicenseProvider>().heartbeat();
        } catch (_) {}
        try {
          context.read<InventoryProvider>().loadProducts();
        } catch (_) {}
        _loadBusinessIdentity();
        _loadTodayOrders();
        _loadDeliveries();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_subscribedToRouteObserver) return;
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic>) {
      appRouteObserver.subscribe(this, route);
      _subscribedToRouteObserver = true;
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _refreshWhenVisible();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshWhenVisible();
    }
  }

  void _refreshWhenVisible() {
    if (!mounted) return;
    context.read<LicenseProvider>().heartbeat();
    context.read<DashboardProvider>().refresh();
    context.read<InventoryProvider>().loadProducts();
    _loadBusinessIdentity();
    _loadTodayOrders();
    _loadDeliveries();
  }

  Future<void> _loadBusinessIdentity() async {
    try {
      final settings = await _businessSettingsManager.load();
      if (!mounted) return;
      setState(() {
        _shopName = settings.shopName.trim();
      });
    } catch (_) {}
  }

  Future<void> _loadTodayOrders() async {
    if (!mounted) return;
    setState(() => _ordersLoading = true);
    try {
      bool isCloud = kIsWeb;
      try {
        isCloud = context.read<StorageModeProvider>().isCloud || kIsWeb;
      } catch (_) {}
      final now = DateTime.now();
      final todayFilter = OrderWorkspaceFilters(selectedDate: now);
      final List<OrderListItem> orders;
      if (isCloud) {
        orders = await _cloudOrderRepository.getWorkspace(
          tab: 'all',
          searchQuery: '',
          filters: todayFilter,
          limit: 10,
        );
      } else {
        orders = await _orderRepository.getOrdersForWorkspace(
          tab: 'all',
          searchQuery: '',
          filters: todayFilter,
          limit: 10,
        );
      }
      if (!mounted) return;
      setState(() {
        _todayOrders = orders;
        _ordersLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _ordersLoading = false);
    }
  }

  Future<void> _loadDeliveries() async {
    if (!mounted) return;
    setState(() => _deliveriesLoading = true);
    try {
      final deliveries = await _deliveryTrackingService.getActiveDeliveries();
      if (!mounted) return;
      setState(() {
        _activeDeliveries = deliveries;
        _deliveriesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _deliveriesLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;
    final authProvider = context.watch<AuthProvider?>();
    final ownerName = authProvider?.bootstrap?['user']?['fullName'] as String?;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F5),
      appBar: const AppHeader(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 28 : 16,
            isDesktop ? 20 : 12,
            isDesktop ? 28 : 16,
            28 + bottomInset,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Subscription Banner
                  _buildSubscriptionBanner(context),

                  // 2. Botanical Hero & Quick Actions
                  DashboardHeroHeader(
                    shopName: _shopName,
                    ownerName: ownerName,
                    onNewSale: () => Navigator.pushNamed(context, '/walkin-sales'),
                    onNewOrder: () => Navigator.pushNamed(context, '/orders'),
                    onAddProduct: () => Navigator.pushNamed(context, '/products'),
                    onDeliveryMap: () =>
                        Navigator.pushNamed(context, '/delivery-workspace'),
                  ),
                  const SizedBox(height: _kSectionSpacing),

                  // 3. Business Performance KPI Section
                  Consumer<DashboardProvider>(
                    builder: (context, dashboard, _) {
                      return DashboardKpiSection(
                        summary: dashboard.summary,
                        onSalesTap: () =>
                            Navigator.pushNamed(context, '/reports/sales'),
                        onOrdersTap: () =>
                            Navigator.pushNamed(context, '/orders'),
                        onDeliveriesTap: () =>
                            Navigator.pushNamed(context, '/delivery-workspace'),
                        onExpensesTap: () =>
                            Navigator.pushNamed(context, '/expenses'),
                      );
                    },
                  ),
                  const SizedBox(height: _kSectionSpacing),

                  // 4. Operational Stream (Desktop Two-Column Grid vs Mobile Stack)
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Attention + Orders Feed (~58% width)
                        Expanded(
                          flex: 58,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Consumer<DashboardProvider>(
                                builder: (context, dashboard, _) {
                                  return DashboardAttentionSection(
                                    summary: dashboard.summary,
                                    onInventoryTap: () =>
                                        Navigator.pushNamed(context, '/inventory'),
                                    onOrdersTap: () =>
                                        Navigator.pushNamed(context, '/orders'),
                                    onDeliveriesTap: () => Navigator.pushNamed(
                                        context, '/delivery-workspace'),
                                    onPaymentsTap: () =>
                                        Navigator.pushNamed(context, '/reminders'),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              DashboardOrdersStream(
                                orders: _todayOrders,
                                isLoading: _ordersLoading,
                                onViewAllOrders: () =>
                                    Navigator.pushNamed(context, '/orders'),
                                onOrderTap: (_) =>
                                    Navigator.pushNamed(context, '/orders'),
                                onNewSale: () =>
                                    Navigator.pushNamed(context, '/walkin-sales'),
                              ),
                              _buildReadyBouquetAttention(context),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),

                        // Right Column: Deliveries + Inventory Health + Tasks (~42% width)
                        Expanded(
                          flex: 42,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DashboardDeliveriesPanel(
                                deliveries: _activeDeliveries,
                                isLoading: _deliveriesLoading,
                                onViewWorkspace: () => Navigator.pushNamed(
                                    context, '/delivery-workspace'),
                              ),
                              const SizedBox(height: 20),
                              const _DashboardInventorySection(),
                              const SizedBox(height: 20),
                              _buildTaskSections(context),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    // Mobile single-column flow
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Consumer<DashboardProvider>(
                          builder: (context, dashboard, _) {
                            return DashboardAttentionSection(
                              summary: dashboard.summary,
                              onInventoryTap: () =>
                                  Navigator.pushNamed(context, '/inventory'),
                              onOrdersTap: () =>
                                  Navigator.pushNamed(context, '/orders'),
                              onDeliveriesTap: () => Navigator.pushNamed(
                                  context, '/delivery-workspace'),
                              onPaymentsTap: () =>
                                  Navigator.pushNamed(context, '/reminders'),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        DashboardOrdersStream(
                          orders: _todayOrders,
                          isLoading: _ordersLoading,
                          onViewAllOrders: () =>
                              Navigator.pushNamed(context, '/orders'),
                          onOrderTap: (_) =>
                              Navigator.pushNamed(context, '/orders'),
                          onNewSale: () =>
                              Navigator.pushNamed(context, '/walkin-sales'),
                        ),
                        const SizedBox(height: 16),
                        DashboardDeliveriesPanel(
                          deliveries: _activeDeliveries,
                          isLoading: _deliveriesLoading,
                          onViewWorkspace: () => Navigator.pushNamed(
                              context, '/delivery-workspace'),
                        ),
                        const SizedBox(height: 16),
                        const _DashboardInventorySection(),
                        const SizedBox(height: 16),
                        _buildTaskSections(context),
                        _buildReadyBouquetAttention(context),
                        const SizedBox(height: 16),
                        // Mobile retains workspace navigation tiles since there is no left sidebar on phone
                        _buildWorkspaces(context),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionBanner(BuildContext context) {
    return Selector<SubscriptionProvider,
        ({String title, String message, bool critical})?>(
      selector: (_, provider) {
        final access = provider.access;
        if (access == null) return null;
        final now = DateTime.now();
        final daysRemaining = access.daysRemaining(now);
        final showTrial = access.isTrial;
        final showPaidReminder = !access.isTrial && daysRemaining <= 30;
        if (!showTrial && !showPaidReminder) return null;
        return (
          title: access.isTrial ? 'Free Trial' : 'Subscription',
          message: access.expiryReminder(now),
          critical: daysRemaining <= 3,
        );
      },
      builder: (context, banner, child) {
        if (banner == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AppCard(
            backgroundColor: banner.critical
                ? const Color(0xFFFFEBEE)
                : const Color(0xFFFFF8E1),
            onTap: () => Navigator.pushNamed(context, '/subscription'),
            child: Row(
              children: [
                Icon(
                  Icons.local_florist_rounded,
                  color: banner.critical ? _urgentColor : _warningColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        banner.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(banner.message),
                    ],
                  ),
                ),
                const Text(
                  'Renew',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReadyBouquetAttention(BuildContext context) {
    return FutureBuilder<List<ReadyBouquetSummary>>(
      future: ReadyBouquetRepository().getAttentionBouquets(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final items = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const _SectionTitle(title: 'Bouquets Requiring Attention'),
            const SizedBox(height: 10),
            ...items.map((item) => _ReadyBouquetAttentionCard(item: item)),
          ],
        );
      },
    );
  }

  Widget _buildTaskSections(BuildContext context) {
    return FutureBuilder<SchedulerDashboardBuckets>(
      future: _schedulerRepository.getDashboardBuckets(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final buckets = snapshot.data!;
        if (buckets.overdue.isEmpty &&
            buckets.dueSoon.isEmpty &&
            buckets.completed.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7DF), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.event_note_rounded,
                        color: Color(0xFFD97706),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Task Reminders',
                      style: TextStyle(
                        color: Color(0xFF1E2922),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => Navigator.pushNamed(context, '/scheduler'),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Scheduler',
                              style: TextStyle(
                                color: Color(0xFFD97706),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 11,
                              color: Color(0xFFD97706),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFEAECE6)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTaskBucket('Overdue', buckets.overdue, _urgentColor),
                    if (buckets.overdue.isNotEmpty &&
                        (buckets.dueSoon.isNotEmpty ||
                            buckets.completed.isNotEmpty))
                      const Divider(height: 20),
                    _buildTaskBucket('Due Soon', buckets.dueSoon, _pendingColor),
                    if (buckets.dueSoon.isNotEmpty &&
                        buckets.completed.isNotEmpty)
                      const Divider(height: 20),
                    _buildTaskBucket(
                        'Completed', buckets.completed, _successColor),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskBucket(
    String title,
    List<SchedulerTask> tasks,
    Color color,
  ) {
    if (tasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 8),
        ...tasks.map(
          (task) => ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title:
                Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(_formatTaskTime(task)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.pushNamed(
              context,
              '/scheduler',
              arguments: {'focus': 'todayScheduledTasks'},
            ),
          ),
        ),
      ],
    );
  }

  String _formatTaskTime(SchedulerTask task) {
    final value = task.effectiveReminderAt;
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.day}/${value.month} $hour:$minute • ${_taskPriorityLabel(task.priority)}';
  }

  String _taskPriorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.normal:
        return 'Normal';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Critical';
    }
  }

  Widget _buildWorkspaces(BuildContext context) {
    return Selector<DashboardProvider, DashboardSummary>(
      selector: (_, provider) => provider.summary,
      builder: (context, summary, child) {
        final groups = WorkspaceNavigation.sections.map((section) {
          return _WorkspaceGroupData(
            icon: section.icon,
            title: section.title,
            color: section.color,
            items: section.items.map((item) {
              return _WorkspaceItemData(
                icon: item.icon,
                title: item.getLabel(context),
                badgeCount: item.getBadge(summary),
                onTap: () => Navigator.pushNamed(context, item.route),
              );
            }).toList(),
          );
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(title: 'Workspaces'),
            const SizedBox(height: _kGridSpacing),
            _ResponsiveCardGrid(
              minTileWidth: 280,
              children: groups
                  .map((group) => _WorkspaceGroupCard(group: group))
                  .toList(),
            ),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _ResponsiveCardGrid extends StatelessWidget {
  final double minTileWidth;
  final List<Widget> children;

  const _ResponsiveCardGrid({
    required this.minTileWidth,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final maxWidth = constraints.maxWidth;

        var columns = (maxWidth / minTileWidth).floor().clamp(1, 4);
        if (textScale > 1.35 || maxWidth < 320) {
          columns = 1;
        }

        final tileWidth =
            (maxWidth - ((columns - 1) * _kGridSpacing)) / columns;

        return Wrap(
          spacing: _kGridSpacing,
          runSpacing: _kGridSpacing,
          children: children
              .map((child) => SizedBox(width: tileWidth, child: child))
              .toList(),
        );
      },
    );
  }
}

class _ReadyBouquetAttentionCard extends StatelessWidget {
  final ReadyBouquetSummary item;

  const _ReadyBouquetAttentionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        onTap: () => Navigator.pushNamed(context, '/ready-bouquets'),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFDE8E8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: _urgentColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${item.currentStock} remaining • ${item.ageDays} days in studio',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceGroupData {
  final IconData icon;
  final String title;
  final Color color;
  final List<_WorkspaceItemData> items;

  const _WorkspaceGroupData({
    required this.icon,
    required this.title,
    required this.color,
    required this.items,
  });
}

class _WorkspaceItemData {
  final IconData icon;
  final String title;
  final int badgeCount;
  final VoidCallback onTap;

  const _WorkspaceItemData({
    required this.icon,
    required this.title,
    required this.badgeCount,
    required this.onTap,
  });
}

class _WorkspaceGroupCard extends StatelessWidget {
  final _WorkspaceGroupData group;

  const _WorkspaceGroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: group.color.withValues(alpha: 0.08),
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(group.icon, size: 20, color: group.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: group.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...group.items.map((item) => _WorkspaceItemTile(item: item)),
        ],
      ),
    );
  }
}

class _WorkspaceItemTile extends StatelessWidget {
  final _WorkspaceItemData item;

  const _WorkspaceItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(item.icon, size: 20, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            if (item.badgeCount > 0)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${item.badgeCount}',
                  style: TextStyle(
                    color: colorScheme.onError,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Icon(Icons.chevron_right, size: 18, color: colorScheme.outline),
          ],
        ),
      ),
    );
  }
}

class _DashboardInventorySection extends StatelessWidget {
  const _DashboardInventorySection();

  @override
  Widget build(BuildContext context) {
    InventoryProvider? inventory;
    try {
      inventory = Provider.of<InventoryProvider>(context);
    } catch (_) {
      inventory = null;
    }

    return DashboardInventoryHealth(
      products: inventory?.products ?? const [],
      lowStockProducts: inventory?.cloudLowStockProducts ?? const [],
      isLoading: inventory?.isLoading ?? false,
      onViewInventory: () => Navigator.pushNamed(context, '/inventory'),
    );
  }
}

