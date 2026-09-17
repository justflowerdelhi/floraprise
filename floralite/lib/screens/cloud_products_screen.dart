import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repositories/cloud_product_repository.dart';
import '../data/repositories/product_repository.dart';
import '../providers/cloud_product_provider.dart';
import '../providers/printer_provider.dart';
import '../services/cloud_product_local_catalog_sync_service.dart';
import '../services/sku_generator_service.dart';
import '../widgets/app_header.dart';
import '../widgets/camera_barcode_scanner_page.dart';
import '../widgets/common_widgets.dart';
import '../widgets/floraprise_page_header.dart';
import 'bouquet_builder_screen.dart';

class CloudProductsScreen extends StatefulWidget {
  const CloudProductsScreen({super.key});

  @override
  State<CloudProductsScreen> createState() => _CloudProductsScreenState();
}

class _CloudProductsScreenState extends State<CloudProductsScreen> {
  final _searchController = TextEditingController();
  final CloudProductLocalCatalogSyncService _catalogSyncService =
      CloudProductLocalCatalogSyncService();
  final ProductRepository _productRepository = ProductRepository();
  bool _isSyncingPosCatalog = false;

  static const List<String> _categoryChips = [
    'all',
    'Finished Products',
    'Flowers',
    'Fillers',
    'Foliage',
    'Packing',
    'Accessories',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CloudProductProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _editProduct({CloudProduct? product}) async {
    final provider = context.read<CloudProductProvider>();
    final activeCategories = provider.categories.where((c) => c.isActive).toList();
    final categories = List<CloudCategory>.from(activeCategories);
    if (product?.categoryId != null) {
      final existingCat = provider.categories
          .where((c) => c.id == product!.categoryId)
          .firstOrNull;
      if (existingCat != null &&
          !categories.any((c) => c.id == existingCat.id)) {
        categories.add(existingCat);
      }
    }
    final result = await showDialog<CloudProductInput>(
      context: context,
      builder: (_) => _CloudProductDialog(
        product: product,
        categories: categories,
      ),
    );
    if (result == null || !mounted) return;
    try {
      if (product == null) {
        await provider.createProduct(result);
      } else {
        await provider.updateProduct(product.id, result);
      }
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _printBarcode(CloudProduct product) async {
    final barcode = (product.barcode?.trim().isNotEmpty == true
            ? product.barcode
            : product.internalBarcode?.trim().isNotEmpty == true
                ? product.internalBarcode
                : product.sku)
        ?.trim();

    if (barcode == null || barcode.isEmpty) {
      _showError('No barcode or SKU available for this product.');
      return;
    }

    final quantity = await _askPrintQuantity(product.name);
    if (quantity == null || quantity <= 0 || !mounted) return;

    final printer = context.read<PrinterProvider>();
    await printer.enqueueBarcodeLabel(
      productName: product.name,
      barcode: barcode,
      quantity: quantity,
      sellingPricePaise: (product.retailPrice * 100).round(),
    );
    if (!mounted) return;
    final message = printer.error ?? 'Barcode label sent to printer queue.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<int?> _askPrintQuantity(String productName) {
    var quantity = 1;
    return showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Print Labels'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(productName, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.outlined(
                    onPressed: quantity <= 1
                        ? null
                        : () => setStateDialog(() => quantity--),
                    icon: const Icon(Icons.remove),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      quantity.toString(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton.outlined(
                    onPressed: () => setStateDialog(() => quantity++),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, quantity),
              child: const Text('Print'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openRecipe(CloudProduct product) async {
    int? localProductId =
        await _productRepository.getLocalProductIdByCloudProductId(product.id);

    if (localProductId == null) {
      await _catalogSyncService.syncForCurrentCompany();
      localProductId = await _productRepository
          .getLocalProductIdByCloudProductId(product.id);
    }

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BouquetBuilderScreen(
          existingProductId: localProductId,
        ),
      ),
    );
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CloudProductProvider>();
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;
    return Scaffold(
      appBar: AppHeader(
        title: isDesktop ? null : 'Products',
        actions: [
          PopupMenuButton<ProductSort>(
            icon: const Icon(Icons.sort),
            onSelected: provider.setSort,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: ProductSort.nameAsc,
                child: Text('Name A-Z'),
              ),
              PopupMenuItem(
                value: ProductSort.nameDesc,
                child: Text('Name Z-A'),
              ),
              PopupMenuItem(
                value: ProductSort.latestUpdated,
                child: Text('Recently Updated'),
              ),
              PopupMenuItem(
                value: ProductSort.priceLowToHigh,
                child: Text('Price Low to High'),
              ),
              PopupMenuItem(
                value: ProductSort.priceHighToLow,
                child: Text('Price High to Low'),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Sync Cloud Products to POS Catalog',
            onPressed: _isSyncingPosCatalog ? null : _syncPosCatalog,
            icon: _isSyncingPosCatalog
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_alt_rounded),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: provider.isLoading ? null : provider.load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton(
              onPressed: () => _editProduct(),
              child: const Icon(Icons.add),
            ),
      body: Column(
        children: [
          FloraprisePageHeader(
            title: 'Products',
            subtitle: 'Manage your flower catalogue and pricing',
            icon: Icons.local_florist_rounded,
            actions: [
              FloraprisePageHeaderAction(
                label: 'Add Product',
                icon: Icons.add_rounded,
                primary: true,
                onPressed: () => _editProduct(),
              ),
            ],
            decorationAlignment: Alignment.centerLeft,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                provider.search(value);
              },
              decoration: InputDecoration(
                labelText: 'Search cloud products',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          provider.search('');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categoryChips.map((cat) {
                  final isSelected = provider.category == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AppChip(
                      label: cat == 'all' ? 'All' : cat,
                      isSelected: isSelected,
                      onTap: () => provider.setCategory(cat),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (provider.isLoading) const LinearProgressIndicator(),
          if (provider.error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(provider.error!),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: provider.load,
              child: isDesktop
                  ? GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 440,
                        mainAxisExtent: 190,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: provider.products.length,
                      itemBuilder: (_, index) => _buildProductCard(
                        provider.products[index],
                        provider,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                      itemCount: provider.products.length,
                      itemBuilder: (_, index) => _buildProductCard(
                        provider.products[index],
                        provider,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    CloudProduct product,
    CloudProductProvider provider,
  ) {
    final isFav = provider.isFavorite(product.id);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${product.sku}  |  ${product.category}  |  ${product.unitOfMeasure}  |  '
                        '${product.isActive ? 'Active' : 'Inactive'}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${product.retailPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  tooltip: isFav ? 'Unfavourite' : 'Favourite',
                  icon: Icon(
                    isFav ? Icons.star : Icons.star_border,
                    color: isFav ? Colors.amber : null,
                  ),
                  onPressed: () => provider.toggleFavorite(product.id),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Recipe',
                  icon: const Icon(Icons.menu_book_outlined),
                  onPressed: () => _openRecipe(product),
                ),
                IconButton(
                  tooltip: 'Print Barcode',
                  icon: const Icon(Icons.print_outlined),
                  onPressed: () => _printBarcode(product),
                ),
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editProduct(product: product),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'toggle') {
                      try {
                        await provider.setProductActive(
                          product.id,
                          !product.isActive,
                        );
                      } catch (error) {
                        if (mounted) _showError(error);
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(
                        product.isActive ? 'Deactivate' : 'Activate',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _syncPosCatalog() async {
    setState(() => _isSyncingPosCatalog = true);
    try {
      final result = await _catalogSyncService.syncForCurrentCompany();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.summary)),
      );
      if (result.skippedCount > 0 && result.errors.isNotEmpty) {
        final preview = result.errors.take(3).join('\n');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(preview)),
        );
      }
      await context.read<CloudProductProvider>().load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not sync POS catalog: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSyncingPosCatalog = false);
    }
  }
}

class _CloudProductDialog extends StatefulWidget {
  const _CloudProductDialog({this.product, required this.categories});

  final CloudProduct? product;
  final List<CloudCategory> categories;

  @override
  State<_CloudProductDialog> createState() => _CloudProductDialogState();
}

class _CloudProductDialogState extends State<_CloudProductDialog> {
  late final TextEditingController _name;
  late final TextEditingController _sku;
  late final TextEditingController _barcode;
  late final TextEditingController _retail;
  late final TextEditingController _cost;
  late final TextEditingController _description;
  late String? _categoryId;
  String _unit = 'Stem';
  bool _trackInventory = false;
  bool _trackBatch = false;
  int _reorderLevel = 0;
  bool _isSaving = false;
  String? _formError;

  // Must match the backend UnitOfMeasure enum exactly (Sumpooj.Domain).
  // Sending a value outside this list is not rejected by the API - it is
  // silently coerced to the default (Stem), which would corrupt data
  // without any visible error.
  static const List<String> _units = [
    'Stem',
    'Bunch',
    'Piece',
    'Box',
    'Roll',
    'Pack',
    'Meter',
    'Set',
    'Dozen',
    'Bundle',
    'Bouquet',
    'Vase',
  ];

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _name = TextEditingController(text: product?.name ?? '');
    _sku = TextEditingController(text: product?.sku ?? '');
    _barcode = TextEditingController(text: product?.manufacturerBarcode ?? product?.barcode ?? '');
    _retail = TextEditingController(text: product?.retailPrice.toString() ?? '');
    _cost = TextEditingController(text: product?.costPrice.toString() ?? '');
    _description = TextEditingController(text: product?.description ?? '');
    final categoryExists = product?.categoryId != null &&
        widget.categories.any((c) => c.id == product!.categoryId);
    _categoryId = categoryExists
        ? product!.categoryId
        : (widget.categories.isEmpty ? null : widget.categories.first.id);

    final initialCat = widget.categories.where((c) => c.id == _categoryId).firstOrNull;
    if (product != null) {
      _unit = _units.contains(product.unitOfMeasure) ? product.unitOfMeasure : 'Stem';
    } else if (initialCat != null && _units.contains(initialCat.effectiveDefaultUnit)) {
      _unit = initialCat.effectiveDefaultUnit;
    } else {
      _unit = 'Stem';
    }

    _trackInventory = product?.trackInventory ?? false;
    _trackBatch = product?.trackBatch ?? false;
    _reorderLevel = product?.reorderLevel ?? 0;
  }

  void _autoGenerateSku() {
    final selectedCategory = widget.categories
        .where((c) => c.id == _categoryId)
        .firstOrNull;
    final catName = selectedCategory?.name ?? 'General';
    final generated = SkuGeneratorService.generateSku(
      categoryName: catName,
      productName: _name.text,
    );
    setState(() {
      _sku.text = generated;
      _formError = null;
    });
  }

  void _onCategoryChanged(String? value) {
    if (value == null) return;
    setState(() {
      _categoryId = value;
      final selectedCategory = widget.categories
          .where((c) => c.id == value)
          .firstOrNull;
      if (selectedCategory != null) {
        final defUnit = selectedCategory.effectiveDefaultUnit;
        if (_units.contains(defUnit)) {
          _unit = defUnit;
        }
      }
    });
  }

  Widget _skuField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: _sku,
        decoration: InputDecoration(
          labelText: 'SKU',
          suffixIcon: IconButton(
            icon: const Icon(Icons.autorenew_rounded),
            tooltip: 'Auto-generate SKU',
            onPressed: _autoGenerateSku,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in [_name, _sku, _barcode, _retail, _cost, _description]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= 640;
    final dialogWidth =
        isWide ? 580.0 : (screenWidth - 48.0).clamp(280.0, 580.0);

    return AlertDialog(
      title: Text(
          widget.product == null ? 'Add Cloud Product' : 'Edit Cloud Product'),
      content: SizedBox(
        width: dialogWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _field(_name, 'Name')),
                    const SizedBox(width: 12),
                    Expanded(child: _skuField()),
                  ],
                )
              else ...[
                _field(_name, 'Name'),
                _skuField(),
              ],
              if (widget.categories.isNotEmpty) ...[
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('cat-$_categoryId'),
                            initialValue: _categoryId,
                            decoration:
                                const InputDecoration(labelText: 'Category'),
                            items: widget.categories
                                .map((category) => DropdownMenuItem(
                                      value: category.id,
                                      child: Text(category.name),
                                    ))
                                .toList(),
                            onChanged: _onCategoryChanged,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('unit-$_unit'),
                            initialValue: _unit,
                            decoration:
                                const InputDecoration(labelText: 'Unit'),
                            items: _units
                                .map((unit) => DropdownMenuItem(
                                      value: unit,
                                      child: Text(unit),
                                    ))
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _unit = value ?? 'Stem'),
                          ),
                        ),
                      ),
                    ],
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('cat-$_categoryId'),
                      initialValue: _categoryId,
                      decoration:
                          const InputDecoration(labelText: 'Category'),
                      items: widget.categories
                          .map((category) => DropdownMenuItem(
                                value: category.id,
                                child: Text(category.name),
                              ))
                          .toList(),
                      onChanged: _onCategoryChanged,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('unit-$_unit'),
                      initialValue: _unit,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: _units
                          .map((unit) => DropdownMenuItem(
                                value: unit,
                                child: Text(unit),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _unit = value ?? 'Stem'),
                    ),
                  ),
                ],
              ] else ...[
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'No categories available. Please add categories before creating products.',
                    style: TextStyle(color: Colors.orange, fontSize: 13),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('unit-$_unit'),
                    initialValue: _unit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: _units
                        .map((unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(unit),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _unit = value ?? 'Stem'),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: _field(_retail, 'Selling price', numeric: true)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _field(_cost, 'Purchase price (optional)',
                            numeric: true)),
                  ],
                )
              else ...[
                _field(_retail, 'Selling price', numeric: true),
                _field(_cost, 'Purchase price (optional)', numeric: true),
              ],
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: _barcode,
                  decoration: InputDecoration(
                    labelText: 'Manufacturer Barcode',
                    suffixIcon: IconButton(
                      tooltip: 'Scan Manufacturer Barcode',
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: () async {
                        final scanned = await showCameraBarcodeScanner(
                          context,
                          title: 'Scan Manufacturer Barcode',
                        );
                        if (scanned == null || scanned.isEmpty) return;
                        _barcode.text = scanned;
                      },
                    ),
                  ),
                ),
              ),
              if (widget.product != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InputDecorator(
                    decoration:
                        const InputDecoration(labelText: 'FloraPrise Barcode'),
                    child: Text(
                        widget.product!.internalBarcode ?? 'Not generated yet'),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'A FloraPrise barcode will be generated automatically once this product is saved.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ),
              _field(_description, 'Description'),
              if (isWide)
                Row(
                  children: [
                    Expanded(
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _trackInventory,
                        title: const Text('Track inventory'),
                        onChanged: (value) =>
                            setState(() => _trackInventory = value),
                      ),
                    ),
                    Expanded(
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _trackBatch,
                        title: const Text('Track batches'),
                        onChanged: (value) =>
                            setState(() => _trackBatch = value),
                      ),
                    ),
                  ],
                )
              else ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _trackInventory,
                  title: const Text('Track inventory'),
                  onChanged: (value) =>
                      setState(() => _trackInventory = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _trackBatch,
                  title: const Text('Track batches'),
                  onChanged: (value) => setState(() => _trackBatch = value),
                ),
              ],
              if (_formError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _formError!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _field(TextEditingController controller, String label, {bool numeric = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  void _save() {
    if (_isSaving) return;
    final categoryId = _categoryId;
    final retail = double.tryParse(_retail.text.trim());
    // Purchase cost is optional: florist purchases have variable costs
    // recorded per inventory stock addition, not on the product master.
    final costText = _cost.text.trim();
    double? cost;
    String? error;
    if (_name.text.trim().isEmpty) {
      error = 'Name is required.';
    } else if (categoryId == null) {
      error = 'Select a category.';
    } else if (retail == null) {
      error = 'Enter a valid selling price.';
    } else if (costText.isNotEmpty) {
      cost = double.tryParse(costText);
      if (cost == null) {
        error = 'Enter a valid purchase price.';
      }
    }

    var finalSku = _sku.text.trim();
    if (error == null) {
      if (finalSku.isEmpty) {
        // Auto-generate SKU if blank instead of blocking with error
        final selectedCategory = widget.categories
            .where((c) => c.id == categoryId)
            .firstOrNull;
        final catName = selectedCategory?.name ?? 'General';
        finalSku = SkuGeneratorService.generateSku(
          categoryName: catName,
          productName: _name.text,
        );
        _sku.text = finalSku;
      } else if (!SkuGeneratorService.isValidSku(finalSku)) {
        error = 'SKU can only contain letters, numbers, hyphens, and underscores.';
      }
    }

    if (error != null) {
      setState(() => _formError = error);
      return;
    }
    // Disable Save/Cancel the moment a valid submission is popped so a second
    // rapid tap landing before the dialog's close transition finishes cannot
    // pop the route (and thus cannot cause a second create/update) again.
    setState(() => _isSaving = true);
    Navigator.pop(
      context,
      CloudProductInput(
        name: _name.text.trim(),
        sku: finalSku,
        categoryId: categoryId!,
        unitOfMeasure: _unit,
        retailPrice: retail!,
        costPrice: cost,
        manufacturerBarcode: _barcode.text.trim().isEmpty ? null : _barcode.text.trim(),
        description: _description.text.trim().isEmpty ? null : _description.text.trim(),
        trackInventory: _trackInventory,
        trackBatch: _trackBatch,
        reorderLevel: _reorderLevel,
      ),
    );
  }
}
