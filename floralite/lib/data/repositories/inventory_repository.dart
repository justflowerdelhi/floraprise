import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../../models/gst_calculation_type.dart';

class InventoryProductRecord {
  final int productId;
  final String? cloudProductId;
  final String name;
  final String category;
  final String unit;
  final String sku;
  final String barcode;
  final String? manufacturerBarcode;
  final String? internalBarcode;
  final bool trackInventory;
  final int gstPercent;
  final GstCalculationType gstCalculationType;
  final int currentQty;
  final int minQty;

  const InventoryProductRecord({
    required this.productId,
    this.cloudProductId,
    required this.name,
    required this.category,
    required this.unit,
    required this.sku,
    required this.barcode,
    this.manufacturerBarcode,
    this.internalBarcode,
    required this.trackInventory,
    required this.gstPercent,
    required this.gstCalculationType,
    required this.currentQty,
    required this.minQty,
  });
}

class InventoryTransactionRecord {
  final int id;
  final String? cloudId;
  final int productId;
  final String txnType;
  final int qty;
  final int? purchasePricePaise;
  final String supplier;
  final String source;
  final String reason;
  final String note;
  final String createdAt;
  final int? previousQty;
  final int? balanceAfter;
  final String? productName;
  final String? category;
  final String? unit;

  const InventoryTransactionRecord({
    required this.id,
    this.cloudId,
    required this.productId,
    required this.txnType,
    required this.qty,
    required this.purchasePricePaise,
    required this.supplier,
    required this.source,
    required this.reason,
    required this.note,
    required this.createdAt,
    this.previousQty,
    this.balanceAfter,
    this.productName,
    this.category,
    this.unit,
  });
}

class InventoryRepository {
  Future<void> createSaleTransaction({
    required int productId,
    required int orderId,
    required int orderLineId,
    required int quantity,
    String? note,
  }) async {
    if (quantity <= 0) {
      throw StateError('Quantity must be greater than zero');
    }
    final db = await AppDatabase.instance.database;
    await _applyTransaction(
      db: db,
      productId: productId,
      quantity: quantity,
      delta: -quantity,
      txnType: 'sale',
      source: 'Walk-in Sale',
      note: note,
      orderId: orderId,
      orderLineId: orderLineId,
    );
  }

  Future<int> createConfirmedOrderSaleTransactionInTransaction({
    required Transaction transaction,
    required int productId,
    required int orderId,
    required int orderLineId,
    required int quantity,
    String? note,
  }) async {
    if (quantity <= 0) {
      throw StateError('Quantity must be greater than zero');
    }
    return _applyTransactionInExecutor(
      db: transaction,
      productId: productId,
      quantity: quantity,
      delta: -quantity,
      txnType: 'sale',
      source: 'Walk-in Sale',
      note: note,
      orderId: orderId,
      orderLineId: orderLineId,
    );
  }

  Future<void> createPurchaseTransaction({
    required int productId,
    required int quantity,
    required int purchasePricePaise,
    String? supplier,
    String? note,
  }) async {
    if (quantity <= 0) {
      throw StateError('Quantity must be greater than zero');
    }
    if (purchasePricePaise <= 0) {
      throw StateError('Purchase price must be greater than zero');
    }

    final db = await AppDatabase.instance.database;
    await _applyTransaction(
      db: db,
      productId: productId,
      quantity: quantity,
      delta: quantity,
      txnType: 'purchase',
      source: 'Manual',
      purchasePricePaise: purchasePricePaise,
      supplier: supplier,
      note: note,
    );
  }

  Future<void> createManualSaleTransaction({
    required int productId,
    required int quantity,
    String? note,
  }) async {
    if (quantity <= 0) {
      throw StateError('Quantity must be greater than zero');
    }

    final db = await AppDatabase.instance.database;
    await _applyTransaction(
      db: db,
      productId: productId,
      quantity: quantity,
      delta: -quantity,
      txnType: 'sale',
      source: 'Manual',
      note: note,
    );
  }

  Future<void> createWastageTransaction({
    required int productId,
    required int quantity,
    required String reason,
    String? note,
  }) async {
    if (quantity <= 0) {
      throw StateError('Quantity must be greater than zero');
    }

    final db = await AppDatabase.instance.database;
    await _applyTransaction(
      db: db,
      productId: productId,
      quantity: quantity,
      delta: -quantity,
      txnType: 'wastage',
      source: 'Manual',
      reason: reason,
      note: note,
    );
  }

  Future<void> createAdjustmentTransaction({
    required int productId,
    required int quantity,
    required bool increase,
    String? note,
  }) async {
    if (quantity <= 0) {
      throw StateError('Quantity must be greater than zero');
    }

    final db = await AppDatabase.instance.database;
    final delta = increase ? quantity : -quantity;
    await _applyTransaction(
      db: db,
      productId: productId,
      quantity: quantity,
      delta: delta,
      txnType: 'adjustment',
      source: 'Manual',
      reason: increase ? 'Increase' : 'Decrease',
      note: note,
    );
  }

  Future<List<InventoryProductRecord>> listInventoryProducts() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT
        p.id AS product_id,
        p.name,
        p.category,
        p.default_unit,
        COALESCE(p.sku, '') AS sku,
        COALESCE(NULLIF(p.manufacturer_barcode, ''), NULLIF(p.floraprise_barcode, ''), COALESCE(p.barcode, '')) AS barcode,
        p.track_inventory,
        p.gst_percent,
        p.gst_calculation_type,
        COALESCE(i.current_qty, 0) AS current_qty,
        COALESCE(i.min_qty, p.min_stock, 0) AS min_qty
      FROM products p
      LEFT JOIN inventory_items i ON i.product_id = p.id
      WHERE p.active = 1 AND p.deleted_at IS NULL
      ORDER BY p.name COLLATE NOCASE ASC
    ''');

    return rows
        .map(
          (row) => InventoryProductRecord(
            productId: row['product_id'] as int,
            name: row['name'] as String,
            category: (row['category'] as String?) ?? 'Other',
            unit: (row['default_unit'] as String?) ?? 'Piece',
            sku: (row['sku'] as String?) ?? '',
            barcode: (row['barcode'] as String?) ?? '',
            trackInventory: (row['track_inventory'] as int? ?? 0) == 1,
            gstPercent: (row['gst_percent'] as int?) ?? 0,
            gstCalculationType: GstCalculationType.fromStorage(
              row['gst_calculation_type'] as String?,
            ),
            currentQty: row['current_qty'] as int,
            minQty: row['min_qty'] as int,
          ),
        )
        .toList();
  }

  Future<List<InventoryTransactionRecord>> getWastageTransactions({
    required DateTime startDate,
    required DateTime endDate,
    String? category,
    int? productId,
    String? supplier,
    String? reason,
  }) async {
    final db = await AppDatabase.instance.database;

    // First, check what txn_type values actually exist
    final allTxnTypes = await db
        .rawQuery('SELECT DISTINCT txn_type FROM inventory_transactions');
    debugPrint(
        'Available txn_type values: ${allTxnTypes.map((r) => r['txn_type']).toList()}');

    // Check wastage transactions without date filter first
    final allWastage = await db.rawQuery(
        "SELECT COUNT(*) as count FROM inventory_transactions WHERE txn_type IN ('wastage', 'expired_bouquet')");
    debugPrint(
        'Total wastage transactions in DB: ${allWastage.first['count']}');

    final startOfDay = DateTime(startDate.year, startDate.month, startDate.day)
        .toIso8601String();
    final endOfDay =
        DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59)
            .toIso8601String();

    debugPrint('Date range filter: $startOfDay to $endOfDay');

    final whereParts = <String>[
      'it.txn_type IN (?, ?)',
      'it.created_at >= ?',
      'it.created_at <= ?',
    ];
    final whereArgs = <Object?>[
      'wastage',
      'expired_bouquet',
      startOfDay,
      endOfDay,
    ];

    if (category != null) {
      whereParts.add('p.category = ?');
      whereArgs.add(category);
    }

    if (productId != null) {
      whereParts.add('it.product_id = ?');
      whereArgs.add(productId);
    }

    if (supplier != null && supplier.isNotEmpty) {
      whereParts.add('it.supplier = ?');
      whereArgs.add(supplier);
    }

    if (reason != null && reason.isNotEmpty) {
      whereParts.add('it.reason = ?');
      whereArgs.add(reason);
    }

    final rows = await db.rawQuery('''
      SELECT
        it.id,
        it.product_id,
        it.txn_type,
        it.qty,
        it.purchase_price_paise,
        COALESCE(it.supplier, '') AS supplier,
        it.source,
        COALESCE(it.reason, '') AS reason,
        COALESCE(it.note, '') AS note,
        it.created_at AS created_at,
        p.name AS product_name,
        p.category,
        p.default_unit AS unit
      FROM inventory_transactions it
      JOIN products p ON it.product_id = p.id
      WHERE ${whereParts.join(' AND ')}
      ORDER BY it.created_at DESC
    ''', whereArgs);

    debugPrint('Query executed, returned ${rows.length} rows');

    return rows
        .map((row) => InventoryTransactionRecord(
              id: row['id'] as int,
              productId: row['product_id'] as int,
              txnType: row['txn_type'] as String,
              qty: row['qty'] as int,
              purchasePricePaise: row['purchase_price_paise'] as int?,
              supplier: row['supplier'] as String? ?? '',
              source: row['source'] as String,
              reason: row['reason'] as String? ?? '',
              note: row['note'] as String? ?? '',
              createdAt: row['created_at'] as String,
              productName: row['product_name'] as String?,
              category: row['category'] as String?,
              unit: row['unit'] as String?,
            ))
        .toList();
  }

  Future<List<InventoryTransactionRecord>> listTransactionsForProduct(
    int productId,
  ) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'inventory_transactions',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'created_at DESC, id DESC',
    );

    return rows
        .map(
          (row) => InventoryTransactionRecord(
            id: row['id'] as int,
            productId: row['product_id'] as int,
            txnType: row['txn_type'] as String,
            qty: row['qty'] as int,
            purchasePricePaise: row['purchase_price_paise'] as int?,
            supplier: (row['supplier'] as String?) ?? '',
            source: (row['source'] as String?) ?? 'Manual',
            reason: (row['reason'] as String?) ?? '',
            note: (row['note'] as String?) ?? '',
            createdAt: row['created_at'] as String,
          ),
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> getLowStockItems({int limit = 5}) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT p.id, p.name, COALESCE(NULLIF(p.manufacturer_barcode, ''), NULLIF(p.floraprise_barcode, ''), p.barcode) AS barcode, i.current_qty, i.min_qty
      FROM inventory_items i
      JOIN products p ON i.product_id = p.id
      WHERE i.current_qty <= i.min_qty
      AND i.current_qty > 0
      AND p.active = 1
      AND p.deleted_at IS NULL
      AND p.track_inventory = 1
      ORDER BY i.current_qty ASC
      LIMIT ?
    ''', [limit]);

    return rows;
  }

  Future<int> getLowStockCount() async {
    final db = await AppDatabase.instance.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM inventory_items i
      JOIN products p ON i.product_id = p.id
      WHERE i.current_qty <= i.min_qty
      AND i.current_qty > 0
      AND p.active = 1
      AND p.deleted_at IS NULL
      AND p.track_inventory = 1
    ''');

    return result.first['count'] as int;
  }

  Future<int> getOutOfStockCount() async {
    final db = await AppDatabase.instance.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM inventory_items i
      JOIN products p ON i.product_id = p.id
      WHERE i.current_qty = 0
      AND p.active = 1
      AND p.deleted_at IS NULL
      AND p.track_inventory = 1
    ''');

    return result.first['count'] as int;
  }

  Future<void> _applyTransaction({
    required Database db,
    required int productId,
    required int quantity,
    required int delta,
    required String txnType,
    required String source,
    int? purchasePricePaise,
    String? supplier,
    String? reason,
    String? note,
    int? orderId,
    int? orderLineId,
  }) async {
    await db.transaction((txn) async {
      await _applyTransactionInExecutor(
        db: txn,
        productId: productId,
        quantity: quantity,
        delta: delta,
        txnType: txnType,
        source: source,
        purchasePricePaise: purchasePricePaise,
        supplier: supplier,
        reason: reason,
        note: note,
        orderId: orderId,
        orderLineId: orderLineId,
      );
    });
  }

  Future<int> _applyTransactionInExecutor({
    required DatabaseExecutor db,
    required int productId,
    required int quantity,
    required int delta,
    required String txnType,
    required String source,
    int? purchasePricePaise,
    String? supplier,
    String? reason,
    String? note,
    int? orderId,
    int? orderLineId,
  }) async {
    final now = DateTime.now().toIso8601String();
    final productRows = await db.query(
        'products',
        columns: ['track_inventory', 'min_stock', 'deleted_at'],
        where: 'id = ?',
        whereArgs: [productId],
        limit: 1,
      );
    if (productRows.isEmpty || productRows.first['deleted_at'] != null) {
      throw StateError('Product not found');
    }

      final trackInventory =
        (productRows.first['track_inventory'] as int? ?? 0) == 1;
      final minStock = (productRows.first['min_stock'] as int? ?? 0);

    final items = await db.query(
        'inventory_items',
        where: 'product_id = ?',
        whereArgs: [productId],
        limit: 1,
      );

    int currentQty = 0;
    if (items.isNotEmpty) {
      currentQty = items.first['current_qty'] as int? ?? 0;
    }

    final nextQty = currentQty + delta;
    if (trackInventory && nextQty < 0) {
      throw StateError('Stock cannot go negative');
    }

    if (items.isEmpty) {
      await db.insert('inventory_items', {
          'product_id': productId,
          'current_qty': nextQty,
          'min_qty': minStock,
          'updated_at': now,
        });
    } else {
      await db.update(
          'inventory_items',
          {
            'current_qty': nextQty,
            'min_qty': minStock,
            'updated_at': now,
          },
          where: 'product_id = ?',
          whereArgs: [productId],
        );
    }

    return db.insert('inventory_transactions', {
        'product_id': productId,
        'order_id': orderId,
        'order_line_id': orderLineId,
        'txn_type': txnType,
        'qty': quantity,
        'purchase_price_paise': purchasePricePaise,
        'supplier': supplier,
        'source': source,
        'reason': reason,
        'note': note,
        'created_at': now,
    });
  }
}
