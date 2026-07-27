import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../data/repositories/product_repository.dart';
import '../data/repositories/ready_bouquet_repository.dart';
import '../services/business_data_event_bus.dart';
import '../widgets/common_widgets.dart';
import '../widgets/product_picker_sheet.dart';
import '../widgets/quantity_input_stepper.dart';

class RefreshBouquetScreen extends StatefulWidget {
  const RefreshBouquetScreen({super.key, required this.batch});

  final ReadyBouquetBatch batch;

  @override
  State<RefreshBouquetScreen> createState() => _RefreshBouquetScreenState();
}

class _RefreshBouquetScreenState extends State<RefreshBouquetScreen> {
  final ReadyBouquetRepository _repository = ReadyBouquetRepository();
  int _quantity = 1;
  String _action = 'replace';
  bool _returnToInventory = true;
  ProductRecord? _selectedProduct;
  bool _isSaving = false;

  final List<(String value, String label, IconData icon)> _actions = const [
    ('replace', 'Replace', Icons.swap_horiz),
    ('add', 'Add', Icons.add),
    ('remove', 'Remove', Icons.remove),
  ];

  Future<void> _pickProduct() async {
    final product = await showProductPickerSheet(context);
    if (product == null || !mounted) return;
    setState(() => _selectedProduct = product);
  }

  Future<void> _save() async {
    final product = _selectedProduct;
    if (product == null) {
      _showMessage('Select a component');
      return;
    }
    if (_quantity <= 0) {
      _showMessage('Enter a valid quantity');
      return;
    }

    setState(() => _isSaving = true);
    try {
      switch (_action) {
        case 'replace':
          await _repository.refreshReplaceComponent(
            batchId: widget.batch.id,
            productId: product.id,
            quantity: _quantity,
          );
        case 'add':
          await _repository.refreshAddComponent(
            batchId: widget.batch.id,
            productId: product.id,
            quantity: _quantity,
          );
        case 'remove':
          await _repository.refreshRemoveComponent(
            batchId: widget.batch.id,
            productId: product.id,
            quantity: _quantity,
            returnToInventory: _returnToInventory,
          );
      }
      if (!mounted) return;
      context.read<BusinessDataEventBus>().publish(
            source: BusinessDataChangeSource.inventory,
            message: '${widget.batch.productName} refreshed',
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
      appBar: AppBar(title: const Text('Refresh Bouquet')),
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
                  Text('Batch stock: ${batch.remainingQuantity} ${batch.unit}'),
                  Text(
                    'Produced: ${_formatDate(batch.producedAt)}',
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
                    'Action',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: _actions
                        .map((a) => ButtonSegment(
                              value: a.$1,
                              label: Text(a.$2),
                              icon: Icon(a.$3),
                            ))
                        .toList(),
                    selected: {_action},
                    onSelectionChanged: (selected) {
                      setState(() => _action = selected.first);
                    },
                    multiSelectionEnabled: false,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _actionDescription,
                    style: Theme.of(context).textTheme.bodySmall,
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
                    'Component',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.inventory_2_outlined),
                    title: Text(_selectedProduct?.name ?? 'Select Component'),
                    subtitle: _selectedProduct == null
                        ? const Text('Tap to choose a raw material')
                        : Text('ID: ${_selectedProduct!.id}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _pickProduct,
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
                    'Quantity',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  QuantityInputStepper(
                    value: _quantity,
                    min: 1,
                    onChanged: (value) => setState(() => _quantity = value),
                  ),
                ],
              ),
            ),
            if (_action == 'remove') ...[
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Disposition',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: true,
                          label: Text('Return to Inventory'),
                          icon: Icon(Icons.keyboard_return),
                        ),
                        ButtonSegment(
                          value: false,
                          label: Text('Move to Wastage'),
                          icon: Icon(Icons.delete_outline),
                        ),
                      ],
                      selected: {_returnToInventory},
                      onSelectionChanged: (selected) {
                        if (selected.isNotEmpty) {
                          setState(() => _returnToInventory = selected.first);
                        }
                      },
                      multiSelectionEnabled: false,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Save Refresh'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _actionDescription {
    switch (_action) {
      case 'replace':
        return 'Replace damaged components with fresh stock. The old component is recorded as wastage.';
      case 'add':
        return 'Add extra components to the bouquet. Deducts only newly added inventory.';
      case 'remove':
        return 'Remove components from the bouquet. Choose whether they return to inventory or move to wastage.';
      default:
        return '';
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
