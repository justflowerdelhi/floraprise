import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../controllers/voice_dictation_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/design.dart';
import '../models/share_branding.dart';
import '../providers/design_provider.dart';
import '../services/design_share_image_service.dart';
import '../services/share_branding_settings_service.dart';
import '../services/speech_recognition_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/voice_dictation_field_header.dart';

enum _DesignShareOption {
  original,
  branded,
  quotation,
}

class MyDesignsScreen extends StatefulWidget {
  const MyDesignsScreen({
    super.key,
    this.isSelectionMode = false,
  });

  final bool isSelectionMode;

  @override
  State<MyDesignsScreen> createState() => _MyDesignsScreenState();
}

class _MyDesignsScreenState extends State<MyDesignsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ShareBrandingSettingsService _brandingSettingsService =
      ShareBrandingSettingsService();
  final DesignShareImageService _shareImageService = DesignShareImageService();

  bool _isCatalogSelectionMode = false;
  final Set<int> _selectedDesignIds = <int>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DesignProvider>().loadDesigns();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myDesigns),
        actions: widget.isSelectionMode
            ? null
            : [
                if (_isCatalogSelectionMode)
                  IconButton(
                    tooltip: 'Share Catalog',
                    onPressed: _selectedDesignIds.isEmpty
                        ? null
                        : _shareCatalogSelection,
                    icon: const Icon(Icons.share_rounded),
                  ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isCatalogSelectionMode = !_isCatalogSelectionMode;
                      _selectedDesignIds.clear();
                    });
                  },
                  child: Text(_isCatalogSelectionMode ? 'Cancel' : 'Select'),
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
                        onChanged: (value) {
                          context.read<DesignProvider>().setSearchQuery(value);
                        },
                        decoration: InputDecoration(
                          hintText: l10n.searchByIdFlowerColorOccasion,
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: const Icon(Icons.mic_none_rounded),
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
            Expanded(
              child: Consumer<DesignProvider>(
                builder: (context, provider, child) {
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
                            Text(provider.error!),
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

                  if (provider.designs.isEmpty) {
                    return ListView(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 96 + bottomInset),
                      children: [
                        AppCard(
                          child: Column(
                            children: [
                              Icon(
                                Icons.photo_library_outlined,
                                size: 56,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                l10n.noDesignsFound,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final textScale =
                          MediaQuery.textScalerOf(context).scale(1);
                      final maxExtent = textScale > 1.2 ? 220.0 : 190.0;

                      return GridView.builder(
                        padding:
                            EdgeInsets.fromLTRB(16, 0, 16, 96 + bottomInset),
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: maxExtent,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio:
                              constraints.maxWidth < 360 ? 0.88 : 0.92,
                        ),
                        itemCount: provider.designs.length,
                        itemBuilder: (context, index) {
                          final design = provider.designs[index];
                          final selected =
                              _selectedDesignIds.contains(design.id);
                          return GestureDetector(
                            onLongPress: _isCatalogSelectionMode
                                ? null
                                : () => _showDesignActions(context, design),
                            child: AppCard(
                              onTap: () => _onDesignTap(design),
                              padding: EdgeInsets.zero,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 7,
                                    child: _buildImagePane(
                                      design,
                                      isSelected: selected,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            design.bouquetId,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            design.sellingPriceLabel.isEmpty
                                                ? '₹0'
                                                : design.sellingPriceLabel,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOptions(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.addDesign),
      ),
    );
  }

  Widget _buildImagePane(DesignRecord design, {required bool isSelected}) {
    final isReady = design.isReady;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: design.imagePath != null && design.imagePath!.isNotEmpty
                ? ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: Image.file(
                      File(design.imagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.image_not_supported_outlined,
                              size: 48),
                        );
                      },
                    ),
                  )
                : const Center(
                    child: Icon(Icons.photo_library_outlined, size: 48),
                  ),
          ),
          Positioned(
            left: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isReady ? Colors.green.shade700 : Colors.orange.shade700,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                isReady ? 'Ready' : 'Needs Review',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: InkWell(
              onTap: () =>
                  context.read<DesignProvider>().toggleFavourite(design),
              child: Icon(
                design.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: design.isFavorite ? Colors.red : Colors.grey.shade700,
              ),
            ),
          ),
          if (_isCatalogSelectionMode)
            Positioned(
              right: 10,
              bottom: 10,
              child: Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isSelected ? Colors.green.shade700 : Colors.white,
                size: 24,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onDesignTap(DesignRecord design) async {
    if (!widget.isSelectionMode && _isCatalogSelectionMode) {
      setState(() {
        if (_selectedDesignIds.contains(design.id)) {
          _selectedDesignIds.remove(design.id);
        } else {
          _selectedDesignIds.add(design.id);
        }
      });
      return;
    }

    if (!widget.isSelectionMode) {
      await _showDesignFormDialog(existing: design);
      return;
    }

    int? amountPaise = design.sellingPricePaise;
    if (amountPaise == null || amountPaise <= 0) {
      amountPaise = await _promptSellingPrice();
      if (amountPaise == null) return;
    }

    if (!mounted) return;
    Navigator.pop(
      context,
      SelectedDesign(
        designId: design.bouquetId,
        description: design.description,
        price: '₹${(amountPaise / 100).toStringAsFixed(0)}',
        imagePath: design.imagePath,
      ),
    );
  }

  Future<int?> _promptSellingPrice() async {
    final controller = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Selling Price'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            prefixText: '₹',
            labelText: 'Selling Price',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim()) ?? 0;
              if (value <= 0) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter the selling amount.'),
                  ),
                );
                return;
              }
              Navigator.pop(context, value * 100);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return result;
  }

  void _showDesignActions(BuildContext context, DesignRecord design) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: Text(l10n.edit),
              onTap: () {
                Navigator.pop(context);
                _showDesignFormDialog(existing: design);
              },
            ),
            ListTile(
              leading: Icon(
                design.isFavorite ? Icons.favorite : Icons.favorite_border,
              ),
              title: Text(l10n.favourite),
              onTap: () {
                Navigator.pop(context);
                context.read<DesignProvider>().toggleFavourite(design);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                _shareSingleDesign(design);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded),
              title: Text(l10n.delete),
              onTap: () async {
                Navigator.pop(context);
                final ok = await context
                    .read<DesignProvider>()
                    .deleteDesign(design.id);
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content:
                        Text(ok ? 'Design deleted' : 'Failed to delete design'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareSingleDesign(DesignRecord design) async {
    if (!mounted) return;
    final option = await _pickShareOption(context, isCatalogShare: false);
    if (option == null || !mounted) return;

    final originalPath = design.imagePath?.trim() ?? '';
    if (originalPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image found for this design.')),
      );
      return;
    }

    final temporaryFiles = <String>[];
    try {
      final settings = await _brandingSettingsService.loadSettings();
      final identity = await _brandingSettingsService.loadBrandingIdentity();

      final String sharePath;
      if (option == _DesignShareOption.original) {
        sharePath = originalPath;
      } else {
        final generated = await _runWithPreparingDialog(
          () => _shareImageService.generateBrandedJpeg(
            design: design,
            settings: settings,
            variant: option == _DesignShareOption.quotation
                ? DesignShareVariant.quotation
                : DesignShareVariant.brandedPreview,
          ),
        );
        sharePath = generated.path;
        temporaryFiles.add(generated.path);
      }

      final message = _shareMessage(
        design: design,
        shopName: identity.shopName,
        includePrice: settings.showPrice,
      );

      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(sharePath)],
        text: message,
        subject: design.description.trim().isEmpty
            ? design.bouquetId
            : design.description,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to share design: $error')),
      );
    } finally {
      for (final path in temporaryFiles) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
  }

  Future<void> _shareCatalogSelection() async {
    final provider = context.read<DesignProvider>();
    final selectedDesigns = provider.designs
        .where((design) => _selectedDesignIds.contains(design.id))
        .toList();
    if (selectedDesigns.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one design to share.')),
      );
      return;
    }

    final option = await _pickShareOption(context, isCatalogShare: true);
    if (option == null || !mounted) return;

    final temporaryFiles = <String>[];
    try {
      final settings = await _brandingSettingsService.loadSettings();
      final identity = await _brandingSettingsService.loadBrandingIdentity();

      final sharePaths = <String>[];
      if (option == _DesignShareOption.original) {
        for (final design in selectedDesigns) {
          final path = design.imagePath?.trim() ?? '';
          if (path.isNotEmpty) {
            sharePaths.add(path);
          }
        }
      } else {
        final generatedFiles = await _runWithPreparingDialog(
          () async {
            final files = <File>[];
            for (final design in selectedDesigns) {
              if ((design.imagePath?.trim() ?? '').isEmpty) continue;
              final created = await _shareImageService.generateBrandedJpeg(
                design: design,
                settings: settings,
                variant: option == _DesignShareOption.quotation
                    ? DesignShareVariant.quotation
                    : DesignShareVariant.brandedPreview,
              );
              files.add(created);
            }
            return files;
          },
        );

        for (final file in generatedFiles) {
          sharePaths.add(file.path);
          temporaryFiles.add(file.path);
        }
      }

      if (sharePaths.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No shareable image found.')),
        );
        return;
      }

      final message =
          '${_shareMessage(design: selectedDesigns.first, shopName: identity.shopName, includePrice: settings.showPrice)}\n\nCatalog includes ${sharePaths.length} designs.';

      if (!mounted) return;
      await Share.shareXFiles(
        sharePaths.map(XFile.new).toList(),
        text: message,
        subject: 'Bouquet Catalog',
      );

      if (!mounted) return;
      setState(() {
        _isCatalogSelectionMode = false;
        _selectedDesignIds.clear();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to share catalog: $error')),
      );
    } finally {
      for (final path in temporaryFiles) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
  }

  Future<_DesignShareOption?> _pickShareOption(
    BuildContext context, {
    required bool isCatalogShare,
  }) {
    final title = isCatalogShare ? 'Share Catalog' : 'Share Design';
    return showDialog<_DesignShareOption>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Original Image'),
              onTap: () => Navigator.pop(context, _DesignShareOption.original),
            ),
            ListTile(
              leading: const Icon(Icons.auto_fix_high_outlined),
              title: const Text('Branded Image (Recommended)'),
              onTap: () => Navigator.pop(context, _DesignShareOption.branded),
            ),
            ListTile(
              leading: const Icon(Icons.request_quote_outlined),
              title: const Text('Share as Quotation'),
              onTap: () => Navigator.pop(context, _DesignShareOption.quotation),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  String _shareMessage({
    required DesignRecord design,
    required String shopName,
    required bool includePrice,
  }) {
    final lines = <String>[
      '🌸 Thank you for your interest.',
      '',
      'Please find the bouquet design below.',
      '',
    ];
    if (includePrice && (design.sellingPricePaise ?? 0) > 0) {
      lines.add('Price: ${design.sellingPriceLabel}');
      lines.add('');
    }
    lines.add('Regards');
    if (shopName.trim().isNotEmpty) {
      lines.add('');
      lines.add(shopName.trim());
    }
    return lines.join('\n');
  }

  Future<T> _runWithPreparingDialog<T>(Future<T> Function() action) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Expanded(child: Text('Preparing Image...')),
          ],
        ),
      ),
    );

    try {
      return await action();
    } finally {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, size: 32),
              title: const Text(
                'Take Photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              onTap: () async {
                Navigator.pop(context);
                final image = await ImagePicker().pickImage(
                  source: ImageSource.camera,
                  imageQuality: 85,
                );
                if (!mounted || image == null) return;
                await _showDesignFormDialog(initialImagePath: image.path);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.photo_library, size: 32),
              title: const Text(
                'Choose from Gallery',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              onTap: () async {
                Navigator.pop(context);
                final image = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 85,
                );
                if (!mounted || image == null) return;
                await _showDesignFormDialog(initialImagePath: image.path);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.collections, size: 32),
              title: const Text(
                'Bulk Import',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Select multiple images (up to 100)'),
              onTap: () async {
                Navigator.pop(context);
                await _startBulkImport();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startBulkImport() async {
    final images = await ImagePicker().pickMultiImage(imageQuality: 85);
    if (!mounted || images.isEmpty) return;

    final selectedPaths = images.map((image) => image.path).toList();
    List<String> importPaths = selectedPaths;
    if (selectedPaths.length > 100) {
      importPaths = selectedPaths.take(100).toList();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only first 100 images will be imported.'),
        ),
      );
    }

    final payload = await Navigator.of(context).push<_BulkImportPayload>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _BulkImportReviewScreen(imagePaths: importPaths),
      ),
    );
    if (!mounted || payload == null) return;

    final provider = context.read<DesignProvider>();
    final success = await provider.bulkImportDesigns(
      imagePaths: payload.imagePaths,
      sellingPricePaise: payload.sellingPricePaise,
      flowers: payload.flowers,
      occasion: payload.occasion,
      color: payload.color,
      collection: payload.collection,
      notes: payload.notes,
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Imported ${payload.imagePaths.length} designs'
              : (provider.error ?? 'Bulk import failed'),
        ),
      ),
    );
  }

  Future<void> _showFilterSheet(BuildContext context) async {
    final provider = context.read<DesignProvider>();
    final flowerController =
        TextEditingController(text: provider.flowerFilter ?? '');
    final occasionController =
        TextEditingController(text: provider.occasionFilter ?? '');
    final colorController =
        TextEditingController(text: provider.colorFilter ?? '');
    String status = provider.statusFilter ?? 'all';
    bool? favourite = provider.favouriteFilter;
    String priceRange =
        _priceRangeKey(provider.minPricePaise, provider.maxPricePaise);

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.filters,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: flowerController,
                      decoration: const InputDecoration(labelText: 'Flower'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: occasionController,
                      decoration: const InputDecoration(labelText: 'Occasion'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: colorController,
                      decoration: const InputDecoration(labelText: 'Color'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      items: const [
                        DropdownMenuItem(
                            value: 'all', child: Text('All Status')),
                        DropdownMenuItem(
                          value: 'needs_review',
                          child: Text('Needs Review'),
                        ),
                        DropdownMenuItem(value: 'ready', child: Text('Ready')),
                      ],
                      onChanged: (value) =>
                          setSheetState(() => status = value ?? 'all'),
                      decoration: const InputDecoration(labelText: 'Status'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: priceRange,
                      items: const [
                        DropdownMenuItem(
                            value: 'all', child: Text('All Prices')),
                        DropdownMenuItem(
                            value: 'lt500', child: Text('Under ₹500')),
                        DropdownMenuItem(
                            value: '500_1000', child: Text('₹500 - ₹1000')),
                        DropdownMenuItem(
                            value: '1000_2000', child: Text('₹1000 - ₹2000')),
                        DropdownMenuItem(
                            value: 'gt2000', child: Text('Above ₹2000')),
                      ],
                      onChanged: (value) =>
                          setSheetState(() => priceRange = value ?? 'all'),
                      decoration: const InputDecoration(labelText: 'Price'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: favourite == null
                          ? 'all'
                          : (favourite! ? 'yes' : 'no'),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All')),
                        DropdownMenuItem(
                            value: 'yes', child: Text('Favourite only')),
                        DropdownMenuItem(
                            value: 'no', child: Text('Non-favourite only')),
                      ],
                      onChanged: (value) {
                        setSheetState(() {
                          if (value == 'yes') favourite = true;
                          if (value == 'no') favourite = false;
                          if (value == 'all') favourite = null;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Favourite'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              await provider.clearFilters();
                              if (!context.mounted) return;
                              Navigator.pop(context);
                            },
                            child: const Text('Clear'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              final range = _rangeForKey(priceRange);
                              await provider.setFilters(
                                flower: flowerController.text,
                                occasion: occasionController.text,
                                color: colorController.text,
                                status: status,
                                favourite: favourite,
                                minPricePaise: range.$1,
                                maxPricePaise: range.$2,
                              );
                              if (!context.mounted) return;
                              Navigator.pop(context);
                            },
                            child: const Text('Apply Filters'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _priceRangeKey(int? min, int? max) {
    if (min == null && max == null) return 'all';
    if (min == null && max == 50000) return 'lt500';
    if (min == 50000 && max == 100000) return '500_1000';
    if (min == 100000 && max == 200000) return '1000_2000';
    if (min == 200000 && max == null) return 'gt2000';
    return 'all';
  }

  (int?, int?) _rangeForKey(String key) {
    switch (key) {
      case 'lt500':
        return (null, 50000);
      case '500_1000':
        return (50000, 100000);
      case '1000_2000':
        return (100000, 200000);
      case 'gt2000':
        return (200000, null);
      default:
        return (null, null);
    }
  }

  Future<void> _showDesignFormDialog({
    DesignRecord? existing,
    String? initialImagePath,
  }) async {
    final designProvider = context.read<DesignProvider>();
    final descriptionController =
        TextEditingController(text: existing?.description ?? '');
    final priceController = TextEditingController(
      text: existing?.sellingPricePaise == null
          ? ''
          : (existing!.sellingPricePaise! / 100).toStringAsFixed(0),
    );
    final flowersController =
        TextEditingController(text: existing?.flowers ?? '');
    final occasionController =
        TextEditingController(text: existing?.occasion ?? '');
    final colorController = TextEditingController(text: existing?.color ?? '');
    final collectionController =
        TextEditingController(text: existing?.collection ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');
    final notesDictationController = VoiceDictationController(
      speechRecognition: SpeechRecognitionService(),
    );
    notesDictationController.bindController(notesController);

    String? imagePath = existing?.imagePath ?? initialImagePath;
    bool removeImage = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickImage(ImageSource source) async {
              final image = await ImagePicker().pickImage(
                source: source,
                imageQuality: 85,
              );
              if (image == null) return;
              setDialogState(() {
                imagePath = image.path;
                removeImage = false;
              });
            }

            return AlertDialog(
              title: Text(existing == null ? 'Add Design' : 'Edit Design'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade200,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: imagePath != null && !removeImage
                          ? Image.file(
                              File(imagePath!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                    child: Text('Image unavailable'));
                              },
                            )
                          : const Center(child: Icon(Icons.photo, size: 40)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Camera'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            setDialogState(() {
                              imagePath = null;
                              removeImage = true;
                            });
                          },
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Remove'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      decoration:
                          const InputDecoration(labelText: 'Description *'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Selling Price *',
                        prefixText: '₹',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: flowersController,
                      decoration: const InputDecoration(labelText: 'Flowers'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: occasionController,
                      decoration: const InputDecoration(labelText: 'Occasion'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: colorController,
                      decoration: const InputDecoration(labelText: 'Color'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: collectionController,
                      decoration:
                          const InputDecoration(labelText: 'Collection'),
                    ),
                    const SizedBox(height: 8),
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
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final description = descriptionController.text.trim();
                    final amount =
                        int.tryParse(priceController.text.trim()) ?? 0;

                    if (imagePath == null && existing == null) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                            content: Text('Please add design image.')),
                      );
                      return;
                    }
                    if (description.isEmpty) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                            content: Text('Please enter description.')),
                      );
                      return;
                    }
                    if (amount <= 0) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                            content: Text('Please enter the selling amount.')),
                      );
                      return;
                    }

                    bool success;
                    if (existing == null) {
                      success = await designProvider.createDesign(
                        imagePath: imagePath,
                        description: description,
                        sellingPricePaise: amount * 100,
                        flowers: flowersController.text,
                        occasion: occasionController.text,
                        color: colorController.text,
                        collection: collectionController.text,
                        notes: notesController.text,
                      );
                    } else {
                      success = await designProvider.updateDesign(
                        id: existing.id,
                        description: description,
                        sellingPricePaise: amount * 100,
                        flowers: flowersController.text,
                        occasion: occasionController.text,
                        color: colorController.text,
                        collection: collectionController.text,
                        notes: notesController.text,
                        replaceImagePath:
                            imagePath != null && imagePath != existing.imagePath
                                ? imagePath
                                : null,
                        removeImage: removeImage,
                      );
                    }

                    if (!mounted) return;
                    if (success) {
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    } else {
                      if (!mounted) return;
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text(
                            designProvider.error ?? 'Could not save design',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
    notesDictationController.dispose();
  }
}

class SelectedDesign {
  final String designId;
  final String description;
  final String price;
  final String? imagePath;

  const SelectedDesign({
    required this.designId,
    required this.description,
    required this.price,
    this.imagePath,
  });
}

class _BulkImportPayload {
  const _BulkImportPayload({
    required this.imagePaths,
    required this.sellingPricePaise,
    required this.flowers,
    required this.occasion,
    required this.color,
    required this.collection,
    required this.notes,
  });

  final List<String> imagePaths;
  final int? sellingPricePaise;
  final String? flowers;
  final String? occasion;
  final String? color;
  final String? collection;
  final String? notes;
}

class _BulkImportReviewScreen extends StatefulWidget {
  const _BulkImportReviewScreen({required this.imagePaths});

  final List<String> imagePaths;

  @override
  State<_BulkImportReviewScreen> createState() =>
      _BulkImportReviewScreenState();
}

class _BulkImportReviewScreenState extends State<_BulkImportReviewScreen> {
  final TextEditingController _flowersController = TextEditingController();
  final TextEditingController _occasionController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _collectionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final VoiceDictationController _notesDictationController =
      VoiceDictationController(
    speechRecognition: SpeechRecognitionService(),
  );

  @override
  void initState() {
    super.initState();
    _notesDictationController.bindController(_notesController);
  }

  @override
  void dispose() {
    _flowersController.dispose();
    _occasionController.dispose();
    _colorController.dispose();
    _collectionController.dispose();
    _notesController.dispose();
    _priceController.dispose();
    _notesDictationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Review')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text(
                    '${widget.imagePaths.length} images selected',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  const Text('Apply to all'),
                ],
              ),
            ),
            SizedBox(
              height: 120,
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: widget.imagePaths.length,
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(widget.imagePaths[index]),
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    TextField(
                      controller: _flowersController,
                      decoration: const InputDecoration(labelText: 'Flowers'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _occasionController,
                      decoration: const InputDecoration(labelText: 'Occasion'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _colorController,
                      decoration: const InputDecoration(labelText: 'Color'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _collectionController,
                      decoration:
                          const InputDecoration(labelText: 'Collection'),
                    ),
                    const SizedBox(height: 8),
                    VoiceDictationFieldHeader(
                      label: 'Notes',
                      controller: _notesDictationController,
                      compact: true,
                    ),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Selling Price (optional)',
                        prefixText: '₹',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          final amountRaw = _priceController.text.trim();
                          final amount = amountRaw.isEmpty
                              ? null
                              : int.tryParse(amountRaw);

                          if (amountRaw.isNotEmpty &&
                              (amount == null || amount <= 0)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Enter a valid optional price or leave it blank.'),
                              ),
                            );
                            return;
                          }

                          Navigator.pop(
                            context,
                            _BulkImportPayload(
                              imagePaths: widget.imagePaths,
                              sellingPricePaise:
                                  amount == null ? null : amount * 100,
                              flowers: _valueOrNull(_flowersController.text),
                              occasion: _valueOrNull(_occasionController.text),
                              color: _valueOrNull(_colorController.text),
                              collection:
                                  _valueOrNull(_collectionController.text),
                              notes: _valueOrNull(_notesController.text),
                            ),
                          );
                        },
                        child: const Text('Import All'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _valueOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
