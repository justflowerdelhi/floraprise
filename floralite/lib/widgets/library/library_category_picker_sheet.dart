import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/library_models.dart';
import '../../providers/library_provider.dart';

class LibraryCategoryPickerSheet extends StatefulWidget {
  const LibraryCategoryPickerSheet({super.key});

  static Future<LibraryCategoryTree?> show(BuildContext context) {
    return showModalBottomSheet<LibraryCategoryTree>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const LibraryCategoryPickerSheet(),
    );
  }

  @override
  State<LibraryCategoryPickerSheet> createState() =>
      _LibraryCategoryPickerSheetState();
}

class _LibraryCategoryPickerSheetState
    extends State<LibraryCategoryPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _filterQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<LibraryProvider>();
      if (provider.categoryTree.isEmpty) {
        provider.init();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LibraryCategoryTree> _filterTree(List<LibraryCategoryTree> tree) {
    if (_filterQuery.trim().isEmpty) return tree;
    final query = _filterQuery.toLowerCase();

    List<LibraryCategoryTree> results = [];
    for (final node in tree) {
      final nameMatches = node.name.toLowerCase().contains(query);
      final matchingChildren = node.children
          .where((c) => c.name.toLowerCase().contains(query))
          .toList();

      if (nameMatches || matchingChildren.isNotEmpty) {
        results.add(LibraryCategoryTree(
          id: node.id,
          name: node.name,
          slug: node.slug,
          description: node.description,
          imageUrl: node.imageUrl,
          iconKey: node.iconKey,
          sortOrder: node.sortOrder,
          isActive: node.isActive,
          productCount: node.productCount,
          children: matchingChildren.isNotEmpty ? matchingChildren : node.children,
        ));
      }
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<LibraryProvider>();
    final categories = _filterTree(provider.categoryTree);

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Color(0xFF2E7D32),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Import from Library',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Select a standard category to add to your catalogue',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search library categories...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _filterQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _filterQuery = '');
                          },
                        )
                      : null,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                ),
                onChanged: (val) => setState(() => _filterQuery = val),
              ),
            ),
            Expanded(
              child: provider.isLoading && provider.categoryTree.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : categories.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.category_outlined,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _filterQuery.isNotEmpty
                                      ? 'No matching library categories.'
                                      : 'No library categories found.',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final cat = categories[index];
                            return _buildCategoryNode(context, cat);
                          },
                        ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryNode(BuildContext context, LibraryCategoryTree cat) {
    if (cat.children.isNotEmpty) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: ExpansionTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFE8F5E9),
            child: Icon(Icons.folder_rounded, color: Color(0xFF2E7D32)),
          ),
          title: Text(
            cat.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${cat.children.length} subcategories • ${cat.productCount} products',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          trailing: OutlinedButton.icon(
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Import'),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: const Color(0xFF2E7D32),
              side: const BorderSide(color: Color(0xFF2E7D32)),
            ),
            onPressed: () => Navigator.pop(context, cat),
          ),
          children: cat.children.map((child) {
            return ListTile(
              contentPadding: const EdgeInsets.only(left: 32, right: 16),
              leading: const Icon(Icons.category_rounded, size: 20, color: Color(0xFF2E7D32)),
              title: Text(child.name),
              subtitle: Text(
                '${child.productCount} products',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              trailing: FilledButton.tonalIcon(
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Import'),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => Navigator.pop(context, child),
              ),
            );
          }).toList(),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE8F5E9),
          child: Icon(Icons.category_rounded, color: Color(0xFF2E7D32)),
        ),
        title: Text(
          cat.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${cat.productCount} products',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: FilledButton.icon(
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Import'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            visualDensity: VisualDensity.compact,
          ),
          onPressed: () => Navigator.pop(context, cat),
        ),
      ),
    );
  }
}
