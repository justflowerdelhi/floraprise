import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../models/cloud_order_status_report.dart';
import '../../services/mobile_auth_service.dart';

typedef CloudOrderStatusSender = Future<dynamic> Function(Uri uri);

class CloudOrderStatusRepository {
  CloudOrderStatusRepository({
    MobileAuthService? auth,
    CloudOrderStatusSender? sender,
    FlutterSecureStorage? secureStorage,
  })  : _auth = auth ?? MobileAuthService(),
        _sender = sender,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final MobileAuthService _auth;
  final CloudOrderStatusSender? _sender;
  final FlutterSecureStorage? _secureStorage;

  final Map<String, CloudOrderStatusReport> _cache = {};
  static const String _storageKeyPrefix = 'cloud_order_status_report_';

  String _buildCacheKey(DateTime? fromDate, DateTime? toDate) {
    final from = fromDate?.toIso8601String() ?? 'none';
    final to = toDate?.toIso8601String() ?? 'none';
    return '$from-$to';
  }

  Future<CloudOrderStatusReport> getOrderStatusReport({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final cacheKey = _buildCacheKey(fromDate, toDate);
    final queryParams = <String, String>{};
    if (fromDate != null) {
      queryParams['fromDate'] = fromDate.toUtc().toIso8601String();
    }
    if (toDate != null) {
      queryParams['toDate'] = toDate.toUtc().toIso8601String();
    }

    final baseUri =
        Uri.parse('${_auth.baseUrl}/api/v1/mobile/orders/status-report');
    final uri = queryParams.isEmpty
        ? baseUri
        : baseUri.replace(queryParameters: queryParams);

    try {
      final dynamic response = _sender != null
          ? await _sender!(uri)
          : await _sendGet(uri);

      if (response is Map) {
        final report = CloudOrderStatusReport.fromJson(
          response.cast<String, dynamic>(),
        );
        _cache[cacheKey] = report;
        await _writeCache(cacheKey, report);
        return report;
      }

      return await _readCache(cacheKey);
    } catch (e) {
      debugPrint(
          '[CloudOrderStatusRepository] Fetch failed ($e), attempting cache fallback');
      return await _readCache(cacheKey);
    }
  }

  Future<dynamic> _sendGet(Uri uri) async {
    var token = await _auth.getStoredAccessToken();
    for (var attempt = 0; attempt < 2; attempt++) {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 15);
      try {
        final request = await client.getUrl(uri);
        if (token != null && token.isNotEmpty) {
          request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
        }
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');

        final response = await request.close();
        final body = await utf8.decodeStream(response);

        if (response.statusCode == 401 && attempt == 0) {
          final refreshed = await _auth.refreshAndBootstrap();
          token = refreshed.accessToken;
          continue;
        }

        if (response.statusCode >= 200 && response.statusCode < 300) {
          if (body.isEmpty) return const <String, dynamic>{};
          return jsonDecode(body);
        }
        throw HttpException(
          'GET $uri failed (${response.statusCode}): $body',
          uri: uri,
        );
      } finally {
        client.close(force: true);
      }
    }
    throw HttpException('GET $uri failed after retry', uri: uri);
  }

  Future<CloudOrderStatusReport> _readCache(String cacheKey) async {
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final storage = _secureStorage;
    if (storage != null) {
      try {
        final raw = await storage.read(key: '$_storageKeyPrefix$cacheKey');
        if (raw != null && raw.trim().isNotEmpty) {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            final report = CloudOrderStatusReport.fromJson(
              decoded.cast<String, dynamic>(),
            );
            _cache[cacheKey] = report;
            return report;
          }
        }
      } catch (e) {
        debugPrint('[CloudOrderStatusRepository] Cache read error: $e');
      }
    }

    if (cacheKey != 'none-none' && _cache.containsKey('none-none')) {
      return _cache['none-none']!;
    }

    return CloudOrderStatusReport.empty;
  }

  Future<void> _writeCache(
      String cacheKey, CloudOrderStatusReport report) async {
    final storage = _secureStorage;
    if (storage == null) return;
    try {
      final raw = jsonEncode(report.toJson());
      await storage.write(key: '$_storageKeyPrefix$cacheKey', value: raw);
    } catch (e) {
      debugPrint('[CloudOrderStatusRepository] Cache write error: $e');
    }
  }
}
