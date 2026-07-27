import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/order_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../models/order_workspace_models.dart';
import '../../managers/business_settings_manager.dart';
import '../../widgets/common_widgets.dart';

class TopProductsReportScreen extends StatefulWidget {
  const TopProductsReportScreen({super.key});

  @override
  State<TopProductsReportScreen> createState() =>
      _TopProductsReportScreenState();
}

class _TopProductsReportScreenState extends State<TopProductsReportScreen> {
  final OrderRepository _orderRepository = OrderRepository();
  final ProductRepository _productRepository = ProductRepository();
  final BusinessSettingsManager _businessSettingsManager =
      BusinessSettingsManager();

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = true;
  String _shopName = 'My Flower Shop';

  List<_ProductData> _topProducts = [];

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
      final products = await _productRepository.listProducts(showActive: true, showInactive: false);

      Map<int, _ProductData> productMap = {};

      for (final order in orders) {
        final orderLines = await _orderRepository.getOrderLines(order.id);
        for (final line in orderLines) {
          final productId = line['product_id'] as int?;
          if (productId == null) continue;

          if (!productMap.containsKey(productId)) {
            final product = products.firstWhere(
              (p) => p.id == productId,
              orElse: () => products.first,
            );
            productMap[productId] = _ProductData(
              productId: productId,
              productName: product.name,
              quantitySold: 0,
              totalRevenue: 0,
            );
          }
          final quantity = (line['quantity'] as num?)?.toInt() ?? 0;
          final price = (line['total_price'] as num?)?.toInt() ?? 0;
          productMap[productId]!.quantitySold += quantity;
          productMap[productId]!.totalRevenue += price;
        }
      }

      final sortedProducts = productMap.values.toList()
        ..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));

      if (!mounted) return;
      setState(() {
        _topProducts = sortedProducts.take(10).toList();
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
        title: const Text('Top Products'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildDateRangeSelector(),
                const SizedBox(height: 16),
                if (_topProducts.isEmpty)
                  _buildEmptyState()
                else
                  _buildProductList(),
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
            Icons.inventory_2_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No products found',
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

  Widget _buildProductList() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top 10 Products',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_topProducts.length, (index) {
            final product = _topProducts[index];
            return _ProductRow(
              rank: index + 1,
              product: product,
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

class _ProductRow extends StatelessWidget {
  final int rank;
  final _ProductData product;

  const _ProductRow({
    required this.rank,
    required this.product,
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
                  product.productName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${product.quantitySold} sold',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹ ${(product.totalRevenue / 100).toStringAsFixed(2)}',
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

class _ProductData {
  final int productId;
  final String productName;
  int quantitySold;
  int totalRevenue;

  _ProductData({
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.totalRevenue,
  });
}
