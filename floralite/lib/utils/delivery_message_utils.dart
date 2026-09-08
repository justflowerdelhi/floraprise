import '../models/order_workspace_models.dart';

/// Shared "▶ START DELIVERY" block appended to a delivery assignment message.
/// Used by both the Local and Cloud assignment flows so the driver receives the
/// same tracking-start link in either storage mode.
List<String> startDeliverySection(String? startDeliveryLink) {
  final link = startDeliveryLink?.trim() ?? '';
  if (link.isEmpty) return const [];
  return ['', '▶ START DELIVERY', link];
}

String assignmentFormatDate(DateTime? value) {
  if (value == null) return '-';
  return '${value.day}/${value.month}/${value.year}';
}

String assignmentFormatPaise(int paise) =>
    '₹${(paise / 100).toStringAsFixed(0)}';

String assignmentProductChecklist(
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

/// Designer WhatsApp message. Reads only the order detail bundle, so Local and
/// Cloud orders produce the same text from their own data.
String designerAssignmentMessage(
  OrderDetailHeader header,
  OrderDetailBundle? detail,
  String designerName,
) {
  return [
    '🌸 NEW DESIGN ORDER',
    '',
    'Order : ${header.orderNo}',
    '',
    'Recipient',
    header.recipientName,
    '',
    'Customer',
    header.customerName,
    '',
    'Delivery',
    assignmentFormatDate(header.scheduledAt),
    header.deliverySlot.isEmpty ? '-' : header.deliverySlot,
    '',
    'Designer',
    designerName,
    '',
    'Products',
    assignmentProductChecklist(detail, checked: true),
    '',
    'Message Card',
    header.cardMessage.isEmpty ? '-' : header.cardMessage,
    '',
    'Please acknowledge after preparation.',
  ].join('\n');
}

/// Delivery WhatsApp message, including the START DELIVERY tracking link.
String deliveryAssignmentMessage(
  OrderDetailHeader header,
  OrderDetailBundle? detail,
  String deliveryName, {
  String? startDeliveryLink,
}) {
  final address = header.address.trim();
  final mapsLink = address.isNotEmpty
      ? 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}'
      : '-';
  final outstanding = header.outstandingAmountPaise;
  final lines = [
    '🚚 DELIVERY ASSIGNMENT',
    '',
    'Order : ${header.orderNo}',
    '',
    'Recipient',
    header.recipientName,
    '',
    'Customer',
    header.customerName,
    '',
    'Phone',
    header.recipientPhone.isEmpty ? '-' : header.recipientPhone,
    '',
    'Delivery Address',
    address.isEmpty ? '-' : address,
    '',
    'Google Maps URL',
    mapsLink,
    '',
    'Delivery Slot',
    header.deliverySlot.isEmpty ? '-' : header.deliverySlot,
    '',
    'Occasion',
    header.occasion.isEmpty ? '-' : header.occasion,
    '',
    'Message Card Included',
    header.cardMessage.isEmpty ? 'NO' : 'YES',
    '',
    'Outstanding Amount',
    assignmentFormatPaise(outstanding),
    '',
    'Products',
    assignmentProductChecklist(detail, checked: false),
    '',
    'Delivery Person',
    deliveryName,
    ...startDeliverySection(startDeliveryLink),
  ];
  return lines.join('\n');
}
