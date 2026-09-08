import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/repositories/cloud_order_repository.dart';
import '../models/order_workspace_models.dart';
import '../providers/order_provider.dart';
import '../widgets/common_widgets.dart';

/// Cloud-only order editor. Writes through the Cloud order APIs using the
/// cloudOrderId Guid and never touches the local SQLite edit path.
class CloudOrderEditScreen extends StatefulWidget {
  const CloudOrderEditScreen({
    super.key,
    required this.cloudOrderId,
    required this.header,
    required this.detail,
  });

  final String cloudOrderId;
  final OrderDetailHeader header;
  final OrderDetailBundle detail;

  @override
  State<CloudOrderEditScreen> createState() => _CloudOrderEditScreenState();
}

class _CloudOrderEditScreenState extends State<CloudOrderEditScreen> {
  late final TextEditingController _addressController;
  late final TextEditingController _pincodeController;
  late final TextEditingController _recipientNameController;
  late final TextEditingController _recipientPhoneController;
  late final TextEditingController _cardMessageController;
  late final TextEditingController _timeSlotController;
  late final TextEditingController _billDiscountController;
  late final TextEditingController _deliveryFeeController;
  late final TextEditingController _rewardPointsController;
  late final TextEditingController _rewardDiscountController;

  late DateTime? _scheduledAt;
  late List<_EditableLine> _lines;
  bool _isSaving = false;
  String? _error;

  bool get _isDelivery =>
      widget.header.fulfilmentType.toLowerCase() == 'delivery';

  @override
  void initState() {
    super.initState();
    final header = widget.header;
    final info = widget.detail.marketplaceInfo;

    _addressController = TextEditingController(text: _clean(header.address));
    _pincodeController =
        TextEditingController(text: _clean(header.deliveryPincode));
    _recipientNameController =
        TextEditingController(text: _clean(header.recipientName));
    _recipientPhoneController =
        TextEditingController(text: _clean(header.recipientPhone));
    _cardMessageController =
        TextEditingController(text: _clean(header.cardMessage));
    _timeSlotController =
        TextEditingController(text: _clean(header.deliverySlot));
    _billDiscountController = TextEditingController(
      text: _rupees(_intOf(info['discount_amount_paise'])),
    );
    _deliveryFeeController = TextEditingController(
      text: _rupees(_intOf(info['delivery_fee_paise'])),
    );
    _rewardPointsController =
        TextEditingController(text: '${header.rewardPointsRedeemed}');
    _rewardDiscountController = TextEditingController(
      text: _rupees(header.rewardDiscountAmountPaise),
    );

    _scheduledAt = header.scheduledAt;
    _lines = widget.detail.lines
        .map(_EditableLine.fromRow)
        .whereType<_EditableLine>()
        .toList();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _pincodeController.dispose();
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    _cardMessageController.dispose();
    _timeSlotController.dispose();
    _billDiscountController.dispose();
    _deliveryFeeController.dispose();
    _rewardPointsController.dispose();
    _rewardDiscountController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(title: Text('Edit ${widget.header.orderNo}')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildScheduleCard(),
              const SizedBox(height: 12),
              if (_isDelivery) ...[
                _buildDeliveryCard(),
                const SizedBox(height: 12),
              ],
              _buildItemsCard(),
              const SizedBox(height: 12),
              _buildFinancialsCard(),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Schedule'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_outlined),
            title: Text(_isDelivery ? 'Delivery Date' : 'Pickup Date'),
            subtitle: Text(_scheduledAt == null
                ? 'Not set'
                : '${_scheduledAt!.day}/${_scheduledAt!.month}/${_scheduledAt!.year}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickDate,
          ),
          TextField(
            controller: _timeSlotController,
            decoration: const InputDecoration(labelText: 'Time Slot'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Delivery Details'),
          TextField(
            controller: _recipientNameController,
            decoration: const InputDecoration(labelText: 'Recipient Name'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _recipientPhoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Recipient Phone'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _addressController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Delivery Address'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pincodeController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: const InputDecoration(labelText: 'Pincode'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _cardMessageController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Card Message'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Items'),
          if (_lines.isEmpty)
            const Text('This order has no editable Cloud items.')
          else
            for (final line in _lines) _buildLineEditor(line),
        ],
      ),
    );
  }

  Widget _buildLineEditor(_EditableLine line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  line.productName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                tooltip: 'Remove item',
                icon: const Icon(Icons.delete_outline),
                onPressed: _lines.length <= 1
                    ? null
                    : () => setState(() {
                          _lines.remove(line);
                          line.dispose();
                        }),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: line.quantityController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Qty'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: line.unitPriceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Unit Price',
                    prefixText: '₹ ',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: line.discountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Discount',
                    prefixText: '₹ ',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialsCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Charges & Rewards'),
          TextField(
            controller: _billDiscountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Bill Discount',
              prefixText: '₹ ',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _deliveryFeeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Delivery Fee',
              prefixText: '₹ ',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _rewardPointsController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Reward Points Used'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _rewardDiscountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Reward Discount',
              prefixText: '₹ ',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final initial = _scheduledAt ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year - 1),
      lastDate: DateTime(initial.year + 2),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _scheduledAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        initial.hour,
        initial.minute,
      );
    });
  }

  Future<void> _save() async {
    final items = <CloudOrderItemInput>[];
    for (final line in _lines) {
      final quantity = int.tryParse(line.quantityController.text.trim()) ?? 0;
      if (quantity <= 0) {
        setState(() => _error = 'Every item needs a quantity of at least 1.');
        return;
      }
      items.add(
        CloudOrderItemInput(
          productId: line.productId,
          productName: line.productName,
          quantity: quantity,
          unitPricePaise: _paise(line.unitPriceController.text),
          discountAmountPaise: _paise(line.discountController.text),
          taxRatePercent: line.gstPercent,
        ),
      );
    }
    if (items.isEmpty) {
      setState(() => _error = 'An order must keep at least one item.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await context.read<OrderProvider>().saveCloudOrderEdit(
            cloudOrderId: widget.cloudOrderId,
            deliveryDate: _scheduledAt,
            timeSlot: _timeSlotController.text.trim(),
            deliveryAddress:
                _isDelivery ? _addressController.text.trim() : null,
            deliveryPincode:
                _isDelivery ? _pincodeController.text.trim() : null,
            recipientName:
                _isDelivery ? _recipientNameController.text.trim() : null,
            recipientPhone:
                _isDelivery ? _recipientPhoneController.text.trim() : null,
            cardMessage:
                _isDelivery ? _cardMessageController.text.trim() : null,
            items: items,
            discountAmountPaise: _paise(_billDiscountController.text),
            deliveryFeePaise: _paise(_deliveryFeeController.text),
            rewardPointsRedeemed:
                int.tryParse(_rewardPointsController.text.trim()) ?? 0,
            rewardDiscountAmountPaise: _paise(_rewardDiscountController.text),
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = 'Unable to save order: $error';
      });
    }
  }

  static String _clean(String value) => value.trim() == '-' ? '' : value.trim();

  static int _intOf(Object? value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

  static String _rupees(int paise) => (paise / 100).toStringAsFixed(2);

  static int _paise(String text) {
    final normalized = text.replaceAll(RegExp(r'[^0-9.]'), '').trim();
    if (normalized.isEmpty) return 0;
    return ((double.tryParse(normalized) ?? 0) * 100).round();
  }
}

class _EditableLine {
  _EditableLine({
    required this.productId,
    required this.productName,
    required this.gstPercent,
    required int quantity,
    required int unitPricePaise,
    required int discountPaise,
  })  : quantityController = TextEditingController(text: '$quantity'),
        unitPriceController = TextEditingController(
          text: (unitPricePaise / 100).toStringAsFixed(2),
        ),
        discountController = TextEditingController(
          text: (discountPaise / 100).toStringAsFixed(2),
        );

  final String productId;
  final String productName;
  final int gstPercent;
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;
  final TextEditingController discountController;

  static _EditableLine? fromRow(Map<String, Object?> row) {
    final productId = row['product_id']?.toString().trim() ?? '';
    if (productId.isEmpty) return null;
    return _EditableLine(
      productId: productId,
      productName: (row['product_name'] ?? row['description'])?.toString() ??
          'Item',
      gstPercent: _CloudOrderEditScreenState._intOf(row['gst_percent']),
      quantity: _CloudOrderEditScreenState._intOf(row['qty']),
      unitPricePaise: _CloudOrderEditScreenState._intOf(row['unit_price_paise']),
      discountPaise: _CloudOrderEditScreenState._intOf(row['discount_paise']),
    );
  }

  void dispose() {
    quantityController.dispose();
    unitPriceController.dispose();
    discountController.dispose();
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
