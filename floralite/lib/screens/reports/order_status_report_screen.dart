import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/cloud_order_status_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../models/order_workspace_models.dart';
import '../../managers/business_settings_manager.dart';
import '../../providers/storage_mode_provider.dart';
import '../../widgets/common_widgets.dart';

class OrderStatusReportScreen extends StatefulWidget {
  const OrderStatusReportScreen({super.key});

  @override
  State<OrderStatusReportScreen> createState() =>
      _OrderStatusReportScreenState();
}

class _OrderStatusReportScreenState extends State<OrderStatusReportScreen> {
  final OrderRepository _orderRepository = OrderRepository();
  final CloudOrderStatusRepository _cloudOrderStatusRepository =
      CloudOrderStatusRepository();
  final BusinessSettingsManager _businessSettingsManager =
      BusinessSettingsManager();

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = true;
  String _shopName = 'My Flower Shop';
  bool _isCloud = false;

  int _pendingCount = 0;
  int _inProgressCount = 0;
  int _readyCount = 0;
  int _completedCount = 0;
  int _cancelledCount = 0;
  int _totalCount = 0;

  int _deliveryCount = 0;
  int _pickupCount = 0;
  int _takeAwayCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadBusinessIdentity();
  }

  Future<void> _loadBusinessIdentity() async {
    final settings = await _businessSettingsManager.load();
    if (!mounted) return;
    setState(() {
      _shopName = settings.shopName.trim().isEmpty
          ? 'My Flower Shop'
          : settings.shopName;
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      bool isCloud = false;
      try {
        isCloud = context.read<StorageModeProvider>().isCloud;
      } catch (_) {}

      if (isCloud) {
        final report = await _cloudOrderStatusRepository.getOrderStatusReport(
          fromDate: _startDate,
          toDate: _endDate,
        );

        if (!mounted) return;
        setState(() {
          _isCloud = true;
          _pendingCount = report.pending;
          _inProgressCount = report.inProgress;
          _readyCount = report.ready;
          _completedCount = report.completed;
          _cancelledCount = report.cancelled;
          _totalCount = report.total;
          _deliveryCount = report.fulfillment.delivery;
          _pickupCount = report.fulfillment.pickup;
          _takeAwayCount = report.fulfillment.takeAway;
          _isLoading = false;
        });
        return;
      }

      final orders = await _orderRepository.getOrdersForWorkspace(
        tab: 'all',
        searchQuery: '',
        filters: const OrderWorkspaceFilters(),
        limit: 10000,
      );

      int pendingCount = 0;
      int inProgressCount = 0;
      int readyCount = 0;
      int completedCount = 0;
      int cancelledCount = 0;

      for (final order in orders) {
        final status = order.status.toLowerCase();
        switch (status) {
          case 'pending':
            pendingCount++;
            break;
          case 'in progress':
            inProgressCount++;
            break;
          case 'ready':
            readyCount++;
            break;
          case 'completed':
            completedCount++;
            break;
          case 'cancelled':
            cancelledCount++;
            break;
        }
      }

      if (!mounted) return;
      setState(() {
        _isCloud = false;
        _pendingCount = pendingCount;
        _inProgressCount = inProgressCount;
        _readyCount = readyCount;
        _completedCount = completedCount;
        _cancelledCount = cancelledCount;
        _totalCount = orders.length;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Status Report'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildDateRangeSelector(),
                const SizedBox(height: 16),
                _buildSummaryCard(),
                const SizedBox(height: 16),
                _buildStatusBreakdown(),
                if (_isCloud ||
                    _deliveryCount + _pickupCount + _takeAwayCount > 0) ...[
                  const SizedBox(height: 16),
                  _buildFulfillmentBreakdown(),
                ],
                const SizedBox(height: 16),
                _buildReportFooter(),
              ],
            ),
    );
  }

  Widget _buildDateRangeSelector() {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: _selectDateRange,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to change date range',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
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

  Widget _buildSummaryCard() {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Orders',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _totalCount.toString(),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBreakdown() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _StatusRow(
            label: 'Pending',
            count: _pendingCount,
            color: Colors.orange,
            icon: Icons.pending_rounded,
          ),
          const SizedBox(height: 12),
          _StatusRow(
            label: 'In Progress',
            count: _inProgressCount,
            color: Colors.blue,
            icon: Icons.autorenew_rounded,
          ),
          const SizedBox(height: 12),
          _StatusRow(
            label: 'Ready',
            count: _readyCount,
            color: Colors.green,
            icon: Icons.check_circle_rounded,
          ),
          const SizedBox(height: 12),
          _StatusRow(
            label: 'Completed',
            count: _completedCount,
            color: Colors.purple,
            icon: Icons.done_all_rounded,
          ),
          const SizedBox(height: 12),
          _StatusRow(
            label: 'Cancelled',
            count: _cancelledCount,
            color: Colors.red,
            icon: Icons.cancel_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildFulfillmentBreakdown() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fulfillment Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _StatusRow(
            label: 'Delivery',
            count: _deliveryCount,
            color: Colors.blue,
            icon: Icons.local_shipping_rounded,
          ),
          const SizedBox(height: 12),
          _StatusRow(
            label: 'Pickup',
            count: _pickupCount,
            color: Colors.orange,
            icon: Icons.storefront_rounded,
          ),
          const SizedBox(height: 12),
          _StatusRow(
            label: 'Walk-in Sale',
            count: _takeAwayCount,
            color: Colors.teal,
            icon: Icons.shopping_bag_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildReportFooter() {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shop: $_shopName',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Generated: ${dateFormat.format(DateTime.now())}',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatusRow({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
