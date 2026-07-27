import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

import '../controllers/voice_dictation_controller.dart';
import '../controllers/voice_purchase_controller.dart';
import '../l10n/app_localizations.dart';
import '../providers/purchase_provider.dart';
import '../data/repositories/purchase_repository.dart';
import '../services/product_matcher.dart';
import '../services/speech_recognition_service.dart';
import '../services/voice_purchase_entry_service.dart';
import '../services/voice_purchase_parser.dart';
import '../widgets/common_widgets.dart';
import '../widgets/quantity_input_stepper.dart';
import '../widgets/voice_dictation_field_header.dart';

class PurchaseListScreen extends StatefulWidget {
  const PurchaseListScreen({super.key});

  @override
  State<PurchaseListScreen> createState() => _PurchaseListScreenState();
}

class _PurchaseListScreenState extends State<PurchaseListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _listScrollController = ScrollController();
  final Map<int, GlobalKey> _itemKeys = <int, GlobalKey>{};
  VoicePurchaseController? _voiceController;
  bool _voiceLoading = true;
  int _shownVoiceMessageVersion = 0;
  int _handledVoiceAddedVersion = 0;
  int? _highlightedItemId;
  Timer? _highlightTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.read<PurchaseProvider>().loadItems();
        _initializeVoiceEntry();
      }
    });
  }

  Future<void> _initializeVoiceEntry() async {
    try {
      final provider = context.read<PurchaseProvider>();
      final products = await provider.getInventoryTrackedProducts();
      if (!mounted) return;

      final productById = <int, Map<String, dynamic>>{};
      for (final product in products) {
        final id = product['id'] as int?;
        if (id != null) {
          productById[id] = product;
        }
      }

      final controller = VoicePurchaseController(
        speechRecognition: SpeechRecognitionService(),
        voiceEntry: VoicePurchaseEntryService(
          parser: VoicePurchaseParser(),
          matcher: ProductMatcher(
            products.map(
              (product) => ProductMatchCandidate(
                id: product['id'] as int,
                name: product['name'] as String,
              ),
            ),
          ),
        ),
        onApply: (product, parsed) async {
          final raw = productById[product.id];
          final unit = (raw?['default_unit'] as String?)?.trim();
          final result = await provider.addOrMergeVoiceItem(
            productId: product.id,
            quantity: parsed.quantity,
            unit: (unit == null || unit.isEmpty) ? 'Piece' : unit,
          );
          return VoicePurchaseApplyResult(
            merged: result.merged,
            totalQuantity: result.totalQuantity,
          );
        },
      );
      controller.addListener(_handleVoiceControllerChange);

      setState(() {
        _voiceController = controller;
        _voiceLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _voiceLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not initialize voice entry.')),
      );
    }
  }

  void _handleVoiceControllerChange() {
    if (!mounted) return;
    final controller = _voiceController;
    if (controller == null) return;

    setState(() {});

    if (controller.messageVersion != _shownVoiceMessageVersion) {
      _shownVoiceMessageVersion = controller.messageVersion;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || controller.message == null) return;
        final message = controller.message!;
        final isPermissionBlocked =
            message.toLowerCase().contains('permission is blocked') ||
                message.toLowerCase().contains('app settings');
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(message),
              action: isPermissionBlocked
                  ? const SnackBarAction(
                      label: 'Open Settings',
                      onPressed: openAppSettings,
                    )
                  : null,
            ),
          );
      });
    }

    if (controller.addedVersion != _handledVoiceAddedVersion &&
        controller.recentlyAdded != null) {
      _handledVoiceAddedVersion = controller.addedVersion;
      _scrollToVoiceUpdatedItem(controller.recentlyAdded!.productId);
    }
  }

  Future<void> _toggleVoiceEntry() async {
    final controller = _voiceController;
    if (controller == null || _voiceLoading) return;
    if (controller.isListening) {
      await controller.stop();
    } else {
      await controller.start();
    }
  }

  void _scrollToVoiceUpdatedItem(int productId) {
    final provider = context.read<PurchaseProvider>();
    PurchaseListItem? target;
    for (final item in provider.items) {
      if (item.productId == productId) {
        target = item;
        break;
      }
    }
    if (target == null) return;
    final targetItem = target;

    final rowKey = _itemKeys.putIfAbsent(targetItem.id, () => GlobalKey());

    _highlightTimer?.cancel();
    setState(() => _highlightedItemId = targetItem.id);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final rowContext = rowKey.currentContext;
      if (rowContext == null) return;

      await Scrollable.ensureVisible(
        rowContext,
        duration: const Duration(milliseconds: 320),
        alignment: 0.18,
        curve: Curves.easeOutCubic,
      );

      if (!mounted) return;
      _highlightTimer = Timer(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        setState(() => _highlightedItemId = null);
      });
    });
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _listScrollController.dispose();
    _voiceController?.removeListener(_handleVoiceControllerChange);
    _voiceController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.purchaseList),
        actions: [
          IconButton(
            icon: Icon(
              _voiceController?.isListening == true ? Icons.stop : Icons.mic,
            ),
            tooltip: _voiceController?.isListening == true
                ? 'Stop Voice Entry'
                : 'Start Voice Entry',
            onPressed: _voiceLoading ? null : _toggleVoiceEntry,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareWhatsApp(context),
          ),
        ],
      ),
      body: Consumer<PurchaseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.refresh(),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }

          final groupedItems = provider.groupedItems;
          return Column(
            children: [
              _buildVoiceEntryCard(),
              const SizedBox(height: 8),
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.search,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              provider.setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) => provider.setSearchQuery(value),
                ),
              ),
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    FilterChip(
                      label: Text(l10n.all),
                      selected: provider.filterStatus == 'all',
                      onSelected: (_) => provider.setStatusFilter('all'),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(l10n.pending),
                      selected: provider.filterStatus == 'pending',
                      onSelected: (_) => provider.setStatusFilter('pending'),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(l10n.purchased),
                      selected: provider.filterStatus == 'purchased',
                      onSelected: (_) => provider.setStatusFilter('purchased'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // List
              Expanded(
                child: groupedItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.shopping_basket_outlined,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              l10n.noItems,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(l10n.addFirstItem),
                          ],
                        ),
                      )
                    : ListView(
                        controller: _listScrollController,
                        padding:
                            EdgeInsets.fromLTRB(16, 0, 16, 96 + bottomInset),
                        children: groupedItems.entries.map((entry) {
                          return _buildCategorySection(
                              context, entry.key, entry.value);
                        }).toList(),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'autoSuggest',
            onPressed: () => _generateAutoSuggest(context),
            icon: const Icon(Icons.auto_awesome),
            label: Text(l10n.generateAutoSuggest),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'voiceEntry',
            onPressed: _voiceLoading ? null : _toggleVoiceEntry,
            icon: Icon(
              _voiceController?.isListening == true ? Icons.stop : Icons.mic,
            ),
            label: Text(
              _voiceController?.isListening == true
                  ? 'Stop Voice Entry'
                  : 'Start Voice Entry',
            ),
            backgroundColor: _voiceController?.isListening == true
                ? Theme.of(context).colorScheme.error
                : null,
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'addItem',
            onPressed: () => _showAddItemDialog(context),
            icon: const Icon(Icons.add),
            label: Text(l10n.addItem),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceEntryCard() {
    if (_voiceLoading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: AppCard(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          ),
        ),
      );
    }

    final controller = _voiceController;
    if (controller == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  controller.isListening ? Icons.mic : Icons.mic_none,
                  color: controller.isListening
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  controller.isListening ? 'Listening...' : 'Voice Entry',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                if (controller.isProcessing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Speak: "Red Roses 200" or "200 Red Roses"'),
            if (controller.isListening ||
                controller.liveTranscript.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  controller.liveTranscript.isEmpty
                      ? 'Listening for item...'
                      : 'Heard: ${controller.liveTranscript}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            if (controller.recentlyAdded != null) ...[
              const SizedBox(height: 10),
              _VoicePurchaseAddedBanner(item: controller.recentlyAdded!),
            ],
            if (controller.pendingMatches.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Did you mean?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              RadioGroup<int>(
                groupValue: null,
                onChanged: (productId) {
                  if (productId == null) return;
                  final product = controller.pendingMatches.firstWhere(
                    (candidate) => candidate.id == productId,
                  );
                  controller.chooseProduct(product);
                },
                child: Column(
                  children: controller.pendingMatches
                      .map(
                        (product) => RadioListTile<int>(
                          value: product.id,
                          title: Text(product.name),
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(
      BuildContext context, String category, List items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            category,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        ...items.map((item) => _buildItemCard(context, item)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildItemCard(BuildContext context, PurchaseListItem item) {
    final rowKey = _itemKeys.putIfAbsent(item.id, () => GlobalKey());
    final isHighlighted = _highlightedItemId == item.id;

    return Container(
      key: rowKey,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isHighlighted
              ? Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.45)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: AppCard(
          child: Row(
            children: [
              Checkbox(
                value: item.purchased,
                onChanged: (_) =>
                    context.read<PurchaseProvider>().togglePurchased(item.id),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration:
                            item.purchased ? TextDecoration.lineThrough : null,
                        color: item.purchased ? Colors.grey : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('${item.quantity} ${item.unit}'),
                        if (item.supplier != null &&
                            item.supplier!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text('• ${item.supplier}'),
                        ],
                      ],
                    ),
                    if (item.remarks != null && item.remarks!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.remarks!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildPriorityBadge(item.priority),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditItemDialog(context, item);
                  } else if (value == 'delete') {
                    _showDeleteConfirmDialog(context, item);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    switch (priority.toLowerCase()) {
      case 'high':
        color = Colors.red;
        break;
      case 'low':
        color = Colors.green;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AddItemDialog(),
    );
  }

  void _showEditItemDialog(BuildContext context, PurchaseListItem item) {
    showDialog(
      context: context,
      builder: (context) => _EditItemDialog(item: item),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, PurchaseListItem item) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteItem),
        content: Text('${l10n.deleteItem} ${item.productName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final success =
                  await context.read<PurchaseProvider>().deleteItem(item.id);
              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.itemDeleted)),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.failedToDelete)),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => Consumer<PurchaseProvider>(
        builder: (context, provider, child) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.filters,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Text(l10n.filters,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: Text(l10n.all),
                      selected: provider.filterCategory == 'all',
                      onSelected: (_) => provider.setCategoryFilter('all'),
                    ),
                    ...provider.categories.map((cat) => FilterChip(
                          label: Text(cat),
                          selected: provider.filterCategory == cat,
                          onSelected: (_) => provider.setCategoryFilter(cat),
                        )),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          provider.clearFilters();
                          Navigator.pop(context);
                        },
                        child: Text(l10n.clearFilters),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.applyFilters),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _shareWhatsApp(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<PurchaseProvider>();
    final message = await provider.generateWhatsAppText();

    final waUri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(message)}',
    );

    if (await launchUrl(waUri, mode: LaunchMode.externalApplication)) {
      return;
    }

    final fallback = Uri.parse(
      'https://api.whatsapp.com/send?text=${Uri.encodeComponent(message)}',
    );
    if (await launchUrl(fallback, mode: LaunchMode.externalApplication)) {
      return;
    }

    if (!context.mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Unable to open WhatsApp on this device')),
    );
  }

  void _generateAutoSuggest(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.generateAutoSuggest),
        content: Text(l10n.autoSuggestDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context
                  .read<PurchaseProvider>()
                  .generateAutoSuggestedItems();
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.itemAdded)),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.failedToAdd)),
                  );
                }
              }
            },
            child: Text(l10n.generate),
          ),
        ],
      ),
    );
  }
}

class _VoicePurchaseAddedBanner extends StatelessWidget {
  const _VoicePurchaseAddedBanner({required this.item});

  final VoicePurchaseAddedItem item;

  @override
  Widget build(BuildContext context) {
    final headline = item.merged ? 'Updated' : 'Added';
    final delta =
        item.merged ? '+${item.spokenQuantity}' : '${item.spokenQuantity}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$headline\n${item.productName}\n$delta\nTotal: ${item.totalQuantity}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddItemDialog extends StatefulWidget {
  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedProductId;
  int _quantity = 1;
  String _unit = 'Piece';
  String _supplier = '';
  String _priority = 'Normal';
  String _remarks = '';
  final _remarksController = TextEditingController();
  final _remarksDictationController = VoiceDictationController(
    speechRecognition: SpeechRecognitionService(),
  );
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _remarksDictationController.bindController(_remarksController);
    _loadProducts();
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _remarksDictationController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final provider = context.read<PurchaseProvider>();
    final products = await provider.getInventoryTrackedProducts();
    setState(() {
      _products = products;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dialogWidth = screenWidth > 460 ? 420.0 : screenWidth - 48;
    if (_isLoading) {
      return const AlertDialog(
        content: Center(child: CircularProgressIndicator()),
      );
    }

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(l10n.addItem),
      content: SizedBox(
        width: dialogWidth,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  decoration:
                      const InputDecoration(labelText: 'Select Product'),
                  initialValue: _selectedProductId,
                  isExpanded: true,
                  items: _products.map((product) {
                    return DropdownMenuItem<int>(
                      value: product['id'] as int,
                      child: Text(
                        '${product['name']} (${product['category']})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  selectedItemBuilder: (context) {
                    return _products.map((product) {
                      return Text(
                        '${product['name']} (${product['category']})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    }).toList();
                  },
                  onChanged: (value) {
                    setState(() {
                      _selectedProductId = value;
                      if (value != null) {
                        final product =
                            _products.firstWhere((p) => p['id'] == value);
                        _unit = product['default_unit'] as String;
                      }
                    });
                  },
                  validator: (value) =>
                      value == null ? l10n.selectProduct : null,
                ),
                const SizedBox(height: 16),
                _buildQuantityStepper(l10n),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Enter Supplier (Optional)'),
                  onChanged: (value) => _supplier = value,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Priority'),
                  initialValue: _priority,
                  items: const [
                    DropdownMenuItem(value: 'High', child: Text('High')),
                    DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'Low', child: Text('Low')),
                  ],
                  onChanged: (value) => _priority = value!,
                ),
                const SizedBox(height: 16),
                VoiceDictationFieldHeader(
                  label: 'Enter Remarks (Optional)',
                  controller: _remarksDictationController,
                  compact: true,
                ),
                TextFormField(
                  controller: _remarksController,
                  maxLines: 3,
                  decoration: const InputDecoration(),
                  onChanged: (value) => _remarks = value,
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
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final success = await context.read<PurchaseProvider>().addItem(
                    productId: _selectedProductId!,
                    quantity: _quantity,
                    unit: _unit,
                    supplier: _supplier.isEmpty ? null : _supplier,
                    priority: _priority,
                    remarks: _remarks.isEmpty ? null : _remarks,
                  );
              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.itemAdded)),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.failedToAdd)),
                  );
                }
              }
            }
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }

  Widget _buildQuantityStepper(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.quantity),
        const SizedBox(height: 8),
        QuantityInputStepper(
          value: _quantity,
          min: 1,
          onChanged: (quantity) => setState(() => _quantity = quantity),
        ),
      ],
    );
  }
}

class _EditItemDialog extends StatefulWidget {
  final PurchaseListItem item;

  const _EditItemDialog({required this.item});

  @override
  State<_EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<_EditItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late int _quantity;
  late String _unit;
  late String _supplier;
  late String _priority;
  late String _remarks;
  late final TextEditingController _remarksController;
  late final VoiceDictationController _remarksDictationController;

  @override
  void initState() {
    super.initState();
    _quantity = widget.item.quantity;
    _unit = widget.item.unit;
    _supplier = widget.item.supplier ?? '';
    _priority = widget.item.priority;
    _remarks = widget.item.remarks ?? '';
    _remarksController = TextEditingController(text: _remarks);
    _remarksDictationController = VoiceDictationController(
      speechRecognition: SpeechRecognitionService(),
    );
    _remarksDictationController.bindController(_remarksController);
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _remarksDictationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.editItem),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.item.productName,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildQuantityStepper(l10n),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _supplier,
                decoration: const InputDecoration(
                    labelText: 'Enter Supplier (Optional)'),
                onChanged: (value) => _supplier = value,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Priority'),
                initialValue: _priority,
                items: const [
                  DropdownMenuItem(value: 'High', child: Text('High')),
                  DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                  DropdownMenuItem(value: 'Low', child: Text('Low')),
                ],
                onChanged: (value) => _priority = value!,
              ),
              const SizedBox(height: 16),
              VoiceDictationFieldHeader(
                label: 'Enter Remarks (Optional)',
                controller: _remarksDictationController,
                compact: true,
              ),
              TextFormField(
                controller: _remarksController,
                maxLines: 3,
                decoration: const InputDecoration(),
                onChanged: (value) => _remarks = value,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final success = await context.read<PurchaseProvider>().updateItem(
                  id: widget.item.id,
                  quantity: _quantity,
                  unit: _unit,
                  supplier: _supplier.isEmpty ? null : _supplier,
                  priority: _priority,
                  remarks: _remarks.isEmpty ? null : _remarks,
                );
            if (context.mounted) {
              Navigator.pop(context);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.itemUpdated)),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.failedToUpdate)),
                );
              }
            }
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }

  Widget _buildQuantityStepper(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.quantity),
        const SizedBox(height: 8),
        QuantityInputStepper(
          value: _quantity,
          min: 1,
          onChanged: (quantity) => setState(() => _quantity = quantity),
        ),
      ],
    );
  }
}
