import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/order_repository.dart';
import '../../managers/business_settings_manager.dart';
import '../../widgets/common_widgets.dart';

class TopCustomersReportScreen extends StatefulWidget {
  const TopCustomersReportScreen({super.key});

  @override
  State<TopCustomersReportScreen> createState() =>
      _TopCustomersReportScreenState();
}

class _TopCustomersReportScreenState extends State<TopCustomersReportScreen> {
  final OrderRepository _orderRepository = OrderRepository();
  final BusinessSettingsManager _businessSettingsManager =
      BusinessSettingsManager();

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = true;
  String _shopName = 'My Flower Shop';

  List<_CustomerData> _topCustomers = [];

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
      final sortedCustomers = await _orderRepository.getTopCustomerStatistics(
        startDate: _startDate,
        endDate: _endDate,
        limit: 10,
      );

      if (!mounted) return;
      setState(() {
        _topCustomers = sortedCustomers
            .map(
              (customer) => _CustomerData(
                customerId: customer.customerId,
                customerName: customer.customerName,
                totalAmount: customer.lifetimePurchasePaise,
                orderCount: customer.previousOrders,
              ),
            )
            .toList();
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
        title: const Text('Top Customers'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildDateRangeSelector(),
                const SizedBox(height: 16),
                if (_topCustomers.isEmpty)
                  _buildEmptyState()
                else
                  _buildCustomerList(),
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

  Widget _buildEmptyState() {
    return AppCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.person_off_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No customers found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different date range',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top 10 Customers',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_topCustomers.length, (index) {
            final customer = _topCustomers[index];
            return _CustomerRow(
              rank: index + 1,
              customer: customer,
            );
          }),
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

class _CustomerRow extends StatelessWidget {
  final int rank;
  final _CustomerData customer;

  const _CustomerRow({
    required this.rank,
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _RankBadge(rank: rank),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.customerName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${customer.orderCount} orders',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹ ${(customer.totalAmount / 100).toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    Color color;
    if (rank == 1) {
      color = Colors.amber;
    } else if (rank == 2) {
      color = Colors.grey;
    } else if (rank == 3) {
      color = Colors.brown;
    } else {
      color = Theme.of(context).colorScheme.primary;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          rank.toString(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _CustomerData {
  final int? customerId;
  final String customerName;
  int totalAmount;
  int orderCount;

  _CustomerData({
    required this.customerId,
    required this.customerName,
    required this.totalAmount,
    required this.orderCount,
  });
}
