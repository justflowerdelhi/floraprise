import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/day_closing.dart';
import '../../models/expense.dart';
import '../../models/expense_category.dart';
import '../../services/mobile_auth_service.dart';

typedef CloudFinanceSender = Future<dynamic> Function(
  String method,
  Uri uri, {
  Map<String, dynamic>? body,
});

class CloudExpenseRepository {
  CloudExpenseRepository({MobileAuthService? auth, CloudFinanceSender? sender})
      : _auth = auth ?? MobileAuthService(),
        _sender = sender;

  final MobileAuthService _auth;
  final CloudFinanceSender? _sender;

  Future<List<ExpenseCategory>> getCategories() async {
    final response = await _send('GET', Uri.parse('${_auth.baseUrl}/api/accounting/expense-categories'));
    if (response is! List || response.isEmpty) return _defaultCategories();
    return response.whereType<Map>().toList().asMap().entries.map((entry) {
      final row = entry.value.cast<String, dynamic>();
      return ExpenseCategory(
        id: -(entry.key + 1),
        name: _string(row, 'name'),
        emoji: _string(row, 'emoji', fallback: '•'),
        groupName: _string(row, 'groupName', fallback: 'Others'),
        active: row[_key(row, 'active')] != false,
        createdAt: _date(row, 'createdAtUtc'),
        updatedAt: _date(row, 'updatedAtUtc'),
      );
    }).toList();
  }

  List<ExpenseCategory> _defaultCategories() {
    const categories = [
      ('Purchase', 'Business'),
      ('Packing Material', 'Business'),
      ('Delivery', 'Business'),
      ('Marketing', 'Business'),
      ('Rent', 'Shop'),
      ('Electricity', 'Shop'),
      ('Phone & Internet', 'Shop'),
      ('Shop Maintenance', 'Shop'),
      ('Salary', 'Staff'),
      ('Tea & Snacks', 'Staff'),
      ('Fuel', 'Travel'),
      ('Miscellaneous', 'Others'),
    ];
    final now = DateTime.now();
    return [
      for (var index = 0; index < categories.length; index++)
        ExpenseCategory(
          id: -(index + 1),
          name: categories[index].$1,
          emoji: '',
          groupName: categories[index].$2,
          active: true,
          createdAt: now,
          updatedAt: now,
        ),
    ];
  }

  Future<List<Expense>> getByDate(DateTime date) async {
    final response = await _send(
      'GET',
      Uri.parse('${_auth.baseUrl}/api/accounting/expenses').replace(
        queryParameters: {'date': _dateQuery(date)},
      ),
    );
    if (response is! List) return const [];
    return response.whereType<Map>().toList().asMap().entries.map((entry) {
      final row = entry.value.cast<String, dynamic>();
      return Expense(
        id: -(entry.key + 1),
        amount: _paise(row, 'amount'),
        categoryId: 0,
        categoryName: _string(row, 'category', fallback: 'Expense'),
        paymentMode: PaymentModeExtension.fromString(_string(row, 'paymentMode')),
        notes: _nullableString(row, 'description'),
        expenseDate: _date(row, 'expenseDate'),
        createdAt: _date(row, 'expenseDate'),
        updatedAt: _date(row, 'expenseDate'),
      );
    }).toList();
  }

  Future<void> create({
    required ExpenseCategory category,
    required int amountPaise,
    required PaymentMode paymentMode,
    required String? notes,
    required DateTime date,
  }) => _send(
        'POST',
        Uri.parse('${_auth.baseUrl}/api/accounting/expenses'),
        body: {
          'category': category.name,
          'amount': amountPaise / 100,
          'paymentMode': paymentMode.name,
          if (notes?.trim().isNotEmpty == true) 'description': notes!.trim(),
          'expenseDate': _dateQuery(date),
        },
      );

  Future<dynamic> _send(String method, Uri uri, {Map<String, dynamic>? body}) async {
    final override = _sender;
    if (override != null) return override(method, uri, body: body);
    var token = await _auth.getStoredAccessToken();
    if (token == null || token.trim().isEmpty) throw StateError('Cloud session is not available. Please log in again.');
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
        final streamedResponse = await client.send(request).timeout(const Duration(seconds: 20));
        final text = await streamedResponse.stream.bytesToString();
        final statusCode = streamedResponse.statusCode;
        if (statusCode == 401 && attempt == 0) {
          final refreshed = await _auth.refreshAndBootstrap();
          token = refreshed.accessToken;
          continue;
        }
        if (statusCode < 200 || statusCode >= 300) throw StateError('Cloud finance request failed (HTTP $statusCode).');
        return text.trim().isEmpty ? <String, dynamic>{} : jsonDecode(text);
      } finally {
        client.close();
      }
    }
    throw StateError('Cloud finance request failed.');
  }

  static String _dateQuery(DateTime value) => DateTime.utc(value.year, value.month, value.day).toIso8601String();
  static String _key(Map<String, dynamic> row, String key) => row.containsKey(key) ? key : '${key[0].toUpperCase()}${key.substring(1)}';
  static String _string(Map<String, dynamic> row, String key, {String fallback = ''}) => row[_key(row, key)]?.toString() ?? fallback;
  static String? _nullableString(Map<String, dynamic> row, String key) { final value = _string(row, key).trim(); return value.isEmpty ? null : value; }
  static DateTime _date(Map<String, dynamic> row, String key) => DateTime.tryParse(_string(row, key)) ?? DateTime.fromMillisecondsSinceEpoch(0);
  static int _paise(Map<String, dynamic> row, String key) => ((num.tryParse(_string(row, key)) ?? 0) * 100).round();
}

class CloudDayCloseRepository {
  CloudDayCloseRepository({MobileAuthService? auth, CloudFinanceSender? sender})
      : _auth = auth ?? MobileAuthService(), _sender = sender;
  final MobileAuthService _auth;
  final CloudFinanceSender? _sender;

  Future<List<DayClosing>> getByDateRange(DateTime startDate, DateTime endDate) async {
    final locationId = await _locationId();
    final response = await _send(
      'GET',
      Uri.parse('${_auth.baseUrl}/api/day-close/history').replace(
        queryParameters: {
          'locationId': locationId,
          'startDate': _dateQuery(startDate),
          'endDate': _dateQuery(endDate),
        },
      ),
    );
    if (response is! List) return const [];
    return response.whereType<Map>().toList().asMap().entries.map((entry) {
      final row = entry.value.cast<String, dynamic>();
      final closedAt = CloudExpenseRepository._date(row, 'closedAt');
      final date = CloudExpenseRepository._date(row, 'businessDate');
      return DayClosing(
        id: -(entry.key + 1),
        date: date,
        cashSales: CloudExpenseRepository._paise(row, 'cashTotal'),
        upiSales: CloudExpenseRepository._paise(row, 'upiTotal'),
        cardSales: CloudExpenseRepository._paise(row, 'cardTotal'),
        creditSales: 0,
        cashExpenses: CloudExpenseRepository._paise(row, 'cashExpenses'),
        upiExpenses: 0,
        cardExpenses: 0,
        openingCash: 0,
        expectedCash: CloudExpenseRepository._paise(row, 'expectedCash'),
        countedCash: CloudExpenseRepository._paise(row, 'actualCash'),
        difference: CloudExpenseRepository._paise(row, 'cashVariance'),
        notes: CloudExpenseRepository._nullableString(row, 'notes'),
        closedAt: closedAt,
        createdAt: closedAt,
      );
    }).toList();
  }

  Future<Map<String, dynamic>> summary(DateTime date) async {
    final locationId = await _locationId();
    final response = await _send('GET', Uri.parse('${_auth.baseUrl}/api/day-close/summary').replace(queryParameters: {'locationId': locationId, 'date': _dateQuery(date)}));
    return (response as Map).cast<String, dynamic>();
  }

  Future<bool> isClosed(DateTime date) async {
    try {
      final locationId = await _locationId();
      final response = await _send('GET', Uri.parse('${_auth.baseUrl}/api/day-close/is-closed').replace(queryParameters: {'locationId': locationId, 'date': _dateQuery(date)}));
      if (response is Map) {
        return response['isClosed'] == true || response['IsClosed'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> close(DateTime date, int countedCashPaise, String? notes) async {
    final locationId = await _locationId();
    await _send('POST', Uri.parse('${_auth.baseUrl}/api/day-close'), body: {
      'locationId': locationId,
      'businessDate': _dateQuery(date),
      'actualCash': countedCashPaise / 100,
      if (notes?.trim().isNotEmpty == true) 'notes': notes!.trim(),
    });
  }

  Future<String> _locationId() async {
    final response = await _send('GET', Uri.parse('${_auth.baseUrl}/api/locations'));
    if (response is! List || response.isEmpty) throw StateError('No active Cloud location is available for Day Close.');
    final id = (response.first as Map)['id']?.toString() ?? '';
    if (id.isEmpty) throw StateError('Cloud location is missing its identifier.');
    return id;
  }

  Future<dynamic> _send(String method, Uri uri, {Map<String, dynamic>? body}) => CloudExpenseRepository(auth: _auth, sender: _sender)._send(method, uri, body: body);
  static String _dateQuery(DateTime value) => DateTime.utc(value.year, value.month, value.day).toIso8601String();
}