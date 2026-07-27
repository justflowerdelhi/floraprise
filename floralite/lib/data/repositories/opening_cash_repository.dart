import '../database/app_database.dart';
import '../../models/opening_cash.dart';

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
