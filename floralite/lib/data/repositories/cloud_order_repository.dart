import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../models/cloud_order_status_report.dart';
import '../../models/order_workspace_models.dart';
import '../../services/mobile_auth_service.dart';
import 'cloud_order_status_repository.dart';

typedef CloudOrderHttpSender = Future<dynamic> Function(
  String method,
  Uri uri, {
  Map<String, dynamic>? body,
});

/// Carries the failing request identity so a Cloud error can be diagnosed from
/// the device instead of showing only the server's generic message.
class CloudOrderRequestException implements Exception {
  const CloudOrderRequestException({
    required this.method,
    required this.path,
    required this.statusCode,
    required this.serverMessage,
    required this.responseBody,
    this.traceId,
  });

  final String method;
  final String path;
  final int statusCode;
  final String? serverMessage;
  final String responseBody;
  final String? traceId;

  @override
  String toString() {
    final detail = serverMessage?.trim().isNotEmpty == true
        ? serverMessage!.trim()
        : (responseBody.trim().isEmpty ? 'no response body' : responseBody.trim());
    final trace = traceId == null ? '' : ' [traceId $traceId]';
    return '$method $path failed (HTTP $statusCode): $detail$trace';
  }
}

class CloudAssignee {
  const CloudAssignee({
    required this.staffId,
    required this.name,
    required this.role,
    this.phone,
  });

  final String staffId;
  final String name;
  final String role;
  final String? phone;
}

/// A single replacement line for `PUT /api/orders/{id}/items`.
class CloudOrderItemInput {
  const CloudOrderItemInput({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPricePaise,
    this.discountAmountPaise = 0,
    this.discountType,
    this.discountValue,
    this.taxRatePercent,
    this.specialInstructions,
    this.clientOrderLineId,
  });

  final String productId;
  final String productName;
  final int quantity;
  final int unitPricePaise;
  final int discountAmountPaise;
  final String? discountType;
  final int? discountValue;
  final int? taxRatePercent;
  final String? specialInstructions;
  final String? clientOrderLineId;

  int get lineSubtotalPaise =>
      (quantity * unitPricePaise) - discountAmountPaise;

  int get lineTaxPaise => taxRatePercent == null
      ? 0
      : (lineSubtotalPaise * taxRatePercent! / 100).round();

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'unitPrice': unitPricePaise / 100,
        'discountAmount': discountAmountPaise / 100,
        if (discountType != null) 'discountType': discountType,
        if (discountValue != null) 'discountValue': discountValue! / 100,
        if (taxRatePercent != null) 'taxRatePercent': taxRatePercent,
        'lineSubtotal': lineSubtotalPaise / 100,
        'lineTaxAmount': lineTaxPaise / 100,
        if (specialInstructions != null)
          'specialInstructions': specialInstructions,
        if (clientOrderLineId != null) 'clientOrderLineId': clientOrderLineId,
      };
}

class CloudOrderRepository {
  CloudOrderRepository({
    MobileAuthService? auth,
    CloudOrderHttpSender? sender,
    CloudOrderStatusRepository? statusRepository,
  })  : _auth = auth ?? MobileAuthService(),
        _sender = sender,
        _statusRepository = statusRepository ??
            CloudOrderStatusRepository(auth: auth ?? MobileAuthService());

  final MobileAuthService _auth;
  final CloudOrderHttpSender? _sender;
  final CloudOrderStatusRepository _statusRepository;

  Future<CloudOrderStatusReport> getOrderStatusReport({
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return _statusRepository.getOrderStatusReport(
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  Future<List<OrderListItem>> getWorkspace({
    required String tab,
    required String searchQuery,
    required OrderWorkspaceFilters filters,
    int limit = 200,
    int offset = 0,
  }) async {
    final pageSize = limit.clamp(1, 200);
    final page = (offset ~/ pageSize) + 1;
    final queryParameters = <String, String>{
      'page': '$page',
      'pageSize': '$pageSize',
      if (searchQuery.trim().isNotEmpty) 'query': searchQuery.trim(),
      if (_statusForTab(tab, filters) != null) 'status': _statusForTab(tab, filters)!,
      if (filters.selectedDate != null)
        'deliveryDate': _dateQueryValue(filters.selectedDate!),
      if (filters.delivery) 'fulfilmentType': 'delivery',
      if (filters.pickup) 'fulfilmentType': 'pickup_later',
      if (filters.takeAway) 'fulfilmentType': 'take_away',
      if (filters.paid) 'paymentStatus': 'paid',
      if (filters.unpaid) 'paymentStatus': 'unpaid',
    };

    final response = await _send(
      'GET',
      Uri.parse('${_auth.baseUrl}/api/v1/mobile/orders/workspace')
          .replace(queryParameters: queryParameters),
    );
    final responseMap = response is Map ? response.cast<String, dynamic>() : null;
    final rawItems = responseMap?[_key(responseMap, 'items')];
    if (rawItems is! List) return const [];

    return rawItems
        .whereType<Map>()
        .map((row) => _listItem(row.cast<String, dynamic>()))
        .toList();
  }

  Future<OrderDetailBundle?> getDetail(String cloudOrderId) async {
    final id = cloudOrderId.trim();
    if (id.isEmpty) return null;
    final response = await _send(
      'GET',
      Uri.parse('${_auth.baseUrl}/api/v1/mobile/orders/$id'),
    );
    if (response is! Map) return null;
    return _detailBundle(response.cast<String, dynamic>());
  }

  Future<OrderDetailBundle?> getDetailByOrderNumber(String orderNumber) async {
    final normalized = orderNumber.trim();
    if (normalized.isEmpty) return null;
    final response = await _send(
      'GET',
      Uri.parse(
        '${_auth.baseUrl}/api/v1/mobile/orders/by-number/'
        '${Uri.encodeComponent(normalized)}',
      ),
    );
    if (response is! Map) return null;
    return _detailBundle(response.cast<String, dynamic>());
  }

  Future<void> updateStatus({
    required String cloudOrderId,
    required String status,
  }) async {
    await _send(
      'PATCH',
      Uri.parse('${_auth.baseUrl}/api/orders/${Uri.encodeComponent(cloudOrderId)}/status'),
      body: {'status': _cloudStatus(status)},
    );
  }

  Future<List<CloudAssignee>> getDesigners() async {
    final response = await _send(
      'GET',
      Uri.parse('${_auth.baseUrl}/api/staff/by-role/Designer'),
    );
    return _assignees(response);
  }

  Future<List<CloudAssignee>> getDrivers() async {
    final response = await _send(
      'GET',
      Uri.parse('${_auth.baseUrl}/api/staff/available-drivers'),
    );
    return _assignees(response);
  }

  Future<void> assignDesigner({
    required String cloudOrderId,
    required String staffId,
  }) async {
    await _send(
      'POST',
      Uri.parse(
        '${_auth.baseUrl}/api/orders/${Uri.encodeComponent(cloudOrderId.trim())}'
        '/assign-designer',
      ),
      body: {'staffId': staffId.trim()},
    );
  }

  Future<void> assignDriver({
    required String cloudOrderId,
    required String staffId,
  }) async {
    await _send(
      'POST',
      Uri.parse(
        '${_auth.baseUrl}/api/orders/${Uri.encodeComponent(cloudOrderId.trim())}'
        '/assign-driver',
      ),
      body: {'staffId': staffId.trim()},
    );
  }

  Future<void> updateDetails({
    required String cloudOrderId,
    DateTime? deliveryDate,
    String? timeSlot,
    String? deliveryAddress,
    String? deliveryPincode,
    String? recipientName,
    String? recipientPhone,
    String? cardMessage,
  }) async {
    final body = <String, dynamic>{
      if (deliveryDate != null)
        'deliveryDate': _utcIso(deliveryDate),
      if (timeSlot != null) 'timeSlot': timeSlot,
      if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
      if (deliveryPincode != null) 'deliveryPincode': deliveryPincode,
      if (recipientName != null) 'recipientName': recipientName,
      if (recipientPhone != null) 'recipientPhone': recipientPhone,
      if (cardMessage != null) 'cardMessage': cardMessage,
    };
    if (body.isEmpty) return;

    await _send(
      'PATCH',
      Uri.parse(
        '${_auth.baseUrl}/api/orders/${Uri.encodeComponent(cloudOrderId.trim())}'
        '/details',
      ),
      body: body,
    );
  }

  Future<void> replaceItems({
    required String cloudOrderId,
    required List<CloudOrderItemInput> items,
  }) async {
    if (items.isEmpty) {
      throw StateError('An order must keep at least one item.');
    }
    final taxPaise = items.fold<int>(0, (sum, item) => sum + item.lineTaxPaise);

    await _send(
      'PUT',
      Uri.parse(
        '${_auth.baseUrl}/api/orders/${Uri.encodeComponent(cloudOrderId.trim())}'
        '/items',
      ),
      body: {
        'items': items.map((item) => item.toJson()).toList(),
        'taxAmount': taxPaise / 100,
      },
    );
  }

  Future<void> updateFinancials({
    required String cloudOrderId,
    int? discountAmountPaise,
    int? deliveryFeePaise,
    int? rewardPointsRedeemed,
    int? rewardDiscountAmountPaise,
  }) async {
    final body = <String, dynamic>{
      if (discountAmountPaise != null)
        'discountAmount': discountAmountPaise / 100,
      if (deliveryFeePaise != null) 'deliveryFee': deliveryFeePaise / 100,
      if (rewardPointsRedeemed != null)
        'rewardPointsRedeemed': rewardPointsRedeemed,
      if (rewardDiscountAmountPaise != null)
        'rewardDiscountAmount': rewardDiscountAmountPaise / 100,
    };
    if (body.isEmpty) return;

    await _send(
      'PATCH',
      Uri.parse(
        '${_auth.baseUrl}/api/orders/${Uri.encodeComponent(cloudOrderId.trim())}'
        '/financials',
      ),
      body: body,
    );
  }

  Future<void> collectPayment({
    required String cloudOrderId,
    required String method,
    required int amountPaise,
  }) async {
    if (amountPaise <= 0) {
      throw StateError('Payment amount must be greater than zero.');
    }
    final now = DateTime.now();
    await _send(
      'POST',
      Uri.parse('${_auth.baseUrl}/api/payments'),
      body: {
        'orderId': cloudOrderId.trim(),
        'method': _cloudPaymentMethod(method),
        'amount': amountPaise / 100,
        'paymentDate':
            DateTime.utc(now.year, now.month, now.day).toIso8601String(),
      },
    );
  }

  Future<void> cancel({
    required String cloudOrderId,
    String? reason,
  }) async {
    await _send(
      'POST',
      Uri.parse('${_auth.baseUrl}/api/orders/${Uri.encodeComponent(cloudOrderId)}/cancel'),
      body: {
        if (reason?.trim().isNotEmpty == true) 'reason': reason!.trim(),
      },
    );
  }

  Future<dynamic> _send(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    final override = _sender;
    if (override != null) return override(method, uri, body: body);

    var token = await _auth.getStoredAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw StateError('Cloud session is not available. Please log in again.');
    }

    debugPrint('[ORDERS-CLOUD] $method $uri');
    for (var attempt = 0; attempt < 2; attempt++) {
      final client = HttpClient();
      try {
        final request = await client.openUrl(method, uri).timeout(
              const Duration(seconds: 12),
            );
        request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
        if (body != null) {
          request.headers.contentType = ContentType.json;
          request.write(jsonEncode(body));
        }

        final response =
            await request.close().timeout(const Duration(seconds: 20));
        final responseBody = await response.transform(utf8.decoder).join();
        debugPrint('[ORDERS-CLOUD] HTTP STATUS: ${response.statusCode}');

        if (response.statusCode == 401 && attempt == 0) {
          final refreshed = await _auth.refreshAndBootstrap();
          token = refreshed.accessToken;
          continue;
        }

        final decoded = responseBody.trim().isEmpty
            ? <String, dynamic>{}
            : _decode(responseBody);
        if (response.statusCode < 200 || response.statusCode >= 300) {
          debugPrint(
            '[ORDERS-CLOUD] FAILED $method ${uri.path} -> '
            '${response.statusCode} body: $responseBody',
          );
          final map = decoded is Map ? decoded : const {};
          throw CloudOrderRequestException(
            method: method,
            path: uri.path,
            statusCode: response.statusCode,
            serverMessage: (map['message'] ??
                    map['detail'] ??
                    map['title'] ??
                    map['error'])
                ?.toString(),
            responseBody: responseBody,
            traceId: map['traceId']?.toString(),
          );
        }
        return decoded;
      } on SocketException catch (error) {
        throw StateError('Unable to connect to Floraprise Cloud: $error');
      } finally {
        client.close(force: true);
      }
    }
    throw StateError('Cloud orders request failed.');
  }

  static dynamic _decode(String text) {
    try {
      return jsonDecode(text);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static OrderListItem _listItem(Map<String, dynamic> json) {
    final cloudId = _string(json, 'id');
    final total = _moneyPaise(json, 'totalAmount');
    final paid = _moneyPaise(json, 'paidAmount');
    return OrderListItem(
      id: _surrogateId(cloudId),
      cloudOrderId: cloudId,
      orderNo: _string(json, 'orderNumber', fallback: '-'),
      customerName: _string(json, 'customerName', fallback: '-'),
      customerPhone: _string(json, 'customerPhone', fallback: '-'),
      recipientName: _string(json, 'recipientName', fallback: '-'),
      source: 'cloud',
      fulfilmentType: _string(json, 'fulfilmentType', fallback: 'delivery'),
      status: _string(json, 'status', fallback: 'confirmed'),
      grandTotalPaise: total,
      createdAt: _date(json, 'orderDate'),
      scheduledAt: _dateOrNull(json, 'deliveryDate'),
      isPaid: paid >= total && total > 0 ? 1 : 0,
      designerName: _nullableString(json, 'designerName'),
      deliveryName: _nullableString(json, 'deliveryPersonName'),
    );
  }

  static OrderDetailBundle _detailBundle(Map<String, dynamic> json) {
    final cloudId = _string(json, 'id');
    final total = _moneyPaise(json, 'totalAmount');
    final paid = _moneyPaise(json, 'paidAmount');
    final lines = _list(json, 'items').map(_lineMap).toList();
    final payments = _list(json, 'payments').map(_paymentMap).toList();
    final timeline = _list(json, 'timeline')
        .map(
          (row) => OrderTimelineItem(
            status: _string(row, 'status', fallback: '-'),
            notes: _nullableString(row, 'notes'),
            createdAt: _date(row, 'createdAtUtc'),
          ),
        )
        .toList();
    final delivery = _mapOrNull(json, 'deliverySummary');

    final header = OrderDetailHeader(
      id: _surrogateId(cloudId),
      cloudOrderId: cloudId,
      orderNo: _string(json, 'orderNumber', fallback: '-'),
      status: _string(json, 'status', fallback: 'confirmed'),
      customerName: _string(json, 'customerName', fallback: '-'),
      customerPhone: _string(json, 'customerPhone', fallback: '-'),
      recipientName: _string(json, 'recipientName', fallback: '-'),
      recipientPhone: _string(json, 'recipientPhone', fallback: '-'),
      fulfilmentType: _string(json, 'fulfilmentType', fallback: 'delivery'),
      source: _string(json, 'orderSource', fallback: 'cloud'),
      grandTotalPaise: total,
      address: _string(json, 'deliveryAddress', fallback: '-'),
      deliveryPincode: _string(json, 'deliveryPincode'),
      scheduledAt: _dateOrNull(json, 'deliveryDate'),
      occasion: '-',
      deliverySlot: _string(json, 'timeSlot', fallback: '-'),
      cardMessage: _string(json, 'cardMessage'),
      isPaid: paid >= total && total > 0 ? 1 : 0,
      paidAmountPaise: paid,
      rewardPointsEarned: _int(json, 'rewardPointsEarned'),
      rewardPointsRedeemed: _int(json, 'rewardPointsRedeemed'),
      rewardDiscountAmountPaise: 0,
      designerName: _nullableString(json, 'assignedDesignerName'),
      deliveryName: _nullableString(json, 'deliveryPersonName'),
    );

    return OrderDetailBundle(
      header: header,
      lines: lines,
      payments: payments,
      timeline: timeline,
      schedulerTasks: const [],
      inventoryTransactions: const [],
      receiptStatus: 'cloud',
      whatsappStatus: 'cloud',
      relayInfo: const {},
      corporateInfo: const {},
      marketplaceInfo: {
        'cloud_order_id': cloudId,
        'discount_amount_paise': _moneyPaise(json, 'discountAmount'),
        'delivery_fee_paise': _moneyPaise(json, 'deliveryFee'),
        'tax_amount_paise': _moneyPaise(json, 'taxAmount'),
        if (delivery != null) 'delivery_status': _string(delivery, 'status'),
      },
    );
  }

  static Map<String, Object?> _lineMap(Map<String, dynamic> json) => {
        'id': _string(json, 'id'),
        'product_id': _string(json, 'productId'),
        'product_name': _string(json, 'productName'),
        'description': _string(json, 'productName', fallback: 'Item'),
        'qty': _int(json, 'quantity'),
        'unit_price_paise': _moneyPaise(json, 'unitPrice'),
        'discount_paise': _moneyPaise(json, 'discountAmount'),
        'discount_type': null,
        'discount_value': null,
        'gst_percent': _int(json, 'taxRatePercent'),
        'line_subtotal_paise': _moneyPaise(json, 'lineSubtotal'),
        'line_gst_paise': _moneyPaise(json, 'lineTaxAmount'),
        'line_total_paise': _moneyPaise(json, 'lineTotal'),
        'source': 'cloud',
      };

  static Map<String, Object?> _paymentMap(Map<String, dynamic> json) => {
        'id': _string(json, 'id'),
        'order_id': _string(json, 'orderId'),
        'method': _string(json, 'method'),
        'amount_paise': _moneyPaise(json, 'amount'),
        'reference': _nullableString(json, 'reference') ??
            _nullableString(json, 'transactionId'),
        'created_at': _string(json, 'createdAtUtc'),
        'status': _string(json, 'status'),
      };

  static String? _statusForTab(String tab, OrderWorkspaceFilters filters) {
    if (filters.cancelled) return 'cancelled';
    if (filters.completed) return 'delivered';
    if (filters.pending) return 'confirmed';
    return switch (tab) {
      'pending' => 'confirmed',
      'in_progress' => 'processing',
      'ready' => 'ready_for_delivery',
      'completed' => 'delivered',
      _ => null,
    };
  }

  static String _cloudStatus(String status) {
    return switch (status.trim().toLowerCase()) {
      'created' => 'Pending',
      'confirmed' => 'Confirmed',
      'sent_to_designer' => 'Processing',
      'preparing' => 'Processing',
      'ready' => 'ReadyForDelivery',
      'out_for_delivery' => 'OutForDelivery',
      'delivered' => 'Delivered',
      'cancelled' => 'Cancelled',
      _ => status,
    };
  }

  static String _cloudPaymentMethod(String method) {
    return switch (method.trim().toLowerCase().replaceAll(' ', '_')) {
      'cash' => 'Cash',
      'upi' => 'Upi',
      'card' || 'credit_card' || 'debit_card' => 'Card',
      'bank_transfer' || 'netbanking' => 'BankTransfer',
      'gift_card' => 'GiftCard',
      'external_terminal' => 'ExternalTerminal',
      _ => method,
    };
  }

  static String _utcIso(DateTime value) =>
      (value.isUtc ? value : value.toUtc()).toIso8601String();

  static String _dateQueryValue(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day).toIso8601String();

  static int _surrogateId(String value) {
    var hash = 0;
    for (final code in value.codeUnits) {
      hash = 0x1fffffff & (hash + code);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= hash >> 6;
    }
    return hash == 0 ? -1 : -hash.abs();
  }

  static String _key(Map<String, dynamic> json, String key) =>
      json.containsKey(key) ? key : '${key[0].toUpperCase()}${key.substring(1)}';

  static String _string(
    Map<String, dynamic> json,
    String key, {
    String fallback = '',
  }) =>
      json[_key(json, key)]?.toString() ?? fallback;

  static String? _nullableString(Map<String, dynamic> json, String key) {
    final value = json[_key(json, key)]?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  static int _int(Map<String, dynamic> json, String key) {
    final value = json[_key(json, key)];
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _moneyPaise(Map<String, dynamic> json, String key) {
    final value = json[_key(json, key)];
    if (value is num) return (value * 100).round();
    return ((double.tryParse(value?.toString() ?? '') ?? 0) * 100).round();
  }

  static DateTime _date(Map<String, dynamic> json, String key) =>
      DateTime.tryParse(_string(json, key)) ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  static DateTime? _dateOrNull(Map<String, dynamic> json, String key) {
    final value = _nullableString(json, key);
    return value == null ? null : DateTime.tryParse(value);
  }

  static List<Map<String, dynamic>> _list(Map<String, dynamic> json, String key) {
    final value = json[_key(json, key)];
    if (value is! List) return const [];
    return value.whereType<Map>().map((row) => row.cast<String, dynamic>()).toList();
  }

  static Map<String, dynamic>? _mapOrNull(Map<String, dynamic> json, String key) {
    final value = json[_key(json, key)];
    return value is Map ? value.cast<String, dynamic>() : null;
  }

  static List<CloudAssignee> _assignees(dynamic response) {
    final rows = response is List
        ? response
        : response is Map
            ? response[_key(response.cast<String, dynamic>(), 'items')]
            : null;
    if (rows is! List) return const [];

    return rows
        .whereType<Map>()
        .map((row) => row.cast<String, dynamic>())
        .where((row) => _string(row, 'id').trim().isNotEmpty)
        .map(
          (row) => CloudAssignee(
            staffId: _string(row, 'id'),
            name: _string(row, 'name', fallback: '-'),
            role: _string(row, 'role'),
            phone: _nullableString(row, 'phone'),
          ),
        )
        .toList();
  }
}