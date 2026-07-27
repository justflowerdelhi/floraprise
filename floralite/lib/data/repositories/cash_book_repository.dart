import '../database/app_database.dart';
import '../../models/cash_book.dart';

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
