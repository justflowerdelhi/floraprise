import 'dart:async';

import '../data/repositories/associate_repository.dart';
import '../data/repositories/order_workflow_repository.dart';
import '../models/order_status.dart';
import '../models/order_workspace_models.dart';
import '../models/scheduler_task.dart';
import '../services/delivery_tracking_service.dart';
import '../services/order_print_service.dart';
import '../services/order_whatsapp_service.dart';
import 'order_manager.dart';
import 'scheduler_manager.dart';

/// Order Workflow Manager extends the existing Orders module.
///
/// It coordinates status transitions, production scheduling, designer
/// forwarding, delivery and relay assignments, printing and WhatsApp
/// templates without duplicating order lifecycle logic held by
/// [OrderManager].
class OrderWorkflowManager {
  OrderWorkflowManager({
    required OrderManager orderManager,
    required OrderWorkflowRepository workflowRepository,
    required AssociateRepository associateRepository,
    required SchedulerManager schedulerManager,
    OrderWhatsappService? whatsappService,
    OrderPrintService? printService,
    String createdBy = 'system',
  })  : _orderManager = orderManager,
        _workflowRepository = workflowRepository,
        _associateRepository = associateRepository,
        _schedulerManager = schedulerManager,
        _whatsappService = whatsappService,
        _printService = printService,
        _createdBy = createdBy;

  final OrderManager _orderManager;
  final OrderWorkflowRepository _workflowRepository;
  final AssociateRepository _associateRepository;
  final SchedulerManager _schedulerManager;
  final OrderWhatsappService? _whatsappService;
  final OrderPrintService? _printService;
  final String _createdBy;

  /// Advances the order through the locked lifecycle and records the
  /// transition timeline event.
  Future<void> advanceStatus({
    required int orderId,
    required String currentStatus,
    required String newStatus,
    String? notes,
  }) async {
    if (!OrderStatus.canTransition(currentStatus, newStatus)) {
      throw ArgumentError(
        'Cannot move from ${OrderStatus.label(currentStatus)} to ${OrderStatus.label(newStatus)}.',
      );
    }

    final combinedNote =
        notes ?? OrderStatus.actionNote(currentStatus, newStatus);

    await _orderManager.updateOrderStatus(
      orderId: orderId,
      currentStatus: currentStatus,
      newStatus: newStatus,
      notes: combinedNote,
    );
  }

  /// Forwards the order to a designer and transitions to [sent_to_designer].
  Future<void> sendToDesigner({
    required int orderId,
    required int designerId,
    String? notes,
  }) async {
    await _workflowRepository.assign(
      orderId: orderId,
      assignmentType: 'designer',
      associateId: designerId,
      notes: notes,
    );

    final header = await _orderManager.getOrderDetailHeader(orderId);
    final status = header?.status ?? OrderStatus.confirmed;

    if (status == OrderStatus.confirmed) {
      await advanceStatus(
        orderId: orderId,
        currentStatus: status,
        newStatus: OrderStatus.sentToDesigner,
        notes: notes ?? 'Forwarded to designer',
      );
    }

    await _schedulerManager.createManualTask(
      title: 'Designer work for order #$orderId',
      scheduledAt: DateTime.now(),
      priority: TaskPriority.high,
      notes: 'Design approval for order #$orderId',
    );
  }

  Future<void> assignDeliveryPartner({
    required int orderId,
    required int deliveryPartnerId,
    String? notes,
    bool syncDeliveryInBackground = true,
  }) async {
    await _workflowRepository.assign(
      orderId: orderId,
      assignmentType: 'delivery',
      associateId: deliveryPartnerId,
      notes: notes ?? 'Delivery partner assigned',
    );
    await _workflowRepository.markDeliverySyncPending(orderId);
    if (syncDeliveryInBackground) {
      await DeliveryTrackingService().syncDeliveryAssignment(orderId);
    }
  }

  /// Starts production/preparing for the order and creates a production task.
  Future<void> startProduction({
    required int orderId,
    DateTime? scheduledAt,
    String? notes,
  }) async {
    final header = await _orderManager.getOrderDetailHeader(orderId);
    final status = header?.status ?? OrderStatus.sentToDesigner;

    await advanceStatus(
      orderId: orderId,
      currentStatus: status,
      newStatus: OrderStatus.preparing,
      notes: notes ?? 'Production started',
    );

    await _schedulerManager.createManualTask(
      title: 'Production for order #$orderId',
      scheduledAt: scheduledAt ?? DateTime.now(),
      priority: TaskPriority.high,
      notes: 'Prepare order #$orderId',
    );
  }

  /// Marks the order as ready and optionally assigns a delivery partner.
  Future<void> markReady({
    required int orderId,
    int? deliveryPartnerId,
    String? notes,
  }) async {
    final header = await _orderManager.getOrderDetailHeader(orderId);
    final status = header?.status ?? OrderStatus.preparing;

    await advanceStatus(
      orderId: orderId,
      currentStatus: status,
      newStatus: OrderStatus.ready,
      notes: notes ?? 'Order ready',
    );

    if (deliveryPartnerId != null) {
      await _workflowRepository.assign(
        orderId: orderId,
        assignmentType: 'delivery',
        associateId: deliveryPartnerId,
        notes: 'Delivery partner assigned',
      );
      await _workflowRepository.markDeliverySyncPending(orderId);
      unawaited(DeliveryTrackingService().syncDeliveryAssignment(orderId));
    }
  }

  /// Sends the order out for delivery.
  Future<void> outForDelivery({
    required int orderId,
    int? deliveryPartnerId,
    String? notes,
  }) async {
    final header = await _orderManager.getOrderDetailHeader(orderId);
    final status = header?.status ?? OrderStatus.ready;

    await advanceStatus(
      orderId: orderId,
      currentStatus: status,
      newStatus: OrderStatus.outForDelivery,
      notes: notes ?? 'Out for delivery',
    );

    if (deliveryPartnerId != null) {
      await _workflowRepository.assign(
        orderId: orderId,
        assignmentType: 'delivery',
        associateId: deliveryPartnerId,
        notes: 'Delivery partner assigned for delivery',
      );
      await _workflowRepository.markDeliverySyncPending(orderId);
      unawaited(DeliveryTrackingService().syncDeliveryAssignment(orderId));
    }
  }

  /// Marks the order delivered.
  Future<void> markDelivered({
    required int orderId,
    String? notes,
  }) async {
    await advanceStatus(
      orderId: orderId,
      currentStatus: OrderStatus.outForDelivery,
      newStatus: OrderStatus.delivered,
      notes: notes ?? 'Order delivered',
    );
  }

  /// Marks the delivery failed and allows retry.
  Future<void> markDeliveryFailed({
    required int orderId,
    String? notes,
  }) async {
    await advanceStatus(
      orderId: orderId,
      currentStatus: OrderStatus.outForDelivery,
      newStatus: OrderStatus.deliveryFailed,
      notes: notes ?? 'Delivery failed',
    );
  }

  /// Cancels the order if it is not terminal.
  Future<void> cancelOrder({
    required int orderId,
    required String currentStatus,
    String? reason,
  }) async {
    await advanceStatus(
      orderId: orderId,
      currentStatus: currentStatus,
      newStatus: OrderStatus.cancelled,
      notes: reason ?? 'Order cancelled',
    );
  }

  /// Assigns a relay partner for inter-store relay.
  Future<void> assignRelayPartner({
    required int orderId,
    required int relayPartnerId,
    String? notes,
  }) async {
    await _workflowRepository.assign(
      orderId: orderId,
      assignmentType: 'relay',
      associateId: relayPartnerId,
      notes: notes,
    );
  }

  /// Adds a workflow note without changing status.
  Future<void> addNote({
    required int orderId,
    required String note,
  }) async {
    await _workflowRepository.addWorkflowNote(
      orderId: orderId,
      note: note,
      createdBy: _createdBy,
    );
  }

  /// Loads the order header, bundle and assignments needed by the workflow UI.
  Future<OrderWorkflowView> loadWorkflowView(int orderId) async {
    final header = await _orderManager.getOrderDetailHeader(orderId);
    final bundle = await _orderManager.getOrderDetailBundle(orderId);
    final assignments = await _workflowRepository.getAssignments(orderId);
    final timeline = await _workflowRepository.getTimeline(orderId);

    if (header == null) {
      throw StateError('Order $orderId not found');
    }

    return OrderWorkflowView(
      header: header,
      bundle: bundle,
      assignments: assignments,
      timeline: timeline,
      nextStatuses: OrderStatus.nextStatuses(header.status),
    );
  }

  /// Returns active associates that can be selected for a workflow role.
  Future<List<AssociateRecord>> getAssignableAssociates() async {
    final rows = await _associateRepository.getAll(activeOnly: true);
    return rows
        .where((a) => a.isActive && a.types.isNotEmpty)
        .toList(growable: false);
  }

  /// Prints the receipt for the given order via the existing job queue.
  Future<void> printReceipt(int orderId) async {
    final service = _printService;
    if (service == null) {
      throw StateError('OrderPrintService is not configured');
    }
    await service.printReceipt(orderId);
  }

  /// Prints the delivery slip / worksheet for the order.
  Future<void> printDeliverySlip(int orderId) async {
    final service = _printService;
    if (service == null) {
      throw StateError('OrderPrintService is not configured');
    }
    await service.printWorksheet(orderId);
  }

  Future<void> printMessageCard(int orderId) async {
    final service = _printService;
    if (service == null) {
      throw StateError('OrderPrintService is not configured');
    }
    await service.printMessageCard(orderId);
  }

  /// Builds a receipt text preview for the order.
  Future<String> previewReceiptText(int orderId) async {
    final service = _printService;
    if (service == null) {
      throw StateError('OrderPrintService is not configured');
    }
    return service.buildReceiptText(orderId);
  }

  /// Sends a WhatsApp message using the configured template.
  Future<void> sendWhatsAppUpdate({
    required int orderId,
    required String template,
    required String phone,
    String? fallbackMessage,
  }) async {
    final service = _whatsappService;
    if (service == null) {
      throw StateError('OrderWhatsappService is not configured');
    }
    await service.sendOrderUpdate(
      orderId: orderId,
      template: template,
      phone: phone,
      fallbackMessage: fallbackMessage,
    );
  }

  /// Enqueues a WhatsApp share job for the background queue.
  Future<void> enqueueWhatsAppUpdate({
    required int orderId,
    required String template,
    required String phone,
    String? fallbackMessage,
  }) async {
    final service = _whatsappService;
    if (service == null) {
      throw StateError('OrderWhatsappService is not configured');
    }

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

    final message = fallbackMessage ??
        await OrderWhatsappService.buildMessage(
          template,
          orderId,
          name,
          status,
          total,
          itemsText,
          address,
        );

    await service.enqueueShare(
        orderId: orderId, phone: phone, message: message);
  }
}

/// Simple container for the workflow screen state.
class OrderWorkflowView {
  final OrderDetailHeader header;
  final OrderDetailBundle? bundle;
  final Map<String, AssignmentRow> assignments;
  final List<Map<String, dynamic>> timeline;
  final List<String> nextStatuses;

  const OrderWorkflowView({
    required this.header,
    this.bundle,
    required this.assignments,
    required this.timeline,
    required this.nextStatuses,
  });
}
