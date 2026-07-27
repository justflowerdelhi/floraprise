import 'package:flutter/material.dart';

import '../data/repositories/ready_bouquet_repository.dart';
import '../widgets/common_widgets.dart';
import 'ready_bouquet_detail_screen.dart';

class ReadyBouquetInventoryScreen extends StatefulWidget {
  const ReadyBouquetInventoryScreen({super.key});

  @override
  State<ReadyBouquetInventoryScreen> createState() =>
      _ReadyBouquetInventoryScreenState();
}

class _ReadyBouquetInventoryScreenState
    extends State<ReadyBouquetInventoryScreen> {
  final ReadyBouquetRepository _repository = ReadyBouquetRepository();
  List<ReadyBouquetSummary> _items = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await _repository.listReadyBouquets();
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ready Bouquets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_florist_outlined,
                  size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No ready bouquets in stock.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text('Produce bouquets from a recipe to see them here.'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/production'),
                icon: const Icon(Icons.precision_manufacturing_outlined),
                label: const Text('Produce Bouquet'),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              onTap: () => _openDetail(item),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.productName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      _StatusChip(status: item.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Stock: ${item.currentStock} ${item.unit}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Age: ${item.ageDays} day${item.ageDays == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openDetail(ReadyBouquetSummary item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReadyBouquetDetailScreen(productId: item.productId),
      ),
    );
    _load();
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ReadyBouquetStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ReadyBouquetStatus.fresh => ('Fresh', Colors.green),
      ReadyBouquetStatus.needsRefresh => ('Needs Refresh', Colors.amber.shade700),
      ReadyBouquetStatus.nearExpiry => ('Near Expiry', Colors.orange),
      ReadyBouquetStatus.expired => ('Expired', Colors.red),
    };
    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.12),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      side: BorderSide(color: color),
      padding: EdgeInsets.zero,
    );
  }
}
