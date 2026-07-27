import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/repositories/morning_purchase_list_repository.dart';
import '../providers/inventory_provider.dart';
import '../providers/morning_purchase_list_provider.dart';
import '../widgets/common_widgets.dart';
import '../widgets/quantity_input_stepper.dart';

class MorningPurchaseListScreen extends StatefulWidget {
  const MorningPurchaseListScreen({super.key});

  @override
  State<MorningPurchaseListScreen> createState() =>
      _MorningPurchaseListScreenState();
}

class _MorningPurchaseListScreenState extends State<MorningPurchaseListScreen> {
  final TextEditingController _searchController = TextEditingController();

  static const _statusFilters = ['All', 'Pending', 'Purchased'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MorningPurchaseListProvider>().loadInitial();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MorningPurchaseListProvider>();
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Purchase List'),
        actions: [
          IconButton(
            onPressed: provider.refresh,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () => _shareOnWhatsApp(provider),
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOrEditSheet(provider),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
      body: SafeArea(
        top: false,
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(provider, bottomInset),
      ),
    );
  }

  Widget _buildContent(
      MorningPurchaseListProvider provider, double bottomInset) {
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
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 90 + bottomInset),
      children: [
        _buildActions(provider),
        const SizedBox(height: 12),
        _buildSearchAndFilters(provider),
        const SizedBox(height: 12),
        _buildSummary(provider),
        const SizedBox(height: 12),
        if (provider.items.isEmpty)
          const AppCard(
            child: Text('No items in today\'s list.'),
          )
        else
          ..._buildGroupedItems(provider),
      ],
    );
  }

  Widget _buildActions(MorningPurchaseListProvider provider) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: provider.isBusy
                ? null
                : () async {
                    final added = await provider.generateTodayList();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          added == 0
                              ? 'Everything is already above minimum stock.'
                              : 'Added $added suggested items.',
                        ),
                      ),
                    );
                  },
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generate Today\'s Purchase List'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: provider.isBusy ? null : provider.clearPurchased,
                  icon: const Icon(Icons.cleaning_services),
                  label: const Text('Clear Purchased'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: provider.isBusy
                      ? null
                      : () => _openInventoryPurchaseFlow(provider),
                  icon: const Icon(Icons.inventory_2_rounded),
                  label: const Text('Create Purchase'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(MorningPurchaseListProvider provider) {
    return AppCard(
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) => provider.setSearchQuery(value),
            decoration: InputDecoration(
              hintText: 'Search product or category',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        provider.setSearchQuery('');
                        setState(() {});
                      },
                      icon: const Icon(Icons.clear),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusFilters
                  .map(
                    (status) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        selected: provider.statusFilter == status,
                        label: Text(status),
                        onSelected: (_) => provider.setStatusFilter(status),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: provider.categoryOptions
                  .map(
                    (category) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        selected: provider.categoryFilter == category,
                        label: Text(category),
                        onSelected: (_) => provider.setCategoryFilter(category),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(MorningPurchaseListProvider provider) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: _summaryTile('Total', '${provider.items.length}'),
          ),
          Expanded(
            child: _summaryTile('Pending', '${provider.pendingCount}'),
          ),
          Expanded(
            child: _summaryTile('Purchased', '${provider.purchasedCount}'),
          ),
        ],
      ),
    );
  }

  Widget _summaryTile(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label),
      ],
    );
  }

  List<Widget> _buildGroupedItems(MorningPurchaseListProvider provider) {
    final grouped = <String, List<MorningPurchaseListItem>>{};
    for (final category in MorningPurchaseListRepository.supportedGroups) {
      grouped[category] = <MorningPurchaseListItem>[];
    }

    for (final item in provider.items) {
      grouped
          .putIfAbsent(item.category, () => <MorningPurchaseListItem>[])
          .add(item);
    }

    final widgets = <Widget>[];
    for (final category in MorningPurchaseListRepository.supportedGroups) {
      final rows = grouped[category] ?? const <MorningPurchaseListItem>[];
      if (rows.isEmpty) {
        continue;
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            category,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );

      for (final item in rows) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildItemCard(provider, item),
          ),
        );
      }
    }

    return widgets;
  }

  Widget _buildItemCard(
    MorningPurchaseListProvider provider,
    MorningPurchaseListItem item,
  ) {
    final grey = item.purchased;
    return AppCard(
      backgroundColor: grey ? Colors.grey.shade100 : null,
      child: Opacity(
        opacity: grey ? 0.65 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: item.purchased,
                  onChanged: provider.isBusy
                      ? null
                      : (_) => provider.togglePurchased(item),
                ),
                Expanded(
                  child: Text(
                    item.productName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      _showAddOrEditSheet(provider, existing: item);
                    } else if (value == 'delete') {
                      await provider.deleteItem(item.id);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('${item.quantity} ${item.unit}'),
            const SizedBox(height: 4),
            Text('Stock ${item.currentQty} / Min ${item.minQty}'),
            if (item.supplier.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Supplier: ${item.supplier}'),
            ],
            if (item.remarks.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Remark: ${item.remarks}'),
            ],
            if (item.purchased && item.inventoryUpdated) ...[
              const SizedBox(height: 6),
              const Text(
                'Inventory updated',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showAddOrEditSheet(
    MorningPurchaseListProvider provider, {
    MorningPurchaseListItem? existing,
  }) async {
    final products = provider.trackedProducts;
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No inventory-tracked products found.')),
      );
      return;
    }

    MarketProductRecord selected = products.first;
    if (existing != null) {
      final match = products.where((p) => p.productId == existing.productId);
      if (match.isNotEmpty) {
        selected = match.first;
      }
    }

    final qtyController = TextEditingController(
      text: existing?.quantity.toString() ??
          (selected.suggestedQty > 0 ? selected.suggestedQty.toString() : '1'),
    );
    final unitController =
        TextEditingController(text: existing?.unit ?? selected.unit);
    final supplierController =
        TextEditingController(text: existing?.supplier ?? selected.supplier);
    final remarkController =
        TextEditingController(text: existing?.remarks ?? '');

    int quantity = int.tryParse(qtyController.text) ?? 1;

    Future<void> save(StateSetter setLocalState) async {
      if (quantity <= 0) {
        setLocalState(() {
          quantity = 1;
          qtyController.text = '1';
        });
      }

      if (existing == null) {
        await provider.addOrUpdateItem(
          productId: selected.productId,
          quantity: quantity,
          unit: unitController.text.trim(),
          supplier: supplierController.text.trim(),
          remarks: remarkController.text.trim(),
        );
      } else {
        await provider.editItem(
          id: existing.id,
          quantity: quantity,
          unit: unitController.text.trim(),
          supplier: supplierController.text.trim(),
          remarks: remarkController.text.trim(),
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
    }

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      existing == null ? 'Add Item' : 'Edit Item',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: selected.productId,
                      decoration: const InputDecoration(labelText: 'Product'),
                      items: products
                          .map(
                            (p) => DropdownMenuItem<int>(
                              value: p.productId,
                              child: Text('${p.name} (${p.category})'),
                            ),
                          )
                          .toList(),
                      onChanged: existing != null
                          ? null
                          : (value) {
                              final next = products.firstWhere(
                                (p) => p.productId == value,
                                orElse: () => selected,
                              );
                              setLocalState(() {
                                selected = next;
                                if ((int.tryParse(qtyController.text) ?? 0) <=
                                    0) {
                                  quantity = next.suggestedQty > 0
                                      ? next.suggestedQty
                                      : 1;
                                  qtyController.text = '$quantity';
                                }
                                if (unitController.text.trim().isEmpty) {
                                  unitController.text = next.unit;
                                }
                                if (supplierController.text.trim().isEmpty) {
                                  supplierController.text = next.supplier;
                                }
                              });
                            },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Quantity'),
                        const Spacer(),
                        QuantityInputStepper(
                          value: quantity,
                          min: 1,
                          onChanged: (value) {
                            setLocalState(() {
                              quantity = value;
                              qtyController.text = '$value';
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: unitController,
                      decoration: const InputDecoration(labelText: 'Unit'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: supplierController,
                      decoration: const InputDecoration(
                          labelText: 'Supplier (optional)'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: remarkController,
                      decoration: const InputDecoration(labelText: 'Remark'),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed:
                          provider.isBusy ? null : () => save(setLocalState),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    qtyController.dispose();
    unitController.dispose();
    supplierController.dispose();
    remarkController.dispose();
  }

  Future<void> _shareOnWhatsApp(MorningPurchaseListProvider provider) async {
    final text = await provider.whatsappText();
    if (text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pending items to share.')),
      );
      return;
    }

    final uri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(text)}',
    );

    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to open WhatsApp.')),
    );
  }

  Future<void> _openInventoryPurchaseFlow(
    MorningPurchaseListProvider provider,
  ) async {
    final pending = await provider.purchasedForInventoryUpdate();
    if (!mounted) return;

    if (pending.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No purchased items pending for inventory update.')),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) {
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Inventory Purchase',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                  'Purchased items are prefilled with product and quantity.'),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: pending.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = pending[index];
                    return AppCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text('${item.quantity} ${item.unit}'),
                              ],
                            ),
                          ),
                          FilledButton.tonal(
                            onPressed: () =>
                                _openSingleInventoryEntry(provider, item),
                            child: const Text('Update'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openSingleInventoryEntry(
    MorningPurchaseListProvider provider,
    MorningPurchaseListItem item,
  ) async {
    final supplierController = TextEditingController(text: item.supplier);
    final priceController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Purchase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child:
                  Text('${item.productName} • ${item.quantity} ${item.unit}'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Purchase Price'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: supplierController,
              decoration: const InputDecoration(labelText: 'Supplier'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Update Inventory'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      supplierController.dispose();
      priceController.dispose();
      return;
    }

    final priceValue = double.tryParse(priceController.text.trim()) ?? 0;
    if (priceValue <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter valid purchase price.')),
        );
      }
      supplierController.dispose();
      priceController.dispose();
      return;
    }

    if (!mounted) return;

    try {
      await context.read<InventoryProvider>().purchase(
            productId: item.productId,
            quantity: item.quantity,
            purchasePricePaise: (priceValue * 100).round(),
            supplier: supplierController.text.trim(),
            note: 'Morning Market List',
          );

      await provider.markInventoryUpdated(item.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Inventory updated for ${item.productName}.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to update inventory: $e')),
        );
      }
    } finally {
      supplierController.dispose();
      priceController.dispose();
    }
  }
}
