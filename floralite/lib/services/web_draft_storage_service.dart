import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/repositories/order_repository.dart';
import '../models/gst_calculation_type.dart';
import '../models/payment_split.dart';
import '../models/walk_in_enums.dart';
import '../models/walk_in_line_item.dart';
import '../models/walk_in_session.dart';

class WebDraftStorageService {
  WebDraftStorageService({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  static const String _storageKey = 'floraprise_web_draft_orders_v1';

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<List<Map<String, dynamic>>> _loadAllDrafts() async {
    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr == null || jsonStr.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        return decoded.whereType<Map<String, dynamic>>().toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> _saveAllDrafts(List<Map<String, dynamic>> drafts) async {
    final prefs = await _getPrefs();
    await prefs.setString(_storageKey, jsonEncode(drafts));
  }

  Future<int> upsertDraft({
    required WalkInSession session,
    required OrderTotals totals,
    required int? customerId,
    String? cloudCustomerId,
  }) async {
    final drafts = await _loadAllDrafts();
    final now = DateTime.now().toIso8601String();

    int draftId = session.draftOrderId ??
        (DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF);

    final orderNo = 'DRAFT-$draftId';
    final clientSyncId = session.posClientSyncId ??
        'web_sync_${DateTime.now().millisecondsSinceEpoch}';

    final draftMap = <String, dynamic>{
      'id': draftId,
      'order_no': orderNo,
      'pos_client_sync_id': clientSyncId,
      'customer_id': customerId,
      'cloud_customer_id': cloudCustomerId,
      'fulfilment_type': session.fulfilmentType.name,
      'customer_phone': session.customerPhone,
      'customer_name': session.customerName,
      'occasion': session.occasion,
      'scheduled_at': session.scheduledAt?.toIso8601String(),
      'delivery_slot': session.deliverySlot,
      'recipient_name': session.recipientName,
      'recipient_phone': session.recipientPhone,
      'delivery_address': session.deliveryAddress,
      'delivery_pincode': session.deliveryPincode,
      'delivery_landmark': session.deliveryLandmark,
      'card_message': session.cardMessage,
      'special_instructions': session.specialInstructions,
      'bill_discount_type': session.billDiscountType,
      'bill_discount_value': session.billDiscountValue,
      'reward_points_redeemed': session.rewardPointsRedeemed,
      'reward_discount_amount_paise': totals.rewardDiscountPaise,
      'totals': {
        'subtotal_paise': totals.subtotalPaise,
        'gst_total_paise': totals.gstTotalPaise,
        'discount_total_paise': totals.discountTotalPaise,
        'reward_discount_paise': totals.rewardDiscountPaise,
        'round_off_paise': totals.roundOffPaise,
        'grand_total_paise': totals.grandTotalPaise,
      },
      'lines': session.lines.map((l) => {
        'product_id': l.productId,
        'cloud_product_id': l.cloudProductId,
        'design_ref': l.designRef,
        'description': l.description,
        'quantity': l.quantity,
        'unit_price_paise': l.unitPricePaise,
        'gst_percent': l.gstPercent,
        'gst_calculation_type': l.gstCalculationType?.name,
        'discount_paise': l.discountPaise,
        'discount_type': l.discountType,
        'discount_value': l.discountValue,
        'source': l.source,
      }).toList(),
      'payments': session.payments.map((p) => {
        'method': p.method.name,
        'amount_paise': p.amountPaise,
        'reference': p.reference,
        'method_code': p.methodCode,
      }).toList(),
      'created_at': now,
      'updated_at': now,
    };

    final index = drafts.indexWhere((d) => d['id'] == draftId);
    if (index >= 0) {
      draftMap['created_at'] = drafts[index]['created_at'] ?? now;
      drafts[index] = draftMap;
    } else {
      drafts.insert(0, draftMap);
    }

    await _saveAllDrafts(drafts);
    return draftId;
  }

  Future<WalkInSession?> getDraftById(int id) async {
    final drafts = await _loadAllDrafts();
    final match = drafts.where((d) => d['id'] == id).firstOrNull;
    if (match == null) return null;
    return _toSession(match);
  }

  Future<WalkInSession?> getLatestDraft(FulfilmentType type) async {
    final drafts = await _loadAllDrafts();
    for (final d in drafts) {
      if (d['fulfilment_type'] == type.name) {
        return _toSession(d);
      }
    }
    return null;
  }

  Future<List<DraftOrderSummary>> listDraftOrders({String query = ''}) async {
    final drafts = await _loadAllDrafts();
    final normalized = query.trim().toLowerCase();

    final filtered = drafts.where((d) {
      if (normalized.isEmpty) return true;
      final orderNo = (d['order_no'] ?? '').toString().toLowerCase();
      final customerName = (d['customer_name'] ?? '').toString().toLowerCase();
      final customerPhone = (d['customer_phone'] ?? '').toString().toLowerCase();
      final id = (d['id'] ?? '').toString();
      return orderNo.contains(normalized) ||
          customerName.contains(normalized) ||
          customerPhone.contains(normalized) ||
          id.contains(normalized);
    }).toList();

    return filtered.map((d) {
      final id = d['id'] as int;
      final lines = (d['lines'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final itemCount = lines.fold<int>(
        0,
        (sum, l) => sum + ((l['quantity'] as int?) ?? 1),
      );
      final totals = d['totals'] as Map<String, dynamic>?;
      final grandTotalPaise = totals?['grand_total_paise'] as int? ?? 0;
      final createdAt = DateTime.tryParse(d['created_at']?.toString() ?? '') ??
          DateTime.now();
      final updatedAt = DateTime.tryParse(d['updated_at']?.toString() ?? '') ??
          createdAt;

      final fulfilmentType = FulfilmentType.values.firstWhere(
        (f) => f.name == d['fulfilment_type'],
        orElse: () => FulfilmentType.takeAway,
      );

      return DraftOrderSummary(
        id: id,
        orderNo: d['order_no']?.toString() ?? 'DRAFT-$id',
        customerName: d['customer_name']?.toString() ?? 'Walk-in Customer',
        customerPhone: d['customer_phone']?.toString() ?? '',
        fulfilmentType: fulfilmentType,
        itemCount: itemCount,
        grandTotalPaise: grandTotalPaise,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    }).toList();
  }

  Future<int> countDraftOrders() async {
    final drafts = await _loadAllDrafts();
    return drafts.length;
  }

  Future<void> deleteDraft(int id) async {
    final drafts = await _loadAllDrafts();
    drafts.removeWhere((d) => d['id'] == id);
    await _saveAllDrafts(drafts);
  }

  Future<String> getOrCreatePosClientSyncId(int orderId) async {
    final drafts = await _loadAllDrafts();
    final index = drafts.indexWhere((d) => d['id'] == orderId);
    if (index >= 0) {
      final existing = drafts[index]['pos_client_sync_id']?.toString().trim();
      if (existing != null && existing.isNotEmpty) return existing;
      final generated = 'web_${DateTime.now().millisecondsSinceEpoch}';
      drafts[index]['pos_client_sync_id'] = generated;
      await _saveAllDrafts(drafts);
      return generated;
    }
    return 'web_${DateTime.now().millisecondsSinceEpoch}';
  }

  WalkInSession _toSession(Map<String, dynamic> d) {
    final linesList = (d['lines'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final paymentsList =
        (d['payments'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final fulfilmentType = FulfilmentType.values.firstWhere(
      (f) => f.name == d['fulfilment_type'],
      orElse: () => FulfilmentType.takeAway,
    );

    return WalkInSession(
      draftOrderId: d['id'] as int?,
      posClientSyncId: d['pos_client_sync_id'] as String?,
      fulfilmentType: fulfilmentType,
      lines: linesList.map((l) {
        final calcTypeName = l['gst_calculation_type']?.toString();
        final calcType = GstCalculationType.values.firstWhere(
          (c) => c.name == calcTypeName,
          orElse: () => GstCalculationType.inclusive,
        );
        return WalkInLineItem(
          productId: l['product_id'] as int?,
          cloudProductId: l['cloud_product_id'] as String?,
          designRef: l['design_ref'] as String?,
          description: l['description'] as String? ?? '',
          quantity: l['quantity'] as int? ?? 1,
          unitPricePaise: l['unit_price_paise'] as int? ?? 0,
          gstPercent: l['gst_percent'] as int? ?? 12,
          gstCalculationType: calcType,
          discountPaise: l['discount_paise'] as int? ?? 0,
          discountType: l['discount_type'] as String?,
          discountValue: l['discount_value'] as int?,
          source: l['source'] as String? ?? 'manual',
        );
      }).toList(),
      customerPhone: d['customer_phone'] as String? ?? '',
      customerName: d['customer_name'] as String? ?? '',
      occasion: d['occasion'] as String? ?? '',
      scheduledAt: d['scheduled_at'] != null
          ? DateTime.tryParse(d['scheduled_at'].toString())
          : null,
      deliverySlot: d['delivery_slot'] as String? ?? '',
      recipientName: d['recipient_name'] as String? ?? '',
      recipientPhone: d['recipient_phone'] as String? ?? '',
      deliveryAddress: d['delivery_address'] as String? ?? '',
      deliveryPincode: d['delivery_pincode'] as String? ?? '',
      deliveryLandmark: d['delivery_landmark'] as String? ?? '',
      cardMessage: d['card_message'] as String? ?? '',
      specialInstructions: d['special_instructions'] as String? ?? '',
      payments: paymentsList.map((p) {
        final method = PaymentMethod.values.firstWhere(
          (m) => m.name == p['method'],
          orElse: () => PaymentMethod.cash,
        );
        return PaymentSplit(
          method: method,
          amountPaise: p['amount_paise'] as int? ?? 0,
          reference: p['reference'] as String?,
          methodCode: p['method_code'] as String?,
        );
      }).toList(),
      billDiscountType: d['bill_discount_type'] as String?,
      billDiscountValue: d['bill_discount_value'] as int?,
      rewardPointsRedeemed: d['reward_points_redeemed'] as int? ?? 0,
      rewardDiscountAmountPaise:
          d['reward_discount_amount_paise'] as int? ?? 0,
    );
  }
}
