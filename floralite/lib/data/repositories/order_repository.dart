import 'package:sqflite/sqflite.dart';

import '../../models/payment_split.dart';
import '../../models/order_workspace_models.dart';
import '../../models/walk_in_enums.dart';
import '../../models/walk_in_line_item.dart';
import '../../models/walk_in_session.dart';
import '../database/app_database.dart';

class OrderTotals {
  final int subtotalPaise;
  final int gstTotalPaise;
  final int discountTotalPaise;
  final int roundOffPaise;
  final int grandTotalPaise;

  const OrderTotals({
    required this.subtotalPaise,
    required this.gstTotalPaise,
    required this.discountTotalPaise,
    required this.roundOffPaise,
    required this.grandTotalPaise,
  });
}

class ConfirmedOrder {
  final int orderId;
  final List<Map<String, int>> lineProductLinks;

  const ConfirmedOrder({
    required this.orderId,
    required this.lineProductLinks,
  });
}

class DraftOrderSummary {
  final int id;
  final String orderNo;
  final String customerName;
  final String customerPhone;
  final FulfilmentType fulfilmentType;
  final int itemCount;
  final int grandTotalPaise;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DraftOrderSummary({
    required this.id,
    required this.orderNo,
    required this.customerName,
    required this.customerPhone,
    required this.fulfilmentType,
    required this.itemCount,
    required this.grandTotalPaise,
    required this.createdAt,
    required this.updatedAt,
  });
}

class CustomerOrderStatistics {
  final int? customerId;
  final String customerName;
  final String customerPhone;
  final int previousOrders;
  final int lifetimePurchasePaise;
  final String? lastOrderDate;
  final String? favouriteDesign;

  const CustomerOrderStatistics({
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.previousOrders,
    required this.lifetimePurchasePaise,
    required this.lastOrderDate,
    required this.favouriteDesign,
  });

  Map<String, dynamic> toCardMap() {
    return {
      'previousOrders': previousOrders,
      'lifetimePurchasePaise': lifetimePurchasePaise,
      'lastOrderDate': lastOrderDate,
      'favouriteDesign': favouriteDesign,
    };
  }
}

class OrderRepository {
  static const List<String> customerStatisticsStatuses = [
    'confirmed',
    'preparing',
    'ready',
    'out_for_delivery',
    'delivered',
  ];

  String _fulfilmentToDb(FulfilmentType type) {
    switch (type) {
      case FulfilmentType.takeAway:
        return 'take_away';
      case FulfilmentType.pickupLater:
        return 'pickup_later';
      case FulfilmentType.delivery:
        return 'delivery';
    }
  }

  FulfilmentType _dbToFulfilment(String value) {
    switch (value) {
      case 'pickup_later':
        return FulfilmentType.pickupLater;
      case 'delivery':
        return FulfilmentType.delivery;
      default:
        return FulfilmentType.takeAway;
    }
  }

  PaymentMethod _paymentMethodFromCode(String code) {
    switch (code.toLowerCase()) {
      case 'cash':
        return PaymentMethod.cash;
      case 'upi':
        return PaymentMethod.upi;
      case 'card':
        return PaymentMethod.card;
      case 'bank':
      case 'bank_transfer':
        return PaymentMethod.bank;
      default:
        return PaymentMethod.other;
    }
  }

  int _paidAmountPaiseFromPayments(List<PaymentSplit> payments) {
    return payments
        .where((payment) => !payment.isCreditOutstanding)
        .fold<int>(0, (sum, payment) => sum + payment.amountPaise);
  }

  Future<WalkInSession?> getLatestDraft(FulfilmentType type) async {
    final db = await AppDatabase.instance.database;
    final fulfilment = _fulfilmentToDb(type);

    final rows = await db.query(
      'orders',
      where: 'status = ? AND fulfilment_type = ?',
      whereArgs: ['draft', fulfilment],
      orderBy: 'updated_at DESC',
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _draftSessionFromOrder(db, rows.first);
  }

  Future<WalkInSession?> getDraftById(int id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'orders',
      where: 'id = ? AND status = ?',
      whereArgs: [id, 'draft'],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _draftSessionFromOrder(db, rows.first);
  }

  Future<List<DraftOrderSummary>> listDraftOrders({String query = ''}) async {
    final db = await AppDatabase.instance.database;
    final whereParts = <String>['o.status = ?'];
    final whereArgs = <Object?>['draft'];

    final trimmedQuery = query.trim().toLowerCase();
    if (trimmedQuery.isNotEmpty) {
      whereParts.add('''
        (
          LOWER(COALESCE(o.order_no, '')) LIKE ?
          OR LOWER(COALESCE(o.customer_name, '')) LIKE ?
          OR LOWER(COALESCE(o.customer_phone, '')) LIKE ?
          OR CAST(o.id AS TEXT) LIKE ?
        )
      ''');
      final pattern = '%$trimmedQuery%';
      whereArgs.addAll([pattern, pattern, pattern, pattern]);
    }

    final rows = await db.rawQuery('''
      SELECT
        o.id,
        o.order_no,
        o.customer_name,
        o.customer_phone,
        o.fulfilment_type,
        o.grand_total_paise,
        o.created_at,
        o.updated_at,
        COALESCE(SUM(ol.qty), 0) AS item_count
      FROM orders o
      LEFT JOIN order_lines ol ON ol.order_id = o.id
      WHERE ${whereParts.join(' AND ')}
      GROUP BY o.id
      ORDER BY o.updated_at DESC
    ''', whereArgs);

    return rows.map(_toDraftOrderSummary).toList();
  }

  Future<int> countDraftOrders() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
      "SELECT COUNT(*) AS count FROM orders WHERE status = 'draft'",
    );
    return (rows.first['count'] as int?) ?? 0;
  }

  Future<void> deleteDraft(int id) async {
    final db = await AppDatabase.instance.database;
    await db.transaction<void>((txn) async {
      final existing = await txn.query(
        'orders',
        columns: ['id'],
        where: 'id = ? AND status = ?',
        whereArgs: [id, 'draft'],
        limit: 1,
      );
      if (existing.isEmpty) {
        return;
      }

      await txn
          .delete('order_payments', where: 'order_id = ?', whereArgs: [id]);
      await txn.delete('order_lines', where: 'order_id = ?', whereArgs: [id]);
      await txn.delete(
        'order_timeline_events',
        where: 'order_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'orders',
        where: 'id = ? AND status = ?',
        whereArgs: [id, 'draft'],
      );
    });
  }

  Future<WalkInSession> _draftSessionFromOrder(
    Database db,
    Map<String, Object?> order,
  ) async {
    final orderId = order['id'] as int;

    final lines = await db.query(
      'order_lines',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'id ASC',
    );

    final payments = await db.query(
      'order_payments',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'id ASC',
    );

    return WalkInSession(
      draftOrderId: orderId,
      fulfilmentType: _dbToFulfilment(order['fulfilment_type'] as String),
      lines: lines
          .map(
            (row) => WalkInLineItem(
              productId: row['product_id'] as int?,
              designRef: row['design_ref'] as String?,
              description: row['description'] as String,
              quantity: row['qty'] as int,
              unitPricePaise: row['unit_price_paise'] as int,
              gstPercent: row['gst_percent'] as int,
              discountPaise: row['discount_paise'] as int,
              discountType: row['discount_type'] as String?,
              discountValue: row['discount_value'] as int?,
              source: row['source'] as String,
            ),
          )
          .toList(),
      customerPhone: (order['customer_phone'] as String?) ?? '',
      customerName: (order['customer_name'] as String?) ?? '',
      occasion: (order['occasion'] as String?) ?? '',
      scheduledAt: order['scheduled_at'] == null
          ? null
          : DateTime.tryParse(order['scheduled_at'] as String),
      deliverySlot: (order['delivery_slot'] as String?) ?? '',
      recipientName: (order['recipient_name'] as String?) ?? '',
      recipientPhone: (order['recipient_phone'] as String?) ?? '',
      deliveryAddress: (order['delivery_address'] as String?) ?? '',
      deliveryPincode: (order['delivery_pincode'] as String?) ?? '',
      deliveryLandmark: (order['delivery_landmark'] as String?) ?? '',
      cardMessage: (order['card_message'] as String?) ?? '',
      specialInstructions: (order['special_instructions'] as String?) ?? '',
      payments: payments
          .map(
            (row) => PaymentSplit(
              method: _paymentMethodFromCode((row['method'] as String?) ?? ''),
              amountPaise: row['amount_paise'] as int,
              reference: row['reference'] as String?,
              methodCode: row['method'] as String,
            ),
          )
          .toList(),
      billDiscountType: order['bill_discount_type'] as String?,
      billDiscountValue: order['bill_discount_value'] as int?,
    );
  }

  DraftOrderSummary _toDraftOrderSummary(Map<String, Object?> row) {
    return DraftOrderSummary(
      id: row['id'] as int,
      orderNo: (row['order_no'] as String?) ?? 'DRAFT-${row['id']}',
      customerName: (row['customer_name'] as String?)?.trim().isNotEmpty == true
          ? (row['customer_name'] as String).trim()
          : 'Walk-in Customer',
      customerPhone: (row['customer_phone'] as String?)?.trim() ?? '',
      fulfilmentType: _dbToFulfilment(row['fulfilment_type'] as String? ?? ''),
      itemCount: (row['item_count'] as int?) ?? 0,
      grandTotalPaise: (row['grand_total_paise'] as int?) ?? 0,
      createdAt: DateTime.tryParse((row['created_at'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse((row['updated_at'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Future<int> upsertDraft({
    required WalkInSession session,
    required OrderTotals totals,
    required int? customerId,
  }) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final orderNo = 'DRAFT-${DateTime.now().millisecondsSinceEpoch}';

    return db.transaction<int>((txn) async {
      final orderData = {
        'order_no': session.draftOrderId == null ? orderNo : null,
        'fulfilment_type': _fulfilmentToDb(session.fulfilmentType),
        'status': 'draft',
        'customer_id': customerId,
        'customer_phone': session.customerPhone,
        'customer_name': session.customerName,
        'occasion': session.occasion,
        'recipient_name': session.recipientName,
        'recipient_phone': session.recipientPhone,
        'delivery_address': session.deliveryAddress,
        'delivery_pincode': session.deliveryPincode,
        'delivery_landmark': session.deliveryLandmark,
        'card_message': session.cardMessage,
        'special_instructions': session.specialInstructions,
        'scheduled_at': session.scheduledAt?.toIso8601String(),
        'delivery_slot': session.deliverySlot,
        'subtotal_paise': totals.subtotalPaise,
        'gst_total_paise': totals.gstTotalPaise,
        'discount_total_paise': totals.discountTotalPaise,
        'bill_discount_type': session.billDiscountType,
        'bill_discount_value': session.billDiscountValue,
        'round_off_paise': totals.roundOffPaise,
        'grand_total_paise': totals.grandTotalPaise,
        'is_paid': _paidAmountPaiseFromPayments(session.payments) >=
                totals.grandTotalPaise
            ? 1
            : 0,
        'updated_at': now,
        'created_at': now,
      };

      int orderId;
      if (session.draftOrderId == null) {
        final insertMap = Map<String, Object?>.from(orderData)
          ..removeWhere((key, value) => value == null);
        orderId = await txn.insert('orders', insertMap);
        await txn.insert('order_timeline_events', {
          'order_id': orderId,
          'status': 'created',
          'notes': 'Order draft created',
          'created_at': now,
          'created_by': 'walkInManager',
        });
      } else {
        final updateMap = Map<String, Object?>.from(orderData)
          ..remove('order_no')
          ..remove('created_at');
        await txn.update(
          'orders',
          updateMap,
          where: 'id = ?',
          whereArgs: [session.draftOrderId],
        );
        orderId = session.draftOrderId!;
        await txn
            .delete('order_lines', where: 'order_id = ?', whereArgs: [orderId]);
        await txn.delete('order_payments',
            where: 'order_id = ?', whereArgs: [orderId]);
      }

      for (final line in session.lines) {
        final subtotal = line.unitPricePaise * line.quantity;
        final taxable = subtotal - line.discountPaise;
        final gst = (taxable * line.gstPercent) ~/ 100;
        final total = taxable + gst;

        await txn.insert('order_lines', {
          'order_id': orderId,
          'product_id': line.productId,
          'design_ref': line.designRef,
          'description': line.description,
          'qty': line.quantity,
          'unit_price_paise': line.unitPricePaise,
          'gst_percent': line.gstPercent,
          'discount_paise': line.discountPaise,
          'discount_type': line.discountType,
          'discount_value': line.discountValue,
          'line_subtotal_paise': subtotal,
          'line_gst_paise': gst,
          'line_total_paise': total,
          'source': line.source,
        });
      }

      for (final payment in session.payments) {
        await txn.insert('order_payments', {
          'order_id': orderId,
          'method': payment.persistenceMethod,
          'amount_paise': payment.amountPaise,
          'reference': payment.reference,
          'created_at': now,
        });
      }

      return orderId;
    });
  }

  Future<ConfirmedOrder> confirmDraft({required int orderId}) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    return db.transaction<ConfirmedOrder>((txn) async {
      final orderNo = 'ORD-${DateTime.now().millisecondsSinceEpoch}';
      await txn.update(
        'orders',
        {
          'status': 'confirmed',
          'order_no': orderNo,
          'confirmed_at': now,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [orderId],
      );

      await txn.insert('order_timeline_events', {
        'order_id': orderId,
        'status': 'confirmed',
        'notes': 'Order confirmed from walk-in',
        'created_at': now,
        'created_by': 'walkInManager',
      });

      final lines = await txn.query(
        'order_lines',
        columns: ['id', 'product_id', 'qty'],
        where: 'order_id = ?',
        whereArgs: [orderId],
      );

      final lineProductLinks = <Map<String, int>>[];
      for (final line in lines) {
        final productId = line['product_id'] as int?;
        if (productId == null) {
          continue;
        }
        lineProductLinks.add({
          'orderLineId': line['id'] as int,
          'productId': productId,
          'qty': line['qty'] as int,
        });
      }

      return ConfirmedOrder(
          orderId: orderId, lineProductLinks: lineProductLinks);
    });
  }

  Future<Map<String, Object?>> getOrderSummary(int orderId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('orders',
        where: 'id = ?', whereArgs: [orderId], limit: 1);
    if (rows.isEmpty) {
      return {};
    }
    return rows.first;
  }

  OrderListItem _toListItem(Map<String, Object?> row) {
    return OrderListItem(
      id: row['id'] as int,
      orderNo: (row['order_no'] as String?) ?? '-',
      customerName: (row['customer_name'] as String?) ?? '-',
      customerPhone: (row['customer_phone'] as String?) ?? '-',
      recipientName: (row['recipient_name'] as String?) ?? '-',
      designerName: row['designer_name'] as String?,
      deliveryName: row['delivery_name'] as String?,
      source: (row['source'] as String?) ?? 'walkIn',
      fulfilmentType: (row['fulfilment_type'] as String?) ?? 'delivery',
      status: (row['status'] as String?) ?? 'draft',
      grandTotalPaise: (row['grand_total_paise'] as int?) ?? 0,
      createdAt: DateTime.tryParse((row['created_at'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      scheduledAt: row['scheduled_at'] == null
          ? null
          : DateTime.tryParse(row['scheduled_at'] as String),
      isPaid: (row['is_paid'] as int?) ?? 0,
    );
  }

  Future<List<OrderListItem>> getOrdersForWorkspace({
    required String tab,
    required String searchQuery,
    required OrderWorkspaceFilters filters,
    int limit = 200,
    int offset = 0,
  }) async {
    final db = await AppDatabase.instance.database;
    final whereParts = <String>['1 = 1'];
    final whereArgs = <Object?>[];

    if (filters.selectedDate == null && tab != 'all') {
      final tabStatuses = switch (tab) {
        'pending' => const ['draft', 'confirmed'],
        'in_progress' => const ['preparing', 'out_for_delivery'],
        'ready' => const ['ready'],
        'completed' => const ['delivered', 'cancelled'],
        _ => const [
            'draft',
            'confirmed',
            'preparing',
            'ready',
            'out_for_delivery',
            'delivered',
            'cancelled'
          ],
      };

      whereParts
          .add('status IN (${List.filled(tabStatuses.length, '?').join(',')})');
      whereArgs.addAll(tabStatuses);
    }

    if (filters.today) {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day).toIso8601String();
      final end = DateTime(now.year, now.month, now.day)
          .add(const Duration(days: 1))
          .toIso8601String();
      whereParts.add(
          '((scheduled_at >= ? AND scheduled_at < ?) OR (created_at >= ? AND created_at < ?))');
      whereArgs.addAll([start, end, start, end]);
    }

    if (filters.selectedDate != null) {
      final date = filters.selectedDate!;
      final day = DateTime(date.year, date.month, date.day)
          .toIso8601String()
          .substring(0, 10);
      whereParts.add('(date(scheduled_at) = ? OR date(created_at) = ?)');
      whereArgs.addAll([day, day]);
    }

    if (filters.pending) {
      whereParts.add(
          "status IN ('draft', 'confirmed', 'preparing', 'ready', 'out_for_delivery')");
    }
    if (filters.completed) {
      whereParts.add("status = 'delivered'");
    }
    if (filters.cancelled) {
      whereParts.add("status = 'cancelled'");
    }
    if (filters.delivery) {
      whereParts.add("fulfilment_type = 'delivery'");
    }
    if (filters.pickup) {
      whereParts.add("fulfilment_type = 'pickup_later'");
    }
    if (filters.takeAway) {
      whereParts.add("fulfilment_type = 'take_away'");
    }
    if (filters.relay) {
      whereParts.add("source IN ('relayIn', 'relayOut')");
    }
    if (filters.corporate) {
      whereParts
          .add('(channel = \'corporate\' OR corporate_account IS NOT NULL)');
    }
    if (filters.marketplace) {
      whereParts
          .add('(channel = \'marketplace\' OR marketplace_name IS NOT NULL)');
    }
    if (filters.paid) {
      whereParts.add('is_paid = 1');
    }
    if (filters.unpaid) {
      whereParts.add('is_paid = 0');
    }

    final q = searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      whereParts.add('('
          'LOWER(order_no) LIKE ? OR '
          'LOWER(COALESCE(customer_name, "")) LIKE ? OR '
          'LOWER(COALESCE(customer_phone, "")) LIKE ? OR '
          'LOWER(COALESCE(recipient_name, "")) LIKE ? OR '
          'LOWER(COALESCE(relay_partner_name, "")) LIKE ? OR '
          'LOWER(COALESCE(website_order_number, "")) LIKE ? OR '
          'LOWER(COALESCE(marketplace_order_id, "")) LIKE ? OR '
          'LOWER(COALESCE(relay_token, "")) LIKE ?'
          ')');
      final like = '%$q%';
      whereArgs.addAll([like, like, like, like, like, like, like, like]);
    }

    final rows = await db.rawQuery('''
      SELECT
        o.id,
        o.order_no,
        o.customer_name,
        o.customer_phone,
        o.recipient_name,
        o.source,
        o.fulfilment_type,
        o.status,
        o.grand_total_paise,
        o.created_at,
        o.scheduled_at,
        o.is_paid,
        (
          SELECT s.name FROM order_workflow_assignments owa
          JOIN staff s ON s.id = owa.associate_id
          WHERE owa.order_id = o.id AND owa.assignment_type = 'designer'
          LIMIT 1
        ) AS designer_name,
        (
          SELECT s.name FROM order_workflow_assignments owa
          JOIN staff s ON s.id = owa.associate_id
          WHERE owa.order_id = o.id AND owa.assignment_type = 'delivery'
          LIMIT 1
        ) AS delivery_name
      FROM orders o
      WHERE ${whereParts.join(' AND ')}
      ORDER BY COALESCE(o.scheduled_at, o.created_at) DESC
      LIMIT $limit OFFSET $offset
    ''', whereArgs);

    return rows.map(_toListItem).toList();
  }

  Future<void> updateOrderFromSession({
    required int orderId,
    required WalkInSession session,
    required OrderTotals totals,
    required int? customerId,
  }) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    return db.transaction((txn) async {
      final existingRows = await txn.query(
        'orders',
        columns: ['status'],
        where: 'id = ?',
        whereArgs: [orderId],
        limit: 1,
      );
      if (existingRows.isEmpty) {
        throw StateError('Order $orderId not found');
      }

      final existingStatus =
          (existingRows.first['status'] as String?) ?? 'draft';
      if (existingStatus == 'delivered' || existingStatus == 'cancelled') {
        throw StateError('Delivered and cancelled orders are read-only');
      }

      final updateMap = <String, Object?>{
        'fulfilment_type': _fulfilmentToDb(session.fulfilmentType),
        'customer_id': customerId,
        'customer_phone': session.customerPhone,
        'customer_name': session.customerName,
        'occasion': session.occasion,
        'recipient_name': session.recipientName,
        'recipient_phone': session.recipientPhone,
        'delivery_address': session.deliveryAddress,
        'delivery_pincode': session.deliveryPincode,
        'delivery_landmark': session.deliveryLandmark,
        'card_message': session.cardMessage,
        'special_instructions': session.specialInstructions,
        'scheduled_at': session.scheduledAt?.toIso8601String(),
        'delivery_slot': session.deliverySlot,
        'subtotal_paise': totals.subtotalPaise,
        'gst_total_paise': totals.gstTotalPaise,
        'discount_total_paise': totals.discountTotalPaise,
        'bill_discount_type': session.billDiscountType,
        'bill_discount_value': session.billDiscountValue,
        'round_off_paise': totals.roundOffPaise,
        'grand_total_paise': totals.grandTotalPaise,
        'is_paid': _paidAmountPaiseFromPayments(session.payments) >=
                totals.grandTotalPaise
            ? 1
            : 0,
        'updated_at': now,
      };

      await txn.update(
        'orders',
        updateMap,
        where: 'id = ?',
        whereArgs: [orderId],
      );

      await txn
          .delete('order_lines', where: 'order_id = ?', whereArgs: [orderId]);
      await txn.delete('order_payments',
          where: 'order_id = ?', whereArgs: [orderId]);

      for (final line in session.lines) {
        final subtotal = line.unitPricePaise * line.quantity;
        final taxable = subtotal - line.discountPaise;
        final gst = (taxable * line.gstPercent) ~/ 100;
        final total = taxable + gst;

        await txn.insert('order_lines', {
          'order_id': orderId,
          'product_id': line.productId,
          'design_ref': line.description,
          'description': line.description,
          'qty': line.quantity,
          'unit_price_paise': line.unitPricePaise,
          'gst_percent': line.gstPercent,
          'discount_paise': line.discountPaise,
          'discount_type': line.discountType,
          'discount_value': line.discountValue,
          'line_subtotal_paise': subtotal,
          'line_gst_paise': gst,
          'line_total_paise': total,
          'source': line.source,
        });
      }

      for (final payment in session.payments) {
        await txn.insert('order_payments', {
          'order_id': orderId,
          'method': payment.persistenceMethod,
          'amount_paise': payment.amountPaise,
          'reference': payment.reference,
          'created_at': now,
        });
      }

      await txn.insert('order_timeline_events', {
        'order_id': orderId,
        'status': 'workflow_note',
        'notes': 'Order details updated',
        'created_at': now,
        'created_by': 'walkInManager',
      });
    });
  }

  Future<OrderDetailHeader?> getOrderDetailHeader(int orderId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT o.*,
        COALESCE((
          SELECT SUM(op.amount_paise)
          FROM order_payments op
          WHERE op.order_id = o.id AND LOWER(COALESCE(op.method, '')) != 'credit'
        ), 0) AS paid_amount_paise,
        (
          SELECT s.name FROM order_workflow_assignments owa
          JOIN staff s ON s.id = owa.associate_id
          WHERE owa.order_id = o.id AND owa.assignment_type = 'designer'
          LIMIT 1
        ) AS designer_name,
        (
          SELECT s.name FROM order_workflow_assignments owa
          JOIN staff s ON s.id = owa.associate_id
          WHERE owa.order_id = o.id AND owa.assignment_type = 'delivery'
          LIMIT 1
        ) AS delivery_name
      FROM orders o
      WHERE o.id = ?
      LIMIT 1
      ''',
      [orderId],
    );
    if (rows.isEmpty) {
      return null;
    }

    final row = rows.first;
    return OrderDetailHeader(
      id: orderId,
      orderNo: (row['order_no'] as String?) ?? '-',
      status: (row['status'] as String?) ?? 'draft',
      customerName: (row['customer_name'] as String?) ?? '-',
      customerPhone: (row['customer_phone'] as String?) ?? '-',
      recipientName: (row['recipient_name'] as String?) ?? '-',
      recipientPhone: (row['recipient_phone'] as String?) ?? '-',
      fulfilmentType: (row['fulfilment_type'] as String?) ?? 'delivery',
      source: (row['source'] as String?) ?? 'walkIn',
      grandTotalPaise: (row['grand_total_paise'] as int?) ?? 0,
      address: (row['delivery_address'] as String?) ?? '-',
      scheduledAt: row['scheduled_at'] == null
          ? null
          : DateTime.tryParse(row['scheduled_at'] as String),
      occasion: (row['occasion'] as String?) ?? '-',
      deliverySlot: (row['delivery_slot'] as String?) ?? '-',
      cardMessage: (row['card_message'] as String?) ?? '',
      isPaid: (row['is_paid'] as int?) ?? 0,
      paidAmountPaise: (row['paid_amount_paise'] as int?) ?? 0,
      deliveryPincode: (row['delivery_pincode'] as String?) ?? '',
      deliveryLandmark: (row['delivery_landmark'] as String?) ?? '',
      specialInstructions: (row['special_instructions'] as String?) ?? '',
      designerName: row['designer_name'] as String?,
      deliveryName: row['delivery_name'] as String?,
    );
  }

  Future<List<Map<String, Object?>>> getOrderLines(int orderId) async {
    final db = await AppDatabase.instance.database;
    return db.rawQuery('''
      SELECT
        ol.*,
        p.name AS product_name,
        NULL AS product_image_path
      FROM order_lines ol
      LEFT JOIN products p ON p.id = ol.product_id
      WHERE ol.order_id = ?
      ORDER BY ol.id ASC
    ''', [orderId]);
  }

  Future<List<Map<String, Object?>>> getOrderPayments(int orderId) async {
    final db = await AppDatabase.instance.database;
    return db
        .query('order_payments', where: 'order_id = ?', whereArgs: [orderId]);
  }

  Future<List<OrderTimelineItem>> getOrderTimeline(int orderId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'order_timeline_events',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'created_at DESC',
    );
    return rows
        .map(
          (row) => OrderTimelineItem(
            status: row['status'] as String,
            notes: row['notes'] as String?,
            createdAt:
                DateTime.tryParse((row['created_at'] as String?) ?? '') ??
                    DateTime.fromMillisecondsSinceEpoch(0),
          ),
        )
        .toList();
  }

  Future<List<Map<String, Object?>>> getSchedulerTasksForOrder(
      int orderId) async {
    final db = await AppDatabase.instance.database;
    return db.query(
      'scheduler_tasks',
      where: 'linked_order_id = ? AND deleted_at IS NULL',
      whereArgs: [orderId],
      orderBy: 'scheduled_at DESC',
    );
  }

  Future<List<Map<String, Object?>>> getInventoryImpactForOrder(
      int orderId) async {
    final db = await AppDatabase.instance.database;
    return db.query(
      'inventory_transactions',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'created_at DESC',
    );
  }

  Future<String?> getReceiptStatus(int orderId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'receipt_jobs',
      columns: ['status'],
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['status'] as String?;
  }

  Future<String?> getWhatsappStatus(int orderId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'whatsapp_share_jobs',
      columns: ['status'],
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['status'] as String?;
  }

  Future<Map<String, Object?>> getSourceMetadata(int orderId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('orders',
        where: 'id = ?', whereArgs: [orderId], limit: 1);
    if (rows.isEmpty) {
      return {};
    }
    final row = rows.first;
    return {
      'relay_partner_name': row['relay_partner_name'],
      'relay_partner_phone': row['relay_partner_phone'],
      'relay_partner_email': row['relay_partner_email'],
      'relay_partner_order_number': row['relay_partner_order_number'],
      'relay_token': row['relay_token'],
      'relay_status': row['relay_status'],
      'settlement_status': row['settlement_status'],
      'settlement_amount_paise': row['settlement_amount_paise'],
      'commission_amount_paise': row['commission_amount_paise'],
      'corporate_account': row['corporate_account'],
      'corporate_department': row['corporate_department'],
      'corporate_employee_name': row['corporate_employee_name'],
      'corporate_occasion': row['corporate_occasion'],
      'marketplace_name': row['marketplace_name'],
      'marketplace_order_id': row['marketplace_order_id'],
      'marketplace_status': row['marketplace_status'],
    };
  }

  Future<void> updateOrderStatus({
    required int orderId,
    required String newStatus,
    String? notes,
    required String createdBy,
  }) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      await txn.update(
        'orders',
        {
          'status': newStatus,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [orderId],
      );

      await txn.insert('order_timeline_events', {
        'order_id': orderId,
        'status': newStatus,
        'notes': notes,
        'created_at': now,
        'created_by': createdBy,
      });
    });
  }

  Future<void> updateRelayMetadata({
    required int orderId,
    required Map<String, Object?> relay,
  }) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'orders',
      {
        ...relay,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  Future<void> prepareRelayActionLinks({
    required int orderId,
    required String relayToken,
  }) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final actions = [
      'accept',
      'out_for_delivery',
      'delivered',
      'unable_to_deliver'
    ];

    await db.delete('relay_action_links',
        where: 'order_id = ?', whereArgs: [orderId]);

    for (final action in actions) {
      await db.insert('relay_action_links', {
        'order_id': orderId,
        'relay_token': relayToken,
        'action_name': action,
        'secure_link_path': '/relay/action/$relayToken/$action',
        'template_channel': 'whatsapp_email',
        'status': 'prepared',
        'created_at': now,
      });
    }
  }

  Future<Map<String, int>> getTodaySummary() async {
    final db = await AppDatabase.instance.database;
    final today = DateTime.now();
    final startOfDay =
        DateTime(today.year, today.month, today.day).toIso8601String();
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59)
        .toIso8601String();

    final salesResult = await db.rawQuery('''
      SELECT COALESCE(SUM(grand_total_paise), 0) as total
      FROM orders
      WHERE status IN ('confirmed', 'preparing', 'ready', 'out_for_delivery', 'delivered')
      AND created_at >= ? AND created_at <= ?
    ''', [startOfDay, endOfDay]);

    final orderCountResult = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM orders
      WHERE status IN ('confirmed', 'preparing', 'ready', 'out_for_delivery', 'delivered')
      AND created_at >= ? AND created_at <= ?
    ''', [startOfDay, endOfDay]);

    final pendingResult = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM orders
      WHERE status = 'confirmed'
    ''');

    final preparingResult = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM orders
      WHERE status = 'preparing'
    ''');

    final readyResult = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM orders
      WHERE status = 'ready'
    ''');

    final outForDeliveryResult = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM orders
      WHERE status = 'out_for_delivery'
    ''');

    final todayDeliveryResult = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM orders
      WHERE fulfilment_type = 'delivery'
      AND status IN ('confirmed', 'preparing', 'ready', 'out_for_delivery')
      AND scheduled_at >= ? AND scheduled_at <= ?
    ''', [startOfDay, endOfDay]);

    final todayPickupResult = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM orders
      WHERE fulfilment_type = 'pickup_later'
      AND status IN ('confirmed', 'preparing', 'ready')
      AND scheduled_at >= ? AND scheduled_at <= ?
    ''', [startOfDay, endOfDay]);

    return {
      'todaySalesAmount': salesResult.first['total'] as int,
      'todayOrderCount': orderCountResult.first['count'] as int,
      'pendingOrders': pendingResult.first['count'] as int,
      'preparingOrders': preparingResult.first['count'] as int,
      'readyOrders': readyResult.first['count'] as int,
      'outForDeliveryOrders': outForDeliveryResult.first['count'] as int,
      'todayDeliveryCount': todayDeliveryResult.first['count'] as int,
      'todayPickupCount': todayPickupResult.first['count'] as int,
    };
  }

  Future<Map<String, dynamic>> getCustomerStatistics(
    int customerId, {
    String? customerPhone,
  }) async {
    final stats = await getCustomerOrderStatistics(
      customerId: customerId,
      customerPhone: customerPhone,
    );
    return stats.toCardMap();
  }

  Future<CustomerOrderStatistics> getCustomerOrderStatistics({
    int? customerId,
    String? customerPhone,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await AppDatabase.instance.database;
    final where = <String>[
      'o.status IN (${List.filled(customerStatisticsStatuses.length, '?').join(',')})',
    ];
    final args = <Object?>[...customerStatisticsStatuses];
    final normalizedPhone = _normalizePhone(customerPhone);

    if (customerId != null && normalizedPhone.isNotEmpty) {
      where.add(
        '(o.customer_id = ? OR (o.customer_id IS NULL AND o.customer_phone = ?))',
      );
      args.addAll([customerId, normalizedPhone]);
    } else if (customerId != null) {
      where.add('o.customer_id = ?');
      args.add(customerId);
    } else if (normalizedPhone.isNotEmpty) {
      where.add('o.customer_phone = ?');
      args.add(normalizedPhone);
    } else {
      return const CustomerOrderStatistics(
        customerId: null,
        customerName: '',
        customerPhone: '',
        previousOrders: 0,
        lifetimePurchasePaise: 0,
        lastOrderDate: null,
        favouriteDesign: null,
      );
    }

    _addCustomerStatsDateFilter(where, args, startDate, endDate);
    final whereSql = where.join(' AND ');

    final summaryResult = await db.rawQuery('''
      SELECT
        COUNT(*) AS order_count,
        COALESCE(SUM(o.grand_total_paise), 0) AS total_purchase,
        MAX(o.created_at) AS last_order_date,
        COALESCE(c.name, o.customer_name, '') AS customer_name,
        COALESCE(c.phone, o.customer_phone, '') AS customer_phone
      FROM orders o
      LEFT JOIN customers c ON c.id = o.customer_id
      WHERE $whereSql
    ''', args);

    final favouriteDesignResult = await db.rawQuery('''
      SELECT design_name
      FROM (
        SELECT
          COALESCE(NULLIF(TRIM(p.name), ''), NULLIF(TRIM(ol.description), '')) AS design_name,
          COUNT(*) AS order_count
        FROM order_lines ol
        JOIN orders o ON ol.order_id = o.id
        LEFT JOIN products p ON p.id = ol.product_id
        WHERE $whereSql
        GROUP BY design_name
        HAVING design_name IS NOT NULL AND design_name <> ''
        ORDER BY order_count DESC, design_name COLLATE NOCASE ASC
        LIMIT 1
      )
    ''', args);

    final row = summaryResult.first;
    return CustomerOrderStatistics(
      customerId: customerId,
      customerName: (row['customer_name'] as String?) ?? '',
      customerPhone: (row['customer_phone'] as String?) ?? normalizedPhone,
      previousOrders: (row['order_count'] as int?) ?? 0,
      lifetimePurchasePaise: (row['total_purchase'] as int?) ?? 0,
      lastOrderDate: row['last_order_date'] as String?,
      favouriteDesign: favouriteDesignResult.isNotEmpty
          ? favouriteDesignResult.first['design_name'] as String?
          : null,
    );
  }

  Future<List<CustomerOrderStatistics>> getTopCustomerStatistics({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
  }) async {
    final db = await AppDatabase.instance.database;
    final where = <String>[
      'o.status IN (${List.filled(customerStatisticsStatuses.length, '?').join(',')})',
      "(o.customer_id IS NOT NULL OR TRIM(COALESCE(o.customer_phone, '')) <> '')",
    ];
    final args = <Object?>[...customerStatisticsStatuses];
    _addCustomerStatsDateFilter(where, args, startDate, endDate);

    final rows = await db.rawQuery('''
      SELECT
        COALESCE(o.customer_id, phone_customer.id) AS customer_id,
        COALESCE(c.name, phone_customer.name, o.customer_name, '') AS customer_name,
        COALESCE(c.phone, phone_customer.phone, o.customer_phone, '') AS customer_phone,
        COUNT(*) AS order_count,
        COALESCE(SUM(o.grand_total_paise), 0) AS total_purchase,
        MAX(o.created_at) AS last_order_date
      FROM orders o
      LEFT JOIN customers c ON c.id = o.customer_id
      LEFT JOIN customers phone_customer
        ON o.customer_id IS NULL
       AND phone_customer.deleted_at IS NULL
       AND phone_customer.phone = o.customer_phone
      WHERE ${where.join(' AND ')}
      GROUP BY CASE
        WHEN COALESCE(o.customer_id, phone_customer.id) IS NOT NULL
          THEN 'id:' || COALESCE(o.customer_id, phone_customer.id)
        ELSE 'phone:' || o.customer_phone
      END
      ORDER BY total_purchase DESC, order_count DESC, customer_name COLLATE NOCASE ASC
      LIMIT ?
    ''', [...args, limit]);

    return rows
        .map(
          (row) => CustomerOrderStatistics(
            customerId: row['customer_id'] as int?,
            customerName: (row['customer_name'] as String?) ?? '',
            customerPhone: (row['customer_phone'] as String?) ?? '',
            previousOrders: (row['order_count'] as int?) ?? 0,
            lifetimePurchasePaise: (row['total_purchase'] as int?) ?? 0,
            lastOrderDate: row['last_order_date'] as String?,
            favouriteDesign: null,
          ),
        )
        .toList();
  }

  void _addCustomerStatsDateFilter(
    List<String> where,
    List<Object?> args,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    if (startDate != null) {
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      where.add('o.created_at >= ?');
      args.add(start.toIso8601String());
    }

    if (endDate != null) {
      final end = DateTime(endDate.year, endDate.month, endDate.day)
          .add(const Duration(days: 1));
      where.add('o.created_at < ?');
      args.add(end.toIso8601String());
    }
  }

  String _normalizePhone(String? raw) {
    final digits = (raw ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 10) {
      return digits.substring(digits.length - 10);
    }
    return digits;
  }
}
