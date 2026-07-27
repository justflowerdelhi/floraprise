import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/inventory_repository.dart';
import '../../managers/business_settings_manager.dart';
import '../../widgets/common_widgets.dart';

class WastageReportScreen extends StatefulWidget {
  const WastageReportScreen({super.key});

  @override
  State<WastageReportScreen> createState() => _WastageReportScreenState();
}

class _WastageReportScreenState extends State<WastageReportScreen> {
  final InventoryRepository _inventoryRepository = InventoryRepository();
  final BusinessSettingsManager _businessSettingsManager =
      BusinessSettingsManager();

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String? _selectedCategory;
  String? _selectedProduct;
  String? _selectedSupplier;
  String? _selectedReason;
  bool _isLoading = true;
  String _shopName = 'My Flower Shop';

  List<WastageRecord> _wastageRecords = [];
  List<String> _categories = [];
  List<String> _products = [];
  List<String> _suppliers = [];
  List<String> _reasons = [];

  int _totalWastageValue = 0;
  int _totalWastageQuantity = 0;
  int _productsAffected = 0;
  String _highestWastageProduct = 'N/A';

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
      debugPrint('=== Wastage Report Debug ===');
      debugPrint('Start Date: $_startDate');
      debugPrint('End Date: $_endDate');
      debugPrint('Category: $_selectedCategory');
      debugPrint('Product: $_selectedProduct');
      debugPrint('Supplier: $_selectedSupplier');
      debugPrint('Reason: $_selectedReason');
      
      final transactions = await _inventoryRepository.getWastageTransactions(
        startDate: _startDate,
        endDate: _endDate,
        category: _selectedCategory,
        productId: _selectedProduct != null ? int.tryParse(_selectedProduct!) : null,
        supplier: _selectedSupplier,
        reason: _selectedReason,
      );
      
      debugPrint('Transactions fetched: ${transactions.length}');
      for (final txn in transactions) {
        debugPrint('  - ${txn.productName} | ${txn.txnType} | ${txn.qty} | ${txn.reason}');
      }

      // Extract unique values for filters
      final categories = <String>{};
      final products = <String>{};
      final suppliers = <String>{};
      final reasons = <String>{};

      final wastageRecords = <WastageRecord>[];
      int totalValue = 0;
      int totalQuantity = 0;
      final productQuantities = <String, int>{};

      for (final txn in transactions) {
        if (txn.category != null) categories.add(txn.category!);
        if (txn.productName != null) products.add(txn.productName!);
        if (txn.supplier.isNotEmpty) {
          suppliers.add(txn.supplier);
        }
        if (txn.reason.isNotEmpty) {
          reasons.add(txn.reason);
        }

        final totalValuePaise = txn.qty * (txn.purchasePricePaise ?? 0);
        totalValue += totalValuePaise;
        totalQuantity += txn.qty;

        final productName = txn.productName ?? 'Unknown';
        productQuantities[productName] =
            (productQuantities[productName] ?? 0) + txn.qty;

        wastageRecords.add(WastageRecord(
          date: txn.createdAt,
          productName: txn.productName ?? 'Unknown',
          category: txn.category ?? 'Other',
          supplier: txn.supplier,
          qty: txn.qty,
          unit: txn.unit ?? 'Piece',
          unitCost: txn.purchasePricePaise ?? 0,
          totalValue: totalValuePaise,
          reason: txn.reason,
        ));
      }

      // Find highest wastage product
      String highestProduct = 'N/A';
      int maxQty = 0;
      for (final entry in productQuantities.entries) {
        if (entry.value > maxQty) {
          maxQty = entry.value;
          highestProduct = entry.key;
        }
      }

      if (!mounted) return;
      setState(() {
        _wastageRecords = wastageRecords;
        _categories = categories.toList()..sort();
        _products = products.toList()..sort();
        _suppliers = suppliers.toList()..sort();
        _reasons = reasons.toList()..sort();
        _totalWastageValue = totalValue;
        _totalWastageQuantity = totalQuantity;
        _productsAffected = productQuantities.length;
        _highestWastageProduct = highestProduct;
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
        title: const Text('Wastage Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildDateRangeSelector(),
                const SizedBox(height: 16),
                _buildFilters(),
                const SizedBox(height: 16),
                _buildSummaryCards(),
                const SizedBox(height: 24),
                _buildReportTable(),
                const SizedBox(height: 24),
                _buildAnalytics(),
                const SizedBox(height: 24),
                _buildReportFooter(),
              ],
            ),
    );
  }

  Widget _buildDateRangeSelector() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Date Range',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectDate(context, true),
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    DateFormat('dd/MM/yyyy').format(_startDate),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('to'),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectDate(context, false),
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    DateFormat('dd/MM/yyyy').format(_endDate),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filters',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_categories.isNotEmpty) ...[
            _buildDropdown('Category', _selectedCategory, _categories, (value) {
              setState(() => _selectedCategory = value);
              _loadData();
            }),
            const SizedBox(height: 8),
          ],
          if (_products.isNotEmpty) ...[
            _buildDropdown('Product', _selectedProduct, _products, (value) {
              setState(() => _selectedProduct = value);
              _loadData();
            }),
            const SizedBox(height: 8),
          ],
          if (_suppliers.isNotEmpty) ...[
            _buildDropdown('Supplier', _selectedSupplier, _suppliers, (value) {
              setState(() => _selectedSupplier = value);
              _loadData();
            }),
            const SizedBox(height: 8),
          ],
          if (_reasons.isNotEmpty) ...[
            _buildDropdown('Wastage Reason', _selectedReason, _reasons, (value) {
              setState(() => _selectedReason = value);
              _loadData();
            }),
          ],
          if (_selectedCategory != null ||
              _selectedProduct != null ||
              _selectedSupplier != null ||
              _selectedReason != null)
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = null;
                  _selectedProduct = null;
                  _selectedSupplier = null;
                  _selectedReason = null;
                });
                _loadData();
              },
              child: const Text('Clear Filters'),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('All'),
        ),
        ...items.map((item) => DropdownMenuItem(
              value: item,
              child: Text(item),
            )),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Wastage Value',
                '₹${(_totalWastageValue / 100).toStringAsFixed(0)}',
                Icons.money_off,
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Total Wastage Quantity',
                '$_totalWastageQuantity',
                Icons.inventory_2,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Products Affected',
                '$_productsAffected',
                Icons.category,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Highest Wastage Product',
                _highestWastageProduct,
                Icons.trending_up,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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

  Widget _buildReportTable() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Wastage Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_wastageRecords.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('No wastage records found for selected filters'),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 12,
                headingRowColor: WidgetStateProperty.all(
                  Colors.grey.shade200,
                ),
                columns: const [
                  DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Product', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Supplier', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Unit', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Unit Cost', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Total Value', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Reason', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: _wastageRecords.map((record) {
                  return DataRow(
                    cells: [
                      DataCell(Text(_formatDate(record.date))),
                      DataCell(Text(record.productName)),
                      DataCell(Text(record.category)),
                      DataCell(Text(record.supplier.isEmpty ? '-' : record.supplier)),
                      DataCell(Text(record.qty.toString())),
                      DataCell(Text(record.unit)),
                      DataCell(Text('₹${(record.unitCost / 100).toStringAsFixed(2)}')),
                      DataCell(Text('₹${(record.totalValue / 100).toStringAsFixed(2)}')),
                      DataCell(Text(record.reason.isEmpty ? '-' : record.reason)),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalytics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnalyticsSection('Wastage by Product', _getWastageByProduct()),
        const SizedBox(height: 16),
        _buildAnalyticsSection('Wastage by Category', _getWastageByCategory()),
        const SizedBox(height: 16),
        _buildAnalyticsSection('Wastage by Supplier', _getWastageBySupplier()),
        const SizedBox(height: 16),
        _buildAnalyticsSection('Wastage by Reason', _getWastageByReason()),
        const SizedBox(height: 16),
        _buildMonthlyTrend(),
      ],
    );
  }

  Widget _buildAnalyticsSection(String title, List<AnalyticsItem> items) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text('No data available')
          else
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(item.label)),
                      Text(
                        'Qty: ${item.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '₹${(item.value / 100).toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  List<AnalyticsItem> _getWastageByProduct() {
    final productData = <String, _ProductData>{};
    for (final record in _wastageRecords) {
      final data = productData[record.productName] ?? _ProductData();
      data.quantity += record.qty;
      data.value += record.totalValue;
      productData[record.productName] = data;
    }
    return productData.entries
        .map((e) => AnalyticsItem(
              label: e.key,
              quantity: e.value.quantity,
              value: e.value.value,
            ))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  List<AnalyticsItem> _getWastageByCategory() {
    final categoryData = <String, _ProductData>{};
    for (final record in _wastageRecords) {
      final data = categoryData[record.category] ?? _ProductData();
      data.quantity += record.qty;
      data.value += record.totalValue;
      categoryData[record.category] = data;
    }
    return categoryData.entries
        .map((e) => AnalyticsItem(
              label: e.key,
              quantity: e.value.quantity,
              value: e.value.value,
            ))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  List<AnalyticsItem> _getWastageBySupplier() {
    final supplierData = <String, _ProductData>{};
    for (final record in _wastageRecords) {
      final supplier = record.supplier.isEmpty ? 'No Supplier' : record.supplier;
      final data = supplierData[supplier] ?? _ProductData();
      data.quantity += record.qty;
      data.value += record.totalValue;
      supplierData[supplier] = data;
    }
    return supplierData.entries
        .map((e) => AnalyticsItem(
              label: e.key,
              quantity: e.value.quantity,
              value: e.value.value,
            ))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  List<AnalyticsItem> _getWastageByReason() {
    final reasonData = <String, _ProductData>{};
    for (final record in _wastageRecords) {
      final reason = record.reason.isEmpty ? 'Not Specified' : record.reason;
      final data = reasonData[reason] ?? _ProductData();
      data.quantity += record.qty;
      data.value += record.totalValue;
      reasonData[reason] = data;
    }
    return reasonData.entries
        .map((e) => AnalyticsItem(
              label: e.key,
              quantity: e.value.quantity,
              value: e.value.value,
            ))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  Widget _buildMonthlyTrend() {
    final monthlyData = <String, int>{};
    for (final record in _wastageRecords) {
      final date = DateTime.parse(record.date);
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + record.totalValue;
    }

    final sortedMonths = monthlyData.keys.toList()..sort();

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Wastage Trend',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (sortedMonths.isEmpty)
            const Text('No data available')
          else
            ...sortedMonths.map((month) {
              final parts = month.split('-');
              final monthName = DateFormat('MMM yyyy').format(
                DateTime(int.parse(parts[0]), int.parse(parts[1])),
              );
              final value = monthlyData[month] ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(monthName),
                    Text(
                      '₹${(value / 100).toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildReportFooter() {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Text(
          'Generated by $_shopName',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Generated on ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
      _loadData();
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return 'N/A';
    }
  }
}

class WastageRecord {
  final String date;
  final String productName;
  final String category;
  final String supplier;
  final int qty;
  final String unit;
  final int unitCost;
  final int totalValue;
  final String reason;

  WastageRecord({
    required this.date,
    required this.productName,
    required this.category,
    required this.supplier,
    required this.qty,
    required this.unit,
    required this.unitCost,
    required this.totalValue,
    required this.reason,
  });
}

class AnalyticsItem {
  final String label;
  final int quantity;
  final int value;

  AnalyticsItem({
    required this.label,
    required this.quantity,
    required this.value,
  });
}

class _ProductData {
  int quantity = 0;
  int value = 0;
}
