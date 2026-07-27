import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/repositories/ready_bouquet_repository.dart';
import '../widgets/common_widgets.dart';
import 'expire_bouquet_screen.dart';
import 'refresh_bouquet_screen.dart';

class ReadyBouquetDetailScreen extends StatefulWidget {
  const ReadyBouquetDetailScreen({super.key, required this.productId});

  final int productId;

  @override
  State<ReadyBouquetDetailScreen> createState() =>
      _ReadyBouquetDetailScreenState();
}

class _ReadyBouquetDetailScreenState extends State<ReadyBouquetDetailScreen> {
  final ReadyBouquetRepository _repository = ReadyBouquetRepository();
  List<ReadyBouquetBatch> _batches = const [];
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
      final batches = await _repository.listBatchesForProduct(widget.productId);
      if (!mounted) return;
      setState(() {
        _batches = batches;
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
    final productName = _batches.isNotEmpty ? _batches.first.productName : '';
    final totalStock = _batches.fold(0, (sum, b) => sum + b.remainingQuantity);

    return Scaffold(
      appBar: AppBar(
        title: Text(productName.isEmpty ? 'Ready Bouquets' : productName),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: SafeArea(
        child: _buildBody(totalStock),
      ),
    );
  }

  Widget _buildBody(int totalStock) {
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
    if (_batches.isEmpty) {
      return const Center(child: Text('No ready bouquets for this product.'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Stock',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '$totalStock ${_batches.first.unit}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Batches',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ..._batches.map((batch) => _BatchCard(
                batch: batch,
                onRefresh: () => _openRefresh(batch),
                onExpire: () => _openExpire(batch),
              )),
        ],
      ),
    );
  }

  Future<void> _openRefresh(ReadyBouquetBatch batch) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RefreshBouquetScreen(batch: batch),
      ),
    );
    _load();
  }

  Future<void> _openExpire(ReadyBouquetBatch batch) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExpireBouquetScreen(batch: batch),
      ),
    );
    _load();
  }
}

class _BatchCard extends StatelessWidget {
  const _BatchCard({
    required this.batch,
    required this.onRefresh,
    required this.onExpire,
  });

  final ReadyBouquetBatch batch;
  final VoidCallback onRefresh;
  final VoidCallback onExpire;

  @override
  Widget build(BuildContext context) {
    final ageDays = DateTime.now()
        .difference(batch.lastRefreshAt ?? batch.producedAt)
        .inDays;
    final color = _statusColor(batch.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Produced ${DateFormat.yMMMd().format(batch.producedAt)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color),
                  ),
                  child: Text(
                    _statusLabel(batch.status),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Remaining: ${batch.remainingQuantity} ${batch.unit}'),
            Text('Age: $ageDays day${ageDays == 1 ? '' : 's'}'),
            if (batch.lastRefreshAt != null)
              Text(
                'Last refresh: ${DateFormat.yMMMd().format(batch.lastRefreshAt!)}',
              ),
            Text(
              'Expires: ${DateFormat.yMMMd().format(batch.expiryAt)}',
              style: TextStyle(
                color: batch.status == ReadyBouquetStatus.expired
                    ? Colors.red
                    : null,
                fontWeight: batch.status == ReadyBouquetStatus.expired
                    ? FontWeight.bold
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.autorenew),
                    label: const Text('Refresh'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onExpire,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Expire'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(ReadyBouquetStatus status) {
    return switch (status) {
      ReadyBouquetStatus.fresh => 'Fresh',
      ReadyBouquetStatus.needsRefresh => 'Needs Refresh',
      ReadyBouquetStatus.nearExpiry => 'Near Expiry',
      ReadyBouquetStatus.expired => 'Expired',
    };
  }

  Color _statusColor(ReadyBouquetStatus status) {
    return switch (status) {
      ReadyBouquetStatus.fresh => Colors.green,
      ReadyBouquetStatus.needsRefresh => Colors.amber.shade700,
      ReadyBouquetStatus.nearExpiry => Colors.orange,
      ReadyBouquetStatus.expired => Colors.red,
    };
  }
}
