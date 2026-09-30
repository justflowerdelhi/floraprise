import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/repositories/order_repository.dart';
import '../../managers/business_settings_manager.dart';
import '../../models/crm_models.dart';
import '../../models/walk_in_session.dart';

/// Builds professional A4 Quotation / Estimate PDF documents for CRM enquiries.
class PdfQuotationBuilder {
  const PdfQuotationBuilder();

  static String formatCurrency(int paise, [String? symbol]) {
    final sym = (symbol == null || symbol.trim().isEmpty || symbol.contains('₹'))
        ? 'Rs. '
        : (symbol.trim() == 'INR' ? 'Rs. ' : '$symbol ');
    if (paise < 0) {
      return '-$sym${(paise.abs() / 100).toStringAsFixed(2)}';
    }
    return '$sym${(paise / 100).toStringAsFixed(2)}';
  }

  /// Builds A4 Quotation PDF from CRM Enquiry, WalkInSession, and OrderTotals.
  Future<Uint8List> build({
    required BusinessSettings business,
    required CrmEnquiryItem enquiry,
    required WalkInSession session,
    required OrderTotals totals,
    DateTime? quotationDate,
    DateTime? validUntilDate,
  }) async {
    final doc = pw.Document();
    final fiscal = business.resolvedFiscalProfile;
    final currency = fiscal.currencySymbol;
    final taxIdLabel = fiscal.taxIdentifierLabel;

    final shopName =
        business.shopName.trim().isEmpty ? 'FLORAPRISE' : business.shopName.trim();
    final shopAddress = business.address.trim();
    final shopPhone = business.phone.trim();
    final gstin = business.gstRegistered
        ? business.gstNumber.trim()
        : (fiscal.taxIdentifier ?? '');

    final qDate = quotationDate ?? DateTime.now();
    final vDate = validUntilDate ?? qDate.add(const Duration(days: 7));
    final qDateStr = DateFormat('dd-MM-yyyy').format(qDate);
    final vDateStr = DateFormat('dd-MM-yyyy').format(vDate);

    final quoteNo = session.draftOrderId != null
        ? 'QUO-${session.draftOrderId}'
        : 'QUO-${enquiry.clientSyncId.length >= 8 ? enquiry.clientSyncId.substring(0, 8).toUpperCase() : enquiry.clientSyncId}';

    final primaryColor = PdfColor.fromHex('#0F3822');
    final accentColor = PdfColor.fromHex('#1E3A8A');
    final tableHeaderBg = PdfColor.fromHex('#EBF3EE');
    final borderColor = PdfColor.fromHex('#D2E2D8');
    final lightGrey = PdfColor.fromHex('#666666');
    final darkGrey = PdfColor.fromHex('#333333');

    final lines = session.lines;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left: Business info
                pw.Expanded(
                  flex: 3,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        shopName,
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      if (shopAddress.isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 2),
                          child: pw.Text(
                            shopAddress,
                            style: pw.TextStyle(fontSize: 9, color: lightGrey),
                          ),
                        ),
                      if (shopPhone.isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 1),
                          child: pw.Text(
                            'Phone: $shopPhone',
                            style: pw.TextStyle(fontSize: 9, color: lightGrey),
                          ),
                        ),
                      if (gstin.isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 1),
                          child: pw.Text(
                            '$taxIdLabel: $gstin',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: darkGrey,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Right: Document Title & Metadata
                pw.Expanded(
                  flex: 2,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: tableHeaderBg,
                          borderRadius:
                              const pw.BorderRadius.all(pw.Radius.circular(4)),
                          border: pw.Border.all(color: borderColor),
                        ),
                        child: pw.Text(
                          'ESTIMATE / QUOTATION',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Quotation Ref: $quoteNo',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: darkGrey,
                        ),
                      ),
                      pw.Text(
                        'Date: $qDateStr',
                        style: pw.TextStyle(fontSize: 9, color: lightGrey),
                      ),
                      pw.Text(
                        'Valid Until: $vDateStr',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              child: pw.Divider(color: borderColor, thickness: 1),
            ),
          ],
        ),
        build: (context) {
          final eventDateStr = enquiry.eventDate != null
              ? DateFormat('dd-MM-yyyy').format(enquiry.eventDate!)
              : (session.scheduledAt != null
                  ? DateFormat('dd-MM-yyyy').format(session.scheduledAt!)
                  : null);

          final venueAddress = session.deliveryAddress.trim().isNotEmpty
              ? session.deliveryAddress.trim()
              : (enquiry.location?.trim() ?? '');

          return [
            // Customer & Event Box
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: borderColor),
                color: PdfColor.fromHex('#F9FBF9'),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Client info
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'PREPARED FOR:',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          enquiry.customerName,
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: darkGrey,
                          ),
                        ),
                        if (enquiry.customerPhone.isNotEmpty)
                          pw.Text(
                            'Phone: ${enquiry.customerPhone}',
                            style: pw.TextStyle(fontSize: 9, color: darkGrey),
                          ),
                        if (venueAddress.isNotEmpty)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 2),
                            child: pw.Text(
                              'Venue / Address: $venueAddress',
                              style: pw.TextStyle(fontSize: 9, color: lightGrey),
                            ),
                          ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  // Event info
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'EVENT & REQUIREMENT DETAILS:',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Category: ${enquiry.category}',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: darkGrey,
                          ),
                        ),
                        pw.Text(
                          'Requirement: ${enquiry.requirement}',
                          style: pw.TextStyle(fontSize: 9, color: darkGrey),
                        ),
                        if (eventDateStr != null)
                          pw.Text(
                            'Event Date: $eventDateStr',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        pw.Text(
                          'Fulfillment: ${session.fulfilmentType.name.toUpperCase()}',
                          style: pw.TextStyle(fontSize: 8, color: lightGrey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // Line Items Table
            pw.Table(
              border: pw.TableBorder(
                horizontalInside: pw.BorderSide(color: borderColor, width: 0.5),
                bottom: pw.BorderSide(color: borderColor, width: 1),
              ),
              columnWidths: const {
                0: pw.FixedColumnWidth(24), // #
                1: pw.FlexColumnWidth(4), // Item / Description
                2: pw.FixedColumnWidth(36), // Qty
                3: pw.FixedColumnWidth(65), // Rate
                4: pw.FixedColumnWidth(55), // Disc
                5: pw.FixedColumnWidth(40), // GST
                6: pw.FixedColumnWidth(75), // Total
              },
              children: [
                // Table Header
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: tableHeaderBg,
                    border: pw.Border(
                      top: pw.BorderSide(color: borderColor),
                      bottom: pw.BorderSide(color: borderColor, width: 1),
                    ),
                  ),
                  children: [
                    _buildCell('#', isHeader: true, align: pw.TextAlign.center),
                    _buildCell('Item / Description', isHeader: true),
                    _buildCell('Qty', isHeader: true, align: pw.TextAlign.center),
                    _buildCell('Rate', isHeader: true, align: pw.TextAlign.right),
                    _buildCell('Disc', isHeader: true, align: pw.TextAlign.right),
                    _buildCell('GST', isHeader: true, align: pw.TextAlign.center),
                    _buildCell('Amount', isHeader: true, align: pw.TextAlign.right),
                  ],
                ),
                // Line items
                for (int i = 0; i < lines.length; i++)
                  _buildLineRow(
                    index: i + 1,
                    line: lines[i],
                    currency: currency,
                    darkGrey: darkGrey,
                    lightGrey: lightGrey,
                  ),
              ],
            ),
            pw.SizedBox(height: 14),

            // Bottom Section: Notes/Terms (Left) & Totals (Right)
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left: Instructions & Terms
                pw.Expanded(
                  flex: 3,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (session.specialInstructions.isNotEmpty) ...[
                        pw.Text(
                          'Special Instructions / Proposal Notes:',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          session.specialInstructions,
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            color: darkGrey,
                            fontStyle: pw.FontStyle.italic,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                      ],
                      pw.Text(
                        'Terms & Conditions:',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        '1. This quotation is valid for 7 days from the date of issue.\n'
                        '2. Prices are subject to floral availability and seasonal changes.\n'
                        '3. Advance payment is required to confirm date and booking.',
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          color: lightGrey,
                          lineSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 16),
                // Right: Totals Box
                pw.Expanded(
                  flex: 2,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(6)),
                      border: pw.Border.all(color: borderColor),
                      color: tableHeaderBg,
                    ),
                    child: pw.Column(
                      children: [
                        _buildTotalLine(
                          'Subtotal:',
                          formatCurrency(totals.subtotalPaise, currency),
                        ),
                        if (totals.discountTotalPaise > 0)
                          _buildTotalLine(
                            'Total Discount:',
                            '-${formatCurrency(totals.discountTotalPaise, currency)}',
                            color: PdfColor.fromHex('#047857'),
                          ),
                        if (totals.gstTotalPaise > 0)
                          _buildTotalLine(
                            'Estimated GST:',
                            formatCurrency(totals.gstTotalPaise, currency),
                          ),
                        if (totals.roundOffPaise != 0)
                          _buildTotalLine(
                            'Round Off:',
                            formatCurrency(totals.roundOffPaise, currency),
                          ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 4),
                          child: pw.Divider(color: borderColor, thickness: 1),
                        ),
                        _buildTotalLine(
                          'GRAND TOTAL:',
                          formatCurrency(totals.grandTotalPaise, currency),
                          isBold: true,
                          fontSize: 11,
                          color: primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ];
        },
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: borderColor, thickness: 0.5),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Thank you for considering $shopName!',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontStyle: pw.FontStyle.italic,
                    color: primaryColor,
                  ),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 8, color: lightGrey),
                ),
              ],
            ),
            pw.SizedBox(height: 2),
            pw.Center(
              child: pw.Text(
                'This is an estimate/quotation and does not constitute a tax invoice.',
                style: pw.TextStyle(fontSize: 7, color: lightGrey),
              ),
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  pw.TableRow _buildLineRow({
    required int index,
    required dynamic line,
    required String currency,
    required PdfColor darkGrey,
    required PdfColor lightGrey,
  }) {
    final qty = line.quantity as int;
    final unitPrice = line.unitPricePaise as int;
    final discount = line.discountPaise as int;
    final gstPercent = line.gstPercent as int?;
    final lineTotal = (unitPrice * qty) - discount;

    return pw.TableRow(
      children: [
        _buildCell('$index', align: pw.TextAlign.center),
        _buildCell(line.description as String),
        _buildCell('$qty', align: pw.TextAlign.center),
        _buildCell(formatCurrency(unitPrice, currency),
            align: pw.TextAlign.right),
        _buildCell(discount > 0 ? formatCurrency(discount, currency) : '-',
            align: pw.TextAlign.right),
        _buildCell(gstPercent != null && gstPercent > 0 ? '$gstPercent%' : '-',
            align: pw.TextAlign.center),
        _buildCell(formatCurrency(lineTotal, currency),
            align: pw.TextAlign.right, isBold: true),
      ],
    );
  }

  pw.Widget _buildCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 8.5 : 8,
          fontWeight: isHeader || isBold
              ? pw.FontWeight.bold
              : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _buildTotalLine(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 8.5,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
