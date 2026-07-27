import '../database/app_database.dart';

class ProductCategoryRecord {
  final int id;
  final String name;
  final String defaultUnit;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  const ProductCategoryRecord({
    required this.id,
    required this.name,
    required this.defaultUnit,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
}

class CategoryRepository {
  Future<List<ProductCategoryRecord>> listCategories({
    bool includeInactive = true,
  }) async {
    final db = await AppDatabase.instance.database;
    final where = <String>['deleted_at IS NULL'];
    final args = <Object?>[];

    if (!includeInactive) {
      where.add('is_active = 1');
    }

    final rows = await db.query(
      'product_categories',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return rows.map(_mapCategory).toList();
  }

  Future<ProductCategoryRecord?> createCategory({
    required String name,
    required String defaultUnit,
  }) async {
    final db = await AppDatabase.instance.database;
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final now = DateTime.now().toIso8601String();
    final id = await db.insert('product_categories', {
      'name': trimmed,
      'normalized_name': trimmed.toLowerCase(),
      'default_unit': defaultUnit.trim(),
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
    });

    return getCategoryById(id);
  }

  Future<ProductCategoryRecord?> updateCategory({
    required int id,
    required String name,
    required String defaultUnit,
  }) async {
    final db = await AppDatabase.instance.database;
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    await db.update(
      'product_categories',
      {
        'name': trimmed,
        'normalized_name': trimmed.toLowerCase(),
        'default_unit': defaultUnit.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );

    return getCategoryById(id);
  }

  Future<void> setCategoryActive({
    required int id,
    required bool isActive,
  }) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'product_categories',
      {
        'is_active': isActive ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
  }

  Future<bool> isCategoryUsed(String categoryName) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM products
      WHERE deleted_at IS NULL
        AND LOWER(TRIM(category)) = ?
      ''',
      [categoryName.trim().toLowerCase()],
    );

    final count = (rows.first['count'] as int?) ?? 0;
    return count > 0;
  }

  Future<bool> deleteCategoryIfUnused(int id) async {
    final db = await AppDatabase.instance.database;
    final category = await getCategoryById(id);
    if (category == null) {
      return false;
    }

    final used = await isCategoryUsed(category.name);
    if (used) {
      return false;
    }

    await db.update(
      'product_categories',
      {
        'deleted_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );

    return true;
  }

  Future<ProductCategoryRecord?> getCategoryById(int id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'product_categories',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _mapCategory(rows.first);
  }

  ProductCategoryRecord _mapCategory(Map<String, Object?> row) {
    return ProductCategoryRecord(
      id: row['id'] as int,
      name: (row['name'] as String?) ?? '',
      defaultUnit: (row['default_unit'] as String?) ?? 'Piece',
      isActive: (row['is_active'] as int? ?? 1) == 1,
      createdAt: (row['created_at'] as String?) ?? '',
      updatedAt: (row['updated_at'] as String?) ?? '',
    );
  }
}
