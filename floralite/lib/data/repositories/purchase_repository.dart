import '../database/app_database.dart';

class PurchaseListItem {
  final int id;
  final String listDate;
  final int productId;
  final String productName;
  final String productCategory;
  final int quantity;
  final String unit;
  final String? supplier;
  final String priority;
  final String? remarks;
  final bool purchased;
  final bool inventoryUpdated;
  final String createdAt;
  final String updatedAt;

  const PurchaseListItem({
    required this.id,
    required this.listDate,
    required this.productId,
    required this.productName,
    required this.productCategory,
    required this.quantity,
    required this.unit,
    this.supplier,
    required this.priority,
    this.remarks,
    required this.purchased,
    required this.inventoryUpdated,
    required this.createdAt,
    required this.updatedAt,
  });
}

class PurchaseRepository {
  Future<List<PurchaseListItem>> getByDate(String date) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT 
        mpli.id,
        mpli.list_date,
        mpli.product_id,
        p.name as product_name,
        p.category as product_category,
        mpli.quantity,
        mpli.unit,
        mpli.supplier,
        mpli.priority,
        mpli.remarks,
        mpli.purchased,
        mpli.inventory_updated,
        mpli.created_at,
        mpli.updated_at
      FROM morning_purchase_list_items mpli
      INNER JOIN products p ON mpli.product_id = p.id
      WHERE mpli.list_date = ?
      AND mpli.deleted_at IS NULL
      ORDER BY p.category, p.name
    ''', [date]);

    return rows.map((row) => PurchaseListItem(
      id: row['id'] as int,
      listDate: row['list_date'] as String,
      productId: row['product_id'] as int,
      productName: row['product_name'] as String,
      productCategory: row['product_category'] as String,
      quantity: row['quantity'] as int,
      unit: row['unit'] as String,
      supplier: row['supplier'] as String?,
      priority: row['priority'] as String,
      remarks: row['remarks'] as String?,
      purchased: (row['purchased'] as int) == 1,
      inventoryUpdated: (row['inventory_updated'] as int) == 1,
      createdAt: row['created_at'] as String,
      updatedAt: row['updated_at'] as String,
    )).toList();
  }

  Future<PurchaseListItem> create({
    required String listDate,
    required int productId,
    required int quantity,
    required String unit,
    String? supplier,
    String priority = 'Normal',
    String? remarks,
  }) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final id = await db.insert('morning_purchase_list_items', {
      'list_date': listDate,
      'product_id': productId,
      'quantity': quantity,
      'unit': unit,
      'supplier': supplier,
      'priority': priority,
      'remarks': remarks,
      'purchased': 0,
      'inventory_updated': 0,
      'created_at': now,
      'updated_at': now,
    });

    // Fetch the created item with product details
    final rows = await db.rawQuery('''
      SELECT 
        mpli.id,
        mpli.list_date,
        mpli.product_id,
        p.name as product_name,
        p.category as product_category,
        mpli.quantity,
        mpli.unit,
        mpli.supplier,
        mpli.priority,
        mpli.remarks,
        mpli.purchased,
        mpli.inventory_updated,
        mpli.created_at,
        mpli.updated_at
      FROM morning_purchase_list_items mpli
      INNER JOIN products p ON mpli.product_id = p.id
      WHERE mpli.id = ?
    ''', [id]);

    final row = rows.first;
    return PurchaseListItem(
      id: row['id'] as int,
      listDate: row['list_date'] as String,
      productId: row['product_id'] as int,
      productName: row['product_name'] as String,
      productCategory: row['product_category'] as String,
      quantity: row['quantity'] as int,
      unit: row['unit'] as String,
      supplier: row['supplier'] as String?,
      priority: row['priority'] as String,
      remarks: row['remarks'] as String?,
      purchased: (row['purchased'] as int) == 1,
      inventoryUpdated: (row['inventory_updated'] as int) == 1,
      createdAt: row['created_at'] as String,
      updatedAt: row['updated_at'] as String,
    );
  }

  Future<void> update({
    required int id,
    int? quantity,
    String? unit,
    String? supplier,
    String? priority,
    String? remarks,
    bool? purchased,
  }) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    
    final updates = <String, dynamic>{
      'updated_at': now,
    };
    
    if (quantity != null) updates['quantity'] = quantity;
    if (unit != null) updates['unit'] = unit;
    if (supplier != null) updates['supplier'] = supplier;
    if (priority != null) updates['priority'] = priority;
    if (remarks != null) updates['remarks'] = remarks;
    if (purchased != null) updates['purchased'] = purchased ? 1 : 0;

    await db.update(
      'morning_purchase_list_items',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    
    await db.update(
      'morning_purchase_list_items',
      {'deleted_at': now, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markAllPurchased(String date) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    
    await db.update(
      'morning_purchase_list_items',
      {'purchased': 1, 'updated_at': now},
      where: 'list_date = ? AND purchased = 0 AND deleted_at IS NULL',
      whereArgs: [date],
    );
  }

  Future<void> clearPurchased(String date) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    
    await db.update(
      'morning_purchase_list_items',
      {'deleted_at': now, 'updated_at': now},
      where: 'list_date = ? AND purchased = 1 AND deleted_at IS NULL',
      whereArgs: [date],
    );
  }

  Future<int> getPendingCount(String date) async {
    final db = await AppDatabase.instance.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM morning_purchase_list_items
      WHERE list_date = ?
      AND purchased = 0
      AND deleted_at IS NULL
    ''', [date]);

    return result.first['count'] as int;
  }

  Future<int> getPurchasedCount(String date) async {
    final db = await AppDatabase.instance.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM morning_purchase_list_items
      WHERE list_date = ?
      AND purchased = 1
      AND deleted_at IS NULL
    ''', [date]);

    return result.first['count'] as int;
  }

  Future<List<Map<String, dynamic>>> getInventoryTrackedProducts() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'products',
      where: 'track_inventory = 1 AND active = 1 AND deleted_at IS NULL',
      orderBy: 'category, name',
    );

    return rows.map((row) => {
      'id': row['id'] as int,
      'name': row['name'] as String,
      'category': row['category'] as String,
      'default_unit': row['default_unit'] as String,
      'min_stock': row['min_stock'] as int,
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getLowStockProducts() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT 
        p.id,
        p.name,
        p.category,
        p.default_unit,
        p.min_stock,
        COALESCE(ii.current_qty, 0) as current_qty,
        p.min_stock - COALESCE(ii.current_qty, 0) as suggested_qty
      FROM products p
      LEFT JOIN inventory_items ii ON p.id = ii.product_id
      WHERE p.track_inventory = 1
      AND p.active = 1
      AND p.deleted_at IS NULL
      AND (ii.current_qty < p.min_stock OR ii.current_qty IS NULL)
      ORDER BY p.category, p.name
    ''');

    return rows.map((row) => {
      'id': row['id'] as int,
      'name': row['name'] as String,
      'category': row['category'] as String,
      'default_unit': row['default_unit'] as String,
      'min_stock': row['min_stock'] as int,
      'current_qty': row['current_qty'] as int,
      'suggested_qty': row['suggested_qty'] as int,
    }).toList();
  }
}
