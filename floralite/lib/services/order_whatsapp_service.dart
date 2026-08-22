import 'package:url_launcher/url_launcher.dart';

import '../data/repositories/job_repository.dart';
import '../managers/order_manager.dart';
import '../models/order_status.dart';
import '../utils/whatsapp_phone_utils.dart';
import 'reward_summary_formatter.dart';
import 'whatsapp_template_service.dart';

/// WhatsApp service for the Order Workflow module.
///
/// Supports two modes:
/// 1. Immediate share via `url_launcher` when the phone number is available.
/// 2. Background job enqueue when the share should be handled later.
///
/// All message text is generated through the centralized
/// [WhatsAppTemplateService] so branding, formatting and contact details
/// stay consistent across every module.
class OrderWhatsappService {
  OrderWhatsappService({
    required OrderManager orderManager,
    JobRepository? jobRepository,
  })  : _orderManager = orderManager,
        _jobRepository = jobRepository;

  final OrderManager _orderManager;
  final JobRepository? _jobRepository;

  /// Template keys that callers pass to [sendOrderUpdate] and [buildMessage].
  static const String orderStatusTemplate = 'status';
  static const String deliveryTemplate = 'delivery';
  static const String readyTemplate = 'ready';
  static const String deliveredTemplate = 'delivered';

  /// Builds the message from a template key and order data using the
  /// centralized template engine.
  static Future<String> buildMessage(
    String template,
    int orderId,
    String customerName,
    String status,
    double total,
    String itemsText,
    String address,
  ) async {
    final service = WhatsAppTemplateService();
    final orderNumber = orderId.toString();
    final amountPaise = (total * 100).round();

    switch (template) {
      case deliveryTemplate:
        return service.deliveryConfirmation(
          customerName: customerName,
          orderNumber: orderNumber,
        );
      case readyTemplate:
        return service.readyForPickup(
          customerName: customerName,
          orderNumber: orderNumber,
        );
      case deliveredTemplate:
        return service.delivered(
          customerName: customerName,
          orderNumber: orderNumber,
        );
      case orderStatusTemplate:
      default:
        return service.orderStatusUpdate(
          customerName: customerName,
          orderNumber: orderNumber,
          status: status,
          totalPaise: amountPaise,
          address: address,
        );
    }
  }

  /// Opens WhatsApp with the given message if a phone number is available.
  Future<void> shareByPhone({
    required int orderId,
    required String phone,
    required String message,
  }) async {
    if (phone.isEmpty) {
      throw ArgumentError('Phone number is required to share via WhatsApp');
    }

    final uri = WhatsAppPhoneUtils.buildUri(phone, message: message);
    if (uri == null) {
      throw ArgumentError('Phone number is required to share via WhatsApp');
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw StateError('Could not open WhatsApp');
    }
  }

  /// Enqueues a WhatsApp share job for the background queue.
  Future<void> enqueueShare({
    required int orderId,
    required String phone,
    required String message,
  }) async {
    final repo = _jobRepository;
    if (repo == null) {
      throw StateError('JobRepository not provided for WhatsApp enqueue');
    }

    final normalizedPhone = WhatsAppPhoneUtils.normalize(phone);
    if (normalizedPhone == null) {
      throw ArgumentError('Phone number is required to share via WhatsApp');
    }
    await repo.enqueueWhatsappJob(orderId, {
      'phone': normalizedPhone,
      'message': message,
      'shared_at': DateTime.now().toIso8601String(),
    });
  }

  /// Convenience method that loads the order, builds the message from a
  /// template and attempts to share.
  Future<void> sendOrderUpdate({
    required int orderId,
    required String template,
    required String phone,
    String? fallbackMessage,
  }) async {
    final header = await _orderManager.getOrderDetailHeader(orderId);
    final bundle = await _orderManager.getOrderDetailBundle(orderId);

    if (header == null) {
      throw StateError('Order $orderId not found');
    }

    final name = bundle?.header.customerName ?? 'Customer';
    final status = OrderStatus.label(header.status);
    final total = header.grandTotalPaise / 100.0;
    final itemsText = bundle?.lines
            .map((l) =>
                '- ${l['product_name'] ?? 'Item'} x${l['quantity'] ?? 1}')
            .join('\n') ??
        '';
    final address = header.address;

    final rewardSummary = await _orderManager.getOrderRewardSummary(orderId);
    final baseMessage = fallbackMessage ??
        await buildMessage(
          template,
          orderId,
          name,
          status,
          total,
          itemsText,
          address,
        );
    final message = '$baseMessage${buildRewardWhatsAppText(rewardSummary)}';

    await shareByPhone(orderId: orderId, phone: phone, message: message);
  }
}
