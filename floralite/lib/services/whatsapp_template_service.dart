import '../data/repositories/business_profile_repository.dart';

/// Data for a single line item in a WhatsApp message.
class WhatsAppItemLine {
  final String name;
  final int quantity;
  final String unit;
  final String? category;
  final String? remark;

  const WhatsAppItemLine({
    required this.name,
    required this.quantity,
    required this.unit,
    this.category,
    this.remark,
  });
}

/// Data for an address block in a WhatsApp message.
class WhatsAppAddress {
  final String? line1;
  final String? line2;
  final String? city;
  final String? phone;

  const WhatsAppAddress({
    this.line1,
    this.line2,
    this.city,
    this.phone,
  });
}

/// Unified WhatsApp message template engine for all Floraprise modules.
///
/// Messages are generated from the business profile and module-specific
/// placeholders. The header and footer are automatically added and formatted
/// for easy reading on mobile.
class WhatsAppTemplateService {
  WhatsAppTemplateService({
    BusinessProfileRepository? businessProfileRepository,
  }) : _businessProfileRepository =
            businessProfileRepository ?? BusinessProfileRepository();

  final BusinessProfileRepository _businessProfileRepository;
  BusinessProfile? _cachedProfile;

  Future<BusinessProfile?> _loadProfile() async {
    _cachedProfile ??= await _businessProfileRepository.getBusinessProfile();
    return _cachedProfile;
  }

  static const String _separator = '──────────────────';

  String _shopName(BusinessProfile? profile) =>
      (profile?.shopName.trim().isNotEmpty ?? false)
          ? profile!.shopName.trim()
          : 'Floraprise';

  String _city(BusinessProfile? profile) =>
      (profile?.city?.trim().isNotEmpty ?? false) ? profile!.city!.trim() : '';

  String _phone(BusinessProfile? profile) =>
      (profile?.mobileNumber.trim().isNotEmpty ?? false)
          ? profile!.mobileNumber.trim()
          : '+91 XXXXX XXXXX';

  String _websiteLine(BusinessProfile? profile) {
    final website = profile?.email?.trim() ?? '';
    if (website.isEmpty) return '';
    return '🌐 $website';
  }

  Future<String> _header() async {
    final profile = await _loadProfile();
    final shop = _shopName(profile);
    final city = _city(profile);
    final buffer = StringBuffer()
      ..writeln('🌸 *$shop*')
      ..writeln(city.isEmpty ? '' : city)
      ..writeln(_separator);
    return buffer.toString().trim();
  }

  Future<String> _footer() async {
    final profile = await _loadProfile();
    final phone = _phone(profile);
    final website = _websiteLine(profile);
    final buffer = StringBuffer()
      ..writeln()
      ..writeln(_separator)
      ..writeln('📞 $phone');
    if (website.isNotEmpty) {
      buffer.writeln(website);
    }
    buffer.writeln('Thank You 🌸');
    return buffer.toString();
  }

  String _formatItems(List<WhatsAppItemLine> items) {
    if (items.isEmpty) return 'No items';
    return items.map((i) => '• ${i.name} – ${i.quantity} ${i.unit}').join('\n');
  }

  String _groupedItems(List<WhatsAppItemLine> items) {
    if (items.isEmpty) return 'No items';
    final grouped = <String?, List<WhatsAppItemLine>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }
    final buffer = StringBuffer();
    for (final category in grouped.keys.toList()..sort()) {
      final categoryName =
          category?.trim().isNotEmpty ?? false ? category! : 'Items';
      buffer.writeln(categoryName);
      for (final item in grouped[category]!) {
        buffer.writeln('• ${item.name} – ${item.quantity} ${item.unit}');
        if (item.remark?.trim().isNotEmpty ?? false) {
          buffer.writeln('  Remark: ${item.remark!.trim()}');
        }
      }
      buffer.writeln();
    }
    return buffer.toString().trim();
  }

  Future<String> _build({
    required String title,
    required String body,
  }) async {
    final header = await _header();
    final footer = await _footer();
    return '$header\n\n$title\n\n$body\n$footer';
  }

  /// Generic order status update.
  Future<String> orderStatusUpdate({
    required String customerName,
    required String orderNumber,
    required String status,
    int? totalPaise,
    String? address,
  }) async {
    final totalLine = totalPaise == null
        ? ''
        : '*Total:* ₹${(totalPaise / 100).toStringAsFixed(2)}\n';
    final addressLine = address?.trim().isNotEmpty ?? false
        ? 'Address: ${address!.trim()}\n'
        : '';
    final body = '''
Hi ${customerName.isEmpty ? 'Customer' : customerName},

Your order *$orderNumber* is currently *$status*.

$addressLine${totalLine}Thank you for choosing us.'''
        .trim();
    return _build(
      title: '*ORDER UPDATE*',
      body: body,
    );
  }

  /// 1. Customer bill / order confirmation.
  Future<String> orderConfirmation({
    required String customerName,
    required String orderNumber,
    required DateTime orderDate,
    required int amountPaise,
    required List<WhatsAppItemLine> items,
    required String paymentStatus,
  }) async {
    final amount = '₹${(amountPaise / 100).toStringAsFixed(2)}';
    final body = '''
Hello *${customerName.isEmpty ? 'Customer' : customerName}*,

Thank you for your order.

*Order No:* $orderNumber
*Date:* ${_formatDate(orderDate)}
*Amount:* $amount

Items

${_formatItems(items)}

Payment: $paymentStatus

We'll prepare your order shortly.

Thank you for choosing us.'''
        .trim();
    return _build(
      title: '🧾 *ORDER CONFIRMED*',
      body: body,
    );
  }

  /// 2. Associate order message sent from one florist to another.
  Future<String> associateOrder({
    required String orderNumber,
    required String recipientName,
    String? recipientPhone,
    WhatsAppAddress? recipientAddress,
    required List<WhatsAppItemLine> items,
    String? deliveryTime,
    String? instructions,
  }) async {
    final addressLines = <String>[
      if (recipientAddress?.line1?.trim().isNotEmpty ?? false)
        recipientAddress!.line1!.trim(),
      if (recipientAddress?.line2?.trim().isNotEmpty ?? false)
        recipientAddress!.line2!.trim(),
      if (recipientAddress?.city?.trim().isNotEmpty ?? false)
        recipientAddress!.city!.trim(),
    ].join('\n');

    final body = '''
Dear Partner,

Please arrange delivery for the following order.

*Order No:* $orderNumber

Recipient
$recipientName

${recipientPhone?.trim().isNotEmpty ?? false ? '📞 ${recipientPhone!.trim()}' : ''}

${addressLines.isNotEmpty ? 'Address\n\n$addressLines\n' : ''}
Items

${_formatItems(items)}

${deliveryTime?.trim().isNotEmpty ?? false ? 'Delivery Time\n\n$deliveryTime\n' : ''}
${instructions?.trim().isNotEmpty ?? false ? 'Special Instructions\n\n$instructions\n' : ''}
Please confirm acceptance.

Thank you.'''
        .trim();
    return _build(
      title: '🤝 *NEW ORDER REQUEST*',
      body: body,
    );
  }

  /// 3. Purchase list message.
  Future<String> purchaseList({
    required List<WhatsAppItemLine> items,
    String? vendor,
    String? requestedBy,
  }) async {
    final body = '''
${vendor?.trim().isNotEmpty ?? false ? 'Vendor\n\n${vendor!.trim()}\n' : ''}
Items

${_groupedItems(items)}

${requestedBy?.trim().isNotEmpty ?? false ? 'Requested By\n$requestedBy' : ''}

Thank You'''
        .trim();
    return _build(
      title: '🛒 *PURCHASE LIST*',
      body: body,
    );
  }

  /// 4. Delivery confirmation / out for delivery.
  Future<String> deliveryConfirmation({
    required String customerName,
    required String orderNumber,
    String? deliveryPartner,
  }) async {
    final body = '''
Hello ${customerName.isEmpty ? 'Customer' : customerName},

Your flowers are on the way.

Order
$orderNumber

${deliveryPartner?.trim().isNotEmpty ?? false ? 'Delivery Partner\n$deliveryPartner\n' : ''}
We'll reach you shortly.

Thank you.'''
        .trim();
    return _build(
      title: '🚚 *OUT FOR DELIVERY*',
      body: body,
    );
  }

  /// 5. Delivered successfully.
  Future<String> delivered({
    required String customerName,
    required String orderNumber,
  }) async {
    final body = '''
Hello ${customerName.isEmpty ? 'Customer' : customerName},

Your order has been successfully delivered.

We hope you loved it.

Thank you for choosing us.

We look forward to serving you again.

🌸'''
        .trim();
    return _build(
      title: '✅ *DELIVERED*',
      body: body,
    );
  }

  /// 6. Payment reminder.
  Future<String> paymentReminder({
    required String customerName,
    required String orderNumber,
    required int amountDuePaise,
  }) async {
    final amount = '₹${(amountDuePaise / 100).toStringAsFixed(2)}';
    final body = '''
Hello ${customerName.isEmpty ? 'Customer' : customerName},

This is a friendly reminder that payment for the following order is pending.

Order
$orderNumber

Amount Due
$amount

Please complete the payment at your convenience.

Thank you.'''
        .trim();
    return _build(
      title: '💳 *PAYMENT REMINDER*',
      body: body,
    );
  }

  /// 7. Order reminder.
  Future<String> orderReminder({
    required String customerName,
    required String orderNumber,
    required DateTime deliveryDate,
    String? deliveryTime,
  }) async {
    final body = '''
Hello ${customerName.isEmpty ? 'Customer' : customerName},

This is a reminder about your upcoming order.

Order
$orderNumber

Delivery Date
${_formatDate(deliveryDate)}

${deliveryTime?.trim().isNotEmpty ?? false ? 'Delivery Time\n$deliveryTime\n' : ''}
Thank you.'''
        .trim();
    return _build(
      title: '📅 *ORDER REMINDER*',
      body: body,
    );
  }

  /// 8. Ready for pickup.
  Future<String> readyForPickup({
    required String customerName,
    required String orderNumber,
    String? shopTiming,
  }) async {
    final body = '''
Hello ${customerName.isEmpty ? 'Customer' : customerName},

Your order is ready.

Please collect it from our shop.

Order
$orderNumber

${shopTiming?.trim().isNotEmpty ?? false ? 'Shop Timing\n$shopTiming\n' : ''}
Thank you.'''
        .trim();
    return _build(
      title: '🎁 *READY FOR PICKUP*',
      body: body,
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = _monthName(date.month);
    final year = date.year;
    return '$day $month $year';
  }

  String _monthName(int month) {
    const names = [
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
      'Dec'
    ];
    return names[month - 1];
  }
}
