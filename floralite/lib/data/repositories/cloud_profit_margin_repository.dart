import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../services/mobile_auth_service.dart';

class CloudProfitMarginSummary {
  const CloudProfitMarginSummary({
    required this.grossSalesPaise,
    required this.discountsPaise,
    required this.netRevenuePaise,
    required this.cogsPaise,
    required this.grossProfitPaise,
    required this.marginPercent,
    required this.orderCount,
    required this.cogsIsEstimate,
    required this.cogsLimitationNote,
  });

  final int grossSalesPaise;
  final int discountsPaise;
  final int netRevenuePaise;
  final int cogsPaise;
  final int grossProfitPaise;
  final double marginPercent;
  final int orderCount;
  final bool cogsIsEstimate;
  final String cogsLimitationNote;

  factory CloudProfitMarginSummary.fromJson(Map<String, dynamic> json) {
    return CloudProfitMarginSummary(
      grossSalesPaise: _readInt(json, 'grossSalesPaise'),
      discountsPaise: _readInt(json, 'discountsPaise'),
      netRevenuePaise: _readInt(json, 'netRevenuePaise'),
      cogsPaise: _readInt(json, 'cogsPaise'),
      grossProfitPaise: _readInt(json, 'grossProfitPaise'),
      marginPercent: _readDouble(json, 'marginPercent'),
      orderCount: _readInt(json, 'orderCount'),
      cogsIsEstimate: (json['cogsIsEstimate'] ?? json['CogsIsEstimate']) == true,
      cogsLimitationNote:
          (json['cogsLimitationNote'] ?? json['CogsLimitationNote'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'grossSalesPaise': grossSalesPaise,
        'discountsPaise': discountsPaise,
        'netRevenuePaise': netRevenuePaise,
        'cogsPaise': cogsPaise,
        'grossProfitPaise': grossProfitPaise,
        'marginPercent': marginPercent,
        'orderCount': orderCount,
        'cogsIsEstimate': cogsIsEstimate,
        'cogsLimitationNote': cogsLimitationNote,
      };

  static int _readInt(Map<String, dynamic> json, String key) {
    final value = json[key] ?? json['${key[0].toUpperCase()}${key.substring(1)}'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _readDouble(Map<String, dynamic> json, String key) {
    final value = json[key] ?? json['${key[0].toUpperCase()}${key.substring(1)}'];
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}

typedef CloudProfitMarginSender = Future<Map<String, dynamic>> Function(Uri uri);

/// Fetches Profit/Margin summaries calculated server-side from authoritative
/// Cloud/PostgreSQL data. Never falls back to local SQLite for totals; on
/// failure, only a previously cached Cloud response (if any) is returned.
class CloudProfitMarginRepository {
  CloudProfitMarginRepository({
    MobileAuthService? auth,
    FlutterSecureStorage? secureStorage,
    CloudProfitMarginSender? sender,
  })  : _auth = auth ?? MobileAuthService(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _sender = sender;

  static const _cacheKeyPrefix = 'cloud_profit_margin_';

  final MobileAuthService _auth;
  final FlutterSecureStorage _secureStorage;
  final CloudProfitMarginSender? _sender;
  final Map<String, CloudProfitMarginSummary> _cache = {};

  Future<CloudProfitMarginSummary?> getProfitMargin({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final cacheKey = _cacheKey(fromDate: fromDate, toDate: toDate);
    final sender = _sender;

    try {
      final response = sender != null
          ? await sender(_buildUri(fromDate, toDate))
          : await _send(_buildUri(fromDate, toDate));
      if (response.isEmpty) {
        return await _readCache(cacheKey);
      }

      final summary = CloudProfitMarginSummary.fromJson(response);
      await _writeCache(cacheKey, summary);
      return summary;
    } catch (_) {
      return await _readCache(cacheKey);
    }
  }

  Uri _buildUri(DateTime fromDate, DateTime toDate) {
    return Uri.parse('${_auth.baseUrl}/api/v1/mobile/dashboard/profit-margin').replace(
      queryParameters: {
        'fromDate': _dateQuery(fromDate),
        'toDate': _dateQuery(toDate),
      },
    );
  }

  Future<Map<String, dynamic>> _send(Uri uri) async {
    final token = await _auth.getStoredAccessToken();
    if (token == null || token.trim().isEmpty) {
      return <String, dynamic>{};
    }

    final client = http.Client();
    try {
      final request = http.Request('GET', uri);
      request.headers['Accept'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $token';
      final streamedResponse =
          await client.send(request).timeout(const Duration(seconds: 20));
      final text = await streamedResponse.stream.bytesToString();
      if (streamedResponse.statusCode < 200 || streamedResponse.statusCode >= 300) {
        return <String, dynamic>{};
      }
      final decoded = jsonDecode(text);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    } finally {
      client.close();
    }
  }

  Future<CloudProfitMarginSummary?> _readCache(String key) async {
    final memoryHit = _cache[key];
    if (memoryHit != null) return memoryHit;

    try {
      final cached = await _secureStorage.read(key: key);
      if (cached == null || cached.trim().isEmpty) return null;
      final decoded = jsonDecode(cached);
      if (decoded is! Map<String, dynamic>) return null;
      final summary = CloudProfitMarginSummary.fromJson(decoded);
      _cache[key] = summary;
      return summary;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(String key, CloudProfitMarginSummary summary) async {
    _cache[key] = summary;
    try {
      await _secureStorage.write(key: key, value: jsonEncode(summary.toJson()));
    } catch (_) {
      // Ignore cache write errors.
    }
  }

  String _cacheKey({required DateTime fromDate, required DateTime toDate}) =>
      '$_cacheKeyPrefix${_dateQuery(fromDate)}_${_dateQuery(toDate)}';

  String _dateQuery(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
