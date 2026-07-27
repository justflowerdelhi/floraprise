import '../database/app_database.dart';
import '../../models/day_closing.dart';

class DayClosingRepository {
  Future<DayClosing?> getByDate(DateTime date) async {
    final db = await AppDatabase.instance.database;
    final dateStr = _dateToIso(date);
    final rows = await db.query(
      'day_closing',
      where: 'date = ?',
      whereArgs: [dateStr],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DayClosing.fromMap(rows.first);
  }

  Future<DayClosing> create(DayClosing dayClosing) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final closedAt = DateTime.now().toIso8601String();
    final id = await db.insert('day_closing', {
      'date': _dateToIso(dayClosing.date),
      'cash_sales': dayClosing.cashSales,
      'upi_sales': dayClosing.upiSales,
      'card_sales': dayClosing.cardSales,
      'credit_sales': dayClosing.creditSales,
      'cash_expenses': dayClosing.cashExpenses,
      'upi_expenses': dayClosing.upiExpenses,
      'card_expenses': dayClosing.cardExpenses,
      'opening_cash': dayClosing.openingCash,
      'expected_cash': dayClosing.expectedCash,
      'counted_cash': dayClosing.countedCash,
      'difference': dayClosing.difference,
      'notes': dayClosing.notes,
      'closed_at': closedAt,
      'created_at': now,
    });
    return dayClosing.copyWith(
      id: id,
      closedAt: DateTime.parse(closedAt),
      createdAt: DateTime.parse(now),
    );
  }

  Future<DayClosing> update(DayClosing dayClosing) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'day_closing',
      {
        'cash_sales': dayClosing.cashSales,
        'upi_sales': dayClosing.upiSales,
        'card_sales': dayClosing.cardSales,
        'credit_sales': dayClosing.creditSales,
        'cash_expenses': dayClosing.cashExpenses,
        'upi_expenses': dayClosing.upiExpenses,
        'card_expenses': dayClosing.cardExpenses,
        'opening_cash': dayClosing.openingCash,
        'expected_cash': dayClosing.expectedCash,
        'counted_cash': dayClosing.countedCash,
        'difference': dayClosing.difference,
        'notes': dayClosing.notes,
        'closed_at': dayClosing.closedAt.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [dayClosing.id],
    );
    return dayClosing.copyWith(closedAt: DateTime.parse(now));
  }

  Future<List<DayClosing>> getByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await AppDatabase.instance.database;
    final startStr = _dateToIso(startDate);
    final endStr = _dateToIso(endDate);
    final rows = await db.query(
      'day_closing',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startStr, endStr],
      orderBy: 'date DESC',
    );
    return rows.map((row) => DayClosing.fromMap(row)).toList();
  }

  String _dateToIso(DateTime date) {
    return DateTime(date.year, date.month, date.day).toIso8601String();
  }
}
