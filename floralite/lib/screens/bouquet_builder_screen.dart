import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../data/repositories/product_repository.dart';
import '../data/repositories/production_repository.dart';
import '../models/walk_in_enums.dart';
import '../models/walk_in_line_item.dart';
import '../models/walk_in_session.dart';
import '../providers/printer_provider.dart';
import '../services/business_data_event_bus.dart';
import '../widgets/common_widgets.dart';
import '../widgets/product_picker_sheet.dart';
import '../widgets/quantity_input_stepper.dart';
import 'take_away_screen.dart';

class BouquetBuilderScreen extends StatefulWidget {
  const BouquetBuilderScreen({super.key, this.existingProductId});

  final int? existingProductId;

  @override
  State<BouquetBuilderScreen> createState() => _BouquetBuilderScreenState();
}

enum _RecipeSavedAction { produceNow, continueEditing, close }

class _BouquetBuilderScreenState extends State<BouquetBuilderScreen> {
  final ProductionRepository _productionRepository = ProductionRepository();
  final ProductRepository _productRepository = ProductRepository();

  final _nameController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _labourCostController = TextEditingController(text: '0');

  String _category = 'Bouquet';
  final List<RecipeItem> _components = [];

  bool _isLoading = true;
  bool _isSaving = false;
  bool _updateMasterRecipe = true;

  int _shelfLifeDays = 3;
  int _refreshAfterDays = 2;
  String? _occasion;
  String? _imagePath;

  static const _recipeCategories = [
    'Bouquet',
    'Bunch',
    'Arrangement',
    'Centerpiece',
    'Basket Arrangement',
    'Vase Arrangement',
    'Wreath',
    'Corsage',
    'Boutonniere',
    'Garland',
    'Floral Box',
    'Gift Hamper',
    'Custom',
  ];

  bool get _isFromRecipe => widget.existingProductId != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_isFromRecipe) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final product =
          await _productRepository.getProductById(widget.existingProductId!);
      final components =
          await _productionRepository.getRecipeItems(widget.existingProductId!);
      final metadata = await _productionRepository
          .getRecipeMetadata(widget.existingProductId!);
      if (!mounted) return;
      setState(() {
        _nameController.text = product?.name ?? '';
        final loadedCategory = product?.category ?? 'Bouquet';
        _category = _recipeCategories.contains(loadedCategory)
            ? loadedCategory
            : 'Bouquet';
        _sellingPriceController.text =
            _rupeesFromPaise(product?.sellingPricePaise ?? 0);
        _components.addAll(components);
        if (metadata != null) {
          _shelfLifeDays = metadata['shelf_life_days'] as int? ?? 3;
          _refreshAfterDays = metadata['refresh_after_days'] as int? ?? 2;
          _occasion = metadata['occasion'] as String?;
        }
        _imagePath = product?.imagePath;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Failed to load recipe: $e');
    }
  }

  String _rupeesFromPaise(int paise) {
    return (paise / 100).toStringAsFixed(2);
  }

  int get _sellingPricePaise {
    final text =
        _sellingPriceController.text.replaceAll(RegExp(r'[^0-9.]'), '');
    return ((double.tryParse(text) ?? 0) * 100).round();
  }

  int get _labourCostPaise {
    final text = _labourCostController.text.replaceAll(RegExp(r'[^0-9.]'), '');
    return ((double.tryParse(text) ?? 0) * 100).round();
  }

  int get _materialCostPaise => _components.fold<int>(
        0,
        (sum, c) => sum + (c.purchasePricePaise * c.quantity),
      );

  int get _totalCostPaise => _materialCostPaise + _labourCostPaise;

  int get _profitPaise => _sellingPricePaise - _totalCostPaise;

  double get _marginPercent {
    if (_sellingPricePaise <= 0) return 0;
    return (_profitPaise / _sellingPricePaise) * 100;
  }

  double get _markupPercent {
    if (_totalCostPaise <= 0) return 0;
    return (_profitPaise / _totalCostPaise) * 100;
  }

  Future<void> _addComponent() async {
    final product = await showProductPickerSheet(context);
    if (product == null || !mounted) return;

    final quantity = await _askQuantity(product.name);
    if (quantity == null || quantity <= 0 || !mounted) return;

    final existingIndex = _components.indexWhere(
      (c) => c.rawProductId == product.id,
    );
    if (existingIndex >= 0) {
      final existing = _components[existingIndex];
      setState(() {
        _components[existingIndex] = RecipeItem(
          rawProductId: existing.rawProductId,
          productName: existing.productName,
          unit: existing.unit,
          quantity: existing.quantity + quantity,
          currentQty: existing.currentQty,
          purchasePricePaise: existing.purchasePricePaise,
        );
      });
    } else {
      setState(() {
        _components.add(RecipeItem(
          rawProductId: product.id,
          productName: product.name,
          unit: product.defaultUnit,
          quantity: quantity,
          currentQty: 0,
          purchasePricePaise: product.purchasePricePaise ?? 0,
        ));
      });
    }
  }

  Future<int?> _askQuantity(String productName, {int initialValue = 1}) async {
    var quantity = initialValue < 1 ? 1 : initialValue;
    return showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('$productName quantity'),
          content: QuantityInputStepper(
            value: quantity,
            min: 1,
            onChanged: (value) {
              setDialogState(() => quantity = value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, quantity),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editComponent(RecipeItem item, int index) async {
    final quantity =
        await _askQuantity(item.productName, initialValue: item.quantity);
    if (quantity == null || quantity <= 0 || !mounted) return;
    setState(() {
      _components[index] = RecipeItem(
        rawProductId: item.rawProductId,
        productName: item.productName,
        unit: item.unit,
        quantity: quantity,
        currentQty: item.currentQty,
        purchasePricePaise: item.purchasePricePaise,
      );
    });
  }

  void _deleteComponent(int index) {
    setState(() => _components.removeAt(index));
  }

  bool _validateForAction() {
    if (_components.isEmpty) {
      _showError('Add at least one component');
      return false;
    }
    if (_sellingPricePaise <= 0) {
      _showError('Enter a selling price');
      return false;
    }
    return true;
  }

  Future<void> _createAndSellNow() async {
    if (!_validateForAction()) return;

    final name = _nameController.text.trim().isEmpty
        ? 'Custom Bouquet'
        : _nameController.text.trim();

    final session = WalkInSession.empty(FulfilmentType.takeAway).copyWith(
      lines: [
        WalkInLineItem(
          description: name,
          quantity: 1,
          unitPricePaise: _sellingPricePaise,
          source: 'custom_bouquet',
          gstPercent: 0,
        ),
      ],
    );

    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TakeAwayScreen(initialSession: session),
      ),
    );
  }

  Future<void> _produceReadyBouquet() async {
    if (!_validateForAction()) return;

    final name = _nameController.text.trim();
    if (!_isFromRecipe && name.isEmpty) {
      _showError('Enter a bouquet name to produce');
      return;
    }

    final quantity = await _askProduceQuantity();
    if (quantity == null || quantity <= 0 || !mounted) return;

    setState(() => _isSaving = true);
    try {
      if (_isFromRecipe && _updateMasterRecipe) {
        await _saveRecipeToRepository();
      }

      final result = await _productionRepository.produceBouquet(
        finishedProductId: widget.existingProductId,
        productName: name,
        category: _category,
        quantity: quantity,
        components: _components,
        sellingPricePaise: _sellingPricePaise,
        labourCostPaise: _labourCostPaise,
        imagePath: _imagePath,
        shelfLifeDays: _shelfLifeDays,
        refreshAfterDays: _refreshAfterDays,
      );

      if (!mounted) return;
      _publishInventoryEvent();
      await _handleProductionCompleted(result);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<int?> _askProduceQuantity() async {
    var quantity = 1;
    return showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('How many bouquets?'),
          content: Center(
            heightFactor: 1,
            child: QuantityInputStepper(
              value: quantity,
              min: 1,
              onChanged: (value) {
                setDialogState(() => quantity = value);
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, quantity),
              child: const Text('Produce'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAsRecipe() async {
    if (!_validateForAction()) return;

    final result = await showDialog<_RecipeNameDialogResult>(
      context: context,
      builder: (context) => _RecipeNameDialog(
        initialName: _nameController.text,
        initialCategory: _category,
        initialOccasion: _occasion,
      ),
    );
    if (result == null || !mounted) return;

    _nameController.text = result.name;
    _category = result.category;
    _occasion = result.occasion;

    setState(() => _isSaving = true);
    try {
      final productId = await _saveRecipeToRepository(
        name: result.name,
        category: result.category,
        occasion: result.occasion,
      );

      if (!mounted) return;
      _publishInventoryEvent();
      final nextAction = await _showRecipeSavedDialog();
      if (!mounted) return;
      switch (nextAction) {
        case _RecipeSavedAction.produceNow:
          final quantity = await _askProduceQuantity();
          if (quantity == null || quantity <= 0 || !mounted) return;
          final production = await _productionRepository.produceBouquet(
            finishedProductId: productId,
            productName: result.name,
            category: result.category,
            quantity: quantity,
            components: _components,
            sellingPricePaise: _sellingPricePaise,
            labourCostPaise: _labourCostPaise,
            imagePath: _imagePath,
            shelfLifeDays: _shelfLifeDays,
            refreshAfterDays: _refreshAfterDays,
          );
          if (!mounted) return;
          _publishInventoryEvent();
          await _handleProductionCompleted(production);
        case _RecipeSavedAction.continueEditing:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  BouquetBuilderScreen(existingProductId: productId),
            ),
          );
        case _RecipeSavedAction.close:
        case null:
          Navigator.maybePop(context);
      }
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<int> _saveRecipeToRepository({
    String? name,
    String? category,
    String? occasion,
  }) async {
    return _productionRepository.saveBouquetRecipe(
      finishedProductId: widget.existingProductId,
      productName: name ?? _nameController.text,
      category: category ?? _category,
      items: _components,
      sellingPricePaise: _sellingPricePaise,
      shelfLifeDays: _shelfLifeDays,
      refreshAfterDays: _refreshAfterDays,
      occasion: occasion ?? _occasion,
      imagePath: _imagePath,
    );
  }

  Future<_RecipeSavedAction?> _showRecipeSavedDialog() {
    return showDialog<_RecipeSavedAction>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Expanded(child: Text('Recipe Saved Successfully')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _RecipeSavedAction.close),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, _RecipeSavedAction.continueEditing),
            child: const Text('Continue Editing'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, _RecipeSavedAction.produceNow),
            child: const Text('Produce Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickRecipePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose From Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final image =
        await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (!mounted || image == null) return;
    setState(() => _imagePath = image.path);
  }

  void _publishInventoryEvent() {
    context.read<BusinessDataEventBus>().publish(
          source: BusinessDataChangeSource.inventory,
        );
  }

  Future<void> _handleProductionCompleted(ProductionResult result) async {
    final action = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Production Completed'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Skip'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.qr_code_2),
            label: const Text('Print Barcode'),
          ),
        ],
      ),
    );
    if (!mounted) return;

    if (action == true) {
      final product = await _productRepository.getProductById(
        result.finishedProductId,
      );
      if (!mounted) return;
      final barcode = product?.florapriseBarcode.trim() ?? '';
      if (product != null && barcode.isNotEmpty) {
        await context.read<PrinterProvider>().enqueueBarcodeLabel(
              productName: product.name,
              barcode: barcode,
              quantity: result.finishedQuantity,
              sellingPricePaise: product.sellingPricePaise,
            );
      }
    }

    if (mounted) Navigator.pushReplacementNamed(context, '/ready-bouquets');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sellingPriceController.dispose();
    _labourCostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isFromRecipe ? 'Edit Bouquet Recipe' : 'New Bouquet'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildNameAndCategory(),
            const SizedBox(height: 16),
            _buildPhotoCard(),
            const SizedBox(height: 16),
            _buildComponentsCard(),
            const SizedBox(height: 16),
            _buildPricingCard(),
            const SizedBox(height: 16),
            _buildCostSummaryCard(),
            if (_isFromRecipe) ...[
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text('Update master recipe'),
                subtitle: const Text(
                    'Save component and price changes back to the recipe'),
                value: _updateMasterRecipe,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _updateMasterRecipe = value);
                  }
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildNameAndCategory() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Bouquet Name',
              border: OutlineInputBorder(),
            ),
            readOnly: _isFromRecipe,
          ),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
            child: IgnorePointer(
              ignoring: _isFromRecipe,
              child: DropdownButton<String>(
                value: _category,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                items: _recipeCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentsCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Components',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          if (_components.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('No components added yet'),
              ),
            )
          else
            ..._components.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final lineCost = item.purchasePricePaise * item.quantity;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.productName),
                subtitle: Text(
                  '₹${(item.purchasePricePaise / 100).toStringAsFixed(2)} × ${item.quantity} ${item.unit} = '
                  '₹${(lineCost / 100).toStringAsFixed(2)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _editComponent(item, index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteComponent(index),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addComponent,
            icon: const Icon(Icons.add),
            label: const Text('+ Add Item'),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard() {
    final imagePath = _imagePath;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recipe Photo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          if (imagePath == null || imagePath.trim().isEmpty)
            OutlinedButton.icon(
              onPressed: _pickRecipePhoto,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Capture Photo'),
            )
          else
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(imagePath),
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 88,
                      height: 88,
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.tonalIcon(
                  onPressed: _pickRecipePhoto,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Change Photo'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPricingCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pricing & Details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sellingPriceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Selling Price *',
              prefixText: '₹',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _labourCostController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Labour Cost (Optional)',
              prefixText: '₹',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildCostSummaryCard() {
    final material = _materialCostPaise / 100;
    final labour = _labourCostPaise / 100;
    final total = _totalCostPaise / 100;
    final selling = _sellingPricePaise / 100;
    final profit = _profitPaise / 100;
    final margin = _marginPercent;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cost Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _buildCostRow('Material Cost', material),
          _buildCostRow('Labour Cost', labour),
          const Divider(),
          _buildCostRow('Total Cost', total, isBold: true),
          _buildCostRow('Selling Price', selling),
          const Divider(),
          _buildCostRow('Profit', profit, color: Colors.green),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCostRowInline('Margin', margin,
                  suffix: '%', currency: false),
              _buildCostRowInline('Markup', _markupPercent,
                  suffix: '%', currency: false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCostRow(
    String label,
    double value, {
    bool isBold = false,
    Color? color,
    String suffix = '',
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '₹${value.toStringAsFixed(2)}$suffix',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostRowInline(
    String label,
    double value, {
    String suffix = '',
    Color? color,
    bool currency = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 6),
          Text(
            '${currency ? '₹' : ''}${value.toStringAsFixed(2)}$suffix',
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        FilledButton.icon(
          onPressed: _isSaving ? null : _createAndSellNow,
          icon: const Icon(Icons.point_of_sale),
          label: const Text('Sell Custom Bouquet'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _isSaving ? null : _produceReadyBouquet,
          icon: const Icon(Icons.precision_manufacturing_outlined),
          label: const Text('Produce'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Theme.of(context).colorScheme.onSecondary,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _isSaving ? null : _saveAsRecipe,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save as Recipe'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }
}

class _RecipeNameDialogResult {
  final String name;
  final String category;
  final String? occasion;

  const _RecipeNameDialogResult(this.name, this.category, this.occasion);
}

class _RecipeNameDialog extends StatefulWidget {
  final String initialName;
  final String initialCategory;
  final String? initialOccasion;

  const _RecipeNameDialog({
    required this.initialName,
    required this.initialCategory,
    this.initialOccasion,
  });

  @override
  State<_RecipeNameDialog> createState() => _RecipeNameDialogState();
}

class _RecipeNameDialogState extends State<_RecipeNameDialog> {
  late final _nameController = TextEditingController(text: widget.initialName);
  late String _category = widget.initialCategory;
  late String? _occasion = widget.initialOccasion;

  static const _categories = [
    'Bouquet',
    'Bunch',
    'Arrangement',
    'Centerpiece',
    'Basket Arrangement',
    'Vase Arrangement',
    'Wreath',
    'Corsage',
    'Boutonniere',
    'Garland',
    'Floral Box',
    'Gift Hamper',
    'Custom',
  ];

  static const _occasions = [
    'Birthday',
    'Anniversary',
    'Love & Romance',
    'Wedding',
    'Congratulations',
    'Sympathy',
    'Thank You',
    'Corporate',
    'Festival',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save as Recipe'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Recipe Name *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Recipe Category *',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
            child: DropdownButton<String>(
              value: _category,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
          ),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Occasion (Optional)',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
            child: DropdownButton<String?>(
              value: _occasion,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              hint: const Text('Select occasion'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('— None —'),
                ),
                ..._occasions.map(
                  (o) => DropdownMenuItem<String?>(
                    value: o,
                    child: Text(o),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _occasion = value),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recipe name is required')),
              );
              return;
            }
            Navigator.pop(
              context,
              _RecipeNameDialogResult(name, _category, _occasion),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
