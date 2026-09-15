import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../services/mobile_auth_service.dart';

class CloudExpenseSummary {
  const CloudExpenseSummary({
    required this.totalPaise,
    required this.cashPaise,
    required this.upiPaise,
    required this.cardPaise,
    required this.expenseCount,
  });

  final int totalPaise;
  final int cashPaise;
  final int upiPaise;
  final int cardPaise;
  final int expenseCount;

  factory CloudExpenseSummary.fromJson(Map<String, dynamic> json) {
    // Cached responses (written via toJson) already carry paise ints; live
    // Cloud responses carry rupee decimals under the Amount-suffixed keys.
    if (json.containsKey('totalPaise')) {
      return CloudExpenseSummary(
        totalPaise: _readInt(json, 'totalPaise'),
        cashPaise: _readInt(json, 'cashPaise'),
        upiPaise: _readInt(json, 'upiPaise'),
        cardPaise: _readInt(json, 'cardPaise'),
        expenseCount: _readInt(json, 'expenseCount'),
      );
    }
    return CloudExpenseSummary(
      totalPaise: _moneyPaise(json, 'totalAmount'),
      cashPaise: _moneyPaise(json, 'cashAmount'),
      upiPaise: _moneyPaise(json, 'upiAmount'),
      cardPaise: _moneyPaise(json, 'cardAmount'),
      expenseCount: _readInt(json, 'expenseCount'),
    );
  }

  Map<String, dynamic> toJson() => {
        'totalPaise': totalPaise,
        'cashPaise': cashPaise,
        'upiPaise': upiPaise,
        'cardPaise': cardPaise,
        'expenseCount': expenseCount,
      };

  static String _key(Map<String, dynamic> json, String key) =>
      json.containsKey(key) ? key : '${key[0].toUpperCase()}${key.substring(1)}';

  // Backend returns rupee amounts (decimal), matching MobileFinanceController's
  // other DTOs (CashBookEntryDto etc.), so convert to paise here for the UI.
  static int _moneyPaise(Map<String, dynamic> json, String key) {
    final value = json[_key(json, key)];
    if (value is num) return (value * 100).round();
    return ((double.tryParse(value?.toString() ?? '') ?? 0) * 100).round();
  }

  static int _readInt(Map<String, dynamic> json, String key) {
    final value = json[_key(json, key)];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

typedef CloudExpenseSummarySender = Future<Map<String, dynamic>> Function(Uri uri);

/// Fetches Expense Report summaries calculated server-side from authoritative
/// Cloud/PostgreSQL data. Never falls back to local SQLite for totals; on
/// failure, only a previously cached Cloud response (if any) is returned.
class CloudExpenseRepository {
  CloudExpenseRepository({
    MobileAuthService? auth,
    FlutterSecureStorage? secureStorage,
    CloudExpenseSummarySender? sender,
  })  : _auth = auth ?? MobileAuthService(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _sender = sender;

  static const _cacheKeyPrefix = 'cloud_expense_summary_';

  final MobileAuthService _auth;
  final FlutterSecureStorage _secureStorage;
  final CloudExpenseSummarySender? _sender;
  final Map<String, CloudExpenseSummary> _cache = {};

  Future<CloudExpenseSummary?> getExpenseSummary({
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

      final summary = CloudExpenseSummary.fromJson(response);
      await _writeCache(cacheKey, summary);
      return summary;
    } catch (_) {
      return await _readCache(cacheKey);
    }
  }

  Uri _buildUri(DateTime fromDate, DateTime toDate) {
    return Uri.parse('${_auth.baseUrl}/api/accounting/expense-summary').replace(
      queryParameters: {
        'from': _dateQuery(fromDate),
        'to': _dateQuery(toDate),
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
      final streamedResponse = await client.send(request).timeout(const Duration(seconds: 20));
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

  Future<CloudExpenseSummary?> _readCache(String key) async {
    final memoryHit = _cache[key];
    if (memoryHit != null) return memoryHit;

    try {
      final cached = await _secureStorage.read(key: key);
      if (cached == null || cached.trim().isEmpty) return null;
      final decoded = jsonDecode(cached);
      if (decoded is! Map<String, dynamic>) return null;
      final summary = CloudExpenseSummary.fromJson(decoded);
      _cache[key] = summary;
      return summary;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(String key, CloudExpenseSummary summary) async {
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
