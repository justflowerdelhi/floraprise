import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/repositories/order_repository.dart';
import '../../managers/business_settings_manager.dart';
import '../../managers/pricing_manager.dart';
import '../../managers/walk_in_manager.dart';
import '../../models/crm_models.dart';
import '../../models/walk_in_session.dart';
import '../../providers/crm_provider.dart';
import '../../providers/walk_in_session_provider.dart';
import '../../services/pdf/pdf_document_service.dart';
import '../../utils/whatsapp_phone_utils.dart';
import '../order_view_screen.dart';
import 'crm_quote_compose_dialog.dart';
import 'crm_reopen_dialog.dart';

class CrmQuotePreviewDialog extends StatefulWidget {
  const CrmQuotePreviewDialog({
    super.key,
    required this.enquiry,
  });

  final CrmEnquiryItem enquiry;

  static Future<void> show(
    BuildContext context, {
    required CrmEnquiryItem enquiry,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => CrmQuotePreviewDialog(enquiry: enquiry),
    );
  }

  @override
  State<CrmQuotePreviewDialog> createState() => _CrmQuotePreviewDialogState();
}

class _CrmQuotePreviewDialogState extends State<CrmQuotePreviewDialog> {
  final PricingManager _pricingManager = PricingManager();
  final PdfDocumentService _pdfService = PdfDocumentService();

  bool _isLoading = true;
  bool _isConverting = false;
  WalkInSession? _session;
  OrderTotals? _totals;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDraftSession();
  }

  Future<void> _loadDraftSession() async {
    if (widget.enquiry.quoteOrderId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No quotation draft linked to this enquiry.';
      });
      return;
    }

    try {
      final provider = context.read<CrmProvider>();
      final session = await provider.loadQuoteDraft(widget.enquiry.quoteOrderId!);
      if (!mounted) return;

      if (session != null) {
        final totals = _pricingManager.computeTotals(
          lines: session.lines,
          billDiscountType: session.billDiscountType,
          billDiscountValue: session.billDiscountValue,
        );
        setState(() {
          _session = session;
          _totals = totals;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Quotation draft #${widget.enquiry.quoteOrderId} could not be loaded.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load quotation: $e';
        });
      }
    }
  }

  Future<void> _downloadPdf() async {
    if (_session == null || _totals == null) return;
    await _pdfService.downloadOrShareQuotationPdf(
      context: context,
      enquiry: widget.enquiry,
      session: _session!,
      totals: _totals!,
    );
  }

  Future<void> _shareWhatsApp() async {
    if (_session == null || _totals == null) return;

    final phone = widget.enquiry.customerPhone.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No customer phone number available for WhatsApp.')),
      );
      return;
    }

    final business = await BusinessSettingsManager().load();
    final shopName = business.shopName.trim().isNotEmpty
        ? business.shopName.trim()
        : 'Floraprise Florist';

    final qDate = widget.enquiry.updatedAt;
    final validUntil = qDate.add(const Duration(days: 7));
    final validUntilStr = DateFormat('dd MMM yyyy').format(validUntil);
    final amountStr = (_totals!.grandTotalPaise / 100).toStringAsFixed(2);
    final quoteRef = 'QUO-${_session!.draftOrderId ?? widget.enquiry.quoteOrderId}';

    final message = 'Hello ${widget.enquiry.customerName},\n\n'
        'Please find your quotation for ${widget.enquiry.category} (${widget.enquiry.requirement}):\n\n'
        '💰 Quotation Amount: ₹$amountStr\n'
        '📄 Quotation Ref: $quoteRef\n'
        '📅 Valid Until: $validUntilStr\n\n'
        'Thank you,\n'
        '$shopName';

    final uri = WhatsAppPhoneUtils.buildUri(phone, message: message) ??
        WhatsAppPhoneUtils.buildFallbackUri(phone, message: message);

    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open WhatsApp for $phone')),
      );
    }
  }

  Future<void> _editQuote() async {
    Navigator.of(context).pop();
    await CrmQuoteComposeDialog.show(context, enquiry: widget.enquiry);
  }

  Future<void> _markWonAndConvert() async {
    if (_isConverting) return;
    setState(() {
      _isConverting = true;
    });

    try {
      WalkInManager? walkInManager;
      try {
        walkInManager = context.read<WalkInSessionProvider>().walkInManager;
      } catch (_) {}

      final messenger = ScaffoldMessenger.of(context);
      final nav = Navigator.of(context);
      final provider = context.read<CrmProvider>();
      final confirmedOrderId = await provider.convertQuoteToWonOrder(
        enquiry: widget.enquiry,
        walkInManager: walkInManager,
      );

      if (!mounted) return;
      setState(() {
        _isConverting = false;
      });
      if (nav.canPop()) {
        nav.pop();
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text('Order created successfully — Order #ORD-$confirmedOrderId'),
          backgroundColor: const Color(0xFF059669),
          action: SnackBarAction(
            label: 'View Order',
            textColor: Colors.white,
            onPressed: () {
              nav.push(
                MaterialPageRoute(
                  builder: (_) => OrderViewScreen(orderId: confirmedOrderId),
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConverting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to convert quote: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _viewOrder(int orderId) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderViewScreen(orderId: orderId),
      ),
    );
  }

  Future<void> _reopenEnquiry() async {
    final result = await CrmReopenDialog.show(context, enquiry: widget.enquiry);
    if (result == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = MediaQuery.sizeOf(context).width >= 720;

    if (_isLoading) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading quotation preview...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _session == null || _totals == null) {
      return AlertDialog(
        title: const Text('Quotation Preview'),
        content: Text(_errorMessage ?? 'Quotation not found.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    }

    final session = _session!;
    final totals = _totals!;
    final quoteRef = 'QUO-${session.draftOrderId ?? widget.enquiry.quoteOrderId}';
    final validUntil = widget.enquiry.updatedAt.add(const Duration(days: 7));
    final validUntilStr = DateFormat('dd MMM yyyy').format(validUntil);

    final content = Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quotation $quoteRef', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
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
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                if (widget.enquiry.status == 'lost') ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Enquiry Marked as Lost',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF991B1B),
                                ),
                              ),
                              if (widget.enquiry.lostReason != null && widget.enquiry.lostReason!.isNotEmpty)
                                Text(
                                  'Reason: ${widget.enquiry.lostReason}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF7F1D1D)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Validity & Requirement Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.verified_outlined, color: colorScheme.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.enquiry.category} — ${widget.enquiry.requirement}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Valid for 7 days until $validUntilStr • Fulfillment: ${session.fulfilmentType.name.toUpperCase()}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Line items list
                Text(
                  'Items (${session.lines.length})',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: session.lines.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final line = session.lines[index];
                      final lineSubtotal = (line.unitPricePaise * line.quantity) - line.discountPaise;
                      return ListTile(
                        dense: true,
                        title: Text(line.description, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${line.quantity} × ₹${(line.unitPricePaise / 100).toStringAsFixed(2)}${line.discountPaise > 0 ? ' (Disc: ₹${(line.discountPaise / 100).toStringAsFixed(0)})' : ''}${line.gstPercent != null && line.gstPercent! > 0 ? ' • GST ${line.gstPercent}%' : ''}',
                        ),
                        trailing: Text(
                          '₹${(lineSubtotal / 100).toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // Special instructions
                if (session.specialInstructions.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notes / Special Instructions:',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          session.specialInstructions,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Totals Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      _buildRow('Subtotal:', '₹${(totals.subtotalPaise / 100).toStringAsFixed(2)}'),
                      if (totals.discountTotalPaise > 0)
                        _buildRow(
                          'Total Discount:',
                          '-₹${(totals.discountTotalPaise / 100).toStringAsFixed(2)}',
                          color: Colors.green.shade700,
                        ),
                      if (totals.gstTotalPaise > 0)
                        _buildRow('Estimated GST:', '₹${(totals.gstTotalPaise / 100).toStringAsFixed(2)}'),
                      if (totals.roundOffPaise != 0)
                        _buildRow(
                          'Round Off:',
                          '${totals.roundOffPaise > 0 ? '+' : ''}₹${(totals.roundOffPaise / 100).toStringAsFixed(2)}',
                        ),
                      const Divider(height: 10),
                      _buildRow(
                        'Grand Total:',
                        '₹${(totals.grandTotalPaise / 100).toStringAsFixed(2)}',
                        isBold: true,
                        fontSize: 15,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Bottom Action Buttons Bar
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
              spacing: 8,
              runSpacing: 8,
              children: [
                if (widget.enquiry.status == 'won' || widget.enquiry.convertedOrderId != null)
                  FilledButton.icon(
                    onPressed: widget.enquiry.convertedOrderId != null
                        ? () => _viewOrder(widget.enquiry.convertedOrderId!)
                        : null,
                    icon: const Icon(Icons.receipt_long_rounded, size: 16),
                    label: Text(widget.enquiry.convertedOrderId != null
                        ? 'View Order (#ORD-${widget.enquiry.convertedOrderId})'
                        : 'Order Won'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                    ),
                  )
                else if (widget.enquiry.status == 'lost')
                  FilledButton.icon(
                    onPressed: _reopenEnquiry,
                    icon: const Icon(Icons.replay_rounded, size: 16),
                    label: const Text('Reopen Enquiry'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: _isConverting ? null : _editQuote,
                    icon: const Icon(Icons.edit_note_rounded, size: 16),
                    label: const Text('Edit Quote'),
                  ),
                OutlinedButton.icon(
                  onPressed: _isConverting ? null : _downloadPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                  label: const Text('Download PDF'),
                ),
                FilledButton.icon(
                  onPressed: _isConverting ? null : _shareWhatsApp,
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Colors.white),
                  label: const Text('Share WhatsApp'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                  ),
                ),
                if (widget.enquiry.status != 'won' && widget.enquiry.convertedOrderId == null && widget.enquiry.status != 'lost')
                  FilledButton.icon(
                    onPressed: _isConverting ? null : _markWonAndConvert,
                    icon: _isConverting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_outline_rounded, size: 16),
                    label: Text(_isConverting ? 'Converting...' : 'Mark Won & Convert'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                    ),
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
          width: 720,
          height: 600,
          child: content,
        ),
      );
    }

    return Dialog.fullscreen(child: content);
  }

  Widget _buildRow(String label, String value, {bool isBold = false, double fontSize = 12, Color? color}) {
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
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
