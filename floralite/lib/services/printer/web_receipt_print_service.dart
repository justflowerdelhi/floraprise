import '../../managers/business_settings_manager.dart';
import '../../models/printer_models.dart';
import 'web_receipt_printer.dart';

/// Browser-safe receipt printing service for Floraprise Pro Web.
/// Formats receipts and delivery challans into HTML/CSS tailored for
/// 58mm/80mm thermal receipt printers and standard browser print dialogs.
class WebReceiptPrintService {
  WebReceiptPrintService({BusinessSettingsManager? businessSettingsManager})
      : _businessSettingsManager =
            businessSettingsManager ?? BusinessSettingsManager();

  final BusinessSettingsManager _businessSettingsManager;

  /// Builds the complete HTML document for a POS Bill.
  Future<String> buildPosBillHtml(
    Map<String, dynamic> payload, {
    PrinterPaperWidth paperWidth = PrinterPaperWidth.mm80,
  }) async {
    final business = await _businessSettingsManager.load();
    final shopName = business.shopName.trim().isEmpty
        ? 'FLORAPRISE'
        : business.shopName.trim();
    final address = business.address.trim();
    final phone = business.phone.trim();
    final gstin =
        business.gstRegistered ? business.gstNumber.trim() : '';

    final invoiceNumber = _string(payload, 'invoiceNumber', 'order_no');
    final dateTime = _string(payload, 'dateTime', 'printed_at');
    final cashier = _string(payload, 'cashier');
    final customerName = _string(payload, 'customerName', 'customer_name');
    final customerPhone = _string(payload, 'customerPhone', 'customer_phone');

    final items = _list(payload['items']);
    final basicAmountPaise =
        _int(payload, 'basicAmountPaise', 'subtotal_paise');
    final discountPaise =
        _int(payload, 'discountPaise', 'discount_total_paise');
    final gstPaise = _int(payload, 'gstPaise', 'gst_total_paise');
    final roundOffPaise = _int(payload, 'roundOffPaise', 'round_off_paise');
    final grandTotalPaise =
        _int(payload, 'grandTotalPaise', 'grand_total_paise');

    final paymentSummary = _list(payload['paymentSummary']);
    final paidPaise = _int(payload, 'paidPaise');
    final outstandingPaise = _int(payload, 'outstandingPaise');
    final changePaise = _int(payload, 'changePaise', 'change_due_paise');
    final paymentMode = _string(payload, 'paymentMode', 'payment_mode');

    final is58mm = paperWidth == PrinterPaperWidth.mm58;
    final cssWidth = is58mm ? '54mm' : '76mm';
    final pageSize = is58mm ? '58mm auto' : '80mm auto';
    final fontSize = is58mm ? '11px' : '12px';

    final buffer = StringBuffer()
      ..writeln('<!DOCTYPE html>')
      ..writeln('<html>')
      ..writeln('<head>')
      ..writeln('<meta charset="utf-8">')
      ..writeln('<title>Receipt - ${_escapeHtml(invoiceNumber)}</title>')
      ..writeln('<style>')
      ..writeln('@page { size: $pageSize; margin: 2mm; }')
      ..writeln('@media print {')
      ..writeln('  html, body { width: $cssWidth; margin: 0 auto; padding: 1mm; }')
      ..writeln('}')
      ..writeln('body {')
      ..writeln("  font-family: 'Courier New', Courier, monospace;")
      ..writeln('  font-size: $fontSize;')
      ..writeln('  line-height: 1.25;')
      ..writeln('  color: #000;')
      ..writeln('  background: #fff;')
      ..writeln('  width: $cssWidth;')
      ..writeln('  max-width: 100%;')
      ..writeln('  margin: 0 auto;')
      ..writeln('  padding: 4px;')
      ..writeln('}')
      ..writeln('.center { text-align: center; }')
      ..writeln('.right { text-align: right; }')
      ..writeln('.bold { font-weight: bold; }')
      ..writeln('.title { font-size: 15px; font-weight: bold; margin: 2px 0; text-align: center; }')
      ..writeln('.subtitle { font-size: 13px; font-weight: bold; margin: 2px 0; text-align: center; }')
      ..writeln('.sep { border-top: 1px dashed #000; margin: 4px 0; }')
      ..writeln('.double-sep { border-top: 2px dashed #000; margin: 4px 0; }')
      ..writeln('.row { display: flex; justify-content: space-between; margin: 1px 0; }')
      ..writeln('table { width: 100%; border-collapse: collapse; margin: 3px 0; }')
      ..writeln('th { border-bottom: 1px dashed #000; padding: 2px 0; font-size: 11px; text-align: left; }')
      ..writeln('td { padding: 2px 0; font-size: 11px; vertical-align: top; }')
      ..writeln('th.r, td.r { text-align: right; }')
      ..writeln('th.c, td.c { text-align: center; }')
      ..writeln('.grand-total { font-size: 13px; font-weight: bold; margin: 3px 0; }')
      ..writeln('.footer { text-align: center; margin-top: 6px; font-size: 11px; }')
      ..writeln('</style>')
      ..writeln('</head>')
      ..writeln('<body>')
      // Header
      ..writeln('<div class="title">${_escapeHtml(shopName)}</div>');

    if (address.isNotEmpty) {
      buffer.writeln('<div class="center">${_escapeHtml(address)}</div>');
    }
    if (phone.isNotEmpty) {
      buffer.writeln('<div class="center">Phone: ${_escapeHtml(phone)}</div>');
    }
    if (gstin.isNotEmpty) {
      buffer.writeln('<div class="center">GSTIN: ${_escapeHtml(gstin)}</div>');
    }

    buffer
      ..writeln('<div class="sep"></div>')
      ..writeln('<div class="subtitle">POS BILL</div>');

    if (invoiceNumber.isNotEmpty) {
      buffer.writeln('<div class="row"><span>Invoice:</span><span>#${_escapeHtml(invoiceNumber)}</span></div>');
    }
    if (dateTime.isNotEmpty) {
      buffer.writeln('<div class="row"><span>Date:</span><span>${_escapeHtml(dateTime)}</span></div>');
    }
    if (cashier.isNotEmpty) {
      buffer.writeln('<div class="row"><span>Cashier:</span><span>${_escapeHtml(cashier)}</span></div>');
    }
    if (customerName.isNotEmpty) {
      final custDisplay = customerPhone.isNotEmpty
          ? '${_escapeHtml(customerName)} (${_escapeHtml(customerPhone)})'
          : _escapeHtml(customerName);
      buffer.writeln('<div class="row"><span>Customer:</span><span>$custDisplay</span></div>');
    }

    // Line items table
    buffer
      ..writeln('<div class="sep"></div>')
      ..writeln('<table>')
      ..writeln('<thead><tr><th>Item</th><th class="c">Qty</th><th class="r">Rate</th><th class="r">Amt</th></tr></thead>')
      ..writeln('<tbody>');

    for (final item in items) {
      final name = _string(item, 'name', 'product_name');
      final qty = _string(item, 'qty', 'quantity');
      final ratePaise = _int(item, 'ratePaise', 'unit_price_paise');
      final totalPaise = _int(item, 'totalPaise', 'line_total_paise');

      buffer.writeln(
        '<tr>'
        '<td>${_escapeHtml(name)}</td>'
        '<td class="c">${_escapeHtml(qty)}</td>'
        '<td class="r">${_money(ratePaise)}</td>'
        '<td class="r">${_money(totalPaise)}</td>'
        '</tr>',
      );
    }

    buffer
      ..writeln('</tbody>')
      ..writeln('</table>')
      ..writeln('<div class="sep"></div>');

    // Totals
    if (basicAmountPaise > 0) {
      buffer.writeln('<div class="row"><span>Basic Amount:</span><span>${_money(basicAmountPaise)}</span></div>');
    }
    if (discountPaise > 0) {
      buffer.writeln('<div class="row"><span>Discount:</span><span>-${_money(discountPaise)}</span></div>');
    }
    if (gstPaise > 0) {
      buffer.writeln('<div class="row"><span>GST Amount:</span><span>${_money(gstPaise)}</span></div>');
    }
    if (roundOffPaise != 0) {
      final sign = roundOffPaise > 0 ? '+' : '';
      buffer.writeln('<div class="row"><span>Round Off:</span><span>$sign${_money(roundOffPaise)}</span></div>');
    }

    buffer.writeln(
      '<div class="row grand-total bold">'
      '<span>Grand Total:</span>'
      '<span>${_money(grandTotalPaise)}</span>'
      '</div>',
    );

    // Payment Summary
    if (paymentSummary.isNotEmpty) {
      buffer
        ..writeln('<div class="sep"></div>')
        ..writeln('<div class="bold">Payment Summary:</div>');
      for (final p in paymentSummary) {
        final method = _string(p, 'method');
        final amount = _int(p, 'amountPaise');
        buffer.writeln('<div class="row"><span>${_escapeHtml(method)}:</span><span>${_money(amount)}</span></div>');
      }
      if (paidPaise > 0) {
        buffer.writeln('<div class="row"><span>Paid:</span><span>${_money(paidPaise)}</span></div>');
      }
      if (changePaise > 0) {
        buffer.writeln('<div class="row"><span>Change:</span><span>${_money(changePaise)}</span></div>');
      }
      if (outstandingPaise > 0) {
        buffer.writeln('<div class="row bold"><span>Outstanding:</span><span>${_money(outstandingPaise)}</span></div>');
      }
    } else if (paymentMode.isNotEmpty) {
      buffer.writeln('<div class="row"><span>Payment:</span><span>${_escapeHtml(paymentMode)}</span></div>');
    }

    // Rewards
    final earnedPoints = _int(payload, 'rewardPointsEarned');
    final redeemedPoints = _int(payload, 'rewardPointsRedeemed');
    final closingBalance = _int(payload, 'rewardClosingBalance');
    if (earnedPoints > 0 || redeemedPoints > 0 || closingBalance > 0) {
      buffer
        ..writeln('<div class="sep"></div>')
        ..writeln('<div class="bold">Loyalty Rewards:</div>');
      if (earnedPoints > 0) {
        buffer.writeln('<div class="row"><span>Points Earned:</span><span>+$earnedPoints</span></div>');
      }
      if (redeemedPoints > 0) {
        buffer.writeln('<div class="row"><span>Points Redeemed:</span><span>-$redeemedPoints</span></div>');
      }
      if (closingBalance > 0) {
        buffer.writeln('<div class="row"><span>Closing Balance:</span><span>$closingBalance pts</span></div>');
      }
    }

    // Footer
    buffer
      ..writeln('<div class="double-sep"></div>')
      ..writeln('<div class="footer">Thank you for shopping with us!</div>')
      ..writeln('</body>')
      ..writeln('</html>');

    return buffer.toString();
  }

  /// Builds the complete HTML document for a Delivery Challan.
  Future<String> buildDeliverySlipHtml(
    Map<String, dynamic> payload, {
    PrinterPaperWidth paperWidth = PrinterPaperWidth.mm80,
  }) async {
    final business = await _businessSettingsManager.load();
    final shopName = business.shopName.trim().isEmpty
        ? 'FLORAPRISE'
        : business.shopName.trim();
    final address = business.address.trim();
    final phone = business.phone.trim();
    final gstin =
        business.gstRegistered ? business.gstNumber.trim() : '';

    final orderNo = _string(payload, 'orderNo', 'order_no');
    final deliveryTime = _string(payload, 'deliveryTime', 'delivery_time');
    final recipientName = _string(payload, 'recipientName', 'customer');
    final recipientPhone = _string(payload, 'recipientPhone', 'phone');
    final deliveryAddress = _string(payload, 'address', 'delivery_address');
    final landmark = _string(payload, 'landmark');
    final pinCode = _string(payload, 'pinCode', 'pincode');
    final senderName = _string(payload, 'senderName', 'customerName');
    final senderPhone = _string(payload, 'senderPhone', 'customerPhone');
    final instructions =
        _string(payload, 'deliveryInstructions', 'instructions');
    final items = _list(payload['items']);

    final is58mm = paperWidth == PrinterPaperWidth.mm58;
    final cssWidth = is58mm ? '54mm' : '76mm';
    final pageSize = is58mm ? '58mm auto' : '80mm auto';
    final fontSize = is58mm ? '11px' : '12px';

    final buffer = StringBuffer()
      ..writeln('<!DOCTYPE html>')
      ..writeln('<html>')
      ..writeln('<head>')
      ..writeln('<meta charset="utf-8">')
      ..writeln('<title>Delivery Challan - ${_escapeHtml(orderNo)}</title>')
      ..writeln('<style>')
      ..writeln('@page { size: $pageSize; margin: 2mm; }')
      ..writeln('@media print {')
      ..writeln('  html, body { width: $cssWidth; margin: 0 auto; padding: 1mm; }')
      ..writeln('}')
      ..writeln('body {')
      ..writeln("  font-family: 'Courier New', Courier, monospace;")
      ..writeln('  font-size: $fontSize;')
      ..writeln('  line-height: 1.25;')
      ..writeln('  color: #000;')
      ..writeln('  background: #fff;')
      ..writeln('  width: $cssWidth;')
      ..writeln('  max-width: 100%;')
      ..writeln('  margin: 0 auto;')
      ..writeln('  padding: 4px;')
      ..writeln('}')
      ..writeln('.center { text-align: center; }')
      ..writeln('.bold { font-weight: bold; }')
      ..writeln('.title { font-size: 15px; font-weight: bold; margin: 2px 0; text-align: center; }')
      ..writeln('.subtitle { font-size: 13px; font-weight: bold; margin: 2px 0; text-align: center; }')
      ..writeln('.sep { border-top: 1px dashed #000; margin: 4px 0; }')
      ..writeln('.double-sep { border-top: 2px dashed #000; margin: 4px 0; }')
      ..writeln('.row { display: flex; justify-content: space-between; margin: 1px 0; }')
      ..writeln('.section-header { font-weight: bold; margin-top: 4px; margin-bottom: 2px; }')
      ..writeln('table { width: 100%; border-collapse: collapse; margin: 3px 0; }')
      ..writeln('th { border-bottom: 1px dashed #000; padding: 2px 0; font-size: 11px; text-align: left; }')
      ..writeln('td { padding: 2px 0; font-size: 11px; }')
      ..writeln('th.c, td.c { text-align: center; }')
      ..writeln('.footer { text-align: center; margin-top: 8px; font-size: 11px; }')
      ..writeln('</style>')
      ..writeln('</head>')
      ..writeln('<body>')
      ..writeln('<div class="title">${_escapeHtml(shopName)}</div>');

    if (address.isNotEmpty) {
      buffer.writeln('<div class="center">${_escapeHtml(address)}</div>');
    }
    if (phone.isNotEmpty) {
      buffer.writeln('<div class="center">Phone: ${_escapeHtml(phone)}</div>');
    }
    if (gstin.isNotEmpty) {
      buffer.writeln('<div class="center">GSTIN: ${_escapeHtml(gstin)}</div>');
    }

    buffer
      ..writeln('<div class="double-sep"></div>')
      ..writeln('<div class="subtitle">DELIVERY CHALLAN</div>')
      ..writeln('<div class="double-sep"></div>')
      ..writeln('<div class="row"><span>Order No:</span><span>#${_escapeHtml(orderNo)}</span></div>');

    if (deliveryTime.isNotEmpty) {
      buffer.writeln('<div class="row"><span>Scheduled:</span><span>${_escapeHtml(deliveryTime)}</span></div>');
    }

    buffer
      ..writeln('<div class="sep"></div>')
      ..writeln('<div class="section-header">RECIPIENT:</div>')
      ..writeln('<div class="row"><span>Name:</span><span>${_escapeHtml(recipientName)}</span></div>');

    if (recipientPhone.isNotEmpty) {
      buffer.writeln('<div class="row"><span>Mobile:</span><span>${_escapeHtml(recipientPhone)}</span></div>');
    }
    if (deliveryAddress.isNotEmpty) {
      buffer.writeln('<div>Address: ${_escapeHtml(deliveryAddress)}</div>');
    }
    if (landmark.isNotEmpty) {
      buffer.writeln('<div>Landmark: ${_escapeHtml(landmark)}</div>');
    }
    if (pinCode.isNotEmpty) {
      buffer.writeln('<div>PIN: ${_escapeHtml(pinCode)}</div>');
    }

    if (senderName.isNotEmpty || senderPhone.isNotEmpty) {
      buffer
        ..writeln('<div class="sep"></div>')
        ..writeln('<div class="section-header">SENDER:</div>');
      if (senderName.isNotEmpty) {
        buffer.writeln('<div class="row"><span>Name:</span><span>${_escapeHtml(senderName)}</span></div>');
      }
      if (senderPhone.isNotEmpty) {
        buffer.writeln('<div class="row"><span>Mobile:</span><span>${_escapeHtml(senderPhone)}</span></div>');
      }
    }

    if (instructions.isNotEmpty) {
      buffer
        ..writeln('<div class="sep"></div>')
        ..writeln('<div class="section-header">INSTRUCTIONS:</div>')
        ..writeln('<div>${_escapeHtml(instructions)}</div>');
    }

    // Product Checklist
    buffer
      ..writeln('<div class="sep"></div>')
      ..writeln('<div class="section-header">PRODUCT CHECKLIST:</div>')
      ..writeln('<table>')
      ..writeln('<thead><tr><th>[ ] Item</th><th class="c">Qty</th></tr></thead>')
      ..writeln('<tbody>');

    if (items.isEmpty) {
      buffer.writeln('<tr><td>[ ] Arrangement checked</td><td class="c">1</td></tr>');
    } else {
      for (final item in items) {
        final name = _string(item, 'name', 'product_name');
        final qty = _string(item, 'qty', 'quantity');
        buffer.writeln(
          '<tr>'
          '<td>[ ] ${_escapeHtml(name)}</td>'
          '<td class="c">${_escapeHtml(qty)}</td>'
          '</tr>',
        );
      }
    }

    buffer
      ..writeln('</tbody>')
      ..writeln('</table>')
      ..writeln('<div class="double-sep"></div>')
      ..writeln('<div class="footer">Please inspect items upon delivery.</div>')
      ..writeln('</body>')
      ..writeln('</html>');

    return buffer.toString();
  }

  /// Sends a POS Bill to the browser print dialog.
  Future<void> printPosBill(
    Map<String, dynamic> payload, {
    PrinterPaperWidth paperWidth = PrinterPaperWidth.mm80,
  }) async {
    final html = await buildPosBillHtml(payload, paperWidth: paperWidth);
    await printHtmlReceipt(html);
  }

  /// Sends a Delivery Challan to the browser print dialog.
  Future<void> printDeliverySlip(
    Map<String, dynamic> payload, {
    PrinterPaperWidth paperWidth = PrinterPaperWidth.mm80,
  }) async {
    final html = await buildDeliverySlipHtml(payload, paperWidth: paperWidth);
    await printHtmlReceipt(html);
  }

  static String _string(
    Map<String, dynamic> map,
    String key, [
    String? fallbackKey,
  ]) {
    final value = map[key] ?? (fallbackKey != null ? map[fallbackKey] : null);
    return value?.toString().trim() ?? '';
  }

  static int _int(
    Map<String, dynamic> map,
    String key, [
    String? fallbackKey,
  ]) {
    final value = map[key] ?? (fallbackKey != null ? map[fallbackKey] : null);
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static List<Map<String, dynamic>> _list(dynamic value) {
    if (value is List) {
      return value.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    return const [];
  }

  static String _money(int paise) {
    return '₹${(paise / 100).toStringAsFixed(2)}';
  }

  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}
