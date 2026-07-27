import 'package:flutter/material.dart';
import '../services/discount_service.dart';

class BillDiscountDialog extends StatefulWidget {
  final int subtotalPaise;
  final String? currentDiscountType;
  final int? currentDiscountValue;

  const BillDiscountDialog({
    super.key,
    required this.subtotalPaise,
    this.currentDiscountType,
    this.currentDiscountValue,
  });

  @override
  State<BillDiscountDialog> createState() => _BillDiscountDialogState();
}

class _BillDiscountDialogState extends State<BillDiscountDialog> {
  String _discountType = 'percentage';
  final TextEditingController _valueController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.currentDiscountType != null && widget.currentDiscountValue != null) {
      _discountType = widget.currentDiscountType!;
      if (_discountType == 'final_amount') {
        _valueController.text = (widget.currentDiscountValue! / 100).toStringAsFixed(2);
      } else if (_discountType == 'percentage') {
        _valueController.text = widget.currentDiscountValue.toString();
      } else {
        _valueController.text = (widget.currentDiscountValue! / 100).toStringAsFixed(2);
      }
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  void _validateAndApply() {
    final valueText = _valueController.text.trim();
    if (valueText.isEmpty) {
      setState(() => _error = 'Please enter a value');
      return;
    }

    final value = double.tryParse(valueText);
    if (value == null || value < 0) {
      setState(() => _error = 'Please enter a valid positive number');
      return;
    }

    final discountValue = _discountType == 'percentage' 
        ? value.round() 
        : (value * 100).round();

    final validation = DiscountService.validateBillDiscount(
      subtotalPaise: widget.subtotalPaise,
      discountType: _discountType,
      discountValue: discountValue,
    );

    if (validation != null) {
      setState(() => _error = validation);
      return;
    }

    Navigator.of(context).pop({
      'discountType': _discountType,
      'discountValue': discountValue,
    });
  }

  void _removeDiscount() {
    Navigator.of(context).pop({
      'discountType': null,
      'discountValue': null,
    });
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.subtotalPaise / 100;

    return AlertDialog(
      title: const Text('Bill Discount'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Subtotal: ₹${subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 16),
          const Text('Discount Type'),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'percentage',
                label: Text('%'),
              ),
              ButtonSegment(
                value: 'fixed',
                label: Text('₹'),
              ),
              ButtonSegment(
                value: 'final_amount',
                label: Text('Final'),
              ),
            ],
            selected: {_discountType},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _discountType = newSelection.first;
                _valueController.clear();
                _error = null;
              });
            },
          ),
          const SizedBox(height: 16),
          Text(
            _discountType == 'percentage'
                ? 'Discount (%)'
                : _discountType == 'fixed'
                    ? 'Discount (₹)'
                    : 'Customer Will Pay (₹)',
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _valueController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: _discountType == 'percentage'
                  ? 'e.g., 10'
                  : _discountType == 'fixed'
                      ? 'e.g., 100'
                      : 'e.g., 1600',
              errorText: _error,
              suffix: const Text('₹'),
            ),
            onChanged: (_) => setState(() => _error = null),
          ),
          if (_discountType == 'final_amount') ...[
            const SizedBox(height: 8),
            Text(
              'Floraprise will calculate the discount needed to reach this final amount.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (widget.currentDiscountType != null)
          TextButton(
            onPressed: _removeDiscount,
            child: const Text('Remove'),
          ),
        FilledButton(
          onPressed: _validateAndApply,
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
