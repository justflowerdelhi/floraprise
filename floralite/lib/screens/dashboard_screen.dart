import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../managers/business_settings_manager.dart';
import '../data/repositories/ready_bouquet_repository.dart';
import '../data/repositories/scheduler_repository.dart';
import '../models/dashboard_summary.dart';
import '../models/scheduler_task.dart';
import '../providers/app_shell_controller.dart';
import '../providers/dashboard_provider.dart';
import '../providers/license_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/app_route_observer.dart';
import '../services/delivery_tracking_service.dart';
import '../widgets/botanical_signature.dart';
import '../widgets/common_widgets.dart';

const double _kSectionSpacing = 24;
const double _kGridSpacing = 16;

const Color _successColor = Color(0xFF2E7D32);
const Color _infoColor = Color(0xFF1565C0);
const Color _pendingColor = Color(0xFFEF6C00);
const Color _creativeColor = Color(0xFF7B1FA2);
const Color _urgentColor = Color(0xFFC62828);
const Color _warningColor = Color(0xFFF57C00);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver, RouteAware {
  final BusinessSettingsManager _businessSettingsManager =
      BusinessSettingsManager();
  final DeliveryTrackingService _deliveryTrackingService =
      DeliveryTrackingService();
  final SchedulerRepository _schedulerRepository = SchedulerRepository();
  String _shopName = 'My Flower Shop';
  String _shopAddress = '';
  String _logoPath = '';
  bool _subscribedToRouteObserver = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DashboardProvider>().loadSummary(showLoading: true);
        context.read<LicenseProvider>().heartbeat();
        _loadBusinessIdentity();
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
  }

  void _openShellTab(AppShellTab tab, String routeName) {
    context.read<AppShellController>().selectTab(tab);
    Navigator.of(context).pushNamedAndRemoveUntil(routeName, (route) => false);
  }

  Future<void> _loadBusinessIdentity() async {
    final settings = await _businessSettingsManager.load();
    final logoPath = await _businessSettingsManager.getLogoPath();
    if (!mounted) return;
    setState(() {
      _shopName = settings.shopName;
      _shopAddress = settings.address;
      _logoPath = logoPath;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DashboardHeader(
                shopName: _shopName,
                shopAddress: _shopAddress,
                logoPath: _logoPath,
                onProfileSelected: (value) {
                  if (value == l10n.shopDetails) {
                    Navigator.pushNamed(context, '/shop-details');
                    return;
                  }
                  if (value == l10n.backup) {
                    Navigator.pushNamed(context, '/backup-restore');
                    return;
                  }
                  if (value == l10n.settingsTitle) {
                    Navigator.pushNamed(context, '/settings');
                    return;
                  }
                  if (value == l10n.about) {
                    Navigator.pushNamed(context, '/about');
                    return;
                  }
                },
              ),
              const SizedBox(height: _kSectionSpacing),
              _buildSubscriptionBanner(context),
              _buildBusinessSnapshot(context),
              _buildReadyBouquetAttention(context),
              _buildTodaysWork(context),
              _buildTaskSections(context),
              _buildActiveDeliveriesCard(context),
              _buildWorkspaces(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveDeliveriesCard(BuildContext context) {
    return FutureBuilder<List<DeliveryWorkspaceRecord>>(
      future: _deliveryTrackingService.getActiveDeliveries(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final active = snapshot.data ?? const <DeliveryWorkspaceRecord>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(title: 'Active Deliveries'),
            const SizedBox(height: 14),
            AppCard(
              onTap: () => Navigator.pushNamed(context, '/delivery-workspace'),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _infoColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.local_shipping_rounded,
                        color: _infoColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Live Delivery Tracking',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          active.isEmpty
                              ? 'No active deliveries right now'
                              : '${active.length} active deliveries in progress',
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
            const SizedBox(height: _kSectionSpacing),
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(title: 'Task Reminders'),
            const SizedBox(height: 14),
            AppCard(
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
            const SizedBox(height: _kSectionSpacing),
          ],
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
          padding: const EdgeInsets.only(bottom: _kSectionSpacing),
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
            const _SectionTitle(title: 'Ready Bouquets Requiring Attention'),
            const SizedBox(height: 14),
            ...items.map((item) => _ReadyBouquetAttentionCard(item: item)),
            const SizedBox(height: _kSectionSpacing),
          ],
        );
      },
    );
  }

  Widget _buildBusinessSnapshot(BuildContext context) {
    return Selector<DashboardProvider, DashboardSummary>(
      selector: (_, provider) => provider.summary,
      builder: (context, summary, child) {
        final cards = <_KpiCardData>[
          _KpiCardData(
            icon: Icons.payments_rounded,
            value: '₹${(summary.todaySalesAmount / 100).toStringAsFixed(0)}',
            label: 'Today\'s Sales',
            color: _successColor,
            onTap: () => Navigator.pushNamed(context, '/reports/sales'),
          ),
          _KpiCardData(
            icon: Icons.receipt_long_rounded,
            value: '${summary.todayOrderCount}',
            label: 'Today\'s Orders',
            color: _pendingColor,
            onTap: () => _openShellTab(AppShellTab.orders, '/_orders-tab'),
          ),
          _KpiCardData(
            icon: Icons.shopping_cart_rounded,
            value: '₹${(summary.todayExpenses / 100).toStringAsFixed(0)}',
            label: 'Today\'s Expenses',
            color: _warningColor,
            onTap: () => _openShellTab(AppShellTab.money, '/_money-tab'),
          ),
          _KpiCardData(
            icon: Icons.local_shipping_rounded,
            value: '${summary.outForDeliveryOrders}',
            label: 'Pending Deliveries',
            color: _infoColor,
            onTap: () => _openShellTab(AppShellTab.orders, '/_orders-tab'),
          ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              title: 'Business Snapshot',
            ),
            const SizedBox(height: 14),
            _ResponsiveCardGrid(
              minTileWidth: 150,
              children: cards.map((card) => _KpiCard(data: card)).toList(),
            ),
            const SizedBox(height: _kSectionSpacing),
          ],
        );
      },
    );
  }

  Widget _buildTodaysWork(BuildContext context) {
    return Selector<DashboardProvider, DashboardSummary>(
      selector: (_, provider) => provider.summary,
      builder: (context, summary, child) {
        final items = <_WorkItemData>[
          if (summary.preparingOrders > 0)
            _WorkItemData(
              priority: 10,
              icon: Icons.local_florist_rounded,
              title: 'Prepare Orders',
              subtitle: 'Orders waiting for preparation',
              count: summary.preparingOrders,
              color: _pendingColor,
              onTap: () => Navigator.pushNamed(context, '/orders'),
            ),
          if (summary.outForDeliveryOrders > 0)
            _WorkItemData(
              priority: 20,
              icon: Icons.local_shipping_rounded,
              title: 'Deliveries',
              subtitle: 'Orders pending delivery',
              count: summary.outForDeliveryOrders,
              color: _infoColor,
              onTap: () => Navigator.pushNamed(context, '/orders'),
            ),
          if (summary.todayPickupCount > 0)
            _WorkItemData(
              priority: 30,
              icon: Icons.shopping_bag_rounded,
              title: 'Pickups',
              subtitle: 'Customer pickups due today',
              count: summary.todayPickupCount,
              color: _creativeColor,
              onTap: () => Navigator.pushNamed(context, '/orders'),
            ),
          if (summary.todayPendingPayments > 0)
            _WorkItemData(
              priority: 40,
              icon: Icons.call_rounded,
              title: 'Payment Follow-up',
              subtitle: 'Customers with pending payments',
              count: summary.todayPendingPayments,
              color: _urgentColor,
              onTap: () => Navigator.pushNamed(context, '/reminders'),
            ),
          _WorkItemData(
            priority: 50,
            icon: Icons.task_alt_rounded,
            title: 'Today\'s Scheduled Tasks',
            subtitle: summary.todayTaskCount == 0
                ? 'No tasks scheduled for today'
                : 'Tasks planned for today',
            count: summary.todayTaskCount,
            color: _pendingColor,
            onTap: () => Navigator.pushNamed(
              context,
              '/scheduler',
              arguments: {'focus': 'todayScheduledTasks'},
            ),
          ),
        ]..sort((a, b) => a.priority.compareTo(b.priority));

        if (items.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              title: 'Today\'s Work',
            ),
            const SizedBox(height: 14),
            _WorkQueueCard(items: items),
            const SizedBox(height: _kSectionSpacing),
          ],
        );
      },
    );
  }

  Widget _buildWorkspaces(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Selector<DashboardProvider, DashboardSummary>(
      selector: (_, provider) => provider.summary,
      builder: (context, summary, child) {
        final inventoryAttention =
            summary.lowStockItems + summary.outOfStockItems;
        final groups = <_WorkspaceGroupData>[
          _WorkspaceGroupData(
            icon: Icons.shopping_bag_rounded,
            title: 'Sales & Orders',
            color: _pendingColor,
            items: [
              _WorkspaceItemData(
                icon: Icons.point_of_sale_rounded,
                title: l10n.navWalkinSales,
                onTap: () => Navigator.pushNamed(context, '/walkin-sales'),
              ),
              _WorkspaceItemData(
                icon: Icons.receipt_long_rounded,
                title: l10n.orders,
                badgeCount: summary.pendingOrders,
                onTap: () => Navigator.pushNamed(context, '/orders'),
              ),
              _WorkspaceItemData(
                icon: Icons.event_note_rounded,
                title: 'Scheduled Tasks',
                badgeCount: summary.todayTaskCount,
                onTap: () => Navigator.pushNamed(context, '/scheduler'),
              ),
              _WorkspaceItemData(
                icon: Icons.groups_rounded,
                title: l10n.customers,
                onTap: () => Navigator.pushNamed(context, '/customers'),
              ),
              _WorkspaceItemData(
                icon: Icons.business_rounded,
                title: 'Associates',
                onTap: () => Navigator.pushNamed(context, '/associates'),
              ),
              _WorkspaceItemData(
                icon: Icons.location_searching_rounded,
                title: 'Delivery Workspace',
                onTap: () =>
                    Navigator.pushNamed(context, '/delivery-workspace'),
              ),
            ],
          ),
          _WorkspaceGroupData(
            icon: Icons.local_florist_rounded,
            title: 'Catalogue & Inventory',
            color: _successColor,
            items: [
              _WorkspaceItemData(
                icon: Icons.category_rounded,
                title: 'Categories',
                onTap: () => Navigator.pushNamed(context, '/categories'),
              ),
              _WorkspaceItemData(
                icon: Icons.spa_rounded,
                title: l10n.products,
                onTap: () => Navigator.pushNamed(context, '/products'),
              ),
              _WorkspaceItemData(
                icon: Icons.palette_rounded,
                title: 'My Designs',
                onTap: () => Navigator.pushNamed(context, '/my-designs'),
              ),
              _WorkspaceItemData(
                icon: Icons.inventory_2_rounded,
                title: l10n.inventoryTitle,
                badgeCount: inventoryAttention,
                onTap: () => Navigator.pushNamed(context, '/inventory'),
              ),
              _WorkspaceItemData(
                icon: Icons.shopping_cart_rounded,
                title: 'Create Puchase List',
                badgeCount: summary.todayPurchaseListCount,
                onTap: () => Navigator.pushNamed(context, '/purchase-list'),
              ),
            ],
          ),
          _WorkspaceGroupData(
            icon: Icons.groups_2_rounded,
            title: 'Team',
            color: _infoColor,
            items: [
              _WorkspaceItemData(
                icon: Icons.badge_rounded,
                title: l10n.staff,
                onTap: () async {
                  await Navigator.pushNamed(context, '/staff');
                },
              ),
              _WorkspaceItemData(
                icon: Icons.event_available_rounded,
                title: l10n.attendance,
                badgeCount: summary.unmarkedAttendanceCount,
                onTap: () async {
                  await Navigator.pushNamed(context, '/attendance');
                },
              ),
            ],
          ),
          _WorkspaceGroupData(
            icon: Icons.account_balance_wallet_rounded,
            title: 'Accounting',
            color: _creativeColor,
            items: [
              _WorkspaceItemData(
                icon: Icons.attach_money_rounded,
                title: 'Opening Cash',
                onTap: () => Navigator.pushNamed(context, '/opening-cash'),
              ),
              _WorkspaceItemData(
                icon: Icons.receipt_long_rounded,
                title: 'Cash Book',
                onTap: () => Navigator.pushNamed(context, '/cash-book'),
              ),
              _WorkspaceItemData(
                icon: Icons.receipt_rounded,
                title: 'Expenses',
                onTap: () => Navigator.pushNamed(context, '/expenses'),
              ),
              _WorkspaceItemData(
                icon: Icons.nights_stay_rounded,
                title: 'Day Closing',
                onTap: () => Navigator.pushNamed(context, '/day-closing'),
              ),
              _WorkspaceItemData(
                icon: Icons.bar_chart_rounded,
                title: 'Reports',
                onTap: () => Navigator.pushNamed(context, '/reports'),
              ),
            ],
          ),
          _WorkspaceGroupData(
            icon: Icons.tune_rounded,
            title: 'Utilities',
            color: _creativeColor,
            items: [
              _WorkspaceItemData(
                icon: Icons.notifications_rounded,
                title: l10n.reminders,
                badgeCount: summary.todayFollowUps,
                onTap: () => Navigator.pushNamed(context, '/reminders'),
              ),
              _WorkspaceItemData(
                icon: Icons.settings_rounded,
                title: l10n.settingsTitle,
                onTap: () => Navigator.pushNamed(context, '/settings'),
              ),
            ],
          ),
        ];

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

class _DashboardHeader extends StatelessWidget {
  final String shopName;
  final String shopAddress;
  final String logoPath;
  final ValueChanged<String> onProfileSelected;

  const _DashboardHeader({
    required this.shopName,
    required this.shopAddress,
    required this.logoPath,
    required this.onProfileSelected,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final displayName = shopName.trim().isEmpty ? 'My Flower Shop' : shopName;
    final displayAddress = shopAddress.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Row(
                children: [
                  Image.asset(
                    'assets/icon.png',
                    width: 32,
                    height: 32,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Floraprise',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.onboardingPoweringModernFlorists,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            PopupMenuButton<String>(
              onSelected: onProfileSelected,
              itemBuilder: (context) => [
                PopupMenuItem(
                    value: l10n.shopDetails, child: Text(l10n.shopDetails)),
                PopupMenuItem(value: l10n.backup, child: Text(l10n.backup)),
                PopupMenuItem(
                    value: l10n.settingsTitle, child: Text(l10n.settingsTitle)),
                PopupMenuItem(value: l10n.about, child: Text(l10n.about)),
              ],
              child: CircleAvatar(
                radius: 22,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  Icons.person_rounded,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Consumer<DashboardProvider>(
          builder: (context, provider, child) {
            return AppCard(
              padding: const EdgeInsets.all(12),
              child: Stack(
                children: [
                  const Positioned(
                    right: -26,
                    top: -48,
                    child: BotanicalSignature(width: 150, height: 112),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _BusinessLogo(path: logoPath, size: 40),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (displayAddress.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                displayAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _BusinessLogo extends StatelessWidget {
  final String path;
  final double size;

  const _BusinessLogo({required this.path, required this.size});

  @override
  Widget build(BuildContext context) {
    final trimmed = path.trim();
    if (trimmed.isNotEmpty) {
      final file = File(trimmed);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _fallbackLogo(context),
        );
      }
    }

    return _fallbackLogo(context);
  }

  Widget _fallbackLogo(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(size <= 32 ? 8 : 10),
      ),
      child: Icon(
        Icons.store_rounded,
        color: colorScheme.primary,
        size: size * 0.56,
      ),
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
          style: textTheme.titleLarge?.copyWith(
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

class _KpiCardData {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _KpiCardData({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _KpiCard extends StatelessWidget {
  final _KpiCardData data;

  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      onTap: data.onTap,
      padding: const EdgeInsets.all(12),
      backgroundColor: colorScheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 88),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(data.icon, color: data.color, size: 21),
            ),
            const SizedBox(height: 7),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.12),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                data.value,
                key: ValueKey('${data.label}-${data.value}'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              data.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkItemData {
  final int priority;
  final IconData icon;
  final String title;
  final String subtitle;
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _WorkItemData({
    required this.priority,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.color,
    required this.onTap,
  });
}

class _WorkQueueCard extends StatelessWidget {
  final List<_WorkItemData> items;

  const _WorkQueueCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              _WorkQueueRow(item: item),
              if (index != items.length - 1) const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _WorkQueueRow extends StatelessWidget {
  final _WorkItemData item;

  const _WorkQueueRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: item.color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              constraints: const BoxConstraints(minWidth: 36),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                '${item.count}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: item.color,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
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
    this.badgeCount = 0,
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
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 150),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: group.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(group.icon, color: group.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    group.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(
              height: 1,
              thickness: 1,
              color: group.color.withValues(alpha: 0.16),
            ),
            const SizedBox(height: 10),
            ...group.items.map(
              (item) => _WorkspaceItemRow(
                item: item,
                color: group.color,
                foregroundColor: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceItemRow extends StatelessWidget {
  final _WorkspaceItemData item;
  final Color color;
  final Color foregroundColor;

  const _WorkspaceItemRow({
    required this.item,
    required this.color,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(item.icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            if (item.badgeCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(minWidth: 28),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${item.badgeCount}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              color: foregroundColor,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadyBouquetAttentionCard extends StatelessWidget {
  const _ReadyBouquetAttentionCard({required this.item});

  final ReadyBouquetSummary item;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(item.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: () => Navigator.pushNamed(context, '/ready-bouquets'),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Age: ${item.ageDays} day${item.ageDays == 1 ? '' : 's'} • Stock: ${item.currentStock} ${item.unit}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color),
              ),
              child: Text(
                _statusLabel(item.status),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(ReadyBouquetStatus status) {
    return switch (status) {
      ReadyBouquetStatus.fresh => 'Fresh',
      ReadyBouquetStatus.needsRefresh => 'Needs Refresh',
      ReadyBouquetStatus.nearExpiry => 'Near Expiry',
      ReadyBouquetStatus.expired => 'Expired',
    };
  }

  Color _statusColor(ReadyBouquetStatus status) {
    return switch (status) {
      ReadyBouquetStatus.fresh => Colors.green,
      ReadyBouquetStatus.needsRefresh => Colors.amber.shade700,
      ReadyBouquetStatus.nearExpiry => Colors.orange,
      ReadyBouquetStatus.expired => Colors.red,
    };
  }
}
