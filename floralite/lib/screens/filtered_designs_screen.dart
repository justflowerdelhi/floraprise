import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/design.dart';
import '../providers/design_provider.dart';
import '../widgets/common_widgets.dart';

class FilteredDesignsScreen extends StatefulWidget {
  final String filterType;
  final String filterValue;
  final String title;

  const FilteredDesignsScreen({
    super.key,
    required this.filterType,
    required this.filterValue,
    required this.title,
  });

  @override
  State<FilteredDesignsScreen> createState() => _FilteredDesignsScreenState();
}

class _FilteredDesignsScreenState extends State<FilteredDesignsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<DesignProvider>();
      switch (widget.filterType) {
        case 'flower':
          await provider.setFilters(flower: widget.filterValue);
          break;
        case 'occasion':
          await provider.setFilters(occasion: widget.filterValue);
          break;
        case 'color':
          await provider.setFilters(color: widget.filterValue);
          break;
        default:
          await provider.loadDesigns();
      }
    });
  }

  @override
  void dispose() {
    context.read<DesignProvider>().clearFilters();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        top: false,
        child: Consumer<DesignProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.designs.isEmpty) {
              return const Center(child: Text('No designs found'));
            }

            return GridView.builder(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 190,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.92,
              ),
              itemCount: provider.designs.length,
              itemBuilder: (context, index) {
                final design = provider.designs[index];
                return _DesignCard(design: design);
              },
            );
          },
        ),
      ),
    );
  }
}

class _DesignCard extends StatelessWidget {
  const _DesignCard({required this.design});

  final DesignRecord design;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 7,
            child: Container(
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
                    child: design.imagePath != null &&
                            design.imagePath!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: Image.file(
                              File(design.imagePath!),
                              fit: BoxFit.cover,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: design.isReady
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        design.isReady ? 'Ready' : 'Needs Review',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    design.bouquetId,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    design.sellingPriceLabel.isEmpty
                        ? '₹0'
                        : design.sellingPriceLabel,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
