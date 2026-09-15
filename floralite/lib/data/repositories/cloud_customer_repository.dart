import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../services/mobile_auth_service.dart';

class CloudCustomer {
  const CloudCustomer({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.notes,
  });

  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? notes;

  factory CloudCustomer.fromJson(Map<String, dynamic> json) => CloudCustomer(
        id: json['id']?.toString() ?? json['Id']?.toString() ?? '',
        name: json['name']?.toString() ?? json['Name']?.toString() ?? '',
        email: json['email']?.toString() ?? json['Email']?.toString(),
        phone: json['phone']?.toString() ?? json['Phone']?.toString(),
        notes: json['notes']?.toString() ?? json['Notes']?.toString(),
      );
}

class CloudCustomerStatistics {
  const CloudCustomerStatistics({
    required this.customerId,
    required this.totalOrders,
    required this.lastOrderAt,
    required this.lifetimePurchasePaise,
    required this.pendingPaymentPaise,
  });

  final String customerId;
  final int totalOrders;
  final String? lastOrderAt;
  final int lifetimePurchasePaise;
  final int pendingPaymentPaise;

  factory CloudCustomerStatistics.fromJson(Map<String, dynamic> json) =>
      CloudCustomerStatistics(
        customerId: json['customerId']?.toString() ??
            json['CustomerId']?.toString() ??
            '',
        totalOrders: _readInt(json, 'totalOrders'),
        lastOrderAt: json['lastOrderAt']?.toString() ??
            json['LastOrderAt']?.toString(),
        lifetimePurchasePaise: _readInt(json, 'lifetimePurchasePaise'),
        pendingPaymentPaise: _readInt(json, 'pendingPaymentPaise'),
      );

  static int _readInt(Map<String, dynamic> json, String key) {
    final value = json[key] ?? json['${key[0].toUpperCase()}${key.substring(1)}'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}


class CloudCustomerException implements Exception {
  const CloudCustomerException(this.message);

  final String message;

  @override
  String toString() => message;
}

typedef CloudCustomerHttpSender = Future<Map<String, dynamic>> Function(
  String method,
  Uri uri, {
  Map<String, dynamic>? body,
});

class CloudCustomerRepository {
  CloudCustomerRepository({
    MobileAuthService? auth,
    CloudCustomerHttpSender? sender,
  })  : _auth = auth ?? MobileAuthService(),
        _sender = sender;

  final MobileAuthService _auth;
  final CloudCustomerHttpSender? _sender;
  final Map<String, CloudCustomerStatistics> _statisticsCache = {};

  Future<List<CloudCustomer>> getAll({String? query}) async {
    final queryParameters = <String, String>{
      'page': '1',
      'pageSize': '500',
    };

    final trimmedQuery = query?.trim() ?? '';
    if (trimmedQuery.isNotEmpty) {
      queryParameters['query'] = trimmedQuery;
    }

    final response = await _send(
      'GET',
      Uri.parse('${_auth.baseUrl}/api/customers/search')
          .replace(queryParameters: queryParameters),
    );

    final rawItems = response['items'] ?? response['Items'] ?? [];
    if (rawItems is! List) return const [];

    return rawItems
        .whereType<Map>()
        .map(
          (item) => CloudCustomer.fromJson(
            item.cast<String, dynamic>(),
          ),
        )
        .where((customer) => customer.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<CloudCustomer?> findByPhone(String phone) async {
    final digits = _normalizePhone(phone);
    if (digits.length != 10) return null;

    final response = await _send(
      'GET',
      Uri.parse('${_auth.baseUrl}/api/customers/by-phone').replace(
        queryParameters: {'phone': digits},
      ),
    );

    if (response.isEmpty || _readString(response, 'id').isEmpty) {
      return null;
    }

    return CloudCustomer.fromJson(response);
  }

  Future<CloudCustomerStatistics?> getStatistics(
    String cloudCustomerId, {
    String? companyId,
  }) async {
    final normalizedCustomerId = cloudCustomerId.trim();
    if (normalizedCustomerId.isEmpty) return null;

    final cacheKey = _statisticsCacheKey(
      cloudCustomerId: normalizedCustomerId,
      companyId: companyId,
    );
    final cached = _statisticsCache[cacheKey];

    try {
      final response = await _send(
        'GET',
        Uri.parse(
          '${_auth.baseUrl}/api/v1/mobile/customers/'
          '${Uri.encodeComponent(normalizedCustomerId)}/statistics',
        ),
      );
      if (response.isEmpty) {
        return cached;
      }

      final stats = CloudCustomerStatistics.fromJson(response);
      _statisticsCache[cacheKey] = stats;
      return stats;
    } catch (_) {
      return cached;
    }
  }

  Future<String> create({
    required String phone,
    required String name,
  }) async {
    final response = await _send(
      'POST',
      Uri.parse('${_auth.baseUrl}/api/customers'),
      body: {
        'name': name.trim(),
        'phone': _normalizePhone(phone),
      },
    );

    final returnedId = _readString(response, 'id').trim();
    if (returnedId.isNotEmpty) return returnedId;

    final created = await findByPhone(phone);
    if (created == null || created.id.isEmpty) {
      throw const CloudCustomerException(
        'Customer was created, but its server ID could not be retrieved.',
      );
    }

    return created.id;
  }

  Future<void> update({
    required String id,
    required String phone,
    required String name,
  }) async {
    await _send(
      'PUT',
      Uri.parse(
        '${_auth.baseUrl}/api/customers/${Uri.encodeComponent(id)}/contact',
      ),
      body: {
        'name': name.trim(),
        'phone': _normalizePhone(phone),
      },
    );
  }

  Future<void> deactivate(String id) async {
    await _send(
      'PUT',
      Uri.parse(
        '${_auth.baseUrl}/api/customers/${Uri.encodeComponent(id)}/deactivate',
      ),
    );
  }

  Future<Map<String, dynamic>> _send(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    final sender = _sender;
    if (sender != null) {
      return sender(method, uri, body: body);
    }

    var token = await _auth.getStoredAccessToken();

    if (token == null || token.trim().isEmpty) {
      throw const CloudCustomerException(
        'Cloud session is not available. Please log in again.',
      );
    }

    debugPrint('[CUSTOMER-CLOUD] $method $uri');

    for (var attempt = 0; attempt < 2; attempt++) {
      final client = http.Client();

      try {
        final request = http.Request(method, uri);
        request.headers['Accept'] = 'application/json';
        request.headers['Authorization'] = 'Bearer $token';

        if (body != null) {
          request.headers['Content-Type'] = 'application/json';
          request.body = jsonEncode(body);
        }

        final streamedResponse =
            await client.send(request).timeout(const Duration(seconds: 20));
        final responseBody = await streamedResponse.stream.bytesToString();
        final statusCode = streamedResponse.statusCode;

        debugPrint(
          '[CUSTOMER-CLOUD] HTTP STATUS: $statusCode',
        );

        if (statusCode == 401 && attempt == 0) {
          try {
            final refreshed = await _auth.refreshAndBootstrap();
            token = refreshed.accessToken;

            if (token.trim().isNotEmpty) {
              continue;
            }
          } catch (_) {
            // Fall through to the normal expired-session error.
          }

          throw const CloudCustomerException(
            'Cloud session expired. Please log in again.',
          );
        }

        final decoded = responseBody.trim().isEmpty
            ? <String, dynamic>{}
            : _decode(responseBody);

        if (statusCode < 200 || statusCode >= 300) {
          final message = decoded['message'] ??
              decoded['detail'] ??
              decoded['title'] ??
              decoded['error'];

          throw CloudCustomerException(
            message?.toString() ??
                'Cloud customer request failed '
                    '(HTTP $statusCode).',
          );
        }

        debugPrint('[CUSTOMER-CLOUD] RESPONSE: $responseBody');
        return decoded;
      } on CloudCustomerException {
        rethrow;
      } catch (error) {
        throw CloudCustomerException(
          'Unable to connect to Floraprise Cloud: $error',
        );
      } finally {
        client.close();
      }
    }

    throw const CloudCustomerException('Cloud customer request failed.');
  }

  static Map<String, dynamic> _decode(String text) {
    try {
      final value = jsonDecode(text);
      return value is Map
          ? Map<String, dynamic>.from(value)
          : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static String _readString(
    Map<String, dynamic> json,
    String key,
  ) =>
      json[key]?.toString() ??
      json['${key[0].toUpperCase()}${key.substring(1)}']?.toString() ??
      '';

  static String _normalizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 10
        ? digits.substring(digits.length - 10)
        : digits;
  }

  static String _statisticsCacheKey({
    required String cloudCustomerId,
    String? companyId,
  }) {
    final normalizedCompanyId = companyId?.trim().toLowerCase() ?? '';
    return '$normalizedCompanyId:$cloudCustomerId';
  }
}
