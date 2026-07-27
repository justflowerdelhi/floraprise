import '../data/repositories/job_repository.dart';
import '../managers/onboarding_manager.dart';
import '../managers/order_manager.dart';
import '../models/order_status.dart';
import '../models/order_workspace_models.dart';
import '../models/printer_models.dart';
import 'printer/printer_manager.dart';

/// Service for printing order receipts and work sheets from the
/// Order Workflow module.
///
/// It reuses the existing background job queue by enqueueing a
/// `receipt_jobs` row, and also builds a printable plain text summary
/// that can be previewed or shared.
class OrderPrintService {
  OrderPrintService({
    required OrderManager orderManager,
    JobRepository? jobRepository,
    PrinterManager? printerManager,
  })  : _orderManager = orderManager,
        _jobRepository = jobRepository,
        _printerManager = printerManager ?? PrinterManager();

  final OrderManager _orderManager;
  final JobRepository? _jobRepository;
  final PrinterManager _printerManager;
  final OnboardingManager _onboardingManager = OnboardingManager();

  /// Enqueues a receipt print job for the background queue.
  Future<void> printReceipt(int orderId) async {
    final repo = _jobRepository;
    if (repo == null) {
      throw StateError('JobRepository not provided for print job');
    }

    final header = await _orderManager.getOrderDetailHeader(orderId);
    if (header == null) {
      throw StateError('Order $orderId not found');
    }

    final bundle = await _orderManager.getOrderDetailBundle(orderId);
    final payload = _posPayload(header, bundle);
    await repo.enqueueReceiptJob(orderId, payload);
    await _printerManager.enqueue(
      type: PrintJobType.posBill,
      payload: payload,
      tryPrintNow: true,
    );
    await _onboardingManager.markPrinterTested();
  }

  /// Enqueues a kitchen/preparation work sheet print job.
  Future<void> printWorksheet(int orderId) async {
    final repo = _jobRepository;
    if (repo == null) {
      throw StateError('JobRepository not provided for print job');
    }

    final header = await _orderManager.getOrderDetailHeader(orderId);
    final bundle = await _orderManager.getOrderDetailBundle(orderId);
    if (header == null) {
      throw StateError('Order $orderId not found');
    }

    final payload = _deliveryPayload(header, bundle);
    await repo.enqueueReceiptJob(orderId, payload);
    await _printerManager.enqueue(
      type: PrintJobType.deliverySlip,
      payload: payload,
      tryPrintNow: true,
    );
    await _onboardingManager.markPrinterTested();
  }

  Future<void> printMessageCard(int orderId) async {
    final repo = _jobRepository;
    if (repo == null) {
      throw StateError('JobRepository not provided for print job');
    }

    final header = await _orderManager.getOrderDetailHeader(orderId);
    if (header == null) {
      throw StateError('Order $orderId not found');
    }

    final payload = {
      'order_id': orderId,
      'order_no': header.orderNo,
      'printed_at': DateTime.now().toIso8601String(),
      'type': 'message_card',
      'recipient': header.recipientName,
      'occasion': header.occasion,
      'message': header.cardMessage,
      'sender': header.customerName,
      'theme': 'classic',
    };
    await repo.enqueueReceiptJob(orderId, payload);
    await _printerManager.enqueue(
      type: PrintJobType.messageCard,
      payload: payload,
      tryPrintNow: true,
    );
    await _onboardingManager.markPrinterTested();
  }

  /// Builds a plain text receipt summary for preview or sharing.
  Future<String> buildReceiptText(int orderId) async {
    final header = await _orderManager.getOrderDetailHeader(orderId);
    final bundle = await _orderManager.getOrderDetailBundle(orderId);

    if (header == null) {
      throw StateError('Order $orderId not found');
    }

    final buffer = StringBuffer();
    buffer.writeln('FLORAPRISE');
    buffer.writeln('Order: ${header.orderNo}');
    buffer.writeln('Status: ${OrderStatus.label(header.status)}');
    buffer.writeln('Customer: ${header.customerName}');
    buffer.writeln('Phone: ${header.customerPhone}');
    buffer.writeln('Recipient: ${header.recipientName}');
    buffer.writeln('Address: ${header.address}');
    buffer.writeln('');
    buffer.writeln('--- Items ---');
    for (final line in bundle?.lines ?? []) {
      final name = line['product_name'] ?? 'Item';
      final qty = line['quantity'] ?? 1;
      final price = line['unit_price_paise'] ?? 0;
      final lineTotal = (qty as int) * (price as int) / 100.0;
      buffer.writeln('$name x$qty - ₹${lineTotal.toStringAsFixed(2)}');
    }
    buffer.writeln('');
    buffer.writeln(
        'Total: ₹${(header.grandTotalPaise / 100.0).toStringAsFixed(2)}');
    return buffer.toString();
  }

  /// Builds a printable delivery slip/delivery boy handout.
  Future<String> buildDeliverySlip(int orderId) async {
    final header = await _orderManager.getOrderDetailHeader(orderId);
    final bundle = await _orderManager.getOrderDetailBundle(orderId);

    if (header == null) {
      throw StateError('Order $orderId not found');
    }

    final buffer = StringBuffer();
    buffer.writeln('DELIVERY SLIP');
    buffer.writeln('Order: ${header.orderNo}');
    buffer.writeln('Customer: ${header.customerName}');
    buffer.writeln('Phone: ${header.customerPhone}');
    buffer.writeln('Recipient: ${header.recipientName}');
    buffer.writeln('Address: ${header.address}');
    buffer.writeln('');
    buffer.writeln('--- Items ---');
    for (final line in bundle?.lines ?? []) {
      final name = line['product_name'] ?? 'Item';
      final qty = line['quantity'] ?? 1;
      buffer.writeln('$name x$qty');
    }
    buffer.writeln('');
    buffer.writeln(
        'Total: ₹${(header.grandTotalPaise / 100.0).toStringAsFixed(2)}');
    return buffer.toString();
  }

  Map<String, dynamic> _posPayload(
    OrderDetailHeader header,
    OrderDetailBundle? bundle,
  ) {
    final paymentRows =
        (bundle?.payments ?? const <Map<String, Object?>>[]).map((row) {
      final method = (row['method'] as String?) ?? '';
      final amount = (row['amount_paise'] as int?) ?? 0;
      return {
        'method': _displayPaymentMethod(method),
        'amountPaise': amount,
        'isCredit': method.toLowerCase() == 'credit',
      };
    }).toList(growable: false);

    final paymentMode = paymentRows
        .map((row) => row['method']?.toString() ?? '')
        .where((method) => method.isNotEmpty)
        .join(', ');

    final paidPaise = paymentRows
        .where((row) => row['isCredit'] != true)
        .fold<int>(0, (sum, row) => sum + ((row['amountPaise'] as int?) ?? 0));
    final outstandingPaise =
        (header.grandTotalPaise - paidPaise).clamp(0, header.grandTotalPaise);

    return {
      'order_id': header.id,
      'order_no': header.orderNo,
      'invoiceNumber': header.orderNo,
      'printed_at': DateTime.now().toIso8601String(),
      'dateTime': DateTime.now().toString().split('.').first,
      'type': 'receipt',
      'customerName': header.customerName,
      'customerPhone': header.customerPhone,
      'items': bundle?.lines ?? const [],
      'grandTotalPaise': header.grandTotalPaise,
      'paymentMode': paymentMode,
      'paymentSummary': paymentRows,
      'paidPaise': paidPaise,
      'outstandingPaise': outstandingPaise,
    };
  }

  String _displayPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'upi':
        return 'UPI';
      case 'card':
        return 'Card';
      case 'bank_transfer':
      case 'bank':
        return 'Bank Transfer';
      case 'cheque':
        return 'Cheque';
      case 'credit':
        return 'Credit (Outstanding)';
      case 'gift_voucher':
        return 'Gift Voucher';
      case 'store_wallet':
        return 'Store Wallet';
      default:
        return method;
    }
  }

  Map<String, dynamic> _deliveryPayload(
    OrderDetailHeader header,
    OrderDetailBundle? bundle,
  ) {
    return {
      'order_id': header.id,
      'order_no': header.orderNo,
      'orderNo': header.orderNo,
      'printed_at': DateTime.now().toIso8601String(),
      'type': 'delivery_slip',
      'customer': header.customerName,
      'phone': header.customerPhone,
      'recipientName': header.recipientName,
      'recipientPhone': header.recipientPhone,
      'senderName': header.customerName,
      'senderPhone': header.customerPhone,
      'address': header.address,
      'landmark': header.deliveryLandmark,
      'pinCode': header.deliveryPincode,
      'city': '',
      'deliveryTime': header.scheduledAt?.toString() ?? header.deliverySlot,
      'driverName': header.deliveryName ?? '',
      'deliveryInstructions': header.specialInstructions,
      'messageCardIncluded': header.cardMessage.trim().isNotEmpty,
      'remarks': header.cardMessage,
      'items': bundle?.lines ?? const [],
    };
  }
}
