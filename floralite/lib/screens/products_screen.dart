import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/voice_dictation_controller.dart';
import '../data/repositories/product_repository.dart';
import '../models/gst_calculation_type.dart';
import 'bouquet_builder_screen.dart';
import '../l10n/app_localizations.dart';
import '../providers/printer_provider.dart';
import '../providers/product_provider.dart';
import '../providers/storage_mode_provider.dart';
import 'cloud_products_screen.dart';
import '../services/speech_recognition_service.dart';
import '../widgets/app_header.dart';
import '../widgets/camera_barcode_scanner_page.dart';
import '../widgets/common_widgets.dart';
import '../widgets/voice_dictation_field_header.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
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

  static const Map<String, String> _legacyCategoryLabels = {
    'Finished Product': 'Finished Products',
    'Flower': 'Flowers',
    'Filler': 'Fillers',
    'Accessory': 'Accessories',
    'Other': 'Others',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProductProvider>();
      _searchController.text = provider.query;
      provider.loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.watch<StorageModeProvider?>()?.isCloud ?? false) {
      return const CloudProductsScreen();
    }

    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<ProductProvider>();

    return Scaffold(
      appBar: AppHeader(
        title: l10n.products,
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
            icon: const Icon(Icons.refresh),
            onPressed: provider.refresh,
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
                    child: SizedBox(
                      height: 64,
                      child: TextField(
                        controller: _searchController,
                        onChanged: provider.setQuery,
                        decoration: InputDecoration(
                          hintText: 'Search by Product Name, SKU, or Barcode',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    provider.setQuery('');
                                  },
                                  icon: const Icon(Icons.clear_rounded),
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 64,
                    child: FilledButton.tonalIcon(
                      onPressed: () => _showFilterSheet(context),
                      icon: const Icon(Icons.tune_rounded),
                      label: Text(l10n.filter),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ..._categoryChips.map((category) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildCategoryChip(
                          category,
                          category == 'all' ? l10n.allProducts : category,
                          provider.category,
                        ),
                      );
                    }),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AppChip(
                        label: provider.showDeleted
                            ? 'Show Deleted On'
                            : 'Show Deleted',
                        isSelected: provider.showDeleted,
                        onTap: () {
                          context
                              .read<ProductProvider>()
                              .setShowDeleted(!provider.showDeleted);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _buildBody(l10n, bottomInset),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: _showCreateProduct,
        tooltip: l10n.addProduct,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, double bottomInset) {
    final provider = context.watch<ProductProvider>();

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

    if (provider.products.isEmpty) {
      final noFilters = provider.query.trim().isEmpty &&
          provider.category == 'all' &&
          provider.trackInventory == null &&
          provider.showActive &&
          !provider.showInactive &&
          !provider.favoriteOnly &&
          !provider.showDeleted;

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(noFilters ? 'No products yet.' : l10n.noProductsFound),
              const SizedBox(height: 12),
              if (noFilters)
                FilledButton.icon(
                  onPressed: _showCreateProduct,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addProduct),
                ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(12, 10, 12, 80 + bottomInset),
      itemCount: provider.products.length,
      itemBuilder: (context, index) {
        return _buildProductCard(context, provider.products[index], l10n);
      },
    );
  }

  Widget _buildCategoryChip(String key, String label, String selectedCategory) {
    final isSelected = selectedCategory == key;
    return AppChip(
      label: label,
      isSelected: isSelected,
      onTap: () {
        context.read<ProductProvider>().setCategory(key);
      },
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    ProductRecord product,
    AppLocalizations l10n,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final price = '₹${(product.sellingPricePaise / 100).toStringAsFixed(0)}';
    final statusLabel = product.deletedAt != null
        ? 'Deleted'
        : (product.active ? 'Active' : 'Inactive');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductThumbnail(product),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${product.category} • ${product.defaultUnit} • $statusLabel',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        price,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2E7D32),
                          fontSize: 16,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'GST ${product.gstPercent}% ${product.gstCalculationType.label}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 5),
              _buildBarcodeSummary(product, colorScheme),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (product.deletedAt == null)
                    _buildCompactProductAction(
                      tooltip: product.favorite ? 'Unfavourite' : 'Favourite',
                      icon: product.favorite ? Icons.star : Icons.star_border,
                      color: product.favorite ? Colors.amber : null,
                      onPressed: () => context
                          .read<ProductProvider>()
                          .toggleFavorite(product),
                    )
                  else
                    const SizedBox(width: 48),
                  const Spacer(),
                  if (product.deletedAt == null) ...[
                    if (_isFinishedProductCategory(product.category))
                      _buildCompactProductAction(
                        tooltip: 'Recipe',
                        icon: Icons.menu_book_outlined,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BouquetBuilderScreen(
                              existingProductId: product.id,
                            ),
                          ),
                        ),
                      ),
                    _buildCompactProductAction(
                      tooltip: product.florapriseBarcode.trim().isEmpty
                          ? 'Generate Barcode'
                          : 'Reprint Barcode',
                      icon: Icons.print_outlined,
                      onPressed: () => _generateOrPrintBarcode(product),
                    ),
                    _buildCompactProductAction(
                      tooltip: l10n.edit,
                      icon: Icons.edit_outlined,
                      onPressed: () => _showEditProduct(product),
                    ),
                    _buildCompactProductAction(
                      tooltip: l10n.delete,
                      icon: Icons.delete_outline,
                      onPressed: () => _confirmDelete(product),
                    ),
                  ] else
                    _buildCompactProductAction(
                      tooltip: 'Restore',
                      icon: Icons.restore,
                      onPressed: () => context
                          .read<ProductProvider>()
                          .restoreProduct(product.id),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailFallback(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.local_florist_outlined,
        color: colorScheme.primary,
        size: 22,
      ),
    );
  }

  Widget _buildProductThumbnail(ProductRecord product) {
    final imagePath = product.imagePath?.trim();
    if (imagePath == null || imagePath.isEmpty) {
      return Builder(builder: _buildThumbnailFallback);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.file(
        File(imagePath),
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildThumbnailFallback(context);
        },
      ),
    );
  }

  Widget _buildBarcodeSummary(
    ProductRecord product,
    ColorScheme colorScheme,
  ) {
    final manufacturerBarcode = product.manufacturerBarcode.trim();
    return DefaultTextStyle(
      style: TextStyle(
        color: Colors.grey.shade700,
        fontSize: 12,
        height: 1.2,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Floraprise: ${product.florapriseBarcode}',
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (manufacturerBarcode.isNotEmpty)
            Text('Manufacturer: $manufacturerBarcode'),
        ],
      ),
    );
  }

  Widget _buildCompactProductAction({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, color: color),
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.padded,
        minimumSize: const Size(48, 48),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Future<void> _generateOrPrintBarcode(ProductRecord product) async {
    var barcode = product.florapriseBarcode.trim();
    if (barcode.isEmpty) {
      barcode = await ProductRepository().generateFlorapriseBarcode(product.id);
      if (!mounted) return;
      await context.read<ProductProvider>().refresh();
    }

    if (!mounted) return;
    final quantity = await _askPrintQuantity(product.name);
    if (quantity == null || quantity <= 0) return;

    if (!mounted) return;
    final printer = context.read<PrinterProvider>();
    await printer.enqueueBarcodeLabel(
      productName: product.name,
      barcode: barcode,
      quantity: quantity,
      sellingPricePaise: product.sellingPricePaise,
    );
    if (!mounted) return;
    final message = printer.error ?? 'Barcode label sent to printer queue.';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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

  void _showFilterSheet(BuildContext context) {
    final provider = context.read<ProductProvider>();
    final l10n = AppLocalizations.of(context)!;
    var localTrack = provider.trackInventory;
    var localShowActive = provider.showActive;
    var localShowInactive = provider.showInactive;
    var localFavoriteOnly = provider.favoriteOnly;
    var localShowDeleted = provider.showDeleted;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.filterProducts,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: localTrack == null
                      ? 'all'
                      : (localTrack == true ? 'yes' : 'no'),
                  decoration:
                      const InputDecoration(labelText: 'Track Inventory'),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'yes', child: Text('Yes')),
                    DropdownMenuItem(value: 'no', child: Text('No')),
                  ],
                  onChanged: (value) {
                    setStateModal(() {
                      if (value == 'yes') {
                        localTrack = true;
                      } else if (value == 'no') {
                        localTrack = false;
                      } else {
                        localTrack = null;
                      }
                    });
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: localShowActive,
                  onChanged: (value) =>
                      setStateModal(() => localShowActive = value),
                  title: const Text('Active'),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  value: localShowInactive,
                  onChanged: (value) =>
                      setStateModal(() => localShowInactive = value),
                  title: const Text('Inactive'),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  value: localFavoriteOnly,
                  onChanged: (value) =>
                      setStateModal(() => localFavoriteOnly = value),
                  title: const Text('Favourite Only'),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  value: localShowDeleted,
                  onChanged: (value) =>
                      setStateModal(() => localShowDeleted = value),
                  title: const Text('Show Deleted'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      await provider.setTrackInventory(localTrack);
                      await provider.setStatusFilters(
                        showActive: localShowActive,
                        showInactive: localShowInactive,
                      );
                      await provider.setFavoriteOnly(localFavoriteOnly);
                      await provider.setShowDeleted(localShowDeleted);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
                    child: Text(l10n.applyFilters),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showCreateProduct() async {
    final provider = context.read<ProductProvider>();
    final input = await _showProductFormDialog();
    if (input == null) return;

    try {
      await provider.createProduct(input);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyErrorMessage(e))),
      );
    }
  }

  Future<void> _showEditProduct(ProductRecord product) async {
    final provider = context.read<ProductProvider>();
    final input = await _showProductFormDialog(existing: product);
    if (input == null) return;

    try {
      await provider.updateProduct(product.id, input);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyErrorMessage(e))),
      );
    }
  }

  Future<void> _confirmDelete(ProductRecord product) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<ProductProvider>();
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text('Hide ${product.name} from product list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;
    await provider.deleteProduct(product.id);
  }

  Future<ProductUpsertInput?> _showProductFormDialog({
    ProductRecord? existing,
  }) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final sellingController = TextEditingController(
      text: existing == null
          ? ''
          : (existing.sellingPricePaise / 100).toStringAsFixed(0),
    );
    final gstController =
        TextEditingController(text: (existing?.gstPercent ?? 12).toString());
    final skuController = TextEditingController(text: existing?.sku ?? '');
    final manufacturerBarcodeController =
        TextEditingController(text: existing?.manufacturerBarcode ?? '');
    final florapriseBarcodeController =
        TextEditingController(text: existing?.florapriseBarcode ?? '');
    final supplierController =
        TextEditingController(text: existing?.supplier ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');
    final notesDictationController = VoiceDictationController(
      speechRecognition: SpeechRecognitionService(),
    );
    notesDictationController.bindController(notesController);
    final minStockController = TextEditingController(
      text: (existing?.minStock ?? 0).toString(),
    );

    var category = _dropdownCategoryValue(existing?.category);
    var defaultUnit = existing?.defaultUnit ??
        ProductRepository.defaultUnitForCategory(category);
    var trackInventory =
        existing?.trackInventory ?? _isFinishedProductCategory(category);
    var minStock = int.tryParse(minStockController.text.trim()) ?? 0;
    var active = existing?.active ?? true;
    var favorite = existing?.favorite ?? false;
    var gstCalculationType =
        existing?.gstCalculationType ?? GstCalculationType.inclusive;
    var unitManuallyChanged = existing != null &&
        existing.defaultUnit !=
            ProductRepository.defaultUnitForCategory(category);

    final result = await showDialog<ProductUpsertInput>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(existing == null ? 'Add Product' : 'Edit Product'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration:
                          const InputDecoration(labelText: 'Product Name *'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration:
                          const InputDecoration(labelText: 'Category *'),
                      items: ProductRepository.allowedCategories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        final previousCategory = category;
                        setStateDialog(() {
                          category = value;
                          if (_isFinishedProductCategory(value)) {
                            trackInventory = true;
                          }
                          final previousDefault =
                              ProductRepository.defaultUnitForCategory(
                            previousCategory,
                          );
                          if (!unitManuallyChanged ||
                              defaultUnit == previousDefault) {
                            defaultUnit =
                                ProductRepository.defaultUnitForCategory(value);
                            unitManuallyChanged = false;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: defaultUnit,
                      decoration:
                          const InputDecoration(labelText: 'Default Unit *'),
                      items: ProductRepository.allowedUnits
                          .map(
                            (unit) => DropdownMenuItem(
                                value: unit, child: Text(unit)),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setStateDialog(() {
                          defaultUnit = value;
                          unitManuallyChanged = value !=
                              ProductRepository.defaultUnitForCategory(
                                  category);
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: sellingController,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Selling Price *'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: gstController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'GST %'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<GstCalculationType>(
                      initialValue: gstCalculationType,
                      decoration: const InputDecoration(
                        labelText: 'GST Calculation Type',
                      ),
                      items: GstCalculationType.values
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setStateDialog(() {
                          gstCalculationType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: skuController,
                      decoration: const InputDecoration(labelText: 'SKU'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: manufacturerBarcodeController,
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
                            if (scanned == null || scanned.isEmpty) {
                              return;
                            }
                            manufacturerBarcodeController.text = scanned;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: florapriseBarcodeController,
                      decoration: const InputDecoration(
                          labelText: 'Floraprise Barcode'),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      value: trackInventory,
                      onChanged: (value) =>
                          setStateDialog(() => trackInventory = value),
                      title: const Text('Track Inventory'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (trackInventory)
                      TextField(
                        controller: minStockController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Minimum Stock'),
                        onChanged: (value) =>
                            minStock = int.tryParse(value.trim()) ?? 0,
                      ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: supplierController,
                      decoration: const InputDecoration(labelText: 'Supplier'),
                    ),
                    const SizedBox(height: 10),
                    VoiceDictationFieldHeader(
                      label: 'Notes',
                      controller: notesDictationController,
                      compact: true,
                    ),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      value: active,
                      onChanged: (value) =>
                          setStateDialog(() => active = value),
                      title: const Text('Active'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    SwitchListTile(
                      value: favorite,
                      onChanged: (value) =>
                          setStateDialog(() => favorite = value),
                      title: const Text('Favourite'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final sellingRupees =
                    int.tryParse(sellingController.text.trim()) ?? -1;
                final gstPercent = int.tryParse(gstController.text.trim()) ?? 0;

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Product Name is required.')),
                  );
                  return;
                }

                if (sellingRupees < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Selling Price cannot be negative.'),
                    ),
                  );
                  return;
                }

                Navigator.pop(
                  context,
                  ProductUpsertInput(
                    name: name,
                    category: category,
                    defaultUnit: defaultUnit,
                    sellingPricePaise: sellingRupees * 100,
                    purchasePricePaise: existing?.purchasePricePaise,
                    gstPercent: gstPercent,
                    gstCalculationType: gstCalculationType,
                    sku: skuController.text.trim(),
                    manufacturerBarcode:
                        manufacturerBarcodeController.text.trim(),
                    florapriseBarcode: florapriseBarcodeController.text.trim(),
                    trackInventory: trackInventory,
                    minStock: minStock,
                    supplier: supplierController.text.trim(),
                    notes: notesController.text.trim(),
                    active: active,
                    favorite: favorite,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    notesDictationController.dispose();
    return result;
  }

  String _friendlyErrorMessage(Object error) {
    final text = error.toString();
    if (text.contains('UNIQUE constraint failed')) {
      return 'Barcode/SKU must be unique.';
    }
    if (text.contains('Product name is required')) {
      return 'Product Name is required.';
    }
    if (text.contains('Selling price cannot be negative')) {
      return 'Selling Price cannot be negative.';
    }
    if (text.contains('Purchase price cannot be negative')) {
      return 'Purchase Price cannot be negative.';
    }
    return 'Could not save product. Please try again.';
  }

  String _dropdownCategoryValue(String? value) {
    final trimmed = value?.trim() ?? '';
    final normalized = _legacyCategoryLabels[trimmed] ?? trimmed;
    if (ProductRepository.allowedCategories.contains(normalized)) {
      return normalized;
    }
    return 'Others';
  }

  bool _isFinishedProductCategory(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null) return false;
    return normalized == 'finished products' ||
        normalized == 'finished product' ||
        normalized == 'bouquet' ||
        normalized == 'bunch' ||
        normalized == 'arrangement' ||
        normalized == 'centerpiece' ||
        normalized == 'basket arrangement' ||
        normalized == 'vase arrangement' ||
        normalized == 'wreath' ||
        normalized == 'corsage' ||
        normalized == 'boutonniere' ||
        normalized == 'garland' ||
        normalized == 'floral box' ||
        normalized == 'gift hamper' ||
        normalized == 'custom';
  }
}
