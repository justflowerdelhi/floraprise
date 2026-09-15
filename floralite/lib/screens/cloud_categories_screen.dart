import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repositories/cloud_product_repository.dart';
import '../data/repositories/product_repository.dart';
import '../providers/cloud_product_provider.dart';
import '../widgets/app_header.dart';
import '../widgets/floraprise_page_header.dart';

class CloudCategoriesScreen extends StatefulWidget {
  const CloudCategoriesScreen({super.key});

  @override
  State<CloudCategoriesScreen> createState() => _CloudCategoriesScreenState();
}

class _CloudCategoriesScreenState extends State<CloudCategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CloudProductProvider>().load();
    });
  }

  Future<void> _edit({CloudCategory? category}) async {
    final provider = context.read<CloudProductProvider>();
    final result = await showDialog<CloudCategoryInput>(
      context: context,
      builder: (_) => _CloudCategoryEditorDialog(category: category),
    );
    if (!mounted || result == null) return;
    try {
      if (category == null) {
        await provider.createCategory(result);
      } else {
        await provider.updateCategory(category.id, result);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _delete(CloudCategory category) async {
    if (category.productCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This category is used by ${category.productCount} product(s) and cannot be deleted.',
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await context.read<CloudProductProvider>().deleteCategory(category.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Category "${category.name}" deleted.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete category: $error')),
      );
    }
  }

  Widget _buildCategoryTile(
    BuildContext context,
    CloudCategory category,
    CloudProductProvider provider,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: category.isActive
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.grey.shade200,
              child: Icon(
                Icons.category_rounded,
                color: category.isActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Default unit: ${category.effectiveDefaultUnit}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (category.isPerishable) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Perishable',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        category.productCount == 1
                            ? '1 product'
                            : '${category.productCount} products',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Switch(
              value: category.isActive,
              onChanged: (value) async {
                try {
                  await provider.setCategoryActive(category.id, value);
                } catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error.toString())),
                  );
                }
              },
            ),
            IconButton(
              onPressed: () => _edit(category: category),
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
            ),
            IconButton(
              onPressed: () => _delete(category),
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CloudProductProvider>();
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;

    Widget content;
    if (provider.isLoading && provider.categories.isEmpty) {
      content = const Center(child: CircularProgressIndicator());
    } else if (isDesktop) {
      content = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 460,
              mainAxisExtent: 110,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: provider.categories.length,
            itemBuilder: (ctx, index) =>
                _buildCategoryTile(ctx, provider.categories[index], provider),
          ),
        ),
      );
    } else {
      content = ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: provider.categories.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, index) =>
            _buildCategoryTile(ctx, provider.categories[index], provider),
      );
    }

    return Scaffold(
      appBar: AppHeader(
        title: isDesktop ? null : 'Categories',
        actions: [
          IconButton(
            onPressed: provider.isLoading ? null : provider.load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton(
              onPressed: () => _edit(),
              child: const Icon(Icons.add),
            ),
      body: Column(
        children: [
          FloraprisePageHeader(
            title: 'Categories',
            subtitle: 'Organize your catalogue for faster daily work',
            icon: Icons.category_rounded,
            actions: [
              FloraprisePageHeaderAction(
                label: 'Add Category',
                icon: Icons.add_rounded,
                primary: true,
                onPressed: () => _edit(),
              ),
            ],
          ),
          Expanded(child: content),
        ],
      ),
    );
  }
}

class _CloudCategoryEditorDialog extends StatefulWidget {
  const _CloudCategoryEditorDialog({this.category});

  final CloudCategory? category;

  @override
  State<_CloudCategoryEditorDialog> createState() => _CloudCategoryEditorDialogState();
}

class _CloudCategoryEditorDialogState extends State<_CloudCategoryEditorDialog> {
  late final TextEditingController _controller;
  late String _selectedUnit;
  late bool _isPerishable;
  late bool _trackBatchByDefault;
  bool _batchManuallyChanged = false;

  @override
  void initState() {
    super.initState();
    final cat = widget.category;
    _controller = TextEditingController(text: cat?.name ?? '');
    _selectedUnit = _resolveUnit(cat?.defaultUnit ?? (cat != null ? cat.effectiveDefaultUnit : 'Stem'));
    _isPerishable = cat?.isPerishable ?? true;
    _trackBatchByDefault = cat?.trackBatchByDefault ?? true;
  }

  String _resolveUnit(String? unit) {
    final trimmed = unit?.trim();
    if (trimmed != null && ProductRepository.allowedUnits.contains(trimmed)) {
      return trimmed;
    }
    return 'Piece';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.category == null;
    return AlertDialog(
      title: Text(isNew ? 'Add Cloud Category' : 'Edit Cloud Category'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _controller,
                autofocus: isNew,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Category name',
                  hintText: 'e.g. Fresh Flowers, Fillers',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedUnit,
                decoration: const InputDecoration(labelText: 'Default Unit'),
                items: ProductRepository.allowedUnits
                    .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedUnit = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Perishable items'),
                subtitle: const Text('Items spoil or have limited shelf life'),
                value: _isPerishable,
                onChanged: (value) {
                  setState(() {
                    _isPerishable = value;
                    if (!_batchManuallyChanged) {
                      _trackBatchByDefault = value;
                    }
                  });
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Track batch by default'),
                subtitle: const Text('Require batch tracking when receiving inventory'),
                value: _trackBatchByDefault,
                onChanged: (value) {
                  setState(() {
                    _trackBatchByDefault = value;
                    _batchManuallyChanged = true;
                  });
                },
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
          onPressed: () {
            final name = _controller.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(
              context,
              CloudCategoryInput(
                name: name,
                defaultUnit: _selectedUnit,
                isPerishable: _isPerishable,
                trackBatchByDefault: _trackBatchByDefault,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
