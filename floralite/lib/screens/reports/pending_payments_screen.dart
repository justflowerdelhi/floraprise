import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/database/app_database.dart';
import '../../data/repositories/cloud_order_repository.dart';
import '../../data/repositories/cloud_scheduler_repository.dart';
import '../../models/order_workspace_models.dart';
import '../../models/scheduler_task.dart';
import '../../providers/storage_mode_provider.dart';
import '../../widgets/app_header.dart';
import '../../widgets/collect_payment_dialog.dart';
import '../../widgets/schedule_payment_followup_dialog.dart';
import '../order_detail_screen.dart';

class PendingPaymentItem {
  final int orderId;
  final String? cloudOrderId;
  final String orderNo;
  final int? customerId;
  final String? cloudCustomerId;
  final String customerName;
  final String customerPhone;
  final DateTime orderDate;
  final DateTime? scheduledAt;
  final int grandTotalPaise;
  final int paidAmountPaise;
  final int outstandingAmountPaise;
  final String paymentStatus;
  final String fulfilmentType;
  final DateTime? lastPaymentDate;
  final DateTime? followUpScheduledAt;
  final String? followUpNotes;

  const PendingPaymentItem({
    required this.orderId,
    this.cloudOrderId,
    required this.orderNo,
    this.customerId,
    this.cloudCustomerId,
    required this.customerName,
    required this.customerPhone,
    required this.orderDate,
    this.scheduledAt,
    required this.grandTotalPaise,
    required this.paidAmountPaise,
    required this.outstandingAmountPaise,
    required this.paymentStatus,
    this.fulfilmentType = 'delivery',
    this.lastPaymentDate,
    this.followUpScheduledAt,
    this.followUpNotes,
  });

  bool get isOverdue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (scheduledAt != null) {
      final sched = DateTime(scheduledAt!.year, scheduledAt!.month, scheduledAt!.day);
      return sched.isBefore(today);
    }
    // Default overdue threshold: older than 3 days
    final created = DateTime(orderDate.year, orderDate.month, orderDate.day);
    return created.isBefore(today.subtract(const Duration(days: 3)));
  }

  bool get isDueToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (scheduledAt != null) {
      final sched = DateTime(scheduledAt!.year, scheduledAt!.month, scheduledAt!.day);
      return sched.isAtSameMomentAs(today);
    }
    final created = DateTime(orderDate.year, orderDate.month, orderDate.day);
    return created.isAtSameMomentAs(today);
  }

  bool get isPartiallyPaid => paidAmountPaise > 0 && outstandingAmountPaise > 0;
}

enum PendingPaymentFilter {
  all,
  overdue,
  dueToday,
  partiallyPaid,
}

class PendingPaymentsScreen extends StatefulWidget {
  const PendingPaymentsScreen({super.key});

  @override
  State<PendingPaymentsScreen> createState() => _PendingPaymentsScreenState();
}

class _PendingPaymentsScreenState extends State<PendingPaymentsScreen> {
  final CloudOrderRepository _cloudOrderRepository = CloudOrderRepository();

  List<PendingPaymentItem> _items = [];
  bool _isLoading = true;
  PendingPaymentFilter _selectedFilter = PendingPaymentFilter.all;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatPaise(int paise) {
    final rs = paise / 100;
    if (rs % 1 == 0) {
      return '₹${rs.toInt()}';
    }
    return '₹${rs.toStringAsFixed(2)}';
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final storageMode = context.read<StorageModeProvider>();
      final isCloud = storageMode.isCloud;

      List<PendingPaymentItem> loaded = [];

      if (isCloud) {
        // Query cloud orders
        final orders = await _cloudOrderRepository.getWorkspace(
          tab: 'all',
          searchQuery: '',
          filters: const OrderWorkspaceFilters(unpaid: true),
          limit: 200,
        );

        // Fetch cloud follow-up reminders
        final cloudScheduler = CloudSchedulerRepository();
        List<SchedulerTask> cloudTasks = [];
        try {
          cloudTasks = await cloudScheduler.listTasks(query: 'payment_followup:');
        } catch (_) {}

        final activeTasksByRef = <String, SchedulerTask>{};
        for (final t in cloudTasks) {
          if (t.sourceRef != null &&
              t.status != TaskStatus.completed &&
              t.status != TaskStatus.cancelled) {
            activeTasksByRef[t.sourceRef!] = t;
          }
        }

        for (final o in orders) {
          if (o.status == 'cancelled' || o.status == 'draft') continue;
          final detail = await _cloudOrderRepository.getDetail(o.cloudOrderId ?? '');
          if (detail?.header.status == 'cancelled' || detail?.header.status == 'draft') continue;

          final total = detail?.header.grandTotalPaise ?? o.grandTotalPaise;
          final paid = detail?.header.paidAmountPaise ?? (o.paidAmountPaise > 0 ? o.paidAmountPaise : (o.isPaid == 1 ? total : 0));
          final outstanding = total - paid;
          if (outstanding <= 0) continue;

          final sourceRef = 'payment_followup:order_${o.cloudOrderId}';
          final task = activeTasksByRef[sourceRef];

          DateTime? lastPaymentDate;
          if (detail != null && detail.payments.isNotEmpty) {
            final validPayments = detail.payments.where((p) => p['createdAtUtc'] != null).toList();
            if (validPayments.isNotEmpty) {
              lastPaymentDate = DateTime.tryParse(validPayments.last['createdAtUtc'].toString());
            }
          }

          loaded.add(
            PendingPaymentItem(
              orderId: o.id,
              cloudOrderId: o.cloudOrderId,
              orderNo: o.orderNo,
              customerName: o.customerName,
              customerPhone: o.customerPhone,
              orderDate: o.createdAt,
              scheduledAt: o.scheduledAt,
              grandTotalPaise: total,
              paidAmountPaise: paid,
              outstandingAmountPaise: outstanding,
              paymentStatus: paid == 0 ? 'Credit / Unpaid' : 'Partially Paid',
              fulfilmentType: detail?.header.fulfilmentType ?? o.fulfilmentType,
              lastPaymentDate: lastPaymentDate,
              followUpScheduledAt: task?.scheduledAt,
              followUpNotes: task?.notes,
            ),
          );
        }
      } else {
        // Query Solo SQLite
        final db = await AppDatabase.instance.database;
        final rows = await db.rawQuery('''
          SELECT
            o.id,
            o.order_no,
            o.customer_id,
            o.customer_name,
            o.customer_phone,
            o.fulfilment_type,
            o.created_at,
            o.scheduled_at,
            o.grand_total_paise,
            COALESCE((
              SELECT SUM(op.amount_paise)
              FROM order_payments op
              WHERE op.order_id = o.id
                AND LOWER(COALESCE(op.method, '')) != 'credit'
            ), 0) AS paid_amount_paise,
            (
              SELECT MAX(op.created_at)
              FROM order_payments op
              WHERE op.order_id = o.id
                AND LOWER(COALESCE(op.method, '')) != 'credit'
            ) AS last_payment_date
          FROM orders o
          WHERE o.status NOT IN ('draft', 'cancelled')
          ORDER BY o.created_at DESC
        ''');

        // Fetch local follow-up tasks
        final taskRows = await db.query(
          'scheduler_tasks',
          columns: ['source_ref', 'scheduled_at', 'notes'],
          where: "source_ref LIKE 'payment_followup:%' AND status IN ('pending', 'inProgress', 'deferred') AND deleted_at IS NULL",
        );

        final activeTasksByRef = <String, Map<String, dynamic>>{};
        for (final r in taskRows) {
          final ref = r['source_ref'] as String?;
          if (ref != null) {
            activeTasksByRef[ref] = r;
          }
        }

        for (final row in rows) {
          final orderId = row['id'] as int;
          final grandTotal = (row['grand_total_paise'] as int?) ?? 0;
          final paidAmount = (row['paid_amount_paise'] as int?) ?? 0;
          final outstanding = grandTotal - paidAmount;
          if (outstanding <= 0) continue;

          final sourceRef = 'payment_followup:order_$orderId';
          final task = activeTasksByRef[sourceRef];

          loaded.add(
            PendingPaymentItem(
              orderId: orderId,
              orderNo: (row['order_no'] as String?) ?? '#$orderId',
              customerId: row['customer_id'] as int?,
              customerName: (row['customer_name'] as String?) ?? 'Walk-in Customer',
              customerPhone: (row['customer_phone'] as String?) ?? '',
              orderDate: DateTime.parse(row['created_at'] as String),
              scheduledAt: row['scheduled_at'] == null
                  ? null
                  : DateTime.tryParse(row['scheduled_at'] as String),
              grandTotalPaise: grandTotal,
              paidAmountPaise: paidAmount,
              outstandingAmountPaise: outstanding,
              paymentStatus: paidAmount == 0 ? 'Credit / Unpaid' : 'Partially Paid',
              fulfilmentType: (row['fulfilment_type'] as String?) ?? 'take_away',
              lastPaymentDate: row['last_payment_date'] == null
                  ? null
                  : DateTime.tryParse(row['last_payment_date'] as String),
              followUpScheduledAt: task == null
                  ? null
                  : DateTime.tryParse(task['scheduled_at'] as String),
              followUpNotes: task?['notes'] as String?,
            ),
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _items = loaded;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading pending payments: $e')),
      );
    }
  }

  List<PendingPaymentItem> get _filteredItems {
    return _items.where((item) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchOrder = item.orderNo.toLowerCase().contains(q);
        final matchCust = item.customerName.toLowerCase().contains(q);
        final matchPhone = item.customerPhone.toLowerCase().contains(q);
        if (!matchOrder && !matchCust && !matchPhone) return false;
      }

      // Status tab filter
      switch (_selectedFilter) {
        case PendingPaymentFilter.all:
          return true;
        case PendingPaymentFilter.overdue:
          return item.isOverdue;
        case PendingPaymentFilter.dueToday:
          return item.isDueToday;
        case PendingPaymentFilter.partiallyPaid:
          return item.isPartiallyPaid;
      }
    }).toList();
  }

  int get _totalPendingPaise =>
      _items.fold<int>(0, (sum, item) => sum + item.outstandingAmountPaise);

  int get _overdueCount => _items.where((item) => item.isOverdue).length;

  int get _dueTodayCount => _items.where((item) => item.isDueToday).length;

  int get _partiallyPaidCount => _items.where((item) => item.isPartiallyPaid).length;

  String _formatFulfilmentType(String type) {
    final normalized = type.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    switch (normalized) {
      case 'delivery':
        return 'Delivery';
      case 'pickup':
      case 'pickup_later':
        return 'Pickup';
      case 'take_away':
      case 'takeaway':
      case 'walk_in':
      case 'walkin':
        return 'Walk-in';
      default:
        return type.isEmpty ? 'Order' : type[0].toUpperCase() + type.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4EE),
      appBar: const AppHeader(title: 'Pending Payments / Receivables'),
      body: SafeArea(
        child: Column(
          children: [
            _buildSummaryHeader(),
            _buildFiltersAndSearch(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredItems.isEmpty
                      ? _buildEmptyState()
                      : _buildList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2D9CC))),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _buildSummaryCard(
                title: 'Total Outstanding',
                value: _formatPaise(_totalPendingPaise),
                color: Colors.red.shade700,
                icon: Icons.account_balance_wallet_outlined,
              ),
              _buildSummaryCard(
                title: 'Pending Orders',
                value: '${_items.length}',
                color: const Color(0xFF1E5E3A),
                icon: Icons.receipt_long_outlined,
              ),
              _buildSummaryCard(
                title: 'Overdue',
                value: '$_overdueCount',
                color: Colors.orange.shade800,
                icon: Icons.warning_amber_rounded,
              ),
              _buildSummaryCard(
                title: 'Partially Paid',
                value: '$_partiallyPaidCount',
                color: Colors.blue.shade700,
                icon: Icons.pie_chart_outline,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersAndSearch() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2D9CC))),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by customer, phone, or order #',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: const Color(0xFFF8F4EE),
            ),
            onChanged: (value) => setState(() => _searchQuery = value.trim()),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All (${_items.length})', PendingPaymentFilter.all),
                const SizedBox(width: 6),
                _buildFilterChip('Overdue ($_overdueCount)', PendingPaymentFilter.overdue),
                const SizedBox(width: 6),
                _buildFilterChip('Due Today ($_dueTodayCount)', PendingPaymentFilter.dueToday),
                const SizedBox(width: 6),
                _buildFilterChip(
                  'Partially Paid (${_items.where((i) => i.isPartiallyPaid).length})',
                  PendingPaymentFilter.partiallyPaid,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, PendingPaymentFilter filter) {
    final isSelected = _selectedFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedFilter = filter);
        }
      },
      selectedColor: const Color(0xFF1E5E3A),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, size: 56, color: Color(0xFF1E5E3A)),
          const SizedBox(height: 12),
          const Text(
            'No Pending Payments',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _searchQuery.isNotEmpty
                ? 'No matching pending orders found for "$_searchQuery".'
                : 'All orders are fully paid! Great job.',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final dateFormat = DateFormat('dd MMM yyyy');
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _filteredItems.length,
        itemBuilder: (context, index) {
          final item = _filteredItems[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: item.isOverdue
                    ? Colors.red.shade300
                    : const Color(0xFFE2D9CC),
                width: item.isOverdue ? 1.5 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              item.orderNo,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: item.isPartiallyPaid
                                    ? Colors.amber.shade100
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.paymentStatus,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: item.isPartiallyPaid
                                      ? Colors.amber.shade900
                                      : Colors.red.shade800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E5E3A).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _formatFulfilmentType(item.fulfilmentType),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E5E3A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatPaise(item.outstandingAmountPaise),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            item.customerName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (item.customerPhone.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              '(${item.customerPhone})',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        'Total: ${_formatPaise(item.grandTotalPaise)}',
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ordered: ${dateFormat.format(item.orderDate)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        'Paid: ${_formatPaise(item.paidAmountPaise)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  if (item.followUpScheduledAt != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E5E3A).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF1E5E3A).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.alarm_on,
                            size: 14,
                            color: Color(0xFF1E5E3A),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Follow-up: ${DateFormat('dd MMM, hh:mm a').format(item.followUpScheduledAt!)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1E5E3A),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Divider(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    alignment: WrapAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderDetailScreen(orderId: item.orderId),
                            ),
                          ).then((_) => _loadData());
                        },
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text('View Order'),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          showSchedulePaymentFollowUpDialog(
                            context: context,
                            orderId: item.orderId,
                            cloudOrderId: item.cloudOrderId,
                            orderNo: item.orderNo,
                            customerId: item.customerId,
                            cloudCustomerId: item.cloudCustomerId,
                            customerName: item.customerName,
                            outstandingAmountPaise: item.outstandingAmountPaise,
                            onScheduled: _loadData,
                          );
                        },
                        icon: const Icon(Icons.alarm_add_outlined, size: 16),
                        label: const Text('Schedule Follow-up'),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () {
                          showCollectPaymentDialog(
                            context: context,
                            orderId: item.orderId,
                            cloudOrderId: item.cloudOrderId,
                            orderNo: item.orderNo,
                            customerName: item.customerName,
                            grandTotalPaise: item.grandTotalPaise,
                            paidAmountPaise: item.paidAmountPaise,
                            outstandingAmountPaise: item.outstandingAmountPaise,
                            onPaymentSuccess: _loadData,
                          );
                        },
                        icon: const Icon(Icons.payments_outlined, size: 16),
                        label: const Text('Collect Payment'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1E5E3A),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
