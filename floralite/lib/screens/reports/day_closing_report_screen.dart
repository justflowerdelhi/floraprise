import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/day_closing_repository.dart';
import '../../managers/business_settings_manager.dart';
import '../../widgets/common_widgets.dart';

class DayClosingReportScreen extends StatefulWidget {
  const DayClosingReportScreen({super.key});

  @override
  State<DayClosingReportScreen> createState() =>
      _DayClosingReportScreenState();
}

class _DayClosingReportScreenState extends State<DayClosingReportScreen> {
  final DayClosingRepository _dayClosingRepository = DayClosingRepository();
  final BusinessSettingsManager _businessSettingsManager =
      BusinessSettingsManager();

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = true;
  String _shopName = 'My Flower Shop';

  List<Map<String, dynamic>> _dayClosings = [];
  int _totalSales = 0;
  int _totalExpenses = 0;
  int _closedDays = 0;

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
      final closings =
          await _dayClosingRepository.getByDateRange(_startDate, _endDate);

      int totalSales = 0;
      int totalExpenses = 0;

      for (final closing in closings) {
        totalSales += closing.cashSales +
            closing.upiSales +
            closing.cardSales +
            closing.creditSales;
        totalExpenses += closing.cashExpenses +
            closing.upiExpenses +
            closing.cardExpenses;
      }

      if (!mounted) return;
      setState(() {
        _dayClosings = closings.map((c) => c.toMap()).toList();
        _totalSales = totalSales;
        _totalExpenses = totalExpenses;
        _closedDays = closings.length;
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
        title: const Text('Day Closing Report'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildDateRangeSelector(),
                const SizedBox(height: 16),
                _buildSummaryCards(),
                const SizedBox(height: 16),
                if (_dayClosings.isEmpty)
                  _buildEmptyState()
                else
                  _buildDayClosingList(),
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

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Total Sales',
            value: '₹ ${(_totalSales / 100).toStringAsFixed(0)}',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'Total Expenses',
            value: '₹ ${(_totalExpenses / 100).toStringAsFixed(0)}',
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return AppCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.nights_stay_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No day closings found',
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

  Widget _buildDayClosingList() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Day Closings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$_closedDays days',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(_dayClosings.length, (index) {
            final closing = _dayClosings[index];
            return _DayClosingRow(closing: closing);
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

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayClosingRow extends StatelessWidget {
  final Map<String, dynamic> closing;

  const _DayClosingRow({required this.closing});

  @override
  Widget build(BuildContext context) {
    final dateStr = closing['date'] as String? ?? '';
    final cashSales = closing['cash_sales'] as int? ?? 0;
    final upiSales = closing['upi_sales'] as int? ?? 0;
    final cardSales = closing['card_sales'] as int? ?? 0;
    final creditSales = closing['credit_sales'] as int? ?? 0;
    final cashExpenses = closing['cash_expenses'] as int? ?? 0;
    final expectedCash = closing['expected_cash'] as int? ?? 0;
    final countedCash = closing['counted_cash'] as int? ?? 0;
    final difference = closing['difference'] as int? ?? 0;

    final totalSales = cashSales + upiSales + cardSales + creditSales;
    final dateFormat = DateFormat('MMM dd, yyyy');
    final formattedDate = dateStr.isNotEmpty
        ? dateFormat.format(DateTime.parse(dateStr))
        : 'Unknown';

    final isMatch = difference == 0;
    final diffColor = isMatch ? Colors.green : Colors.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formattedDate,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: diffColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isMatch ? 'Matched' : 'Mismatch',
                  style: TextStyle(
                    fontSize: 11,
                    color: diffColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Sales',
                  value: '₹ ${(totalSales / 100).toStringAsFixed(0)}',
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Expenses',
                  value: '₹ ${(cashExpenses / 100).toStringAsFixed(0)}',
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Expected',
                  value: '₹ ${(expectedCash / 100).toStringAsFixed(0)}',
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Counted',
                  value: '₹ ${(countedCash / 100).toStringAsFixed(0)}',
                ),
              ),
            ],
          ),
          if (!isMatch) ...[
            const SizedBox(height: 8),
            Text(
              'Difference: ₹ ${(difference / 100).toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                color: diffColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const Divider(height: 24),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
