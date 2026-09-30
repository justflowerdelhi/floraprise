import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/order_workspace_models.dart';
import '../providers/order_provider.dart';
import '../services/pdf/pdf_document_service.dart';
import '../services/product_image_service.dart';
import '../utils/order_display_utils.dart';
import '../widgets/common_widgets.dart';
import '../widgets/order_action_menu_sheet.dart';
import '../widgets/safe_platform_image.dart';

/// Clean, retail-friendly submitted-order view.
///
/// Designed information-first: presents the customer, recipient, delivery details,
/// line items with quantities and pricing, financial totals, payment details, and
/// message card notes without bulky ERP linkages or diagnostic metadata.
///
/// Quick actions are accessed via the compact "Actions" button in the AppBar,
/// which invokes the central [showOrderActionMenu].
class OrderViewScreen extends StatefulWidget {
  const OrderViewScreen({
    super.key,
    required this.orderId,
    this.cloudOrderId,
  });

  final int orderId;
  final String? cloudOrderId;

  @override
  State<OrderViewScreen> createState() => _OrderViewScreenState();
}

class _OrderViewScreenState extends State<OrderViewScreen> {
  final ProductImageService _productImageService = const ProductImageService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrder();
    });
  }

  Future<void> _loadOrder() async {
    await context.read<OrderProvider>().loadOrderDetailProgressive(
          widget.orderId,
          cloudOrderId: widget.cloudOrderId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        final header = provider.detailHeader;
        final bundle = provider.detailBundle;

        final title = header != null
            ? header.displayOrderNo
            : (widget.orderId > 0
                ? OrderDisplayUtils.format(null, orderId: widget.orderId)
                : 'Order');

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              if (header != null) ...[
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  tooltip: 'Download Bill (PDF)',
                  onPressed: () => PdfDocumentService().downloadOrShareBillPdf(
                    context: context,
                    header: header,
                    bundle: bundle,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  tooltip: 'Order Actions',
                  onPressed: () => showOrderActionMenu(
                    context,
                    orderId: header.id,
                    cloudOrderId: header.cloudOrderId ?? widget.cloudOrderId,
                    header: header,
                    detailBundle: bundle,
                    onOrderUpdated: _loadOrder,
                  ),
                ),
              ],
            ],
          ),
          body: _buildBody(provider, header, bundle, colorScheme, l10n),
        );
      },
    );
  }

  Widget _buildBody(
    OrderProvider provider,
    OrderDetailHeader? header,
    OrderDetailBundle? bundle,
    ColorScheme colorScheme,
    AppLocalizations? l10n,
  ) {
    if (provider.isDetailLoading && header == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (header == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              l10n?.orderNotFound ?? 'Order not found',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: _loadOrder,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 24;

    return RefreshIndicator(
      onRefresh: _loadOrder,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 840;

          if (isWide) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Items, Customer & Delivery, Notes
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeaderCard(header, colorScheme),
                            const SizedBox(height: 16),
                            _buildItemsCard(header, bundle, colorScheme),
                            if (_hasNotes(header)) ...[
                              const SizedBox(height: 16),
                              _buildNotesCard(header, colorScheme),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Right Column: Financial Summary, Customer Details, Payments, Assignments
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCustomerAndDeliveryCard(header, colorScheme),
                            const SizedBox(height: 16),
                            _buildFinancialSummaryCard(header, colorScheme),
                            if (bundle != null && bundle.payments.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildPaymentDetailsCard(header, bundle, colorScheme),
                            ],
                            if (_hasAssignments(header)) ...[
                              const SizedBox(height: 16),
                              _buildAssignmentsCard(header, colorScheme),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Mobile / Narrow view
          return ListView(
            padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
            children: [
              _buildHeaderCard(header, colorScheme),
              const SizedBox(height: 12),
              _buildCustomerAndDeliveryCard(header, colorScheme),
              const SizedBox(height: 12),
              _buildItemsCard(header, bundle, colorScheme),
              const SizedBox(height: 12),
              _buildFinancialSummaryCard(header, colorScheme),
              if (bundle != null && bundle.payments.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildPaymentDetailsCard(header, bundle, colorScheme),
              ],
              if (_hasNotes(header)) ...[
                const SizedBox(height: 12),
                _buildNotesCard(header, colorScheme),
              ],
              if (_hasAssignments(header)) ...[
                const SizedBox(height: 12),
                _buildAssignmentsCard(header, colorScheme),
              ],
            ],
          );
        },
      ),
    );
  }

  // Header Banner Card
  Widget _buildHeaderCard(OrderDetailHeader header, ColorScheme colorScheme) {
    final statusColor = _getStatusColor(header.status);
    final isPaid = header.isPaid == 1 || header.outstandingAmountPaise <= 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: header.orderNo));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order number copied')),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      header.displayOrderNo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.copy_rounded, size: 16, color: Colors.grey.shade500),
                  ],
                ),
              ),
              Row(
                children: [
                  StatusChip(
                    label: _pretty(header.status),
                    color: statusColor,
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPaid ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isPaid ? Colors.green.shade300 : Colors.orange.shade300,
                      ),
                    ),
                    child: Text(
                      isPaid ? 'Paid' : 'Pending',
                      style: TextStyle(
                        color: isPaid ? Colors.green.shade800 : Colors.orange.shade900,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _pillChip(
                _getFulfilmentIcon(header.fulfilmentType),
                _pretty(header.fulfilmentType),
                Colors.blueGrey.shade700,
                Colors.blueGrey.shade50,
              ),
              if (header.scheduledAt != null)
                _pillChip(
                  Icons.event_outlined,
                  'Delivery: ${_formatDate(header.scheduledAt)}${header.deliverySlot.isNotEmpty ? ' (${header.deliverySlot})' : ''}',
                  Colors.indigo.shade700,
                  Colors.indigo.shade50,
                ),
              _pillChip(
                Icons.access_time,
                'Placed: ${_formatDateTime(header.createdAt)}',
                Colors.grey.shade700,
                Colors.grey.shade100,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Customer & Delivery Details Card
  Widget _buildCustomerAndDeliveryCard(
    OrderDetailHeader header,
    ColorScheme colorScheme,
  ) {
    final isDelivery = header.fulfilmentType.toLowerCase().contains('delivery');
    final hasRecipient = header.recipientName.isNotEmpty;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_pin_circle_outlined,
                  color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                isDelivery ? 'Customer & Delivery Info' : 'Customer Info',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Recipient Section (if delivery/pickup and different)
          if (hasRecipient) ...[
            _infoRow(
              'Recipient',
              header.recipientName,
              phone: header.recipientPhone.isNotEmpty ? header.recipientPhone : null,
              isHighlight: true,
            ),
            const SizedBox(height: 8),
          ],
          // Customer Section
          _infoRow(
            'Customer',
            header.customerName.trim().isNotEmpty ? header.customerName : 'Walk-in Customer',
            phone: header.customerPhone.isNotEmpty ? header.customerPhone : null,
            isHighlight: !hasRecipient,
            isPrimaryCustomer: true,
          ),
          if (header.customerEmail != null && header.customerEmail!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _infoRow('Email', header.customerEmail!),
          ],
          if (header.occasion.isNotEmpty) ...[
            const SizedBox(height: 6),
            _infoRow('Occasion', header.occasion),
          ],
          // Delivery Address
          if (isDelivery && header.address.isNotEmpty) ...[
            const Divider(height: 20),
            _infoRow('Address', header.address),
            if (header.deliveryLandmark.isNotEmpty) ...[
              const SizedBox(height: 4),
              _infoRow('Landmark', header.deliveryLandmark),
            ],
            if (header.deliveryPincode.isNotEmpty) ...[
              const SizedBox(height: 4),
              _infoRow('Pincode', header.deliveryPincode),
            ],
          ],
        ],
      ),
    );
  }

  // Items List Card
  Widget _buildItemsCard(
    OrderDetailHeader header,
    OrderDetailBundle? bundle,
    ColorScheme colorScheme,
  ) {
    final lines = bundle?.lines ?? const <Map<String, Object?>>[];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.local_florist_outlined,
                      color: colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Order Items (${lines.length})',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (lines.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No items found',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lines.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final line = lines[index];
                final productName = (line['product_name'] as String?)?.trim();
                final lineDescription = (line['description'] as String?)?.trim();

                final String title;
                final String? subtitle;

                if (productName != null && productName.isNotEmpty) {
                  title = productName;
                  if (lineDescription != null &&
                      lineDescription.isNotEmpty &&
                      lineDescription != productName) {
                    subtitle = lineDescription;
                  } else {
                    subtitle = null;
                  }
                } else if (lineDescription != null && lineDescription.isNotEmpty) {
                  title = lineDescription;
                  subtitle = null;
                } else {
                  title = 'Product';
                  subtitle = null;
                }

                final sku = (line['product_sku'] as String?)?.trim() ??
                    (line['sku'] as String?)?.trim();
                final qty = (line['qty'] as int?) ?? 1;
                final unitPricePaise = (line['unit_price_paise'] as int?) ?? 0;
                final lineDiscountPaise = (line['discount_paise'] as int?) ?? 0;
                final lineTotalPaise = (line['line_total_paise'] as int?) ??
                    (unitPricePaise * qty - lineDiscountPaise);
                final gstPercent = (line['gst_percent'] as int?) ?? 0;
                final specialInstructions =
                    (line['special_instructions'] as String?)?.trim();

                final imageResult =
                    _productImageService.resolveForOrderLine(line);

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Thumbnail
                    _buildProductThumbnail(imageResult),
                    const SizedBox(width: 12),
                    // Product Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (subtitle != null && subtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                          if (sku != null && sku.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'SKU: $sku',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            '$qty × ${_formatPaise(unitPricePaise)}'
                            '${lineDiscountPaise > 0 ? ' • Discount: -${_formatPaise(lineDiscountPaise)}' : ''}'
                            '${gstPercent > 0 ? ' • GST $gstPercent%' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          if (specialInstructions != null &&
                              specialInstructions.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Note: $specialInstructions',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Line Total
                    Text(
                      _formatPaise(lineTotalPaise),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // Financial Summary Card
  Widget _buildFinancialSummaryCard(
    OrderDetailHeader header,
    ColorScheme colorScheme,
  ) {
    final subtotal = header.subtotalPaise;
    final discount = header.discountTotalPaise;
    final delivery = header.deliveryChargesPaise;
    final gst = header.gstTotalPaise;
    final roundOff = header.roundOffPaise;
    final grandTotal = header.grandTotalPaise;
    final paid = header.paidAmountPaise;
    final outstanding = header.outstandingAmountPaise;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_outlined, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Financial Summary',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _summaryRow('Subtotal', _formatPaise(subtotal > 0 ? subtotal : grandTotal)),
          if (discount > 0)
            _summaryRow('Discount', '-${_formatPaise(discount)}',
                color: Colors.green.shade700),
          if (delivery > 0)
            _summaryRow('Delivery Charges', _formatPaise(delivery)),
          if (gst > 0)
            _summaryRow('GST / Taxes', _formatPaise(gst)),
          if (roundOff != 0)
            _summaryRow('Round Off', '${roundOff > 0 ? '+' : ''}${_formatPaise(roundOff)}'),
          const Divider(height: 16),
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _summaryRow('Amount Paid', _formatPaise(paid),
              color: paid > 0 ? Colors.green.shade800 : null),
          if (outstanding > 0)
            _summaryRow(
              'Balance Outstanding',
              _formatPaise(outstanding),
              color: Colors.red.shade800,
              isBold: true,
            ),
        ],
      ),
    );
  }

  // Payment Details Card
  Widget _buildPaymentDetailsCard(
    OrderDetailHeader header,
    OrderDetailBundle bundle,
    ColorScheme colorScheme,
  ) {
    final payments = bundle.payments;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment_outlined, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Payments Received',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: payments.length,
            separatorBuilder: (_, __) => const Divider(height: 12),
            itemBuilder: (context, index) {
              final p = payments[index];
              final method = ((p['method'] as String?) ?? 'Cash').toUpperCase();
              final amountPaise = (p['amount_paise'] as int?) ?? 0;
              final reference = p['reference'] as String?;
              final createdAt = p['created_at'] != null
                  ? DateTime.tryParse(p['created_at'].toString())
                  : null;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blueGrey.shade200),
                            ),
                            child: Text(
                              method,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey.shade800,
                              ),
                            ),
                          ),
                          if (reference != null && reference.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              'Ref: $reference',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (createdAt != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          _formatDateTime(createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    _formatPaise(amountPaise),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: amountPaise >= 0
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Card Message & Notes
  Widget _buildNotesCard(OrderDetailHeader header, ColorScheme colorScheme) {
    final hasInternalNotes =
        header.internalNotes != null && header.internalNotes!.isNotEmpty;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.card_giftcard_outlined,
                  color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Card Message & Instructions',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (header.cardMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.pink.shade50.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.pink.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.favorite, size: 14, color: Colors.pink.shade400),
                      const SizedBox(width: 6),
                      Text(
                        'Greeting Card Message',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '"${header.cardMessage}"',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                      color: Colors.pink.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (header.specialInstructions.isNotEmpty) ...[
            const SizedBox(height: 10),
            _infoRow('Special Instructions', header.specialInstructions),
          ],
          if (hasInternalNotes) ...[
            const SizedBox(height: 8),
            _infoRow('Internal Notes', header.internalNotes!),
          ],
        ],
      ),
    );
  }

  // Assigned Staff (Designer & Driver)
  Widget _buildAssignmentsCard(OrderDetailHeader header, ColorScheme colorScheme) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.badge_outlined, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Staff Assignments',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (header.designerName != null && header.designerName!.isNotEmpty)
            _assignmentRow('🎨 Designer', header.designerName!),
          if (header.deliveryName != null && header.deliveryName!.isNotEmpty) ...[
            if (header.designerName != null && header.designerName!.isNotEmpty)
              const SizedBox(height: 6),
            _assignmentRow('🚚 Driver', header.deliveryName!),
          ],
        ],
      ),
    );
  }

  Widget _assignmentRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildProductThumbnail(ProductImageResult imageResult) {
    if (!imageResult.hasImage) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.local_florist_outlined,
            size: 20, color: Colors.grey.shade400),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 44,
        height: 44,
        child: SafePlatformImageView(
          imagePath: imageResult.reference,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          fallbackIcon: Icons.local_florist_outlined,
          errorIcon: Icons.local_florist_outlined,
        ),
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    String? phone,
    bool isHighlight = false,
    bool isPrimaryCustomer = false,
  }) {
    final isEmphasized = isHighlight || isPrimaryCustomer;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: isEmphasized ? 15.5 : 13.5,
                  fontWeight: isEmphasized ? FontWeight.bold : FontWeight.w600,
                  color: const Color(0xFF1E2922),
                ),
              ),
              if (phone != null && phone.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  phone,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillChip(IconData icon, String label, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  bool _hasNotes(OrderDetailHeader header) {
    return header.cardMessage.isNotEmpty ||
        header.specialInstructions.isNotEmpty ||
        (header.internalNotes != null && header.internalNotes!.isNotEmpty);
  }

  bool _hasAssignments(OrderDetailHeader header) {
    return (header.designerName != null && header.designerName!.isNotEmpty) ||
        (header.deliveryName != null && header.deliveryName!.isNotEmpty);
  }

  IconData _getFulfilmentIcon(String type) {
    return switch (type.toLowerCase()) {
      'take_away' => Icons.shopping_bag_outlined,
      'pickup_later' => Icons.storefront_outlined,
      _ => Icons.local_shipping_outlined,
    };
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    return '${value.day}/${value.month}/${value.year}';
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return '-';
    final hour = value.hour == 0
        ? 12
        : (value.hour > 12 ? value.hour - 12 : value.hour);
    final minute = value.minute.toString().padLeft(2, '0');
    final meridiem = value.hour >= 12 ? 'PM' : 'AM';
    return '${value.day}/${value.month}/${value.year} $hour:$minute $meridiem';
  }

  String _formatPaise(int paise) {
    return '₹${(paise / 100).toStringAsFixed(0)}';
  }

  String _pretty(String value) {
    return value.replaceAll('_', ' ').replaceAllMapped(
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
