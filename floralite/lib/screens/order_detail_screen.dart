import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/voice_dictation_controller.dart';
import '../data/repositories/associate_repository.dart';
import '../data/repositories/cloud_order_repository.dart';
import '../data/repositories/inventory_repository.dart';
import '../data/repositories/order_repository.dart';
import '../data/repositories/product_repository.dart';
import '../data/repositories/staff_repository.dart';
import '../data/repositories/third_party_delivery_repository.dart';
import '../l10n/app_localizations.dart';
import '../models/payment_split.dart';
import '../models/order_status.dart';
import '../models/order_workspace_models.dart';
import '../models/walk_in_enums.dart' hide OrderStatus;
import '../models/walk_in_line_item.dart';
import '../models/walk_in_session.dart';
import '../providers/order_provider.dart';
import '../providers/order_workflow_provider.dart';
import '../services/delivery_tracking_service.dart';
import '../services/pdf/pdf_document_service.dart';
import '../services/product_image_service.dart';
import '../services/speech_recognition_service.dart';
import 'bouquet_production_entry_screen.dart';
import 'delivery_screen.dart';
import 'cloud_order_edit_screen.dart';
import 'event_sale_screen.dart';
import 'live_delivery_tracking_screen.dart';
import 'pickup_later_screen.dart';
import 'take_away_screen.dart';
import '../data/repositories/cloud_inventory_repository.dart';
import '../utils/whatsapp_phone_utils.dart';
import '../utils/delivery_message_utils.dart';
import '../widgets/collect_payment_dialog.dart';
import '../widgets/common_widgets.dart';
import '../widgets/safe_platform_image.dart';
import '../widgets/schedule_payment_followup_dialog.dart';
import '../widgets/voice_dictation_field_header.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  final String? cloudOrderId;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    this.cloudOrderId,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final DeliveryTrackingService _deliveryTrackingService =
      DeliveryTrackingService();
  final ProductImageService _productImageService = const ProductImageService();
  final InventoryRepository _inventoryRepository = InventoryRepository();
  final ProductRepository _productRepository = ProductRepository();
  final OrderRepository _orderRepository = OrderRepository();
  List<InventoryReservationRecord> _orderReservations = [];
  Timer? _deliveryConnectivityTimer;
  DeliveryTrackingSnapshot? _deliveryTrackingSnapshot;
  Object? _deliveryTrackingError;
  DateTime? _deliveryTrackingLastSyncAt;
  int? _deliveryConnectivityOrderId;
  bool _deliveryConnectivityLoading = false;
  bool _generatingStartDeliveryLink = false;

  bool get _isCloudOrder {
    if (widget.cloudOrderId?.trim().isNotEmpty == true) return true;
    final headerCloudId = context.read<OrderProvider>().detailHeader?.cloudOrderId;
    return headerCloudId != null && headerCloudId.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrderDetailProgressive(
            widget.orderId,
            cloudOrderId: widget.cloudOrderId,
          );
      final workflowProvider = context.read<OrderWorkflowProvider>();
      if (!_isCloudOrder) {
        workflowProvider.loadWorkflow(widget.orderId);
      }
      workflowProvider.loadAssignableAssociates(
        isCloud: _isCloudOrder || kIsWeb,
      );
      _loadOrderReservations();
    });
  }

  Future<void> _loadOrderReservations() async {
    if (kIsWeb) return;
    try {
      final reservations = await _inventoryRepository.getReservationsForOrder(
        orderId: widget.orderId > 0 ? widget.orderId : null,
        cloudOrderId: widget.cloudOrderId,
      );
      if (mounted) {
        setState(() {
          _orderReservations = reservations;
        });
      }
    } catch (e) {
      debugPrint('[OrderDetailScreen] Error loading reservations: $e');
    }
  }

  @override
  void dispose() {
    _deliveryConnectivityTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.orderDetails),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Order',
            onPressed: _isCloudOrder ? () => _editCloudOrder() : () => _editOrder(),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Consumer<OrderProvider>(
          builder: (context, provider, _) {
            final header = provider.detailHeader;
            final detail = provider.detailBundle;

            if (provider.isDetailLoading && header == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (header == null) {
              return Center(child: Text(l10n.orderNotFound));
            }

            _ensureDeliveryConnectivityPolling(header);

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 800;

                if (isWide) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(24, 20, 24, 28 + bottomInset),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1400),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column (58% width): Customer, Items, Financials, Notes, Linkages
                            Expanded(
                              flex: 6,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildCustomerCard(header, colorScheme),
                                  const SizedBox(height: 16),
                                  _buildOrderItemsSection(header, detail, colorScheme),
                                  const SizedBox(height: 16),
                                  _buildFinancialSummaryCard(header, detail, colorScheme),
                                  if (_hasNotes(header, detail)) ...[
                                    const SizedBox(height: 16),
                                    _buildNotesCard(header, detail, colorScheme),
                                  ],
                                  if (_hasLinkages(detail)) ...[
                                    const SizedBox(height: 16),
                                    _buildLinkagesCard(detail!, colorScheme),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            // Right Column (42% width): Header summary, Payments, Fulfillment, Quick Actions, Timeline
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildOrderHeader(header, colorScheme),
                                  const SizedBox(height: 16),
                                  if (header.fulfilmentType == 'event_sale') ...[
                                    _buildEventPreparationCard(header, detail, colorScheme),
                                    const SizedBox(height: 16),
                                  ],
                                  _buildPaymentDetailsCard(header, detail, colorScheme),
                                  const SizedBox(height: 16),
                                  _buildFulfillmentCard(header, detail, colorScheme),
                                  const SizedBox(height: 16),
                                  _buildQuickActionsSection(header, detail, colorScheme),
                                  const SizedBox(height: 16),
                                  _buildTimelineCard(header, detail, colorScheme),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // Mobile / Narrow Viewport (Single Column Streamlined Stack)
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOrderHeader(header, colorScheme),
                      const SizedBox(height: 14),
                      _buildCustomerCard(header, colorScheme),
                      const SizedBox(height: 14),
                      _buildOrderItemsSection(header, detail, colorScheme),
                      if (header.fulfilmentType == 'event_sale') ...[
                        const SizedBox(height: 14),
                        _buildEventPreparationCard(header, detail, colorScheme),
                      ],
                      const SizedBox(height: 14),
                      _buildFinancialSummaryCard(header, detail, colorScheme),
                      const SizedBox(height: 14),
                      _buildPaymentDetailsCard(header, detail, colorScheme),
                      const SizedBox(height: 14),
                      _buildFulfillmentCard(header, detail, colorScheme),
                      if (_hasNotes(header, detail)) ...[
                        const SizedBox(height: 14),
                        _buildNotesCard(header, detail, colorScheme),
                      ],
                      const SizedBox(height: 14),
                      _buildQuickActionsSection(header, detail, colorScheme),
                      const SizedBox(height: 14),
                      _buildTimelineCard(header, detail, colorScheme),
                      if (_hasLinkages(detail)) ...[
                        const SizedBox(height: 14),
                        _buildLinkagesCard(detail!, colorScheme),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderHeader(
    OrderDetailHeader header,
    ColorScheme colorScheme,
  ) {
    final outstanding = header.outstandingAmountPaise;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Number & Status Chips Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => _copyOrderNumber(header.orderNo),
                      borderRadius: BorderRadius.circular(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              header.displayOrderNo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.copy_rounded,
                            size: 14,
                            color: colorScheme.primary.withValues(alpha: 0.7),
                          ),
                        ],
                      ),
                    ),
                    if (header.createdAt != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Placed on ${_formatDateTime(header.createdAt)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    StatusChip(
                      label: _pretty(header.status),
                      color: _getStatusColor(header.status),
                    ),
                    _buildPaymentStatusChip(header.paymentStatus),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Metadata Grid
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _headerValue('Fulfillment', _pretty(header.fulfilmentType)),
              _headerValue('Source', _pretty(header.source)),
              if (header.occasion.trim().isNotEmpty && header.occasion != '-')
                _headerValue('Occasion', header.occasion),
              if (header.scheduledAt != null)
                _headerValue('Delivery Date', _formatDate(header.scheduledAt)),
              if (header.deliverySlot.trim().isNotEmpty && header.deliverySlot != '-')
                _headerValue('Delivery Slot', _pretty(header.deliverySlot)),
            ],
          ),
          const SizedBox(height: 12),
          // Prominent Grand Total Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grand Total',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _formatPaise(header.grandTotalPaise),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (outstanding > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Outstanding',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade800,
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            _formatPaise(outstanding),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 14, color: Colors.green.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Fully Paid',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(
    OrderDetailHeader header,
    ColorScheme colorScheme,
  ) {
    final customerName = header.customerName.trim().isEmpty || header.customerName == '-'
        ? 'Walk-In Customer'
        : header.customerName;
    final hasCustomerPhone = header.customerPhone.trim().isNotEmpty && header.customerPhone != '-';
    final hasCustomerEmail = header.customerEmail != null &&
        header.customerEmail!.trim().isNotEmpty &&
        header.customerEmail != '-';
    final isRecipientDifferent = header.recipientName.trim().isNotEmpty &&
        header.recipientName != '-' &&
        header.recipientName.trim().toLowerCase() != customerName.trim().toLowerCase();
    final hasRecipientPhone = header.recipientPhone.trim().isNotEmpty &&
        header.recipientPhone != '-' &&
        header.recipientPhone != header.customerPhone;
    final hasAddress = header.address.trim().isNotEmpty && header.address != '-';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_pin_circle_outlined, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Customer & Delivery Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Customer (Ordered By) Block
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'ORDERED BY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    if (hasCustomerPhone)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.phone, size: 18, color: Colors.green),
                            tooltip: 'Call Customer',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            onPressed: () => _callNumber(header.customerPhone),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Colors.teal),
                            tooltip: 'WhatsApp Customer',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            onPressed: () => _whatsappNumber(header.customerPhone),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  customerName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E2922),
                  ),
                ),
                if (hasCustomerPhone) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.phone_iphone_rounded, size: 15, color: Colors.grey.shade700),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          header.customerPhone,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (hasCustomerEmail) ...[
                  const SizedBox(height: 3),
                  InkWell(
                    onTap: () => _emailCustomer(header.customerEmail),
                    child: Row(
                      children: [
                        Icon(Icons.email_outlined, size: 15, color: Colors.grey.shade700),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            header.customerEmail!,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Recipient & Address Block
          if (isRecipientDifferent || hasRecipientPhone || hasAddress) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'DELIVER TO / RECIPIENT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      if (hasRecipientPhone)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.phone, size: 18, color: Colors.green),
                              tooltip: 'Call Recipient',
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              onPressed: () => _callNumber(header.recipientPhone),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Colors.teal),
                              tooltip: 'WhatsApp Recipient',
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              onPressed: () => _whatsappNumber(header.recipientPhone),
                            ),
                          ],
                        ),
                    ],
                  ),
                  if (isRecipientDifferent) ...[
                    const SizedBox(height: 4),
                    Text(
                      header.recipientName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E2922),
                      ),
                    ),
                  ],
                  if (hasRecipientPhone) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.phone_iphone_rounded, size: 15, color: Colors.grey.shade700),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            header.recipientPhone,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (hasAddress) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on_outlined, size: 16, color: colorScheme.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                header.address,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade900,
                                ),
                              ),
                              if (header.deliveryLandmark.trim().isNotEmpty)
                                Text(
                                  'Landmark: ${header.deliveryLandmark}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                ),
                              if (header.deliveryPincode.trim().isNotEmpty)
                                Text(
                                  'PIN: ${header.deliveryPincode}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.near_me_rounded, size: 16),
                      label: const Text('Navigate / Google Maps'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () => _navigateToCustomerAddress(header.address),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderItemsSection(
    OrderDetailHeader header,
    OrderDetailBundle? detail,
    ColorScheme colorScheme,
  ) {
    final lines = detail?.lines ?? const <Map<String, Object?>>[];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.local_florist_rounded, size: 20, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Order Items (${lines.length})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatPaise(header.grandTotalPaise),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (lines.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No line items found for this order.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
              ),
            )
          else
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildRichOrderItemCard(line, colorScheme, header: header),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRichOrderItemCard(
    Map<String, Object?> line,
    ColorScheme colorScheme, {
    OrderDetailHeader? header,
  }) {
    final productName = (line['product_name'] as String?) ??
        (line['description'] as String?) ??
        'Item';
    final sku = (line['product_sku'] as String?) ?? (line['sku'] as String?);
    final qty = (line['qty'] as int?) ?? 1;
    final unitPrice = (line['unit_price_paise'] as int?) ?? 0;
    final discount = (line['discount_paise'] as int?) ?? 0;
    final gstPercent = (line['gst_percent'] as int?) ?? 0;
    final lineGst = (line['line_gst_paise'] as int?) ?? 0;
    final lineTotal = (line['line_total_paise'] as int?) ??
        (unitPrice > 0 ? unitPrice * qty : 0);
    final customization = (line['special_instructions'] as String?) ??
        (line['notes'] as String?) ??
        (line['design_ref'] as String?);

    final productId = (line['product_id'] as int?);
    final cloudProductId = (line['cloud_product_id'] as String?);
    final isEventSale = header != null &&
        (header.fulfilmentType.toLowerCase() == 'event_sale' ||
         header.fulfilmentType.toLowerCase() == 'event');
    final isInventoryProduct = (productId != null && productId > 0) ||
        (cloudProductId != null && cloudProductId.trim().isNotEmpty);

    final imageResult = _productImageService.resolveForOrderLine(line);

    List<InventoryReservationRecord> matchingReservations = [];
    int reservedQty = 0;
    if (isEventSale && isInventoryProduct) {
      matchingReservations = _orderReservations
          .where((r) =>
              r.status == 'active' &&
              ((line['id'] != null && r.orderLineId == line['id']) ||
               (productId != null && r.productId == productId)))
          .toList();
      reservedQty = matchingReservations.fold<int>(0, (sum, r) => sum + r.quantity);
    }
    final stillToArrange = (qty - reservedQty).clamp(0, qty);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 56,
              child: _buildItemThumbnail(imageResult, colorScheme),
            ),
          ),
          const SizedBox(width: 12),
          // Item Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        productName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatPaise(lineTotal),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                if (sku != null && sku.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'SKU: $sku',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                // Qty x Unit price + discount + GST row
                Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Qty: $qty × ${_formatPaise(unitPrice)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                    ),
                    if (discount > 0)
                      Text(
                        'Disc: -${_formatPaise(discount)}',
                        style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600),
                      ),
                    if (gstPercent > 0)
                      Text(
                        'GST $gstPercent% (${_formatPaise(lineGst)})',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                  ],
                ),
                if (customization != null && customization.trim().isNotEmpty && customization != '-') ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.format_quote_rounded, size: 13, color: Colors.amber.shade800),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            customization,
                            style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (isEventSale && isInventoryProduct) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: reservedQty > 0 ? Colors.teal.shade50 : Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: reservedQty > 0 ? Colors.teal.shade200 : Colors.blueGrey.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              reservedQty > 0 ? Icons.inventory_2_rounded : Icons.info_outline_rounded,
                              size: 15,
                              color: reservedQty > 0 ? Colors.teal.shade800 : Colors.blueGrey.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Event Stock Hold Status',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: reservedQty > 0 ? Colors.teal.shade900 : Colors.blueGrey.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildReservationMetric(
                              'Required',
                              '$qty',
                              Colors.blueGrey.shade700,
                            ),
                            const SizedBox(width: 8),
                            _buildReservationMetric(
                              'Reserved / Held',
                              '$reservedQty',
                              reservedQty > 0 ? Colors.teal.shade800 : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            _buildReservationMetric(
                              'Still to Arrange',
                              '$stillToArrange',
                              stillToArrange > 0 ? Colors.orange.shade800 : Colors.green.shade800,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          reservedQty == 0
                              ? 'Stock is not reserved for this event. Future event booking does not consume physical stock.'
                              : reservedQty >= qty
                                  ? 'All $qty unit(s) reserved from stock.'
                                  : '$reservedQty unit(s) reserved from stock. $stillToArrange unit(s) still to arrange.',
                          style: TextStyle(
                            fontSize: 11,
                            color: reservedQty > 0 ? Colors.teal.shade900 : Colors.blueGrey.shade800,
                          ),
                        ),
                        if (!kIsWeb && header.status != 'cancelled' && header.status != 'delivered') ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (stillToArrange > 0) ...[
                                TextButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const BouquetProductionEntryScreen()),
                                  ),
                                  icon: const Icon(Icons.precision_manufacturing_outlined, size: 14),
                                  label: const Text('Produce / Prepare', style: TextStyle(fontSize: 11)),
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    foregroundColor: Colors.orange.shade800,
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              OutlinedButton.icon(
                                icon: Icon(
                                  reservedQty > 0 ? Icons.edit : Icons.bookmark_add_outlined,
                                  size: 14,
                                ),
                                label: Text(
                                  reservedQty > 0 ? 'Edit Hold ($reservedQty)' : 'Reserve Stock',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  visualDensity: VisualDensity.compact,
                                  foregroundColor: reservedQty > 0 ? Colors.teal.shade800 : colorScheme.primary,
                                  side: BorderSide(
                                    color: reservedQty > 0 ? Colors.teal.shade400 : colorScheme.primary,
                                  ),
                                ),
                                onPressed: () => _showOrderDetailReserveStockDialog(
                                  line: line,
                                  requiredQty: qty,
                                  reservedQty: reservedQty,
                                  matchingReservations: matchingReservations,
                                  productId: productId,
                                  cloudProductId: cloudProductId,
                                  header: header,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationMetric(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showOrderDetailReserveStockDialog({
    required Map<String, Object?> line,
    required int requiredQty,
    required int reservedQty,
    required List<InventoryReservationRecord> matchingReservations,
    required int? productId,
    required String? cloudProductId,
    required OrderDetailHeader? header,
  }) async {
    if (productId == null || header == null) return;

    final allProducts = await _productRepository.listActiveProductsWithInventory();
    final currentProd = allProducts.firstWhere(
      (p) => p.id == productId,
      orElse: () => ProductInventoryRecord(
        id: productId,
        code: '',
        name: (line['product_name'] as String?) ?? 'Product',
        category: 'Other',
        defaultUnit: 'unit',
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

    final avail = currentProd.availableToSell + reservedQty;
    final maxCanReserve = avail.clamp(0, requiredQty);
    final reserveController = TextEditingController(
      text: (reservedQty > 0 ? reservedQty : maxCanReserve).toString(),
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
                  (line['product_name'] as String?) ?? 'Product',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text('Required for Event: $requiredQty'),
                Text('Available in Stock to Hold: $avail'),
                Text('Currently Held: $reservedQty'),
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
            if (reservedQty > 0)
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, 0),
                child: const Text('Release Hold', style: TextStyle(color: Colors.red)),
              ),
            FilledButton(
              onPressed: () {
                final qty = int.tryParse(reserveController.text.trim()) ?? 0;
                if (qty < 0 || qty > maxCanReserve) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Please enter a quantity between 0 and $maxCanReserve')),
                  );
                  return;
                }
                Navigator.pop(dialogContext, qty);
              },
              child: const Text('Save Reservation'),
            ),
          ],
        );
      },
    );

    if (newReserved == null || newReserved == reservedQty || !mounted) return;

    if (newReserved == 0) {
      for (final r in matchingReservations) {
        await _inventoryRepository.releaseReservation(r.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reservation released.')),
        );
      }
    } else if (newReserved > reservedQty) {
      final diff = newReserved - reservedQty;
      await _inventoryRepository.reserveStock(
        orderId: header.id,
        orderLineId: line['id'] as int?,
        productId: productId,
        cloudProductId: cloudProductId,
        quantity: diff,
        eventDate: header.scheduledAt != null
            ? '${header.scheduledAt!.year}-${header.scheduledAt!.month.toString().padLeft(2, '0')}-${header.scheduledAt!.day.toString().padLeft(2, '0')}'
            : null,
        eventName: '${header.customerName.isNotEmpty ? header.customerName : 'Event'} (#${header.orderNo})',
        notes: 'Reserved from order details',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reserved $newReserved unit(s) for event.')),
        );
      }
    } else {
      final toRelease = reservedQty - newReserved;
      int remainingToRelease = toRelease;
      for (final r in matchingReservations) {
        if (remainingToRelease <= 0) break;
        if (r.quantity <= remainingToRelease) {
          await _inventoryRepository.releaseReservation(r.id);
          remainingToRelease -= r.quantity;
        } else {
          await _inventoryRepository.releaseReservation(r.id);
          await _inventoryRepository.reserveStock(
            orderId: header.id,
            orderLineId: r.orderLineId,
            productId: productId,
            cloudProductId: cloudProductId,
            quantity: r.quantity - remainingToRelease,
            eventDate: r.eventDate,
            eventName: r.eventName,
            notes: r.notes,
          );
          remainingToRelease = 0;
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Updated hold to $newReserved unit(s).')),
        );
      }
    }

    await _loadOrderReservations();
  }

  Widget _buildItemThumbnail(ProductImageResult imageResult, ColorScheme colorScheme) {
    if (imageResult.hasImage) {
      return SafePlatformImageView(
        imagePath: imageResult.reference,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        fallbackIcon: Icons.local_florist_outlined,
        errorIcon: Icons.local_florist_outlined,
      );
    }
    return _buildItemPlaceholderIcon(colorScheme);
  }

  Widget _buildItemPlaceholderIcon(ColorScheme colorScheme, {double size = 56}) {
    return Container(
      width: size,
      height: size,
      color: colorScheme.primary.withValues(alpha: 0.08),
      child: Center(
        child: Icon(
          Icons.local_florist_rounded,
          size: size * 0.45,
          color: colorScheme.primary.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildFinancialSummaryCard(
    OrderDetailHeader header,
    OrderDetailBundle? detail,
    ColorScheme colorScheme,
  ) {
    final subtotal = header.subtotalPaise > 0
        ? header.subtotalPaise
        : _computeSubtotal(detail?.lines, header.grandTotalPaise);
    final itemDiscount = _computeItemDiscount(detail?.lines);
    final billDiscount = header.discountTotalPaise > 0
        ? header.discountTotalPaise
        : _readMarketplaceDiscount(detail);
    final rewardDiscount = header.rewardDiscountAmountPaise;
    final gstTotal = header.gstTotalPaise > 0
        ? header.gstTotalPaise
        : _computeGst(detail?.lines);
    final deliveryFee = header.deliveryChargesPaise > 0
        ? header.deliveryChargesPaise
        : _readDeliveryFee(detail);
    final roundOff = header.roundOffPaise;
    final grandTotal = header.grandTotalPaise;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_rounded, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Financial Summary',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Items Subtotal', _formatPaise(subtotal)),
          if (itemDiscount > 0)
            _buildSummaryRow('Item Discounts', '- ${_formatPaise(itemDiscount)}', isGreen: true),
          if (billDiscount > 0)
            _buildSummaryRow('Order Discount', '- ${_formatPaise(billDiscount)}', isGreen: true),
          if (rewardDiscount > 0)
            _buildSummaryRow(
              'Reward Points (${header.rewardPointsRedeemed} pts)',
              '- ${_formatPaise(rewardDiscount)}',
              isGreen: true,
            ),
          if (gstTotal > 0)
            _buildSummaryRow('GST / Taxes', _formatPaise(gstTotal)),
          if (deliveryFee > 0)
            _buildSummaryRow('Delivery Charges', _formatPaise(deliveryFee)),
          if (roundOff != 0)
            _buildSummaryRow('Round Off', _formatPaise(roundOff)),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Grand Total',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                _formatPaise(grandTotal),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
    bool isGreen = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isGreen ? Colors.green.shade700 : valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetailsCard(
    OrderDetailHeader header,
    OrderDetailBundle? detail,
    ColorScheme colorScheme,
  ) {
    final outstanding = header.outstandingAmountPaise;
    final paid = header.paidAmountPaise;
    final grandTotal = header.grandTotalPaise;
    final payments = detail?.payments ?? const <Map<String, Object?>>[];

    // Classify payments according to Stage 3 rules:
    final saleTenders = <Map<String, Object?>>[];
    final creditCollections = <Map<String, Object?>>[];
    final adjustments = <Map<String, Object?>>[];

    for (final p in payments) {
      final type = (p['payment_type'] as String?)?.trim().toLowerCase();
      if (type == 'creditcollection') {
        creditCollections.add(p);
      } else if (type == 'adjustment') {
        adjustments.add(p);
      } else {
        // Defaults to SaleTender
        saleTenders.add(p);
      }
    }

    // Credit created at sale:
    final saleTenderSum = saleTenders.fold<int>(
      0,
      (sum, p) => sum + ((p['amount_paise'] as int?) ?? 0),
    );
    final creditCreated = (grandTotal - saleTenderSum).clamp(0, grandTotal);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.payment_rounded, size: 20, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Payment Details',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildPaymentStatusChip(header.paymentStatus),
            ],
          ),
          const SizedBox(height: 12),
          // Summary row inside payment card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order Total', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(_formatPaise(grandTotal), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Paid Amount', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(_formatPaise(paid), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Balance Due', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _formatPaise(outstanding),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: outstanding > 0 ? Colors.red.shade700 : Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (outstanding > 0) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.payments_outlined, size: 18),
                label: Text('Collect Payment (${_formatPaise(outstanding)})'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _collectPayment(header),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.alarm_add_outlined, size: 18),
                label: const Text('Schedule Payment Follow-up'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  showSchedulePaymentFollowUpDialog(
                    context: context,
                    orderId: header.id,
                    cloudOrderId: header.cloudOrderId,
                    orderNo: header.orderNo,
                    customerName: header.customerName,
                    outstandingAmountPaise: header.outstandingAmountPaise,
                  );
                },
              ),
            ),
          ],
          if (paid > 0 && outstanding == 0) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: const Text('Adjust Payment'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _startPaymentAdjustment(header),
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          const Text(
            'Tender Breakdown',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          if (payments.isEmpty && creditCreated == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No payments recorded.', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
            )
          else ...[
            // 1. Sale Tenders
            if (saleTenders.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 6),
                child: Text('Sale Tenders (Checkout)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade700)),
              ),
              ...saleTenders.map((p) => _buildPaymentRow(p, isSaleTender: true)),
            ],
            // 2. Credit Created
            if (creditCreated > 0) ...[
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.credit_card_off_rounded, size: 15, color: Colors.amber.shade900),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Credit Created at Checkout',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.amber.shade900),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(_formatPaise(creditCreated), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                    ],
                  ),
                ),
              ),
            ],
            // 3. Credit Collections
            if (creditCollections.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 6),
                child: Text('Credit Collections (Subsequent)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
              ),
              ...creditCollections.map((p) => _buildPaymentRow(p, isCollection: true)),
            ],
            // 4. Adjustments
            if (adjustments.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 6),
                child: Text('Adjustments', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple.shade800)),
              ),
              ...adjustments.map((p) => _buildPaymentRow(p)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentStatusChip(String status) {
    final s = status.toLowerCase();
    Color bg;
    Color fg;
    if (s == 'paid') {
      bg = Colors.green.shade50;
      fg = Colors.green.shade800;
    } else if (s == 'partial' || s == 'partiallypaid') {
      bg = Colors.amber.shade50;
      fg = Colors.orange.shade900;
    } else if (s == 'credit') {
      bg = Colors.deepOrange.shade50;
      fg = Colors.deepOrange.shade900;
    } else {
      bg = Colors.red.shade50;
      fg = Colors.red.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _pretty(status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildPaymentRow(Map<String, Object?> payment, {bool isSaleTender = false, bool isCollection = false}) {
    final method = (payment['method'] as String?) ?? 'Unknown';
    final amount = (payment['amount_paise'] as int?) ?? 0;
    final reference = (payment['reference'] as String?) ?? (payment['transactionId'] as String?);
    final createdAt = (payment['created_at'] as String?);
    final dt = createdAt == null ? null : DateTime.tryParse(createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(_getPaymentMethodIcon(method), size: 15, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_pretty(method), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      if (reference != null && reference.isNotEmpty)
                        Text(
                          'Ref: $reference',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (dt != null)
                        Text(
                          _formatDateTime(dt),
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(_formatPaise(amount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.money_rounded;
      case 'upi':
      case 'gpay':
      case 'phonepe':
      case 'paytm':
        return Icons.qr_code_rounded;
      case 'card':
      case 'credit_card':
      case 'debit_card':
        return Icons.credit_card_rounded;
      case 'banktransfer':
      case 'bank_transfer':
      case 'netbanking':
        return Icons.account_balance_rounded;
      case 'credit':
        return Icons.credit_score_rounded;
      default:
        return Icons.payment_rounded;
    }
  }

  Widget _buildFulfillmentCard(
    OrderDetailHeader header,
    OrderDetailBundle? detail,
    ColorScheme colorScheme,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping_outlined, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Fulfillment & Staff',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Fulfillment Type & Schedule Row
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _headerValue('Fulfillment Type', _pretty(header.fulfilmentType)),
              if (header.scheduledAt != null)
                _headerValue('Scheduled Date', _formatDate(header.scheduledAt)),
              if (header.deliverySlot.trim().isNotEmpty && header.deliverySlot != '-')
                _headerValue('Delivery Slot', _pretty(header.deliverySlot)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Assigned Staff Row
          Row(
            children: [
              Expanded(
                child: _assignedToChip(
                  Icons.brush_rounded,
                  'Designer',
                  header.designerName,
                  colorScheme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _assignedToChip(
                  Icons.delivery_dining_rounded,
                  'Delivery',
                  header.deliveryName,
                  colorScheme,
                ),
              ),
            ],
          ),
          // Live Connectivity & Tracking CTA
          if (_shouldShowDeliveryConnectivity(header)) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  _buildDeliveryConnectivityIndicator(header, colorScheme),
                  OutlinedButton.icon(
                    onPressed: () => _openLiveTracking(header),
                    icon: const Icon(Icons.location_searching_rounded, size: 14),
                    label: const Text('Track Live', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesCard(
    OrderDetailHeader header,
    OrderDetailBundle? detail,
    ColorScheme colorScheme,
  ) {
    final cardMessage = header.cardMessage.trim();
    final instructions = header.specialInstructions.trim();
    final internalNotes = header.internalNotes?.trim() ?? '';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes_rounded, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Notes & Instructions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (cardMessage.isNotEmpty && cardMessage != '-') ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFE0B2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.card_giftcard_rounded, size: 16, color: Color(0xFFE65100)),
                      const SizedBox(width: 6),
                      Text(
                        'Card Message',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cardMessage,
                    style: const TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF4E342E),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (instructions.isNotEmpty && instructions != '-') ...[
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery Instructions',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(instructions, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ],
          if (internalNotes.isNotEmpty && internalNotes != instructions && internalNotes != '-') ...[
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Internal Notes',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(internalNotes, style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(
    OrderDetailHeader header,
    OrderDetailBundle? detail,
    ColorScheme colorScheme,
  ) {
    if (_isCloudOrder) {
      return _buildCloudQuickActions(header, detail);
    } else {
      return _buildWorkflowQuickActions(header, detail);
    }
  }

  Widget _buildTimelineCard(
    OrderDetailHeader header,
    OrderDetailBundle? detail,
    ColorScheme colorScheme,
  ) {
    final timeline = detail?.timeline ?? const <OrderTimelineItem>[];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              const Text(
                'Order Timeline',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (timeline.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No timeline events yet.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
              ),
            )
          else
            ...timeline.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 16,
                      color: _getStatusColor(item.status),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _pretty(item.status),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          if (item.notes != null && item.notes!.trim().isNotEmpty)
                            Text(
                              item.notes!,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          Text(
                            _formatDateTime(item.createdAt),
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLinkagesCard(OrderDetailBundle detail, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Linkages & Sync Status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildLinkageRow(
                'Scheduler Tasks',
                '${detail.schedulerTasks.length}',
              ),
              _buildLinkageRow(
                'Inventory Impact Rows',
                '${detail.inventoryTransactions.length}',
              ),
              _buildLinkageRow(
                'Receipt Status',
                (detail.receiptStatus ?? 'pending').toString(),
              ),
              _buildLinkageRow(
                'WhatsApp Status',
                (detail.whatsappStatus ?? 'pending').toString(),
              ),
            ],
          ),
        ),
        if (detail.relayInfo.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildInfoCard('Relay Information', detail.relayInfo),
        ],
        if (detail.corporateInfo.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildInfoCard('Corporate Information', detail.corporateInfo),
        ],
        if (detail.marketplaceInfo.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildInfoCard('Marketplace Information', detail.marketplaceInfo),
        ],
      ],
    );
  }

  bool _hasNotes(OrderDetailHeader header, OrderDetailBundle? detail) {
    return (header.cardMessage.trim().isNotEmpty && header.cardMessage != '-') ||
        (header.specialInstructions.trim().isNotEmpty && header.specialInstructions != '-') ||
        (header.internalNotes != null &&
            header.internalNotes!.trim().isNotEmpty &&
            header.internalNotes != '-');
  }

  bool _hasLinkages(OrderDetailBundle? detail) {
    if (detail == null) return false;
    return detail.schedulerTasks.isNotEmpty ||
        detail.inventoryTransactions.isNotEmpty ||
        detail.relayInfo.isNotEmpty ||
        detail.corporateInfo.isNotEmpty ||
        detail.marketplaceInfo.isNotEmpty;
  }

  int _computeSubtotal(List<Map<String, Object?>>? lines, int fallbackTotal) {
    if (lines == null || lines.isEmpty) return fallbackTotal;
    int sum = 0;
    for (final line in lines) {
      final sub = line['line_subtotal_paise'] as int?;
      final price = line['unit_price_paise'] as int?;
      final qty = (line['qty'] as int?) ?? 1;
      if (sub != null && sub > 0) {
        sum += sub;
      } else if (price != null && price > 0) {
        sum += price * qty;
      }
    }
    return sum > 0 ? sum : fallbackTotal;
  }

  int _computeItemDiscount(List<Map<String, Object?>>? lines) {
    if (lines == null || lines.isEmpty) return 0;
    int sum = 0;
    for (final line in lines) {
      sum += (line['discount_paise'] as int?) ?? 0;
    }
    return sum;
  }

  int _computeGst(List<Map<String, Object?>>? lines) {
    if (lines == null || lines.isEmpty) return 0;
    int sum = 0;
    for (final line in lines) {
      sum += (line['line_gst_paise'] as int?) ?? 0;
    }
    return sum;
  }

  int _readMarketplaceDiscount(OrderDetailBundle? detail) {
    if (detail == null) return 0;
    return (detail.marketplaceInfo['discount_amount_paise'] as int?) ?? 0;
  }

  int _readDeliveryFee(OrderDetailBundle? detail) {
    if (detail == null) return 0;
    return (detail.marketplaceInfo['delivery_fee_paise'] as int?) ?? 0;
  }

  Future<void> _callNumber(String? phone) async {
    final clean = phone?.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean == null || clean.isEmpty) return;
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showSnack('Unable to place call to $clean');
    }
  }

  Future<void> _whatsappNumber(String? phone) async {
    final uri = WhatsAppPhoneUtils.buildUri(phone);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnack('Unable to open WhatsApp for $phone');
    }
  }

  Future<void> _emailCustomer(String? email) async {
    final clean = email?.trim();
    if (clean == null || clean.isEmpty) return;
    final uri = Uri.parse('mailto:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showSnack('Unable to send email to $clean');
    }
  }

  void _copyOrderNumber(String orderNo) {
    Clipboard.setData(ClipboardData(text: orderNo));
    _showSnack('Copied $orderNo to clipboard');
  }

  Widget _headerValue(String label, String value, {bool isAlert = false}) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),
          Text(
            value.trim().isEmpty ? '-' : value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isAlert ? Colors.red.shade700 : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _assignedToChip(
    IconData icon,
    String role,
    String? name,
    ColorScheme colorScheme,
  ) {
    final assigned = name != null && name.trim().isNotEmpty;
    final color = assigned ? colorScheme.primary : Colors.grey.shade400;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: assigned
            ? colorScheme.primary.withValues(alpha: 0.08)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
                Text(
                  assigned ? name : 'Not Assigned',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: assigned ? null : Colors.grey.shade500,
                    fontStyle: assigned ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _ensureDeliveryConnectivityPolling(OrderDetailHeader header) {
    if (!_shouldShowDeliveryConnectivity(header)) {
      _deliveryConnectivityTimer?.cancel();
      _deliveryConnectivityTimer = null;
      _deliveryConnectivityOrderId = null;
      return;
    }

    if (_deliveryConnectivityOrderId == header.id) return;
    _deliveryConnectivityOrderId = header.id;
    _deliveryConnectivityTimer?.cancel();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _deliveryConnectivityOrderId != header.id) return;
      _refreshDeliveryConnectivity(header);
      _deliveryConnectivityTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _refreshDeliveryConnectivity(header),
      );
    });
  }

  bool _shouldShowDeliveryConnectivity(OrderDetailHeader header) {
    final fulfilment = header.fulfilmentType.toLowerCase();
    return fulfilment.contains('delivery') ||
        ((header.deliveryName ?? '').trim().isNotEmpty) ||
        _isDeliveryInMotion(header.status);
  }

  Future<void> _refreshDeliveryConnectivity(OrderDetailHeader header) async {
    if (_deliveryConnectivityLoading) return;
    if (mounted) {
      setState(() => _deliveryConnectivityLoading = true);
    }

    try {
      DeliveryTrackingSnapshot snapshot;
      final isCloud = _isCloudOrder ||
          kIsWeb ||
          (header.cloudOrderId?.trim().isNotEmpty == true);
      if (isCloud) {
        final cloudId = (header.cloudOrderId?.trim().isNotEmpty == true)
            ? header.cloudOrderId!.trim()
            : widget.cloudOrderId?.trim();
        if (cloudId != null && cloudId.isNotEmpty) {
          snapshot = await _deliveryTrackingService
              .getTrackingForCloudOrder(cloudId);
        } else {
          final deliveryId = await _deliveryTrackingService.getCloudDeliveryId(
            orderNo: header.orderNo,
          );
          if (deliveryId == null || deliveryId.trim().isEmpty) return;
          snapshot = await _deliveryTrackingService
              .getTrackingByAssignmentId(deliveryId.trim());
        }
      } else {
        snapshot =
            await _deliveryTrackingService.getTrackingForLocalOrder(header.id);
      }
      if (!mounted || _deliveryConnectivityOrderId != header.id) return;
      setState(() {
        _deliveryTrackingSnapshot = snapshot;
        _deliveryTrackingError = null;
        _deliveryTrackingLastSyncAt = DateTime.now();
        _deliveryConnectivityLoading = false;
      });
    } catch (error) {
      if (!mounted || _deliveryConnectivityOrderId != header.id) return;
      setState(() {
        _deliveryTrackingError = error;
        _deliveryConnectivityLoading = false;
      });
    }
  }

  Widget _buildDeliveryConnectivityIndicator(
    OrderDetailHeader header,
    ColorScheme colorScheme,
  ) {
    final state = _deliveryConnectivityState(header);
    final updatedLabel = _deliveryUpdatedAgoLabel();
    return Tooltip(
      message: state.tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showDeliveryConnectivitySheet(header),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: state.color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: state.color.withValues(alpha: 0.35)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: state.color,
                      shape: BoxShape.circle,
                      border: state.kind == _DeliveryConnectivityKind.notStarted
                          ? Border.all(color: Colors.grey.shade500)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    state.label,
                    style: TextStyle(
                      color: state.textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              if (updatedLabel != null) ...[
                const SizedBox(height: 2),
                Text(
                  updatedLabel,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  _DeliveryConnectivityState _deliveryConnectivityState(
    OrderDetailHeader header,
  ) {
    final snapshot = _deliveryTrackingSnapshot;
    final lastLocation = snapshot?.lastLocation;
    final now = DateTime.now();
    final status = (snapshot?.status ?? header.status).toLowerCase();
    final accepted = _isDeliveryInMotion(status);

    if (!accepted && lastLocation == null) {
      return _DeliveryConnectivityState.notStarted();
    }

    if (_deliveryTrackingError != null && _deliveryTrackingLastSyncAt == null) {
      return _DeliveryConnectivityState.noInternet();
    }

    if (lastLocation == null) {
      return _DeliveryConnectivityState.driverOffline();
    }

    final age = now.difference(lastLocation.recordedAt.toLocal());
    if (_deliveryTrackingError != null) {
      return _DeliveryConnectivityState.serverUnreachable();
    }
    if (age > const Duration(minutes: 5)) {
      return _DeliveryConnectivityState.driverOffline();
    }
    if (age <= const Duration(seconds: 60)) {
      return _DeliveryConnectivityState.live();
    }
    return _DeliveryConnectivityState.delayed();
  }

  String? _deliveryUpdatedAgoLabel() {
    final lastGps = _deliveryTrackingSnapshot?.lastLocation?.recordedAt;
    final updatedAt = lastGps ?? _deliveryTrackingLastSyncAt;
    if (updatedAt == null) return null;
    return 'Updated ${_relativeTime(updatedAt)} ago';
  }

  String _relativeTime(DateTime value) {
    final elapsed = DateTime.now().difference(value.toLocal());
    if (elapsed.inSeconds < 5) return 'now';
    if (elapsed.inSeconds < 60) return '${elapsed.inSeconds} sec';
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes} min';
    if (elapsed.inHours < 24) return '${elapsed.inHours} hr';
    return '${elapsed.inDays} d';
  }

  String _clockTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour == 0
        ? 12
        : local.hour > 12
            ? local.hour - 12
            : local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  Color _batteryColor(int battery) {
    if (battery <= 20) return Colors.red;
    if (battery <= 40) return Colors.amber.shade700;
    return Colors.green;
  }

  String _batteryLabel(int? battery) {
    if (battery == null) return 'Not available';
    return '$battery%';
  }

  bool _isDeliveryInMotion(String status) {
    final normalized = status.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    return normalized.contains('accepted') ||
        normalized.contains('pickedup') ||
        normalized.contains('outfordelivery') ||
        normalized.contains('intransit') ||
        normalized.contains('started') ||
        normalized.contains('delivered');
  }

  void _showDeliveryConnectivitySheet(OrderDetailHeader header) {
    final state = _deliveryConnectivityState(header);
    final snapshot = _deliveryTrackingSnapshot;
    final location = snapshot?.lastLocation;
    final driverOnline = state.kind == _DeliveryConnectivityKind.live ||
        state.kind == _DeliveryConnectivityKind.delayed;
    final battery = location?.batteryPercentage;
    final driverName = snapshot?.driver?.name.trim();

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery Tracking',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _statusDot(state),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.label,
                        style: TextStyle(
                          color: state.textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (state.kind == _DeliveryConnectivityKind.live)
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _openLiveTracking(header);
                        },
                        icon: const Icon(Icons.location_searching_rounded),
                        label: const Text('Track Driver'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _connectivityDetailRow(
                  'Driver Online',
                  driverOnline ? 'Yes' : 'No',
                ),
                _connectivityDetailRow(
                  'Driver',
                  driverName == null || driverName.isEmpty ? '-' : driverName,
                ),
                _connectivityDetailRow(
                  'Last Seen',
                  location == null
                      ? 'Not available'
                      : _clockTime(location.recordedAt),
                ),
                _connectivityDetailRow(
                  'GPS Accuracy',
                  location?.accuracyMeters == null
                      ? 'Not available'
                      : '${location!.accuracyMeters!.toStringAsFixed(0)} m',
                ),
                _connectivityDetailRow(
                  'Battery',
                  _batteryLabel(battery),
                  valueColor: battery == null ? null : _batteryColor(battery),
                ),
                _connectivityDetailRow(
                  'Last Updated',
                  location == null
                      ? 'Not available'
                      : '${_relativeTime(location.recordedAt)} ago',
                ),
                _connectivityDetailRow(
                  'Last Known Location',
                  location == null
                      ? 'Not available'
                      : '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _refreshDeliveryConnectivity(header),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Refresh Now'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _openLiveTracking(header);
                        },
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Track Driver'),
                      ),
                    ),
                  ],
                ),
                if (_deliveryTrackingError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Tracking is unavailable right now. Last known location is preserved when available.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusDot(_DeliveryConnectivityState state) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: state.color,
        shape: BoxShape.circle,
        border: state.kind == _DeliveryConnectivityKind.notStarted
            ? Border.all(color: Colors.grey.shade500)
            : null,
      ),
    );
  }

  Widget _connectivityDetailRow(
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowQuickActions(
    OrderDetailHeader header,
    OrderDetailBundle? detail,
  ) {
    return Consumer<OrderWorkflowProvider>(
      builder: (context, workflowProvider, _) {
        final disabled = workflowProvider.isLoading;
        final isEventSale = header.fulfilmentType == 'event_sale';
        final deliveryAssigned =
            (header.deliveryName ?? '').trim().isNotEmpty ||
                header.status == 'out_for_delivery' ||
                header.status == 'delivered';
        final actions = [
          if (isEventSale) ...[
            _OrderQuickAction(
              'Produce / Prepare',
              Icons.precision_manufacturing_outlined,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BouquetProductionEntryScreen()),
              ),
            ),
            if (header.status == OrderStatus.confirmed)
              _OrderQuickAction(
                'Start Preparing',
                Icons.build_circle_outlined,
                disabled ? null : () => _advanceEventStatus(header, detail, OrderStatus.preparing),
              ),
            if (header.status == OrderStatus.preparing)
              _OrderQuickAction(
                'Mark Ready',
                Icons.check_circle_outline,
                disabled ? null : () => _advanceEventStatus(header, detail, OrderStatus.ready),
              ),
            if (header.status == OrderStatus.ready)
              _OrderQuickAction(
                'Fulfill Event',
                Icons.task_alt,
                disabled ? null : () => _advanceEventStatus(header, detail, OrderStatus.delivered),
              ),
            _OrderQuickAction(
              'Change Status',
              Icons.swap_horiz_rounded,
              disabled ? null : () => _showStatusChangeDialog(header, detail),
            ),
          ],
          if (header.outstandingAmountPaise > 0)
            _OrderQuickAction(
              'Collect Payment',
              Icons.payments_outlined,
              disabled ? null : () => _collectPayment(header),
            ),
          if (header.paidAmountPaise > 0)
            _OrderQuickAction(
              'Adjust Payment',
              Icons.tune_rounded,
              disabled ? null : () => _startPaymentAdjustment(header),
            ),
          _OrderQuickAction(
            'Assign Designer',
            Icons.design_services,
            disabled ? null : () => _assignDesigner(header, detail),
          ),
          if (!deliveryAssigned && !isEventSale)
            _OrderQuickAction(
              'Assign Delivery',
              Icons.delivery_dining,
              disabled ? null : () => _assignDelivery(header, detail),
            ),
          if (!isEventSale) ...[
            _OrderQuickAction(
              _generatingStartDeliveryLink
                  ? 'Generating Link...'
                  : 'Generate Start Delivery Link',
              Icons.local_shipping_outlined,
              disabled || _generatingStartDeliveryLink
                  ? null
                  : () => _generateStartDeliveryLink(header),
              isLoading: _generatingStartDeliveryLink,
            ),
            _OrderQuickAction(
              'Call Driver',
              Icons.call_rounded,
              disabled || !deliveryAssigned ? null : () => _callDriver(header),
            ),
            _OrderQuickAction(
              'Navigate',
              Icons.near_me_rounded,
              disabled || header.address.trim().isEmpty
                  ? null
                  : () => _navigateToCustomerAddress(header.address),
            ),
            _OrderQuickAction(
              'Track Driver',
              Icons.location_searching_rounded,
              disabled || !deliveryAssigned
                  ? null
                  : () => _openLiveTracking(header),
            ),
            _OrderQuickAction(
              'Share Tracking Link',
              Icons.share_rounded,
              disabled || !deliveryAssigned
                  ? null
                  : () => _shareTrackingLinkViaWhatsApp(header),
            ),
          ],
          _OrderQuickAction(
            'Forward Associate',
            Icons.forward_to_inbox,
            disabled ? null : () => _forwardAssociate(header, detail),
          ),
          _OrderQuickAction(
            'Print',
            Icons.print,
            disabled ? null : () => _showPrintMenu(header, detail),
          ),
          _OrderQuickAction(
            'More',
            Icons.more_horiz,
            () => _showMoreMenu(header, detail),
          ),
        ];

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: actions.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 64,
                ),
                itemBuilder: (context, index) {
                  final action = actions[index];
                  final color = Theme.of(context).colorScheme.primary;
                  return InkWell(
                    onTap: action.onTap,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(10),
                        color: color.withValues(alpha: 0.07),
                      ),
                      child: Row(
                        children: [
                          if (action.isLoading)
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: color,
                              ),
                            )
                          else
                            Icon(action.icon, color: color, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              action.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              if (workflowProvider.error != null) ...[
                const SizedBox(height: 8),
                Text(
                  workflowProvider.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCloudQuickActions(
    OrderDetailHeader header,
    OrderDetailBundle? detail,
  ) {
    final isEventSale = header.fulfilmentType == 'event_sale';
    final canNavigate = header.address.trim().isNotEmpty && header.address != '-';
    final canCancel = OrderStatus.canCancel(header.status);
    final deliveryAssigned = (header.deliveryName ?? '').trim().isNotEmpty ||
        header.status == 'out_for_delivery' ||
        header.status == 'delivered';

    final actions = [
      if (isEventSale) ...[
        _OrderQuickAction(
          'Produce / Prepare',
          Icons.precision_manufacturing_outlined,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BouquetProductionEntryScreen()),
          ),
        ),
        if (header.status == OrderStatus.confirmed)
          _OrderQuickAction(
            'Start Preparing',
            Icons.build_circle_outlined,
            () => _advanceEventStatus(header, detail, OrderStatus.preparing),
          ),
        if (header.status == OrderStatus.preparing)
          _OrderQuickAction(
            'Mark Ready',
            Icons.check_circle_outline,
            () => _advanceEventStatus(header, detail, OrderStatus.ready),
          ),
        if (header.status == OrderStatus.ready)
          _OrderQuickAction(
            'Fulfill Event',
            Icons.task_alt,
            () => _advanceEventStatus(header, detail, OrderStatus.delivered),
          ),
      ],
      _OrderQuickAction(
        'View Bill',
        Icons.receipt_long,
        () => _showBill(header, detail),
      ),
      _OrderQuickAction(
        'Print',
        Icons.print,
        () => _showPrintMenu(header, detail),
      ),
      _OrderQuickAction(
        'Navigate',
        Icons.near_me_rounded,
        canNavigate ? () => _navigateToCustomerAddress(header.address) : null,
      ),
      if (header.outstandingAmountPaise > 0)
        _OrderQuickAction(
          'Collect Payment',
          Icons.payments_outlined,
          () => _collectPayment(header),
        ),
      if (header.paidAmountPaise > 0)
        _OrderQuickAction(
          'Adjust Payment',
          Icons.tune_rounded,
          () => _startPaymentAdjustment(header),
        ),
      _OrderQuickAction(
        'Assign Designer',
        Icons.design_services,
        () => _assignCloudDesigner(header),
      ),
      if (!isEventSale) ...[
        _OrderQuickAction(
          'Assign Delivery',
          Icons.delivery_dining,
          () => _assignCloudDelivery(header),
        ),
        _OrderQuickAction(
          _generatingStartDeliveryLink
              ? 'Generating Link...'
              : 'Generate Start Delivery Link',
          Icons.local_shipping_outlined,
          _generatingStartDeliveryLink
              ? null
              : () => _generateStartDeliveryLink(header),
          isLoading: _generatingStartDeliveryLink,
        ),
        _OrderQuickAction(
          'Call Driver',
          Icons.call_rounded,
          deliveryAssigned ? () => _callDriver(header) : null,
        ),
        _OrderQuickAction(
          'Track Driver',
          Icons.location_searching_rounded,
          deliveryAssigned ? () => _openLiveTracking(header) : null,
        ),
        _OrderQuickAction(
          'Share Tracking Link',
          Icons.share_rounded,
          deliveryAssigned ? () => _shareTrackingLinkViaWhatsApp(header) : null,
        ),
      ],
      _OrderQuickAction(
        'Forward Associate',
        Icons.forward_to_inbox,
        () => _forwardAssociate(header, detail),
      ),
      _OrderQuickAction(
        'Change Status',
        Icons.swap_horiz_rounded,
        () => _showStatusChangeDialog(header, detail),
      ),
      _OrderQuickAction(
        'Cancel Order',
        Icons.cancel_outlined,
        canCancel ? () => _confirmCancelCloudOrder(header) : null,
      ),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cloud Actions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 64,
            ),
            itemBuilder: (context, index) {
              final action = actions[index];
              final color = Theme.of(context).colorScheme.primary;
              return InkWell(
                onTap: action.onTap,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(10),
                    color: color.withValues(alpha: 0.07),
                  ),
                  child: Row(
                    children: [
                      Icon(action.icon, color: color, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          action.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _generateStartDeliveryLink(OrderDetailHeader header) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _generatingStartDeliveryLink = true);
    String? driverLink;
    Object? failure;
    try {
      String? deliveryId;
      if (_isCloudOrder ||
          kIsWeb ||
          (header.cloudOrderId?.trim().isNotEmpty == true)) {
        deliveryId = await _deliveryTrackingService.getCloudDeliveryId(
          cloudOrderId: header.cloudOrderId,
          orderNo: header.orderNo,
        );
      } else {
        deliveryId = await _deliveryTrackingService
            .resolveOrCreateCloudDeliveryId(header.id);
      }
      if (deliveryId == null || deliveryId.trim().isEmpty) {
        throw const DeliveryTrackingException(
          'Unable to create or find delivery record.',
        );
      }

      final links = await _deliveryTrackingService.generateTrackingLinks(
        deliveryId.trim(),
      );
      driverLink = links.driverLink.trim();
      if (driverLink.isEmpty) {
        throw const DeliveryTrackingException(
          'The Start Delivery link was not returned. Please try again.',
        );
      }
    } catch (error) {
      failure = error;
    } finally {
      if (mounted) {
        setState(() => _generatingStartDeliveryLink = false);
      }
    }

    if (!mounted) return;
    if (failure != null) {
      messenger.showSnackBar(SnackBar(content: Text(failure.toString())));
      return;
    }

    await _showStartDeliveryLinkDialog(driverLink!);
  }

  Future<void> _showStartDeliveryLinkDialog(String driverLink) async {
    final messenger = ScaffoldMessenger.of(context);
    final linkUri = Uri.parse(driverLink);
    final shareMessage = 'START DELIVERY LINK\n\n$driverLink';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('START DELIVERY LINK'),
        content: SelectableText(driverLink),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: driverLink));
              messenger.showSnackBar(
                const SnackBar(content: Text('Start Delivery link copied.')),
              );
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy Link'),
          ),
          TextButton.icon(
            onPressed: () async {
              final opened = await _launchExternalUri(linkUri);
              if (!opened) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Unable to open the Start Delivery link.'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Open Link'),
          ),
          TextButton.icon(
            onPressed: () => Share.share(
              shareMessage,
              subject: 'Floraprise Start Delivery link',
            ),
            icon: const Icon(Icons.share_rounded),
            label: const Text('Share'),
          ),
          TextButton.icon(
            onPressed: () async {
              final uri = Uri.https('wa.me', '/', {'text': shareMessage});
              final opened = await _launchExternalUri(uri);
              if (!opened) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Unable to open WhatsApp.')),
                );
              }
            },
            icon: const Icon(Icons.chat_rounded),
            label: const Text('Send via WhatsApp'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _openLiveTracking(OrderDetailHeader header) async {
    if (!mounted) return;
    final isCloud = _isCloudOrder ||
        kIsWeb ||
        (header.cloudOrderId?.trim().isNotEmpty == true);
    String? assignmentId;
    if (isCloud) {
      assignmentId = await _deliveryTrackingService.getCloudDeliveryId(
        cloudOrderId: header.cloudOrderId,
        orderNo: header.orderNo,
      );
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveDeliveryTrackingScreen(
          orderId: isCloud ? null : header.id,
          cloudOrderId:
              isCloud ? (header.cloudOrderId ?? widget.cloudOrderId) : null,
          assignmentId: assignmentId,
        ),
      ),
    );
  }

  Future<void> _callDriver(OrderDetailHeader header) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      DeliveryTrackingSnapshot? snapshot = _deliveryTrackingSnapshot;
      if (snapshot == null) {
        final isCloud = _isCloudOrder ||
            kIsWeb ||
            (header.cloudOrderId?.trim().isNotEmpty == true);
        if (isCloud) {
          final cloudId = (header.cloudOrderId?.trim().isNotEmpty == true)
              ? header.cloudOrderId!.trim()
              : widget.cloudOrderId?.trim();
          if (cloudId != null && cloudId.isNotEmpty) {
            snapshot = await _deliveryTrackingService
                .getTrackingForCloudOrder(cloudId);
          } else {
            final deliveryId = await _deliveryTrackingService.getCloudDeliveryId(
              orderNo: header.orderNo,
            );
            if (deliveryId != null && deliveryId.trim().isNotEmpty) {
              snapshot = await _deliveryTrackingService
                  .getTrackingByAssignmentId(deliveryId.trim());
            }
          }
        } else {
          snapshot = await _deliveryTrackingService
              .getTrackingForLocalOrder(header.id);
        }
      }
      final phone = snapshot?.driver?.phone.trim() ?? '';
      if (phone.isEmpty || phone == '-') {
        messenger.showSnackBar(
          const SnackBar(content: Text('Driver phone is not available yet.')),
        );
        return;
      }
      final uri = Uri(scheme: 'tel', path: phone);
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Unable to open phone dialer.')),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Unable to call driver: $error')),
      );
    }
  }

  Future<void> _navigateToCustomerAddress(String address) async {
    final messenger = ScaffoldMessenger.of(context);
    final normalized = address.trim();
    if (normalized.isEmpty || normalized == '-') {
      messenger.showSnackBar(
        const SnackBar(content: Text('Delivery address is not available.')),
      );
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(normalized)}',
    );
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Unable to open navigation.')),
    );
  }

  Future<void> _shareTrackingLinkViaWhatsApp(OrderDetailHeader header) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      String? deliveryId;
      if (_isCloudOrder ||
          kIsWeb ||
          (header.cloudOrderId?.trim().isNotEmpty == true)) {
        deliveryId = await _deliveryTrackingService.getCloudDeliveryId(
          cloudOrderId: header.cloudOrderId,
          orderNo: header.orderNo,
        );
      } else {
        deliveryId = await _deliveryTrackingService
            .resolveOrCreateCloudDeliveryId(header.id);
      }
      if (deliveryId == null || deliveryId.trim().isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Tracking link is not available yet.')),
        );
        return;
      }

      final links = await _deliveryTrackingService.generateTrackingLinks(
        deliveryId.trim(),
      );
      final link = links.customerLink.trim();
      if (link.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Tracking link is not available yet.')),
        );
        return;
      }

      final message = 'Track your delivery live:\n$link';
      final waUri = WhatsAppPhoneUtils.buildUri('', message: message) ??
          Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');

      if (await launchUrl(waUri, mode: LaunchMode.externalApplication)) {
        return;
      }

      final fallback = Uri.parse(
        'https://api.whatsapp.com/send?text=${Uri.encodeComponent(message)}',
      );
      if (await launchUrl(fallback, mode: LaunchMode.externalApplication)) {
        return;
      }

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Unable to open WhatsApp on this device')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Unable to share tracking link: $e')),
      );
    }
  }

  Future<Staff?> _selectStaff(String title, StaffRole role) async {
    final repository = StaffRepository();
    var staff = await repository.searchStaff(
      roles: [role],
      activeOnly: true,
    );
    if (staff.isEmpty) {
      staff = await repository.searchStaff(activeOnly: true);
    }

    if (!mounted) return null;

    return showDialog<Staff>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: staff.isEmpty
              ? const Text('No active staff available for this role.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: staff.length,
                  itemBuilder: (context, index) {
                    final person = staff[index];
                    return ListTile(
                      title: Text(person.name),
                      subtitle: Text(person.phone),
                      onTap: () => Navigator.pop(dialogContext, person),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<AssociateRecord?> _selectAssociate(
      String title, List<AssociateRecord> associates) async {
    if (!mounted) return null;

    return showDialog<AssociateRecord>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: associates.isEmpty
              ? const Text(
                  'No active associates available. Add one in Associates.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: associates.length,
                  itemBuilder: (context, index) {
                    final associate = associates[index];
                    return ListTile(
                      title: Text(associate.businessName),
                      subtitle: Text(associate.typesDisplay),
                      onTap: () => Navigator.pop(dialogContext, associate),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _assignDesigner(
    OrderDetailHeader header,
    OrderDetailBundle? detail,
  ) async {
    final workflowProvider = context.read<OrderWorkflowProvider>();
    final orderProvider = context.read<OrderProvider>();
    final designer = await _selectStaff('Select Designer', StaffRole.designer);
    if (designer == null || !mounted) return;

    await workflowProvider.sendToDesigner(
      orderId: header.id,
      designerId: designer.id,
      notes: 'Assigned to ${designer.name}',
    );
    if (!mounted) return;
    await orderProvider.loadOrderDetailProgressive(
      header.id,
      cloudOrderId: header.cloudOrderId ?? widget.cloudOrderId,
    );

    final sendWhatsApp = await _showAssignmentChoiceDialog(
      title: 'Designer Assigned Successfully',
      header: header,
      detail: detail,
    );
    if (sendWhatsApp != true || !mounted) return;

    await _launchWhatsAppMessage(
      phone: designer.whatsapp?.trim().isNotEmpty == true
          ? designer.whatsapp!
          : designer.phone,
      message: _designerChecklist(header, detail, designer.name),
    );
  }

  Future<void> _assignDelivery(
    OrderDetailHeader header,
    OrderDetailBundle? detail,
  ) async {
    final deliveryType = await _showDeliveryTypeDialog();
    if (deliveryType == null || !mounted) return;

    await _waitForRouteTeardown();
    if (!mounted) return;

    if (deliveryType == 'internal') {
      await _assignInternalDelivery(header, detail);
    } else {
      await _assignThirdPartyDelivery(header, detail);
    }
  }

  Future<String?> _showDeliveryTypeDialog() async {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Assign Delivery'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Internal Delivery'),
              subtitle: const Text('Assign to staff member'),
              leading: const Icon(Icons.person),
              onTap: () => Navigator.pop(dialogContext, 'internal'),
            ),
            ListTile(
              title: const Text('Third-Party Delivery'),
              subtitle: const Text('Porter, Dunzo, Borzo, etc.'),
              leading: const Icon(Icons.local_shipping),
              onTap: () => Navigator.pop(dialogContext, 'third-party'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignInternalDelivery(
    OrderDetailHeader header,
    OrderDetailBundle? detail,
  ) async {
    final workflowProvider = context.read<OrderWorkflowProvider>();
    final orderProvider = context.read<OrderProvider>();
    final delivery =
        await _selectStaff('Select Delivery Person', StaffRole.delivery);
    if (delivery == null || !mounted) return;

    // Assign delivery partner and sync to cloud
    try {
      await workflowProvider.assignDeliveryPartner(
        orderId: header.id,
        deliveryPartnerId: delivery.id,
        notes: 'Assigned to ${delivery.name}',
        syncDeliveryInBackground: true,
      );
    } catch (error) {
      debugPrint('[OrderDetail] Delivery assignment failed: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign delivery: $error'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }
    if (!mounted) return;

    // Reload order to confirm cloud Delivery is Assigned
    await orderProvider.loadOrderDetailProgressive(
      header.id,
      cloudOrderId: header.cloudOrderId ?? widget.cloudOrderId,
    );
    if (!mounted) return;

    // Generate tracking link for WhatsApp
    String? startDeliveryLink;
    try {
      final deliveryId = await _deliveryTrackingService.getCloudDeliveryId(
            cloudOrderId: header.cloudOrderId,
            orderNo: header.orderNo,
          ) ??
          (kIsWeb
              ? null
              : await _deliveryTrackingService
                  .resolveOrCreateCloudDeliveryId(header.id));
      if (deliveryId != null && deliveryId.trim().isNotEmpty) {
        final links =
            await _deliveryTrackingService.generateTrackingLinks(deliveryId);
        if (links.driverLink.trim().isNotEmpty) {
          startDeliveryLink = links.driverLink.trim();
        }
      }
    } catch (error) {
      debugPrint(
        '[OrderDetail] Tracking link generation failed after assignment: $error',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Delivery assigned but Start Delivery link could not be generated: $error'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }

    await _launchWhatsAppMessage(
      phone: delivery.whatsapp?.trim().isNotEmpty == true
          ? delivery.whatsapp!
          : delivery.phone,
      message: _deliveryChecklist(
        header,
        detail,
        delivery.name,
        startDeliveryLink: startDeliveryLink,
      ),
    );
  }

  Future<void> _assignThirdPartyDelivery(
    OrderDetailHeader header,
    OrderDetailBundle? detail,
  ) async {
    final result = await _showThirdPartyDeliveryDialog();
    if (result == null || !mounted) return;

    final repository = ThirdPartyDeliveryRepository();
    final input = ThirdPartyDeliveryInput(
      orderId: header.id,
      deliveryPartner: result['deliveryPartner'] as String,
      bookingReference: result['bookingReference'] as String?,
      driverName: result['driverName'] as String?,
      driverMobile: result['driverMobile'] as String?,
      deliveryChargesPaise: result['deliveryChargesPaise'] as int,
      notes: result['notes'] as String?,
    );
    final existing = await repository.getByOrderId(header.id);
    if (existing == null) {
      await repository.create(input);
    } else {
      await repository.update(existing.id, input);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Third-party delivery assigned')),
    );

    // Resolve or create cloud Delivery and generate tracking link
    String? startDeliveryLink;
    try {
      final deliveryId = await _deliveryTrackingService.getCloudDeliveryId(
            cloudOrderId: header.cloudOrderId,
            orderNo: header.orderNo,
          ) ??
          (kIsWeb
              ? null
              : await _deliveryTrackingService
                  .resolveOrCreateCloudDeliveryId(header.id));
      if (deliveryId != null && deliveryId.trim().isNotEmpty) {
        final links =
            await _deliveryTrackingService.generateTrackingLinks(deliveryId);
        if (links.driverLink.trim().isNotEmpty) {
          startDeliveryLink = links.driverLink.trim();
        }
      }
    } catch (error) {
      debugPrint(
        '[OrderDetail] Tracking link generation failed for third-party delivery: $error',
      );
    }

    final driverMobile = input.driverMobile?.trim();
    if (driverMobile != null && driverMobile.isNotEmpty) {
      await _launchWhatsAppMessage(
        phone: driverMobile,
        message: _deliveryChecklist(
          header,
          detail,
          input.driverName?.trim().isNotEmpty == true
              ? input.driverName!.trim()
              : input.deliveryPartner.trim(),
          startDeliveryLink: startDeliveryLink,
        ),
      );
    }
  }

  Future<Map<String, dynamic>?> _showThirdPartyDeliveryDialog() async {
    if (!mounted) return null;

    final partnerController = TextEditingController();
    final bookingRefController = TextEditingController();
    final driverNameController = TextEditingController();
    final driverMobileController = TextEditingController();
    final chargesController = TextEditingController(text: '0');
    final notesController = TextEditingController();
    final notesDictationController = VoiceDictationController(
      speechRecognition: SpeechRecognitionService(),
    );
    notesDictationController.bindController(notesController);

    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Third-Party Delivery'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: partnerController,
                  decoration: const InputDecoration(
                    labelText: 'Delivery Partner',
                    hintText: 'e.g., Porter, Dunzo, Borzo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bookingRefController,
                  decoration: const InputDecoration(
                    labelText: 'Booking Reference',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: driverNameController,
                  decoration: const InputDecoration(
                    labelText: 'Driver Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: driverMobileController,
                  decoration: const InputDecoration(
                    labelText: 'Driver Mobile',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: chargesController,
                  decoration: const InputDecoration(
                    labelText: 'Delivery Charges (₹)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                VoiceDictationFieldHeader(
                  label: 'Notes',
                  controller: notesDictationController,
                  compact: true,
                ),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
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
                Navigator.pop(dialogContext, {
                  'deliveryPartner': partnerController.text,
                  'bookingReference': bookingRefController.text,
                  'driverName': driverNameController.text,
                  'driverMobile': driverMobileController.text,
                  'deliveryChargesPaise':
                      ((double.tryParse(chargesController.text) ?? 0) * 100)
                          .round(),
                  'notes': notesController.text,
                });
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      );
      await _waitForRouteTeardown();
      return result;
    } finally {
      partnerController.dispose();
      bookingRefController.dispose();
      driverNameController.dispose();
      driverMobileController.dispose();
      chargesController.dispose();
      notesController.dispose();
      notesDictationController.dispose();
    }
  }

  Future<bool?> _showAssignmentChoiceDialog({
    required String title,
    required OrderDetailHeader header,
    required OrderDetailBundle? detail,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDesignerAssignmentProductPreview(detail),
              const SizedBox(height: 12),
              Text(
                'Customer: ${header.customerName}',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Occasion: ${header.occasion.trim().isEmpty ? '-' : header.occasion}',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Delivery: ${_formatDate(header.scheduledAt)} ${header.deliverySlot.trim().isEmpty ? '' : header.deliverySlot}',
                style: const TextStyle(fontSize: 13),
              ),
              if (header.specialInstructions.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Special Instructions: ${header.specialInstructions}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
              const SizedBox(height: 12),
              const Text('Do you want to send WhatsApp now?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Done'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Send WhatsApp'),
          ),
        ],
      ),
    );
  }

  Widget _buildDesignerAssignmentProductPreview(OrderDetailBundle? detail) {
    final lines = detail?.lines ?? const <Map<String, Object?>>[];

    if (lines.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Preview',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _buildPreviewPlaceholder(),
        ],
      );
    }

    if (lines.length == 1) {
      final line = lines.first;
      final name = (line['product_name'] as String?) ??
          (line['description'] as String?) ??
          'Product';
      final qty = (line['qty'] as int?) ?? 1;
      final image = _productImageService.resolveForOrderLine(line);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Preview',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 132,
                  child: _buildPreviewImage(
                    image,
                    size: 132,
                    fullWidth: true,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Qty : $qty', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      );
    }

    final productionItems = lines
        .where((line) => _isLikelyProductionItem(line))
        .toList(growable: false);
    final otherItems = lines
        .where((line) => !_isLikelyProductionItem(line))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Preview',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (productionItems.isNotEmpty)
          _buildCompactProductGroup(
            title: 'Production Items',
            items: productionItems,
            icon: Icons.local_florist_outlined,
          ),
        if (otherItems.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildCompactProductGroup(
            title: 'Other Items',
            items: otherItems,
            icon: Icons.inventory_2_outlined,
          ),
        ],
      ],
    );
  }

  Widget _buildCompactProductGroup({
    required String title,
    required List<Map<String, Object?>> items,
    required IconData icon,
  }) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            child: Row(
              children: [
                Icon(icon, size: 16, color: Colors.grey.shade700),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final line = items[index];
                final name = (line['product_name'] as String?) ??
                    (line['description'] as String?) ??
                    'Product';
                final qty = (line['qty'] as int?) ?? 1;
                final image = _productImageService.resolveForOrderLine(line);

                return ListTile(
                  dense: true,
                  leading: _buildPreviewImage(image, size: 46),
                  title: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Qty : $qty',
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewImage(
    ProductImageResult image, {
    double size = 48,
    bool fullWidth = false,
  }) {
    Widget fallback() => _buildPreviewPlaceholder(size: size);

    if (!image.hasImage) {
      return fallback();
    }

    final ref = image.reference!.trim();
    if (image.isNetwork) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          ref,
          width: fullWidth ? double.infinity : size,
          height: size,
          fit: BoxFit.cover,
          cacheWidth: fullWidth ? 480 : 160,
          cacheHeight: fullWidth ? 300 : 160,
          filterQuality: FilterQuality.low,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              width: fullWidth ? double.infinity : size,
              height: size,
              child: const Center(
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => fallback(),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(ref),
        width: fullWidth ? double.infinity : size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: fullWidth ? 480 : 160,
        cacheHeight: fullWidth ? 300 : 160,
        filterQuality: FilterQuality.low,
        errorBuilder: (_, __, ___) => fallback(),
      ),
    );
  }

  Widget _buildPreviewPlaceholder({double size = 48}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.local_florist_outlined, size: 20),
    );
  }

  bool _isLikelyProductionItem(Map<String, Object?> line) {
    final productName = ((line['product_name'] as String?) ??
            (line['description'] as String?) ??
            '')
        .toLowerCase();
    final source = ((line['source'] as String?) ?? '').toLowerCase();

    const nonProductionKeywords = <String>[
      'cake',
      'chocolate',
      'teddy',
      'balloon',
      'gift card',
      'mug',
      'candle',
    ];

    final explicitlyNonProduction = nonProductionKeywords.any(
      (keyword) => productName.contains(keyword),
    );
    if (explicitlyNonProduction) {
      return false;
    }

    // Design/manual bouquet lines are generally production-relevant.
    if (source == 'design' || source == 'manual') {
      return true;
    }

    return true;
  }

  Future<void> _launchWhatsAppMessage({
    required String phone,
    required String message,
  }) async {
    final normalizedPhone = WhatsAppPhoneUtils.normalize(phone);
    if (normalizedPhone == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid phone number for WhatsApp')),
      );
      return;
    }

    final uri = WhatsAppPhoneUtils.buildUri(normalizedPhone, message: message);
    final fallback = WhatsAppPhoneUtils.buildFallbackUri(
      normalizedPhone,
      message: message,
    );

    if (uri != null && await _launchExternalUri(uri)) {
      return;
    }

    if (fallback != null && await _launchExternalUri(fallback)) {
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not launch WhatsApp')),
    );
  }

  Future<void> _forwardAssociate(
    OrderDetailHeader header,
    OrderDetailBundle? detail,
  ) async {
    final workflowProvider = context.read<OrderWorkflowProvider>();
    final orderProvider = context.read<OrderProvider>();
    if (workflowProvider.associates.isEmpty) {
      await workflowProvider.loadAssignableAssociates(
        isCloud: _isCloudOrder || kIsWeb,
      );
    }
    final associates = List<AssociateRecord>.from(workflowProvider.associates);

    if (!mounted) return;

    final associate = await _selectAssociate('Select Associate', associates);
    if (associate == null || !mounted) return;

    await _waitForRouteTeardown();
    if (!mounted) return;

    final referenceController = TextEditingController();
    final amountController = TextEditingController();
    final values = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Forward to ${associate.businessName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: referenceController,
              decoration: const InputDecoration(labelText: 'Reference Number'),
            ),
            TextField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Fulfillment Amount',
                prefixText: '₹ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, [
              referenceController.text.trim(),
              amountController.text.trim(),
            ]),
            child: const Text('Forward'),
          ),
        ],
      ),
    );
    await _waitForRouteTeardown();
    referenceController.dispose();
    amountController.dispose();
    if (values == null || !mounted) return;

    final note = 'Reference: ${values[0]} • Fulfillment: ₹${values[1]}';
    await workflowProvider.assignRelayPartner(
      orderId: header.id,
      relayPartnerId: associate.id,
      notes: note,
    );
    if (!mounted) return;

    await orderProvider.loadOrderDetailProgressive(
      header.id,
      cloudOrderId: header.cloudOrderId ?? widget.cloudOrderId,
    );
    if (!mounted) return;

    await _waitForRouteTeardown();
    if (!mounted) return;

    final phone = associate.whatsapp?.trim().isNotEmpty == true
        ? associate.whatsapp!
        : associate.phone;
    final normalizedPhone = WhatsAppPhoneUtils.normalize(phone);
    if (normalizedPhone != null && mounted) {
      final message = _forwardAssociateMessage(header, detail, note);
      final uri =
          WhatsAppPhoneUtils.buildUri(normalizedPhone, message: message);
      final fallback = WhatsAppPhoneUtils.buildFallbackUri(
        normalizedPhone,
        message: message,
      );
      if (uri != null && await _launchExternalUri(uri)) {
        return;
      }
      if (fallback != null && await _launchExternalUri(fallback)) {
        return;
      }
    }
  }

  Future<bool> _launchExternalUri(Uri uri) async {
    try {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  Future<void> _waitForRouteTeardown() async {
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> _showPrintMenu(
    OrderDetailHeader header,
    OrderDetailBundle? detail,
  ) async {
    final workflowProvider = context.read<OrderWorkflowProvider>();
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Print & PDF',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Print Bill'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await workflowProvider.printReceipt(header.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping),
              title: const Text('Print Delivery Slip'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await workflowProvider.printDeliverySlip(header.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.card_giftcard),
              title: const Text('Print Message Card'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await workflowProvider.printMessageCard(header.id);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Download Bill PDF'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await PdfDocumentService().downloadOrShareBillPdf(
                  context: context,
                  header: header,
                  bundle: detail,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Download Delivery Slip PDF'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await PdfDocumentService().downloadOrShareDeliverySlipPdf(
                  context: context,
                  header: header,
                  bundle: detail,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreMenu(
    OrderDetailHeader header,
    OrderDetailBundle? detail,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'More Actions',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('View Bill'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showBill(header, detail);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Download Bill PDF'),
              onTap: () {
                Navigator.pop(sheetContext);
                PdfDocumentService().downloadOrShareBillPdf(
                  context: context,
                  header: header,
                  bundle: detail,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Download Delivery Slip PDF'),
              onTap: () {
                Navigator.pop(sheetContext);
                PdfDocumentService().downloadOrShareDeliverySlipPdf(
                  context: context,
                  header: header,
                  bundle: detail,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Order'),
              onTap: () {
                Navigator.pop(sheetContext);
                _editOrder(header: header, detail: detail);
              },
            ),
            if (OrderStatus.canCancel(header.status))
              ListTile(
                leading: Icon(Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error),
                title: Text(
                  'Cancel Order',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmDeleteOrder(header);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBill(
    OrderDetailHeader header,
    OrderDetailBundle? detail,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Bill ${header.displayOrderNo}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...?detail?.lines.map(
                (line) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text((line['description'] as String?) ?? 'Item'),
                  subtitle: Text('Qty ${(line['qty'] as int?) ?? 1}'),
                  trailing: Text(
                    _formatPaise((line['line_total_paise'] as int?) ?? 0),
                  ),
                ),
              ),
              const Divider(),
              _billRow('Total', _formatPaise(header.grandTotalPaise)),
              _billRow('Received', _formatPaise(header.paidAmountPaise)),
              _billRow('Balance', _formatPaise(header.outstandingAmountPaise)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await PdfDocumentService().downloadOrShareBillPdf(
                context: context,
                header: header,
                bundle: detail,
              );
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Download PDF'),
          ),
          if (!_isCloudOrder)
            FilledButton.icon(
              onPressed: () {
                context.read<OrderWorkflowProvider>().printReceipt(header.id);
                Navigator.pop(dialogContext);
              },
              icon: const Icon(Icons.print),
              label: const Text('Print Bill'),
            ),
        ],
      ),
    );
  }

  Widget _buildEventPreparationCard(
    OrderDetailHeader header,
    OrderDetailBundle? detail,
    ColorScheme colorScheme,
  ) {
    final lines = detail?.lines ?? const <Map<String, Object?>>[];

    // Physical inventory items only (exclude service/decor lines with productId == null and cloudProductId == null)
    final physicalLines = lines.where((line) {
      final pid = line['product_id'] as int?;
      final cpid = line['cloud_product_id'] as String?;
      return (pid != null && pid > 0) || (cpid != null && cpid.trim().isNotEmpty);
    }).toList();

    int totalRequired = 0;
    int totalReserved = 0;

    for (final line in physicalLines) {
      final qty = (line['qty'] as int?) ?? 1;
      final pid = line['product_id'] as int?;
      totalRequired += qty;

      final matching = _orderReservations
          .where((r) =>
              r.status == 'active' &&
              ((line['id'] != null && r.orderLineId == line['id']) ||
               (pid != null && r.productId == pid)))
          .toList();
      totalReserved += matching.fold<int>(0, (sum, r) => sum + r.quantity);
    }

    final totalStillToArrange = (totalRequired - totalReserved).clamp(0, totalRequired);
    final isDelivered = header.status == OrderStatus.delivered;
    final isCancelled = header.status == OrderStatus.cancelled;
    final isReady = header.status == OrderStatus.ready;
    final isPreparing = header.status == OrderStatus.preparing;
    final isConfirmed = header.status == OrderStatus.confirmed;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.event_available_rounded, size: 20, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Event Preparation & Readiness',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDelivered
                      ? Colors.green.shade50
                      : isReady
                          ? Colors.teal.shade50
                          : isPreparing
                              ? Colors.purple.shade50
                              : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDelivered
                        ? Colors.green.shade200
                        : isReady
                            ? Colors.teal.shade200
                            : isPreparing
                                ? Colors.purple.shade200
                                : Colors.blue.shade200,
                  ),
                ),
                child: Text(
                  isDelivered
                      ? 'Fulfilled'
                      : isReady
                          ? 'Ready for Event'
                          : isPreparing
                              ? 'In Preparation'
                              : 'Stock Hold / Prep',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDelivered
                        ? Colors.green.shade800
                        : isReady
                            ? Colors.teal.shade800
                            : isPreparing
                                ? Colors.purple.shade800
                                : Colors.blue.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 3-Metric Summary Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                _buildReservationMetric(
                  'Total Required',
                  '$totalRequired',
                  Colors.blueGrey.shade800,
                ),
                const SizedBox(width: 8),
                _buildReservationMetric(
                  'Reserved / Held',
                  '$totalReserved',
                  totalReserved > 0 ? Colors.teal.shade800 : Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                _buildReservationMetric(
                  'Still to Arrange',
                  '$totalStillToArrange',
                  totalStillToArrange > 0 ? Colors.orange.shade800 : Colors.green.shade800,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Descriptive guidance
          Text(
            isDelivered
                ? 'Event has been fulfilled. Physical inventory has been deducted.'
                : totalStillToArrange > 0
                    ? '$totalStillToArrange unit(s) still need to be produced or arranged before the event.'
                    : 'All physical items are reserved/held in stock. Ready to prepare or fulfill.',
            style: TextStyle(
              fontSize: 12,
              color: isDelivered
                  ? Colors.green.shade800
                  : totalStillToArrange > 0
                      ? Colors.orange.shade900
                      : Colors.teal.shade900,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (!isDelivered && !isCancelled) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (totalStillToArrange > 0)
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BouquetProductionEntryScreen()),
                    ),
                    icon: const Icon(Icons.precision_manufacturing_outlined, size: 16),
                    label: const Text('Produce / Prepare Bouquet'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange.shade800,
                      side: BorderSide(color: Colors.orange.shade300),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                if (isConfirmed)
                  FilledButton.icon(
                    onPressed: () => _advanceEventStatus(header, detail, OrderStatus.preparing),
                    icon: const Icon(Icons.build_circle_outlined, size: 16),
                    label: const Text('Start Preparing'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.purple.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                if (isPreparing)
                  FilledButton.icon(
                    onPressed: () => _advanceEventStatus(header, detail, OrderStatus.ready),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Mark Ready for Event'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                if (isReady)
                  FilledButton.icon(
                    onPressed: () => _advanceEventStatus(header, detail, OrderStatus.delivered),
                    icon: const Icon(Icons.task_alt, size: 16),
                    label: const Text('Fulfill Event'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<bool> _preCheckEventFulfillmentStock({
    required OrderDetailHeader header,
    required OrderDetailBundle? detail,
  }) async {
    final isCloud = _isCloudOrder ||
        kIsWeb ||
        (header.cloudOrderId?.trim().isNotEmpty == true);

    if (isCloud) {
      try {
        final cloudInventoryRepo = CloudInventoryRepository();
        final inventoryItems = await cloudInventoryRepo.listInventoryProducts();
        final stockByCloudId = <String, int>{};
        for (final item in inventoryItems) {
          if (item.cloudProductId != null && item.cloudProductId!.isNotEmpty) {
            stockByCloudId[item.cloudProductId!] = item.currentQty;
          }
        }

        final lines = detail?.lines ?? const <Map<String, Object?>>[];
        final shortages = <Map<String, dynamic>>[];

        for (final line in lines) {
          final cloudProdId = line['cloud_product_id'] as String?;
          final qty = (line['qty'] as int?) ?? 0;
          final name = (line['product_name'] as String?) ?? (line['description'] as String?) ?? 'Product';
          if (cloudProdId == null || cloudProdId.isEmpty || qty <= 0) continue;

          final avail = stockByCloudId[cloudProdId] ?? 0;
          if (avail < qty) {
            shortages.add({
              'productName': name,
              'requiredQty': qty,
              'availableQty': avail,
              'shortageQty': qty - avail,
            });
          }
        }

        if (shortages.isNotEmpty) {
          if (!mounted) return false;
          await _showFulfillmentShortageDialog(shortages);
          return false;
        }
      } catch (e) {
        debugPrint('[OrderDetail] Cloud stock pre-check warning: $e');
      }
      return true;
    }

    final shortages = await _orderRepository.checkEventFulfillmentStock(header.id);
    if (shortages.isNotEmpty) {
      if (!mounted) return false;
      await _showFulfillmentShortageDialog(
        shortages.map((s) => {
          'productName': s.productName,
          'requiredQty': s.requiredQty,
          'availableQty': s.availableQty,
          'shortageQty': s.shortageQty,
        }).toList(),
      );
      return false;
    }
    return true;
  }

  Future<void> _showFulfillmentShortageDialog(List<Map<String, dynamic>> shortages) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
            const SizedBox(width: 8),
            const Expanded(child: Text('Insufficient Physical Stock')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cannot fulfill event. Current physical stock is less than required for the following item(s):',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              ...shortages.map((s) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s['productName'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Required: ${s['requiredQty']}', style: const TextStyle(fontSize: 12)),
                        Text('In Stock: ${s['availableQty']}', style: const TextStyle(fontSize: 12)),
                        Text(
                          'Shortage: ${s['shortageQty']}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade800),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 8),
              const Text(
                'Please produce or procure the missing bouquets before marking the event as fulfilled.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BouquetProductionEntryScreen()),
              );
            },
            icon: const Icon(Icons.precision_manufacturing_outlined, size: 16),
            label: const Text('Open Bouquet Production'),
          ),
        ],
      ),
    );
  }

  Future<void> _advanceEventStatus(
    OrderDetailHeader header,
    OrderDetailBundle? detail,
    String targetStatus,
  ) async {
    if (targetStatus == OrderStatus.delivered) {
      final canFulfill = await _preCheckEventFulfillmentStock(
        header: header,
        detail: detail,
      );
      if (!canFulfill || !mounted) return;
    }

    final isCloud = _isCloudOrder ||
        kIsWeb ||
        (header.cloudOrderId?.trim().isNotEmpty == true);

    try {
      if (isCloud) {
        final cloudOrderId = (header.cloudOrderId?.trim().isNotEmpty == true)
            ? header.cloudOrderId!.trim()
            : widget.cloudOrderId?.trim();
        if (cloudOrderId != null && cloudOrderId.isNotEmpty) {
          await context.read<OrderProvider>().updateCloudOrderStatus(
            cloudOrderId: cloudOrderId,
            newStatus: targetStatus,
          );
        }
      } else {
        await context.read<OrderWorkflowProvider>().advanceStatus(
          orderId: header.id,
          currentStatus: header.status,
          newStatus: targetStatus,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Event status updated to ${OrderStatus.label(targetStatus)}.')),
        );
        await context.read<OrderProvider>().loadOrderDetailProgressive(
          header.id,
          cloudOrderId: header.cloudOrderId ?? widget.cloudOrderId,
        );
        await _loadOrderReservations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update event status: $e')),
        );
      }
    }
  }

  Future<void> _showStatusChangeDialog(
    OrderDetailHeader header,
    OrderDetailBundle? detail,
  ) async {
    final isEventSale = header.fulfilmentType == 'event_sale';
    final nextStatuses = OrderStatus.nextStatuses(header.status, fulfilmentType: header.fulfilmentType)
        .where((status) => status != OrderStatus.cancelled)
        .toList(growable: false);

    if (nextStatuses.isEmpty) {
      _showSnack('No status changes are available for this order.');
      return;
    }

    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Change Status'),
        children: [
          for (final status in nextStatuses)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, status),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(OrderStatus.actionLabel(status, fulfilmentType: header.fulfilmentType)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );

    if (selected == null || !mounted) return;

    if (isEventSale) {
      await _advanceEventStatus(header, detail, selected);
    } else {
      final isCloud = _isCloudOrder ||
          kIsWeb ||
          (header.cloudOrderId?.trim().isNotEmpty == true);
      if (isCloud) {
        final cloudOrderId = header.cloudOrderId?.trim();
        if (cloudOrderId != null && cloudOrderId.isNotEmpty) {
          try {
            await context.read<OrderProvider>().updateCloudOrderStatus(
                  cloudOrderId: cloudOrderId,
                  newStatus: selected,
                );
            if (mounted) {
              _showSnack('Order status updated.');
              await context.read<OrderProvider>().loadOrderDetailProgressive(
                header.id,
                cloudOrderId: header.cloudOrderId ?? widget.cloudOrderId,
              );
            }
          } catch (error) {
            if (mounted) _showSnack('Unable to update order status: $error');
          }
        }
      } else {
        try {
          await context.read<OrderWorkflowProvider>().advanceStatus(
            orderId: header.id,
            currentStatus: header.status,
            newStatus: selected,
          );
          if (mounted) {
            _showSnack('Order status updated.');
            await context.read<OrderProvider>().loadOrderDetailProgressive(header.id);
          }
        } catch (error) {
          if (mounted) _showSnack('Unable to update order status: $error');
        }
      }
    }
  }

  Future<void> _assignCloudDesigner(OrderDetailHeader header) async {
    final cloudOrderId = header.cloudOrderId?.trim();
    if (cloudOrderId == null || cloudOrderId.isEmpty) return;
    final provider = context.read<OrderProvider>();

    final selected = await _pickCloudAssignee(
      title: 'Select Designer',
      emptyMessage: 'No designers are available in Cloud.',
      load: provider.loadCloudDesigners,
    );
    if (selected == null || !mounted) return;

    try {
      await provider.assignCloudDesigner(
        cloudOrderId: cloudOrderId,
        staffId: selected.staffId,
      );
      if (!mounted) return;
      _showSnack('Designer assigned to ${selected.name}.');
    } catch (error) {
      if (!mounted) return;
      _showSnack('Unable to assign designer: $error');
      return;
    }

    final refreshedHeader = provider.detailHeader ?? header;
    final refreshedDetail = provider.detailBundle;

    final sendWhatsApp = await _showAssignmentChoiceDialog(
      title: 'Designer Assigned Successfully',
      header: refreshedHeader,
      detail: refreshedDetail,
    );
    if (sendWhatsApp != true || !mounted) return;

    await _launchWhatsAppMessage(
      phone: selected.phone ?? '',
      message: _designerChecklist(
        refreshedHeader,
        refreshedDetail,
        selected.name,
      ),
    );
  }

  Future<void> _assignCloudDelivery(OrderDetailHeader header) async {
    final cloudOrderId = header.cloudOrderId?.trim();
    if (cloudOrderId == null || cloudOrderId.isEmpty) return;
    final provider = context.read<OrderProvider>();

    final selected = await _pickCloudAssignee(
      title: 'Select Delivery Person',
      emptyMessage: 'No delivery staff are available in Cloud.',
      load: provider.loadCloudDrivers,
    );
    if (selected == null || !mounted) return;

    try {
      await provider.assignCloudDriver(
        cloudOrderId: cloudOrderId,
        staffId: selected.staffId,
      );
      if (!mounted) return;
      _showSnack('Delivery assigned to ${selected.name}.');
    } catch (error) {
      if (!mounted) return;
      _showSnack('Unable to assign delivery: $error');
      return;
    }

    final refreshedHeader = provider.detailHeader ?? header;
    final startDeliveryLink = await _resolveCloudStartDeliveryLink(
      refreshedHeader.orderNo,
      cloudOrderId: cloudOrderId,
    );
    if (!mounted) return;

    await _launchWhatsAppMessage(
      phone: selected.phone ?? '',
      message: _deliveryChecklist(
        refreshedHeader,
        provider.detailBundle,
        selected.name,
        startDeliveryLink: startDeliveryLink,
      ),
    );
  }

  /// Resolves the Cloud delivery created by assign-driver and mints its driver
  /// tracking link. A failure here must not undo the completed assignment.
  Future<String?> _resolveCloudStartDeliveryLink(
    String orderNo, {
    String? cloudOrderId,
  }) async {
    try {
      final deliveryId = await _deliveryTrackingService.getCloudDeliveryId(
        cloudOrderId: cloudOrderId,
        orderNo: orderNo,
      );
      if (deliveryId == null || deliveryId.trim().isEmpty) return null;

      final links =
          await _deliveryTrackingService.generateTrackingLinks(deliveryId);
      final driverLink = links.driverLink.trim();
      return driverLink.isEmpty ? null : driverLink;
    } catch (error) {
      debugPrint('[OrderDetail] Cloud tracking link generation failed: $error');
      if (mounted) {
        _showSnack(
          'Delivery assigned but the Start Delivery link could not be generated: $error',
        );
      }
      return null;
    }
  }

  Future<CloudAssignee?> _pickCloudAssignee({
    required String title,
    required String emptyMessage,
    required Future<List<CloudAssignee>> Function() load,
  }) async {
    List<CloudAssignee> assignees;
    try {
      assignees = await load();
    } catch (error) {
      if (!mounted) return null;
      _showSnack('Unable to load Cloud staff: $error');
      return null;
    }
    if (!mounted) return null;
    if (assignees.isEmpty) {
      _showSnack(emptyMessage);
      return null;
    }

    return showDialog<CloudAssignee>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(title),
        children: [
          for (final assignee in assignees)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, assignee),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(assignee.name),
                subtitle: assignee.phone == null ? null : Text(assignee.phone!),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmCancelCloudOrder(OrderDetailHeader header) async {
    final cloudOrderId = header.cloudOrderId?.trim();
    if (cloudOrderId == null || cloudOrderId.isEmpty) return;
    if (!OrderStatus.canCancel(header.status)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text(
          'The Cloud order will be cancelled and retained for audit history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Order'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await context.read<OrderProvider>().cancelCloudOrder(
            cloudOrderId: cloudOrderId,
            reason: 'Cancelled from Order Details',
          );
      if (!mounted) return;
      _showSnack('Order cancelled.');
    } catch (error) {
      if (!mounted) return;
      _showSnack('Unable to cancel order: $error');
    }
  }

  Widget _billRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value)],
      ),
    );
  }

  void _showEditOrderMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Delivered and cancelled orders are read-only.')),
    );
  }

  bool _canEditOrder(String status) {
    return status != OrderStatus.delivered && status != OrderStatus.cancelled;
  }

  Future<void> _editCloudOrder() async {
    final provider = context.read<OrderProvider>();
    final header = provider.detailHeader;
    final detail = provider.detailBundle;
    final cloudOrderId = header?.cloudOrderId?.trim();
    if (header == null || detail == null) return;
    if (cloudOrderId == null || cloudOrderId.isEmpty) return;

    if (!_canEditOrder(header.status)) {
      _showEditOrderMessage();
      return;
    }

    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CloudOrderEditScreen(
          cloudOrderId: cloudOrderId,
          header: header,
          detail: detail,
        ),
      ),
    );
  }

  Future<void> _editOrder({
    OrderDetailHeader? header,
    OrderDetailBundle? detail,
  }) async {
    final currentHeader = header ?? context.read<OrderProvider>().detailHeader;
    final currentDetail = detail ?? context.read<OrderProvider>().detailBundle;
    if (currentHeader == null || currentDetail == null) return;

    if (!_canEditOrder(currentHeader.status)) {
      _showEditOrderMessage();
      return;
    }

    final session = _buildEditSession(currentHeader, currentDetail);
    final fulfilment = _parseFulfilmentType(currentHeader.fulfilmentType);

    Widget editor;
    switch (fulfilment) {
      case FulfilmentType.takeAway:
        editor = TakeAwayScreen(
          initialSession: session,
          editingOrderId: currentHeader.id,
        );
        break;
      case FulfilmentType.pickupLater:
        editor = PickupLaterScreen(
          initialSession: session,
          editingOrderId: currentHeader.id,
        );
        break;
      case FulfilmentType.delivery:
        editor = DeliveryScreen(
          initialSession: session,
          editingOrderId: currentHeader.id,
        );
        break;
      case FulfilmentType.eventSale:
        editor = EventSaleScreen(
          initialSession: session,
          editingOrderId: currentHeader.id,
        );
        break;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => editor),
    );

    if (!mounted) return;
    await context.read<OrderProvider>().loadOrderDetailProgressive(
          currentHeader.id,
          cloudOrderId: currentHeader.cloudOrderId ?? widget.cloudOrderId,
        );
    await _loadOrderReservations();
  }

  FulfilmentType _parseFulfilmentType(String value) {
    return switch (value.toLowerCase()) {
      'take_away' || 'takeaway' => FulfilmentType.takeAway,
      'pickup_later' || 'pickup' => FulfilmentType.pickupLater,
      'event_sale' || 'event' => FulfilmentType.eventSale,
      _ => FulfilmentType.delivery,
    };
  }

  WalkInSession _buildEditSession(
    OrderDetailHeader header,
    OrderDetailBundle detail,
  ) {
    final lines = detail.lines
        .map(
          (line) {
            final imageRef = (line['design_ref'] ??
                    line['designRef'] ??
                    line['order_reference_image_path'] ??
                    line['reference_image_path'] ??
                    line['attachment_path'] ??
                    line['attachmentPath'] ??
                    line['product_image_path'] ??
                    line['image_url'] ??
                    line['imageUrl'])
                ?.toString();
            final rawDescription = (line['description'] as String?)?.trim();
            final rawProductName = (line['product_name'] as String?)?.trim();
            final desc = (rawDescription != null && rawDescription.isNotEmpty)
                ? rawDescription
                : (rawProductName != null && rawProductName.isNotEmpty
                    ? rawProductName
                    : 'Item');
            return WalkInLineItem(
              productId: line['product_id'] as int?,
              cloudProductId: line['cloud_product_id']?.toString(),
              designRef: imageRef?.isNotEmpty == true ? imageRef : null,
              description: desc,
              quantity: (line['qty'] as int?) ?? 1,
              unitPricePaise: (line['unit_price_paise'] as int?) ?? 0,
              discountPaise: (line['discount_paise'] as int?) ?? 0,
              discountType: line['discount_type'] as String?,
              discountValue: line['discount_value'] as int?,
              gstPercent: (line['gst_percent'] as int?) ?? 0,
              source: (line['source'] as String?) ?? 'manual',
            );
          },
        )
        .toList(growable: false);

    final payments = detail.payments
        .map(
          (row) => PaymentSplit(
            method: switch (((row['method'] as String?) ?? '').toLowerCase()) {
              'cash' => PaymentMethod.cash,
              'upi' => PaymentMethod.upi,
              'card' => PaymentMethod.card,
              'bank' || 'bank_transfer' => PaymentMethod.bank,
              _ => PaymentMethod.other,
            },
            amountPaise: (row['amount_paise'] as int?) ?? 0,
            reference: row['reference'] as String?,
            methodCode: row['method'] as String?,
          ),
        )
        .toList(growable: false);

    return WalkInSession(
      draftOrderId: header.id,
      fulfilmentType: _parseFulfilmentType(header.fulfilmentType),
      lines: lines,
      customerPhone: header.customerPhone,
      customerName: header.customerName,
      occasion: header.occasion,
      scheduledAt: header.scheduledAt,
      deliverySlot: header.deliverySlot,
      recipientName: header.recipientName,
      recipientPhone: header.recipientPhone,
      deliveryAddress: header.address,
      cardMessage: header.cardMessage,
      specialInstructions: '',
      payments: payments,
      billDiscountType: null,
      billDiscountValue: null,
    );
  }

  Future<void> _confirmDeleteOrder(OrderDetailHeader header) async {
    if (!OrderStatus.canCancel(header.status)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Order'),
        content: const Text(
          'The order will be cancelled and retained for audit history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Order'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<OrderWorkflowProvider>().cancelOrder(
          orderId: header.id,
          currentStatus: header.status,
          reason: 'Cancelled from Order Details',
        );
    if (!mounted) return;
    await context.read<OrderProvider>().loadOrderDetailProgressive(
          header.id,
          cloudOrderId: header.cloudOrderId ?? widget.cloudOrderId,
        );
  }

  String _designerChecklist(
    OrderDetailHeader header,
    OrderDetailBundle? detail,
    String designerName,
  ) {
    return designerAssignmentMessage(header, detail, designerName);
  }

  String _deliveryChecklist(
    OrderDetailHeader header,
    OrderDetailBundle? detail,
    String deliveryName, {
    String? startDeliveryLink,
  }) {
    return deliveryAssignmentMessage(
      header,
      detail,
      deliveryName,
      startDeliveryLink: startDeliveryLink,
    );
  }

  String _forwardAssociateMessage(
    OrderDetailHeader header,
    OrderDetailBundle? detail,
    String note,
  ) {
    final outstanding = header.outstandingAmountPaise;
    return [
      '📦 FORWARD ASSOCIATE',
      '',
      'Order : ${header.orderNo}',
      '',
      'Recipient',
      header.recipientName,
      '',
      'Customer',
      header.customerName,
      '',
      'Products',
      _productChecklist(detail, checked: true),
      '',
      'Delivery Date',
      _formatDate(header.scheduledAt),
      '',
      'Delivery Slot',
      header.deliverySlot.isEmpty ? '-' : header.deliverySlot,
      '',
      'Card Message',
      header.cardMessage.isEmpty ? '-' : header.cardMessage,
      if (outstanding > 0) '',
      if (outstanding > 0) 'Outstanding Amount',
      if (outstanding > 0) _formatPaise(outstanding),
      '',
      note,
    ].join('\n');
  }

  String _productChecklist(
    OrderDetailBundle? detail, {
    required bool checked,
  }) {
    final lines = detail?.lines ?? const <Map<String, Object?>>[];
    if (lines.isEmpty) return checked ? '✅ No products' : '☐ No products';
    final mark = checked ? '✅' : '☐';
    return lines
        .map(
          (line) =>
              '$mark ${(line['qty'] as int?) ?? 1} × ${(line['product_name'] as String?) ?? (line['description'] as String?) ?? 'Item'}',
        )
        .join('\n');
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    return '${value.day}/${value.month}/${value.year}';
  }

  Widget _buildInfoCard(String title, Map<String, Object?> data) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (data.isEmpty)
            Text(l10n.noData)
          else
            ...data.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        _pretty(entry.key),
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: Text((entry.value ?? '-').toString()),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLinkageRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) {
      return '-';
    }
    final hour =
        value.hour == 0 ? 12 : (value.hour > 12 ? value.hour - 12 : value.hour);
    final minute = value.minute.toString().padLeft(2, '0');
    final meridiem = value.hour >= 12 ? 'PM' : 'AM';
    return '${value.day}/${value.month}/${value.year} $hour:$minute $meridiem';
  }

  String _formatPaise(int paise) {
    return '₹${(paise / 100).toStringAsFixed(0)}';
  }

  Future<void> _collectPayment(OrderDetailHeader header) async {
    final success = await showCollectPaymentDialog(
      context: context,
      orderId: header.id,
      cloudOrderId: header.cloudOrderId,
      orderNo: header.orderNo,
      customerName: header.customerName,
      grandTotalPaise: header.grandTotalPaise,
      paidAmountPaise: header.paidAmountPaise,
      outstandingAmountPaise: header.outstandingAmountPaise,
      onPaymentSuccess: () async {
        final provider = context.read<OrderProvider>();
        if (_isCloudOrder) {
          await provider.loadOrderDetailProgressive(-1, cloudOrderId: header.cloudOrderId);
        } else {
          await provider.loadOrderDetailProgressive(header.id);
        }
      },
    );
    if (success == true && mounted) {
      final provider = context.read<OrderProvider>();
      if (_isCloudOrder) {
        await provider.loadOrderDetailProgressive(-1, cloudOrderId: header.cloudOrderId);
      } else {
        await provider.loadOrderDetailProgressive(header.id);
      }
    }
  }

  Future<void> _startPaymentAdjustment(OrderDetailHeader header) async {
    final detail = context.read<OrderProvider>().detailBundle;
    final payments = detail?.payments ?? const <Map<String, Object?>>[];
    final receivedPaise = _sumNonCreditPayments(payments);
    final refundedPaise = _sumRefundAdjustments(payments);
    final netReceivedPaise = receivedPaise - refundedPaise;
    final outstandingPaise = (header.grandTotalPaise - netReceivedPaise)
        .clamp(0, header.grandTotalPaise);
    final suggestedPaise =
        (receivedPaise - refundedPaise).clamp(0, receivedPaise);

    String whatHappened = 'customer_cancelled';
    String action = 'refund_customer';
    String refundMethod = 'cash';
    final amountController = TextEditingController(
      text: (suggestedPaise / 100).toStringAsFixed(0),
    );
    final remarksController = TextEditingController();
    var isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) => AlertDialog(
            title: const Text('Adjust Payment'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Step 1: What happened?'),
                  const SizedBox(height: 6),
                  _choiceGroup(
                    value: whatHappened,
                    onChanged: (value) =>
                        setStateDialog(() => whatHappened = value),
                    options: const [
                      _CodeLabel('customer_cancelled', 'Customer Cancelled'),
                      _CodeLabel('order_modified', 'Order Modified'),
                      _CodeLabel('money_returned', 'Money Returned'),
                      _CodeLabel('duplicate_payment', 'Duplicate Payment'),
                      _CodeLabel('wrong_entry', 'Wrong Entry'),
                      _CodeLabel('other', 'Other'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('Payment Summary'),
                  const SizedBox(height: 6),
                  _billRow('Order Total', _formatPaise(header.grandTotalPaise)),
                  _billRow('Received', _formatPaise(receivedPaise)),
                  _billRow('Refunded', _formatPaise(refundedPaise)),
                  _billRow('Net Received', _formatPaise(netReceivedPaise)),
                  _billRow('Outstanding', _formatPaise(outstandingPaise)),
                  const SizedBox(height: 10),
                  const Text('Step 2: Enter adjustment amount'),
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      prefixText: '₹ ',
                      helperText: 'Suggested: Paid - Already Refunded',
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('Step 3: What to do?'),
                  _choiceGroup(
                    value: action,
                    onChanged: (value) => setStateDialog(() => action = value),
                    options: const [
                      _CodeLabel('refund_customer', 'Refund Customer'),
                      _CodeLabel('keep_as_advance', 'Keep as Advance'),
                      _CodeLabel('adjust_next_order', 'Adjust in Next Order'),
                      _CodeLabel('no_refund', 'No Refund'),
                    ],
                  ),
                  if (action == 'refund_customer') ...[
                    const SizedBox(height: 8),
                    const Text('Refund Method (record only)'),
                    DropdownButtonFormField<String>(
                      initialValue: refundMethod,
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'upi', child: Text('UPI')),
                        DropdownMenuItem(
                            value: 'bank_transfer',
                            child: Text('Bank Transfer')),
                        DropdownMenuItem(
                            value: 'credit_note', child: Text('Credit Note')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setStateDialog(() => refundMethod = value);
                      },
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextField(
                    controller: remarksController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Remarks (optional)',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final amountPaise =
                            _parseCurrencyToPaise(amountController.text);
                        if (amountPaise <= 0) {
                          _showSnack('Enter a valid adjustment amount.');
                          return;
                        }
                        if (amountPaise > receivedPaise) {
                          _showSnack(
                              'Adjustment cannot exceed amount received.');
                          return;
                        }

                        setStateDialog(() => isSaving = true);
                        try {
                          await context
                              .read<OrderProvider>()
                              .adjustOrderPayment(
                                orderId: header.id,
                                event: whatHappened,
                                resolution: action,
                                amountPaise: amountPaise,
                                refundMethod: action == 'refund_customer'
                                    ? refundMethod
                                    : null,
                                remarks: remarksController.text.trim().isEmpty
                                    ? null
                                    : remarksController.text.trim(),
                              );
                          if (!mounted || !dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          _showSnack('Payment adjustment saved.');
                        } catch (e) {
                          if (!mounted || !dialogContext.mounted) return;
                          _showSnack('Unable to save adjustment: $e');
                          setStateDialog(() => isSaving = false);
                        }
                      },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _choiceGroup({
    required String value,
    required ValueChanged<String> onChanged,
    required List<_CodeLabel> options,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: options
          .map(
            (option) => ChoiceChip(
              label: Text(option.label),
              selected: option.code == value,
              onSelected: (_) => onChanged(option.code),
            ),
          )
          .toList(growable: false),
    );
  }

  int _parseCurrencyToPaise(String? value) {
    if (value == null || value.trim().isEmpty) return 0;
    final normalized = value.replaceAll('₹', '').replaceAll(',', '').trim();
    final parsed = double.tryParse(normalized) ?? 0;
    return (parsed * 100).round();
  }

  int _sumNonCreditPayments(List<Map<String, Object?>> rows) {
    return rows.where((row) {
      final method = ((row['method'] as String?) ?? '').toLowerCase();
      return method != 'credit';
    }).fold<int>(
      0,
      (sum, row) => sum + ((row['amount_paise'] as int?) ?? 0),
    );
  }

  int _sumRefundAdjustments(List<Map<String, Object?>> rows) {
    return rows.where((row) {
      final amount = (row['amount_paise'] as int?) ?? 0;
      return amount < 0;
    }).fold<int>(
      0,
      (sum, row) => sum + (((row['amount_paise'] as int?) ?? 0).abs()),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _pretty(String value) {
    final withSpaces = value
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m.group(1)} ${m.group(2)}')
        .replaceAll('_', ' ');
    return withSpaces.replaceAllMapped(
      RegExp(r'(^|\s)([a-z])'),
      (m) => '${m.group(1)}${m.group(2)!.toUpperCase()}',
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
      case 'confirmed':
        return Colors.orange;
      case 'preparing':
        return Colors.blue;
      case 'ready':
        return Colors.green;
      case 'out_for_delivery':
        return Colors.purple;
      case 'delivered':
        return Colors.teal;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

enum _DeliveryConnectivityKind { notStarted, live, delayed, offline }

class _DeliveryConnectivityState {
  const _DeliveryConnectivityState._({
    required this.kind,
    required this.label,
    required this.tooltip,
    required this.color,
    required this.textColor,
  });

  factory _DeliveryConnectivityState.notStarted() {
    return _DeliveryConnectivityState._(
      kind: _DeliveryConnectivityKind.notStarted,
      label: 'Not Started',
      tooltip: 'Driver has not accepted this delivery.',
      color: Colors.white,
      textColor: Colors.grey.shade800,
    );
  }

  factory _DeliveryConnectivityState.live() {
    return _DeliveryConnectivityState._(
      kind: _DeliveryConnectivityKind.live,
      label: 'Live',
      tooltip: 'Driver session active. GPS updated within 60 seconds.',
      color: Colors.green,
      textColor: Colors.green.shade800,
    );
  }

  factory _DeliveryConnectivityState.delayed() {
    return _DeliveryConnectivityState._(
      kind: _DeliveryConnectivityKind.delayed,
      label: 'Delayed',
      tooltip: 'Driver connected, but GPS updates are delayed.',
      color: Colors.amber,
      textColor: Colors.orange.shade900,
    );
  }

  factory _DeliveryConnectivityState.driverOffline() {
    return _DeliveryConnectivityState._(
      kind: _DeliveryConnectivityKind.offline,
      label: 'Driver Offline',
      tooltip: 'Driver is offline or GPS updates are stale.',
      color: Colors.red,
      textColor: Colors.red.shade800,
    );
  }

  factory _DeliveryConnectivityState.noInternet() {
    return _DeliveryConnectivityState._(
      kind: _DeliveryConnectivityKind.offline,
      label: 'No Internet',
      tooltip: 'Tracking cannot connect from this device.',
      color: Colors.red,
      textColor: Colors.red.shade800,
    );
  }

  factory _DeliveryConnectivityState.serverUnreachable() {
    return _DeliveryConnectivityState._(
      kind: _DeliveryConnectivityKind.offline,
      label: 'Server Unreachable',
      tooltip: 'Tracking server did not respond. Last location is preserved.',
      color: Colors.red,
      textColor: Colors.red.shade800,
    );
  }

  final _DeliveryConnectivityKind kind;
  final String label;
  final String tooltip;
  final Color color;
  final Color textColor;
}

class _OrderQuickAction {
  const _OrderQuickAction(
    this.label,
    this.icon,
    this.onTap, {
    this.isLoading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isLoading;
}

class _CodeLabel {
  const _CodeLabel(this.code, this.label);

  final String code;
  final String label;
}
