import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../services/mobile_auth_service.dart';

class CloudRewardsReport {
  const CloudRewardsReport({
    required this.currentPoints,
    required this.lifetimePoints,
    required this.redeemedPoints,
    required this.rewardOrders,
    required this.discountPaise,
    required this.customers,
  });

  final int currentPoints;
  final int lifetimePoints;
  final int redeemedPoints;
  final int rewardOrders;
  final int discountPaise;
  final List<Map<String, Object?>> customers;

  factory CloudRewardsReport.fromJson(Map<String, dynamic> json) {
    final customerRows = _read(json, 'customers');
    return CloudRewardsReport(
      currentPoints: _readInt(_read(json, 'currentPoints')),
      lifetimePoints: _readInt(_read(json, 'lifetimePoints')),
      redeemedPoints: _readInt(_read(json, 'redeemedPoints')),
      rewardOrders: _readInt(_read(json, 'rewardOrders')),
      discountPaise: _moneyPaise(_read(json, 'discountAmount')),
      customers: customerRows is List
          ? customerRows.whereType<Map<String, dynamic>>().map((customer) {
              return <String, Object?>{
                'name': _read(customer, 'customerName')?.toString(),
                'phone': _read(customer, 'phone')?.toString(),
                'reward_points': _readInt(_read(customer, 'rewardPoints')),
                'lifetime_reward_points':
                    _readInt(_read(customer, 'lifetimeRewardPoints')),
                'redeemed_reward_points':
                    _readInt(_read(customer, 'redeemedRewardPoints')),
                'last_reward_activity':
                    _read(customer, 'lastRewardActivityAtUtc')?.toString(),
              };
            }).toList()
          : const [],
    );
  }
}

class CloudTopProduct {
  const CloudTopProduct({
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.totalRevenuePaise,
  });

  final String productId;
  final String productName;
  final int quantitySold;
  final int totalRevenuePaise;

  factory CloudTopProduct.fromJson(Map<String, dynamic> json) =>
      CloudTopProduct(
        productId: _read(json, 'productId')?.toString() ?? '',
        productName: _read(json, 'productName')?.toString() ?? '',
        quantitySold: _readInt(_read(json, 'quantitySold')),
        totalRevenuePaise: _moneyPaise(_read(json, 'totalRevenue')),
      );
}

typedef CloudRemainingReportsSender = Future<Object?> Function(Uri uri);

class CloudRemainingReportsRepository {
  CloudRemainingReportsRepository({
    MobileAuthService? auth,
    CloudRemainingReportsSender? sender,
  })  : _auth = auth ?? MobileAuthService(),
        _sender = sender;

  final MobileAuthService _auth;
  final CloudRemainingReportsSender? _sender;

  Future<CloudRewardsReport?> getRewardsReport() async {
    final response = await _request(
      Uri.parse('${_auth.baseUrl}/api/accounting/rewards-summary'),
    );
    return response is Map<String, dynamic>
        ? CloudRewardsReport.fromJson(response)
        : null;
  }

  Future<List<CloudTopProduct>> getTopProducts({
    required DateTime fromDate,
    required DateTime toDate,
    int limit = 10,
  }) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/accounting/top-products').replace(
      queryParameters: {
        'from': _dateQuery(fromDate),
        'to': _dateQuery(toDate),
        'limit': limit.toString(),
      },
    );
    final response = await _request(uri);
    if (response is! List) return const [];
    return response
        .whereType<Map<String, dynamic>>()
        .map(CloudTopProduct.fromJson)
        .toList();
  }

  Future<Object?> _request(Uri uri) async {
    final sender = _sender;
    try {
      if (sender != null) return await sender(uri);
      final token = await _auth.getStoredAccessToken();
      if (token == null || token.trim().isEmpty) return null;

      final client = http.Client();
      try {
        final request = http.Request('GET', uri);
        request.headers['Accept'] = 'application/json';
        request.headers['Authorization'] = 'Bearer $token';
        final streamedResponse =
            await client.send(request).timeout(const Duration(seconds: 20));
        final text = await streamedResponse.stream.bytesToString();
        if (streamedResponse.statusCode < 200 || streamedResponse.statusCode >= 300) {
          return null;
        }
        return jsonDecode(text);
      } finally {
        client.close();
      }
    } catch (_) {
      return null;
    }
  }

  String _dateQuery(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

Object? _read(Map<String, dynamic> json, String key) =>
    json[key] ?? json['${key[0].toUpperCase()}${key.substring(1)}'];

int _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int _moneyPaise(Object? value) {
  if (value is num) return (value * 100).round();
  return ((double.tryParse(value?.toString() ?? '') ?? 0) * 100).round();
}