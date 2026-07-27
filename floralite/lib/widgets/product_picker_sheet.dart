import 'package:flutter/material.dart';

import '../data/repositories/product_repository.dart';

Future<ProductRecord?> showProductPickerSheet(BuildContext context) {
  return showModalBottomSheet<ProductRecord>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => const _ProductPickerSheet(),
  );
}

class _ProductPickerSheet extends StatefulWidget {
  const _ProductPickerSheet();

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  final ProductRepository _repository = ProductRepository();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  List<ProductInventoryRecord> _products = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rows = await _repository.listActiveProductsWithInventory();
      if (!mounted) return;
      setState(() {
        _products = rows;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load products. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _products.where((p) {
      if (query.isEmpty) return true;
      return p.name.toLowerCase().contains(query) ||
          p.sku.toLowerCase().contains(query) ||
          p.manufacturerBarcode.toLowerCase().contains(query) ||
          p.florapriseBarcode.toLowerCase().contains(query);
    }).toList();

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Search Product',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search product, SKU, or barcode',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
          ),
          Expanded(
            child: _buildBody(filtered),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<ProductInventoryRecord> filtered) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _load,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (filtered.isEmpty) {
      return const Center(child: Text('No products found'));
    }

    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final product = filtered[index];
        return ListTile(
          title: Text(product.name),
          subtitle: _buildStockSubtitle(product),
          trailing: Text(
            '₹${(product.sellingPricePaise / 100).toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          onTap: () => Navigator.pop(context, _toProductRecord(product)),
        );
      },
    );
  }

  Widget _buildStockSubtitle(ProductInventoryRecord product) {
    final stockText = productPickerAvailabilityText(product);
    if (stockText.isEmpty) {
      return Text(product.category);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            '${product.category} • $stockText',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.circle, size: 10, color: _stockIndicatorColor(product)),
      ],
    );
  }

  Color _stockIndicatorColor(ProductInventoryRecord product) {
    if (product.currentQty <= 0) {
      return Colors.red;
    }
    if (product.minQty > 0 && product.currentQty <= product.minQty) {
      return Colors.amber.shade700;
    }
    return Colors.green;
  }

  ProductRecord _toProductRecord(ProductInventoryRecord product) {
    return ProductRecord(
      id: product.id,
      name: product.name,
      category: product.category,
      defaultUnit: product.defaultUnit,
      sellingPricePaise: product.sellingPricePaise,
      purchasePricePaise: product.purchasePricePaise,
      gstPercent: product.gstPercent,
      sku: product.sku,
      manufacturerBarcode: product.manufacturerBarcode,
      florapriseBarcode: product.florapriseBarcode,
      trackInventory: product.trackInventory,
      minStock: product.minQty,
      supplier: '',
      notes: '',
      active: product.active,
      favorite: product.favorite,
      deletedAt: null,
      createdAt: '',
      updatedAt: '',
    );
  }
}

@visibleForTesting
String productPickerAvailabilityText(ProductInventoryRecord product) {
  if (!product.trackInventory) {
    return '';
  }
  if (product.currentQty <= 0) {
    return 'Out of Stock';
  }
  return 'Stock: ${_formatStockQuantity(product.currentQty, product.defaultUnit)}';
}

String _formatStockQuantity(int quantity, String unit) {
  final trimmedUnit = unit.trim();
  if (trimmedUnit.isEmpty || trimmedUnit == 'Piece') {
    return quantity.toString();
  }

  return '$quantity ${_pluralizeUnit(trimmedUnit, quantity)}';
}

String _pluralizeUnit(String unit, int quantity) {
  if (quantity == 1) {
    return unit;
  }

  switch (unit) {
    case 'Box':
      return 'Boxes';
    case 'Bunch':
      return 'Bunches';
    default:
      return unit.endsWith('s') ? unit : '${unit}s';
  }
}
