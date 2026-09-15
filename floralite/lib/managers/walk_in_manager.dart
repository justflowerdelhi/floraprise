import 'package:flutter/foundation.dart';

import '../models/gst_calculation_type.dart';
import '../models/payment_split.dart';
import '../models/order_workspace_models.dart';
import '../models/walk_in_enums.dart';
import '../models/walk_in_line_item.dart';
import '../models/walk_in_session.dart';
import '../services/discount_service.dart';
import '../services/pos_sale_sync_service.dart';
import '../data/repositories/customer_repository.dart';
import '../data/repositories/order_repository.dart';
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

String cloudPosOrderNumber(String clientSyncId) {
  final normalized = clientSyncId.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(clientSyncId, 'clientSyncId', 'must not be empty');
  }
  return 'ORD-POS-$normalized';
}

class WalkInManager {
  @visibleForTesting
  static bool debugForceWebMode = false;

  WalkInManager({
    required CustomerManager customerManager,
    required PricingManager pricingManager,
    required OrderManager orderManager,
    required InventoryManager inventoryManager,
    required SchedulerManager schedulerManager,
    PosSaleSyncService? posSaleSyncService,
    RewardManager? rewardManager,
  })  : _customerManager = customerManager,
        _pricingManager = pricingManager,
        _orderManager = orderManager,
        _schedulerManager = schedulerManager,
      _posSaleSyncService = posSaleSyncService,
        _rewardManager = rewardManager ?? RewardManager();

  final CustomerManager _customerManager;
  final PricingManager _pricingManager;
  final OrderManager _orderManager;
  final SchedulerManager _schedulerManager;
  final PosSaleSyncService? _posSaleSyncService;
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
    final draftId = session.draftOrderId ??
        await _orderManager.saveDraft(
          session: session,
          totals: totals,
          customerId: ensuredCustomer?.id,
          cloudCustomerId: ensuredCustomer?.cloudCustomerId,
        );

    return SaveDraftResult(
      session: session.copyWith(
        draftOrderId: draftId,
        posClientSyncId: await _orderManager.getOrCreatePosClientSyncId(draftId),
      ),
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
      cloudCustomerId: ensuredCustomer?.cloudCustomerId,
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
      cloudCustomerId: ensuredCustomer?.cloudCustomerId,
    );

    final confirmed = await _orderManager.confirmOrderDraft(orderId: draftId);

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

  Future<ConfirmOrderResult> confirmOnlineOrder(WalkInSession session) async {
    final syncService = _posSaleSyncService;
    if (syncService == null) {
      throw StateError('Cloud POS sync service is not available.');
    }
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

    if (kIsWeb || debugForceWebMode) {
      final clientSyncId =
          'web_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecondsSinceEpoch % 1000)}';
      final now = DateTime.now();
      final payload = buildWebPosPayload(
        session: session,
        totals: totals,
        ensuredCustomer: ensuredCustomer,
        clientSyncId: clientSyncId,
        now: now,
      );

      await syncService.submitPayload(payload);
      if (session.draftOrderId != null) {
        try {
          await _orderManager.deleteDraft(session.draftOrderId!);
        } catch (_) {}
      }
      return ConfirmOrderResult(
        orderId: payload['localOrderId'] as int,
        grandTotalPaise: totals.grandTotalPaise,
      );
    }

    final draftId = await _orderManager.saveDraft(
      session: session,
      totals: totals,
      customerId: ensuredCustomer?.id,
      cloudCustomerId: ensuredCustomer?.cloudCustomerId,
    );
    final clientSyncId = await _orderManager.getOrCreatePosClientSyncId(draftId);
    final orderNo = cloudPosOrderNumber(clientSyncId);
    final payload = await _orderManager.buildCloudPosSalePayload(
      orderId: draftId,
      clientSyncId: clientSyncId,
      orderNo: orderNo,
    );
    final syncResult = await syncService.submitPayload(payload);
    final confirmed = await _orderManager.finalizeCloudConfirmedDraft(
      orderId: draftId,
      orderNo: orderNo,
      cloudOrderId: syncResult.cloudOrderId,
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

  @visibleForTesting
  static Map<String, dynamic> buildWebPosPayload({
    required WalkInSession session,
    required OrderTotals totals,
    required CustomerRecord? ensuredCustomer,
    required String clientSyncId,
    required DateTime now,
  }) {
    final orderNo = cloudPosOrderNumber(clientSyncId);
    final lineSnapshots = <Map<String, dynamic>>[];
    final inventorySnapshots = <Map<String, dynamic>>[];

    for (var i = 0; i < session.lines.length; i++) {
      final line = session.lines[i];
      final authoritativeId = line.cloudProductId?.trim();
      final hasAuthoritativeProduct =
          authoritativeId != null && authoritativeId.isNotEmpty;

      if (line.source == 'product' && !hasAuthoritativeProduct) {
        throw StateError(
            'Unable to complete sale because product information is incomplete.');
      }

      final lineSubtotal = (line.unitPricePaise * line.quantity).round();
      final lineDiscount = line.discountType != null && line.discountValue != null
          ? DiscountService.calculateLineDiscount(
              lineSubtotalPaise: lineSubtotal,
              discountType: line.discountType!,
              discountValue: line.discountValue!,
            )
          : line.discountPaise;
      final discounted = lineSubtotal - lineDiscount;
      final breakup = calculateGstLineBreakup(
        amountPaise: discounted,
        gstPercent: line.gstPercent,
        calculationType: line.gstCalculationType,
      );

      lineSnapshots.add({
        'id': i + 1,
        if (hasAuthoritativeProduct) ...{
          'product_id': authoritativeId,
          'cloudProductId': authoritativeId,
        },
        'design_ref': line.designRef,
        'description': line.description,
        'qty': line.quantity.round(),
        'unit_price_paise': line.unitPricePaise.round(),
        'gst_percent': line.gstPercent,
        'discount_type': line.discountType,
        'discount_value': line.discountValue,
        'discount_paise': lineDiscount.round(),
        'line_subtotal_paise': breakup.basicAmountPaise.round(),
        'line_gst_paise': breakup.gstAmountPaise.round(),
        'line_total_paise': discounted.round(),
        'source': line.source,
      });

      if (hasAuthoritativeProduct) {
        inventorySnapshots.add({
          'id': i + 1,
          'product_id': authoritativeId,
          'cloudProductId': authoritativeId,
          'qty': line.quantity.round(),
          'created_at': now.toIso8601String(),
        });
      }
    }

    final paymentSnapshots = session.payments.asMap().entries.map((e) => {
          'id': e.key + 1,
          'method': e.value.persistenceMethod,
          'amount_paise': e.value.amountPaise.round(),
          'reference': e.value.reference,
          'created_at': now.toIso8601String(),
        }).toList();

    return {
      'clientSyncId': clientSyncId,
      'localOrderId': (now.millisecondsSinceEpoch & 0x7FFFFFFF),
      'order': {
        'order_no': orderNo,
        'cloudCustomerId': ensuredCustomer?.cloudCustomerId,
        'customer_phone': session.customerPhone,
        'customer_name': session.customerName,
        'source': 'pos',
        'channel': 'walkin',
        'fulfilment_type': session.fulfilmentType.name,
        'recipient_name': session.recipientName,
        'recipient_phone': session.recipientPhone,
        'delivery_address': session.deliveryAddress,
        'delivery_pincode': session.deliveryPincode,
        'card_message': session.cardMessage,
        'delivery_slot': session.deliverySlot,
        'scheduled_at': session.scheduledAt?.toIso8601String(),
        'confirmed_at': now.toIso8601String(),
        'business_date':
            DateTime.utc(now.year, now.month, now.day).toIso8601String(),
        'subtotal_paise': totals.subtotalPaise.round(),
        'gst_total_paise': totals.gstTotalPaise.round(),
        'discount_total_paise': totals.discountTotalPaise.round(),
        'grand_total_paise': totals.grandTotalPaise.round(),
        'round_off_paise':
            totals.roundOffPaise == 0 ? 0 : totals.roundOffPaise.round(),
        'reward_discount_amount_paise': session.rewardDiscountAmountPaise.round(),
        'reward_points_earned': 0,
        'reward_points_redeemed': session.rewardPointsRedeemed.round(),
        'is_paid': 1,
      },
      'lines': lineSnapshots,
      'payments': paymentSnapshots,
      'inventoryTransactions': inventorySnapshots,
    };
  }
}
