import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/inventory_repository.dart';
import '../../managers/business_settings_manager.dart';
import '../../widgets/common_widgets.dart';

class LowStockReportScreen extends StatefulWidget {
  const LowStockReportScreen({super.key});

  @override
  State<LowStockReportScreen> createState() => _LowStockReportScreenState();
}

class _LowStockReportScreenState extends State<LowStockReportScreen> {
  final InventoryRepository _inventoryRepository = InventoryRepository();
  final BusinessSettingsManager _businessSettingsManager =
      BusinessSettingsManager();

  bool _isLoading = true;
  String _shopName = 'My Flower Shop';

  List<Map<String, dynamic>> _lowStockItems = [];

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
      final inventoryItems = await _inventoryRepository.getLowStockItems();

      if (!mounted) return;
      setState(() {
        _lowStockItems = inventoryItems;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Low Stock Report'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryCard(),
                const SizedBox(height: 16),
                if (_lowStockItems.isEmpty)
                  _buildEmptyState()
                else
                  _buildStockList(),
                const SizedBox(height: 16),
                _buildReportFooter(),
              ],
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
            'Items Needing Restock',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _lowStockItems.length.toString(),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return AppCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 64,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          Text(
            'All items are well stocked',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'No items need restocking',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockList() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Low Stock Items',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_lowStockItems.length, (index) {
            final item = _lowStockItems[index];
            return _StockRow(item: item);
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

class _StockRow extends StatelessWidget {
  final Map<String, dynamic> item;

  const _StockRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final name = item['name'] as String? ?? 'Unknown';
    final currentStock = item['current_stock'] as int? ?? 0;
    final minStock = item['min_stock'] as int? ?? 0;
    final unit = item['unit'] as String? ?? 'pcs';

    final stockLevel = currentStock / (minStock > 0 ? minStock : 1);
    Color statusColor;
    String statusText;

    if (stockLevel <= 0.25) {
      statusColor = Colors.red;
      statusText = 'Critical';
    } else if (stockLevel <= 0.5) {
      statusColor = Colors.orange;
      statusText = 'Low';
    } else {
      statusColor = Colors.amber;
      statusText = 'Warning';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.inventory_2_rounded,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Min: $minStock $unit',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$currentStock $unit',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 11,
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
