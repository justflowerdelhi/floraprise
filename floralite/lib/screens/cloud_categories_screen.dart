import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repositories/cloud_product_repository.dart';
import '../providers/cloud_product_provider.dart';

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
    // The dialog owns its TextEditingController's whole lifecycle (see
    // _CategoryNameDialog below). Disposing it here instead, right after
    // showDialog resolves, would race the dialog's still-running close
    // transition: the TextField stays mounted for a few more frames while
    // it fades out, and rebuilding it against an already-disposed
    // controller throws "A TextEditingController was used after being
    // disposed", which cascades into the framework's
    // '_dependents.isEmpty' assertion.
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _CategoryNameDialog(initialName: category?.name ?? ''),
    );
    if (!mounted || name == null || name.isEmpty) return;
    try {
      if (category == null) {
        await provider.createCategory(name);
      } else {
        await provider.updateCategory(category.id, name);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CloudProductProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Categories'),
        actions: [
          IconButton(onPressed: provider.isLoading ? null : provider.load, icon: const Icon(Icons.refresh), tooltip: 'Refresh'),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _edit(), child: const Icon(Icons.add)),
      body: provider.isLoading && provider.categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.categories.length,
              itemBuilder: (_, index) {
                final category = provider.categories[index];
                return Card(
                  child: ListTile(
                    title: Text(category.name),
                    subtitle: Text(category.isActive ? 'Active' : 'Inactive'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                        IconButton(onPressed: () => _edit(category: category), icon: const Icon(Icons.edit), tooltip: 'Edit'),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _CategoryNameDialog extends StatefulWidget {
  const _CategoryNameDialog({required this.initialName});

  final String initialName;

  @override
  State<_CategoryNameDialog> createState() => _CategoryNameDialogState();
}

class _CategoryNameDialogState extends State<_CategoryNameDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    // Owned and disposed entirely within this dialog's own State lifecycle,
    // so Flutter only tears it down once this Element is actually unmounted
    // (after the dialog's close transition finishes) rather than the moment
    // the parent screen's showDialog() future resolves.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialName.isEmpty ? 'Add Cloud Category' : 'Edit Cloud Category'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Category name'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
