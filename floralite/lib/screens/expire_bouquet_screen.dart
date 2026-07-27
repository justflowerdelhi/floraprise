import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repositories/ready_bouquet_repository.dart';
import '../services/business_data_event_bus.dart';
import '../widgets/common_widgets.dart';
import '../widgets/quantity_input_stepper.dart';

class ExpireBouquetScreen extends StatefulWidget {
  const ExpireBouquetScreen({super.key, required this.batch});

  final ReadyBouquetBatch batch;

  @override
  State<ExpireBouquetScreen> createState() => _ExpireBouquetScreenState();
}

class _ExpireBouquetScreenState extends State<ExpireBouquetScreen> {
  final ReadyBouquetRepository _repository = ReadyBouquetRepository();
  late int _quantity;
  String _reason = 'Wilted Flowers';
  bool _isSaving = false;

  final List<String> _reasons = const [
    'Wilted Flowers',
    'Display Too Old',
    'Customer Damage',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _quantity = widget.batch.remainingQuantity;
  }

  Future<void> _expire() async {
    if (_quantity <= 0) {
      _showMessage('Enter a valid quantity');
      return;
    }
    if (_quantity > widget.batch.remainingQuantity) {
      _showMessage('Cannot expire more than ${widget.batch.remainingQuantity}');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _repository.expireBouquet(
        batchId: widget.batch.id,
        quantity: _quantity,
        reason: _reason,
      );
      if (!mounted) return;
      context.read<BusinessDataEventBus>().publish(
            source: BusinessDataChangeSource.inventory,
            message: '${widget.batch.productName} expired',
          );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString());
      setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final batch = widget.batch;
    return Scaffold(
      appBar: AppBar(title: const Text('Expire Bouquet')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    batch.productName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                      'Available to expire: ${batch.remainingQuantity} ${batch.unit}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quantity to Expire',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  QuantityInputStepper(
                    value: _quantity,
                    min: 1,
                    max: widget.batch.remainingQuantity,
                    onChanged: (value) => setState(() => _quantity = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reason',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: DropdownButton<String>(
                      value: _reason,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      items: _reasons
                          .map((reason) => DropdownMenuItem(
                                value: reason,
                                child: Text(reason),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _reason = value);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ? null : _expire,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_forever),
              label: const Text('Mark Expired'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
