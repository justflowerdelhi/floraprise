import '../models/payment_split.dart';
import '../models/order_workspace_models.dart';
import '../models/walk_in_enums.dart';
import '../models/walk_in_line_item.dart';
import '../models/walk_in_session.dart';
import 'customer_manager.dart';
import 'inventory_manager.dart';
import 'order_manager.dart';
import 'pricing_manager.dart';
import 'reward_manager.dart';
import 'scheduler_manager.dart';

class SaveDraftResult {
  final WalkInSession session;
  final int grandTotalPaise;

  const SaveDraftResult({
    required this.session,
    required this.grandTotalPaise,
  });
}

class ConfirmOrderResult {
  final int orderId;
  final int grandTotalPaise;

  const ConfirmOrderResult({
    required this.orderId,
    required this.grandTotalPaise,
  });
}

class WalkInManager {
  WalkInManager({
    required CustomerManager customerManager,
    required PricingManager pricingManager,
    required OrderManager orderManager,
    required InventoryManager inventoryManager,
    required SchedulerManager schedulerManager,
    RewardManager? rewardManager,
  })  : _customerManager = customerManager,
        _pricingManager = pricingManager,
        _orderManager = orderManager,
        _inventoryManager = inventoryManager,
        _schedulerManager = schedulerManager,
        _rewardManager = rewardManager ?? RewardManager();

  final CustomerManager _customerManager;
  final PricingManager _pricingManager;
  final OrderManager _orderManager;
  final InventoryManager _inventoryManager;
  final SchedulerManager _schedulerManager;
  final RewardManager _rewardManager;

  Future<WalkInSession> startOrResume(FulfilmentType type) async {
    return WalkInSession.empty(type);
  }

  Future<WalkInSession?> loadDraft(int id) {
    return _orderManager.loadDraftById(id);
  }

  Future<String?> lookupCustomerName(String phone) async {
    final customer = await _customerManager.lookupByPhone(phone);
    return customer?.name;
  }

  Future<Map<String, dynamic>?> lookupCustomerStatistics(String phone) async {
    final customer = await _customerManager.lookupByPhone(phone);
    if (customer == null) {
      return _orderManager.getCustomerStatisticsByPhone(
        _customerManager.normalizePhone(phone),
      );
    }
    return await _orderManager.getCustomerStatistics(
      customer.id,
      customerPhone: customer.phone,
    );
  }

  Future<SaveDraftResult> saveDraft(WalkInSession session) async {
    final ensuredCustomer = await _customerManager.ensureCustomer(
      phone: session.customerPhone,
      name: session.customerName,
    );

    final totals = _pricingManager.computeTotals(
      lines: session.lines,
      billDiscountType: session.billDiscountType,
      billDiscountValue: session.billDiscountValue,
      rewardDiscountPaise: session.rewardDiscountAmountPaise,
    );
    final draftId = await _orderManager.saveDraft(
      session: session,
      totals: totals,
      customerId: ensuredCustomer?.id,
    );

    return SaveDraftResult(
      session: session.copyWith(draftOrderId: draftId),
      grandTotalPaise: totals.grandTotalPaise,
    );
  }

  Future<void> updateExistingOrder({
    required int orderId,
    required WalkInSession session,
  }) async {
    final ensuredCustomer = await _customerManager.ensureCustomer(
      phone: session.customerPhone,
      name: session.customerName,
    );

    final totals = _pricingManager.computeTotals(
      lines: session.lines,
      billDiscountType: session.billDiscountType,
      billDiscountValue: session.billDiscountValue,
      rewardDiscountPaise: session.rewardDiscountAmountPaise,
    );

    await _orderManager.updateExistingOrder(
      orderId: orderId,
      session: session,
      totals: totals,
      customerId: ensuredCustomer?.id,
    );
  }

  Future<ConfirmOrderResult> confirmOrder(WalkInSession session) async {
    if (session.lines.isEmpty) {
      throw StateError('Please add at least one product');
    }

    final ensuredCustomer = await _customerManager.ensureCustomer(
      phone: session.customerPhone,
      name: session.customerName,
    );

    final totals = _pricingManager.computeTotals(
      lines: session.lines,
      billDiscountType: session.billDiscountType,
      billDiscountValue: session.billDiscountValue,
      rewardDiscountPaise: session.rewardDiscountAmountPaise,
    );
    final paymentValidation = _pricingManager.validatePayments(
      grandTotalPaise: totals.grandTotalPaise,
      payments: session.payments,
    );

    if (!paymentValidation.isValid) {
      throw StateError(
          paymentValidation.message ?? 'Payment validation failed');
    }

    final draftId = await _orderManager.saveDraft(
      session: session,
      totals: totals,
      customerId: ensuredCustomer?.id,
    );

    final confirmed = await _orderManager.confirmOrderDraft(orderId: draftId);

    await _inventoryManager.recordOrderSales(
      orderId: confirmed.orderId,
      lineProductLinks: confirmed.lineProductLinks,
    );

    await _schedulerManager.publishWalkInOrderTask(
      orderId: confirmed.orderId,
      fulfilmentType: session.fulfilmentType,
      scheduledAt: session.scheduledAt,
      deliverySlotLabel: session.deliverySlot,
    );

    await _orderManager.enqueueReceiptAndWhatsappJobs(confirmed.orderId);

    return ConfirmOrderResult(
      orderId: confirmed.orderId,
      grandTotalPaise: totals.grandTotalPaise,
    );
  }

  Future<OrderRewardSummary?> getOrderRewardSummary(int orderId) {
    return _orderManager.getOrderRewardSummary(orderId);
  }

  WalkInSession withLines(WalkInSession session, List<WalkInLineItem> lines) {
    return session.copyWith(lines: lines);
  }

  WalkInSession withSinglePayment(
    WalkInSession session,
    PaymentMethod method,
    int grandTotalPaise,
  ) {
    return session.copyWith(
      payments: [
        PaymentSplit(method: method, amountPaise: grandTotalPaise),
      ],
    );
  }

  int currentGrandTotal(WalkInSession session) {
    return _pricingManager
        .computeTotals(
          lines: session.lines,
          billDiscountType: session.billDiscountType,
          billDiscountValue: session.billDiscountValue,
          rewardDiscountPaise: session.rewardDiscountAmountPaise,
        )
        .grandTotalPaise;
  }

  Future<WalkInSession> applyMaximumRewards(WalkInSession session) async {
    final customer =
        await _customerManager.lookupByPhone(session.customerPhone);
    if (customer == null || customer.rewardPoints <= 0) {
      return session.copyWith(
        rewardPointsRedeemed: 0,
        rewardDiscountAmountPaise: 0,
      );
    }

    final settings = await _rewardManager.loadSettings();
    final totalsBeforeReward = _pricingManager.computeTotals(
      lines: session.lines,
      billDiscountType: session.billDiscountType,
      billDiscountValue: session.billDiscountValue,
    );
    final points = _rewardManager.calculateMaximumRedeemablePoints(
      billPaise: totalsBeforeReward.grandTotalPaise,
      availablePoints: customer.rewardPoints,
      settings: settings,
    );
    final discountPaise = _rewardManager.redemptionAmountPaise(
      points: points,
      settings: settings,
    );
    return session.copyWith(
      rewardPointsRedeemed: points,
      rewardDiscountAmountPaise: discountPaise,
    );
  }
}
