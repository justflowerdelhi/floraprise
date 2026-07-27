import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/expense_repository.dart';
import '../../models/expense.dart';
import '../../managers/business_settings_manager.dart';
import '../../widgets/common_widgets.dart';

class ExpenseReportScreen extends StatefulWidget {
  const ExpenseReportScreen({super.key});

  @override
  State<ExpenseReportScreen> createState() => _ExpenseReportScreenState();
}

class _ExpenseReportScreenState extends State<ExpenseReportScreen> {
  final ExpenseRepository _expenseRepository = ExpenseRepository();
  final BusinessSettingsManager _businessSettingsManager =
      BusinessSettingsManager();

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = true;
  String _shopName = 'My Flower Shop';

  int _totalExpenses = 0;
  int _cashExpenses = 0;
  int _upiExpenses = 0;
  int _cardExpenses = 0;
  int _expenseCount = 0;

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
      final expenses =
          await _expenseRepository.getByDateRange(_startDate, _endDate);

      int totalExpenses = 0;
      int cashExpenses = 0;
      int upiExpenses = 0;
      int cardExpenses = 0;

      for (final expense in expenses) {
        final amount = expense.amount;
        totalExpenses += amount;
        switch (expense.paymentMode) {
          case PaymentMode.cash:
            cashExpenses += amount;
            break;
          case PaymentMode.upi:
            upiExpenses += amount;
            break;
          case PaymentMode.card:
            cardExpenses += amount;
            break;
        }
      }

      if (!mounted) return;
      setState(() {
        _totalExpenses = totalExpenses;
        _cashExpenses = cashExpenses;
        _upiExpenses = upiExpenses;
        _cardExpenses = cardExpenses;
        _expenseCount = expenses.length;
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
        title: const Text('Expense Report'),
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
                _buildTransactionCount(),
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
            'Total Expenses',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹ ${(_totalExpenses / 100).toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.red,
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
            amount: _cashExpenses,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _PaymentModeRow(
            label: 'UPI',
            amount: _upiExpenses,
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _PaymentModeRow(
            label: 'Card',
            amount: _cardExpenses,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCount() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Total Transactions',
              style: TextStyle(fontSize: 14),
            ),
          ),
          Text(
            _expenseCount.toString(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
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
