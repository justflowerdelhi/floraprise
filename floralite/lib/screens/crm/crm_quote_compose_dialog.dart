import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/order_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../managers/pricing_manager.dart';
import '../../models/crm_models.dart';
import '../../models/gst_calculation_type.dart';
import '../../models/walk_in_enums.dart';
import '../../models/walk_in_line_item.dart';
import '../../models/walk_in_session.dart';
import '../../providers/crm_provider.dart';
import '../../widgets/product_picker_sheet.dart';

class CrmQuoteComposeDialog extends StatefulWidget {
  const CrmQuoteComposeDialog({
    super.key,
    required this.enquiry,
  });

  final CrmEnquiryItem enquiry;

  static Future<int?> show(
    BuildContext context, {
    required CrmEnquiryItem enquiry,
  }) {
    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CrmQuoteComposeDialog(enquiry: enquiry),
    );
  }

  @override
  State<CrmQuoteComposeDialog> createState() => _CrmQuoteComposeDialogState();
}

class _CrmQuoteComposeDialogState extends State<CrmQuoteComposeDialog> {
  final PricingManager _pricingManager = PricingManager();

  bool _isLoadingDraft = false;
  bool _isSaving = false;
  String? _errorMessage;

  FulfilmentType _fulfilmentType = FulfilmentType.takeAway;
  DateTime? _scheduledAt;
  final TextEditingController _deliverySlotController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _billDiscountController = TextEditingController();
  final TextEditingController _deliveryChargeController = TextEditingController();

  String? _billDiscountType; // 'fixed' or 'percent'
  int? _billDiscountValue;
  int _deliveryChargePaise = 0;

  List<WalkInLineItem> _lines = [];

  @override
  void initState() {
    super.initState();
    _initializeFromEnquiry();
    if (widget.enquiry.quoteOrderId != null) {
      _loadExistingDraft(widget.enquiry.quoteOrderId!);
    }
  }

  @override
  void dispose() {
    _deliverySlotController.dispose();
    _addressController.dispose();
    _instructionsController.dispose();
    _billDiscountController.dispose();
    _deliveryChargeController.dispose();
    super.dispose();
  }

  void _initializeFromEnquiry() {
    final hasLocation = widget.enquiry.location != null &&
        widget.enquiry.location!.trim().isNotEmpty;
    _fulfilmentType = hasLocation
        ? FulfilmentType.delivery
        : (widget.enquiry.eventDate != null
            ? FulfilmentType.pickupLater
            : FulfilmentType.takeAway);

    _scheduledAt = widget.enquiry.eventDate;
    _addressController.text = widget.enquiry.location ?? '';

    final notes = widget.enquiry.notes != null && widget.enquiry.notes!.trim().isNotEmpty
        ? '\nNotes: ${widget.enquiry.notes!.trim()}'
        : '';
    _instructionsController.text = '${widget.enquiry.requirement}$notes';
  }

  Future<void> _loadExistingDraft(int draftOrderId) async {
    setState(() {
      _isLoadingDraft = true;
    });

    try {
      final provider = context.read<CrmProvider>();
      final draftSession = await provider.loadQuoteDraft(draftOrderId);
      if (!mounted) return;

      if (draftSession != null) {
        setState(() {
          _fulfilmentType = draftSession.fulfilmentType;
          _lines = List<WalkInLineItem>.from(draftSession.lines);
          _scheduledAt = draftSession.scheduledAt ?? widget.enquiry.eventDate;
          _deliverySlotController.text = draftSession.deliverySlot;
          _addressController.text = draftSession.deliveryAddress.isNotEmpty
              ? draftSession.deliveryAddress
              : (widget.enquiry.location ?? '');
          _instructionsController.text = draftSession.specialInstructions.isNotEmpty
              ? draftSession.specialInstructions
              : widget.enquiry.requirement;
          _billDiscountType = draftSession.billDiscountType;
          _billDiscountValue = draftSession.billDiscountValue;
          if (_billDiscountValue != null && _billDiscountValue! > 0) {
            _billDiscountController.text = _billDiscountType == 'percent'
                ? _billDiscountValue.toString()
                : (_billDiscountValue! / 100).toStringAsFixed(0);
          }
          _isLoadingDraft = false;
        });
      } else {
        setState(() {
          _isLoadingDraft = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDraft = false;
        });
      }
    }
  }

  OrderTotals _computeTotals() {
    return _pricingManager.computeTotals(
      lines: _lines,
      billDiscountType: _billDiscountType,
      billDiscountValue: _billDiscountValue,
      deliveryChargePaise: _deliveryChargePaise,
    );
  }

  void _onAddCatalogProduct(ProductRecord product) {
    setState(() {
      final existingIndex = _lines.indexWhere((l) =>
          (l.productId != null && l.productId == product.id) ||
          (l.cloudProductId != null &&
              product.cloudProductId != null &&
              l.cloudProductId == product.cloudProductId));

      if (existingIndex >= 0) {
        final existing = _lines[existingIndex];
        _lines[existingIndex] = existing.copyWith(quantity: existing.quantity + 1);
      } else {
        _lines.add(
          WalkInLineItem(
            productId: product.id,
            cloudProductId: product.cloudProductId,
            description: product.name,
            quantity: 1,
            unitPricePaise: product.sellingPricePaise,
            gstPercent: product.gstPercent,
            gstCalculationType: product.gstCalculationType,
            source: 'catalog',
          ),
        );
      }
    });
  }

  Future<void> _openProductPicker() async {
    final picked = await showProductPickerSheet(context);
    if (picked != null && mounted) {
      _onAddCatalogProduct(picked);
    }
  }

  Future<void> _openCustomItemDialog() async {
    final descController = TextEditingController();
    final priceController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    int selectedGstPercent = 0;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Add Custom Item / Service'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Item / Service Description *',
                    hintText: 'e.g. Stage Floral Arch, Labor',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Unit Price (₹) *',
                          prefixText: '₹ ',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: qtyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Qty *',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: selectedGstPercent,
                  decoration: const InputDecoration(labelText: 'GST Rate'),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('0% (Exempt/Nil)')),
                    DropdownMenuItem(value: 5, child: Text('5% GST')),
                    DropdownMenuItem(value: 12, child: Text('12% GST')),
                    DropdownMenuItem(value: 18, child: Text('18% GST')),
                    DropdownMenuItem(value: 28, child: Text('28% GST')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDlgState(() => selectedGstPercent = val);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final desc = descController.text.trim();
                final price = double.tryParse(priceController.text.trim()) ?? 0;
                final qty = int.tryParse(qtyController.text.trim()) ?? 1;

                if (desc.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Please enter item description.')),
                  );
                  return;
                }
                if (price < 0 || qty <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid price and quantity.')),
                  );
                  return;
                }
                Navigator.of(ctx).pop(true);
              },
              child: const Text('Add Line Item'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      final desc = descController.text.trim();
      final price = double.tryParse(priceController.text.trim()) ?? 0;
      final qty = int.tryParse(qtyController.text.trim()) ?? 1;
      final pricePaise = (price * 100).round();

      setState(() {
        _lines.add(
          WalkInLineItem(
            description: desc,
            quantity: qty,
            unitPricePaise: pricePaise,
            gstPercent: selectedGstPercent,
            gstCalculationType: GstCalculationType.exclusive,
            source: 'manual',
          ),
        );
      });
    }
  }

  void _updateLineQty(int index, int newQty) {
    setState(() {
      if (newQty <= 0) {
        _lines.removeAt(index);
      } else {
        _lines[index] = _lines[index].copyWith(quantity: newQty);
      }
    });
  }

  void _updateLinePrice(int index, double priceRupees) {
    setState(() {
      final paise = (priceRupees * 100).round();
      _lines[index] = _lines[index].copyWith(unitPricePaise: paise);
    });
  }

  void _removeLine(int index) {
    setState(() {
      _lines.removeAt(index);
    });
  }

  Future<void> _selectScheduledDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null && mounted) {
      setState(() {
        _scheduledAt = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _scheduledAt?.hour ?? 10,
          _scheduledAt?.minute ?? 0,
        );
      });
    }
  }

  Future<void> _saveQuoteDraft() async {
    if (_lines.isEmpty) {
      setState(() {
        _errorMessage = 'Please add at least one line item to create a quote.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final totals = _computeTotals();
      final session = WalkInSession(
        draftOrderId: widget.enquiry.quoteOrderId,
        fulfilmentType: _fulfilmentType,
        lines: _lines,
        customerPhone: widget.enquiry.customerPhone,
        customerName: widget.enquiry.customerName,
        occasion: widget.enquiry.category,
        scheduledAt: _scheduledAt,
        deliverySlot: _deliverySlotController.text.trim(),
        deliveryAddress: _addressController.text.trim(),
        specialInstructions: _instructionsController.text.trim(),
        billDiscountType: _billDiscountType,
        billDiscountValue: _billDiscountValue,
      );

      final provider = context.read<CrmProvider>();
      final draftId = await provider.saveQuoteDraftForEnquiry(
        enquiry: widget.enquiry,
        session: session,
        totals: totals,
      );

      if (!mounted) return;
      Navigator.of(context).pop(draftId);
    } catch (e, st) {
      debugPrint('[CrmQuoteComposeDialog] Error saving quote draft: $e\n$st');
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Failed to save quote draft: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = MediaQuery.sizeOf(context).width >= 720;
    final totals = _computeTotals();

    if (_isLoadingDraft) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading quotation draft...'),
            ],
          ),
        ),
      );
    }

    final dialogChild = Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.enquiry.quoteOrderId == null
                  ? 'Create Quotation'
                  : 'Edit Quotation (Draft #${widget.enquiry.quoteOrderId})',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text(
              '${widget.enquiry.customerName} • ${widget.enquiry.customerPhone}',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              color: colorScheme.errorContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: colorScheme.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: colorScheme.onErrorContainer, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Enquiry Reference Banner
                _buildEnquiryBanner(theme, colorScheme),
                const SizedBox(height: 16),

                // Fulfillment & Schedule Section
                _buildFulfillmentSection(theme, colorScheme),
                const SizedBox(height: 16),

                // Line Items Header & Action Buttons
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Text(
                      'Quotation Items (${_lines.length})',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _openCustomItemDialog,
                          icon: const Icon(Icons.post_add_rounded, size: 16),
                          label: const Text('Custom Item'),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: _openProductPicker,
                          icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                          label: const Text('Catalog Item'),
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Line Items List or Empty State
                if (_lines.isEmpty)
                  _buildLinesEmptyState(theme)
                else
                  _buildLinesTable(theme, colorScheme),
                const SizedBox(height: 16),

                // Bill Adjustments & Notes
                _buildAdjustmentsAndNotesSection(theme, colorScheme),
                const SizedBox(height: 16),

                // Order Totals Summary Card
                _buildTotalsCard(totals, theme, colorScheme),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Grand Total: ₹${(totals.grandTotalPaise / 100).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _saveQuoteDraft,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        widget.enquiry.quoteOrderId == null
                            ? 'Save Quote Draft'
                            : 'Update Quote Draft',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isDesktop) {
      return Dialog(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 960,
          height: 720,
          child: dialogChild,
        ),
      );
    }

    return Dialog.fullscreen(child: dialogChild);
  }

  Widget _buildEnquiryBanner(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.enquiry.category,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Enquiry Ref: ${widget.enquiry.customerName}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.enquiry.budgetPaise != null && widget.enquiry.budgetPaise! > 0) ...[
                const SizedBox(width: 8),
                Text(
                  'Budget: ₹${(widget.enquiry.budgetPaise! / 100).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF047857),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.enquiry.requirement,
            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildFulfillmentSection(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fulfillment & Event Schedule',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<FulfilmentType>(
                segments: const [
                  ButtonSegment(
                    value: FulfilmentType.takeAway,
                    label: Text('Takeaway'),
                    icon: Icon(Icons.storefront_outlined, size: 16),
                  ),
                  ButtonSegment(
                    value: FulfilmentType.pickupLater,
                    label: Text('Pickup Later'),
                    icon: Icon(Icons.schedule_outlined, size: 16),
                  ),
                  ButtonSegment(
                    value: FulfilmentType.delivery,
                    label: Text('Delivery'),
                    icon: Icon(Icons.local_shipping_outlined, size: 16),
                  ),
                ],
                selected: {_fulfilmentType},
                onSelectionChanged: (set) {
                  setState(() {
                    _fulfilmentType = set.first;
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectScheduledDate,
                    borderRadius: BorderRadius.circular(8),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Event / Fulfillment Date',
                        prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text(
                        _scheduledAt != null
                            ? DateFormat('dd MMM yyyy').format(_scheduledAt!)
                            : 'Select date',
                        style: TextStyle(
                          fontSize: 13,
                          color: _scheduledAt != null ? null : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_fulfilmentType == FulfilmentType.delivery) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _deliverySlotController,
                      decoration: const InputDecoration(
                        labelText: 'Delivery Slot / Time',
                        hintText: 'e.g. 10 AM - 12 PM',
                        prefixIcon: Icon(Icons.access_time_rounded, size: 18),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (_fulfilmentType == FulfilmentType.delivery) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Delivery / Venue Address',
                  hintText: 'Street address, venue hall, or landmark',
                  prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLinesEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 36, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            const Text(
              'No Items in Quotation',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Add floral items from catalog or custom event arrangements.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinesTable(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _lines.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final line = _lines[index];
          final lineSubtotal = (line.unitPricePaise * line.quantity) - line.discountPaise;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line.description,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      if (line.gstPercent != null && line.gstPercent! > 0)
                        Text(
                          'GST ${line.gstPercent}%',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                ),
                // Qty Selector
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                      onPressed: () => _updateLineQty(index, line.quantity - 1),
                      visualDensity: VisualDensity.compact,
                    ),
                    Text(
                      '${line.quantity}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                      onPressed: () => _updateLineQty(index, line.quantity + 1),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                // Unit Price Editor
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    initialValue: (line.unitPricePaise / 100).toStringAsFixed(0),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      prefixText: '₹',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 12),
                    onChanged: (val) {
                      final p = double.tryParse(val.trim());
                      if (p != null && p >= 0) {
                        _updateLinePrice(index, p);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Line Total
                SizedBox(
                  width: 75,
                  child: Text(
                    '₹${(lineSubtotal / 100).toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 4),
                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                  onPressed: () => _removeLine(index),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdjustmentsAndNotesSection(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Special Instructions & Notes
        Expanded(
          flex: 2,
          child: TextField(
            controller: _instructionsController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Special Instructions / Proposal Notes',
              hintText: 'Color themes, flower substitutions, delivery instructions...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Discount & Delivery Charges
        Expanded(
          flex: 1,
          child: Column(
            children: [
              TextField(
                controller: _billDiscountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Bill Discount',
                  hintText: '0',
                  prefixText: _billDiscountType == 'percent' ? '% ' : '₹ ',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  suffixIcon: PopupMenuButton<String>(
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    tooltip: 'Discount Type',
                    onSelected: (type) {
                      setState(() {
                        _billDiscountType = type;
                      });
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'fixed', child: Text('Fixed Amount (₹)')),
                      PopupMenuItem(value: 'percent', child: Text('Percentage (%)')),
                    ],
                  ),
                ),
                onChanged: (val) {
                  final parsed = double.tryParse(val.trim());
                  setState(() {
                    if (parsed == null || parsed <= 0) {
                      _billDiscountValue = null;
                      _billDiscountType = null;
                    } else {
                      _billDiscountType ??= 'fixed';
                      _billDiscountValue = _billDiscountType == 'percent'
                          ? parsed.round()
                          : (parsed * 100).round();
                    }
                  });
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _deliveryChargeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Delivery Charge',
                  hintText: '0',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                onChanged: (val) {
                  final parsed = double.tryParse(val.trim()) ?? 0;
                  setState(() {
                    _deliveryChargePaise = (parsed * 100).round();
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalsCard(OrderTotals totals, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _buildTotalRow('Net Subtotal:', '₹${(totals.subtotalPaise / 100).toStringAsFixed(2)}'),
          if (totals.discountTotalPaise > 0)
            _buildTotalRow(
              'Total Discount:',
              '-₹${(totals.discountTotalPaise / 100).toStringAsFixed(2)}',
              valueColor: Colors.green.shade700,
            ),
          if (_deliveryChargePaise > 0)
            _buildTotalRow('Delivery Charge:', '₹${(_deliveryChargePaise / 100).toStringAsFixed(2)}'),
          if (totals.gstTotalPaise > 0)
            _buildTotalRow('GST Total:', '₹${(totals.gstTotalPaise / 100).toStringAsFixed(2)}'),
          if (totals.roundOffPaise != 0)
            _buildTotalRow(
              'Round Off:',
              '${totals.roundOffPaise > 0 ? '+' : ''}₹${(totals.roundOffPaise / 100).toStringAsFixed(2)}',
            ),
          const Divider(height: 12),
          _buildTotalRow(
            'Grand Total:',
            '₹${(totals.grandTotalPaise / 100).toStringAsFixed(2)}',
            isBold: true,
            fontSize: 16,
            valueColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 13,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
