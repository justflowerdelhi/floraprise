import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/cloud_profit_margin_repository.dart';
import '../../managers/business_settings_manager.dart';
import '../../providers/storage_mode_provider.dart';
import '../../widgets/common_widgets.dart';

class ProfitMarginReportScreen extends StatefulWidget {
  const ProfitMarginReportScreen({super.key});

  @override
  State<ProfitMarginReportScreen> createState() =>
      _ProfitMarginReportScreenState();
}

class _ProfitMarginReportScreenState extends State<ProfitMarginReportScreen> {
  final BusinessSettingsManager _businessSettingsManager =
      BusinessSettingsManager();
  final CloudProfitMarginRepository _repository = CloudProfitMarginRepository();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String _selectedPreset = 'today';
  bool _isLoading = true;
  String _shopName = 'My Flower Shop';

  CloudProfitMarginSummary? _summary;

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
    if (!context.read<StorageModeProvider>().isCloud) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final summary = await _repository.getProfitMargin(
        fromDate: _startDate,
        toDate: _endDate,
      );
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (_) {
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
        _selectedPreset = 'custom';
      });
      await _loadData();
    }
  }

  void _applyPreset(String preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime start;
    DateTime end;
    switch (preset) {
      case 'today':
        start = today;
        end = today;
        break;
      case 'yesterday':
        start = today.subtract(const Duration(days: 1));
        end = start;
        break;
      case 'this_week':
        start = today.subtract(Duration(days: today.weekday - 1));
        end = today;
        break;
      case 'this_month':
        start = DateTime(today.year, today.month, 1);
        end = today;
        break;
      default:
        return;
    }
    setState(() {
      _startDate = start;
      _endDate = end;
      _selectedPreset = preset;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final isCloud = context.watch<StorageModeProvider>().isCloud;

    return Scaffold(
      appBar: AppBar(title: const Text('Profit / Margin Report')),
      body: !isCloud
          ? _buildCloudRequiredBanner()
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildPresetSelector(),
                    const SizedBox(height: 12),
                    _buildDateRangeSelector(),
                    const SizedBox(height: 16),
                    _buildMarginCard(),
                    const SizedBox(height: 16),
                    _buildBreakdownCard(),
                    if (_summary?.cogsIsEstimate == true) ...[
                      const SizedBox(height: 16),
                      _buildLimitationNotice(),
                    ],
                    const SizedBox(height: 16),
                    _buildReportFooter(),
                  ],
                ),
    );
  }

  Widget _buildCloudRequiredBanner() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_rounded, size: 56, color: Colors.blue.shade700),
            const SizedBox(height: 16),
            Text(
              'Profit / Margin Report requires Cloud Mode',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'This report is calculated from authoritative Cloud data. Switch to Cloud mode in Settings to view it.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetSelector() {
    final presets = <(String, String)>[
      ('today', 'Today'),
      ('yesterday', 'Yesterday'),
      ('this_week', 'This Week'),
      ('this_month', 'This Month'),
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: presets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (value, label) = presets[index];
          final isSelected = _selectedPreset == value;
          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => _applyPreset(value),
          );
        },
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

  Widget _buildMarginCard() {
    final grossProfit = (_summary?.grossProfitPaise ?? 0) / 100;
    final marginPercent = _summary?.marginPercent ?? 0;
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gross Profit',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            '₹ ${grossProfit.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Margin: ${marginPercent.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard() {
    final grossSales = (_summary?.grossSalesPaise ?? 0) / 100;
    final discounts = (_summary?.discountsPaise ?? 0) / 100;
    final netRevenue = (_summary?.netRevenuePaise ?? 0) / 100;
    final cogs = (_summary?.cogsPaise ?? 0) / 100;
    final orderCount = _summary?.orderCount ?? 0;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Breakdown',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _buildBreakdownRow('Gross Sales', grossSales),
          const SizedBox(height: 12),
          _buildBreakdownRow('Discounts', -discounts),
          const SizedBox(height: 12),
          _buildBreakdownRow('Net Revenue', netRevenue),
          const SizedBox(height: 12),
          _buildBreakdownRow('Cost of Goods Sold', -cogs),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Orders',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                '$orderCount',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double amount) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 14)),
        ),
        Text(
          '₹ ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: amount < 0 ? Colors.red.shade700 : null,
          ),
        ),
      ],
    );
  }

  Widget _buildLimitationNotice() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _summary?.cogsLimitationNote ??
                  "Cost of goods sold uses each product's current cost price, "
                      'not a historical cost snapshot at time of sale.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
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
