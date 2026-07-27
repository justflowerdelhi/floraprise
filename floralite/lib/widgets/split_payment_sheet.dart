import 'package:flutter/material.dart';

class SplitPaymentMethodOption {
  const SplitPaymentMethodOption({
    required this.code,
    required this.label,
    required this.icon,
    this.isCredit = false,
  });

  final String code;
  final String label;
  final IconData icon;
  final bool isCredit;
}

class SplitPaymentAllocationResult {
  const SplitPaymentAllocationResult({
    required this.amountsPaise,
    required this.paidPaise,
    required this.outstandingPaise,
  });

  final Map<String, int> amountsPaise;
  final int paidPaise;
  final int outstandingPaise;
}

const List<SplitPaymentMethodOption> kSplitPaymentMethodOptions = [
  SplitPaymentMethodOption(code: 'cash', label: 'Cash', icon: Icons.payments),
  SplitPaymentMethodOption(
      code: 'upi', label: 'UPI', icon: Icons.qr_code_scanner),
  SplitPaymentMethodOption(
      code: 'card', label: 'Card', icon: Icons.credit_card),
  SplitPaymentMethodOption(
    code: 'bank_transfer',
    label: 'Bank Transfer',
    icon: Icons.account_balance,
  ),
  SplitPaymentMethodOption(
    code: 'cheque',
    label: 'Cheque',
    icon: Icons.description,
  ),
  SplitPaymentMethodOption(
    code: 'credit',
    label: 'Credit (Outstanding)',
    icon: Icons.account_balance_wallet,
    isCredit: true,
  ),
  SplitPaymentMethodOption(
    code: 'gift_voucher',
    label: 'Gift Voucher',
    icon: Icons.card_giftcard,
  ),
  SplitPaymentMethodOption(
    code: 'store_wallet',
    label: 'Store Wallet',
    icon: Icons.account_balance_wallet,
  ),
];

Future<SplitPaymentAllocationResult?> showSplitPaymentAllocationSheet({
  required BuildContext context,
  required int orderTotalPaise,
  required String Function(int paise) formatPaise,
  Map<String, int>? initialAmountsPaise,
}) {
  return showModalBottomSheet<SplitPaymentAllocationResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _SplitPaymentSheet(
      orderTotalPaise: orderTotalPaise,
      formatPaise: formatPaise,
      initialAmountsPaise: initialAmountsPaise ?? const <String, int>{},
    ),
  );
}

class _SplitPaymentSheet extends StatefulWidget {
  const _SplitPaymentSheet({
    required this.orderTotalPaise,
    required this.formatPaise,
    required this.initialAmountsPaise,
  });

  final int orderTotalPaise;
  final String Function(int paise) formatPaise;
  final Map<String, int> initialAmountsPaise;

  @override
  State<_SplitPaymentSheet> createState() => _SplitPaymentSheetState();
}

class _SplitPaymentSheetState extends State<_SplitPaymentSheet> {
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final method in kSplitPaymentMethodOptions)
        method.code: TextEditingController(
          text: _paiseToInputText(widget.initialAmountsPaise[method.code] ?? 0),
        ),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  int _parsePaise(String value) {
    final normalized = value.replaceAll(',', '').trim();
    if (normalized.isEmpty) return 0;
    final parsed = double.tryParse(normalized) ?? 0;
    return (parsed * 100).round();
  }

  String _paiseToInputText(int paise) {
    if (paise <= 0) return '';
    final rupees = paise / 100.0;
    if (rupees == rupees.roundToDouble()) {
      return rupees.toStringAsFixed(0);
    }
    return rupees.toStringAsFixed(2);
  }

  Map<String, int> get _amountsPaise => {
        for (final method in kSplitPaymentMethodOptions)
          method.code: _parsePaise(_controllers[method.code]!.text),
      };

  int get _totalAllocatedPaise =>
      _amountsPaise.values.fold<int>(0, (sum, amount) => sum + amount);

  int get _paidPaise {
    final amounts = _amountsPaise;
    return kSplitPaymentMethodOptions
        .where((method) => !method.isCredit)
        .fold<int>(
          0,
          (sum, method) => sum + (amounts[method.code] ?? 0),
        );
  }

  int get _creditPaise => _amountsPaise['credit'] ?? 0;

  int get _remainingPaise {
    final remaining = widget.orderTotalPaise - _totalAllocatedPaise;
    return remaining < 0 ? 0 : remaining;
  }

  bool get _isExceeded => _totalAllocatedPaise > widget.orderTotalPaise;

  bool get _canComplete {
    if (_isExceeded) return false;
    if (_remainingPaise == 0) return true;
    return _remainingPaise > 0 && _creditPaise > 0;
  }

  Future<void> _fillRemaining(SplitPaymentMethodOption method) async {
    final remaining = _remainingPaise;
    if (remaining <= 0) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(method.label),
        content: Text('Use remaining ${widget.formatPaise(remaining)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final current = _parsePaise(_controllers[method.code]!.text);
    final next = current + remaining;
    setState(() {
      _controllers[method.code]!.text = _paiseToInputText(next);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Material(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Split Payment',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _summaryRow('Order Total', widget.orderTotalPaise),
                _summaryRow('Amount Received', _paidPaise),
                _summaryRow('Remaining', _remainingPaise),
                if (_isExceeded) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Total entered cannot exceed order total.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Payment Methods',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...kSplitPaymentMethodOptions.map(_buildMethodRow),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _canComplete
                      ? () {
                          final amounts = _amountsPaise;
                          final cleaned = <String, int>{
                            for (final method in kSplitPaymentMethodOptions)
                              if ((amounts[method.code] ?? 0) > 0)
                                method.code: amounts[method.code]!,
                          };
                          final outstanding =
                              (widget.orderTotalPaise - _paidPaise)
                                  .clamp(0, widget.orderTotalPaise);
                          Navigator.of(context).pop(
                            SplitPaymentAllocationResult(
                              amountsPaise: cleaned,
                              paidPaise: _paidPaise,
                              outstandingPaise: outstanding,
                            ),
                          );
                        }
                      : null,
                  child: const Text('Complete Payment'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMethodRow(SplitPaymentMethodOption method) {
    return InkWell(
      onTap: () => _fillRemaining(method),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(method.icon),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                method.label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            SizedBox(
              width: 130,
              child: TextField(
                controller: _controllers[method.code],
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  prefixText: '₹ ',
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, int amountPaise) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            widget.formatPaise(amountPaise),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
