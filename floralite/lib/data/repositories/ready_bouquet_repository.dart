import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';

enum ReadyBouquetStatus {
  fresh,
  needsRefresh,
  nearExpiry,
  expired,
}

class ReadyBouquetSummary {
  final int productId;
  final String productName;
  final String unit;
  final int currentStock;
  final int batchCount;
  final DateTime? oldestProducedAt;
  final DateTime? lastRefreshAt;
  final int ageDays;
  final ReadyBouquetStatus status;

  const ReadyBouquetSummary({
    required this.productId,
    required this.productName,
    required this.unit,
    required this.currentStock,
    required this.batchCount,
    this.oldestProducedAt,
    this.lastRefreshAt,
    required this.ageDays,
    required this.status,
  });
}

class ReadyBouquetBatch {
  final int id;
  final int finishedProductId;
  final String productName;
  final String unit;
  final int? recipeId;
  final int? productionId;
  final int initialQuantity;
  final int remainingQuantity;
  final int shelfLifeDays;
  final int refreshAfterDays;
  final DateTime producedAt;
  final DateTime? lastRefreshAt;
  final DateTime expiryAt;
  final String location;
  final ReadyBouquetStatus status;
  final String? note;

  const ReadyBouquetBatch({
    required this.id,
    required this.finishedProductId,
    required this.productName,
    required this.unit,
    required this.recipeId,
    this.productionId,
    required this.initialQuantity,
    required this.remainingQuantity,
    required this.shelfLifeDays,
    required this.refreshAfterDays,
    required this.producedAt,
    this.lastRefreshAt,
    required this.expiryAt,
    required this.location,
    required this.status,
    this.note,
  });
}

class RefreshEventRecord {
  final int id;
  final int batchId;
  final String actionType;
  final int productId;
  final String productName;
  final int quantity;
  final int wastageQuantity;
  final String? reason;
  final String? note;
  final DateTime createdAt;

  const RefreshEventRecord({
    required this.id,
    required this.batchId,
    required this.actionType,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.wastageQuantity,
    this.reason,
    this.note,
    required this.createdAt,
  });
}

class ReadyBouquetRepository {
  static ReadyBouquetStatus computeStatus({
    required DateTime producedAt,
    required DateTime? lastRefreshAt,
    required DateTime expiryAt,
    required int refreshAfterDays,
    required int shelfLifeDays,
  }) {
    final reference = lastRefreshAt ?? producedAt;
    final now = DateTime.now();
    final ageDays = now.difference(reference).inDays;
    if (now.isAfter(expiryAt)) return ReadyBouquetStatus.expired;
    if (shelfLifeDays > 0 && ageDays >= shelfLifeDays - 1) {
      return ReadyBouquetStatus.nearExpiry;
    }
    if (refreshAfterDays > 0 && ageDays >= refreshAfterDays) {
      return ReadyBouquetStatus.needsRefresh;
    }
    return ReadyBouquetStatus.fresh;
  }

  Future<List<ReadyBouquetSummary>> listReadyBouquets() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT
        b.id,
        b.finished_product_id,
        p.name AS product_name,
        p.default_unit AS unit,
        b.recipe_id,
        b.production_id,
        b.initial_quantity,
        b.remaining_quantity,
        b.shelf_life_days,
        b.refresh_after_days,
        b.produced_at,
        b.last_refresh_at,
        b.expiry_at,
        b.location,
        b.status,
        b.note
      FROM ready_bouquet_batches b
      JOIN products p ON p.id = b.finished_product_id
      WHERE b.remaining_quantity > 0
      ORDER BY b.finished_product_id, b.produced_at ASC
    ''');

    final byProduct = <int, List<ReadyBouquetBatch>>{};
    for (final row in rows) {
      final batch = _mapBatchRow(row);
      byProduct.putIfAbsent(batch.finishedProductId, () => []).add(batch);
    }

    return byProduct.entries.map((entry) {
      final batches = entry.value;
      final productName = batches.first.productName;
      final unit = batches.first.unit;
      final currentStock = batches.fold(0, (sum, b) => sum + b.remainingQuantity);
      final oldest = batches.map((b) => b.producedAt).reduce((a, b) => a.isBefore(b) ? a : b);
      final lastRefresh = batches
          .where((b) => b.lastRefreshAt != null)
          .map((b) => b.lastRefreshAt!)
          .fold<DateTime?>(null, (latest, dt) => latest == null || dt.isAfter(latest) ? dt : latest);
      final oldestBatch = batches.first;
      final status = computeStatus(
        producedAt: oldest,
        lastRefreshAt: lastRefresh,
        expiryAt: batches.map((b) => b.expiryAt).reduce((a, b) => a.isAfter(b) ? a : b),
        refreshAfterDays: oldestBatch.refreshAfterDays,
        shelfLifeDays: oldestBatch.shelfLifeDays,
      );
      final ageDays = DateTime.now().difference(lastRefresh ?? oldest).inDays;

      return ReadyBouquetSummary(
        productId: entry.key,
        productName: productName,
        unit: unit,
        currentStock: currentStock,
        batchCount: batches.length,
        oldestProducedAt: oldest,
        lastRefreshAt: lastRefresh,
        ageDays: ageDays,
        status: status,
      );
    }).toList();
  }

  Future<List<ReadyBouquetBatch>> listBatchesForProduct(int finishedProductId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT
        b.id,
        b.finished_product_id,
        p.name AS product_name,
        p.default_unit AS unit,
        b.recipe_id,
        b.production_id,
        b.initial_quantity,
        b.remaining_quantity,
        b.shelf_life_days,
        b.refresh_after_days,
        b.produced_at,
        b.last_refresh_at,
        b.expiry_at,
        b.location,
        b.status,
        b.note
      FROM ready_bouquet_batches b
      JOIN products p ON p.id = b.finished_product_id
      WHERE b.finished_product_id = ? AND b.remaining_quantity > 0
      ORDER BY b.produced_at ASC
    ''', [finishedProductId]);
    return rows.map(_mapBatchRow).toList();
  }

  Future<ReadyBouquetBatch?> getBatch(int batchId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT
        b.id,
        b.finished_product_id,
        p.name AS product_name,
        p.default_unit AS unit,
        b.recipe_id,
        b.production_id,
        b.initial_quantity,
        b.remaining_quantity,
        b.shelf_life_days,
        b.refresh_after_days,
        b.produced_at,
        b.last_refresh_at,
        b.expiry_at,
        b.location,
        b.status,
        b.note
      FROM ready_bouquet_batches b
      JOIN products p ON p.id = b.finished_product_id
      WHERE b.id = ?
    ''', [batchId]);
    if (rows.isEmpty) return null;
    return _mapBatchRow(rows.first);
  }

  Future<List<RefreshEventRecord>> listRefreshEvents(int batchId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT
        e.id,
        e.batch_id,
        e.action_type,
        e.product_id,
        p.name AS product_name,
        e.quantity,
        e.wastage_quantity,
        e.reason,
        e.note,
        e.created_at
      FROM ready_bouquet_refresh_events e
      JOIN products p ON p.id = e.product_id
      WHERE e.batch_id = ?
      ORDER BY e.created_at DESC
    ''', [batchId]);
    return rows.map((row) => RefreshEventRecord(
      id: row['id'] as int,
      batchId: row['batch_id'] as int,
      actionType: row['action_type'] as String,
      productId: row['product_id'] as int,
      productName: row['product_name'] as String,
      quantity: row['quantity'] as int,
      wastageQuantity: row['wastage_quantity'] as int? ?? 0,
      reason: row['reason'] as String?,
      note: row['note'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    )).toList();
  }

  Future<void> expireBouquet({
    required int batchId,
    required int quantity,
    required String reason,
    String? note,
  }) async {
    if (quantity <= 0) {
      throw StateError('Quantity must be greater than zero');
    }
    final db = await AppDatabase.instance.database;
    await db.transaction((txn) async {
      final batch = await _requireBatch(txn, batchId);
      if (batch.remainingQuantity < quantity) {
        throw StateError('Cannot expire $quantity: only ${batch.remainingQuantity} remain');
      }

      final now = DateTime.now().toIso8601String();
      final remaining = batch.remainingQuantity - quantity;
      final newStatus = computeStatus(
        producedAt: batch.producedAt,
        lastRefreshAt: batch.lastRefreshAt,
        expiryAt: batch.expiryAt,
        refreshAfterDays: batch.refreshAfterDays,
        shelfLifeDays: batch.shelfLifeDays,
      );

      await txn.update(
        'ready_bouquet_batches',
        {
          'remaining_quantity': remaining,
          'status': remaining == 0 ? 'expired' : _statusName(newStatus),
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [batchId],
      );

      await _changeStock(
        txn: txn,
        productId: batch.finishedProductId,
        delta: -quantity,
        updatedAt: now,
      );

      await txn.insert('inventory_transactions', {
        'product_id': batch.finishedProductId,
        'txn_type': 'expired_bouquet',
        'qty': quantity,
        'source': 'Ready Bouquet',
        'reason': reason,
        'note': note?.trim().isEmpty ?? true ? null : note!.trim(),
        'created_at': now,
      });
    });
  }

  Future<void> refreshReplaceComponent({
    required int batchId,
    required int productId,
    required int quantity,
    String? reason,
    String? note,
  }) async {
    if (quantity <= 0) throw StateError('Quantity must be greater than zero');
    final db = await AppDatabase.instance.database;
    await db.transaction((txn) async {
      final batch = await _requireBatch(txn, batchId);
      final now = DateTime.now().toIso8601String();

      await _deductRawStock(txn, productId, quantity, now);
      await _recordWastage(txn, productId, quantity, now,
          reason: reason ?? 'Replaced damaged component', note: note);

      await txn.insert('ready_bouquet_refresh_events', {
        'batch_id': batchId,
        'action_type': 'replace',
        'product_id': productId,
        'quantity': quantity,
        'wastage_quantity': quantity,
        'reason': reason,
        'note': note?.trim(),
        'created_at': now,
      });

      await _touchBatch(txn, batch, now);
    });
  }

  Future<void> refreshAddComponent({
    required int batchId,
    required int productId,
    required int quantity,
    String? reason,
    String? note,
  }) async {
    if (quantity <= 0) throw StateError('Quantity must be greater than zero');
    final db = await AppDatabase.instance.database;
    await db.transaction((txn) async {
      final batch = await _requireBatch(txn, batchId);
      final now = DateTime.now().toIso8601String();

      await _deductRawStock(txn, productId, quantity, now);

      await txn.insert('ready_bouquet_refresh_events', {
        'batch_id': batchId,
        'action_type': 'add',
        'product_id': productId,
        'quantity': quantity,
        'wastage_quantity': 0,
        'reason': reason,
        'note': note?.trim(),
        'created_at': now,
      });

      await _touchBatch(txn, batch, now);
    });
  }

  Future<void> refreshRemoveComponent({
    required int batchId,
    required int productId,
    required int quantity,
    required bool returnToInventory,
    String? reason,
    String? note,
  }) async {
    if (quantity <= 0) throw StateError('Quantity must be greater than zero');
    final db = await AppDatabase.instance.database;
    await db.transaction((txn) async {
      final batch = await _requireBatch(txn, batchId);
      final now = DateTime.now().toIso8601String();

      if (returnToInventory) {
        await _changeStock(
          txn: txn,
          productId: productId,
          delta: quantity,
          updatedAt: now,
        );
        await txn.insert('inventory_transactions', {
          'product_id': productId,
          'txn_type': 'refresh',
          'qty': quantity,
          'source': 'Ready Bouquet',
          'reason': reason ?? 'Returned to inventory',
          'note': note?.trim(),
          'created_at': now,
        });
      } else {
        await _recordWastage(txn, productId, quantity, now,
            reason: reason ?? 'Removed component', note: note);
      }

      await txn.insert('ready_bouquet_refresh_events', {
        'batch_id': batchId,
        'action_type': 'remove',
        'product_id': productId,
        'quantity': quantity,
        'wastage_quantity': returnToInventory ? 0 : quantity,
        'reason': reason,
        'note': note?.trim(),
        'created_at': now,
      });

      await _touchBatch(txn, batch, now);
    });
  }

  Future<List<ReadyBouquetSummary>> getAttentionBouquets() async {
    final all = await listReadyBouquets();
    return all
        .where((b) =>
            b.status == ReadyBouquetStatus.needsRefresh ||
            b.status == ReadyBouquetStatus.nearExpiry ||
            b.status == ReadyBouquetStatus.expired)
        .toList();
  }

  Future<ReadyBouquetBatch> _requireBatch(Transaction txn, int batchId) async {
    final rows = await txn.rawQuery('''
      SELECT
        b.id,
        b.finished_product_id,
        p.name AS product_name,
        p.default_unit AS unit,
        b.recipe_id,
        b.production_id,
        b.initial_quantity,
        b.remaining_quantity,
        b.shelf_life_days,
        b.refresh_after_days,
        b.produced_at,
        b.last_refresh_at,
        b.expiry_at,
        b.location,
        b.status,
        b.note
      FROM ready_bouquet_batches b
      JOIN products p ON p.id = b.finished_product_id
      WHERE b.id = ?
    ''', [batchId]);
    if (rows.isEmpty) throw StateError('Batch not found');
    return _mapBatchRow(rows.first);
  }

  Future<void> _touchBatch(Transaction txn, ReadyBouquetBatch batch, String now) async {
    final newStatus = computeStatus(
      producedAt: batch.producedAt,
      lastRefreshAt: DateTime.parse(now),
      expiryAt: batch.expiryAt,
      refreshAfterDays: batch.refreshAfterDays,
      shelfLifeDays: batch.shelfLifeDays,
    );
    await txn.update(
      'ready_bouquet_batches',
      {
        'last_refresh_at': now,
        'status': _statusName(newStatus),
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [batch.id],
    );
  }

  Future<void> _deductRawStock(Transaction txn, int productId, int quantity, String now) async {
    final rows = await txn.query(
      'products',
      columns: ['track_inventory', 'min_stock', 'deleted_at'],
      where: 'id = ?',
      whereArgs: [productId],
      limit: 1,
    );
    if (rows.isEmpty || rows.first['deleted_at'] != null) {
      throw StateError('Product not found');
    }
    final trackInventory = (rows.first['track_inventory'] as int? ?? 0) == 1;
    final minStock = (rows.first['min_stock'] as int? ?? 0);

    final items = await txn.query(
      'inventory_items',
      where: 'product_id = ?',
      whereArgs: [productId],
      limit: 1,
    );
    final currentQty = items.isEmpty ? 0 : items.first['current_qty'] as int? ?? 0;
    if (trackInventory && currentQty < quantity) {
      throw StateError('Insufficient raw material stock');
    }

    final nextQty = currentQty - quantity;
    if (items.isEmpty) {
      await txn.insert('inventory_items', {
        'product_id': productId,
        'current_qty': nextQty,
        'min_qty': minStock,
        'updated_at': now,
      });
    } else {
      await txn.update(
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

    await txn.insert('inventory_transactions', {
      'product_id': productId,
      'txn_type': 'refresh',
      'qty': quantity,
      'source': 'Ready Bouquet',
      'reason': 'Refresh component',
      'created_at': now,
    });
  }

  Future<void> _recordWastage(
    Transaction txn,
    int productId,
    int quantity,
    String now, {
    required String reason,
    String? note,
  }) async {
    await txn.insert('inventory_transactions', {
      'product_id': productId,
      'txn_type': 'wastage',
      'qty': quantity,
      'source': 'Ready Bouquet',
      'reason': reason,
      'note': note?.trim(),
      'created_at': now,
    });
  }

  Future<void> _changeStock({
    required Transaction txn,
    required int productId,
    required int delta,
    required String updatedAt,
  }) async {
    final rows = await txn.query(
      'inventory_items',
      where: 'product_id = ?',
      whereArgs: [productId],
      limit: 1,
    );
    if (rows.isEmpty) {
      await txn.insert('inventory_items', {
        'product_id': productId,
        'current_qty': delta,
        'min_qty': 0,
        'updated_at': updatedAt,
      });
      return;
    }
    final currentQty = rows.first['current_qty'] as int;
    await txn.update(
      'inventory_items',
      {
        'current_qty': currentQty + delta,
        'updated_at': updatedAt,
      },
      where: 'product_id = ?',
      whereArgs: [productId],
    );
  }

  ReadyBouquetBatch _mapBatchRow(Map<String, Object?> row) {
    final producedAt = DateTime.parse(row['produced_at'] as String);
    final lastRefreshAt = row['last_refresh_at'] == null
        ? null
        : DateTime.parse(row['last_refresh_at'] as String);
    final expiryAt = DateTime.parse(row['expiry_at'] as String);
    final shelfLifeDays = row['shelf_life_days'] as int? ?? 3;
    final refreshAfterDays = row['refresh_after_days'] as int? ?? 2;
    final status = computeStatus(
      producedAt: producedAt,
      lastRefreshAt: lastRefreshAt,
      expiryAt: expiryAt,
      refreshAfterDays: refreshAfterDays,
      shelfLifeDays: shelfLifeDays,
    );

    return ReadyBouquetBatch(
      id: row['id'] as int,
      finishedProductId: row['finished_product_id'] as int,
      productName: row['product_name'] as String? ?? '',
      unit: row['unit'] as String? ?? 'Piece',
      recipeId: row['recipe_id'] as int?,
      productionId: row['production_id'] as int?,
      initialQuantity: row['initial_quantity'] as int,
      remainingQuantity: row['remaining_quantity'] as int,
      shelfLifeDays: shelfLifeDays,
      refreshAfterDays: refreshAfterDays,
      producedAt: producedAt,
      lastRefreshAt: lastRefreshAt,
      expiryAt: expiryAt,
      location: row['location'] as String? ?? 'Store',
      status: status,
      note: row['note'] as String?,
    );
  }

  String _statusName(ReadyBouquetStatus status) {
    switch (status) {
      case ReadyBouquetStatus.fresh:
        return 'fresh';
      case ReadyBouquetStatus.needsRefresh:
        return 'needs_refresh';
      case ReadyBouquetStatus.nearExpiry:
        return 'near_expiry';
      case ReadyBouquetStatus.expired:
        return 'expired';
    }
  }
}
