import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../services/mobile_auth_service.dart';

class CloudDashboardSummary {
  const CloudDashboardSummary({
    required this.totalSalesPaise,
    required this.orderCount,
    required this.cashPaise,
    required this.upiPaise,
    required this.cardPaise,
    required this.creditPaise,
    required this.pendingOrderCount,
    required this.preparingOrderCount,
    required this.readyOrderCount,
    required this.outForDeliveryCount,
    required this.deliveryCount,
    required this.pickupCount,
    required this.expensePaise,
  });

  final int totalSalesPaise;
  final int orderCount;
  final int cashPaise;
  final int upiPaise;
  final int cardPaise;
  final int creditPaise;
  final int pendingOrderCount;
  final int preparingOrderCount;
  final int readyOrderCount;
  final int outForDeliveryCount;
  final int deliveryCount;
  final int pickupCount;
  final int expensePaise;

  factory CloudDashboardSummary.fromJson(Map<String, dynamic> json) {
    return CloudDashboardSummary(
      totalSalesPaise: _readInt(json, 'totalSalesPaise'),
      orderCount: _readInt(json, 'orderCount'),
      cashPaise: _readInt(json, 'cashPaise'),
      upiPaise: _readInt(json, 'upiPaise'),
      cardPaise: _readInt(json, 'cardPaise'),
      creditPaise: _readInt(json, 'creditPaise'),
      pendingOrderCount: _readInt(json, 'pendingOrderCount'),
      preparingOrderCount: _readInt(json, 'preparingOrderCount'),
      readyOrderCount: _readInt(json, 'readyOrderCount'),
      outForDeliveryCount: _readInt(json, 'outForDeliveryCount'),
      deliveryCount: _readInt(json, 'deliveryCount'),
      pickupCount: _readInt(json, 'pickupCount'),
      expensePaise: _readInt(json, 'expensePaise'),
    );
  }

  Map<String, dynamic> toJson() => {
        'totalSalesPaise': totalSalesPaise,
        'orderCount': orderCount,
        'cashPaise': cashPaise,
        'upiPaise': upiPaise,
        'cardPaise': cardPaise,
        'creditPaise': creditPaise,
        'pendingOrderCount': pendingOrderCount,
        'preparingOrderCount': preparingOrderCount,
        'readyOrderCount': readyOrderCount,
        'outForDeliveryCount': outForDeliveryCount,
        'deliveryCount': deliveryCount,
        'pickupCount': pickupCount,
        'expensePaise': expensePaise,
      };

  static int _readInt(Map<String, dynamic> json, String key) {
    final value = json[key] ?? json['${key[0].toUpperCase()}${key.substring(1)}'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class CloudPendingPaymentsSummary {
  const CloudPendingPaymentsSummary({
    required this.pendingOrderCount,
    required this.pendingPaymentPaise,
  });

  final int pendingOrderCount;
  final int pendingPaymentPaise;

  factory CloudPendingPaymentsSummary.fromJson(Map<String, dynamic> json) {
    return CloudPendingPaymentsSummary(
      pendingOrderCount: _readInt(json, 'pendingOrderCount'),
      pendingPaymentPaise: _readInt(json, 'pendingPaymentPaise'),
    );
  }

  Map<String, dynamic> toJson() => {
        'pendingOrderCount': pendingOrderCount,
        'pendingPaymentPaise': pendingPaymentPaise,
      };

  static int _readInt(Map<String, dynamic> json, String key) {
    final value = json[key] ?? json['${key[0].toUpperCase()}${key.substring(1)}'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

typedef CloudDashboardSummarySender = Future<Map<String, dynamic>> Function(
  Uri uri,
);

typedef CloudPendingPaymentsSender = Future<Map<String, dynamic>> Function(
  Uri uri,
);

class CloudDashboardRepository {
  CloudDashboardRepository({
    MobileAuthService? auth,
    FlutterSecureStorage? secureStorage,
    CloudDashboardSummarySender? summarySender,
    CloudPendingPaymentsSender? pendingPaymentsSender,
  })  : _auth = auth ?? MobileAuthService(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _summarySender = summarySender,
        _pendingPaymentsSender = pendingPaymentsSender;

  static const _cacheKeyPrefix = 'cloud_dashboard_summary_';
  static const _pendingPaymentsCacheKeyPrefix = 'cloud_pending_payments_';

  final MobileAuthService _auth;
  final FlutterSecureStorage _secureStorage;
  final CloudDashboardSummarySender? _summarySender;
  final CloudPendingPaymentsSender? _pendingPaymentsSender;
  final Map<String, CloudDashboardSummary> _summaryCache = {};
  final Map<String, CloudPendingPaymentsSummary> _pendingPaymentsCache = {};

  Future<CloudDashboardSummary?> getSummary({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final cacheKey = _summaryCacheKey(fromDate: fromDate, toDate: toDate);
    final sender = _summarySender;

    try {
      final response = sender != null
          ? await sender(_buildSummaryUri(fromDate, toDate))
          : await _send(_buildSummaryUri(fromDate, toDate));
      if (response.isEmpty) {
        return await _readSummaryCache(cacheKey);
      }

      final summary = CloudDashboardSummary.fromJson(response);
      await _writeSummaryCache(cacheKey, summary);
      return summary;
    } catch (_) {
      return await _readSummaryCache(cacheKey);
    }
  }

  Future<CloudPendingPaymentsSummary?> getPendingPayments({
    DateTime? asOf,
  }) async {
    final cacheKey = _pendingPaymentsCacheKey(asOf ?? DateTime.now());
    final sender = _pendingPaymentsSender;

    try {
      final response = sender != null
          ? await sender(_buildPendingPaymentsUri())
          : await _send(_buildPendingPaymentsUri());
      if (response.isEmpty) {
        return await _readPendingPaymentsCache(cacheKey);
      }

      final summary = CloudPendingPaymentsSummary.fromJson(response);
      await _writePendingPaymentsCache(cacheKey, summary);
      return summary;
    } catch (_) {
      return await _readPendingPaymentsCache(cacheKey);
    }
  }

  Uri _buildSummaryUri(DateTime fromDate, DateTime toDate) {
    return Uri.parse('${_auth.baseUrl}/api/v1/mobile/dashboard/summary').replace(
      queryParameters: {
        'fromDate': _dateQuery(fromDate),
        'toDate': _dateQuery(toDate),
      },
    );
  }

  Uri _buildPendingPaymentsUri() {
    return Uri.parse('${_auth.baseUrl}/api/v1/mobile/payments/pending');
  }

  Future<Map<String, dynamic>> _send(Uri uri) async {
    final token = await _auth.getStoredAccessToken();
    if (token == null || token.trim().isEmpty) {
      return <String, dynamic>{};
    }

    final client = HttpClient();
    try {
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 12));
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      final response = await request.close().timeout(const Duration(seconds: 20));
      final text = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return <String, dynamic>{};
      }
      final decoded = jsonDecode(text);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    } finally {
      client.close(force: true);
    }
  }

  Future<CloudDashboardSummary?> _readSummaryCache(String key) async {
    final memoryHit = _summaryCache[key];
    if (memoryHit != null) return memoryHit;

    try {
      final cached = await _secureStorage.read(key: key);
      if (cached == null || cached.trim().isEmpty) return null;
      final decoded = jsonDecode(cached);
      if (decoded is! Map<String, dynamic>) return null;
      final summary = CloudDashboardSummary.fromJson(decoded);
      _summaryCache[key] = summary;
      return summary;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeSummaryCache(String key, CloudDashboardSummary summary) async {
    _summaryCache[key] = summary;
    try {
      await _secureStorage.write(key: key, value: jsonEncode(summary.toJson()));
    } catch (_) {
      // Ignore cache write errors.
    }
  }

  Future<CloudPendingPaymentsSummary?> _readPendingPaymentsCache(String key) async {
    final memoryHit = _pendingPaymentsCache[key];
    if (memoryHit != null) return memoryHit;

    try {
      final cached = await _secureStorage.read(key: key);
      if (cached == null || cached.trim().isEmpty) return null;
      final decoded = jsonDecode(cached);
      if (decoded is! Map<String, dynamic>) return null;
      final summary = CloudPendingPaymentsSummary.fromJson(decoded);
      _pendingPaymentsCache[key] = summary;
      return summary;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writePendingPaymentsCache(
    String key,
    CloudPendingPaymentsSummary summary,
  ) async {
    _pendingPaymentsCache[key] = summary;
    try {
      await _secureStorage.write(key: key, value: jsonEncode(summary.toJson()));
    } catch (_) {
      // Ignore cache write errors.
    }
  }

  static String _summaryCacheKey({required DateTime fromDate, required DateTime toDate}) {
    return '$_cacheKeyPrefix${_dateQuery(fromDate)}_${_dateQuery(toDate)}';
  }

  static String _pendingPaymentsCacheKey(DateTime asOf) {
    return '$_pendingPaymentsCacheKeyPrefix${_dateQuery(asOf)}';
  }

  static String _dateQuery(DateTime value) {
    final utc = DateTime.utc(value.year, value.month, value.day);
    return utc.toIso8601String();
  }
}
