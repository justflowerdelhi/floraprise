import '../data/repositories/job_repository.dart';
import '../data/repositories/order_repository.dart';
import '../models/order_status.dart';
import '../models/order_workspace_models.dart';
import '../models/walk_in_enums.dart' hide OrderStatus;
import '../models/walk_in_session.dart';
import '../utils/whatsapp_phone_utils.dart';

class OrderManager {
  OrderManager(this._orderRepository, this._jobRepository);

  final OrderRepository _orderRepository;
  final JobRepository _jobRepository;

  static const Map<String, List<String>> _allowedTransitions =
      OrderStatus.allowedTransitions;

  Future<WalkInSession?> loadLatestDraftForType(FulfilmentType type) {
    return _orderRepository.getLatestDraft(type);
  }

  Future<WalkInSession?> loadDraftById(int id) {
    return _orderRepository.getDraftById(id);
  }

  Future<List<DraftOrderSummary>> listDraftOrders({String query = ''}) {
    return _orderRepository.listDraftOrders(query: query);
  }

  Future<int> countDraftOrders() {
    return _orderRepository.countDraftOrders();
  }

  Future<void> deleteDraft(int id) {
    return _orderRepository.deleteDraft(id);
  }

  Future<int> saveDraft({
    required WalkInSession session,
    required OrderTotals totals,
    required int? customerId,
  }) {
    return _orderRepository.upsertDraft(
      session: session,
      totals: totals,
      customerId: customerId,
    );
  }

  Future<void> updateExistingOrder({
    required int orderId,
    required WalkInSession session,
    required OrderTotals totals,
    required int? customerId,
  }) {
    return _orderRepository.updateOrderFromSession(
      orderId: orderId,
      session: session,
      totals: totals,
      customerId: customerId,
    );
  }

  Future<ConfirmedOrder> confirmOrderDraft({required int orderId}) {
    return _orderRepository.confirmDraft(orderId: orderId);
  }

  Future<Map<String, dynamic>> getCustomerStatistics(
    int customerId, {
    String? customerPhone,
  }) {
    return _orderRepository.getCustomerStatistics(
      customerId,
      customerPhone: customerPhone,
    );
  }

  Future<Map<String, dynamic>> getCustomerStatisticsByPhone(
      String phone) async {
    final stats = await _orderRepository.getCustomerOrderStatistics(
      customerPhone: phone,
    );
    return stats.toCardMap();
  }

  Future<void> enqueueReceiptAndWhatsappJobs(int orderId) async {
    final summary = await _orderRepository.getOrderSummary(orderId);
    final payload = {
      'orderId': orderId,
      'orderNo': summary['order_no'],
      'grandTotalPaise': summary['grand_total_paise'],
      'customerName': summary['customer_name'],
      'customerPhone': summary['customer_phone'],
      'fulfilmentType': summary['fulfilment_type'],
    };

    await _jobRepository.enqueueReceiptJob(orderId, payload);
    await _jobRepository.enqueueWhatsappJob(orderId, {
      ...payload,
      'customerPhone': WhatsAppPhoneUtils.normalize(
        summary['customer_phone'] as String?,
      ),
    });
  }

  Future<List<OrderListItem>> getOrdersForWorkspace({
    required String tab,
    required String searchQuery,
    required OrderWorkspaceFilters filters,
  }) {
    return _orderRepository.getOrdersForWorkspace(
      tab: tab,
      searchQuery: searchQuery,
      filters: filters,
    );
  }

  Future<List<OrderListItem>> getHistory({
    int limit = 100,
    int offset = 0,
  }) {
    return _orderRepository.getOrdersForWorkspace(
      tab: 'all',
      searchQuery: '',
      filters: OrderWorkspaceFilters.empty,
      limit: limit,
      offset: offset,
    );
  }

  Future<OrderDetailHeader?> getOrderDetailHeader(int orderId) {
    return _orderRepository.getOrderDetailHeader(orderId);
  }

  Future<OrderDetailBundle?> getOrderDetailBundle(int orderId) async {
    final header = await _orderRepository.getOrderDetailHeader(orderId);
    if (header == null) {
      return null;
    }

    final lines = await _orderRepository.getOrderLines(orderId);
    final payments = await _orderRepository.getOrderPayments(orderId);
    final timeline = await _orderRepository.getOrderTimeline(orderId);
    final schedulerTasks =
        await _orderRepository.getSchedulerTasksForOrder(orderId);
    final inventoryTransactions =
        await _orderRepository.getInventoryImpactForOrder(orderId);
    final receiptStatus = await _orderRepository.getReceiptStatus(orderId);
    final whatsappStatus = await _orderRepository.getWhatsappStatus(orderId);
    final metadata = await _orderRepository.getSourceMetadata(orderId);

    return OrderDetailBundle(
      header: header,
      lines: lines,
      payments: payments,
      timeline: timeline,
      schedulerTasks: schedulerTasks,
      inventoryTransactions: inventoryTransactions,
      receiptStatus: receiptStatus,
      whatsappStatus: whatsappStatus,
      relayInfo: {
        'relay_partner_name': metadata['relay_partner_name'],
        'relay_partner_phone': metadata['relay_partner_phone'],
        'relay_partner_email': metadata['relay_partner_email'],
        'relay_partner_order_number': metadata['relay_partner_order_number'],
        'relay_token': metadata['relay_token'],
        'relay_status': metadata['relay_status'],
        'settlement_status': metadata['settlement_status'],
      },
      corporateInfo: {
        'corporate_account': metadata['corporate_account'],
        'corporate_department': metadata['corporate_department'],
        'corporate_employee_name': metadata['corporate_employee_name'],
        'corporate_occasion': metadata['corporate_occasion'],
      },
      marketplaceInfo: {
        'marketplace_name': metadata['marketplace_name'],
        'marketplace_order_id': metadata['marketplace_order_id'],
        'marketplace_status': metadata['marketplace_status'],
      },
    );
  }

  Future<OrderRewardSummary?> getOrderRewardSummary(int orderId) {
    return _orderRepository.getOrderRewardSummary(orderId);
  }

  Future<void> updateOrderStatus({
    required int orderId,
    required String currentStatus,
    required String newStatus,
    String? notes,
  }) async {
    final allowed = _allowedTransitions[currentStatus] ?? const <String>[];
    if (!allowed.contains(newStatus)) {
      throw StateError(
          'Invalid status transition: $currentStatus -> $newStatus');
    }

    await _orderRepository.updateOrderStatus(
      orderId: orderId,
      newStatus: newStatus,
      notes: notes,
      createdBy: 'orderManager',
    );
  }

  Future<void> prepareRelayActionLinkTemplates({
    required int orderId,
    required String relayToken,
  }) {
    return _orderRepository.prepareRelayActionLinks(
      orderId: orderId,
      relayToken: relayToken,
    );
  }

  Future<Map<String, int>> getTodaySummary() {
    return _orderRepository.getTodaySummary();
  }

  Future<void> collectOrderPayment({
    required int orderId,
    required String method,
    required int amountPaise,
    String? reference,
  }) {
    return _orderRepository.addOrderPaymentTransaction(
      orderId: orderId,
      method: method,
      amountPaise: amountPaise,
      reference: reference,
      actor: 'orderManager',
      note: 'Payment collected ${method.toUpperCase()}',
    );
  }

  Future<void> adjustOrderPayment({
    required int orderId,
    required String event,
    required String resolution,
    required int amountPaise,
    String? refundMethod,
    String? remarks,
  }) {
    return _orderRepository.addOrderPaymentAdjustment(
      orderId: orderId,
      event: event,
      resolution: resolution,
      amountPaise: amountPaise,
      refundMethod: refundMethod,
      remarks: remarks,
      actor: 'orderManager',
    );
  }
}
