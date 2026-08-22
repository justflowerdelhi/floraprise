import 'dart:typed_data';

import '../../managers/business_settings_manager.dart';
import '../../models/printer_models.dart';
import 'escpos_builder.dart';

class ReceiptBuilder {
  ReceiptBuilder({BusinessSettingsManager? businessSettingsManager})
      : _businessSettingsManager =
            businessSettingsManager ?? BusinessSettingsManager();

  final BusinessSettingsManager _businessSettingsManager;

  Future<Uint8List> build({
    required PrintJobType type,
    required Map<String, dynamic> payload,
    required PrinterConfig settings,
  }) async {
    final builder = EscPosBuilder(paperWidth: settings.paperWidth)..reset();
    switch (type) {
      case PrintJobType.posBill:
        await _posBill(builder, payload, settings);
      case PrintJobType.deliverySlip:
        await _deliverySlip(builder, payload, settings);
      case PrintJobType.messageCard:
        _messageCard(builder, payload, settings);
      case PrintJobType.productionSlip:
        await _productionSlip(builder, payload, settings);
      case PrintJobType.bouquetBarcodeLabel:
        _barcodeLabel(builder, payload, settings);
      case PrintJobType.expenseReceipt:
        await _expenseReceipt(builder, payload, settings);
      case PrintJobType.dayCloseReport:
        await _dayCloseReport(builder, payload, settings);
      case PrintJobType.testPage:
        await _testPage(builder, payload, settings);
    }
    builder.feed(2);
    if (settings.cutPaper) builder.cut();
    return builder.bytes();
  }

  Future<void> _header(EscPosBuilder builder, PrinterConfig settings) async {
    final business = await _businessSettingsManager.load();
    builder.text(
      business.shopName.trim().isEmpty ? 'FLORAPRISE' : business.shopName,
      align: EscPosAlign.center,
      bold: true,
      doubleWidth: true,
      doubleHeight: true,
    );
    if (business.address.trim().isNotEmpty) {
      builder.text(business.address, align: EscPosAlign.center);
    }
    if (business.phone.trim().isNotEmpty) {
      builder.text('Phone: ${business.phone}', align: EscPosAlign.center);
    }
    if (business.gstRegistered && business.gstNumber.trim().isNotEmpty) {
      builder.text('GSTIN: ${business.gstNumber}', align: EscPosAlign.center);
    }
    builder.separator();
  }

  Future<void> _posBill(
    EscPosBuilder builder,
    Map<String, dynamic> payload,
    PrinterConfig settings,
  ) async {
    await _header(builder, settings);
    builder.text('POS BILL', align: EscPosAlign.center, bold: true);
    builder.row('Invoice', _string(payload, 'invoiceNumber', 'order_no'));
    builder.row('Date', _string(payload, 'dateTime', 'printed_at'));
    builder.row('Cashier', _string(payload, 'cashier'));
    builder.row('Customer', _string(payload, 'customerName', 'customer_name'));
    builder.separator();
    final widths = settings.paperWidth == PrinterPaperWidth.mm58
        ? const [14, 4, 6, 8]
        : const [24, 5, 8, 11];
    builder.columns(const ['Item', 'Qty', 'Rate', 'Amt'], widths, bold: true);
    for (final item in _list(payload['items'])) {
      builder.columns([
        _string(item, 'name', 'product_name'),
        _string(item, 'qty', 'quantity'),
        _money(_int(item, 'ratePaise', 'unit_price_paise')),
        _money(_int(item, 'totalPaise', 'line_total_paise')),
      ], widths);
    }
    builder.separator();
    builder.row('Basic Amount',
        _money(_int(payload, 'basicAmountPaise', 'subtotal_paise')));
    builder.row('Discount',
        _money(_int(payload, 'discountPaise', 'discount_total_paise')));
    builder.row(
        'GST Amount', _money(_int(payload, 'gstPaise', 'gst_total_paise')));
    builder.row('Grand Total',
        _money(_int(payload, 'grandTotalPaise', 'grand_total_paise')),
        bold: true);
    final paymentSummary = _list(payload['paymentSummary']);
    if (paymentSummary.isNotEmpty) {
      builder.separator();
      builder.text('Payment Summary', bold: true);
      for (final row in paymentSummary) {
        final method = _string(row, 'method');
        final amount = _int(row, 'amountPaise');
        builder.row(method, _money(amount));
      }
      builder.row('Paid', _money(_int(payload, 'paidPaise')));
      builder.row('Outstanding', _money(_int(payload, 'outstandingPaise')));
    } else {
      builder.row('Payment', _string(payload, 'paymentMode', 'payment_mode'));
    }
    if (settings.printBarcode &&
        _string(payload, 'invoiceNumber', 'order_no').isNotEmpty) {
      builder.barcode(_string(payload, 'invoiceNumber', 'order_no'));
    }
    if (settings.printQrCode && _string(payload, 'qrData').isNotEmpty) {
      builder.qrCode(_string(payload, 'qrData'));
    }
    _footer(builder, settings);
  }

  Future<void> _deliverySlip(
    EscPosBuilder builder,
    Map<String, dynamic> payload,
    PrinterConfig settings,
  ) async {
    final business = await _businessSettingsManager.load();
    _shopHeader(
      builder,
      business.shopName,
      business.address,
      business.phone,
      gstNumber: business.gstRegistered ? business.gstNumber : '',
    );
    builder.separator('=');
    builder.text('DELIVERY CHALLAN', align: EscPosAlign.center, bold: true);
    builder.separator('=');
    _labelValue(builder, 'Order No', _string(payload, 'orderNo', 'order_no'));
    _labelValue(builder, 'Date', _deliveryDate(payload));
    _labelValue(builder, 'Time', _deliveryTime(payload));

    builder.feed();
    _labelValue(
        builder, 'Recipient', _string(payload, 'recipientName', 'customer'));
    _labelValue(builder, 'Mobile', _string(payload, 'recipientPhone', 'phone'));
    _labelValue(builder, 'Address', _deliveryAddress(payload));
    _labelValue(builder, 'Landmark', _string(payload, 'landmark'));

    builder.feed();
    _labelValue(
        builder, 'Sender', _string(payload, 'senderName', 'customerName'));
    _labelValue(
        builder, 'Mobile', _string(payload, 'senderPhone', 'customerPhone'));

    final instructions =
        _string(payload, 'deliveryInstructions', 'instructions');
    if (instructions.isNotEmpty) {
      builder.feed();
      for (final line in _splitInstructions(instructions)) {
        _labelValue(builder, 'Instructions', line);
      }
    }

    _section(builder, 'PRODUCT CHECKLIST', separator: '=');
    final items = _list(payload['items']);
    if (items.isEmpty) {
      builder.text('[ ] Arrangement checked');
    } else {
      for (final item in items) {
        final quantity = _string(item, 'qty', 'quantity');
        final suffix =
            quantity.isEmpty || quantity == '1' ? '' : ' x $quantity';
        builder.text('[ ] ${_itemName(item)}$suffix');
      }
    }
    if (_bool(payload, 'messageCardIncluded')) {
      builder.text('[ ] Message Card Included');
    }

    _section(builder, 'PROOF OF DELIVERY', separator: '=');
    _signatureLine(builder, 'Receiver Name');
    _signatureLine(builder, 'Receiver Mobile');
    _signatureLine(builder, 'Signature');
    _signatureLine(builder, 'Date');
    _signatureLine(builder, 'Time');
    _signatureLine(builder, 'Delivered By');

    builder.separator();
    builder.text('Thank You', align: EscPosAlign.center);
    builder.text(
      business.shopName.trim().isEmpty ? 'FLORAPRISE' : business.shopName,
      align: EscPosAlign.center,
      bold: true,
    );
    if (business.phone.trim().isNotEmpty) {
      builder.text(business.phone, align: EscPosAlign.center);
    }
  }

  void _messageCard(
    EscPosBuilder builder,
    Map<String, dynamic> payload,
    PrinterConfig settings,
  ) {
    final theme = MessageCardTheme.fromPayload(
      _string(payload, 'theme', 'borderStyle'),
      _string(payload, 'occasion'),
    );
    final recipient = _string(payload, 'recipient');
    final message = _string(payload, 'message');
    final sender = _string(payload, 'sender', 'from');

    builder.separator(theme.borderChar);
    builder.text('Message For You', align: EscPosAlign.center, bold: true);
    builder.separator(theme.borderChar);
    builder.feed();

    if (recipient.isNotEmpty && recipient != '-') {
      builder.text(
        'Dear $recipient,',
        align: EscPosAlign.center,
        doubleWidth: true,
        doubleHeight: true,
        maxChars: _largeTextWidth(builder),
      );
      builder.feed();
    }

    if (message.isEmpty) {
      builder.text(
        'With best wishes',
        align: EscPosAlign.center,
        doubleWidth: true,
        doubleHeight: true,
        maxChars: _largeTextWidth(builder),
      );
    } else {
      for (final paragraph in message.split(RegExp(r'\n+'))) {
        if (paragraph.trim().isEmpty) continue;
        builder.text(
          paragraph.trim(),
          align: EscPosAlign.center,
          doubleWidth: true,
          doubleHeight: true,
          maxChars: _largeTextWidth(builder),
        );
        builder.feed();
      }
    }

    if (sender.isNotEmpty && sender != '-') {
      builder.text(sender, align: EscPosAlign.center, bold: true);
      builder.feed();
    }
    final footer = _string(payload, 'footer');
    if (footer.isNotEmpty) {
      builder.text(footer, align: EscPosAlign.center);
    }
    builder.separator(theme.borderChar);
  }

  Future<void> _productionSlip(
    EscPosBuilder builder,
    Map<String, dynamic> payload,
    PrinterConfig settings,
  ) async {
    await _header(builder, settings);
    builder.text('PRODUCTION SLIP', align: EscPosAlign.center, bold: true);
    builder.row('Recipe', _string(payload, 'recipe', 'productName'));
    builder.row('Quantity', _string(payload, 'quantity'));
    builder.row('Date', _string(payload, 'productionDate', 'producedAt'));
    builder.row('Batch', _string(payload, 'batchNumber', 'productionNumber'));
    builder.row('Produced By', _string(payload, 'producedBy', 'operatorName'));
  }

  void _barcodeLabel(
    EscPosBuilder builder,
    Map<String, dynamic> payload,
    PrinterConfig settings,
  ) {
    final copies = _int(payload, 'quantity').clamp(1, 99);
    final barcode = _string(payload, 'barcode');
    final pricePaise = _int(payload, 'pricePaise', 'sellingPricePaise');
    for (var copy = 0; copy < copies; copy++) {
      builder.text(_string(payload, 'productName'),
          align: EscPosAlign.center, bold: true);
      if (barcode.isNotEmpty && settings.printBarcode) builder.barcode(barcode);
      if (barcode.isNotEmpty) {
        builder.text(barcode, align: EscPosAlign.center);
      }
      if (pricePaise > 0) {
        builder.text('MRP ${_money(pricePaise)}',
            align: EscPosAlign.center, bold: true);
      }
      if (copy < copies - 1) builder.feed(2);
    }
  }

  Future<void> _expenseReceipt(
    EscPosBuilder builder,
    Map<String, dynamic> payload,
    PrinterConfig settings,
  ) async {
    await _header(builder, settings);
    builder.text('EXPENSE VOUCHER', align: EscPosAlign.center, bold: true);
    builder.row('Category', _string(payload, 'category'));
    builder.row('Amount', _money(_int(payload, 'amountPaise')));
    builder.row('Date', _string(payload, 'date'));
    builder.row('User', _string(payload, 'user'));
  }

  Future<void> _dayCloseReport(
    EscPosBuilder builder,
    Map<String, dynamic> payload,
    PrinterConfig settings,
  ) async {
    await _header(builder, settings);
    builder.text('DAY CLOSE REPORT', align: EscPosAlign.center, bold: true);
    builder.row('Sales', _money(_int(payload, 'salesPaise')));
    builder.row('Cash', _money(_int(payload, 'cashPaise')));
    builder.row('UPI', _money(_int(payload, 'upiPaise')));
    builder.row('Card', _money(_int(payload, 'cardPaise')));
    builder.row('Credit', _money(_int(payload, 'creditPaise')));
    builder.row('Expenses', _money(_int(payload, 'expensesPaise')));
    builder.row('Refunds', _money(_int(payload, 'refundsPaise')));
    builder.separator();
    builder.row('Net Collection', _money(_int(payload, 'netCollectionPaise')),
        bold: true);
  }

  Future<void> _testPage(
    EscPosBuilder builder,
    Map<String, dynamic> payload,
    PrinterConfig settings,
  ) async {
    builder.text('FLORAPRISE',
        align: EscPosAlign.center,
        bold: true,
        doubleWidth: true,
        doubleHeight: true);
    builder.feed();
    builder.text('Printer Test', align: EscPosAlign.center, bold: true);
    builder.feed();
    builder.row('Printer:', settings.printerName ?? 'POSIFLOW BT80');
    builder.text('Bluetooth OK', align: EscPosAlign.center, bold: true);
    builder.row('Paper Width',
        settings.paperWidth == PrinterPaperWidth.mm58 ? '58 mm' : '80 mm');
    builder.separator();
    builder.text('Barcode Test', align: EscPosAlign.center, bold: true);
    builder.barcode('123456789012');
    builder.text('QR Code Test', align: EscPosAlign.center, bold: true);
    builder.qrCode('FLORAPRISE PRINTER READY');
    builder.feed();
    builder.text('SUCCESS',
        align: EscPosAlign.center, bold: true, doubleWidth: true);
  }

  void _footer(EscPosBuilder builder, PrinterConfig settings) {
    builder.separator();
    if (settings.thankYouMessage.trim().isNotEmpty) {
      builder.text(settings.thankYouMessage, align: EscPosAlign.center);
    }
    if ((settings.website ?? '').trim().isNotEmpty) {
      builder.text(settings.website!, align: EscPosAlign.center);
    }
    if ((settings.whatsappNumber ?? '').trim().isNotEmpty) {
      builder.text('WhatsApp: ${settings.whatsappNumber}',
          align: EscPosAlign.center);
    }
  }

  String _money(int paise) => 'Rs ${(paise / 100).toStringAsFixed(2)}';

  void _shopHeader(
      EscPosBuilder builder, String shopName, String address, String phone,
      {String gstNumber = ''}) {
    builder.text(
      shopName.trim().isEmpty ? 'FLORAPRISE' : shopName,
      align: EscPosAlign.center,
      bold: true,
      doubleWidth: true,
      doubleHeight: true,
    );
    if (address.trim().isNotEmpty) {
      builder.text(address, align: EscPosAlign.center);
    }
    if (phone.trim().isNotEmpty) {
      builder.text('Phone: $phone', align: EscPosAlign.center);
    }
    if (gstNumber.trim().isNotEmpty) {
      builder.text('GSTIN: $gstNumber', align: EscPosAlign.center);
    }
    builder.separator();
  }

  void _section(EscPosBuilder builder, String title, {String separator = '-'}) {
    builder.feed();
    builder.separator(separator);
    builder.text(title, bold: true);
    builder.separator(separator);
  }

  void _signatureLine(EscPosBuilder builder, String label) {
    builder.feed();
    builder.text(label);
    builder.text('_' * (builder.charsPerLine - 4), align: EscPosAlign.center);
  }

  String _deliveryDate(Map<String, dynamic> payload) {
    final raw = _string(payload, 'deliveryTime', 'scheduled_at');
    if (raw.isEmpty) return DateTime.now().toString().split(' ').first;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return '${parsed.day.toString().padLeft(2, '0')}-'
        '${_monthName(parsed.month)}-${parsed.year}';
  }

  String _deliveryTime(Map<String, dynamic> payload) {
    final raw = _string(payload, 'deliveryTime', 'scheduled_at');
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw.contains(':') ? raw : '';
    final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
    final minute = parsed.minute.toString().padLeft(2, '0');
    final period = parsed.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _deliveryAddress(Map<String, dynamic> payload) {
    final parts = [
      _string(payload, 'address', 'deliveryAddress'),
      _string(payload, 'city'),
      _string(payload, 'pinCode', 'pincode'),
    ].where((part) => part.isNotEmpty && part != '-').toList();
    return parts.join(parts.length > 1 ? ' - ' : '');
  }

  void _labelValue(EscPosBuilder builder, String label, String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty || cleaned == '-') return;
    const labelWidth = 12;
    final valueWidth = builder.charsPerLine - labelWidth - 3;
    final lines = _wrapWords(cleaned, valueWidth);
    for (var index = 0; index < lines.length; index++) {
      final prefix =
          index == 0 ? label.padRight(labelWidth) : ''.padRight(labelWidth);
      builder.text(
        '$prefix: ${lines[index]}',
        maxChars: builder.charsPerLine,
        preserveWhitespace: true,
      );
    }
  }

  List<String> _wrapWords(String value, int width) {
    if (value.isEmpty) return const [];
    final words = value.split(RegExp(r'\s+'));
    final lines = <String>[];
    var current = '';
    for (final word in words) {
      final candidate = current.isEmpty ? word : '$current $word';
      if (candidate.length > width && current.isNotEmpty) {
        lines.add(current);
        current = word;
      } else {
        current = candidate;
      }
    }
    if (current.isNotEmpty) lines.add(current);
    return lines;
  }

  int _largeTextWidth(EscPosBuilder builder) {
    return (builder.charsPerLine / 2).floor();
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[(month - 1).clamp(0, 11)];
  }

  List<String> _splitInstructions(String value) {
    return value
        .split(RegExp(r'[\n,;]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String _itemName(Map<String, dynamic> item) {
    final direct = _string(item, 'name', 'product_name');
    if (direct.isNotEmpty) return direct;
    final description = _string(item, 'description', 'design_ref');
    return description.isEmpty ? 'Item' : description;
  }

  bool _bool(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    return value?.toString().toLowerCase() == 'true';
  }

  int _int(Map<String, dynamic> map, String key, [String? fallbackKey]) {
    final value = map[key] ?? (fallbackKey == null ? null : map[fallbackKey]);
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _string(Map<String, dynamic> map, String key, [String? fallbackKey]) {
    final value = map[key] ?? (fallbackKey == null ? null : map[fallbackKey]);
    return value?.toString().trim() ?? '';
  }

  List<Map<String, dynamic>> _list(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
            (item) => item.map((key, value) => MapEntry(key.toString(), value)))
        .toList();
  }
}

class MessageCardTheme {
  const MessageCardTheme({required this.heading, required this.borderChar});

  final String heading;
  final String borderChar;

  static MessageCardTheme fromPayload(String theme, String occasion) {
    final lowerOccasion = occasion.toLowerCase();
    final heading = _headingFor(lowerOccasion, occasion);
    final borderChar = switch (theme.toLowerCase()) {
      'elegant' => '=',
      'floral' => '*',
      'simple' => '-',
      _ => '*',
    };
    return MessageCardTheme(heading: heading, borderChar: borderChar);
  }

  static String _headingFor(String lowerOccasion, String occasion) {
    if (lowerOccasion.contains('birthday')) return 'Best Birthday Wishes';
    if (lowerOccasion.contains('anniversary')) return 'Happy Anniversary';
    if (lowerOccasion.contains('congrat')) return 'Congratulations';
    if (lowerOccasion.contains('sympathy')) return 'With Sympathy';
    if (lowerOccasion.contains('love')) return 'With Love';
    if (occasion.trim().isEmpty || occasion == '-') return 'Best Wishes';
    return occasion.trim();
  }
}
