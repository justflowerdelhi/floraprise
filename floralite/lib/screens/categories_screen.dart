import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repositories/category_repository.dart';
import '../data/repositories/product_repository.dart';
import '../providers/category_provider.dart';
import '../providers/storage_mode_provider.dart';
import 'cloud_categories_screen.dart';
import '../widgets/common_widgets.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CategoryProvider>().loadCategories();
      }
    });
  }

  Future<void> _showCategoryEditor({ProductCategoryRecord? category}) async {
    final result = await showDialog<_CategoryFormResult>(
      context: context,
      builder: (context) => _CategoryEditorDialog(
        category: category,
      ),
    );
    if (result == null || !mounted) return;

    try {
      final provider = context.read<CategoryProvider>();
      if (category == null) {
        await provider.createCategory(
          name: result.name,
          defaultUnit: result.defaultUnit,
        );
      } else {
        await provider.updateCategory(
          id: category.id,
          name: result.name,
          defaultUnit: result.defaultUnit,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save category: $e')),
      );
    }
  }

  Future<void> _deleteCategory(ProductCategoryRecord category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Delete ${category.name}?'),
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

    final deleted = await context
        .read<CategoryProvider>()
        .deleteCategoryIfUnused(category.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted
              ? 'Category deleted.'
              : 'This category is used by products and cannot be deleted.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (context.watch<StorageModeProvider?>()?.isCloud ?? false) {
      return const CloudCategoriesScreen();
    }

    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final provider = context.watch<CategoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => provider.loadCategories(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _buildBody(provider, bottomInset),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
    );
  }

  Widget _buildBody(CategoryProvider provider, double bottomInset) {
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
              Text(provider.error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => provider.loadCategories(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.categories.isEmpty) {
      return const Center(child: Text('No categories yet.'));
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 96 + bottomInset),
      itemBuilder: (context, index) {
        final category = provider.categories[index];
        return AppCard(
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
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Default unit: ${category.defaultUnit}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              Switch(
                value: category.isActive,
                onChanged: (value) => provider.setCategoryActive(
                  id: category.id,
                  isActive: value,
                ),
              ),
              PopupMenuButton<_CategoryAction>(
                onSelected: (action) {
                  switch (action) {
                    case _CategoryAction.edit:
                      _showCategoryEditor(category: category);
                    case _CategoryAction.delete:
                      _deleteCategory(category);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _CategoryAction.edit,
                    child: Text('Edit'),
                  ),
                  PopupMenuItem(
                    value: _CategoryAction.delete,
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemCount: provider.categories.length,
    );
  }
}

class _CategoryFormResult {
  const _CategoryFormResult({required this.name, required this.defaultUnit});

  final String name;
  final String defaultUnit;
}

class _CategoryEditorDialog extends StatefulWidget {
  const _CategoryEditorDialog({this.category});

  final ProductCategoryRecord? category;

  @override
  State<_CategoryEditorDialog> createState() => _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends State<_CategoryEditorDialog> {
  late final TextEditingController _nameController;
  late String _selectedUnit;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedUnit = _dropdownUnitValue(widget.category?.defaultUnit);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    return AlertDialog(
      title: Text(category == null ? 'Add Category' : 'Edit Category'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Category Name'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedUnit,
            decoration: const InputDecoration(labelText: 'Default Unit'),
            items: ProductRepository.allowedUnits
                .map(
                  (unit) => DropdownMenuItem(
                    value: unit,
                    child: Text(unit),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedUnit = value);
            },
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
            if (name.isEmpty) return;
            Navigator.pop(
              context,
              _CategoryFormResult(name: name, defaultUnit: _selectedUnit),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  String _dropdownUnitValue(String? value) {
    final trimmed = value?.trim() ?? '';
    if (ProductRepository.allowedUnits.contains(trimmed)) {
      return trimmed;
    }
    return 'Piece';
  }
}

enum _CategoryAction { edit, delete }
