import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../database/app_database.dart';
import '../../models/cash_book.dart';
import '../../services/mobile_auth_service.dart';

typedef CloudCashBookSender = Future<dynamic> Function(String method, Uri uri);

class CashBookRepository {
  Future<List<CashBook>> getByDate(DateTime date) async {
    final db = await AppDatabase.instance.database;
    final dateStr = _dateToIso(date);
    final rows = await db.query(
      'cash_book',
      where: 'date = ?',
      whereArgs: [dateStr],
      orderBy: 'created_at ASC',
    );
    return rows.map((row) => CashBook.fromMap(row)).toList();
  }

  Future<List<CashBook>> getByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await AppDatabase.instance.database;
    final startStr = _dateToIso(startDate);
    final endStr = _dateToIso(endDate);
    final rows = await db.rawQuery('''
      SELECT * FROM cash_book
      WHERE date BETWEEN ? AND ?
      ORDER BY created_at ASC
    ''', [startStr, endStr]);
    return rows.map((row) => CashBook.fromMap(row)).toList();
  }

  Future<List<CashBook>> search(String query, DateTime? startDate, DateTime? endDate) async {
    final db = await AppDatabase.instance.database;
    String whereClause = 'description LIKE ?';
    List<dynamic> whereArgs = ['%$query%'];

    if (startDate != null && endDate != null) {
      whereClause += ' AND date BETWEEN ? AND ?';
      whereArgs.add(_dateToIso(startDate));
      whereArgs.add(_dateToIso(endDate));
    }

    final rows = await db.query(
      'cash_book',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
    return rows.map((row) => CashBook.fromMap(row)).toList();
  }

  Future<int> getCurrentBalance(DateTime date) async {
    final db = await AppDatabase.instance.database;
    final dateStr = _dateToIso(date);
    final result = await db.rawQuery('''
      SELECT running_balance FROM cash_book
      WHERE date = ?
      ORDER BY created_at DESC
      LIMIT 1
    ''', [dateStr]);
    if (result.isEmpty) return 0;
    return result.first['running_balance'] as int;
  }

  Future<CashBook> create({
    required DateTime date,
    required CashBookTransactionType transactionType,
    required String description,
    required int amount,
    required int cashIn,
    required int cashOut,
  }) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final dateStr = _dateToIso(date);

    final currentBalance = await getCurrentBalance(date);
    final runningBalance = currentBalance + cashIn - cashOut;

    final id = await db.insert('cash_book', {
      'date': dateStr,
      'transaction_type': transactionType.name,
      'description': description,
      'amount': amount,
      'cash_in': cashIn,
      'cash_out': cashOut,
      'running_balance': runningBalance,
      'created_at': now,
    });

    return CashBook(
      id: id,
      date: date,
      transactionType: transactionType,
      description: description,
      amount: amount,
      cashIn: cashIn,
      cashOut: cashOut,
      runningBalance: runningBalance,
      createdAt: DateTime.parse(now),
    );
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      'cash_book',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  String _dateToIso(DateTime date) {
    return DateTime(date.year, date.month, date.day).toIso8601String();
  }
}

class CloudCashBookRepository {
  CloudCashBookRepository({
    MobileAuthService? auth,
    CloudCashBookSender? sender,
  })  : _auth = auth ?? MobileAuthService(),
        _sender = sender;

  final MobileAuthService _auth;
  final CloudCashBookSender? _sender;

  Future<List<CashBook>> getByDate(DateTime date) async {
    final response = await _send(
      'GET',
      Uri.parse('${_auth.baseUrl}/api/accounting/cash-book').replace(
        queryParameters: {'date': _dateQueryValue(date)},
      ),
    );
    if (response is! List) return const [];

    return response
        .whereType<Map>()
        .map((entry) => entry.cast<String, dynamic>())
        .toList()
        .asMap()
        .entries
        .map((entry) => _fromCloudJson(entry.value, -(entry.key + 1)))
        .toList();
  }

  Future<List<CashBook>> search(
    String query,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    final queryParameters = <String, String>{
      'query': query,
      if (startDate != null && endDate != null)
        'from': _dateQueryValue(startDate),
      if (startDate != null && endDate != null) 'to': _dateQueryValue(endDate),
    };
    final response = await _send(
      'GET',
      Uri.parse('${_auth.baseUrl}/api/accounting/cash-book').replace(
        queryParameters: queryParameters,
      ),
    );
    if (response is! List) return const [];

    return response
        .whereType<Map>()
        .map((entry) => entry.cast<String, dynamic>())
        .toList()
        .asMap()
        .entries
        .map((entry) => _fromCloudJson(entry.value, -(entry.key + 1)))
        .toList();
  }

  Future<dynamic> _send(String method, Uri uri) async {
    final override = _sender;
    if (override != null) {
      return override(method, uri);
    }

    var token = await _auth.getStoredAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw StateError('Cloud session is not available. Please log in again.');
    }

    debugPrint('[CASH-BOOK-CLOUD] $method $uri');
    for (var attempt = 0; attempt < 2; attempt++) {
      final client = http.Client();
      try {
        final request = http.Request(method, uri);
        request.headers['Accept'] = 'application/json';
        request.headers['Authorization'] = 'Bearer $token';

        final streamedResponse =
            await client.send(request).timeout(const Duration(seconds: 20));
        final responseBody = await streamedResponse.stream.bytesToString();
        final statusCode = streamedResponse.statusCode;
        debugPrint('[CASH-BOOK-CLOUD] HTTP STATUS: $statusCode');

        if (statusCode == 401 && attempt == 0) {
          final refreshed = await _auth.refreshAndBootstrap();
          token = refreshed.accessToken;
          continue;
        }

        final decoded = responseBody.trim().isEmpty
            ? <String, dynamic>{}
            : _decode(responseBody);
        if (statusCode < 200 || statusCode >= 300) {
          final message = decoded is Map
              ? decoded['message'] ??
                  decoded['detail'] ??
                  decoded['title'] ??
                  decoded['error']
              : null;
          throw StateError(
            message?.toString() ??
                'Cloud cash book request failed (HTTP $statusCode).',
          );
        }
        return decoded;
      } catch (error) {
        if (error is StateError) rethrow;
        throw StateError('Unable to connect to Floraprise Cloud: $error');
      } finally {
        client.close();
      }
    }
    throw StateError('Cloud cash book request failed.');
  }

  CashBook _fromCloudJson(Map<String, dynamic> json, int id) {
    return CashBook(
      id: id,
      date: _date(json, 'date'),
      transactionType: CashBookTransactionTypeExtension.fromString(
        _string(json, 'transactionType'),
      ),
      description: _string(json, 'description'),
      amount: _moneyPaise(json, 'amount'),
      cashIn: _moneyPaise(json, 'cashIn'),
      cashOut: _moneyPaise(json, 'cashOut'),
      runningBalance: _moneyPaise(json, 'runningBalance'),
      createdAt: _date(json, 'createdAtUtc'),
    );
  }

  static dynamic _decode(String text) {
    try {
      return jsonDecode(text);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

    static String _dateQueryValue(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day).toIso8601String();

  static String _key(Map<String, dynamic> json, String key) =>
      json.containsKey(key) ? key : '${key[0].toUpperCase()}${key.substring(1)}';

  static String _string(Map<String, dynamic> json, String key) =>
      json[_key(json, key)]?.toString() ?? '';

  static DateTime _date(Map<String, dynamic> json, String key) {
    return DateTime.tryParse(_string(json, key)) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  static int _moneyPaise(Map<String, dynamic> json, String key) {
    final value = json[_key(json, key)];
    if (value is num) return (value * 100).round();
    return ((double.tryParse(value?.toString() ?? '') ?? 0) * 100).round();
  }
}
