import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../managers/business_settings_manager.dart';
import '../../models/order_status.dart';
import '../../models/order_workspace_models.dart';

/// Builds professional A4 Tax Invoice / Bill PDF documents.
class PdfBillBuilder {
  const PdfBillBuilder();

  static String formatCurrency(int paise, [String? symbol]) {
    final sym = (symbol == null || symbol.trim().isEmpty || symbol.contains('₹'))
        ? 'Rs. '
        : (symbol.trim() == 'INR' ? 'Rs. ' : '$symbol ');
    if (paise < 0) {
      return '-$sym${(paise.abs() / 100).toStringAsFixed(2)}';
    }
    return '$sym${(paise / 100).toStringAsFixed(2)}';
  }

  /// Builds A4 Bill PDF from strongly-typed order models.
  Future<Uint8List> build({
    required BusinessSettings business,
    required OrderDetailHeader header,
    OrderDetailBundle? bundle,
  }) async {
    final doc = pw.Document();
    final fiscal = business.resolvedFiscalProfile;
    final currency = fiscal.currencySymbol;
    final taxLabel = fiscal.taxLabel;
    final taxIdLabel = fiscal.taxIdentifierLabel;

    final shopName = business.shopName.trim().isEmpty ? 'FLORAPRISE' : business.shopName.trim();
    final shopAddress = business.address.trim();
    final shopPhone = business.phone.trim();
    final gstin = business.gstRegistered ? business.gstNumber.trim() : (fiscal.taxIdentifier ?? '');

    final invoiceNo = header.displayOrderNo;
    final orderDate = header.createdAt != null
        ? DateFormat('dd-MM-yyyy HH:mm').format(header.createdAt!)
        : DateFormat('dd-MM-yyyy').format(DateTime.now());

    final lines = bundle?.lines ?? const <Map<String, Object?>>[];
    final payments = bundle?.payments ?? const <Map<String, Object?>>[];

    final primaryColor = PdfColor.fromHex('#0F3822');
    final tableHeaderBg = PdfColor.fromHex('#EBF3EE');
    final borderColor = PdfColor.fromHex('#D2E2D8');
    final lightGrey = PdfColor.fromHex('#666666');

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
                pw.Expanded(
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
                              color: primaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: primaryColor,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Text(
                        'TAX INVOICE',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Invoice No: $invoiceNo',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Date: $orderDate',
                      style: pw.TextStyle(fontSize: 9, color: lightGrey),
                    ),
                    pw.Container(
                      margin: const pw.EdgeInsets.only(top: 3),
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: pw.BoxDecoration(
                        color: header.isPaid == 1 ? PdfColors.green50 : PdfColors.red50,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                        border: pw.Border.all(
                          color: header.isPaid == 1 ? PdfColors.green700 : PdfColors.red700,
                          width: 0.5,
                        ),
                      ),
                      child: pw.Text(
                        header.paymentStatus.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: header.isPaid == 1 ? PdfColors.green900 : PdfColors.red900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              child: pw.Divider(color: borderColor, thickness: 1),
            ),
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: borderColor, thickness: 0.5),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Thank you for your business! | Computer-generated invoice',
                  style: pw.TextStyle(fontSize: 8, color: lightGrey),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 8, color: lightGrey),
                ),
              ],
            ),
          ],
        ),
        build: (context) => [
          // Billed To Section
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F8FAF9'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              border: pw.Border.all(color: borderColor, width: 0.5),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BILLED TO:',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        header.customerName.isNotEmpty ? header.customerName : 'Walk-in Customer',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                      if (header.customerPhone.isNotEmpty)
                        pw.Text('Phone: ${header.customerPhone}', style: const pw.TextStyle(fontSize: 9)),
                      if (header.customerEmail != null && header.customerEmail!.isNotEmpty)
                        pw.Text('Email: ${header.customerEmail!}', style: const pw.TextStyle(fontSize: 9)),
                      if (header.customerAddress != null && header.customerAddress!.isNotEmpty)
                        pw.Text('Address: ${header.customerAddress!}', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ),
                if (header.recipientName.isNotEmpty && header.recipientName != header.customerName)
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'DELIVER TO / RECIPIENT:',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          header.recipientName,
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        if (header.recipientPhone.isNotEmpty)
                          pw.Text('Phone: ${header.recipientPhone}', style: const pw.TextStyle(fontSize: 9)),
                        if (header.address.isNotEmpty)
                          pw.Text('Address: ${header.address}', style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // Items Table
          pw.Table(
            border: pw.TableBorder.all(color: borderColor, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(24),
              1: const pw.FlexColumnWidth(4),
              2: const pw.FixedColumnWidth(36),
              3: const pw.FixedColumnWidth(60),
              4: const pw.FixedColumnWidth(50),
              5: const pw.FixedColumnWidth(44),
              6: const pw.FixedColumnWidth(64),
            },
            children: [
              // Header Row
              pw.TableRow(
                decoration: pw.BoxDecoration(color: tableHeaderBg),
                children: [
                  _cell('#', isHeader: true, align: pw.TextAlign.center),
                  _cell('Item Description', isHeader: true),
                  _cell('Qty', isHeader: true, align: pw.TextAlign.center),
                  _cell('Rate', isHeader: true, align: pw.TextAlign.right),
                  _cell('Discount', isHeader: true, align: pw.TextAlign.right),
                  _cell(taxLabel, isHeader: true, align: pw.TextAlign.center),
                  _cell('Amount', isHeader: true, align: pw.TextAlign.right),
                ],
              ),
              // Item Rows
              if (lines.isEmpty)
                pw.TableRow(
                  children: [
                    _cell('1', align: pw.TextAlign.center),
                    _cell('Order Arrangement / Items'),
                    _cell('1', align: pw.TextAlign.center),
                    _cell(formatCurrency(header.grandTotalPaise, currency), align: pw.TextAlign.right),
                    _cell('-', align: pw.TextAlign.right),
                    _cell('-', align: pw.TextAlign.center),
                    _cell(formatCurrency(header.grandTotalPaise, currency), align: pw.TextAlign.right),
                  ],
                )
              else
                for (int i = 0; i < lines.length; i++) ...[
                  _buildItemRow(i + 1, lines[i], currency),
                ],
            ],
          ),
          pw.SizedBox(height: 10),

          // Financial Summary Section
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Notes / Message Card Left side
              pw.Expanded(
                flex: 5,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (header.cardMessage.trim().isNotEmpty) ...[
                      pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#FDF8F0'),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                          border: pw.Border.all(color: PdfColor.fromHex('#E8DAC0'), width: 0.5),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'MESSAGE CARD NOTE:',
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromHex('#7A5210'),
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              header.cardMessage,
                              style: const pw.TextStyle(fontSize: 8.5),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 8),
                    ],
                    if (header.specialInstructions.trim().isNotEmpty) ...[
                      pw.Text(
                        'Instructions: ${header.specialInstructions}',
                        style: pw.TextStyle(fontSize: 8.5, color: lightGrey),
                      ),
                      pw.SizedBox(height: 4),
                    ],
                    if (header.status.isNotEmpty)
                      pw.Text(
                        'Status: ${OrderStatus.label(header.status)} | Fulfilment: ${header.fulfilmentType}',
                        style: pw.TextStyle(fontSize: 8, color: lightGrey),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(width: 16),
              // Summary Box Right side
              pw.Expanded(
                flex: 5,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: borderColor, width: 0.5),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    children: [
                      _summaryLine(
                        'Subtotal:',
                        formatCurrency(
                          header.subtotalPaise > 0 ? header.subtotalPaise : header.grandTotalPaise,
                          currency,
                        ),
                      ),
                      if (header.discountTotalPaise > 0)
                        _summaryLine(
                          'Discount:',
                          '-${formatCurrency(header.discountTotalPaise, currency)}',
                          isNegative: true,
                        ),
                      if (header.rewardDiscountAmountPaise > 0)
                        _summaryLine(
                          'Reward Discount:',
                          '-${formatCurrency(header.rewardDiscountAmountPaise, currency)}',
                          isNegative: true,
                        ),
                      if (header.deliveryChargesPaise > 0)
                        _summaryLine(
                          'Delivery Charges:',
                          formatCurrency(header.deliveryChargesPaise, currency),
                        ),
                      if (header.gstTotalPaise > 0)
                        _summaryLine(
                          '$taxLabel / Taxes:',
                          formatCurrency(header.gstTotalPaise, currency),
                        ),
                      if (header.roundOffPaise != 0)
                        _summaryLine(
                          'Round Off:',
                          '${header.roundOffPaise > 0 ? '+' : ''}${formatCurrency(header.roundOffPaise, currency)}',
                        ),
                      pw.Divider(color: borderColor, thickness: 0.5),
                      _summaryLine(
                        'Grand Total:',
                        formatCurrency(header.grandTotalPaise, currency),
                        isBold: true,
                        fontSize: 11,
                        color: primaryColor,
                      ),
                      pw.SizedBox(height: 2),
                      _summaryLine(
                        'Amount Paid:',
                        formatCurrency(header.paidAmountPaise, currency),
                        isBold: header.paidAmountPaise > 0,
                      ),
                      if (header.outstandingAmountPaise > 0)
                        _summaryLine(
                          'Balance Due:',
                          formatCurrency(header.outstandingAmountPaise, currency),
                          isBold: true,
                          color: PdfColors.red800,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),

          // Payment Records (if recorded)
          if (payments.isNotEmpty) ...[
            pw.Text(
              'PAYMENT DETAILS:',
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(color: borderColor, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: tableHeaderBg),
                  children: [
                    _cell('Method', isHeader: true),
                    _cell('Amount', isHeader: true, align: pw.TextAlign.right),
                    _cell('Reference / Mode', isHeader: true),
                    _cell('Date', isHeader: true, align: pw.TextAlign.right),
                  ],
                ),
                for (final p in payments) ...[
                  pw.TableRow(
                    children: [
                      _cell((p['method'] as String?)?.toUpperCase() ?? 'CASH'),
                      _cell(
                        formatCurrency((p['amount_paise'] as int?) ?? 0, currency),
                        align: pw.TextAlign.right,
                      ),
                      _cell((p['reference'] as String?) ?? '-'),
                      _cell(
                        (p['paid_at'] as String?) ?? orderDate,
                        align: pw.TextAlign.right,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );

    return doc.save();
  }

  /// Builds A4 Bill PDF from payload map (reusable for POS flows).
  Future<Uint8List> buildFromPayload(
    Map<String, dynamic> payload, {
    BusinessSettings? business,
  }) async {
    final settings = business ?? await BusinessSettingsManager().load();
    final header = _headerFromPayload(payload);
    final bundle = _bundleFromPayload(header, payload);
    return build(business: settings, header: header, bundle: bundle);
  }

  static pw.Widget _cell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 8.5 : 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.TableRow _buildItemRow(int index, Map<String, Object?> line, String? currency) {
    final productName = (line['product_name'] as String?)?.trim() ??
        (line['name'] as String?)?.trim() ??
        'Item';
    final lineDesc = (line['description'] as String?)?.trim();
    final displayName = (lineDesc != null && lineDesc.isNotEmpty && lineDesc != productName)
        ? '$productName ($lineDesc)'
        : productName;

    final qty = (line['quantity'] as int?) ?? (line['qty'] as int?) ?? 1;
    final ratePaise = (line['unit_price_paise'] as int?) ?? (line['ratePaise'] as int?) ?? 0;
    final discountPaise = (line['discount_paise'] as int?) ?? 0;
    final gstPercent = (line['gst_percent'] as int?) ?? 0;
    final lineTotalPaise = (line['line_total_paise'] as int?) ?? (line['totalPaise'] as int?) ?? (qty * ratePaise);

    return pw.TableRow(
      children: [
        _cell('$index', align: pw.TextAlign.center),
        _cell(displayName),
        _cell('$qty', align: pw.TextAlign.center),
        _cell(formatCurrency(ratePaise, currency), align: pw.TextAlign.right),
        _cell(discountPaise > 0 ? '-${formatCurrency(discountPaise, currency)}' : '-', align: pw.TextAlign.right),
        _cell(gstPercent > 0 ? '$gstPercent%' : '-', align: pw.TextAlign.center),
        _cell(formatCurrency(lineTotalPaise, currency), align: pw.TextAlign.right),
      ],
    );
  }

  static pw.Widget _summaryLine(
    String label,
    String value, {
    bool isBold = false,
    bool isNegative = false,
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
              color: color ?? (isNegative ? PdfColors.green800 : null),
            ),
          ),
        ],
      ),
    );
  }

  static OrderDetailHeader _headerFromPayload(Map<String, dynamic> p) {
    final grandTotal = (p['grandTotalPaise'] as int?) ?? (p['grand_total_paise'] as int?) ?? 0;
    final paid = (p['paidPaise'] as int?) ?? 0;
    return OrderDetailHeader(
      id: (p['order_id'] as int?) ?? 0,
      orderNo: (p['order_no'] as String?) ?? (p['invoiceNumber'] as String?) ?? 'POS-BILL',
      status: (p['status'] as String?) ?? 'completed',
      customerName: (p['customerName'] as String?) ?? 'Customer',
      customerPhone: (p['customerPhone'] as String?) ?? '',
      recipientName: (p['recipientName'] as String?) ?? (p['customerName'] as String?) ?? '',
      recipientPhone: (p['recipientPhone'] as String?) ?? '',
      fulfilmentType: (p['fulfilmentType'] as String?) ?? 'pos',
      source: 'pos',
      grandTotalPaise: grandTotal,
      subtotalPaise: (p['basicAmountPaise'] as int?) ?? (p['subtotal_paise'] as int?) ?? grandTotal,
      discountTotalPaise: (p['discountPaise'] as int?) ?? 0,
      gstTotalPaise: (p['gstPaise'] as int?) ?? (p['gst_total_paise'] as int?) ?? 0,
      deliveryChargesPaise: (p['deliveryChargesPaise'] as int?) ?? 0,
      roundOffPaise: (p['roundOffPaise'] as int?) ?? 0,
      address: (p['address'] as String?) ?? '',
      deliveryPincode: (p['pinCode'] as String?) ?? '',
      deliveryLandmark: (p['landmark'] as String?) ?? '',
      specialInstructions: (p['specialInstructions'] as String?) ?? '',
      occasion: (p['occasion'] as String?) ?? '',
      deliverySlot: (p['deliverySlot'] as String?) ?? '',
      cardMessage: (p['cardMessage'] as String?) ?? (p['remarks'] as String?) ?? '',
      scheduledAt: DateTime.tryParse((p['scheduledAt'] ?? p['dateTime'] ?? '').toString()) ?? DateTime.now(),
      isPaid: paid >= grandTotal ? 1 : 0,
      paidAmountPaise: paid,
      rewardPointsEarned: (p['rewardPointsEarned'] as int?) ?? 0,
      rewardPointsRedeemed: (p['rewardPointsRedeemed'] as int?) ?? 0,
      rewardDiscountAmountPaise: (p['rewardDiscountPaise'] as int?) ?? 0,
    );
  }

  static OrderDetailBundle _bundleFromPayload(OrderDetailHeader header, Map<String, dynamic> p) {
    final rawItems = p['items'];
    final lines = (rawItems is List)
        ? rawItems.map((e) => e is Map ? Map<String, Object?>.from(e) : <String, Object?>{}).toList()
        : <Map<String, Object?>>[];

    final rawPayments = p['paymentSummary'] ?? p['payments'];
    final payments = (rawPayments is List)
        ? rawPayments.map((e) => e is Map ? Map<String, Object?>.from(e) : <String, Object?>{}).toList()
        : <Map<String, Object?>>[];

    return OrderDetailBundle(
      header: header,
      lines: lines,
      payments: payments,
      timeline: const [],
      schedulerTasks: const [],
      inventoryTransactions: const [],
      receiptStatus: null,
      whatsappStatus: null,
      relayInfo: const {},
      corporateInfo: const {},
      marketplaceInfo: const {},
    );
  }
}
