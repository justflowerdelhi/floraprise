import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/voice_dictation_controller.dart';
import '../data/repositories/inventory_repository.dart';
import '../data/repositories/product_repository.dart';
import '../l10n/app_localizations.dart';
import '../models/gst_calculation_type.dart';
import '../providers/inventory_provider.dart';
import '../services/speech_recognition_service.dart';
import '../utils/locale_formatter.dart';
import '../widgets/app_header.dart';
import '../widgets/camera_barcode_scanner_page.dart';
import '../widgets/common_widgets.dart';
import '../widgets/quantity_input_stepper.dart';
import '../widgets/voice_dictation_field_header.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ProductRepository _productRepository = ProductRepository();
  static const List<_InventoryFilterOption> _filters = [
    _InventoryFilterOption('all', 'All'),
    _InventoryFilterOption('flower', 'Flowers'),
    _InventoryFilterOption('filler', 'Fillers'),
    _InventoryFilterOption('packing', 'Packing'),
    _InventoryFilterOption('accessory', 'Accessories'),
    _InventoryFilterOption('finished_product', 'Finished Products'),
    _InventoryFilterOption('low_stock', 'Low Stock'),
    _InventoryFilterOption('out_of_stock', 'Out of Stock'),
    _InventoryFilterOption('track_inventory', 'Track Inventory'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<InventoryProvider>();

    return Scaffold(
      appBar: AppHeader(
        title: l10n.inventoryTitle,
        actions: [
          IconButton(
            icon: const Icon(Icons.mic_outlined),
            tooltip: 'Voice Stock Entry',
            onPressed: () =>
                Navigator.pushNamed(context, '/inventory/voice-entry'),
          ),
          IconButton(
            icon: const Icon(Icons.precision_manufacturing_outlined),
            tooltip: 'Production',
            onPressed: () => Navigator.pushNamed(context, '/production'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: provider.refresh,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Low Stock Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: colorScheme.errorContainer,
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.lowStock,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.error,
                          ),
                        ),
                        Text(
                          '${provider.lowStockCount} low • ${provider.outOfStockCount} out',
                          style: TextStyle(
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.error,
                  ),
                ],
              ),
            ),
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by product, SKU, or barcode',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  context
                                      .read<InventoryProvider>()
                                      .setQuery('');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) =>
                          context.read<InventoryProvider>().setQuery(value),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    onPressed: _scanBarcodeAndOpenInventoryDetail,
                    tooltip: l10n.scanBarcode,
                    icon: const Icon(Icons.qr_code_scanner),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters
                      .map(
                        (filter) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: AppChip(
                            label: filter.label,
                            isSelected: provider.filter == filter.key,
                            onTap: () => context
                                .read<InventoryProvider>()
                                .setFilter(filter.key),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Product List
            Expanded(
              child: _buildContent(colorScheme, l10n, bottomInset),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    ColorScheme colorScheme,
    AppLocalizations l10n,
    double bottomInset,
  ) {
    final provider = context.watch<InventoryProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                provider.error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: provider.refresh,
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.filteredProducts.isEmpty) {
      return Center(
        child: Text(l10n.noProductsFound),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 24 + bottomInset),
      itemCount: provider.filteredProducts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final product = provider.filteredProducts[index];
        return _buildProductCard(product, colorScheme, l10n);
      },
    );
  }

  Widget _buildProductCard(InventoryProductRecord product,
      ColorScheme colorScheme, AppLocalizations l10n) {
    final status = _statusFor(product);
    return AppCard(
      onTap: () => _showProductDetail(product),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      '${product.category}${product.sku.isEmpty ? '' : ' • SKU: ${product.sku}'}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip(label: status.label, color: status.color),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildStockInfo(
                'Current Stock',
                _formatStock(product.currentQty, product.unit),
                colorScheme,
              ),
              _buildStockInfo(
                'Minimum Stock',
                _formatStock(product.minQty, product.unit),
                colorScheme,
              ),
              _buildStockInfo('Unit', product.unit, colorScheme),
              if (!product.trackInventory)
                Text(
                  'Tracking Off',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              if (product.trackInventory && product.barcode.isNotEmpty)
                SizedBox(
                  width: 150,
                  child: Text(
                    product.barcode,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockInfo(String label, String value, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  void _showProductDetail(InventoryProductRecord product) {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                l10n.productDetail,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(l10n.productName, product.name),
                    const Divider(),
                    _buildDetailRow('Category', product.category),
                    const Divider(),
                    _buildDetailRow('Unit', product.unit),
                    const Divider(),
                    _buildDetailRow(l10n.barcode, product.barcode),
                    const Divider(),
                    _buildDetailRow('Current Stock',
                        _formatStock(product.currentQty, product.unit)),
                    const Divider(),
                    _buildDetailRow('Minimum Stock',
                        _formatStock(product.minQty, product.unit)),
                    const Divider(),
                    _buildDetailRow('Status', _statusFor(product).label),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (!product.trackInventory)
                AppCard(
                  backgroundColor: Colors.grey.shade100,
                  child: const Text('Inventory tracking disabled.'),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showPurchaseDialog(product),
                        icon: const Icon(Icons.inventory_2_rounded),
                        label: const Text('Purchase'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showSaleDialog(product),
                        icon: const Icon(Icons.remove_circle_outline),
                        label: const Text('Sale'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showWastageDialog(product),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Wastage'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showAdjustmentDialog(product),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Adjustment'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showHistorySheet(product),
                  icon: const Icon(Icons.history),
                  label: const Text('History'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPurchaseDialog(InventoryProductRecord product) async {
    final saved = await _showStockActionDialog(
      title: 'Purchase',
      requiresPurchasePrice: true,
      supportsSupplier: true,
      onSubmit: (form) => context.read<InventoryProvider>().purchase(
            productId: product.productId,
            quantity: form.quantity,
            purchasePricePaise: calculateGstLineBreakup(
              amountPaise: form.purchasePricePaise!,
              gstPercent: product.gstPercent,
              calculationType: product.gstCalculationType,
            ).basicAmountPaise,
            supplier: form.supplier,
            note: form.note,
          ),
    );

    if (!mounted || !saved) {
      return;
    }

    final nextAction = await showDialog<_PostPurchaseAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saved Successfully'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, _PostPurchaseAction.scanNext),
            child: const Text('Scan Next'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _PostPurchaseAction.done),
            child: const Text('Done'),
          ),
        ],
      ),
    );

    if (!mounted) {
      return;
    }

    if (nextAction == _PostPurchaseAction.scanNext) {
      await _scanBarcodeAndOpenInventoryDetail();
    }
  }

  Future<void> _showSaleDialog(InventoryProductRecord product) async {
    final saved = await _showStockActionDialog(
      title: 'Sale',
      onSubmit: (form) => context.read<InventoryProvider>().sale(
            productId: product.productId,
            quantity: form.quantity,
            note: form.note,
          ),
    );

    if (saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sale saved successfully')),
      );
    }
  }

  Future<void> _showWastageDialog(InventoryProductRecord product) async {
    final saved = await _showStockActionDialog(
      title: 'Wastage',
      requiresReason: true,
      onSubmit: (form) => context.read<InventoryProvider>().wastage(
            productId: product.productId,
            quantity: form.quantity,
            reason: form.extra ?? 'Other',
            note: form.note,
          ),
    );

    if (saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wastage saved successfully')),
      );
    }
  }

  Future<void> _showAdjustmentDialog(InventoryProductRecord product) async {
    final saved = await _showStockActionDialog(
      title: 'Adjustment',
      allowsDirection: true,
      onSubmit: (form) {
        final increase = form.extra == 'Increase';
        return context.read<InventoryProvider>().adjustment(
              productId: product.productId,
              quantity: form.quantity,
              increase: increase,
              note: form.note,
            );
      },
    );

    if (saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adjustment saved successfully')),
      );
    }
  }

  Future<bool> _showStockActionDialog({
    required String title,
    bool requiresReason = false,
    bool allowsDirection = false,
    bool requiresPurchasePrice = false,
    bool supportsSupplier = false,
    required Future<void> Function(_StockActionFormValue form) onSubmit,
  }) async {
    final purchasePriceController = TextEditingController();
    final supplierController = TextEditingController();
    final noteController = TextEditingController();
    final notesDictationController = VoiceDictationController(
      speechRecognition: SpeechRecognitionService(),
    );
    notesDictationController.bindController(noteController);
    int quantity = 1;
    String reason = 'Expired';
    String direction = 'Increase';

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QuantityInputStepper(
                  value: quantity,
                  min: 1,
                  onChanged: (value) {
                    setStateDialog(() => quantity = value);
                  },
                ),
                if (requiresPurchasePrice) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: purchasePriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration:
                        const InputDecoration(labelText: 'Purchase Price *'),
                  ),
                ],
                if (supportsSupplier) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: supplierController,
                    decoration:
                        const InputDecoration(labelText: 'Supplier (optional)'),
                  ),
                ],
                if (allowsDirection) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: direction,
                    decoration: const InputDecoration(labelText: 'Direction'),
                    items: const [
                      DropdownMenuItem(
                          value: 'Increase', child: Text('Increase')),
                      DropdownMenuItem(
                          value: 'Decrease', child: Text('Decrease')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setStateDialog(() => direction = value);
                    },
                  ),
                ],
                if (requiresReason) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: reason,
                    decoration: const InputDecoration(labelText: 'Reason'),
                    items: const [
                      DropdownMenuItem(
                          value: 'Expired', child: Text('Expired')),
                      DropdownMenuItem(
                          value: 'Damaged', child: Text('Damaged')),
                      DropdownMenuItem(
                          value: 'Wedding Leftover',
                          child: Text('Wedding Leftover')),
                      DropdownMenuItem(
                          value: 'Transport Damage',
                          child: Text('Transport Damage')),
                      DropdownMenuItem(
                          value: 'Trial Arrangement',
                          child: Text('Trial Arrangement')),
                      DropdownMenuItem(
                          value: 'Staff Use', child: Text('Staff Use')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setStateDialog(() => reason = value);
                    },
                  ),
                ],
                const SizedBox(height: 12),
                VoiceDictationFieldHeader(
                  label: 'Notes (optional)',
                  controller: notesDictationController,
                  compact: true,
                ),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (quantity <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Quantity must be greater than zero.')),
                  );
                  return;
                }

                try {
                  int? purchasePricePaise;
                  if (requiresPurchasePrice) {
                    purchasePricePaise = _parseCurrencyToPaise(
                      purchasePriceController.text,
                    );
                    if (purchasePricePaise <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Purchase Price must be greater than zero.',
                          ),
                        ),
                      );
                      return;
                    }
                  }

                  await onSubmit(
                    _StockActionFormValue(
                      quantity: quantity,
                      note: noteController.text.trim(),
                      extra: requiresReason
                          ? reason
                          : (allowsDirection ? direction : null),
                      purchasePricePaise: purchasePricePaise,
                      supplier: supplierController.text.trim(),
                    ),
                  );
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext, true);
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_friendlyInventoryError(e))),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    notesDictationController.dispose();
    return result == true;
  }

  Future<void> _scanBarcodeAndOpenInventoryDetail() async {
    final l10n = AppLocalizations.of(context)!;
    final scanned = await showCameraBarcodeScanner(
      context,
      title: l10n.scanBarcode,
    );

    final query = scanned?.trim() ?? '';
    if (query.isEmpty || !mounted) {
      return;
    }

    await _lookupBarcodeAndOpenInventoryDetail(query);
  }

  Future<void> _lookupBarcodeAndOpenInventoryDetail(String query) async {
    final matched =
        await _productRepository.lookupProductBySearchPriority(query);
    if (!mounted) {
      return;
    }

    if (matched == null) {
      await _showBarcodeNotFoundDialog();
      return;
    }

    InventoryProductRecord? inventoryProduct;
    final provider = context.read<InventoryProvider>();

    for (final item in provider.products) {
      if (item.productId == matched.id) {
        inventoryProduct = item;
        break;
      }
    }

    if (inventoryProduct == null) {
      await provider.refresh();
      if (!mounted) {
        return;
      }

      for (final item in provider.products) {
        if (item.productId == matched.id) {
          inventoryProduct = item;
          break;
        }
      }
    }

    if (inventoryProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product not available in inventory.')),
      );
      return;
    }

    _showProductDetail(inventoryProduct);
  }

  Future<void> _showBarcodeNotFoundDialog() async {
    final action = await showDialog<_BarcodeNotFoundAction>(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text('Barcode not found.'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, _BarcodeNotFoundAction.createProduct),
            child: const Text('Create Product'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, _BarcodeNotFoundAction.scanAgain),
            child: const Text('Scan Again'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, _BarcodeNotFoundAction.cancel),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (!mounted) {
      return;
    }

    if (action == _BarcodeNotFoundAction.createProduct) {
      Navigator.pushNamed(context, '/products');
      return;
    }

    if (action == _BarcodeNotFoundAction.scanAgain) {
      await _scanBarcodeAndOpenInventoryDetail();
    }
  }

  Future<void> _showHistorySheet(InventoryProductRecord product) async {
    final provider = context.read<InventoryProvider>();
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: FutureBuilder<List<InventoryTransactionRecord>>(
          future: provider.loadHistory(product.productId),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Could not load history.'));
            }

            final history = snapshot.data ?? const [];
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Text(
                  'History',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                    'Closing ${_formatStock(product.currentQty, product.unit)}'),
                const SizedBox(height: 16),
                if (history.isEmpty)
                  const Text('No inventory transactions yet.'),
                ...history.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  LocaleFormatter.formatDateTime(
                                    context,
                                    DateTime.parse(entry.createdAt),
                                  ),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_txnLabel(entry)} ${_signedQty(entry)} ${_pluralizeUnit(product.unit, entry.qty)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (entry.txnType == 'purchase' &&
                                    entry.purchasePricePaise != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '${LocaleFormatter.formatCurrency(context, entry.purchasePricePaise!)} / ${product.unit}',
                                    style: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                if (entry.txnType == 'purchase' &&
                                    entry.supplier.trim().isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Supplier',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    entry.supplier.trim(),
                                    style: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 2),
                                Text(
                                  entry.reason.isNotEmpty
                                      ? '${entry.source} • ${entry.reason}'
                                      : entry.source,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                                if (entry.note.isNotEmpty)
                                  Text(
                                    entry.note,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  _InventoryStatus _statusFor(InventoryProductRecord product) {
    if (!product.trackInventory) {
      return const _InventoryStatus('Tracking Off', Colors.grey);
    }
    if (product.currentQty == 0) {
      return const _InventoryStatus('Out of Stock', Colors.red);
    }
    if (product.currentQty <= product.minQty) {
      return const _InventoryStatus('Low Stock', Colors.orange);
    }
    return const _InventoryStatus('OK', Colors.green);
  }

  String _formatStock(int qty, String unit) {
    return '$qty ${_pluralizeUnit(unit, qty)}';
  }

  String _pluralizeUnit(String unit, int qty) {
    if (qty == 1) return unit;
    switch (unit) {
      case 'Stem':
        return 'Stems';
      case 'Bunch':
        return 'Bunches';
      case 'Piece':
        return 'Pieces';
      case 'Box':
        return 'Boxes';
      case 'Roll':
        return 'Rolls';
      case 'Pot':
        return 'Pots';
      case 'Packet':
        return 'Packets';
      case 'Kg':
        return 'Kgs';
      case 'Meter':
        return 'Meters';
      default:
        return '${unit}s';
    }
  }

  String _friendlyInventoryError(Object error) {
    final message = error.toString();
    if (message.contains('greater than zero')) {
      if (message.contains('Purchase price')) {
        return 'Purchase Price must be greater than zero.';
      }
      return 'Quantity must be greater than zero.';
    }
    if (message.contains('Stock cannot go negative')) {
      return 'Stock cannot go negative.';
    }
    return 'Could not save inventory change. Please try again.';
  }

  int _parseCurrencyToPaise(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9.]'), '').trim();
    if (cleaned.isEmpty) return 0;
    final value = double.tryParse(cleaned) ?? 0;
    return (value * 100).round();
  }

  String _txnLabel(InventoryTransactionRecord record) {
    switch (record.txnType) {
      case 'purchase':
        return 'Purchase';
      case 'sale':
        return 'Sale';
      case 'wastage':
        return 'Wastage';
      case 'adjustment':
        return 'Adjustment';
      default:
        return record.txnType;
    }
  }

  String _signedQty(InventoryTransactionRecord record) {
    switch (record.txnType) {
      case 'purchase':
        return '+${record.qty}';
      case 'sale':
      case 'wastage':
        return '-${record.qty}';
      case 'adjustment':
        return record.reason == 'Increase'
            ? '+${record.qty}'
            : '-${record.qty}';
      default:
        return '${record.qty}';
    }
  }
}

class _InventoryFilterOption {
  final String key;
  final String label;

  const _InventoryFilterOption(this.key, this.label);
}

class _InventoryStatus {
  final String label;
  final Color color;

  const _InventoryStatus(this.label, this.color);
}

class _StockActionFormValue {
  final int quantity;
  final String note;
  final String? extra;
  final int? purchasePricePaise;
  final String supplier;

  const _StockActionFormValue({
    required this.quantity,
    required this.note,
    required this.extra,
    required this.purchasePricePaise,
    required this.supplier,
  });
}

enum _BarcodeNotFoundAction {
  createProduct,
  scanAgain,
  cancel,
}

enum _PostPurchaseAction {
  scanNext,
  done,
}
