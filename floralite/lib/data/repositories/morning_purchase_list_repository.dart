import '../../services/whatsapp_template_service.dart';
import '../database/app_database.dart';

class MarketProductRecord {
  final int productId;
  final String name;
  final String category;
  final String unit;
  final String supplier;
  final int currentQty;
  final int minQty;

  const MarketProductRecord({
    required this.productId,
    required this.name,
    required this.category,
    required this.unit,
    required this.supplier,
    required this.currentQty,
    required this.minQty,
  });

  int get suggestedQty {
    final delta = minQty - currentQty;
    return delta > 0 ? delta : 0;
  }
}

class MorningPurchaseListItem {
  final int id;
  final String listDate;
  final int productId;
  final String productName;
  final String category;
  final int quantity;
  final String unit;
  final String supplier;
  final String priority;
  final String remarks;
  final bool purchased;
  final bool inventoryUpdated;
  final int currentQty;
  final int minQty;
  final String createdAt;
  final String updatedAt;

  const MorningPurchaseListItem({
    required this.id,
    required this.listDate,
    required this.productId,
    required this.productName,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.supplier,
    required this.priority,
    required this.remarks,
    required this.purchased,
    required this.inventoryUpdated,
    required this.currentQty,
    required this.minQty,
    required this.createdAt,
    required this.updatedAt,
  });
}

class MorningPurchaseListRepository {
  static const List<String> supportedGroups = [
    'Flowers',
    'Fillers',
    'Foliage',
    'Packing',
    'Accessories',
    'Others',
  ];

  String _todayDateKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  String _normalizeCategory(String raw) {
    final value = raw.trim().toLowerCase();
    if (value == 'flower' || value == 'flowers') return 'Flowers';
    if (value == 'filler' || value == 'fillers') return 'Fillers';
    if (value == 'foliage') return 'Foliage';
    if (value == 'packing') return 'Packing';
    if (value == 'accessory' || value == 'accessories') return 'Accessories';
    return 'Others';
  }

  Future<List<MarketProductRecord>> listTrackedProducts({
    String search = '',
    String category = 'All',
  }) async {
    final db = await AppDatabase.instance.database;
    final where = <String>[
      'p.active = 1',
      'p.deleted_at IS NULL',
      'p.track_inventory = 1',
    ];
    final args = <Object?>[];

    final trimmed = search.trim().toLowerCase();
    if (trimmed.isNotEmpty) {
      where.add(
        '''
        (
          LOWER(p.name) LIKE ?
          OR LOWER(COALESCE(p.category, '')) LIKE ?
          OR LOWER(COALESCE(p.sku, '')) LIKE ?
          OR LOWER(COALESCE(p.manufacturer_barcode, '')) LIKE ?
        )
        ''',
      );
      final pattern = '%$trimmed%';
      args
        ..add(pattern)
        ..add(pattern)
        ..add(pattern)
        ..add(pattern);
    }

    if (category != 'All') {
      where.add('LOWER(COALESCE(p.category, "")) = ?');
      args.add(category.toLowerCase());
    }

    final rows = await db.rawQuery(
      '''
      SELECT
        p.id AS product_id,
        p.name,
        COALESCE(p.category, 'Others') AS category,
        COALESCE(NULLIF(p.default_unit, ''), 'Piece') AS default_unit,
        COALESCE(p.supplier, '') AS supplier,
        COALESCE(i.current_qty, 0) AS current_qty,
        COALESCE(i.min_qty, p.min_stock, 0) AS min_qty
      FROM products p
      LEFT JOIN inventory_items i ON i.product_id = p.id
      WHERE ${where.join(' AND ')}
      ORDER BY p.name COLLATE NOCASE ASC
      ''',
      args,
    );

    return rows
        .map(
          (row) => MarketProductRecord(
            productId: row['product_id'] as int,
            name: row['name'] as String,
            category:
                _normalizeCategory((row['category'] as String?) ?? 'Others'),
            unit: (row['default_unit'] as String?) ?? 'Piece',
            supplier: (row['supplier'] as String?) ?? '',
            currentQty: row['current_qty'] as int,
            minQty: row['min_qty'] as int,
          ),
        )
        .toList();
  }

  Future<List<MorningPurchaseListItem>> listTodayItems({
    String search = '',
    String statusFilter = 'All',
    String category = 'All',
  }) async {
    final db = await AppDatabase.instance.database;
    final where = <String>[
      'mpl.deleted_at IS NULL',
      'mpl.list_date = ?',
    ];
    final args = <Object?>[_todayDateKey()];

    if (statusFilter == 'Pending') {
      where.add('mpl.purchased = 0');
    } else if (statusFilter == 'Purchased') {
      where.add('mpl.purchased = 1');
    }

    if (category != 'All') {
      where.add('LOWER(COALESCE(p.category, "")) = ?');
      args.add(category.toLowerCase());
    }

    final trimmed = search.trim().toLowerCase();
    if (trimmed.isNotEmpty) {
      where.add(
        '''
        (
          LOWER(p.name) LIKE ?
          OR LOWER(COALESCE(p.category, '')) LIKE ?
        )
        ''',
      );
      final pattern = '%$trimmed%';
      args
        ..add(pattern)
        ..add(pattern);
    }

    final rows = await db.rawQuery(
      '''
      SELECT
        mpl.id,
        mpl.list_date,
        mpl.product_id,
        p.name AS product_name,
        COALESCE(p.category, 'Others') AS category,
        mpl.quantity,
        mpl.unit,
        COALESCE(mpl.supplier, '') AS supplier,
        mpl.priority,
        COALESCE(mpl.remarks, '') AS remarks,
        mpl.purchased,
        mpl.inventory_updated,
        COALESCE(i.current_qty, 0) AS current_qty,
        COALESCE(i.min_qty, p.min_stock, 0) AS min_qty,
        mpl.created_at,
        mpl.updated_at
      FROM morning_purchase_list_items mpl
      INNER JOIN products p ON p.id = mpl.product_id
      LEFT JOIN inventory_items i ON i.product_id = p.id
      WHERE ${where.join(' AND ')}
      ORDER BY
        CASE WHEN mpl.purchased = 1 THEN 1 ELSE 0 END ASC,
        LOWER(p.category) ASC,
        p.name COLLATE NOCASE ASC
      ''',
      args,
    );

    return rows.map(_mapItem).toList();
  }

  Future<int> todayCount() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM morning_purchase_list_items
      WHERE deleted_at IS NULL
        AND list_date = ?
      ''',
      [_todayDateKey()],
    );
    return (rows.first['count'] as int?) ?? 0;
  }

  Future<void> addOrUpdateTodayItem({
    required int productId,
    required int quantity,
    required String unit,
    String supplier = '',
    String priority = 'Normal',
    String remarks = '',
  }) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final today = _todayDateKey();

    final existing = await db.query(
      'morning_purchase_list_items',
      columns: ['id'],
      where: 'list_date = ? AND product_id = ? AND deleted_at IS NULL',
      whereArgs: [today, productId],
      limit: 1,
    );

    final row = <String, Object?>{
      'quantity': quantity,
      'unit': unit.trim().isEmpty ? 'Piece' : unit.trim(),
      'supplier': supplier.trim().isEmpty ? null : supplier.trim(),
      'priority': priority.trim().isEmpty ? 'Normal' : priority.trim(),
      'remarks': remarks.trim().isEmpty ? null : remarks.trim(),
      'updated_at': now,
    };

    if (existing.isEmpty) {
      await db.insert(
        'morning_purchase_list_items',
        {
          'list_date': today,
          'product_id': productId,
          ...row,
          'purchased': 0,
          'inventory_updated': 0,
          'created_at': now,
          'deleted_at': null,
        },
      );
      return;
    }

    await db.update(
      'morning_purchase_list_items',
      row,
      where: 'id = ?',
      whereArgs: [existing.first['id'] as int],
    );
  }

  Future<void> updateItem({
    required int id,
    required int quantity,
    required String unit,
    String supplier = '',
    String priority = 'Normal',
    String remarks = '',
  }) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'morning_purchase_list_items',
      {
        'quantity': quantity,
        'unit': unit.trim().isEmpty ? 'Piece' : unit.trim(),
        'supplier': supplier.trim().isEmpty ? null : supplier.trim(),
        'priority': priority.trim().isEmpty ? 'Normal' : priority.trim(),
        'remarks': remarks.trim().isEmpty ? null : remarks.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
  }

  Future<void> deleteItem(int id) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'morning_purchase_list_items',
      {'deleted_at': now, 'updated_at': now},
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
  }

  Future<void> setPurchased({required int id, required bool purchased}) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'morning_purchase_list_items',
      {
        'purchased': purchased ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
  }

  Future<void> clearPurchased() async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'morning_purchase_list_items',
      {'deleted_at': now, 'updated_at': now},
      where: 'list_date = ? AND purchased = 1 AND deleted_at IS NULL',
      whereArgs: [_todayDateKey()],
    );
  }

  Future<int> generateFromLowStock() async {
    final db = await AppDatabase.instance.database;
    final lowStockProducts = await db.rawQuery(
      '''
      SELECT
        p.id AS product_id,
        COALESCE(NULLIF(p.default_unit, ''), 'Piece') AS default_unit,
        COALESCE(p.supplier, '') AS supplier,
        COALESCE(i.current_qty, 0) AS current_qty,
        COALESCE(i.min_qty, p.min_stock, 0) AS min_qty
      FROM products p
      LEFT JOIN inventory_items i ON i.product_id = p.id
      WHERE p.active = 1
        AND p.deleted_at IS NULL
        AND p.track_inventory = 1
        AND COALESCE(i.current_qty, 0) < COALESCE(i.min_qty, p.min_stock, 0)
      ORDER BY p.name COLLATE NOCASE ASC
      ''',
    );

    final now = DateTime.now().toIso8601String();
    final today = _todayDateKey();
    var added = 0;

    for (final row in lowStockProducts) {
      final productId = row['product_id'] as int;
      final currentQty = (row['current_qty'] as int?) ?? 0;
      final minQty = (row['min_qty'] as int?) ?? 0;
      final suggested = minQty - currentQty;
      if (suggested <= 0) {
        continue;
      }

      final exists = await db.query(
        'morning_purchase_list_items',
        columns: ['id'],
        where: 'list_date = ? AND product_id = ? AND deleted_at IS NULL',
        whereArgs: [today, productId],
        limit: 1,
      );
      if (exists.isNotEmpty) {
        continue;
      }

      await db.insert(
        'morning_purchase_list_items',
        {
          'list_date': today,
          'product_id': productId,
          'quantity': suggested,
          'unit': (row['default_unit'] as String?) ?? 'Piece',
          'supplier': ((row['supplier'] as String?) ?? '').trim().isEmpty
              ? null
              : (row['supplier'] as String),
          'priority': 'Normal',
          'remarks': 'Auto suggested from minimum stock',
          'purchased': 0,
          'inventory_updated': 0,
          'created_at': now,
          'updated_at': now,
          'deleted_at': null,
        },
      );
      added++;
    }

    return added;
  }

  Future<List<MorningPurchaseListItem>>
      listPurchasedForInventoryUpdate() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT
        mpl.id,
        mpl.list_date,
        mpl.product_id,
        p.name AS product_name,
        COALESCE(p.category, 'Others') AS category,
        mpl.quantity,
        mpl.unit,
        COALESCE(mpl.supplier, '') AS supplier,
        mpl.priority,
        COALESCE(mpl.remarks, '') AS remarks,
        mpl.purchased,
        mpl.inventory_updated,
        COALESCE(i.current_qty, 0) AS current_qty,
        COALESCE(i.min_qty, p.min_stock, 0) AS min_qty,
        mpl.created_at,
        mpl.updated_at
      FROM morning_purchase_list_items mpl
      INNER JOIN products p ON p.id = mpl.product_id
      LEFT JOIN inventory_items i ON i.product_id = p.id
      WHERE mpl.deleted_at IS NULL
        AND mpl.list_date = ?
        AND mpl.purchased = 1
        AND mpl.inventory_updated = 0
      ORDER BY p.name COLLATE NOCASE ASC
      ''',
      [_todayDateKey()],
    );

    return rows.map(_mapItem).toList();
  }

  Future<void> markInventoryUpdated(int id) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'morning_purchase_list_items',
      {
        'inventory_updated': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
  }

  Future<String> buildWhatsappText() async {
    final items = await listTodayItems(statusFilter: 'Pending');
    return WhatsAppTemplateService().purchaseList(
      items: items
          .map(
            (item) => WhatsAppItemLine(
              name: item.productName,
              quantity: item.quantity,
              unit: item.unit,
              category: _normalizeCategory(item.category),
              remark: item.remarks.trim().isEmpty ? null : item.remarks.trim(),
            ),
          )
          .toList(),
      requestedBy: null,
    );
  }

  MorningPurchaseListItem _mapItem(Map<String, Object?> row) {
    return MorningPurchaseListItem(
      id: row['id'] as int,
      listDate: (row['list_date'] as String?) ?? '',
      productId: row['product_id'] as int,
      productName: (row['product_name'] as String?) ?? '',
      category: _normalizeCategory((row['category'] as String?) ?? 'Others'),
      quantity: (row['quantity'] as int?) ?? 0,
      unit: (row['unit'] as String?) ?? 'Piece',
      supplier: (row['supplier'] as String?) ?? '',
      priority: (row['priority'] as String?) ?? 'Normal',
      remarks: (row['remarks'] as String?) ?? '',
      purchased: (row['purchased'] as int? ?? 0) == 1,
      inventoryUpdated: (row['inventory_updated'] as int? ?? 0) == 1,
      currentQty: (row['current_qty'] as int?) ?? 0,
      minQty: (row['min_qty'] as int?) ?? 0,
      createdAt: (row['created_at'] as String?) ?? '',
      updatedAt: (row['updated_at'] as String?) ?? '',
    );
  }
}
