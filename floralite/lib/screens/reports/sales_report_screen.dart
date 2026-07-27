import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/order_repository.dart';
import '../../models/order_workspace_models.dart';
import '../../managers/business_settings_manager.dart';
import '../../widgets/common_widgets.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  final OrderRepository _orderRepository = OrderRepository();
  final BusinessSettingsManager _businessSettingsManager =
      BusinessSettingsManager();

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = true;
  String _shopName = 'My Flower Shop';

  int _totalSales = 0;
  int _cashSales = 0;
  int _upiSales = 0;
  int _cardSales = 0;
  int _creditSales = 0;
  int _orderCount = 0;

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
      final orders = await _orderRepository.getOrdersForWorkspace(
        tab: 'all',
        searchQuery: '',
        filters: const OrderWorkspaceFilters(),
        limit: 10000,
      );

      int totalSales = 0;
      int cashSales = 0;
      int upiSales = 0;
      int cardSales = 0;
      int creditSales = 0;

      for (final order in orders) {
        final amount = order.grandTotalPaise;
        totalSales += amount;
        final paymentSummary = await _orderRepository.getOrderSummary(order.id);
        final paymentMode = (paymentSummary['payment_mode'] as String?)?.toLowerCase() ?? 'cash';
        switch (paymentMode) {
          case 'cash':
            cashSales += amount;
            break;
          case 'upi':
            upiSales += amount;
            break;
          case 'card':
            cardSales += amount;
            break;
          case 'credit':
            creditSales += amount;
            break;
        }
      }

      if (!mounted) return;
      setState(() {
        _totalSales = totalSales;
        _cashSales = cashSales;
        _upiSales = upiSales;
        _cardSales = cardSales;
        _creditSales = creditSales;
        _orderCount = orders.length;
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
        title: const Text('Sales Report'),
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
                _buildPaymentModeBreakdown(),
                const SizedBox(height: 16),
                _buildTransactionCounts(),
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
            'Total Sales',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹ ${(_totalSales / 100).toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentModeBreakdown() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Mode Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _PaymentModeRow(
            label: 'Cash',
            amount: _cashSales,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _PaymentModeRow(
            label: 'UPI',
            amount: _upiSales,
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _PaymentModeRow(
            label: 'Card',
            amount: _cardSales,
            color: Colors.purple,
          ),
          const SizedBox(height: 12),
          _PaymentModeRow(
            label: 'Credit',
            amount: _creditSales,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCounts() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transaction Counts',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _TransactionCountRow(
            label: 'Orders',
            count: _orderCount,
            icon: Icons.shopping_bag_rounded,
          ),
          const SizedBox(height: 12),
          _TransactionCountRow(
            label: 'Total Transactions',
            count: _orderCount,
            icon: Icons.receipt_long_rounded,
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

class _PaymentModeRow extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;

  const _PaymentModeRow({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Text(
          '₹ ${(amount / 100).toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TransactionCountRow extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;

  const _TransactionCountRow({
    required this.label,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
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
