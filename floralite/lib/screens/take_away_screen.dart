import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../managers/business_settings_manager.dart';
import '../managers/pricing_manager.dart';
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
import '../utils/locale_formatter.dart';
import '../widgets/app_header.dart';
import '../widgets/bill_discount_dialog.dart';
import '../widgets/camera_barcode_scanner_page.dart';
import '../widgets/common_widgets.dart';
import '../widgets/line_item_discount_dialog.dart';
import '../widgets/product_picker_sheet.dart';
import '../widgets/quantity_input_stepper.dart';
import '../widgets/reward_summary_card.dart';
import '../widgets/split_payment_sheet.dart';
import 'my_designs_screen.dart';

enum _UnsavedChangesAction { saveDraft, discard, cancel }

class TakeAwayScreen extends StatefulWidget {
  const TakeAwayScreen({
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
  State<TakeAwayScreen> createState() => _TakeAwayScreenState();
}

class _TakeAwayScreenState extends State<TakeAwayScreen> {
  static const FulfilmentType _fulfilmentType = FulfilmentType.takeAway;
  static const String _splitPaymentLabel = 'Split Payment';
  final BusinessSettingsManager _businessSettingsManager =
      BusinessSettingsManager();
  final PricingManager _pricingManager = PricingManager();
  final ProductRepository _productRepository = ProductRepository();
  final List<_ProductItem> _products = [];
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _occasionController = TextEditingController();
  final TextEditingController _recipientController = TextEditingController();
  String? _selectedPayment;
  Map<String, int> _splitPaymentAllocationsPaise = <String, int>{};
  _CustomerInfo? _customerInfo;
  bool _gstRegistered = true;
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

    // Prefill data if provided
    if (widget.prefillCustomerPhone != null) {
      _phoneController.text = widget.prefillCustomerPhone!;
    }
    if (widget.prefillCustomerName != null) {
      _customerNameController.text = widget.prefillCustomerName!;
    }
    if (widget.prefillOccasion != null) {
      _occasionController.text = widget.prefillOccasion!;
    }
    if (widget.prefillRecipientName != null) {
      _recipientController.text = widget.prefillRecipientName!;
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
      _shopName = settings.shopName;
      _businessPhone = settings.phone;
      _businessAddress = settings.address;
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _customerNameController.dispose();
    _occasionController.dispose();
    _recipientController.dispose();
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

      _phoneController.text = activeSession.customerPhone;
      _customerNameController.text = activeSession.customerName;
      _occasionController.text = activeSession.occasion;
      _recipientController.text = activeSession.recipientName;
      _billDiscountType = activeSession.billDiscountType;
      _billDiscountValue = activeSession.billDiscountValue;

      if (activeSession.payments.length == 1) {
        final payment = activeSession.payments.first;
        final code = payment.persistenceMethod.toLowerCase();
        if (code == 'cash' || code == 'upi' || code == 'card') {
          _selectedPayment = _paymentToLabel(payment.method);
          _splitPaymentAllocationsPaise = <String, int>{};
        } else {
          _selectedPayment = _splitPaymentLabel;
          _splitPaymentAllocationsPaise = {code: payment.amountPaise};
        }
      } else if (activeSession.payments.isNotEmpty) {
        _selectedPayment = _splitPaymentLabel;
        _splitPaymentAllocationsPaise = {
          for (final payment in activeSession.payments)
            payment.persistenceMethod.toLowerCase(): payment.amountPaise,
        };
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
          title: l10n.takeAway,
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
    return _products.isNotEmpty ||
        _phoneController.text.trim().isNotEmpty ||
        _customerNameController.text.trim().isNotEmpty ||
        _occasionController.text.trim().isNotEmpty ||
        _recipientController.text.trim().isNotEmpty ||
        _selectedPayment != null ||
        _splitPaymentAllocationsPaise.isNotEmpty ||
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
                            setState(() => _products.removeAt(index));
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

  Widget _buildCustomerSection(ColorScheme colorScheme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.customer,
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
                controller: _phoneController,
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
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                onChanged: (value) {
                  if (value.length == 10) {
                    _lookupCustomer(value);
                  }
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _customerNameController,
                decoration: InputDecoration(
                  labelText: l10n.customerName,
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
                controller: _occasionController,
                decoration: InputDecoration(
                  labelText: l10n.occasionOptional,
                  prefixIcon: const Icon(Icons.celebration),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                ),
              ),
              if (_customerInfo != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info,
                              color: colorScheme.primary, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            l10n.existingCustomer,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _buildCustomerInfoRow(l10n.previousOrders,
                          '${_customerInfo!.previousOrders}'),
                      _buildCustomerInfoRow(l10n.lifetimePurchase,
                          _customerInfo!.lifetimePurchase),
                      _buildCustomerInfoRow(
                          l10n.lastOrder, _customerInfo!.lastOrder),
                      _buildCustomerInfoRow(
                          l10n.favouriteDesign, _customerInfo!.favouriteDesign),
                      _buildCustomerInfoRow('Reward Balance',
                          '${_customerInfo!.rewardPoints} Points'),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _products.isEmpty ||
                                  _customerInfo!.rewardPoints <= 0
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
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildPaymentChip(l10n.cash, Icons.payments, colorScheme),
            _buildPaymentChip(l10n.upi, Icons.qr_code_scanner, colorScheme),
            _buildPaymentChip(l10n.card, Icons.credit_card, colorScheme),
            _buildPaymentChip(
              _splitPaymentLabel,
              Icons.call_split,
              colorScheme,
              isSplitPayment: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentChip(
    String label,
    IconData icon,
    ColorScheme colorScheme, {
    bool isSplitPayment = false,
  }) {
    final isSelected = _selectedPayment == label;
    return InkWell(
      onTap: () async {
        if (!isSplitPayment) {
          setState(() {
            _selectedPayment = label;
            _splitPaymentAllocationsPaise = <String, int>{};
          });
          return;
        }

        final result = await showSplitPaymentAllocationSheet(
          context: context,
          orderTotalPaise: _totalAmountPaise,
          formatPaise: (paise) => _formatPaise(context, paise),
          initialAmountsPaise: _splitPaymentAllocationsPaise,
        );
        if (result == null || !mounted) return;

        setState(() {
          _selectedPayment = _splitPaymentLabel;
          _splitPaymentAllocationsPaise = result.amountsPaise;
        });
      },
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
                  onPressed:
                      _products.isEmpty || _isOrderSaved ? null : _saveOrder,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.completeSale,
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

  Future<void> _lookupCustomer(String phone) async {
    final provider = context.read<WalkInSessionProvider>();
    final customerName = await provider.lookupCustomerName(phone);
    final customerStats = await provider.lookupCustomerStatistics(phone);

    // Debug logging
    debugPrint('=== Customer Lookup Debug ===');
    debugPrint('Phone number entered: $phone');
    debugPrint('Customer name found: $customerName');
    if (customerStats != null) {
      debugPrint('Customer statistics: $customerStats');
      debugPrint('Previous Orders: ${customerStats['previousOrders']}');
      debugPrint(
          'Lifetime Purchase (paise): ${customerStats['lifetimePurchasePaise']}');
      debugPrint('Last Order Date: ${customerStats['lastOrderDate']}');
      debugPrint('Favourite Design: ${customerStats['favouriteDesign']}');
    } else {
      debugPrint('Customer statistics: null');
    }
    debugPrint('===========================');

    if (!mounted) return;

    setState(() {
      if (customerName == null || customerName.isEmpty) {
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
        favouriteDesign: favouriteDesign ?? 'N/A',
        rewardPoints: rewardPoints,
      );
      _customerNameController.text = customerName;
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
      if (orderId != null) {
        await _showCompletionDialog(orderId);
      }
      return;
    }

    if (_selectedPayment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseSelectPaymentMethod)),
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
        builder: (context) => AlertDialog(
          title: const Text('Order Updated'),
          content: const Text('Order updated successfully.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text(l10n.done),
            ),
          ],
        ),
      );
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
              await _printBill(context, orderId);
            },
            icon: const Icon(Icons.print),
            label: const Text('Print Receipt'),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              await _shareWhatsApp(context, orderId);
            },
            icon: const Icon(Icons.share),
            label: const Text('Share via WhatsApp'),
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
      _occasionController.clear();
      _recipientController.clear();
      _selectedPayment = null;
      _splitPaymentAllocationsPaise = <String, int>{};
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
    final totalPaise = _totalAmountPaise;

    provider.patchSession(
      WalkInSession(
        draftOrderId: current.draftOrderId,
        fulfilmentType: _fulfilmentType,
        lines: _walkInLines,
        customerPhone: _phoneController.text.trim(),
        customerName: _customerNameController.text.trim(),
        occasion: _occasionController.text.trim(),
        payments: _buildPayments(totalPaise),
        billDiscountType: _billDiscountType,
        billDiscountValue: _billDiscountValue,
        rewardPointsRedeemed: _rewardPointsRedeemed,
        rewardDiscountAmountPaise: _rewardDiscountAmountPaise,
      ),
    );
  }

  List<PaymentSplit> _buildPayments(int grandTotalPaise) {
    if (_selectedPayment == null) {
      return const [];
    }

    final paymentMethod = _paymentMethodFromSelection();
    final isSplitPayment = _selectedPayment == _splitPaymentLabel;

    if (paymentMethod != null && !isSplitPayment) {
      return [
        PaymentSplit(method: paymentMethod, amountPaise: grandTotalPaise)
      ];
    }

    if (isSplitPayment) {
      return _splitPaymentAllocationsPaise.entries
          .where((entry) => entry.value > 0)
          .map((entry) => _paymentSplitFromCode(entry.key, entry.value))
          .toList(growable: false);
    }

    return const [];
  }

  PaymentMethod? _paymentMethodFromSelection() {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedPayment == l10n.cash) return PaymentMethod.cash;
    if (_selectedPayment == l10n.upi) return PaymentMethod.upi;
    if (_selectedPayment == l10n.card) return PaymentMethod.card;
    return null;
  }

  PaymentSplit _paymentSplitFromCode(String rawCode, int amountPaise) {
    final code = rawCode.toLowerCase();
    switch (code) {
      case 'cash':
        return PaymentSplit(
            method: PaymentMethod.cash, amountPaise: amountPaise);
      case 'upi':
        return PaymentSplit(
            method: PaymentMethod.upi, amountPaise: amountPaise);
      case 'card':
        return PaymentSplit(
            method: PaymentMethod.card, amountPaise: amountPaise);
      case 'bank_transfer':
      case 'bank':
        return PaymentSplit(
          method: PaymentMethod.bank,
          amountPaise: amountPaise,
          methodCode: 'bank_transfer',
        );
      case 'cheque':
      case 'credit':
      case 'gift_voucher':
      case 'store_wallet':
        return PaymentSplit(
          method: PaymentMethod.other,
          amountPaise: amountPaise,
          methodCode: code,
        );
      default:
        return PaymentSplit(
          method: PaymentMethod.other,
          amountPaise: amountPaise,
          methodCode: code,
        );
    }
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
      case 'gift_voucher':
        return 'Gift Voucher';
      case 'store_wallet':
        return 'Store Wallet';
      default:
        return payment.persistenceMethod;
    }
  }

  int _paidAmountPaiseFromPayments(List<PaymentSplit> payments) {
    return payments
        .where((payment) => !payment.isCreditOutstanding)
        .fold<int>(0, (sum, payment) => sum + payment.amountPaise);
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

  String _paymentToLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.bank:
        return 'Bank';
      case PaymentMethod.other:
        return 'Other';
    }
  }

  Future<void> _printBill(BuildContext context, [int? orderId]) async {
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product.')),
      );
      return;
    }

    final printerProvider = context.read<PrinterProvider>();
    final payments = _buildPayments(_totalAmountPaise);
    final paidPaise = _paidAmountPaiseFromPayments(payments);
    final outstandingPaise =
        (_totalAmountPaise - paidPaise).clamp(0, _totalAmountPaise);
    final rewardSummary = orderId == null
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
      'discountPaise': _billDiscountPaise,
      'gstPaise': _gstAmountPaise,
      'grandTotalPaise': _totalAmountPaise,
      'paymentMode': _selectedPayment ?? 'Pending',
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
        content: Text(printerProvider.error ?? 'Receipt queued for printing.'),
      ),
    );
  }

  int get _billDiscountPaise {
    if (_billDiscountType == null || _billDiscountValue == null) return 0;
    return DiscountService.calculateBillDiscount(
      subtotalPaise: _subtotalPaise,
      discountType: _billDiscountType!,
      discountValue: _billDiscountValue!,
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
    final phone = _normalizedWhatsAppPhone(_phoneController.text);
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
    if (digits.length == 10) {
      return '91$digits';
    }
    if (digits.length == 12 && digits.startsWith('91')) {
      return digits;
    }
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
