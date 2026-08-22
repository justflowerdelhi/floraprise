import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/order_workspace_models.dart';
import '../providers/order_provider.dart';
import '../widgets/app_header.dart';
import '../widgets/common_widgets.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  static const _tabKeys = [
    'all',
    'pending',
    'in_progress',
    'ready',
    'completed',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabKeys.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        return;
      }
      context
          .read<OrderProvider>()
          .loadOrdersForTab(_tabKeys[_tabController.index]);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<OrderProvider>();
      provider.loadOrdersForTab(_tabKeys[_tabController.index]);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final l10n = AppLocalizations.of(context)!;
    final selectedDate = context.watch<OrderProvider>().filters.selectedDate;

    return Scaffold(
      appBar: AppHeader(
        title: l10n.orders,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.all),
            Tab(text: l10n.pendingOrders),
            Tab(text: l10n.inProgress),
            Tab(text: l10n.readyOrders),
            Tab(text: l10n.deliveredOrders),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          context.read<OrderProvider>().setSearchQuery(value);
                        },
                        decoration: InputDecoration(
                          hintText: l10n.searchByOrderIdCustomer,
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: const Icon(Icons.mic_none_rounded),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () => _pickOrderDate(context),
                      icon: const Icon(Icons.calendar_month_rounded),
                      label: Text(
                        selectedDate == null
                            ? 'Date'
                            : _formatDateLabel(selectedDate),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 56,
                    child: FilledButton.tonalIcon(
                      onPressed: () => _showOrderFilters(context),
                      icon: const Icon(Icons.tune_rounded),
                      label: Text(l10n.filter),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (selectedDate != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Chip(
                      avatar: const Icon(Icons.event, size: 18),
                      label: Text('Showing ${_formatDateLabel(selectedDate)}'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () =>
                          context.read<OrderProvider>().clearDateFilter(),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Consumer<OrderProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.orders.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.orders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noOrdersFound,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 96 + bottomInset),
                    itemCount: provider.orders.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final order = provider.orders[index];
                      final paymentStatus =
                          order.isPaid == 1 ? 'Paid' : 'Pending';
                      return AppCard(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  OrderDetailScreen(orderId: order.id),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Order Number & Status header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  order.orderNo,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                StatusChip(
                                  label: _pretty(order.status),
                                  color: _getStatusColor(order.status),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Recipient Name - LARGE & BOLD (PRIMARY)
                            Text(
                              order.recipientName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Ordered by Customer Name (small)
                            Text(
                              'Ordered by ${order.customerName}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            // Delivery Date & Slot + Amount on same row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _formatOrderTime(order),
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatPaise(order.grandTotalPaise),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Status chips: Payment | Order Status | Source | Fulfillment
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _metaChip(paymentStatus),
                                _metaChip(_pretty(order.status)),
                                _metaChip(_pretty(order.source)),
                                _metaChip(_pretty(order.fulfilmentType)),
                                _assignmentChip('🎨', order.designerName),
                                _assignmentChip('🚚', order.deliveryName),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/walkin-sales'),
        icon: const Icon(Icons.add),
        label: Text(l10n.newOrder),
      ),
    );
  }

  String _formatOrderTime(OrderListItem order) {
    final value = order.scheduledAt ?? order.createdAt;
    final hour =
        value.hour == 0 ? 12 : (value.hour > 12 ? value.hour - 12 : value.hour);
    final minute = value.minute.toString().padLeft(2, '0');
    final meridiem = value.hour >= 12 ? 'PM' : 'AM';
    return '${value.day}/${value.month}/${value.year} $hour:$minute $meridiem';
  }

  String _pretty(String value) {
    return value.replaceAll('_', ' ').replaceAllMapped(
          RegExp(r'(^|\s)([a-z])'),
          (m) => '${m.group(1)}${m.group(2)!.toUpperCase()}',
        );
  }

  String _formatPaise(int paise) {
    return '₹${(paise / 100).toStringAsFixed(0)}';
  }

  String _formatDateLabel(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _pickOrderDate(BuildContext context) async {
    final provider = context.read<OrderProvider>();
    final initialDate = provider.filters.selectedDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      await provider.setSelectedDate(picked);
    }
  }

  Widget _metaChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _assignmentChip(String emoji, String? name) {
    final label =
        name != null && name.trim().isNotEmpty ? name.trim() : 'Not Assigned';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$emoji $label',
        style: TextStyle(
          color: Colors.blueGrey.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _showOrderFilters(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<OrderProvider>();
    var draft = provider.filters;

    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.filterOrders,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _filterSwitch(
                      l10n.today,
                      draft.today,
                      (v) => setState(() => draft = OrderWorkspaceFilters(
                            today: v,
                            pending: draft.pending,
                            completed: draft.completed,
                            cancelled: draft.cancelled,
                            delivery: draft.delivery,
                            pickup: draft.pickup,
                            takeAway: draft.takeAway,
                            relay: draft.relay,
                            corporate: draft.corporate,
                            marketplace: draft.marketplace,
                            paid: draft.paid,
                            unpaid: draft.unpaid,
                          ))),
                  _filterSwitch(
                      l10n.pending,
                      draft.pending,
                      (v) => setState(() => draft = OrderWorkspaceFilters(
                            today: draft.today,
                            pending: v,
                            completed: draft.completed,
                            cancelled: draft.cancelled,
                            delivery: draft.delivery,
                            pickup: draft.pickup,
                            takeAway: draft.takeAway,
                            relay: draft.relay,
                            corporate: draft.corporate,
                            marketplace: draft.marketplace,
                            paid: draft.paid,
                            unpaid: draft.unpaid,
                          ))),
                  _filterSwitch(
                      l10n.completed,
                      draft.completed,
                      (v) => setState(() => draft = OrderWorkspaceFilters(
                            today: draft.today,
                            pending: draft.pending,
                            completed: v,
                            cancelled: draft.cancelled,
                            delivery: draft.delivery,
                            pickup: draft.pickup,
                            takeAway: draft.takeAway,
                            relay: draft.relay,
                            corporate: draft.corporate,
                            marketplace: draft.marketplace,
                            paid: draft.paid,
                            unpaid: draft.unpaid,
                          ))),
                  _filterSwitch(
                      l10n.cancelled,
                      draft.cancelled,
                      (v) => setState(() => draft = OrderWorkspaceFilters(
                            today: draft.today,
                            pending: draft.pending,
                            completed: draft.completed,
                            cancelled: v,
                            delivery: draft.delivery,
                            pickup: draft.pickup,
                            takeAway: draft.takeAway,
                            relay: draft.relay,
                            corporate: draft.corporate,
                            marketplace: draft.marketplace,
                            paid: draft.paid,
                            unpaid: draft.unpaid,
                          ))),
                  _filterSwitch(
                      l10n.delivery,
                      draft.delivery,
                      (v) => setState(() => draft = OrderWorkspaceFilters(
                            today: draft.today,
                            pending: draft.pending,
                            completed: draft.completed,
                            cancelled: draft.cancelled,
                            delivery: v,
                            pickup: draft.pickup,
                            takeAway: draft.takeAway,
                            relay: draft.relay,
                            corporate: draft.corporate,
                            marketplace: draft.marketplace,
                            paid: draft.paid,
                            unpaid: draft.unpaid,
                          ))),
                  _filterSwitch(
                      l10n.pickup,
                      draft.pickup,
                      (v) => setState(() => draft = OrderWorkspaceFilters(
                            today: draft.today,
                            pending: draft.pending,
                            completed: draft.completed,
                            cancelled: draft.cancelled,
                            delivery: draft.delivery,
                            pickup: v,
                            takeAway: draft.takeAway,
                            relay: draft.relay,
                            corporate: draft.corporate,
                            marketplace: draft.marketplace,
                            paid: draft.paid,
                            unpaid: draft.unpaid,
                          ))),
                  _filterSwitch(
                      l10n.takeAway,
                      draft.takeAway,
                      (v) => setState(() => draft = OrderWorkspaceFilters(
                            today: draft.today,
                            pending: draft.pending,
                            completed: draft.completed,
                            cancelled: draft.cancelled,
                            delivery: draft.delivery,
                            pickup: draft.pickup,
                            takeAway: v,
                            relay: draft.relay,
                            corporate: draft.corporate,
                            marketplace: draft.marketplace,
                            paid: draft.paid,
                            unpaid: draft.unpaid,
                          ))),
                  _filterSwitch(
                      l10n.relay,
                      draft.relay,
                      (v) => setState(() => draft = OrderWorkspaceFilters(
                            today: draft.today,
                            pending: draft.pending,
                            completed: draft.completed,
                            cancelled: draft.cancelled,
                            delivery: draft.delivery,
                            pickup: draft.pickup,
                            takeAway: draft.takeAway,
                            relay: v,
                            corporate: draft.corporate,
                            marketplace: draft.marketplace,
                            paid: draft.paid,
                            unpaid: draft.unpaid,
                          ))),
                  _filterSwitch(
                      l10n.corporate,
                      draft.corporate,
                      (v) => setState(() => draft = OrderWorkspaceFilters(
                            today: draft.today,
                            pending: draft.pending,
                            completed: draft.completed,
                            cancelled: draft.cancelled,
                            delivery: draft.delivery,
                            pickup: draft.pickup,
                            takeAway: draft.takeAway,
                            relay: draft.relay,
                            corporate: v,
                            marketplace: draft.marketplace,
                            paid: draft.paid,
                            unpaid: draft.unpaid,
                          ))),
                  _filterSwitch(
                      l10n.marketplace,
                      draft.marketplace,
                      (v) => setState(() => draft = OrderWorkspaceFilters(
                            today: draft.today,
                            pending: draft.pending,
                            completed: draft.completed,
                            cancelled: draft.cancelled,
                            delivery: draft.delivery,
                            pickup: draft.pickup,
                            takeAway: draft.takeAway,
                            relay: draft.relay,
                            corporate: draft.corporate,
                            marketplace: v,
                            paid: draft.paid,
                            unpaid: draft.unpaid,
                          ))),
                  _filterSwitch(
                      l10n.paid,
                      draft.paid,
                      (v) => setState(() => draft = OrderWorkspaceFilters(
                            today: draft.today,
                            pending: draft.pending,
                            completed: draft.completed,
                            cancelled: draft.cancelled,
                            delivery: draft.delivery,
                            pickup: draft.pickup,
                            takeAway: draft.takeAway,
                            relay: draft.relay,
                            corporate: draft.corporate,
                            marketplace: draft.marketplace,
                            paid: v,
                            unpaid: draft.unpaid,
                          ))),
                  _filterSwitch(
                      l10n.unpaid,
                      draft.unpaid,
                      (v) => setState(() => draft = OrderWorkspaceFilters(
                            today: draft.today,
                            pending: draft.pending,
                            completed: draft.completed,
                            cancelled: draft.cancelled,
                            delivery: draft.delivery,
                            pickup: draft.pickup,
                            takeAway: draft.takeAway,
                            relay: draft.relay,
                            corporate: draft.corporate,
                            marketplace: draft.marketplace,
                            paid: draft.paid,
                            unpaid: v,
                          ))),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await provider.applyFilters(draft);
                      },
                      child: Text(l10n.applyFilters),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _filterSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile.adaptive(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value,
      onChanged: onChanged,
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
      case 'confirmed':
        return Colors.orange;
      case 'preparing':
        return Colors.blue;
      case 'ready':
        return Colors.green;
      case 'out_for_delivery':
        return Colors.purple;
      case 'delivered':
        return Colors.teal;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
