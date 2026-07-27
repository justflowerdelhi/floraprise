import 'package:flutter/material.dart';

import '../data/repositories/production_repository.dart';
import '../widgets/common_widgets.dart';
import 'bouquet_builder_screen.dart';

class BouquetProductionEntryScreen extends StatefulWidget {
  const BouquetProductionEntryScreen({super.key});

  @override
  State<BouquetProductionEntryScreen> createState() =>
      _BouquetProductionEntryScreenState();
}

class _BouquetProductionEntryScreenState
    extends State<BouquetProductionEntryScreen> {
  final ProductionRepository _repository = ProductionRepository();
  bool _isLoading = false;

  Future<void> _selectExistingRecipe() async {
    setState(() => _isLoading = true);
    try {
      final products = await _repository.listFinishedProducts();
      if (!mounted) return;
      final recipes = products.where((p) => p.hasRecipe).toList();
      if (recipes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No saved recipes yet. Design a new bouquet.')),
        );
        _openNewBouquet();
        return;
      }
      final selected = await showModalBottomSheet<ProductionProduct>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => _RecipePicker(products: recipes),
      );
      if (selected == null || !mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BouquetBuilderScreen(existingProductId: selected.id),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openNewBouquet() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const BouquetBuilderScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ready Bouquet Production'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'What do you want to make?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              AppCard(
                onTap: _openNewBouquet,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.add_circle_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New Bouquet',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Design a fresh bouquet from scratch',
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                onTap: _isLoading ? null : _selectExistingRecipe,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.menu_book_outlined,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Existing Recipe',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Start from a saved recipe and customise',
                            ),
                          ],
                        ),
                      ),
                      if (_isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipePicker extends StatelessWidget {
  final List<ProductionProduct> products;

  const _RecipePicker({required this.products});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Select Recipe',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: products.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final product = products[index];
                return ListTile(
                  title: Text(product.name),
                  subtitle: Text('Stock: ${product.currentQty} ${product.unit}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(context, product),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
