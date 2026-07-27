import '../database/app_database.dart';
import '../../models/expense.dart';

class ExpenseRepository {
  Future<List<Expense>> getByDate(DateTime date) async {
    final db = await AppDatabase.instance.database;
    final dateStr = _dateToIso(date);
    final rows = await db.query(
      'expenses',
      where: 'expense_date = ?',
      whereArgs: [dateStr],
      orderBy: 'created_at DESC',
    );
    return rows.map((row) => Expense.fromMap(row)).toList();
  }

  Future<List<Expense>> getByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await AppDatabase.instance.database;
    final startStr = _dateToIso(startDate);
    final endStr = _dateToIso(endDate);
    final rows = await db.query(
      'expenses',
      where: 'expense_date BETWEEN ? AND ?',
      whereArgs: [startStr, endStr],
      orderBy: 'expense_date DESC, created_at DESC',
    );
    return rows.map((row) => Expense.fromMap(row)).toList();
  }

  Future<List<Expense>> getByPaymentMode(PaymentMode paymentMode, DateTime date) async {
    final db = await AppDatabase.instance.database;
    final dateStr = _dateToIso(date);
    final rows = await db.query(
      'expenses',
      where: 'payment_mode = ? AND expense_date = ?',
      whereArgs: [paymentMode.name, dateStr],
      orderBy: 'created_at DESC',
    );
    return rows.map((row) => Expense.fromMap(row)).toList();
  }

  Future<Expense> create(Expense expense) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final id = await db.insert('expenses', {
      'amount': expense.amount,
      'category_id': expense.categoryId,
      'payment_mode': expense.paymentMode.name,
      'notes': expense.notes,
      'expense_date': _dateToIso(expense.expenseDate),
      'created_at': now,
      'updated_at': now,
    });
    return expense.copyWith(
      id: id,
      createdAt: DateTime.parse(now),
      updatedAt: DateTime.parse(now),
    );
  }

  Future<Expense> update(Expense expense) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'expenses',
      {
        'amount': expense.amount,
        'category_id': expense.categoryId,
        'payment_mode': expense.paymentMode.name,
        'notes': expense.notes,
        'expense_date': _dateToIso(expense.expenseDate),
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [expense.id],
    );
    return expense.copyWith(updatedAt: DateTime.parse(now));
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getTotalByPaymentMode(PaymentMode paymentMode, DateTime date) async {
    final db = await AppDatabase.instance.database;
    final dateStr = _dateToIso(date);
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total FROM expenses
      WHERE payment_mode = ? AND expense_date = ?
    ''', [paymentMode.name, dateStr]);
    return (result.first['total'] as int?) ?? 0;
  }

  String _dateToIso(DateTime date) {
    return DateTime(date.year, date.month, date.day).toIso8601String();
  }
}
