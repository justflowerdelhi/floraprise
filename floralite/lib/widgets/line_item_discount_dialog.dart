import 'package:flutter/material.dart';
import '../models/walk_in_line_item.dart';
import '../services/discount_service.dart';

class LineItemDiscountDialog extends StatefulWidget {
  final WalkInLineItem item;
  final int lineSubtotalPaise;

  const LineItemDiscountDialog({
    super.key,
    required this.item,
    required this.lineSubtotalPaise,
  });

  @override
  State<LineItemDiscountDialog> createState() => _LineItemDiscountDialogState();
}

class _LineItemDiscountDialogState extends State<LineItemDiscountDialog> {
  String _discountType = 'percentage';
  final TextEditingController _valueController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.item.discountType != null && widget.item.discountValue != null) {
      _discountType = widget.item.discountType!;
      if (_discountType == 'percentage') {
        _valueController.text = widget.item.discountValue.toString();
      } else {
        _valueController.text = (widget.item.discountValue! / 100).toStringAsFixed(2);
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

    final validation = DiscountService.validateLineDiscount(
      lineSubtotalPaise: widget.lineSubtotalPaise,
      discountType: _discountType,
      discountValue: discountValue,
    );

    if (validation != null) {
      setState(() => _error = validation);
      return;
    }

    final discountAmount = DiscountService.calculateLineDiscount(
      lineSubtotalPaise: widget.lineSubtotalPaise,
      discountType: _discountType,
      discountValue: discountValue,
    );

    Navigator.of(context).pop({
      'discountType': _discountType,
      'discountValue': discountValue,
      'discountPaise': discountAmount,
    });
  }

  void _removeDiscount() {
    Navigator.of(context).pop({
      'discountType': null,
      'discountValue': null,
      'discountPaise': 0,
    });
  }

  @override
  Widget build(BuildContext context) {
    final lineAmount = widget.lineSubtotalPaise / 100;

    return AlertDialog(
      title: const Text('Line Item Discount'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Item: ${widget.item.description}'),
          const SizedBox(height: 4),
          Text('Amount: ₹${lineAmount.toStringAsFixed(2)}'),
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
            _discountType == 'percentage' ? 'Discount (%)' : 'Discount (₹)',
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _valueController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: _discountType == 'percentage' ? 'e.g., 10' : 'e.g., 50',
              errorText: _error,
              suffix: Text(_discountType == 'percentage' ? '%' : '₹'),
            ),
            onChanged: (_) => setState(() => _error = null),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (widget.item.discountType != null)
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
