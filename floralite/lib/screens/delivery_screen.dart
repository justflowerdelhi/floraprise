import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/voice_dictation_controller.dart';
import '../l10n/app_localizations.dart';
import '../managers/business_settings_manager.dart';
import '../managers/pricing_manager.dart';
import '../data/repositories/customer_repository.dart';
import '../data/repositories/order_repository.dart';
import '../data/repositories/product_repository.dart';
import '../models/gst_calculation_type.dart';
import '../models/order_workspace_models.dart';
import '../models/payment_split.dart';
import '../models/walk_in_enums.dart';
import '../models/walk_in_line_item.dart';
import '../models/walk_in_session.dart';
import '../providers/design_provider.dart';
import '../providers/printer_provider.dart';
import '../providers/walk_in_session_provider.dart';
import '../services/discount_service.dart';
import '../services/reward_summary_formatter.dart';
import '../services/speech_recognition_service.dart';
import '../utils/delivery_slot_utils.dart';
import '../utils/locale_formatter.dart';
import '../widgets/app_header.dart';
import '../widgets/bill_discount_dialog.dart';
import '../widgets/camera_barcode_scanner_page.dart';
import '../widgets/common_widgets.dart';
import '../widgets/line_item_discount_dialog.dart';
import '../widgets/product_picker_sheet.dart';
import '../widgets/quantity_input_stepper.dart';
import '../widgets/reward_summary_card.dart';
import '../widgets/voice_dictation_field_header.dart';
import 'my_designs_screen.dart';

enum _UnsavedChangesAction { saveDraft, discard, cancel }

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({
    super.key,
    this.prefillCustomerId,
    this.prefillCustomerName,
    this.prefillCustomerPhone,
    this.prefillRecipientName,
    this.prefillOccasion,
    this.initialSession,
    this.editingOrderId,
  });

  final int? prefillCustomerId;
  final String? prefillCustomerName;
  final String? prefillCustomerPhone;
  final String? prefillRecipientName;
  final String? prefillOccasion;
  final WalkInSession? initialSession;
  final int? editingOrderId;

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  static const FulfilmentType _fulfilmentType = FulfilmentType.delivery;
  static const String _deliveryChargeSource = 'delivery_charge';

  final BusinessSettingsManager _businessSettingsManager =
      BusinessSettingsManager();
  final PricingManager _pricingManager = PricingManager();
  final CustomerRepository _customerRepository = CustomerRepository();
  final ProductRepository _productRepository = ProductRepository();
  final List<_ProductItem> _products = [];
  final TextEditingController _customerPhoneController =
      TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _recipientPhoneController =
      TextEditingController();
  final TextEditingController _recipientNameController =
      TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final FocusNode _addressFocusNode = FocusNode();
  final TextEditingController _pinCodeController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _cardMessageController = TextEditingController();
  final FocusNode _cardMessageFocusNode = FocusNode();
  final TextEditingController _specialInstructionsController =
      TextEditingController();
  final FocusNode _specialInstructionsFocusNode = FocusNode();
  final VoiceDictationController _addressDictationController =
      VoiceDictationController(
    speechRecognition: SpeechRecognitionService(),
  );
  final VoiceDictationController _cardMessageDictationController =
      VoiceDictationController(
    speechRecognition: SpeechRecognitionService(),
  );
  final VoiceDictationController _specialInstructionsDictationController =
      VoiceDictationController(
    speechRecognition: SpeechRecognitionService(),
  );
  final TextEditingController _deliveryChargeController =
      TextEditingController();
  final TextEditingController _senderPhoneController = TextEditingController();
  final TextEditingController _senderNameController = TextEditingController();
  final TextEditingController _amountReceivedController =
      TextEditingController();
  String _paymentStatus = 'Paid';
  String? _selectedPayment;
  DateTime? _deliveryDate;
  String? _selectedDeliverySlot;
  TimeOfDay? _customDeliveryTime;
  _CustomerInfo? _customerInfo;
  bool _senderSameAsCustomer = true;
  bool _gstRegistered = true;
  int _defaultDeliveryChargePaise = 0;
  int _minimumPreparationBufferMinutes = 60;
  String _shopName = 'My Flower Shop';
  String _businessPhone = '';
  String _businessAddress = '';
  String? _billDiscountType;
  int? _billDiscountValue;
  int _rewardPointsRedeemed = 0;
  int _rewardDiscountAmountPaise = 0;
  bool _isOrderSaved = false;
  int? _savedOrderId;

  @override
  void initState() {
    super.initState();

    _addressDictationController.bindController(
      _addressController,
      focusNode: _addressFocusNode,
    );
    _cardMessageDictationController.bindController(
      _cardMessageController,
      focusNode: _cardMessageFocusNode,
    );
    _specialInstructionsDictationController.bindController(
      _specialInstructionsController,
      focusNode: _specialInstructionsFocusNode,
    );

    // Prefill data if provided
    if (widget.prefillCustomerPhone != null) {
      _customerPhoneController.text = widget.prefillCustomerPhone!;
      _senderPhoneController.text = widget.prefillCustomerPhone!;
    }
    if (widget.prefillCustomerName != null) {
      _customerNameController.text = widget.prefillCustomerName!;
      _senderNameController.text = widget.prefillCustomerName!;
    }
    if (widget.prefillOccasion != null) {
      // Delivery screen may not have an occasion field, but we can store it
      // For now, we'll skip this as delivery screen structure is different
    }
    if (widget.prefillRecipientName != null) {
      _recipientNameController.text = widget.prefillRecipientName!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBusinessSettings();
      _loadDraftSession();
    });
  }

  bool get _isEditingOrder => widget.editingOrderId != null;

  Future<void> _loadBusinessSettings() async {
    final settings = await _businessSettingsManager.load();
    if (!mounted) return;

    setState(() {
      _gstRegistered = settings.gstRegistered;
      _defaultDeliveryChargePaise = settings.defaultDeliveryChargePaise;
      _minimumPreparationBufferMinutes =
          settings.minimumPreparationBufferMinutes;
      _shopName = settings.shopName;
      _businessPhone = settings.phone;
      _businessAddress = settings.address;
      if (_deliveryChargeController.text.trim().isEmpty) {
        _deliveryChargeController.text =
            (_defaultDeliveryChargePaise / 100).toStringAsFixed(0);
      }
      _upsertDeliveryChargeLine();
    });
  }

  @override
  void dispose() {
    _recipientPhoneController.dispose();
    _recipientNameController.dispose();
    _addressFocusNode.dispose();
    _addressController.dispose();
    _pinCodeController.dispose();
    _landmarkController.dispose();
    _cardMessageFocusNode.dispose();
    _cardMessageController.dispose();
    _specialInstructionsFocusNode.dispose();
    _specialInstructionsController.dispose();
    _addressDictationController.dispose();
    _cardMessageDictationController.dispose();
    _specialInstructionsDictationController.dispose();
    _deliveryChargeController.dispose();
    _customerPhoneController.dispose();
    _customerNameController.dispose();
    _senderPhoneController.dispose();
    _senderNameController.dispose();
    _amountReceivedController.dispose();
    super.dispose();
  }

  int get _subtotalPaise {
    return _orderTotals.subtotalPaise;
  }

  int get _gstAmountPaise {
    return _orderTotals.gstTotalPaise;
  }

  int get _totalAmountPaise {
    return _orderTotals.grandTotalPaise;
  }

  OrderTotals get _orderTotals => _pricingManager.computeTotals(
        lines: _walkInLines,
        billDiscountType: _billDiscountType,
        billDiscountValue: _billDiscountValue,
        rewardDiscountPaise: _rewardDiscountAmountPaise,
      );

  List<WalkInLineItem> get _walkInLines => _products
      .map(
        (product) => WalkInLineItem(
          productId: product.trackInventory ? product.productId : null,
          description: product.designId,
          quantity: product.quantity,
          unitPricePaise: _parseCurrencyToPaise(product.price),
          discountPaise: product.discountValue ?? 0,
          discountType: product.discountType,
          discountValue: product.discountValue,
          gstPercent: _gstRegistered ? product.gstPercent : 0,
          gstCalculationType: product.gstCalculationType,
          source: product.source,
        ),
      )
      .toList();

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
            ),
          ),
        );

      _customerPhoneController.text = activeSession.customerPhone;
      _customerNameController.text = activeSession.customerName;
      if (_senderSameAsCustomer) {
        _senderPhoneController.text = activeSession.customerPhone;
        _senderNameController.text = activeSession.customerName;
      }
      _recipientNameController.text = activeSession.recipientName;
      _recipientPhoneController.text = activeSession.recipientPhone;
      _addressController.text = activeSession.deliveryAddress;
      _pinCodeController.text = activeSession.deliveryPincode;
      _landmarkController.text = activeSession.deliveryLandmark;
      _cardMessageController.text = activeSession.cardMessage;
      _specialInstructionsController.text = activeSession.specialInstructions;
      _deliveryDate = activeSession.scheduledAt;
      _billDiscountType = activeSession.billDiscountType;
      _billDiscountValue = activeSession.billDiscountValue;
      if (activeSession.deliverySlot.startsWith('custom_')) {
        _selectedDeliverySlot = 'custom';
        final raw = activeSession.deliverySlot.replaceFirst('custom_', '');
        final parts = raw.split(':');
        if (parts.length == 2) {
          final hour = int.tryParse(parts[0]);
          final minute = int.tryParse(parts[1]);
          if (hour != null && minute != null) {
            _customDeliveryTime = TimeOfDay(hour: hour, minute: minute);
          }
        }
      } else {
        _selectedDeliverySlot = activeSession.deliverySlot.trim().isEmpty
            ? _inferSlotFromDateTime(activeSession.scheduledAt)
            : activeSession.deliverySlot;
      }
      if (_selectedDeliverySlot == 'custom' &&
          activeSession.scheduledAt != null) {
        _customDeliveryTime =
            TimeOfDay.fromDateTime(activeSession.scheduledAt!);
      }

      final chargeLine =
          _products.where((item) => item.source == _deliveryChargeSource);
      if (chargeLine.isNotEmpty) {
        _deliveryChargeController.text = chargeLine.first.price
            .replaceAll('₹', '')
            .replaceAll(',', '')
            .trim();
      } else if (_deliveryChargeController.text.trim().isEmpty) {
        _deliveryChargeController.text =
            (_defaultDeliveryChargePaise / 100).toStringAsFixed(0);
        _upsertDeliveryChargeLine();
      }

      final receivedPaise = activeSession.payments.fold<int>(
        0,
        (sum, payment) => sum + payment.amountPaise,
      );
      if (receivedPaise <= 0) {
        _paymentStatus = 'Pending';
        _selectedPayment = null;
        _amountReceivedController.text = '0';
      } else if (receivedPaise < _totalAmountPaise) {
        _paymentStatus = 'Partial';
        _selectedPayment = _paymentToLabel(activeSession.payments.first);
        _amountReceivedController.text =
            (receivedPaise / 100).toStringAsFixed(2);
      } else {
        _paymentStatus = 'Paid';
        _selectedPayment = _paymentToLabel(activeSession.payments.first);
        _amountReceivedController.text =
            (_totalAmountPaise / 100).toStringAsFixed(2);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackWithUnsavedChanges();
      },
      child: Scaffold(
        appBar: AppHeader(
          title: l10n.delivery,
          showBackButton: true,
          actions: [
            TextButton(
              onPressed: _isOrderSaved
                  ? null
                  : _isEditingOrder
                      ? _saveOrder
                      : _saveDraft,
              child: Text(_isEditingOrder ? 'Save Changes' : l10n.saveDraft),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductSection(colorScheme, l10n),
                    const SizedBox(height: 8),
                    _buildCustomerSection(colorScheme, l10n),
                    const SizedBox(height: 8),
                    _buildDeliveryInfoSection(colorScheme, l10n),
                    const SizedBox(height: 8),
                    _buildSenderSection(colorScheme, l10n),
                    const SizedBox(height: 8),
                    _buildPaymentSection(colorScheme, l10n),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            _buildBottomSummary(colorScheme, l10n),
          ],
        ),
      ),
    );
  }

  bool get _hasUnsavedChanges {
    if (_isEditingOrder || _isOrderSaved) return false;
    final hasRealProducts = _products.any(
      (item) => item.source != _deliveryChargeSource,
    );
    return hasRealProducts ||
        _customerPhoneController.text.trim().isNotEmpty ||
        _customerNameController.text.trim().isNotEmpty ||
        _recipientPhoneController.text.trim().isNotEmpty ||
        _recipientNameController.text.trim().isNotEmpty ||
        _addressController.text.trim().isNotEmpty ||
        _pinCodeController.text.trim().isNotEmpty ||
        _landmarkController.text.trim().isNotEmpty ||
        _cardMessageController.text.trim().isNotEmpty ||
        _specialInstructionsController.text.trim().isNotEmpty ||
        _senderPhoneController.text.trim().isNotEmpty ||
        _senderNameController.text.trim().isNotEmpty ||
        _deliveryDate != null ||
        _selectedDeliverySlot != null ||
        _customDeliveryTime != null ||
        _selectedPayment != null ||
        _billDiscountType != null ||
        _billDiscountValue != null;
  }

  Future<void> _handleBackWithUnsavedChanges() async {
    final l10n = AppLocalizations.of(context)!;
    final action = await showDialog<_UnsavedChangesAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.unsavedChangesTitle),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, _UnsavedChangesAction.cancel),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, _UnsavedChangesAction.discard),
            child: Text(l10n.discard),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, _UnsavedChangesAction.saveDraft),
            child: Text(l10n.saveDraft),
          ),
        ],
      ),
    );
    if (!mounted || action == null || action == _UnsavedChangesAction.cancel) {
      return;
    }
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

  Widget _buildProductSection(ColorScheme colorScheme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.products,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ..._products.asMap().entries.map((entry) {
          final index = entry.key;
          final product = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product.attachmentPath != null &&
                          product.attachmentPath!.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(product.attachmentPath!),
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 52,
                                height: 52,
                                color: Colors.grey.shade200,
                                alignment: Alignment.center,
                                child: const Icon(Icons.image_not_supported),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.designId,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _quantityUnitLabel(product),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            if (product.discount != null &&
                                product.discount!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${l10n.discountLabel}${product.discount}',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18),
                        onSelected: (value) async {
                          if (value == 'discount') {
                            await _showLineItemDiscountDialog(index);
                          } else if (value == 'remove') {
                            setState(() {
                              final removed = _products.removeAt(index);
                              if (removed.source == _deliveryChargeSource) {
                                _deliveryChargeController.text = '0';
                              }
                            });
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'discount',
                            child: Row(
                              children: [
                                const Icon(Icons.discount, size: 18),
                                const SizedBox(width: 8),
                                Text(l10n.discount),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'remove',
                            child: Row(
                              children: [
                                const Icon(Icons.delete,
                                    size: 18, color: Colors.red),
                                const SizedBox(width: 8),
                                Text(l10n.remove,
                                    style: const TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuantitySelector(product, index),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        product.price,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${l10n.rate} ${product.price}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        'Amount ${_formatPaise(context, _parseCurrencyToPaise(product.price) * product.quantity)}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (product.discount != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          l10n.discountLabel,
                          style: const TextStyle(fontSize: 11),
                        ),
                        Text(
                          product.discount!,
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showAddProductOptions(context),
                icon: const Icon(Icons.add),
                label: Text(
                  _products.isEmpty
                      ? l10n.addProductToCart
                      : l10n.addAnotherProduct,
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showBarcodeScanner(context),
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(l10n.scanBarcode),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuantitySelector(_ProductItem product, int index) {
    return QuantityInputStepper(
      value: product.quantity,
      min: 1,
      onChanged: (quantity) {
        setState(() {
          _products[index] = product.copyWith(quantity: quantity);
        });
      },
    );
  }

  Widget _buildDeliveryInfoSection(
      ColorScheme colorScheme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.deliveryInfo,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        AppCard(
          child: Column(
            children: [
              TextField(
                controller: _recipientNameController,
                decoration: InputDecoration(
                  labelText: l10n.recipientName,
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _recipientPhoneController,
                decoration: InputDecoration(
                  labelText: l10n.recipientPhone,
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
              ),
              const SizedBox(height: 8),
              VoiceDictationFieldHeader(
                label: l10n.address,
                controller: _addressDictationController,
              ),
              TextField(
                focusNode: _addressFocusNode,
                controller: _addressController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _pinCodeController,
                decoration: InputDecoration(
                  labelText: l10n.pinCode,
                  prefixIcon: const Icon(Icons.pin_drop),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _landmarkController,
                decoration: InputDecoration(
                  labelText: '${l10n.landmark} (${l10n.optional})',
                  prefixIcon: const Icon(Icons.near_me),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                leading: Icon(Icons.calendar_today,
                    color: colorScheme.primary, size: 20),
                title: Text(
                  _deliveryDate != null
                      ? '${_deliveryDate!.day}/${_deliveryDate!.month}/${_deliveryDate!.year}'
                      : l10n.deliveryDate,
                  style: const TextStyle(fontSize: 14),
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => _selectDeliveryDate(context),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                leading: Icon(Icons.access_time,
                    color: colorScheme.primary, size: 20),
                title: Text(
                  _selectedDeliverySlot == null
                      ? l10n.deliveryTime
                      : _deliverySlotDisplay(_selectedDeliverySlot!),
                  style: const TextStyle(fontSize: 14),
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => _selectDeliverySlot(context),
              ),
              if (_selectedDeliverySlot == 'custom')
                Column(
                  children: [
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      leading: Icon(Icons.schedule,
                          color: colorScheme.primary, size: 20),
                      title: Text(
                        _customDeliveryTime == null
                            ? l10n.selectCustomTime
                            : '${_customDeliveryTime!.hour}:${_customDeliveryTime!.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => _selectCustomDeliveryTime(context),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              TextField(
                controller: _deliveryChargeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.deliveryCharge,
                  prefixIcon: const Icon(Icons.local_shipping),
                  prefixText: '₹',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                ),
                onChanged: (_) {
                  setState(_upsertDeliveryChargeLine);
                },
              ),
              const SizedBox(height: 8),
              VoiceDictationFieldHeader(
                label: l10n.cardMessage,
                controller: _cardMessageDictationController,
              ),
              TextField(
                focusNode: _cardMessageFocusNode,
                controller: _cardMessageController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.card_giftcard),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              VoiceDictationFieldHeader(
                label: '${l10n.specialInstructions} (${l10n.optional})',
                controller: _specialInstructionsDictationController,
              ),
              TextField(
                focusNode: _specialInstructionsFocusNode,
                controller: _specialInstructionsController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerSection(ColorScheme colorScheme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.customerBuyer,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        AppCard(
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showCustomerSearch,
                  icon: const Icon(Icons.search),
                  label: Text(l10n.searchCustomer),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _customerNameController,
                decoration: InputDecoration(
                  labelText: l10n.name,
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                ),
                onChanged: (_) => _syncSenderFromCustomerIfNeeded(),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _customerPhoneController,
                decoration: InputDecoration(
                  labelText: l10n.phoneNumber,
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  _syncSenderFromCustomerIfNeeded();
                  if (value.length >= 10) _lookupCustomer(value);
                },
              ),
              if (_customerInfo != null) ...[
                const SizedBox(height: 8),
                _buildCustomerSummaryCard(colorScheme),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerSummaryCard(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _customerNameController.text.trim(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
              '${AppLocalizations.of(context)!.phone}: ${_customerPhoneController.text.trim()}'),
          const SizedBox(height: 8),
          _buildCustomerInfoRow(AppLocalizations.of(context)!.purchaseHistory,
              '${_customerInfo!.previousOrders} ${AppLocalizations.of(context)!.orders}'),
          _buildCustomerInfoRow(AppLocalizations.of(context)!.lifetimePurchase,
              _customerInfo!.lifetimePurchase),
          _buildCustomerInfoRow(AppLocalizations.of(context)!.lastOrder,
              _customerInfo!.lastOrder),
          _buildCustomerInfoRow(
              'Reward Balance', '${_customerInfo!.rewardPoints} Points'),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _products.isEmpty || _customerInfo!.rewardPoints <= 0
                  ? null
                  : _applyMaximumRewards,
              icon: const Icon(Icons.redeem, size: 18),
              label: Text(_rewardPointsRedeemed > 0
                  ? 'Using $_rewardPointsRedeemed Points'
                  : 'Use Reward Points'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSenderSection(ColorScheme colorScheme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.senderInfo,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        AppCard(
          child: Column(
            children: [
              CheckboxListTile(
                value: _senderSameAsCustomer,
                onChanged: (value) {
                  setState(() {
                    _senderSameAsCustomer = value ?? true;
                    _syncSenderFromCustomerIfNeeded();
                  });
                },
                title: Text(l10n.senderSameAsCustomer),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              TextField(
                controller: _senderNameController,
                readOnly: _senderSameAsCustomer,
                decoration: InputDecoration(
                  labelText: l10n.senderName,
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _senderPhoneController,
                readOnly: _senderSameAsCustomer,
                decoration: InputDecoration(
                  labelText: l10n.senderPhone,
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(ColorScheme colorScheme, AppLocalizations l10n) {
    final receivedPaise = _paymentStatus == 'Paid'
        ? _totalAmountPaise
        : _paymentStatus == 'Pending'
            ? 0
            : _parseCurrencyToPaise(_amountReceivedController.text);
    final balancePaise = (_totalAmountPaise - receivedPaise).clamp(
      0,
      _totalAmountPaise,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.payment,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _paymentStatus,
                decoration: InputDecoration(labelText: l10n.paymentStatus),
                items: [
                  DropdownMenuItem(value: 'Paid', child: Text(l10n.paid)),
                  DropdownMenuItem(value: 'Partial', child: Text(l10n.partial)),
                  DropdownMenuItem(value: 'Pending', child: Text(l10n.pending)),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _paymentStatus = value;
                    if (value == 'Paid') {
                      _amountReceivedController.text =
                          (_totalAmountPaise / 100).toStringAsFixed(2);
                    } else if (value == 'Pending') {
                      _amountReceivedController.text = '0';
                    }
                  });
                },
              ),
              if (_paymentStatus != 'Pending') ...[
                const SizedBox(height: 12),
                Text(
                  l10n.paymentMode,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildPaymentChip(l10n.cash, Icons.payments, colorScheme),
                    _buildPaymentChip(
                        l10n.upi, Icons.qr_code_scanner, colorScheme),
                    _buildPaymentChip(
                        l10n.card, Icons.credit_card, colorScheme),
                    _buildPaymentChip(
                        l10n.bank, Icons.account_balance, colorScheme),
                    _buildPaymentChip(
                        l10n.other, Icons.more_horiz, colorScheme),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _amountReceivedController,
                readOnly: _paymentStatus != 'Partial',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.amountReceived,
                  prefixText: '₹ ',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.balance),
                  Text(
                    _formatPaise(context, balancePaise),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: balancePaise > 0
                          ? colorScheme.error
                          : colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentChip(
      String label, IconData icon, ColorScheme colorScheme) {
    final isSelected = _selectedPayment == label;
    return InkWell(
      onTap: () => setState(() => _selectedPayment = label),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color:
              isSelected ? colorScheme.primaryContainer : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 20,
                color: isSelected ? colorScheme.primary : Colors.grey.shade700),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? colorScheme.primary : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSummary(ColorScheme colorScheme, AppLocalizations l10n) {
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
                  Text(
                    l10n.subtotal,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    _formatPaise(context, _subtotalPaise),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (_gstRegistered)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.gst,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      _formatPaise(context, _gstAmountPaise),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 4),
              InkWell(
                onTap: _showBillDiscountDialog,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.billDiscount,
                      style: TextStyle(
                        fontSize: 14,
                        color: _billDiscountType != null
                            ? Colors.green
                            : Colors.grey,
                        fontWeight:
                            _billDiscountType != null ? FontWeight.w600 : null,
                      ),
                    ),
                    Text(
                      _billDiscountType != null && _billDiscountValue != null
                          ? DiscountService.getDiscountDisplayText(
                              discountType: _billDiscountType!,
                              discountValue: _billDiscountValue!,
                            )
                          : l10n.add,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _billDiscountType != null
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (_rewardDiscountAmountPaise > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reward Discount',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '-${_formatPaise(context, _rewardDiscountAmountPaise)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ],
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.grandTotal,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _formatPaise(context, _totalAmountPaise),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _products
                              .where((item) =>
                                  item.source != _deliveryChargeSource)
                              .isEmpty ||
                          _isOrderSaved
                      ? null
                      : _saveOrder,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.placeDeliveryOrder,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddProductOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.addProduct,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.inventory_2_rounded, size: 32),
                  title: Text(l10n.products),
                  subtitle: Text(l10n.selectFromProductCatalogue),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickFromProducts(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, size: 32),
                  title: Text(l10n.takePicture),
                  subtitle: Text(l10n.captureProductPhoto),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickFromCamera(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo, size: 32),
                  title: Text(l10n.gallery),
                  subtitle: Text(l10n.captureProductPhoto),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickFromGallery(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, size: 32),
                  title: Text(l10n.myDesigns),
                  subtitle: Text(l10n.selectFromDesignLibrary),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickFromMyDesigns(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit, size: 32),
                  title: Text(l10n.manualEntry),
                  subtitle: Text(l10n.typeProductDetails),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showManualEntry(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showBarcodeScanner(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final input = await showCameraBarcodeScanner(
      context,
      title: l10n.scanBarcode,
    );

    if (input == null || input.trim().isEmpty) {
      return;
    }

    await _lookupByBarcodeAndAdd(input.trim());
  }

  Future<void> _pickFromProducts(BuildContext context) async {
    final selected = await showProductPickerSheet(context);
    if (selected == null || !mounted) return;

    setState(() {
      _addOrIncrementCatalogProduct(
        productId: selected.id,
        trackInventory: selected.trackInventory,
        name: selected.name,
        pricePaise: selected.sellingPricePaise,
        unit: selected.defaultUnit,
        gstPercent: _gstRegistered ? selected.gstPercent : 0,
        gstCalculationType: selected.gstCalculationType,
      );
    });
  }

  Future<void> _lookupByBarcodeAndAdd(String query) async {
    try {
      final matched =
          await _productRepository.lookupProductBySearchPriority(query);
      if (!mounted) return;

      if (matched == null) {
        _showProductNotFoundDialog();
        return;
      }

      setState(() {
        _addOrIncrementCatalogProduct(
          productId: matched.id,
          trackInventory: matched.trackInventory,
          name: matched.name,
          pricePaise: matched.sellingPricePaise,
          unit: matched.defaultUnit,
          gstPercent: _gstRegistered ? matched.gstPercent : 0,
          gstCalculationType: matched.gstCalculationType,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.addedToCart)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseTryAgain)),
      );
    }
  }

  void _addOrIncrementCatalogProduct({
    required int productId,
    required bool trackInventory,
    required String name,
    required int pricePaise,
    required String unit,
    required int gstPercent,
    required GstCalculationType gstCalculationType,
  }) {
    final existingIndex = _products.indexWhere(
      (item) => item.productId == productId && item.source == 'product',
    );

    if (existingIndex >= 0) {
      final existing = _products[existingIndex];
      _products[existingIndex] =
          existing.copyWith(quantity: existing.quantity + 1);
      return;
    }

    _products.add(
      _ProductItem(
        productId: productId,
        trackInventory: trackInventory,
        designId: name,
        quantity: 1,
        price: _formatPaise(context, pricePaise),
        unit: unit,
        gstPercent: gstPercent,
        gstCalculationType: gstCalculationType,
        source: 'product',
      ),
    );
  }

  void _showProductNotFoundDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.noProductFound),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/products');
            },
            child: Text(l10n.createProduct),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFromCamera(BuildContext context) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image == null || !mounted) return;

    await _showBillItemDialog(
      source: 'camera',
      initialDescription: 'Camera: ${p.basename(image.path)}',
      attachmentPath: image.path,
      showPreview: true,
      showSaveAsDesign: true,
    );
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null || !mounted) return;

    await _showBillItemDialog(
      source: 'gallery',
      initialDescription: 'Gallery: ${p.basename(image.path)}',
      attachmentPath: image.path,
      showPreview: true,
      showSaveAsDesign: true,
    );
  }

  Future<void> _pickFromMyDesigns(BuildContext context) async {
    final selected = await Navigator.push<SelectedDesign>(
      context,
      MaterialPageRoute(
        builder: (context) => const MyDesignsScreen(isSelectionMode: true),
      ),
    );
    if (selected == null || !mounted) return;

    final description = selected.description.trim().isNotEmpty
        ? selected.description.trim()
        : selected.designId.trim();

    await _showBillItemDialog(
      source: 'design',
      initialDescription: description,
      initialAmount: selected.price,
      attachmentPath: selected.imagePath,
      note: selected.description,
      showPreview: selected.imagePath != null,
    );
  }

  Future<void> _showBillItemDialog({
    required String source,
    required String initialDescription,
    String? initialAmount,
    String? attachmentPath,
    String? note,
    int? productId,
    bool trackInventory = false,
    int? gstPercentOverride,
    bool amountOnly = false,
    bool showPreview = false,
    bool showSaveAsDesign = false,
  }) async {
    final designProvider = context.read<DesignProvider>();
    final descriptionController =
        TextEditingController(text: initialDescription.trim());
    final amountController = TextEditingController(
      text: initialAmount == null
          ? ''
          : initialAmount.replaceAll('₹', '').replaceAll(',', '').trim(),
    );
    var saveAsDesign = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add to Bill'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showPreview && attachmentPath != null) ...[
                      const Text(
                        'Image Preview',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(attachmentPath),
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 140,
                              color: Colors.grey.shade200,
                              alignment: Alignment.center,
                              child: const Text('Preview not available'),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (!amountOnly) ...[
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: '₹',
                      ),
                    ),
                    if (showSaveAsDesign && attachmentPath != null) ...[
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: saveAsDesign,
                        onChanged: (value) {
                          setDialogState(() => saveAsDesign = value ?? false);
                        },
                        title: const Text('Save this as a new Design'),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final description = amountOnly
                        ? initialDescription.trim()
                        : descriptionController.text.trim();
                    final amountRupees = int.tryParse(
                          amountController.text
                              .replaceAll('₹', '')
                              .replaceAll(',', '')
                              .trim(),
                        ) ??
                        0;

                    if (amountRupees <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter the selling amount.'),
                        ),
                      );
                      return;
                    }

                    if (description.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter product description.'),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      _products.add(
                        _ProductItem(
                          productId: productId,
                          trackInventory: trackInventory,
                          designId: description,
                          quantity: 1,
                          price: '₹$amountRupees',
                          gstPercent:
                              _gstRegistered ? (gstPercentOverride ?? 12) : 0,
                          gstCalculationType: GstCalculationType.inclusive,
                          source: source,
                          attachmentPath: attachmentPath,
                          note: note,
                        ),
                      );
                    });

                    Navigator.pop(dialogContext);

                    if (saveAsDesign && attachmentPath != null) {
                      await designProvider.createDesign(
                        imagePath: attachmentPath,
                        description: description,
                        sellingPricePaise: amountRupees * 100,
                      );
                    }
                  },
                  child: const Text('Add to Bill'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showManualEntry(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final discountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.manualEntry),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: l10n.designIdOrDescription,
                hintText: l10n.eG20RedRosesCustomArrangement,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              decoration: InputDecoration(
                labelText: l10n.sellingPrice,
                hintText: l10n.eG850,
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: discountController,
              decoration: InputDecoration(
                labelText: l10n.discountOptional,
                hintText: l10n.eG50,
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final description = descriptionController.text.trim();
              final amount = int.tryParse(
                    priceController.text
                        .replaceAll('₹', '')
                        .replaceAll(',', '')
                        .trim(),
                  ) ??
                  0;

              if (description.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter product description.'),
                  ),
                );
                return;
              }

              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter the selling amount.'),
                  ),
                );
                return;
              }

              setState(() {
                _products.add(_ProductItem(
                  designId: description,
                  quantity: 1,
                  price: '₹$amount',
                  gstPercent: _gstRegistered ? 12 : 0,
                  gstCalculationType: GstCalculationType.inclusive,
                  discount: discountController.text.isNotEmpty
                      ? discountController.text
                      : null,
                ));
              });
              Navigator.pop(context);
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    );
  }

  void _selectDeliveryDate(BuildContext context) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null && mounted) {
      final now = DateTime.now();
      setState(() {
        _deliveryDate = selected;
        if (_selectedDeliverySlot != null &&
            !_isDeliverySlotAvailable(_selectedDeliverySlot!, now)) {
          _selectedDeliverySlot = null;
          _customDeliveryTime = null;
        }
      });

      if (DeliverySlotUtils.isSameDate(selected, now) &&
          _availableDeliverySlots(now).isEmpty) {
        _showNoDeliverySlotsTodayPrompt();
      }
    }
  }

  void _selectDeliverySlot(BuildContext context) async {
    if (_deliveryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select delivery date first.')),
      );
      return;
    }

    final now = DateTime.now();
    final slots = _availableDeliverySlots(now);
    if (slots.isEmpty) {
      _showNoDeliverySlotsTodayPrompt();
      return;
    }

    final selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: slots
              .map(
                (slot) => ListTile(
                  title: Text(_deliverySlotDisplay(slot)),
                  onTap: () => Navigator.pop(context, slot),
                ),
              )
              .toList(),
        );
      },
    );

    if (selected == null) return;
    setState(() {
      _selectedDeliverySlot = selected;
      if (selected != 'custom') {
        _customDeliveryTime = null;
      }
    });
  }

  void _selectCustomDeliveryTime(BuildContext context) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (selected != null) {
      setState(() => _customDeliveryTime = selected);
    }
  }

  Future<void> _showCustomerSearch() async {
    final selected = await showModalBottomSheet<CustomerRecord>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _CustomerSearchSheet(repository: _customerRepository),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _customerNameController.text = selected.name;
      _customerPhoneController.text = selected.phone;
      _customerInfo = _CustomerInfo(
        previousOrders: selected.totalOrders,
        lifetimePurchase: 'Loading...',
        lastOrder: selected.lastOrderAt == null
            ? 'N/A'
            : _formatDate(selected.lastOrderAt!),
        favouriteDesign: 'N/A',
        rewardPoints: selected.rewardPoints,
      );
      _syncSenderFromCustomerIfNeeded();
    });
    await _lookupCustomer(selected.phone);
  }

  void _syncSenderFromCustomerIfNeeded() {
    if (!_senderSameAsCustomer) return;
    _senderNameController.text = _customerNameController.text;
    _senderPhoneController.text = _customerPhoneController.text;
  }

  Future<void> _lookupCustomer(String phone) async {
    final provider = context.read<WalkInSessionProvider>();
    final customerName = await provider.lookupCustomerName(phone);
    final customerStats = await provider.lookupCustomerStatistics(phone);

    if (!mounted) return;

    setState(() {
      if (customerName == null || customerName.isEmpty) {
        _customerInfo = null;
        _rewardPointsRedeemed = 0;
        _rewardDiscountAmountPaise = 0;
        return;
      }

      if (_customerNameController.text.trim().isEmpty) {
        _customerNameController.text = customerName;
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
        favouriteDesign: favouriteDesign ?? 'N/A',
        rewardPoints: rewardPoints,
      );
      _syncSenderFromCustomerIfNeeded();
    });
  }

  Future<void> _applyMaximumRewards() async {
    _syncProviderSession();
    final provider = context.read<WalkInSessionProvider>();
    final session = await provider.applyMaximumRewards();
    if (!mounted) return;
    setState(() {
      _rewardPointsRedeemed = session.rewardPointsRedeemed;
      _rewardDiscountAmountPaise = session.rewardDiscountAmountPaise;
    });
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return 'N/A';
    }
  }

  Future<void> _showLineItemDiscountDialog(int index) async {
    final product = _products[index];
    final lineSubtotal =
        _parseCurrencyToPaise(product.price) * product.quantity;

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

  Future<void> _showBillDiscountDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => BillDiscountDialog(
        subtotalPaise: _subtotalPaise,
        currentDiscountType: _billDiscountType,
        currentDiscountValue: _billDiscountValue,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _billDiscountType = result['discountType'] as String?;
        _billDiscountValue = result['discountValue'] as int?;
      });
    }
  }

  Future<void> _saveOrder() async {
    final l10n = AppLocalizations.of(context)!;
    if (_isOrderSaved) {
      final orderId = _savedOrderId;
      if (orderId != null) await _showCompletionDialog(orderId);
      return;
    }

    if (_customerNameController.text.trim().isEmpty ||
        _customerPhoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer name and mobile are required.')),
      );
      return;
    }

    final billProducts = _products
        .where((item) => item.source != _deliveryChargeSource)
        .toList();
    if (billProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product.')),
      );
      return;
    }

    if (_paymentStatus != 'Pending' && _selectedPayment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseSelectPaymentMethod)),
      );
      return;
    }

    final amountReceivedPaise =
        _parseCurrencyToPaise(_amountReceivedController.text);
    if (_paymentStatus == 'Partial' &&
        (amountReceivedPaise <= 0 ||
            amountReceivedPaise >= _totalAmountPaise)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Partial amount must be greater than zero and less than the total.'),
        ),
      );
      return;
    }

    final hasInvalidAmount =
        _products.any((item) => _parseCurrencyToPaise(item.price) <= 0);
    if (hasInvalidAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the selling amount.')),
      );
      return;
    }

    if (_deliveryDate == null || _selectedDeliverySlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseSelectDeliveryDateAndTime)),
      );
      return;
    }

    if (_selectedDeliverySlot == 'custom' && _customDeliveryTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select custom delivery time.')),
      );
      return;
    }

    if (!_isSelectedDeliverySlotValidNow()) {
      final now = DateTime.now();
      setState(() {
        _selectedDeliverySlot = null;
        _customDeliveryTime = null;
      });
      if (_deliveryDate != null &&
          DeliverySlotUtils.isSameDate(_deliveryDate!, now) &&
          _availableDeliverySlots(now).isEmpty) {
        _showNoDeliverySlotsTodayPrompt();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Selected delivery slot is no longer available. Please choose another slot.',
            ),
          ),
        );
      }
      return;
    }

    _syncProviderSession();
    final provider = context.read<WalkInSessionProvider>();
    if (_isEditingOrder) {
      final updated =
          await provider.updateExistingOrder(widget.editingOrderId!);
      if (!mounted) return;

      if (!updated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? l10n.couldNotSaveOrder)),
        );
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Order Updated'),
          content: const Text('Order updated successfully.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(l10n.done),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
      return;
    }

    final orderId = await provider.confirmOrder();
    if (!mounted) return;

    if (orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? l10n.couldNotSaveOrder)),
      );
      return;
    }

    setState(() {
      _isOrderSaved = true;
      _savedOrderId = orderId;
    });
    await _showCompletionDialog(orderId);
  }

  Future<void> _showCompletionDialog(int orderId) {
    final l10n = AppLocalizations.of(context)!;
    final rewardFuture =
        context.read<WalkInSessionProvider>().getOrderRewardSummary(orderId);
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Order Completed'),
        content: FutureBuilder<OrderRewardSummary?>(
          future: rewardFuture,
          builder: (context, snapshot) {
            final summary = snapshot.data;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order #$orderId'),
                if (summary != null && summary.hasActivity) ...[
                  const SizedBox(height: 12),
                  RewardSummaryCard(summary: summary, compact: true),
                ],
              ],
            );
          },
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _resetForNextOrder();
            },
            icon: const Icon(Icons.done),
            label: const Text('Done'),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              await _printDeliveryChallan(context, orderId);
            },
            icon: const Icon(Icons.print),
            label: const Text('Print Delivery Challan'),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              await _shareWhatsApp(context, orderId);
            },
            icon: const Icon(Icons.share),
            label: Text(l10n.shareWhatsApp),
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
      _customerPhoneController.clear();
      _customerNameController.clear();
      _recipientPhoneController.clear();
      _recipientNameController.clear();
      _addressController.clear();
      _pinCodeController.clear();
      _landmarkController.clear();
      _cardMessageController.clear();
      _specialInstructionsController.clear();
      _senderSameAsCustomer = true;
      _senderPhoneController.clear();
      _senderNameController.clear();
      _amountReceivedController.clear();
      _paymentStatus = 'Paid';
      _selectedPayment = null;
      _deliveryDate = null;
      _selectedDeliverySlot = null;
      _customDeliveryTime = null;
      _customerInfo = null;
      _billDiscountType = null;
      _billDiscountValue = null;
      _rewardPointsRedeemed = 0;
      _rewardDiscountAmountPaise = 0;
      _isOrderSaved = false;
      _savedOrderId = null;
      _deliveryChargeController.text =
          (_defaultDeliveryChargePaise / 100).toStringAsFixed(0);
      _upsertDeliveryChargeLine();
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

    await _showDraftSavedDialog();
  }

  Future<void> _showDraftSavedDialog() {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Draft Saved Successfully'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Editing'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetForNextOrder();
            },
            child: const Text('New Sale'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/draft-orders');
            },
            child: const Text('View Drafts'),
          ),
        ],
      ),
    );
  }

  void _syncProviderSession() {
    final provider = context.read<WalkInSessionProvider>();
    final current = provider.session;
    final scheduledAt = _resolveScheduledAt();

    _upsertDeliveryChargeLine();

    provider.patchSession(
      WalkInSession(
        draftOrderId: current.draftOrderId,
        fulfilmentType: _fulfilmentType,
        lines: _walkInLines,
        customerPhone: _customerPhoneController.text.trim(),
        customerName: _customerNameController.text.trim(),
        recipientName: _recipientNameController.text.trim(),
        recipientPhone: _recipientPhoneController.text.trim(),
        deliveryAddress: _addressController.text.trim(),
        deliveryPincode: _pinCodeController.text.trim(),
        deliveryLandmark: _landmarkController.text.trim(),
        cardMessage: _cardMessageController.text.trim(),
        specialInstructions: _specialInstructionsController.text.trim(),
        scheduledAt: scheduledAt,
        deliverySlot: _deliverySlotValueForPersistence(),
        payments: _buildPayments(_totalAmountPaise),
        billDiscountType: _billDiscountType,
        billDiscountValue: _billDiscountValue,
        rewardPointsRedeemed: _rewardPointsRedeemed,
        rewardDiscountAmountPaise: _rewardDiscountAmountPaise,
      ),
    );
  }

  List<PaymentSplit> _buildPayments(int grandTotalPaise) {
    if (_paymentStatus == 'Pending' || _selectedPayment == null) {
      return const [];
    }

    final amountPaise = _paymentStatus == 'Paid'
        ? grandTotalPaise
        : _parseCurrencyToPaise(_amountReceivedController.text)
            .clamp(0, grandTotalPaise);
    final methodCode = _selectedPayment!.toLowerCase();
    final method = switch (methodCode) {
      'upi' => PaymentMethod.upi,
      'card' => PaymentMethod.card,
      _ => PaymentMethod.cash,
    };

    return [
      PaymentSplit(
        method: method,
        methodCode: methodCode,
        amountPaise: amountPaise,
      ),
    ];
  }

  int _parseCurrencyToPaise(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 0;
    }

    final sanitized = value.replaceAll('₹', '').replaceAll(',', '').trim();
    final parsed = double.tryParse(sanitized) ?? 0;
    return (parsed * 100).round();
  }

  String _formatPaise(BuildContext context, int paise) {
    return LocaleFormatter.formatCurrency(context, paise);
  }

  String _paymentToLabel(PaymentSplit payment) {
    return switch (payment.persistenceMethod) {
      'upi' => 'UPI',
      'card' => 'Card',
      'bank' => 'Bank',
      'other' => 'Other',
      _ => 'Cash',
    };
  }

  Future<void> _printDeliveryChallan(BuildContext context, int orderId) async {
    final printerProvider = context.read<PrinterProvider>();
    await printerProvider.enqueueDeliverySlip({
      'orderNo': orderId.toString(),
      'deliveryTime': _resolveScheduledAt()?.toIso8601String() ?? '',
      'recipientName': _recipientNameController.text.trim(),
      'recipientPhone': _recipientPhoneController.text.trim(),
      'senderName': _senderNameController.text.trim(),
      'senderPhone': _senderPhoneController.text.trim(),
      'address': _addressController.text.trim(),
      'landmark': _landmarkController.text.trim(),
      'pinCode': _pinCodeController.text.trim(),
      'deliveryInstructions': _specialInstructionsController.text.trim(),
      'messageCardIncluded': _cardMessageController.text.trim().isNotEmpty,
      'items': _printItems(),
    });
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            printerProvider.error ?? 'Delivery challan queued for printing.'),
      ),
    );
  }

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

  Future<void> _shareWhatsApp(BuildContext context, int orderId) async {
    final messenger = ScaffoldMessenger.of(context);
    final phone = _normalizedWhatsAppPhone(_customerPhoneController.text);
    if (phone == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Customer mobile number is required for WhatsApp.'),
        ),
      );
      return;
    }

    final rewardSummary = await context
        .read<WalkInSessionProvider>()
        .getOrderRewardSummary(orderId);
    final message = _buildReceiptMessage(orderId, rewardSummary);
    final waUri = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
    );

    if (await launchUrl(waUri, mode: LaunchMode.externalApplication)) {
      return;
    }

    final fallback = Uri.parse(
      'https://api.whatsapp.com/send?phone=$phone&text=${Uri.encodeComponent(message)}',
    );
    if (await launchUrl(fallback, mode: LaunchMode.externalApplication)) {
      return;
    }

    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Unable to open WhatsApp on this device')),
    );
  }

  String? _normalizedWhatsAppPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) return '91$digits';
    if (digits.length == 12 && digits.startsWith('91')) return digits;
    return null;
  }

  String _buildReceiptMessage(int orderId, OrderRewardSummary? rewardSummary) {
    final l10n = AppLocalizations.of(context)!;
    final lines = <String>[
      _shopName,
      if (_businessPhone.isNotEmpty) '${l10n.phone}: $_businessPhone',
      if (_businessAddress.isNotEmpty) _businessAddress,
      l10n.receipt,
      '${l10n.orderNumber}: #$orderId',
      '',
      '${l10n.items}:',
      ..._products.map(
        (item) {
          final itemLine =
              '- ${item.designId} x${item.quantity} (${item.price})';
          if (item.discount != null && item.discount!.isNotEmpty) {
            return '$itemLine (${l10n.discountLabel}${item.discount})';
          }
          return itemLine;
        },
      ),
      '',
      '${l10n.subtotal}: ${_formatPaise(context, _subtotalPaise)}',
      if (_billDiscountType != null && _billDiscountValue != null)
        '${l10n.billDiscount}: ${DiscountService.getDiscountDisplayText(discountType: _billDiscountType!, discountValue: _billDiscountValue!)}',
      if (_gstRegistered)
        '${l10n.gst}: ${_formatPaise(context, _gstAmountPaise)}',
      '${l10n.grandTotal}: ${_formatPaise(context, _totalAmountPaise)}',
      buildRewardWhatsAppText(rewardSummary),
    ];
    return lines.where((line) => line.trim().isNotEmpty).join('\n');
  }

  String _quantityUnitLabel(_ProductItem product) {
    final unit = product.unit.trim().isEmpty ? 'Piece' : product.unit.trim();
    if (product.quantity == 1) {
      return '1 $unit';
    }
    return '${product.quantity} ${_pluralizeUnit(unit)}';
  }

  String _pluralizeUnit(String unit) {
    switch (unit) {
      case 'Stem':
        return 'Stems';
      case 'Bunch':
        return 'Bunches';
      case 'Piece':
        return 'Pieces';
      case 'Box':
        return 'Boxes';
      case 'Roll':
        return 'Rolls';
      case 'Pot':
        return 'Pots';
      case 'Packet':
        return 'Packets';
      case 'Kg':
        return 'Kgs';
      case 'Meter':
        return 'Meters';
      default:
        return '${unit}s';
    }
  }

  void _upsertDeliveryChargeLine() {
    final amountRupees =
        int.tryParse(_deliveryChargeController.text.trim()) ?? 0;
    _products.removeWhere((item) => item.source == _deliveryChargeSource);
    if (amountRupees <= 0) {
      return;
    }

    _products.add(
      _ProductItem(
        designId: AppLocalizations.of(context)!.deliveryCharge,
        quantity: 1,
        price: '₹$amountRupees',
        gstPercent: _gstRegistered ? 12 : 0,
        gstCalculationType: GstCalculationType.inclusive,
        source: _deliveryChargeSource,
      ),
    );
  }

  DateTime? _resolveScheduledAt() {
    if (_deliveryDate == null || _selectedDeliverySlot == null) {
      return null;
    }

    final time = _selectedDeliverySlot == 'custom'
        ? _customDeliveryTime
        : _defaultTimeForSlot(_selectedDeliverySlot!);
    if (time == null) {
      return null;
    }

    return DateTime(
      _deliveryDate!.year,
      _deliveryDate!.month,
      _deliveryDate!.day,
      time.hour,
      time.minute,
    );
  }

  TimeOfDay? _defaultTimeForSlot(String slot) {
    switch (slot) {
      case 'morning':
        return const TimeOfDay(hour: 9, minute: 0);
      case 'late_morning':
        return const TimeOfDay(hour: 11, minute: 30);
      case 'afternoon':
        return const TimeOfDay(hour: 14, minute: 30);
      case 'evening':
        return const TimeOfDay(hour: 17, minute: 30);
      case 'night':
        return const TimeOfDay(hour: 20, minute: 30);
      case 'midnight':
        return const TimeOfDay(hour: 23, minute: 45);
      default:
        return null;
    }
  }

  List<String> _availableDeliverySlots(DateTime now) {
    if (_deliveryDate == null) return const [];
    return DeliverySlotUtils.availableSlotKeys(
      deliveryDate: _deliveryDate!,
      now: now,
      bufferMinutes: _minimumPreparationBufferMinutes,
    );
  }

  bool _isSelectedDeliverySlotValidNow() {
    final slot = _selectedDeliverySlot;
    if (_deliveryDate == null || slot == null) return false;
    return _isDeliverySlotAvailable(slot, DateTime.now());
  }

  bool _isDeliverySlotAvailable(String slot, DateTime now) {
    if (_deliveryDate == null) return false;
    return DeliverySlotUtils.isSlotAvailable(
      slot: slot,
      deliveryDate: _deliveryDate!,
      now: now,
      bufferMinutes: _minimumPreparationBufferMinutes,
    );
  }

  void _showNoDeliverySlotsTodayPrompt() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('No delivery slots are available today.'),
        action: SnackBarAction(
          label: 'Choose tomorrow',
          onPressed: _chooseTomorrowForDelivery,
        ),
      ),
    );
  }

  void _chooseTomorrowForDelivery() {
    final now = DateTime.now();
    setState(() {
      _deliveryDate = DateTime(now.year, now.month, now.day + 1);
      _selectedDeliverySlot = null;
      _customDeliveryTime = null;
    });
  }

  String _inferSlotFromDateTime(DateTime? value) {
    if (value == null) return '';
    final minutes = value.hour * 60 + value.minute;
    if (minutes >= 8 * 60 && minutes < 10 * 60) return 'morning';
    if (minutes >= 10 * 60 && minutes < 13 * 60) return 'late_morning';
    if (minutes >= 13 * 60 && minutes < 16 * 60) return 'afternoon';
    if (minutes >= 16 * 60 && minutes < 19 * 60) return 'evening';
    if (minutes >= 19 * 60 && minutes < 22 * 60) return 'night';
    if (minutes >= 23 * 60 || minutes <= 30) return 'midnight';
    return 'custom';
  }

  String _deliverySlotDisplay(String slot) {
    switch (slot) {
      case 'morning':
        return 'Morning (8-10)';
      case 'late_morning':
        return 'Late Morning (10-1)';
      case 'afternoon':
        return 'Afternoon (1-4)';
      case 'evening':
        return 'Evening (4-7)';
      case 'night':
        return 'Night (7-10)';
      case 'midnight':
        return 'Midnight (11-12:30)';
      case 'custom':
        return 'Custom Time';
      default:
        return 'Custom Time';
    }
  }

  String _deliverySlotValueForPersistence() {
    if (_selectedDeliverySlot == null) {
      return '';
    }
    if (_selectedDeliverySlot != 'custom') {
      return _selectedDeliverySlot!;
    }
    if (_customDeliveryTime == null) {
      return 'custom';
    }
    final minute = _customDeliveryTime!.minute.toString().padLeft(2, '0');
    return 'custom_${_customDeliveryTime!.hour}:$minute';
  }
}

class _ProductItem {
  final int? productId;
  final bool trackInventory;
  final String designId;
  final int quantity;
  final String price;
  final String unit;
  final String? discount;
  final String? discountType;
  final int? discountValue;
  final int gstPercent;
  final GstCalculationType gstCalculationType;
  final String source;
  final String? attachmentPath;
  final String? note;

  _ProductItem({
    this.productId,
    this.trackInventory = false,
    required this.designId,
    required this.quantity,
    required this.price,
    this.unit = 'Piece',
    this.discount,
    this.discountType,
    this.discountValue,
    this.gstPercent = 12,
    this.gstCalculationType = GstCalculationType.inclusive,
    this.source = 'manual',
    this.attachmentPath,
    this.note,
  });

  _ProductItem copyWith({
    int? quantity,
    String? discount,
    String? discountType,
    int? discountValue,
  }) {
    return _ProductItem(
      productId: productId,
      trackInventory: trackInventory,
      designId: designId,
      quantity: quantity ?? this.quantity,
      price: price,
      unit: unit,
      discount: discount ?? this.discount,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      gstPercent: gstPercent,
      gstCalculationType: gstCalculationType,
      source: source,
      attachmentPath: attachmentPath,
      note: note,
    );
  }
}

class _CustomerSearchSheet extends StatefulWidget {
  const _CustomerSearchSheet({required this.repository});

  final CustomerRepository repository;

  @override
  State<_CustomerSearchSheet> createState() => _CustomerSearchSheetState();
}

class _CustomerSearchSheetState extends State<_CustomerSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  List<CustomerRecord> _results = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    setState(() => _isLoading = true);
    final rows = query.trim().isEmpty
        ? await widget.repository.getAll()
        : await widget.repository.search(query.trim());
    if (!mounted) return;
    setState(() {
      _results = rows;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.searchCustomer,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: _search,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? Center(child: Text(l10n.noCustomersFound))
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final customer = _results[index];
                          return ListTile(
                            title: Text(customer.name),
                            subtitle: Text(customer.phone),
                            trailing:
                                Text('${customer.totalOrders} ${l10n.orders}'),
                            onTap: () => Navigator.pop(context, customer),
                          );
                        },
                      ),
          ),
        ],
      ),
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
