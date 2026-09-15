import 'dart:convert';
import 'package:http/http.dart' as http;

import '../database/app_database.dart';
import '../../models/opening_cash.dart';
import '../../services/mobile_auth_service.dart';

class OpeningCashRepository {
  Future<OpeningCash?> getByDate(DateTime date) async {
    final db = await AppDatabase.instance.database;
    final dateStr = _dateToIso(date);
    final rows = await db.query(
      'opening_cash',
      where: 'date = ?',
      whereArgs: [dateStr],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return OpeningCash.fromMap(rows.first);
  }

  Future<OpeningCash> create(int amount, DateTime date) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final dateStr = _dateToIso(date);
    final id = await db.insert('opening_cash', {
      'date': dateStr,
      'amount': amount,
      'created_at': now,
      'updated_at': now,
    });
    return OpeningCash(
      id: id,
      date: date,
      amount: amount,
      createdAt: DateTime.parse(now),
      updatedAt: DateTime.parse(now),
    );
  }

  Future<OpeningCash> update(OpeningCash openingCash) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'opening_cash',
      {
        'amount': openingCash.amount,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [openingCash.id],
    );
    return openingCash.copyWith(updatedAt: DateTime.parse(now));
  }

  Future<bool> hasTransactionsForDate(DateTime date) async {
    final db = await AppDatabase.instance.database;
    final dateStr = _dateToIso(date);
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM cash_book WHERE date = ?',
      [dateStr],
    );
    return (result.first['count'] as int) > 0;
  }

  String _dateToIso(DateTime date) {
    return DateTime(date.year, date.month, date.day).toIso8601String();
  }
}

class CloudOpeningCashEntry {
  const CloudOpeningCashEntry({required this.id, required this.openingCash});

  final String id;
  final OpeningCash openingCash;
}

class CloudOpeningCashRepository {
  CloudOpeningCashRepository({MobileAuthService? auth})
      : _auth = auth ?? MobileAuthService();

  final MobileAuthService _auth;

  Future<CloudOpeningCashEntry?> getByDate(DateTime date) async {
    final dateStr = DateTime.utc(date.year, date.month, date.day).toIso8601String();
    final token = await _auth.getStoredAccessToken();
    if (token == null || token.trim().isEmpty) return null;

    final client = http.Client();
    try {
      final uri = Uri.parse('${_auth.baseUrl}/api/accounting/opening-cash').replace(
        queryParameters: {'date': dateStr},
      );
      final request = http.Request('GET', uri);
      request.headers['Accept'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $token';

      final streamedResponse =
          await client.send(request).timeout(const Duration(seconds: 15));
      if (streamedResponse.statusCode == 404) return null;
      if (streamedResponse.statusCode < 200 || streamedResponse.statusCode >= 300) {
        return null;
      }

      final body = await streamedResponse.stream.bytesToString();
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;

      final amountRupees =
          (decoded['amount'] ?? decoded['Amount']) as num? ?? 0;
      final amountPaise = (amountRupees * 100).round();
      final idStr =
          decoded['id']?.toString() ?? decoded['Id']?.toString() ?? '';

      return CloudOpeningCashEntry(
        id: idStr,
        openingCash: OpeningCash(
          id: -1,
          date: date,
          amount: amountPaise,
          createdAt: DateTime.tryParse(decoded['createdAtUtc']?.toString() ?? '') ?? date,
          updatedAt: DateTime.tryParse(decoded['updatedAtUtc']?.toString() ?? '') ?? date,
        ),
      );
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  Future<void> save(DateTime date, int amountPaise, {String? cloudId}) async {
    final dateStr = DateTime.utc(date.year, date.month, date.day).toIso8601String();
    final token = await _auth.getStoredAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw StateError('Cloud session is not available. Please log in again.');
    }

    final client = http.Client();
    try {
      final bool isUpdate = cloudId != null && cloudId.trim().isNotEmpty;
      final uri = isUpdate
          ? Uri.parse('${_auth.baseUrl}/api/accounting/opening-cash/$cloudId')
          : Uri.parse('${_auth.baseUrl}/api/accounting/opening-cash');
      final request = http.Request(isUpdate ? 'PUT' : 'POST', uri);
      request.headers['Accept'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'date': dateStr,
        'amount': amountPaise / 100.0,
      });

      final streamedResponse =
          await client.send(request).timeout(const Duration(seconds: 15));
      final body = await streamedResponse.stream.bytesToString();
      if (streamedResponse.statusCode < 200 || streamedResponse.statusCode >= 300) {
        final decoded = jsonDecode(body);
        final message = decoded is Map
            ? (decoded['message'] ?? decoded['title'])
            : null;
        throw StateError(
          message?.toString() ??
              'Failed to save opening cash (HTTP ${streamedResponse.statusCode}).',
        );
      }
    } finally {
      client.close();
    }
  }
}
