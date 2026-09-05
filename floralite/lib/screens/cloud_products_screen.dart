import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repositories/cloud_product_repository.dart';
import '../providers/cloud_product_provider.dart';
import '../services/cloud_product_local_catalog_sync_service.dart';
import '../widgets/camera_barcode_scanner_page.dart';

class CloudProductsScreen extends StatefulWidget {
  const CloudProductsScreen({super.key});

  @override
  State<CloudProductsScreen> createState() => _CloudProductsScreenState();
}

class _CloudProductsScreenState extends State<CloudProductsScreen> {
  final _searchController = TextEditingController();
  final CloudProductLocalCatalogSyncService _catalogSyncService =
      CloudProductLocalCatalogSyncService();
  bool _isSyncingPosCatalog = false;

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
    final result = await showDialog<CloudProductInput>(
      context: context,
      builder: (_) => _CloudProductDialog(
        product: product,
        categories: provider.categories.where((c) => c.isActive).toList(),
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

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CloudProductProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Products'),
        actions: [
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editProduct(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onSubmitted: provider.search,
              decoration: const InputDecoration(
                labelText: 'Search cloud products',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          if (provider.isLoading) const LinearProgressIndicator(),
          if (provider.error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(provider.error!),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: provider.load,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                itemCount: provider.products.length,
                itemBuilder: (_, index) {
                  final product = provider.products[index];
                  return Card(
                    child: ListTile(
                      title: Text(product.name),
                      subtitle: Text(
                        '${product.sku}  |  ${product.unitOfMeasure}  |  ${product.retailPrice.toStringAsFixed(2)}  |  '
                        '${product.isActive ? 'Active' : 'Inactive'}',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') await _editProduct(product: product);
                          if (value == 'toggle') {
                            try {
                              await provider.setProductActive(product.id, !product.isActive);
                            } catch (error) {
                              if (mounted) _showError(error);
                            }
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(
                            value: 'toggle',
                            child: Text(product.isActive ? 'Deactivate' : 'Activate'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
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
    'Dozen',
    'Bundle',
    'Bouquet',
    'Box',
    'Vase',
    'Roll',
    'Pack',
    'Set',
    'Meter',
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
    _categoryId = product?.categoryId ?? (widget.categories.isEmpty ? null : widget.categories.first.id);
    _unit = _units.contains(product?.unitOfMeasure) ? product!.unitOfMeasure : 'Stem';
    _trackInventory = product?.trackInventory ?? false;
    _trackBatch = product?.trackBatch ?? false;
    _reorderLevel = product?.reorderLevel ?? 0;
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
    return AlertDialog(
      title: Text(widget.product == null ? 'Add Cloud Product' : 'Edit Cloud Product'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(_name, 'Name'),
            _field(_sku, 'SKU'),
            if (widget.categories.isNotEmpty)
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: widget.categories
                    .map((category) => DropdownMenuItem(value: category.id, child: Text(category.name)))
                    .toList(),
                onChanged: (value) => setState(() => _categoryId = value),
              ),
            DropdownButtonFormField<String>(
              initialValue: _unit,
              decoration: const InputDecoration(labelText: 'Unit'),
              items: _units.map((unit) => DropdownMenuItem(value: unit, child: Text(unit))).toList(),
              onChanged: (value) => setState(() => _unit = value ?? 'Stem'),
            ),
            _field(_retail, 'Selling price', numeric: true),
            _field(_cost, 'Purchase price', numeric: true),
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
                  decoration: const InputDecoration(labelText: 'FloraPrise Barcode'),
                  child: Text(widget.product!.internalBarcode ?? 'Not generated yet'),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'A FloraPrise barcode will be generated automatically once this product is saved.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            _field(_description, 'Description'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _trackInventory,
              title: const Text('Track inventory'),
              onChanged: (value) => setState(() => _trackInventory = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _trackBatch,
              title: const Text('Track batches'),
              onChanged: (value) => setState(() => _trackBatch = value),
            ),
            if (_formError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_formError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _isSaving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _isSaving ? null : _save, child: const Text('Save')),
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
    final cost = double.tryParse(_cost.text.trim());
    String? error;
    if (_name.text.trim().isEmpty) {
      error = 'Name is required.';
    } else if (_sku.text.trim().isEmpty) {
      error = 'SKU is required.';
    } else if (categoryId == null) {
      error = 'Select a category.';
    } else if (retail == null) {
      error = 'Enter a valid selling price.';
    } else if (cost == null) {
      error = 'Enter a valid purchase price.';
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
        sku: _sku.text.trim(),
        categoryId: categoryId!,
        unitOfMeasure: _unit,
        retailPrice: retail!,
        costPrice: cost!,
        manufacturerBarcode: _barcode.text.trim().isEmpty ? null : _barcode.text.trim(),
        description: _description.text.trim().isEmpty ? null : _description.text.trim(),
        trackInventory: _trackInventory,
        trackBatch: _trackBatch,
        reorderLevel: _reorderLevel,
      ),
    );
  }
}
