import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../services/mobile_auth_service.dart';

class CloudTopCustomer {
  const CloudTopCustomer({
    required this.customerId,
    required this.customerName,
    required this.totalPaise,
    required this.orderCount,
  });

  final String customerId;
  final String customerName;
  final int totalPaise;
  final int orderCount;

  factory CloudTopCustomer.fromJson(Map<String, dynamic> json) =>
      CloudTopCustomer(
        customerId: _read(json, 'customerId')?.toString() ?? '',
        customerName: _read(json, 'customerName')?.toString() ?? '',
        totalPaise: _moneyPaise(_read(json, 'totalAmount')),
        orderCount: _readInt(_read(json, 'orderCount')),
      );

  static Object? _read(Map<String, dynamic> json, String key) =>
      json[key] ?? json['${key[0].toUpperCase()}${key.substring(1)}'];

  static int _moneyPaise(Object? value) {
    if (value is num) return (value * 100).round();
    return ((double.tryParse(value?.toString() ?? '') ?? 0) * 100).round();
  }

  static int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

typedef CloudTopCustomersSender = Future<List<dynamic>> Function(Uri uri);

/// Fetches authoritative Top Customers data from Cloud/PostgreSQL only.
class CloudTopCustomersRepository {
  CloudTopCustomersRepository({
    MobileAuthService? auth,
    CloudTopCustomersSender? sender,
  })  : _auth = auth ?? MobileAuthService(),
        _sender = sender;

  final MobileAuthService _auth;
  final CloudTopCustomersSender? _sender;

  Future<List<CloudTopCustomer>> getTopCustomers({
    required DateTime fromDate,
    required DateTime toDate,
    int limit = 10,
  }) async {
    final uri = _buildUri(fromDate, toDate, limit);
    final sender = _sender;
    try {
      final response = sender != null ? await sender(uri) : await _send(uri);
      return response
          .whereType<Map<String, dynamic>>()
          .map(CloudTopCustomer.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Uri _buildUri(DateTime fromDate, DateTime toDate, int limit) {
    return Uri.parse('${_auth.baseUrl}/api/accounting/top-customers').replace(
      queryParameters: {
        'from': _dateQuery(fromDate),
        'to': _dateQuery(toDate),
        'limit': limit.toString(),
      },
    );
  }

  Future<List<dynamic>> _send(Uri uri) async {
    final token = await _auth.getStoredAccessToken();
    if (token == null || token.trim().isEmpty) return const [];

    final client = http.Client();
    try {
      final request = http.Request('GET', uri);
      request.headers['Accept'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $token';
      final streamedResponse =
          await client.send(request).timeout(const Duration(seconds: 20));
      final text = await streamedResponse.stream.bytesToString();
      if (streamedResponse.statusCode < 200 || streamedResponse.statusCode >= 300) {
        return const [];
      }
      final decoded = jsonDecode(text);
      return decoded is List<dynamic> ? decoded : const [];
    } catch (_) {
      return const [];
    } finally {
      client.close();
    }
  }

  String _dateQuery(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}