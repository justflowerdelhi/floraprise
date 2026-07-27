import '../database/app_database.dart';
import '../../models/expense_category.dart';

class ExpenseCategoryRepository {
  Future<List<ExpenseCategory>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'expense_categories',
      where: 'active = ?',
      whereArgs: [1],
      orderBy: 'group_name, name',
    );
    return rows.map((row) => ExpenseCategory.fromMap(row)).toList();
  }

  Future<List<ExpenseCategory>> getByGroup(String groupName) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'expense_categories',
      where: 'group_name = ? AND active = ?',
      whereArgs: [groupName, 1],
      orderBy: 'name',
    );
    return rows.map((row) => ExpenseCategory.fromMap(row)).toList();
  }

  Future<ExpenseCategory?> getById(int id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'expense_categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ExpenseCategory.fromMap(rows.first);
  }

  Future<ExpenseCategory> create(ExpenseCategory category) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final id = await db.insert('expense_categories', {
      'name': category.name,
      'emoji': category.emoji,
      'group_name': category.groupName,
      'active': 1,
      'created_at': now,
      'updated_at': now,
    });
    return category.copyWith(
      id: id,
      createdAt: DateTime.parse(now),
      updatedAt: DateTime.parse(now),
    );
  }

  Future<ExpenseCategory> update(ExpenseCategory category) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'expense_categories',
      {
        'name': category.name,
        'emoji': category.emoji,
        'group_name': category.groupName,
        'active': category.active ? 1 : 0,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [category.id],
    );
    return category.copyWith(updatedAt: DateTime.parse(now));
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'expense_categories',
      {'active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<String>> getGroups() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
      'SELECT DISTINCT group_name FROM expense_categories WHERE active = 1 ORDER BY group_name',
    );
    return rows.map((row) => row['group_name'] as String).toList();
  }
}
