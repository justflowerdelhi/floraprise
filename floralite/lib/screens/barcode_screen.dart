import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repositories/job_repository.dart';
import '../data/repositories/product_repository.dart';
import '../l10n/app_localizations.dart';
import '../models/walk_in_line_item.dart';
import '../providers/inventory_provider.dart';
import '../providers/printer_provider.dart';
import '../providers/walk_in_session_provider.dart';
import '../utils/locale_formatter.dart';
import '../widgets/camera_barcode_scanner_page.dart';
import '../widgets/common_widgets.dart';

class BarcodeScreen extends StatefulWidget {
  const BarcodeScreen({super.key});

  @override
  State<BarcodeScreen> createState() => _BarcodeScreenState();
}

class _BarcodeScreenState extends State<BarcodeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ProductRepository _productRepository = ProductRepository();
  final JobRepository _jobRepository = JobRepository();

  String _selectedBarcodeType = 'manufacturer';
  bool _isLoading = true;
  bool _isLookupRunning = false;
  String? _error;
  String? _lookupQuery;
  ProductInventoryRecord? _lookupResult;
  List<_BarcodeProduct> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final records =
          await _productRepository.listActiveProductsWithInventory();
      if (!mounted) return;

      setState(() {
        _products = records.expand((record) {
          final values = <_BarcodeProduct>[];
          final manufacturer = record.manufacturerBarcode.trim();
          final florist = record.florapriseBarcode.trim();

          if (manufacturer.isNotEmpty) {
            values.add(
              _BarcodeProduct(
                id: record.id,
                name: record.name,
                barcode: manufacturer,
                barcodeType: 'manufacturer',
              ),
            );
          }

          if (florist.isNotEmpty) {
            values.add(
              _BarcodeProduct(
                id: record.id,
                name: record.name,
                barcode: florist,
                barcodeType: 'florist',
              ),
            );
          }

          return values;
        }).toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load barcode data. Please try again.';
        _isLoading = false;
      });
    }
  }

  List<_BarcodeProduct> get _filteredProducts {
    return _products
        .where((p) => p.barcodeType == _selectedBarcodeType)
        .where((p) {
      final query = _searchController.text.trim().toLowerCase();
      if (query.isEmpty) return true;
      return p.name.toLowerCase().contains(query) ||
          p.barcode.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.barcodeTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildBarcodeTypeOption(
                      l10n.manufacturerBarcode,
                      'manufacturer',
                      colorScheme,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBarcodeTypeOption(
                      l10n.floristBarcode,
                      'florist',
                      colorScheme,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _promptScannerInput,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: Text(l10n.scanBarcodeBtn),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showGenerateBarcodeDialog,
                      icon: const Icon(Icons.qr_code),
                      label: Text(l10n.generateBarcodeBtn),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.searchProductBarcode,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? SizedBox(
                          width: 96,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.search),
                                onPressed: () =>
                                    _lookupProduct(_searchController.text),
                              ),
                              IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _lookupResult = null;
                                    _lookupQuery = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: _lookupProduct,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildContent(l10n, colorScheme, bottomInset),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    double bottomInset,
  ) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadProducts,
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLookupRunning) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_products.isEmpty) {
      return const Center(child: Text('No products available.'));
    }

    final filtered = _filteredProducts;
    if (filtered.isEmpty) {
      return Center(child: Text(l10n.noProductsFound));
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 24 + bottomInset),
      children: [
        if (_lookupResult != null && _lookupQuery != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildLookupResultCard(
              _lookupResult!,
              _lookupQuery!,
              colorScheme,
            ),
          ),
        ...filtered.map(
          (product) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildBarcodeCard(product, colorScheme, l10n),
          ),
        ),
      ],
    );
  }

  Widget _buildBarcodeTypeOption(
    String label,
    String type,
    ColorScheme colorScheme,
  ) {
    final isSelected = _selectedBarcodeType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedBarcodeType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildBarcodeCard(
    _BarcodeProduct product,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return AppCard(
      onTap: () => _showBarcodePreview(product),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.qr_code_2,
              color: colorScheme.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
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
                  product.barcode,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.barcodeType == 'manufacturer'
                      ? l10n.manufacturerBarcode
                      : l10n.floristBarcode,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _queuePrintJob(
              productId: product.id,
              productName: product.name,
              barcode: product.barcode,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLookupResultCard(
    ProductInventoryRecord product,
    String query,
    ColorScheme colorScheme,
  ) {
    final preferredBarcode = product.florapriseBarcode.trim().isNotEmpty
        ? product.florapriseBarcode.trim()
        : (product.manufacturerBarcode.trim().isNotEmpty
            ? product.manufacturerBarcode.trim()
            : product.sku.trim());

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Found',
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${product.category} • ${product.defaultUnit}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            LocaleFormatter.formatCurrency(context, product.sellingPricePaise),
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            product.trackInventory
                ? 'Track Inventory: Yes'
                : 'Track Inventory: No',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
            ),
          ),
          if (preferredBarcode.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Barcode: $preferredBarcode',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _addToWalkIn(product),
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Add to Walk-in'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewInInventory(product),
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('View Product'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Lookup: "$query"',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _showBarcodePreview(_BarcodeProduct product) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.barcodePreview,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outline),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.qr_code_2,
                    size: 120,
                    color: Colors.black,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.barcode,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: Text(l10n.close),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _queuePrintJob(
                        productId: product.id,
                        productName: product.name,
                        barcode: product.barcode,
                      );
                    },
                    icon: const Icon(Icons.print),
                    label: Text(l10n.printBarcodeBtn),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _showGenerateBarcodeDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final missing =
        await _productRepository.listProductsMissingFlorapriseBarcode();
    if (!mounted) return;

    if (missing.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('All products already have Floraprise barcode.')),
      );
      return;
    }

    final generatedIds = <int>{};

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(l10n.generateBarcodeBtn),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.generateNewFloristBarcode),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: missing.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final product = missing[index];
                      final isDone = generatedIds.contains(product.id);
                      return ListTile(
                        dense: true,
                        title: Text(product.name),
                        subtitle: Text(
                          product.sku.isEmpty
                              ? 'SKU: -'
                              : 'SKU: ${product.sku}',
                        ),
                        trailing: isDone
                            ? const Icon(Icons.check_circle,
                                color: Colors.green)
                            : TextButton(
                                onPressed: () async {
                                  final messenger =
                                      ScaffoldMessenger.of(context);
                                  await _productRepository
                                      .generateFlorapriseBarcode(product.id);
                                  if (!mounted) return;
                                  setStateDialog(() {
                                    generatedIds.add(product.id);
                                  });
                                  await _loadProducts();
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Barcode generated and saved.'),
                                    ),
                                  );
                                },
                                child: Text(l10n.generateBarcodeBtn),
                              ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _promptScannerInput() async {
    final l10n = AppLocalizations.of(context)!;
    final input = await showCameraBarcodeScanner(
      context,
      title: l10n.scanBarcodeBtn,
    );

    if (input == null || input.trim().isEmpty || !mounted) {
      return;
    }

    _searchController.text = input.trim();
    await _lookupProduct(input.trim());
  }

  Future<void> _lookupProduct(String input) async {
    final query = input.trim();
    if (query.isEmpty) {
      return;
    }

    setState(() {
      _isLookupRunning = true;
      _lookupResult = null;
      _lookupQuery = query;
    });

    try {
      final matched =
          await _productRepository.lookupProductBySearchPriority(query);
      if (!mounted) return;

      if (matched == null) {
        setState(() {
          _isLookupRunning = false;
          _lookupResult = null;
        });
        _showNotFoundDialog();
        return;
      }

      setState(() {
        _isLookupRunning = false;
        _lookupResult = matched;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLookupRunning = false;
        _lookupResult = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please try again.')),
      );
    }
  }

  void _showNotFoundDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No product found.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/products');
            },
            child: const Text('Create Product'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  Future<void> _queuePrintJob({
    required int productId,
    required String productName,
    required String barcode,
  }) async {
    final printerProvider = context.read<PrinterProvider>();
    await _jobRepository.enqueueBarcodePrintJob(
      productId: productId,
      payload: {
        'productName': productName,
        'barcode': barcode,
      },
    );
    await printerProvider.enqueueBarcodeLabel(
      productName: productName,
      barcode: barcode,
      quantity: 1,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Barcode label queued for printing.'),
      ),
    );
  }

  void _addToWalkIn(ProductInventoryRecord product) {
    final provider = context.read<WalkInSessionProvider>();
    final session = provider.session;
    final lines = List<WalkInLineItem>.from(session.lines);
    final index = lines.indexWhere((line) => line.productId == product.id);

    if (index >= 0) {
      lines[index] = lines[index].copyWith(quantity: lines[index].quantity + 1);
    } else {
      lines.add(
        WalkInLineItem(
          productId: product.id,
          description: product.name,
          quantity: 1,
          unitPricePaise: product.sellingPricePaise,
          gstPercent: product.gstPercent,
          source: 'product',
        ),
      );
    }

    provider.patchSession(session.copyWith(lines: lines));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to walk-in cart.')),
    );
  }

  void _viewInInventory(ProductInventoryRecord product) {
    final inventoryProvider = context.read<InventoryProvider>();
    inventoryProvider.setQuery(product.name);
    Navigator.pushNamed(context, '/inventory');
  }
}

class _BarcodeProduct {
  final int id;
  final String name;
  final String barcode;
  final String barcodeType;

  _BarcodeProduct({
    required this.id,
    required this.name,
    required this.barcode,
    required this.barcodeType,
  });
}
