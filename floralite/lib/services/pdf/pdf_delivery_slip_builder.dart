import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../managers/business_settings_manager.dart';
import '../../models/order_workspace_models.dart';

/// Builds clean, delivery-oriented A4 Delivery Challan / Slip PDF documents.
class PdfDeliverySlipBuilder {
  const PdfDeliverySlipBuilder();

  /// Builds Delivery Slip PDF from strongly-typed order models.
  Future<Uint8List> build({
    required BusinessSettings business,
    required OrderDetailHeader header,
    OrderDetailBundle? bundle,
  }) async {
    final doc = pw.Document();

    final shopName = business.shopName.trim().isEmpty ? 'FLORAPRISE' : business.shopName.trim();
    final shopAddress = business.address.trim();
    final shopPhone = business.phone.trim();

    final orderNo = header.displayOrderNo;
    final scheduledDate = header.scheduledAt != null
        ? DateFormat('dd-MM-yyyy').format(header.scheduledAt!)
        : (header.createdAt != null
            ? DateFormat('dd-MM-yyyy').format(header.createdAt!)
            : DateFormat('dd-MM-yyyy').format(DateTime.now()));
    final deliveryTimeSlot = header.deliverySlot.isNotEmpty
        ? header.deliverySlot
        : (header.scheduledAt != null
            ? DateFormat('HH:mm').format(header.scheduledAt!)
            : 'Standard Delivery');

    final lines = bundle?.lines ?? const <Map<String, Object?>>[];

    final primaryColor = PdfColor.fromHex('#0F3822');
    final accentBg = PdfColor.fromHex('#F4F9F6');
    final borderColor = PdfColor.fromHex('#C8DBD0');
    final darkGrey = PdfColor.fromHex('#222222');
    final lightGrey = PdfColor.fromHex('#555555');

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
                          fontSize: 18,
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
                        'DELIVERY CHALLAN',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Order No: $orderNo',
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Date: $scheduledDate',
                      style: pw.TextStyle(fontSize: 9, color: lightGrey),
                    ),
                    pw.Text(
                      'Slot: $deliveryTimeSlot',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: primaryColor),
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
                  'Please inspect items upon delivery. | Floraprise Delivery System',
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
          // Prominent Recipient & Delivery Box
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: accentBg,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: primaryColor, width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'DELIVERY DESTINATION / RECIPIENT:',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    if (header.deliveryName != null && header.deliveryName!.isNotEmpty)
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: pw.BoxDecoration(
                          color: primaryColor,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                        ),
                        child: pw.Text(
                          'Driver: ${header.deliveryName!}',
                          style: pw.TextStyle(color: PdfColors.white, fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 6,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            header.recipientName.isNotEmpty ? header.recipientName : header.customerName,
                            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: darkGrey),
                          ),
                          if (header.recipientPhone.isNotEmpty || header.customerPhone.isNotEmpty)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(top: 2),
                              child: pw.Text(
                                'Mobile: ${header.recipientPhone.isNotEmpty ? header.recipientPhone : header.customerPhone}',
                                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Address: ${header.address.isNotEmpty ? header.address : "(No address specified)"}',
                            style: pw.TextStyle(fontSize: 10, color: darkGrey),
                          ),
                          if (header.deliveryLandmark.isNotEmpty)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(top: 2),
                              child: pw.Text(
                                'Landmark: ${header.deliveryLandmark}',
                                style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: primaryColor),
                              ),
                            ),
                          if (header.deliveryPincode.isNotEmpty)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(top: 1),
                              child: pw.Text(
                                'Pincode: ${header.deliveryPincode}',
                                style: const pw.TextStyle(fontSize: 9.5),
                              ),
                            ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 16),
                    // Sender info
                    pw.Expanded(
                      flex: 4,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                          border: pw.Border.all(color: borderColor, width: 0.5),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'SENDER DETAILS:',
                              style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: lightGrey),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              header.customerName.isNotEmpty ? header.customerName : 'Sender',
                              style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
                            ),
                            if (header.customerPhone.isNotEmpty)
                              pw.Text(
                                'Phone: ${header.customerPhone}',
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                            if (header.occasion.isNotEmpty)
                              pw.Text(
                                'Occasion: ${header.occasion}',
                                style: pw.TextStyle(fontSize: 8.5, color: lightGrey),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 10),

          // Instructions & Message Card
          if (header.specialInstructions.trim().isNotEmpty || header.cardMessage.trim().isNotEmpty) ...[
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (header.specialInstructions.trim().isNotEmpty)
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#FFF8E7'),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        border: pw.Border.all(color: PdfColor.fromHex('#EAD295'), width: 0.5),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'SPECIAL INSTRUCTIONS:',
                            style: pw.TextStyle(
                              fontSize: 7.5,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('#7A5005'),
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            header.specialInstructions,
                            style: const pw.TextStyle(fontSize: 8.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (header.specialInstructions.trim().isNotEmpty && header.cardMessage.trim().isNotEmpty)
                  pw.SizedBox(width: 8),
                if (header.cardMessage.trim().isNotEmpty)
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#FDF2F4'),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        border: pw.Border.all(color: PdfColor.fromHex('#E8BAC4'), width: 0.5),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'MESSAGE CARD INCLUDED:',
                            style: pw.TextStyle(
                              fontSize: 7.5,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('#7A1D2E'),
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
                  ),
              ],
            ),
            pw.SizedBox(height: 10),
          ],

          // Product Checklist Table
          pw.Text(
            'PRODUCT CHECKLIST / ITEMS TO DELIVER:',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Table(
            border: pw.TableBorder.all(color: borderColor, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(40),
              1: const pw.FlexColumnWidth(5),
              2: const pw.FixedColumnWidth(40),
              3: const pw.FlexColumnWidth(3),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColor.fromHex('#EBF3EE')),
                children: [
                  _cell('[ X ]', isHeader: true, align: pw.TextAlign.center),
                  _cell('Item / Arrangement', isHeader: true),
                  _cell('Qty', isHeader: true, align: pw.TextAlign.center),
                  _cell('Notes / Instructions', isHeader: true),
                ],
              ),
              if (lines.isEmpty)
                pw.TableRow(
                  children: [
                    _cell('[   ]', align: pw.TextAlign.center),
                    _cell('Floral Arrangement / Bouquet'),
                    _cell('1', align: pw.TextAlign.center),
                    _cell('Standard packaging'),
                  ],
                )
              else
                for (int i = 0; i < lines.length; i++) ...[
                  _buildChecklistRow(lines[i]),
                ],
            ],
          ),
          pw.SizedBox(height: 20),

          // Sign-off / Handover Section
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: borderColor, width: 0.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'DISPATCHED / DELIVERED BY:',
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: lightGrey),
                      ),
                      pw.SizedBox(height: 20),
                      pw.Text(
                        'Driver Name: ${header.deliveryName?.isNotEmpty == true ? header.deliveryName! : "_________________"}',
                        style: const pw.TextStyle(fontSize: 8.5),
                      ),
                      pw.Text('Signature: ______________________', style: const pw.TextStyle(fontSize: 8.5)),
                    ],
                  ),
                ),
                pw.Container(width: 0.5, height: 50, color: borderColor),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'RECEIVED BY (CUSTOMER / RECIPIENT):',
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: lightGrey),
                      ),
                      pw.SizedBox(height: 20),
                      pw.Text('Receiver Name: _________________', style: const pw.TextStyle(fontSize: 8.5)),
                      pw.Text('Date & Time: ___________________', style: const pw.TextStyle(fontSize: 8.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  /// Builds Delivery Slip PDF from payload map (reusable for POS flows).
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

  static pw.TableRow _buildChecklistRow(Map<String, Object?> line) {
    final productName = (line['product_name'] as String?)?.trim() ??
        (line['name'] as String?)?.trim() ??
        'Item';
    final lineDesc = (line['description'] as String?)?.trim();
    final qty = (line['quantity'] as int?) ?? (line['qty'] as int?) ?? 1;

    return pw.TableRow(
      children: [
        _cell('[   ]', align: pw.TextAlign.center),
        _cell(productName),
        _cell('$qty', align: pw.TextAlign.center),
        _cell(lineDesc ?? '-'),
      ],
    );
  }

  static OrderDetailHeader _headerFromPayload(Map<String, dynamic> p) {
    return OrderDetailHeader(
      id: (p['order_id'] as int?) ?? 0,
      orderNo: (p['order_no'] as String?) ?? (p['orderNo'] as String?) ?? 'DEL-SLIP',
      status: (p['status'] as String?) ?? 'ready',
      customerName: (p['customer'] as String?) ?? (p['senderName'] as String?) ?? (p['customerName'] as String?) ?? 'Customer',
      customerPhone: (p['phone'] as String?) ?? (p['senderPhone'] as String?) ?? (p['customerPhone'] as String?) ?? '',
      recipientName: (p['recipientName'] as String?) ?? (p['customer'] as String?) ?? '',
      recipientPhone: (p['recipientPhone'] as String?) ?? (p['phone'] as String?) ?? '',
      fulfilmentType: 'delivery',
      source: 'pos',
      grandTotalPaise: (p['grandTotalPaise'] as int?) ?? 0,
      subtotalPaise: (p['subtotalPaise'] as int?) ?? 0,
      discountTotalPaise: 0,
      gstTotalPaise: 0,
      deliveryChargesPaise: 0,
      roundOffPaise: 0,
      address: (p['address'] as String?) ?? '',
      deliveryPincode: (p['pinCode'] as String?) ?? '',
      deliveryLandmark: (p['landmark'] as String?) ?? '',
      deliveryName: (p['driverName'] as String?) ?? '',
      specialInstructions: (p['deliveryInstructions'] as String?) ?? '',
      occasion: (p['occasion'] as String?) ?? '',
      deliverySlot: (p['deliveryTime'] as String?) ?? '',
      cardMessage: (p['remarks'] as String?) ?? (p['cardMessage'] as String?) ?? '',
      scheduledAt: DateTime.tryParse((p['scheduledAt'] ?? p['deliveryTime'] ?? '').toString()) ?? DateTime.now(),
      isPaid: 1,
      paidAmountPaise: 0,
    );
  }

  static OrderDetailBundle _bundleFromPayload(OrderDetailHeader header, Map<String, dynamic> p) {
    final rawItems = p['items'];
    final lines = (rawItems is List)
        ? rawItems.map((e) => e is Map ? Map<String, Object?>.from(e) : <String, Object?>{}).toList()
        : <Map<String, Object?>>[];

    return OrderDetailBundle(
      header: header,
      lines: lines,
      payments: const [],
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
