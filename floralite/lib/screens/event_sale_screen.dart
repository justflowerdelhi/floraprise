import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/repositories/customer_repository.dart';
import '../data/repositories/inventory_repository.dart';
import '../data/repositories/order_repository.dart';
import '../data/repositories/product_repository.dart';
import '../managers/business_settings_manager.dart';
import '../managers/pricing_manager.dart';
import '../models/fiscal_profile.dart';
import '../models/gst_calculation_type.dart';
import '../models/order_workspace_models.dart';
import '../models/payment_split.dart';
import '../models/walk_in_enums.dart';
import '../models/walk_in_line_item.dart';
import '../models/walk_in_session.dart';
import '../providers/customer_provider.dart';
import '../providers/printer_provider.dart';
import '../providers/walk_in_session_provider.dart';
import '../services/discount_service.dart';
import '../services/pdf/pdf_document_service.dart';
import '../services/reward_summary_formatter.dart';
import '../utils/locale_formatter.dart';
import '../utils/whatsapp_phone_utils.dart';
import '../widgets/app_header.dart';
import '../widgets/common_widgets.dart';
import '../widgets/customer_name_autocomplete.dart';
import '../widgets/customer_search_sheet.dart';
import '../widgets/line_item_discount_dialog.dart';
import '../widgets/product_picker_sheet.dart';
import '../widgets/quantity_input_stepper.dart';
import '../widgets/reward_summary_card.dart';
import '../widgets/schedule_payment_followup_dialog.dart';

enum _UnsavedChangesAction { saveDraft, discard, cancel }

enum EventPaymentOption {
  fullPayment,
  partialAdvance,
  payLater,
}

class EventSaleScreen extends StatefulWidget {
  const EventSaleScreen({
    super.key,
    this.prefillCustomerId,
    this.prefillCustomerName,
    this.prefillCustomerPhone,
    this.prefillRecipientName,
    this.prefillOccasion,
    this.initialSession,
    this.editingOrderId,
  });

  final String? prefillCustomerId;
  final String? prefillCustomerName;
  final String? prefillCustomerPhone;
  final String? prefillRecipientName;
  final String? prefillOccasion;
  final WalkInSession? initialSession;
  final int? editingOrderId;

  @override
  State<EventSaleScreen> createState() => _EventSaleScreenState();
}

class _EventSaleScreenState extends State<EventSaleScreen> {
  static const FulfilmentType _fulfilmentType = FulfilmentType.eventSale;

  static const List<String> _eventTypes = [
    'Wedding',
    'Reception',
    'Birthday',
    'Anniversary',
    'Corporate Event',
    'Engagement',
    'Mandap / Stage Decor',
    'Flower Decoration',
    'Other',
  ];

  final BusinessSettingsManager _businessSettingsManager =
      BusinessSettingsManager();
  final PricingManager _pricingManager = PricingManager();

  final List<_ProductItem> _products = [];
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customEventTypeController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _advanceAmountController = TextEditingController();

  String _selectedEventType = 'Wedding';
  DateTime? _eventDate;
  TimeOfDay? _eventTime;

  EventPaymentOption _paymentOption = EventPaymentOption.fullPayment;
  String _selectedTenderMethod = 'UPI';

  _CustomerInfo? _customerInfo;
  FiscalProfile _fiscalProfile = CountryPresets.india();
  String _shopName = '';
  String _businessPhone = '';

  String? _billDiscountType;
  int? _billDiscountValue;
  int _rewardPointsRedeemed = 0;
  int _rewardDiscountAmountPaise = 0;
  bool _isOrderSaved = false;
  int? _savedOrderId;

  @override
  void initState() {
    super.initState();
    BusinessSettingsManager.changeNotifier.addListener(_loadBusinessSettings);

    if (widget.prefillCustomerPhone != null) {
      _phoneController.text = widget.prefillCustomerPhone!;
    }
    if (widget.prefillCustomerName != null) {
      _customerNameController.text = widget.prefillCustomerName!;
    }
    if (widget.prefillOccasion != null) {
      _parseInitialOccasion(widget.prefillOccasion!);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBusinessSettings();
      _loadDraftSession();
    });
  }

  bool get _isEditingOrder => widget.editingOrderId != null;

  void _parseInitialOccasion(String occasion) {
    final trimmed = occasion.trim();
    if (trimmed.isEmpty) return;
    if (_eventTypes.contains(trimmed)) {
      _selectedEventType = trimmed;
    } else {
      _selectedEventType = 'Other';
      _customEventTypeController.text = trimmed;
    }
  }

  String get _resolvedOccasion {
    if (_selectedEventType == 'Other') {
      final custom = _customEventTypeController.text.trim();
      return custom.isNotEmpty ? custom : 'Event';
    }
    return _selectedEventType;
  }

  Future<void> _loadBusinessSettings() async {
    try {
      final settings = await _businessSettingsManager.load();
      if (!mounted) return;
      setState(() {
        _fiscalProfile = settings.resolvedFiscalProfile;
        _shopName = settings.shopName.trim();
        _businessPhone = settings.phone.trim();
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    BusinessSettingsManager.changeNotifier.removeListener(_loadBusinessSettings);
    _phoneController.dispose();
    _customerNameController.dispose();
    _customEventTypeController.dispose();
    _venueController.dispose();
    _notesController.dispose();
    _advanceAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadDraftSession() async {
    final provider = context.read<WalkInSessionProvider>();
    final session = widget.initialSession;
    if (session != null) {
      provider.patchSession(session);
    } else {
      await provider.initialize(_fulfilmentType);
    }
    final activeSession = provider.session;

    if (!mounted) return;
    setState(() {
      _products
        ..clear()
        ..addAll(
          activeSession.lines.map(
            (line) => _ProductItem(
              productId: line.productId,
              cloudProductId: line.cloudProductId,
              trackInventory: line.productId != null,
              designId: line.description,
              quantity: line.quantity,
              price: _formatPaise(context, line.unitPricePaise),
              unit: 'Piece',
              discount: line.discountType != null && line.discountValue != null
                  ? DiscountService.getDiscountDisplayText(
                      discountType: line.discountType!,
                      discountValue: line.discountValue!,
                    )
                  : null,
              discountType: line.discountType,
              discountValue: line.discountValue,
              gstPercent: line.gstPercent,
              gstCalculationType: line.gstCalculationType,
              source: line.source,
              attachmentPath: line.designRef,
            ),
          ),
        );

      _phoneController.text = activeSession.customerPhone;
      _customerNameController.text = activeSession.customerName;
      _parseInitialOccasion(activeSession.occasion);
      _eventDate = activeSession.scheduledAt;
      if (activeSession.scheduledAt != null) {
        _eventTime = TimeOfDay.fromDateTime(activeSession.scheduledAt!);
      }
      _venueController.text = activeSession.deliveryAddress;
      _notesController.text = activeSession.specialInstructions;
      _billDiscountType = activeSession.billDiscountType;
      _billDiscountValue = activeSession.billDiscountValue;

      // Restore payments
      if (activeSession.payments.isNotEmpty) {
        final totalPaid = activeSession.payments
            .where((p) => !p.isCreditOutstanding)
            .fold<int>(0, (sum, p) => sum + p.amountPaise);
        final grandTotal = _totalAmountPaise;

        if (totalPaid <= 0) {
          _paymentOption = EventPaymentOption.payLater;
        } else if (totalPaid < grandTotal && grandTotal > 0) {
          _paymentOption = EventPaymentOption.partialAdvance;
          _advanceAmountController.text = (totalPaid / 100).toStringAsFixed(0);
          final p = activeSession.payments.firstWhere((p) => !p.isCreditOutstanding, orElse: () => activeSession.payments.first);
          _selectedTenderMethod = _paymentToLabel(p.method);
        } else {
          _paymentOption = EventPaymentOption.fullPayment;
          final p = activeSession.payments.firstWhere((p) => !p.isCreditOutstanding, orElse: () => activeSession.payments.first);
          _selectedTenderMethod = _paymentToLabel(p.method);
        }
      }
    });

    if (_phoneController.text.trim().length == 10) {
      _lookupCustomer(_phoneController.text.trim());
    }

    if (widget.editingOrderId != null && !kIsWeb) {
      try {
        final inventoryRepo = InventoryRepository();
        final reservations =
            await inventoryRepo.getReservationsForOrder(orderId: widget.editingOrderId!);
        final activeRes =
            reservations.where((r) => r.status == 'active').toList();
        if (activeRes.isNotEmpty && mounted) {
          setState(() {
            for (int i = 0; i < _products.length; i++) {
              final p = _products[i];
              if (p.productId != null) {
                final match = activeRes
                    .where((r) => r.productId == p.productId)
                    .fold<int>(0, (sum, r) => sum + r.quantity);
                if (match > 0) {
                  _products[i] = p.copyWith(reservedQty: match);
                }
              }
            }
          });
        }
      } catch (_) {}
    }
  }

  // --- Financial Calculations ---

  int get _subtotalPaise => _orderTotals.subtotalPaise;

  int get _gstAmountPaise => _orderTotals.gstTotalPaise;

  int get _totalAmountPaise => _orderTotals.grandTotalPaise;

  int get _billDiscountPaise {
    if (_billDiscountType == null || _billDiscountValue == null) return 0;
    return DiscountService.calculateBillDiscount(
      subtotalPaise: _subtotalPaise,
      discountType: _billDiscountType!,
      discountValue: _billDiscountValue!,
    );
  }

  OrderTotals get _orderTotals => _pricingManager.computeTotals(
        lines: _walkInLines,
        billDiscountType: _billDiscountType,
        billDiscountValue: _billDiscountValue,
        rewardDiscountPaise: _rewardDiscountAmountPaise,
        fiscalProfile: _fiscalProfile,
      );

  List<WalkInLineItem> get _walkInLines => _buildLineItems();

  int get _resolvedAdvancePaidPaise {
    final grandTotal = _totalAmountPaise;
    switch (_paymentOption) {
      case EventPaymentOption.fullPayment:
        return grandTotal;
      case EventPaymentOption.payLater:
        return 0;
      case EventPaymentOption.partialAdvance:
        final enteredRs = int.tryParse(_advanceAmountController.text.trim()) ?? 0;
        final enteredPaise = enteredRs * 100;
        return enteredPaise.clamp(0, grandTotal);
    }
  }

  int get _outstandingBalancePaise {
    return (_totalAmountPaise - _resolvedAdvancePaidPaise).clamp(0, _totalAmountPaise);
  }

  List<WalkInLineItem> _buildLineItems() {
    return _products.map((item) {
      final unitPrice = _parseCurrencyToPaise(item.price);
      final lineSubtotal = unitPrice * item.quantity;
      final lineDiscount = item.discountType != null && item.discountValue != null
          ? DiscountService.calculateLineDiscount(
              lineSubtotalPaise: lineSubtotal,
              discountType: item.discountType!,
              discountValue: item.discountValue!,
            )
          : 0;

      return WalkInLineItem(
        productId: item.productId,
        cloudProductId: item.cloudProductId,
        designRef: item.attachmentPath,
        description: item.designId,
        quantity: item.quantity,
        unitPricePaise: unitPrice,
        gstPercent: _fiscalProfile.taxEnabled ? (item.gstPercent ?? _fiscalProfile.taxRatePercent.round()) : 0,
        gstCalculationType: item.gstCalculationType ?? (_fiscalProfile.taxInclusive ? GstCalculationType.inclusive : GstCalculationType.exclusive),
        discountPaise: lineDiscount,
        discountType: item.discountType,
        discountValue: item.discountValue,
        source: item.source,
      );
    }).toList();
  }

  List<PaymentSplit> _buildPaymentSplits() {
    final grandTotal = _totalAmountPaise;
    final advancePaise = _resolvedAdvancePaidPaise;

    if (advancePaise <= 0) {
      return [
        PaymentSplit(
          method: PaymentMethod.other,
          amountPaise: grandTotal,
          methodCode: 'credit',
        ),
      ];
    }

    final method = _labelToPaymentMethod(_selectedTenderMethod);
    final payments = <PaymentSplit>[
      PaymentSplit(
        method: method,
        amountPaise: advancePaise,
        methodCode: _paymentToCode(method),
      ),
    ];

    final remaining = grandTotal - advancePaise;
    if (remaining > 0) {
      payments.add(
        PaymentSplit(
          method: PaymentMethod.other,
          amountPaise: remaining,
          methodCode: 'credit',
        ),
      );
    }

    return payments;
  }

  void _syncProviderSession() {
    final provider = context.read<WalkInSessionProvider>();
    final scheduledDateTime = _combineDateAndTime(_eventDate, _eventTime);

    provider.patchSession(
      provider.session.copyWith(
        fulfilmentType: _fulfilmentType,
        lines: _buildLineItems(),
        customerPhone: _phoneController.text.trim(),
        customerName: _customerNameController.text.trim(),
        occasion: _resolvedOccasion,
        scheduledAt: scheduledDateTime,
        deliverySlot: _eventTime != null
            ? '${_eventTime!.hour}:${_eventTime!.minute.toString().padLeft(2, '0')}'
            : '',
        deliveryAddress: _venueController.text.trim(),
        specialInstructions: _notesController.text.trim(),
        payments: _buildPaymentSplits(),
        billDiscountType: _billDiscountType,
        billDiscountValue: _billDiscountValue,
        rewardPointsRedeemed: _rewardPointsRedeemed,
        rewardDiscountAmountPaise: _rewardDiscountAmountPaise,
      ),
    );
  }

  DateTime? _combineDateAndTime(DateTime? date, TimeOfDay? time) {
    if (date == null) return null;
    if (time == null) {
      return DateTime(date.year, date.month, date.day, 12, 0);
    }
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackWithUnsavedChanges();
      },
      child: Scaffold(
        appBar: AppHeader(
          title: 'Event / Decoration Sale',
          showBackButton: true,
          actions: [
            TextButton(
              onPressed: _isOrderSaved
                  ? null
                  : _isEditingOrder
                      ? _saveOrder
                      : _saveDraft,
              child: Text(_isEditingOrder ? 'Save Changes' : 'Save Draft'),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCustomerSection(colorScheme),
                    const SizedBox(height: 12),
                    _buildEventDetailsSection(colorScheme),
                    const SizedBox(height: 12),
                    _buildLineItemsSection(colorScheme),
                    const SizedBox(height: 12),
                    _buildPaymentSection(colorScheme),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            _buildBottomSummary(colorScheme),
          ],
        ),
      ),
    );
  }

  bool get _hasUnsavedChanges {
    if (_isEditingOrder || _isOrderSaved) return false;
    return _products.isNotEmpty ||
        _phoneController.text.trim().isNotEmpty ||
        _customerNameController.text.trim().isNotEmpty ||
        _venueController.text.trim().isNotEmpty ||
        _notesController.text.trim().isNotEmpty ||
        _eventDate != null;
  }

  Future<void> _handleBackWithUnsavedChanges() async {
    final action = await showDialog<_UnsavedChangesAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Event Sale'),
        content: const Text('Do you want to save this event sale as a draft before leaving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _UnsavedChangesAction.cancel),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _UnsavedChangesAction.discard),
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _UnsavedChangesAction.saveDraft),
            child: const Text('Save Draft'),
          ),
        ],
      ),
    );
    if (!mounted || action == null || action == _UnsavedChangesAction.cancel) return;
    if (action == _UnsavedChangesAction.saveDraft) {
      _syncProviderSession();
      final provider = context.read<WalkInSessionProvider>();
      await provider.saveDraft();
      if (!mounted) return;
      if (provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error!)),
        );
        return;
      }
    }
    if (mounted) Navigator.pop(context);
  }

  // --- SECTION 1: CUSTOMER ---

  Widget _buildCustomerSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.person_outline, size: 20, color: Color(0xFFC2410C)),
                SizedBox(width: 6),
                Text(
                  'Customer Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: _showCustomerSearch,
              icon: const Icon(Icons.search, size: 18),
              label: const Text('Search'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AppCard(
          child: Column(
            children: [
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number *',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                onChanged: (value) {
                  if (value.length == 10) _lookupCustomer(value);
                },
              ),
              const SizedBox(height: 8),
              CustomerNameAutocomplete(
                controller: _customerNameController,
                labelText: 'Customer / Organization Name *',
                onCustomerSelected: (customer) {
                  setState(() {
                    _customerNameController.text = customer.name;
                    if (customer.phone.isNotEmpty) _phoneController.text = customer.phone;
                  });
                  if (customer.phone.isNotEmpty) _lookupCustomer(customer.phone);
                },
              ),
              if (_customerInfo != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
                  ),
                  child: Column(
                    children: [
                      _buildCustomerInfoRow('Previous Orders', '${_customerInfo!.previousOrders}'),
                      _buildCustomerInfoRow('Total Purchase', _customerInfo!.lifetimePurchase),
                      _buildCustomerInfoRow('Last Order', _customerInfo!.lastOrder),
                      _buildCustomerInfoRow('Reward Balance', '${_customerInfo!.rewardPoints} Pts'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // --- SECTION 2: EVENT DETAILS ---

  Widget _buildEventDetailsSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.celebration_outlined, size: 20, color: Color(0xFFC2410C)),
            SizedBox(width: 6),
            Text(
              'Event Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedEventType,
                decoration: InputDecoration(
                  labelText: 'Event Type / Occasion *',
                  prefixIcon: const Icon(Icons.stars_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                ),
                items: _eventTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedEventType = val);
                },
              ),
              if (_selectedEventType == 'Other') ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _customEventTypeController,
                  decoration: InputDecoration(
                    labelText: 'Specify Event Type *',
                    hintText: 'e.g. Baby Shower, House Warming',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectEventDate(context),
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        _eventDate != null
                            ? '${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year}'
                            : 'Event Date *',
                        style: TextStyle(
                          color: _eventDate != null ? Colors.black87 : Colors.grey.shade600,
                          fontWeight: _eventDate != null ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectEventTime(context),
                      icon: const Icon(Icons.access_time, size: 18),
                      label: Text(
                        _eventTime != null
                            ? _eventTime!.format(context)
                            : 'Event Time',
                        style: TextStyle(
                          color: _eventTime != null ? Colors.black87 : Colors.grey.shade600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _venueController,
                decoration: InputDecoration(
                  labelText: 'Venue / Location',
                  hintText: 'e.g. Grand Ballroom, Taj Hotel, Lawn 2',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Event Notes / Special Instructions',
                  hintText: 'e.g. Setup completed before 4 PM, pastel rose theme',
                  prefixIcon: const Icon(Icons.note_alt_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- SECTION 3: LINE ITEMS (MIXED PRODUCTS & CUSTOM SERVICES) ---

  Widget _buildLineItemsSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.view_list_rounded, size: 20, color: Color(0xFFC2410C)),
                SizedBox(width: 6),
                Text(
                  'Items & Services',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => _showProductPicker(context),
                  icon: const Icon(Icons.inventory_2_outlined, size: 16),
                  label: const Text('+ Product', style: TextStyle(fontSize: 12)),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                ),
                const SizedBox(width: 6),
                FilledButton.icon(
                  onPressed: () => _showAddCustomServiceDialog(context),
                  icon: const Icon(Icons.design_services_outlined, size: 16),
                  label: const Text('+ Service/Decor', style: TextStyle(fontSize: 12)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFC2410C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_products.isEmpty)
          AppCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_seat_outlined, size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      'No items or services added yet',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add physical flowers or custom decoration/service lines.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ..._products.asMap().entries.map((entry) {
            final index = entry.key;
            final product = entry.value;
            final isService = product.productId == null;
            final unitPrice = _parseCurrencyToPaise(product.price);
            final lineTotal = (unitPrice * product.quantity) - (product.discountValue ?? 0);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isService ? const Color(0xFFFFF7ED) : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isService ? const Color(0xFFFFEDD5) : const Color(0xFFDCFCE7),
                          ),
                        ),
                        child: Icon(
                          isService ? Icons.palette_outlined : Icons.inventory_2_outlined,
                          size: 24,
                          color: isService ? const Color(0xFFC2410C) : const Color(0xFF16A34A),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    product.designId,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isService ? const Color(0xFFFFEDD5) : const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isService ? 'SERVICE / DECOR' : 'INVENTORY',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: isService ? const Color(0xFF9A3412) : const Color(0xFF15803D),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${product.quantity} × ${product.price} = ${_formatPaise(context, lineTotal)}',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            if (product.discount != null && product.discount!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Discount: ${product.discount}',
                                style: TextStyle(color: Colors.green.shade700, fontSize: 11.5, fontWeight: FontWeight.w600),
                              ),
                            ],
                            const SizedBox(height: 6),
                            if (!isService) ...[
                              Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: product.reservedQty > 0 ? const Color(0xFFF5F3FF) : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: product.reservedQty > 0 ? const Color(0xFFDDD6FE) : Colors.grey.shade200,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Req: ${product.quantity} • Held: ${product.reservedQty} • To Arrange: ${product.stillToArrange}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: product.reservedQty > 0 ? const Color(0xFF6D28D9) : Colors.grey.shade700,
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () => _showReserveStockDialog(index),
                                          borderRadius: BorderRadius.circular(4),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            child: Text(
                                              product.reservedQty > 0 ? 'Edit Hold' : 'Reserve Stock',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: product.reservedQty > 0 ? Colors.deepPurple : const Color(0xFFC2410C),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      product.reservedQty > 0
                                          ? '${product.reservedQty} unit(s) held from current stock'
                                          : 'Stock is not reserved for this event',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontStyle: product.reservedQty > 0 ? FontStyle.normal : FontStyle.italic,
                                        color: product.reservedQty > 0 ? const Color(0xFF7C3AED) : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            Row(
                              children: [
                                SizedBox(
                                  height: 32,
                                  child: QuantityInputStepper(
                                    value: product.quantity,
                                    height: 32,
                                    min: 1,
                                    onChanged: (newQty) {
                                      if (newQty <= 0) {
                                        setState(() => _products.removeAt(index));
                                      } else {
                                        final clampedReserved = product.reservedQty > newQty ? newQty : product.reservedQty;
                                        setState(() => _products[index] = product.copyWith(
                                          quantity: newQty,
                                          reservedQty: clampedReserved,
                                        ));
                                      }
                                    },
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.discount_outlined, size: 18),
                                  tooltip: 'Line Discount',
                                  onPressed: () => _showLineItemDiscountDialog(index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                  tooltip: 'Remove',
                                  onPressed: () => setState(() => _products.removeAt(index)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  // --- SECTION 4: PAYMENT TENDER & ADVANCE ---

  Widget _buildPaymentSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.payment_outlined, size: 20, color: Color(0xFFC2410C)),
            SizedBox(width: 6),
            Text(
              'Payment & Advance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildPaymentOptionButton(
                      label: 'Full Payment',
                      option: EventPaymentOption.fullPayment,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildPaymentOptionButton(
                      label: 'Partial Advance',
                      option: EventPaymentOption.partialAdvance,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildPaymentOptionButton(
                      label: 'Pay Later',
                      option: EventPaymentOption.payLater,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_paymentOption == EventPaymentOption.partialAdvance) ...[
                TextField(
                  controller: _advanceAmountController,
                  decoration: InputDecoration(
                    labelText: 'Advance Payment Amount (₹) *',
                    hintText: 'Enter amount paid now',
                    prefixIcon: const Icon(Icons.currency_rupee),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (v) => setState(() {}),
                ),
                const SizedBox(height: 10),
              ],
              if (_paymentOption != EventPaymentOption.payLater) ...[
                const Text(
                  'Payment Method:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildTenderChip('UPI', Icons.qr_code_scanner),
                    _buildTenderChip('Cash', Icons.payments_outlined),
                    _buildTenderChip('Card', Icons.credit_card_outlined),
                    _buildTenderChip('Bank Transfer', Icons.account_balance_outlined),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Paid Advance', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text(
                          _formatPaise(context, _resolvedAdvancePaidPaise),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Outstanding Balance', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text(
                          _formatPaise(context, _outstandingBalancePaise),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _outstandingBalancePaise > 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOptionButton({
    required String label,
    required EventPaymentOption option,
  }) {
    final isSelected = _paymentOption == option;
    return InkWell(
      onTap: () {
        setState(() {
          _paymentOption = option;
          if (option == EventPaymentOption.partialAdvance && _advanceAmountController.text.isEmpty) {
            final half = (_totalAmountPaise / 200).round();
            _advanceAmountController.text = half > 0 ? half.toString() : '';
          }
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF7ED) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFFC2410C) : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFFC2410C) : Colors.grey.shade800,
          ),
        ),
      ),
    );
  }

  Widget _buildTenderChip(String method, IconData icon) {
    final isSelected = _selectedTenderMethod == method;
    return InkWell(
      onTap: () => setState(() => _selectedTenderMethod = method),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFEDD5) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFC2410C) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? const Color(0xFFC2410C) : Colors.grey.shade700),
            const SizedBox(width: 6),
            Text(
              method,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFFC2410C) : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- BOTTOM SUMMARY ---

  Widget _buildBottomSummary(ColorScheme colorScheme) {
    final outstanding = _outstandingBalancePaise;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  Text(_formatPaise(context, _subtotalPaise), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                ],
              ),
              if (_fiscalProfile.taxEnabled && _gstAmountPaise > 0) ...[
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fiscalProfile.taxLabel, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    Text(_formatPaise(context, _gstAmountPaise), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
              if (_billDiscountType != null && _billDiscountValue != null) ...[
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Discount', style: TextStyle(fontSize: 14, color: Colors.green)),
                    Text(
                      DiscountService.getDiscountDisplayText(discountType: _billDiscountType!, discountValue: _billDiscountValue!),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.green),
                    ),
                  ],
                ),
              ],
              const Divider(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Grand Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      if (outstanding > 0)
                        Text(
                          'Balance: ${_formatPaise(context, outstanding)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFDC2626)),
                        ),
                    ],
                  ),
                  Text(
                    _formatPaise(context, _totalAmountPaise),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFC2410C)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _products.isEmpty || _isOrderSaved ? null : _saveOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC2410C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _isEditingOrder ? 'Update Event Order' : 'Confirm Event Order',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- ACTIONS & DIALOGS ---

  Future<void> _selectEventDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  Future<void> _selectEventTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _eventTime ?? const TimeOfDay(hour: 18, minute: 0),
    );
    if (picked != null) setState(() => _eventTime = picked);
  }

  Future<void> _showProductPicker(BuildContext context) async {
    final selected = await showProductPickerSheet(context, isEventSale: true);
    if (selected == null || !mounted) return;

    final effectiveGstPercent = _fiscalProfile.taxEnabled
        ? selected.gstPercent
        : 0;
    final effectiveInclusive = selected.gstCalculationType;

    setState(() {
      _products.add(
        _ProductItem(
          productId: selected.id,
          cloudProductId: selected.cloudProductId,
          trackInventory: selected.trackInventory,
          designId: selected.name,
          quantity: 1,
          reservedQty: 0,
          price: _formatPaise(context, selected.sellingPricePaise),
          unit: selected.defaultUnit,
          gstPercent: effectiveGstPercent,
          gstCalculationType: effectiveInclusive,
          source: 'inventory',
          attachmentPath: selected.imagePath,
        ),
      );
    });
  }

  Future<void> _showReserveStockDialog(int index) async {
    final product = _products[index];
    if (product.productId == null) return;

    final prodRepo = ProductRepository();
    final allProducts = await prodRepo.listActiveProductsWithInventory();
    final currentProd = allProducts.firstWhere(
      (p) => p.id == product.productId,
      orElse: () => ProductInventoryRecord(
        id: product.productId!,
        code: '',
        name: product.designId,
        category: 'Other',
        defaultUnit: product.unit,
        sku: '',
        barcode: '',
        manufacturerBarcode: '',
        florapriseBarcode: '',
        sellingPricePaise: 0,
        purchasePricePaise: null,
        gstPercent: 0,
        trackInventory: true,
        active: true,
        favorite: false,
        currentQty: 0,
        minQty: 0,
      ),
    );

    if (!mounted) return;

    final avail = currentProd.availableToSell + product.reservedQty;
    final maxCanReserve = avail.clamp(0, product.quantity);
    final reserveController = TextEditingController(
      text: (product.reservedQty > 0 ? product.reservedQty : maxCanReserve).toString(),
    );

    final newReserved = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reserve Stock for Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.designId,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text('Required for Event: ${product.quantity} ${product.unit}'),
                Text('Available to Hold: $avail ${product.unit}'),
                Text('Currently Held: ${product.reservedQty} ${product.unit}'),
                const SizedBox(height: 12),
                TextField(
                  controller: reserveController,
                  decoration: InputDecoration(
                    labelText: 'Units to Hold (0 - $maxCanReserve)',
                    helperText: maxCanReserve <= 0 ? 'No available stock to hold right now' : null,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            if (product.reservedQty > 0)
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, 0),
                child: const Text('Release Hold', style: TextStyle(color: Colors.red)),
              ),
            FilledButton(
              onPressed: () {
                final qty = int.tryParse(reserveController.text.trim()) ?? 0;
                final clamped = qty.clamp(0, maxCanReserve);
                Navigator.pop(dialogContext, clamped);
              },
              child: const Text('Confirm Hold'),
            ),
          ],
        );
      },
    );

    if (newReserved != null && mounted) {
      setState(() {
        _products[index] = product.copyWith(reservedQty: newReserved);
      });
    }
  }

  Future<void> _showAddCustomServiceDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    final rateController = TextEditingController();
    int? gstPercent = _fiscalProfile.taxEnabled ? _fiscalProfile.taxRatePercent.round() : 0;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Custom Service / Decor'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Service / Item Name *',
                        hintText: 'e.g. Stage Decoration, Mandap Setup, Labour',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: qtyController,
                            decoration: const InputDecoration(labelText: 'Qty *'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: rateController,
                            decoration: InputDecoration(
                              labelText: 'Rate (₹) *',
                              prefixText: '${_fiscalProfile.currencySymbol} ',
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_fiscalProfile.taxEnabled)
                      DropdownButtonFormField<int>(
                        initialValue: gstPercent,
                        decoration: const InputDecoration(labelText: 'GST Rate (%)'),
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('0% (Exempt)')),
                          DropdownMenuItem(value: 5, child: Text('5%')),
                          DropdownMenuItem(value: 12, child: Text('12%')),
                          DropdownMenuItem(value: 18, child: Text('18%')),
                          DropdownMenuItem(value: 28, child: Text('28%')),
                        ],
                        onChanged: (v) => setDialogState(() => gstPercent = v),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final qty = int.tryParse(qtyController.text.trim()) ?? 1;
                    final rate = int.tryParse(rateController.text.trim()) ?? 0;

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter service name.')),
                      );
                      return;
                    }
                    if (rate <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid rate.')),
                      );
                      return;
                    }

                    setState(() {
                      _products.add(
                        _ProductItem(
                          productId: null,
                          cloudProductId: null,
                          trackInventory: false,
                          designId: name,
                          quantity: qty > 0 ? qty : 1,
                          price: '${_fiscalProfile.currencySymbol}$rate',
                          gstPercent: gstPercent,
                          gstCalculationType: _fiscalProfile.taxInclusive
                              ? GstCalculationType.inclusive
                              : GstCalculationType.exclusive,
                          source: 'service',
                        ),
                      );
                    });

                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Add Service'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showCustomerSearch() async {
    final selected = await showModalBottomSheet<CustomerRecord>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CustomerSearchSheet(repository: CustomerRepository()),
    );
    if (selected != null && mounted) {
      setState(() {
        _customerNameController.text = selected.name;
        _phoneController.text = selected.phone;
      });
      _lookupCustomer(selected.phone);
    }
  }

  Future<void> _lookupCustomer(String phone) async {
    final provider = context.read<WalkInSessionProvider>();
    final customerProvider = context.read<CustomerProvider>();
    final customer = await customerProvider.lookupByPhone(phone);
    final customerName = customer?.name ?? await provider.lookupCustomerName(phone);
    final customerStats = customer == null
        ? null
        : await customerProvider.lookupCustomerStatistics(customer);

    if (!mounted) return;
    setState(() {
      final resolvedName = customerName ?? customer?.name;
      if ((resolvedName == null || resolvedName.isEmpty) && customer == null) {
        _customerInfo = null;
        _rewardPointsRedeemed = 0;
        _rewardDiscountAmountPaise = 0;
        return;
      }

      final previousOrders = customerStats?['previousOrders'] as int? ?? 0;
      final lifetimePurchasePaise =
          customerStats?['lifetimePurchasePaise'] as int? ?? 0;
      final lastOrderDate = customerStats?['lastOrderDate'] as String?;
      final favouriteDesign = customerStats?['favouriteDesign'] as String?;
      final rewardPoints = customerStats?['rewardPoints'] as int? ?? 0;

      _customerInfo = _CustomerInfo(
        previousOrders: previousOrders,
        lifetimePurchase:
            '₹${(lifetimePurchasePaise / 100).toStringAsFixed(0)}',
        lastOrder: lastOrderDate != null ? _formatDate(lastOrderDate) : 'N/A',
        favouriteDesign: favouriteDesign ?? 'Event Decor',
        rewardPoints: rewardPoints,
      );
      if (resolvedName != null && resolvedName.isNotEmpty) {
        _customerNameController.text = resolvedName;
      }
    });
  }

  Future<void> _showLineItemDiscountDialog(int index) async {
    final product = _products[index];
    final lineSubtotal = _parseCurrencyToPaise(product.price) * product.quantity;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => LineItemDiscountDialog(
        item: WalkInLineItem(
          description: product.designId,
          quantity: product.quantity,
          unitPricePaise: _parseCurrencyToPaise(product.price),
          gstPercent: product.gstPercent,
          gstCalculationType: product.gstCalculationType,
          discountPaise: product.discountValue ?? 0,
          discountType: product.discountType,
          discountValue: product.discountValue,
          source: product.source,
        ),
        lineSubtotalPaise: lineSubtotal,
        currencySymbol: _fiscalProfile.currencySymbol,
      ),
    );

    if (result != null && mounted) {
      final discountType = result['discountType'] as String?;
      final discountValue = result['discountValue'] as int?;

      setState(() {
        _products[index] = product.copyWith(
          discountType: discountType,
          discountValue: discountValue,
          discount: discountType != null && discountValue != null
              ? DiscountService.getDiscountDisplayText(
                  discountType: discountType,
                  discountValue: discountValue,
                )
              : null,
        );
      });
    }
  }

  Future<void> _saveOrder() async {
    if (_isOrderSaved) {
      final orderId = _savedOrderId;
      if (orderId != null) await _showCompletionDialog(orderId);
      return;
    }

    final custName = _customerNameController.text.trim();
    final custPhone = _phoneController.text.trim();
    if (custName.isEmpty && custPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter customer name or phone number.')),
      );
      return;
    }

    if (_eventDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the Event Date.')),
      );
      return;
    }

    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product or service.')),
      );
      return;
    }

    final advancePaise = _resolvedAdvancePaidPaise;
    final grandTotal = _totalAmountPaise;
    if (advancePaise > grandTotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Advance payment cannot exceed the total amount.')),
      );
      return;
    }

    _syncProviderSession();
    final provider = context.read<WalkInSessionProvider>();

    if (_isEditingOrder) {
      final updated = await provider.updateExistingOrder(widget.editingOrderId!);
      if (!mounted) return;
      if (!updated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Could not update event order.')),
        );
        return;
      }

      if (!kIsWeb) {
        final inventoryRepo = InventoryRepository();
        await inventoryRepo.releaseActiveReservationsForOrder(widget.editingOrderId!);
        for (final product in _products) {
          if (product.productId != null && product.reservedQty > 0) {
            await inventoryRepo.reserveStock(
              orderId: widget.editingOrderId!,
              productId: product.productId!,
              cloudProductId: product.cloudProductId,
              quantity: product.reservedQty,
              eventDate: _eventDate != null
                  ? '${_eventDate!.year}-${_eventDate!.month.toString().padLeft(2, '0')}-${_eventDate!.day.toString().padLeft(2, '0')}'
                  : null,
              eventName: '$_resolvedOccasion (${_customerNameController.text.trim().isNotEmpty ? _customerNameController.text.trim() : 'Walk-in'})',
              notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
            );
          }
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event order updated successfully.')),
      );
      Navigator.pop(context);
      return;
    }

    final orderId = await provider.confirmOrder();
    if (!mounted) return;

    if (orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Could not create event order.')),
      );
      return;
    }

    if (!kIsWeb) {
      final inventoryRepo = InventoryRepository();
      for (final product in _products) {
        if (product.productId != null && product.reservedQty > 0) {
          await inventoryRepo.reserveStock(
            orderId: orderId,
            productId: product.productId!,
            cloudProductId: product.cloudProductId,
            quantity: product.reservedQty,
            eventDate: _eventDate != null
                ? '${_eventDate!.year}-${_eventDate!.month.toString().padLeft(2, '0')}-${_eventDate!.day.toString().padLeft(2, '0')}'
                : null,
            eventName: '$_resolvedOccasion (${_customerNameController.text.trim().isNotEmpty ? _customerNameController.text.trim() : 'Walk-in'})',
            notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
          );
        }
      }
    }

    setState(() {
      _isOrderSaved = true;
      _savedOrderId = orderId;
    });

    final outstanding = _outstandingBalancePaise;
    if (outstanding > 0) {
      await _promptScheduleFollowUp(orderId, outstanding);
    }

    if (mounted) {
      await _showCompletionDialog(orderId);
    }
  }

  Future<void> _promptScheduleFollowUp(int orderId, int outstandingPaise) async {
    final prompt = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule Payment Follow-up?'),
        content: Text(
          'An outstanding balance of ${_formatPaise(context, outstandingPaise)} remains for this event.\n\n'
          'Would you like to schedule a payment follow-up reminder now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Schedule Follow-up'),
          ),
        ],
      ),
    );

    if (prompt == true && mounted) {
      await showSchedulePaymentFollowUpDialog(
        context: context,
        orderId: orderId,
        orderNo: 'ORD-$orderId',
        customerName: _customerNameController.text.trim().isNotEmpty
            ? _customerNameController.text.trim()
            : 'Walk-in Customer',
        outstandingAmountPaise: outstandingPaise,
      );
    }
  }

  Future<void> _showCompletionDialog(int orderId) {
    final rewardFuture =
        context.read<WalkInSessionProvider>().getOrderRewardSummary(orderId);
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF16A34A)),
            SizedBox(width: 8),
            Text('Event Order Confirmed'),
          ],
        ),
        content: FutureBuilder<OrderRewardSummary?>(
          future: rewardFuture,
          builder: (context, snapshot) {
            final summary = snapshot.data;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order #$orderId created successfully.'),
                const SizedBox(height: 8),
                Text('Event: $_resolvedOccasion'),
                if (_eventDate != null)
                  Text('Date: ${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year}'),
                if (_venueController.text.isNotEmpty)
                  Text('Venue: ${_venueController.text}'),
                const SizedBox(height: 8),
                Text('Total: ${_formatPaise(context, _totalAmountPaise)}'),
                Text('Paid: ${_formatPaise(context, _resolvedAdvancePaidPaise)}'),
                if (_outstandingBalancePaise > 0)
                  Text(
                    'Outstanding: ${_formatPaise(context, _outstandingBalancePaise)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                  ),
                if (summary != null && summary.hasActivity) ...[
                  const SizedBox(height: 12),
                  RewardSummaryCard(summary: summary, compact: true),
                ],
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetForNextOrder();
            },
            child: const Text('Done'),
          ),
          OutlinedButton.icon(
            onPressed: () => _printBill(context, orderId),
            icon: const Icon(Icons.print, size: 18),
            label: const Text('Print Receipt'),
          ),
          OutlinedButton.icon(
            onPressed: () => _downloadBillPdf(context, orderId),
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: const Text('Download PDF'),
          ),
          OutlinedButton.icon(
            onPressed: () => _shareWhatsApp(context, orderId),
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Share WhatsApp'),
          ),
        ],
      ),
    );
  }

  void _resetForNextOrder() {
    FocusManager.instance.primaryFocus?.unfocus();
    context.read<WalkInSessionProvider>().patchSession(
          WalkInSession.empty(_fulfilmentType),
        );
    setState(() {
      _products.clear();
      _phoneController.clear();
      _customerNameController.clear();
      _customEventTypeController.clear();
      _venueController.clear();
      _notesController.clear();
      _advanceAmountController.clear();
      _selectedEventType = 'Wedding';
      _eventDate = null;
      _eventTime = null;
      _paymentOption = EventPaymentOption.fullPayment;
      _selectedTenderMethod = 'UPI';
      _customerInfo = null;
      _billDiscountType = null;
      _billDiscountValue = null;
      _rewardPointsRedeemed = 0;
      _rewardDiscountAmountPaise = 0;
      _isOrderSaved = false;
      _savedOrderId = null;
    });
  }

  Future<void> _saveDraft() async {
    _syncProviderSession();
    final provider = context.read<WalkInSessionProvider>();
    await provider.saveDraft();
    if (!mounted) return;
    if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!)),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event Sale draft saved successfully.')),
    );
  }

  // --- PRINT / PDF / WHATSAPP ---

  List<Map<String, dynamic>> _printItems() {
    return _products.map((product) {
      final unitPaise = _parseCurrencyToPaise(product.price);
      final lineSubtotal = unitPaise * product.quantity;
      final lineDiscount =
          product.discountType != null && product.discountValue != null
              ? DiscountService.calculateLineDiscount(
                  lineSubtotalPaise: lineSubtotal,
                  discountType: product.discountType!,
                  discountValue: product.discountValue!,
                )
              : 0;
      return {
        'name': product.designId,
        'qty': product.quantity,
        'ratePaise': unitPaise,
        'totalPaise': lineSubtotal - lineDiscount,
      };
    }).toList();
  }

  Future<void> _printBill(BuildContext context, [int? orderId]) async {
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item.')),
      );
      return;
    }

    final printerProvider = context.read<PrinterProvider>();
    final payments = _buildPaymentSplits();
    final paidPaise = _resolvedAdvancePaidPaise;
    final outstandingPaise = _outstandingBalancePaise;
    final rewardSummary = (orderId == null || kIsWeb)
        ? null
        : await context
            .read<WalkInSessionProvider>()
            .getOrderRewardSummary(orderId);
    await printerProvider.enqueuePosBill({
      'invoiceNumber': orderId?.toString() ?? 'Draft',
      'dateTime': DateTime.now().toString().split('.').first,
      'customerName': _customerNameController.text.trim(),
      'customerPhone': _phoneController.text.trim(),
      'items': _printItems(),
      'basicAmountPaise': _subtotalPaise,
      'discountPaise': _billDiscountPaise,
      'gstPaise': _gstAmountPaise,
      'taxLabel': '${_fiscalProfile.taxLabel} Amount',
      'roundOffPaise': _orderTotals.roundOffPaise,
      'grandTotalPaise': _totalAmountPaise,
      'paymentMode': _paymentOption == EventPaymentOption.payLater
          ? 'Credit'
          : _selectedTenderMethod,
      'paymentSummary': payments
          .map(
            (payment) => {
              'method': _displayPaymentMethodLabel(payment),
              'amountPaise': payment.amountPaise,
              'isCredit': payment.isCreditOutstanding,
            },
          )
          .toList(growable: false),
      'paidPaise': paidPaise,
      'outstandingPaise': outstandingPaise,
      if (rewardSummary != null && rewardSummary.hasActivity) ...{
        'rewardOpeningBalance': rewardSummary.openingBalance,
        'rewardPointsEarned': rewardSummary.earnedPoints,
        'rewardPointsRedeemed': rewardSummary.redeemedPoints,
        'rewardClosingBalance': rewardSummary.closingBalance,
        'rewardValuePaise': rewardSummary.rewardValuePaise,
      },
    });
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          printerProvider.error ??
              (kIsWeb
                  ? 'Receipt sent to printer.'
                  : 'Receipt queued for printing.'),
        ),
      ),
    );
  }

  Future<void> _downloadBillPdf(BuildContext context, [int? orderId]) async {
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item.')),
      );
      return;
    }

    final payments = _buildPaymentSplits();
    final paidPaise = _resolvedAdvancePaidPaise;
    final outstandingPaise = _outstandingBalancePaise;
    final payload = {
      'invoiceNumber': orderId?.toString() ?? 'Draft',
      'dateTime': DateTime.now().toString().split('.').first,
      'customerName': _customerNameController.text.trim(),
      'customerPhone': _phoneController.text.trim(),
      'items': _printItems(),
      'basicAmountPaise': _subtotalPaise,
      'discountPaise': _billDiscountPaise,
      'gstPaise': _gstAmountPaise,
      'taxLabel': '${_fiscalProfile.taxLabel} Amount',
      'roundOffPaise': _orderTotals.roundOffPaise,
      'grandTotalPaise': _totalAmountPaise,
      'paymentMode': _paymentOption == EventPaymentOption.payLater
          ? 'Credit'
          : _selectedTenderMethod,
      'paymentSummary': payments
          .map(
            (payment) => {
              'method': _displayPaymentMethodLabel(payment),
              'amountPaise': payment.amountPaise,
              'isCredit': payment.isCreditOutstanding,
            },
          )
          .toList(growable: false),
      'paidPaise': paidPaise,
      'outstandingPaise': outstandingPaise,
    };

    await PdfDocumentService().downloadOrShareBillPdfFromPayload(
      context: context,
      payload: payload,
    );
  }

  Future<void> _shareWhatsApp(BuildContext context, int orderId) async {
    final messenger = ScaffoldMessenger.of(context);
    final normalizedPhone = WhatsAppPhoneUtils.normalize(_phoneController.text);
    if (normalizedPhone == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Customer mobile number is required for WhatsApp.'),
        ),
      );
      return;
    }

    final rewardSummary =
        await context.read<WalkInSessionProvider>().getOrderRewardSummary(orderId);
    final text = _buildPrintContent(orderId, rewardSummary);
    final uri = WhatsAppPhoneUtils.buildUri(normalizedPhone, message: text);
    final fallback = WhatsAppPhoneUtils.buildFallbackUri(normalizedPhone, message: text);

    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (fallback != null && await canLaunchUrl(fallback)) {
      await launchUrl(fallback, mode: LaunchMode.externalApplication);
      return;
    }

    messenger.showSnackBar(
      const SnackBar(content: Text('Could not launch WhatsApp.')),
    );
  }

  String _buildPrintContent(int orderId, OrderRewardSummary? rewardSummary) {
    final lines = [
      _shopName.isNotEmpty ? _shopName : 'Floraprise Florist',
      if (_businessPhone.isNotEmpty) 'Phone: $_businessPhone',
      'Event / Decoration Order #$orderId',
      'Event: $_resolvedOccasion',
      if (_eventDate != null) 'Date: ${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year}',
      if (_venueController.text.isNotEmpty) 'Venue: ${_venueController.text}',
      'Customer: ${_customerNameController.text.trim()}',
      '',
      'Items:',
      ..._products.map((item) => '- ${item.designId} x${item.quantity} (${item.price})'),
      '',
      'Subtotal: ${_formatPaise(context, _subtotalPaise)}',
      if (_fiscalProfile.taxEnabled && _gstAmountPaise > 0)
        '${_fiscalProfile.taxLabel}: ${_formatPaise(context, _gstAmountPaise)}',
      'Grand Total: ${_formatPaise(context, _totalAmountPaise)}',
      'Paid Advance: ${_formatPaise(context, _resolvedAdvancePaidPaise)}',
      if (_outstandingBalancePaise > 0)
        'Outstanding: ${_formatPaise(context, _outstandingBalancePaise)}',
      buildRewardWhatsAppText(rewardSummary),
    ];
    return lines.where((l) => l.trim().isNotEmpty).join('\n');
  }

  String _displayPaymentMethodLabel(PaymentSplit payment) {
    switch (payment.persistenceMethod.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'upi':
        return 'UPI';
      case 'card':
        return 'Card';
      case 'bank_transfer':
      case 'bank':
        return 'Bank Transfer';
      case 'cheque':
        return 'Cheque';
      case 'credit':
        return 'Credit (Outstanding)';
      default:
        return payment.persistenceMethod;
    }
  }

  String _formatPaise(BuildContext context, int paise) {
    return LocaleFormatter.formatCurrency(context, paise);
  }

  int _parseCurrencyToPaise(String text) {
    final cleaned = text
        .replaceAll(_fiscalProfile.currencySymbol, '')
        .replaceAll('₹', '')
        .replaceAll(',', '')
        .trim();
    final rupees = double.tryParse(cleaned) ?? 0;
    return (rupees * 100).round();
  }

  String _paymentToLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.bank:
        return 'Bank Transfer';
      default:
        return 'Other';
    }
  }

  PaymentMethod _labelToPaymentMethod(String label) {
    switch (label) {
      case 'Cash':
        return PaymentMethod.cash;
      case 'UPI':
        return PaymentMethod.upi;
      case 'Card':
        return PaymentMethod.card;
      case 'Bank Transfer':
        return PaymentMethod.bank;
      default:
        return PaymentMethod.upi;
    }
  }

  String _paymentToCode(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.upi:
        return 'upi';
      case PaymentMethod.card:
        return 'card';
      case PaymentMethod.bank:
        return 'bank_transfer';
      default:
        return 'upi';
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return 'N/A';
    }
  }
}

class _ProductItem {
  final int? productId;
  final String? cloudProductId;
  final bool trackInventory;
  final String designId;
  final int quantity;
  final int reservedQty;
  final String price;
  final String unit;
  final String? discount;
  final String? discountType;
  final int? discountValue;
  final int? gstPercent;
  final GstCalculationType? gstCalculationType;
  final String source;
  final String? attachmentPath;

  _ProductItem({
    this.productId,
    this.cloudProductId,
    this.trackInventory = false,
    required this.designId,
    required this.quantity,
    this.reservedQty = 0,
    required this.price,
    this.discount,
    this.discountType,
    this.discountValue,
    this.unit = 'Piece',
    this.gstPercent,
    this.gstCalculationType,
    this.source = 'manual',
    this.attachmentPath,
  });

  int get stillToArrange => (quantity - reservedQty).clamp(0, quantity);

  _ProductItem copyWith({
    int? quantity,
    int? reservedQty,
    String? discount,
    String? discountType,
    int? discountValue,
  }) {
    return _ProductItem(
      productId: productId,
      cloudProductId: cloudProductId,
      trackInventory: trackInventory,
      designId: designId,
      quantity: quantity ?? this.quantity,
      reservedQty: reservedQty ?? this.reservedQty,
      price: price,
      unit: unit,
      discount: discount ?? this.discount,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      gstPercent: gstPercent,
      gstCalculationType: gstCalculationType,
      source: source,
      attachmentPath: attachmentPath,
    );
  }
}

class _CustomerInfo {
  final int previousOrders;
  final String lifetimePurchase;
  final String lastOrder;
  final String favouriteDesign;
  final int rewardPoints;

  _CustomerInfo({
    required this.previousOrders,
    required this.lifetimePurchase,
    required this.lastOrder,
    required this.favouriteDesign,
    required this.rewardPoints,
  });
}
