import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repositories/inventory_repository.dart';
import '../data/repositories/cloud_product_repository.dart';
import '../data/repositories/product_repository.dart';
import '../models/gst_calculation_type.dart';
import '../providers/auth_provider.dart';
import '../providers/inventory_provider.dart';
import '../screens/purchase_list_screen.dart';

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
  late CloudProductRepository _cloudProductRepository;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  List<ProductInventoryRecord> _products = const [];

  @override
  void initState() {
    super.initState();
    _cloudProductRepository = CloudProductRepository();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final auth = context.read<AuthProvider?>()?.authService;
      if (auth != null) {
        _cloudProductRepository = CloudProductRepository(auth: auth);
      }
    } catch (_) {}
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
      final inventoryProvider = context.read<InventoryProvider>();
      final isCloud = inventoryProvider.isCloud || kIsWeb;
      final products = isCloud
          ? productPickerRowsFromCloudInventory(
              await _loadCloudInventoryProducts(inventoryProvider),
              await _cloudProductRepository.listProducts(),
            )
          : await _repository.listActiveProductsWithInventory();
      if (!mounted) return;
      setState(() {
        _products = products;
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

  Future<List<InventoryProductRecord>> _loadCloudInventoryProducts(
    InventoryProvider inventoryProvider,
  ) async {
    try {
      await inventoryProvider.loadProducts();
      return inventoryProvider.products;
    } catch (_) {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = productPickerVisibleProducts(_products, query);

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
        final isOutOfStock = productPickerIsOutOfStock(product);
        return ListTile(
          enabled: true,
          title: _buildProductTitle(product),
          subtitle: _buildStockSubtitle(product),
          trailing: Text(
            '₹${(product.sellingPricePaise / 100).toStringAsFixed(0)}',
            style: TextStyle(
              color: isOutOfStock ? Colors.grey : null,
              fontWeight: FontWeight.w600,
            ),
          ),
          onTap: productPickerCanSelect(product)
              ? () => Navigator.pop(context, _toProductRecord(product))
              : () => _showOutOfStockActions(product),
        );
      },
    );
  }

  Widget _buildProductTitle(ProductInventoryRecord product) {
    final isOutOfStock = productPickerIsOutOfStock(product);
    final isLowStock = productPickerIsLowStock(product);

    return Row(
      children: [
        Expanded(
          child: Text(
            product.name,
            style: TextStyle(color: isOutOfStock ? Colors.grey : null),
          ),
        ),
        if (isOutOfStock)
          _buildStockBadge('Out of Stock', Colors.red)
        else if (isLowStock)
          _buildStockBadge('Low Stock', Colors.orange),
      ],
    );
  }

  Widget _buildStockBadge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
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

  Future<void> _showOutOfStockActions(ProductInventoryRecord product) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'OUT OF STOCK',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.add_box_outlined),
                title: const Text('Update Stock'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showUpdateStockDialog(product);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.shopping_basket_outlined),
                title: const Text('Create Purchase List'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openPurchaseList(product);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showUpdateStockDialog(ProductInventoryRecord product) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _UpdateStockDialog(product: product),
    );
    if (updated == true) {
      await _load();
    }
  }

  void _openPurchaseList(ProductInventoryRecord product) {
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    Navigator.pop(context);
    rootNavigator.push(
      MaterialPageRoute<void>(
        builder: (_) => PurchaseListScreen(initialProductId: product.id),
      ),
    );
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
      cloudProductId: product.cloudProductId,
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

class _UpdateStockDialog extends StatefulWidget {
  const _UpdateStockDialog({required this.product});

  final ProductInventoryRecord product;

  @override
  State<_UpdateStockDialog> createState() => _UpdateStockDialogState();
}

class _UpdateStockDialogState extends State<_UpdateStockDialog> {
  final _formKey = GlobalKey<FormState>();
  final _receivedQuantityController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _supplierController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final purchasePricePaise = widget.product.purchasePricePaise;
    if (purchasePricePaise != null && purchasePricePaise > 0) {
      _purchasePriceController.text =
          (purchasePricePaise / 100).toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _receivedQuantityController.dispose();
    _purchasePriceController.dispose();
    _supplierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Stock'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.product.name,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Text(
                'Current Stock: ${_formatStockQuantity(widget.product.currentQty, widget.product.defaultUnit)}',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _receivedQuantityController,
                decoration:
                    const InputDecoration(labelText: 'Received Quantity'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final quantity = int.tryParse(value?.trim() ?? '');
                  if (quantity == null || quantity <= 0) {
                    return 'Enter a quantity greater than zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _purchasePriceController,
                decoration: const InputDecoration(labelText: 'Purchase Price'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final price = double.tryParse(value?.trim() ?? '');
                  if (price == null || price <= 0) {
                    return 'Enter a purchase price greater than zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _supplierController,
                decoration:
                    const InputDecoration(labelText: 'Supplier (optional)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final quantity = int.parse(_receivedQuantityController.text.trim());
    final price = double.parse(_purchasePriceController.text.trim());
    final purchasePricePaise = (price * 100).round();
    final supplier = _supplierController.text.trim();

    try {
      await context.read<InventoryProvider>().purchase(
            productId: widget.product.id,
            quantity: quantity,
            purchasePricePaise: purchasePricePaise,
            supplier: supplier.isEmpty ? null : supplier,
            note: 'POS stock update',
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update stock.')),
      );
    }
  }
}

@visibleForTesting
List<ProductInventoryRecord> productPickerRowsFromCloudInventory(
  List<InventoryProductRecord> inventoryProducts,
  [List<CloudProduct> cloudProducts = const <CloudProduct>[]]
) {
  final inventoryByCloudProductId = {
    for (final product in inventoryProducts)
      if (product.cloudProductId?.trim().isNotEmpty == true)
        product.cloudProductId!.trim().toLowerCase(): product,
  };

  // If cloud catalogue products are available, build rows primarily from them.
  if (cloudProducts.isNotEmpty) {
    final matchedCloudIds = <String>{};
    final rows = <ProductInventoryRecord>[];

    for (final cloudProduct in cloudProducts) {
      if (!cloudProduct.isActive) continue;
      final cloudIdLower = cloudProduct.id.trim().toLowerCase();
      matchedCloudIds.add(cloudIdLower);
      final inv = inventoryByCloudProductId[cloudIdLower];

      final sku = cloudProduct.sku.trim();
      final barcode = (cloudProduct.barcode?.trim().isNotEmpty == true
              ? cloudProduct.barcode!.trim()
              : (cloudProduct.manufacturerBarcode?.trim().isNotEmpty == true
                  ? cloudProduct.manufacturerBarcode!.trim()
                  : inv?.barcode)) ??
          '';
      final manufacturer = (cloudProduct.manufacturerBarcode?.trim().isNotEmpty == true
              ? cloudProduct.manufacturerBarcode!.trim()
              : (cloudProduct.barcode?.trim().isNotEmpty == true
                  ? cloudProduct.barcode!.trim()
                  : (inv?.manufacturerBarcode ?? inv?.barcode))) ??
          '';
      final internal = (cloudProduct.internalBarcode?.trim().isNotEmpty == true
              ? cloudProduct.internalBarcode!.trim()
              : inv?.internalBarcode) ??
          '';

      rows.add(
        ProductInventoryRecord(
          id: inv?.productId ?? -1,
          code: inv != null && inv.sku.isNotEmpty
              ? inv.sku
              : (sku.isNotEmpty ? sku : 'P-${cloudProduct.id}'),
          name: inv != null && inv.name.isNotEmpty
              ? inv.name
              : cloudProduct.name,
          category: inv != null && inv.category.isNotEmpty
              ? inv.category
              : (cloudProduct.category.isEmpty ? 'Other' : cloudProduct.category),
          defaultUnit: inv != null && inv.unit.isNotEmpty
              ? inv.unit
              : (cloudProduct.unitOfMeasure.isEmpty
                  ? 'Piece'
                  : cloudProduct.unitOfMeasure),
          sku: sku.isNotEmpty ? sku : (inv?.sku ?? ''),
          barcode: barcode,
          manufacturerBarcode: manufacturer,
          florapriseBarcode: internal,
          cloudProductId: cloudProduct.id,
          sellingPricePaise: ((cloudProduct.retailPrice) * 100).round(),
          purchasePricePaise: (cloudProduct.costPrice * 100).round(),
          gstPercent: inv?.gstPercent ?? 0,
          gstCalculationType:
              inv?.gstCalculationType ?? GstCalculationType.inclusive,
          trackInventory: inv?.trackInventory ?? cloudProduct.trackInventory,
          active: cloudProduct.isActive,
          favorite: false,
          currentQty: inv?.currentQty ?? cloudProduct.stockQuantity.toInt(),
          minQty: inv?.minQty ?? cloudProduct.minimumStockLevel.toInt(),
        ),
      );
    }

    // Preserve any inventory items whose cloudProductId wasn't matched above
    for (final inv in inventoryProducts) {
      if (inv.cloudProductId == null || inv.cloudProductId!.trim().isEmpty) {
        continue;
      }
      if (!matchedCloudIds.contains(inv.cloudProductId!.trim().toLowerCase())) {
        rows.add(
          ProductInventoryRecord(
            id: inv.productId,
            code: inv.sku,
            name: inv.name,
            category: inv.category.isEmpty ? 'Other' : inv.category,
            defaultUnit: inv.unit.isEmpty ? 'Piece' : inv.unit,
            sku: inv.sku,
            barcode: inv.barcode,
            manufacturerBarcode: inv.manufacturerBarcode ?? inv.barcode,
            florapriseBarcode: inv.internalBarcode ?? '',
            cloudProductId: inv.cloudProductId,
            sellingPricePaise: 0,
            purchasePricePaise: null,
            gstPercent: inv.gstPercent,
            gstCalculationType: inv.gstCalculationType,
            trackInventory: inv.trackInventory,
            active: true,
            favorite: false,
            currentQty: inv.currentQty,
            minQty: inv.minQty,
          ),
        );
      }
    }

    return rows;
  }

  // Fallback when cloudProducts list is empty
  final productById = {
    for (final product in cloudProducts) product.id.trim().toLowerCase(): product,
  };
  return inventoryProducts
      .where((product) => product.cloudProductId?.trim().isNotEmpty == true)
      .map(
        (product) {
          final cloudProduct = productById[product.cloudProductId!.trim().toLowerCase()];
          return ProductInventoryRecord(
            id: product.productId,
            code: product.sku,
            name: product.name.isEmpty ? cloudProduct?.name ?? '' : product.name,
            category: product.category.isEmpty ? cloudProduct?.category ?? 'Other' : product.category,
            defaultUnit: product.unit.isEmpty ? cloudProduct?.unitOfMeasure ?? 'Piece' : product.unit,
            sku: product.sku.isEmpty ? cloudProduct?.sku ?? '' : product.sku,
            barcode: product.barcode,
            manufacturerBarcode: product.manufacturerBarcode ?? product.barcode,
            florapriseBarcode: product.internalBarcode ?? '',
            cloudProductId: product.cloudProductId,
            sellingPricePaise: ((cloudProduct?.retailPrice ?? 0) * 100).round(),
            purchasePricePaise: cloudProduct == null
                ? null
                : (cloudProduct.costPrice * 100).round(),
            gstPercent: product.gstPercent,
            gstCalculationType: product.gstCalculationType,
            trackInventory: product.trackInventory,
            active: true,
            favorite: false,
            currentQty: product.currentQty,
            minQty: product.minQty,
          );
        },
      )
      .toList();
}

@visibleForTesting
List<ProductInventoryRecord> productPickerApplyInventoryStock(
  List<ProductInventoryRecord> products,
  List<InventoryProductRecord> inventoryProducts,
  {bool requireCloudMatch = false}
) {
  if (inventoryProducts.isEmpty) return products;
  final inventoryByCloudProductId = {
    for (final product in inventoryProducts)
      if (product.cloudProductId?.trim().isNotEmpty == true)
        product.cloudProductId!.trim().toLowerCase(): product,
  };
  final inventoryByProductId = {
    for (final product in inventoryProducts) product.productId: product,
  };

  return products.map((product) {
    final cloudProductId = product.cloudProductId?.trim().toLowerCase();
    final inventory = cloudProductId == null || cloudProductId.isEmpty
        ? inventoryByProductId[product.id]
        : inventoryByCloudProductId[cloudProductId] ??
            (requireCloudMatch ? null : inventoryByProductId[product.id]);
    if (inventory == null && !requireCloudMatch) return product;
    return ProductInventoryRecord(
      id: product.id,
      code: product.code,
      name: product.name,
      category: product.category,
      defaultUnit: product.defaultUnit,
      sku: product.sku,
      barcode: product.barcode,
      manufacturerBarcode: product.manufacturerBarcode,
      florapriseBarcode: product.florapriseBarcode,
      cloudProductId: product.cloudProductId,
      sellingPricePaise: product.sellingPricePaise,
      purchasePricePaise: product.purchasePricePaise,
      gstPercent: product.gstPercent,
      gstCalculationType: product.gstCalculationType,
      trackInventory: product.trackInventory,
      active: product.active,
      favorite: product.favorite,
      currentQty: inventory?.currentQty ?? 0,
      minQty: inventory?.minQty ?? product.minQty,
    );
  }).toList();
}

@visibleForTesting
List<ProductInventoryRecord> productPickerVisibleProducts(
  List<ProductInventoryRecord> products,
  String query,
) {
  final normalizedQuery = query.trim().toLowerCase();
  return products.where((product) {
    return normalizedQuery.isEmpty ||
        product.name.toLowerCase().contains(normalizedQuery) ||
        product.sku.toLowerCase().contains(normalizedQuery) ||
        product.manufacturerBarcode.toLowerCase().contains(normalizedQuery) ||
        product.florapriseBarcode.toLowerCase().contains(normalizedQuery);
  }).toList();
}

@visibleForTesting
bool productPickerCanSelect(ProductInventoryRecord product) {
  return !productPickerIsOutOfStock(product);
}

@visibleForTesting
bool productPickerIsOutOfStock(ProductInventoryRecord product) {
  return product.trackInventory && product.currentQty <= 0;
}

@visibleForTesting
bool productPickerIsLowStock(ProductInventoryRecord product) {
  return product.trackInventory &&
      product.currentQty > 0 &&
      product.minQty > 0 &&
      product.currentQty <= product.minQty;
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
