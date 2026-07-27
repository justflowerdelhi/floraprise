import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../../services/barcode_service.dart';

class ProductionProduct {
  final int id;
  final String name;
  final String unit;
  final String barcode;
  final int sellingPricePaise;
  final int purchasePricePaise;
  final int currentQty;
  final bool hasRecipe;

  const ProductionProduct({
    required this.id,
    required this.name,
    required this.unit,
    required this.barcode,
    required this.sellingPricePaise,
    required this.purchasePricePaise,
    required this.currentQty,
    required this.hasRecipe,
  });
}

class RecipeItem {
  final int rawProductId;
  final String productName;
  final String unit;
  final int quantity;
  final int currentQty;
  final int purchasePricePaise;

  const RecipeItem({
    required this.rawProductId,
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.currentQty,
    required this.purchasePricePaise,
  });
}

class ProductionResult {
  final int productionId;
  final int productionCostPaise;
  final int finishedQuantity;
  final int finishedProductId;

  const ProductionResult({
    required this.productionId,
    required this.productionCostPaise,
    required this.finishedQuantity,
    required this.finishedProductId,
  });
}

class ProductionReportRecord {
  final int id;
  final String producedAt;
  final String productName;
  final int quantity;
  final int productionCostPaise;
  final int currentStock;
  final bool isReversed;

  const ProductionReportRecord({
    required this.id,
    required this.producedAt,
    required this.productName,
    required this.quantity,
    required this.productionCostPaise,
    required this.currentStock,
    required this.isReversed,
  });
}

class ProductionDetail {
  final int id;
  final int finishedProductId;
  final String productName;
  final int quantity;
  final int productionCostPaise;
  final String producedAt;
  final String operatorName;
  final String? deviceName;
  final String? note;
  final String? reversedAt;
  final String? reversalNote;
  final List<ProductionConsumptionDetail> consumptions;

  const ProductionDetail({
    required this.id,
    required this.finishedProductId,
    required this.productName,
    required this.quantity,
    required this.productionCostPaise,
    required this.producedAt,
    required this.operatorName,
    required this.deviceName,
    required this.note,
    required this.reversedAt,
    required this.reversalNote,
    required this.consumptions,
  });

  String get productionNumber => 'PROD-${id.toString().padLeft(6, '0')}';
  bool get isReversed => reversedAt != null;
}

class ProductionConsumptionDetail {
  final int rawProductId;
  final String productName;
  final String unit;
  final int quantity;
  final int unitCostPaise;
  final int totalCostPaise;

  const ProductionConsumptionDetail({
    required this.rawProductId,
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.unitCostPaise,
    required this.totalCostPaise,
  });
}

class ProductionRepository {
  static bool isFinishedProductCategory(String? category) {
    final normalized = category?.trim().toLowerCase();
    if (normalized == null) return false;
    return normalized == 'finished products' ||
        normalized == 'finished product' ||
        normalized == 'bouquet' ||
        normalized == 'bunch' ||
        normalized == 'arrangement' ||
        normalized == 'centerpiece' ||
        normalized == 'basket arrangement' ||
        normalized == 'vase arrangement' ||
        normalized == 'wreath' ||
        normalized == 'corsage' ||
        normalized == 'boutonniere' ||
        normalized == 'garland' ||
        normalized == 'floral box' ||
        normalized == 'gift hamper' ||
        normalized == 'custom';
  }

  Future<List<ProductionProduct>> listFinishedProducts() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT
        p.id,
        p.name,
        p.default_unit,
        COALESCE(NULLIF(p.floraprise_barcode, ''), NULLIF(p.manufacturer_barcode, ''), NULLIF(p.barcode, '')) AS barcode,
        p.selling_price_paise,
        COALESCE(p.purchase_price_paise, 0) AS purchase_price_paise,
        COALESCE(i.current_qty, 0) AS current_qty,
        CASE WHEN r.id IS NULL THEN 0 ELSE 1 END AS has_recipe
      FROM products p
      LEFT JOIN inventory_items i ON i.product_id = p.id
      LEFT JOIN product_recipes r ON r.finished_product_id = p.id
      WHERE LOWER(TRIM(p.category)) IN (
          'finished products', 'finished product',
          'bouquet', 'bunch', 'arrangement', 'centerpiece',
          'basket arrangement', 'vase arrangement', 'wreath',
          'corsage', 'boutonniere', 'garland', 'floral box',
          'gift hamper', 'custom'
        )
        AND p.active = 1
        AND p.deleted_at IS NULL
      ORDER BY p.name COLLATE NOCASE ASC
    ''');
    return rows.map(_mapProductionProduct).toList();
  }

  Future<List<ProductionProduct>> listRawProducts() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT
        p.id,
        p.name,
        p.default_unit,
        COALESCE(NULLIF(p.floraprise_barcode, ''), NULLIF(p.manufacturer_barcode, ''), NULLIF(p.barcode, '')) AS barcode,
        p.selling_price_paise,
        COALESCE(p.purchase_price_paise, 0) AS purchase_price_paise,
        COALESCE(i.current_qty, 0) AS current_qty,
        0 AS has_recipe
      FROM products p
      LEFT JOIN inventory_items i ON i.product_id = p.id
      WHERE LOWER(TRIM(p.category)) NOT IN (
          'finished products', 'finished product',
          'bouquet', 'bunch', 'arrangement', 'centerpiece',
          'basket arrangement', 'vase arrangement', 'wreath',
          'corsage', 'boutonniere', 'garland', 'floral box',
          'gift hamper', 'custom'
        )
        AND p.active = 1
        AND p.deleted_at IS NULL
        AND p.track_inventory = 1
      ORDER BY p.name COLLATE NOCASE ASC
    ''');
    return rows.map(_mapProductionProduct).toList();
  }

  Future<List<RecipeItem>> getRecipeItems(int finishedProductId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT
        ri.raw_product_id,
        p.name AS product_name,
        ri.unit,
        ri.quantity,
        COALESCE(i.current_qty, 0) AS current_qty,
        COALESCE((
          SELECT purchase_price_paise
          FROM inventory_transactions
          WHERE product_id = p.id
            AND txn_type = 'purchase'
            AND purchase_price_paise IS NOT NULL
          ORDER BY created_at DESC, id DESC
          LIMIT 1
        ), 0) AS purchase_price_paise
      FROM product_recipes r
      JOIN product_recipe_items ri ON ri.recipe_id = r.id
      JOIN products p ON p.id = ri.raw_product_id
      LEFT JOIN inventory_items i ON i.product_id = p.id
      WHERE r.finished_product_id = ?
      ORDER BY p.name COLLATE NOCASE ASC
    ''', [finishedProductId]);
    return rows
        .map((row) => RecipeItem(
              rawProductId: row['raw_product_id'] as int,
              productName: row['product_name'] as String,
              unit: row['unit'] as String,
              quantity: row['quantity'] as int,
              currentQty: row['current_qty'] as int,
              purchasePricePaise: row['purchase_price_paise'] as int,
            ))
        .toList();
  }

  Future<void> saveRecipe({
    required int finishedProductId,
    required List<RecipeItem> items,
    int shelfLifeDays = 3,
    int refreshAfterDays = 2,
    String? occasion,
  }) async {
    if (items.isEmpty) {
      throw StateError('Add at least one raw product to the recipe');
    }
    if (items.any((item) => item.quantity <= 0)) {
      throw StateError('Recipe quantities must be greater than zero');
    }
    if (items.map((item) => item.rawProductId).toSet().length != items.length) {
      throw StateError('Each raw product can only be added once');
    }

    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      final finished = await txn.query(
        'products',
        columns: ['id', 'category', 'track_inventory', 'active', 'deleted_at'],
        where: 'id = ?',
        whereArgs: [finishedProductId],
        limit: 1,
      );
      if (finished.isEmpty ||
          !isFinishedProductCategory(finished.first['category'] as String?) ||
          (finished.first['track_inventory'] as int? ?? 0) != 1 ||
          (finished.first['active'] as int? ?? 0) != 1 ||
          finished.first['deleted_at'] != null) {
        throw StateError(
            'Select an active finished product with inventory tracking enabled');
      }

      final recipeRows = await txn.query(
        'product_recipes',
        columns: ['id'],
        where: 'finished_product_id = ?',
        whereArgs: [finishedProductId],
        limit: 1,
      );
      final recipeId = recipeRows.isEmpty
          ? await txn.insert('product_recipes', {
              'finished_product_id': finishedProductId,
              'shelf_life_days': shelfLifeDays,
              'refresh_after_days': refreshAfterDays,
              'occasion': occasion,
              'created_at': now,
              'updated_at': now,
            })
          : recipeRows.first['id'] as int;
      if (recipeRows.isNotEmpty) {
        await txn.update(
          'product_recipes',
          {
            'shelf_life_days': shelfLifeDays,
            'refresh_after_days': refreshAfterDays,
            'occasion': occasion,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [recipeId],
        );
        await txn.delete('product_recipe_items',
            where: 'recipe_id = ?', whereArgs: [recipeId]);
      }

      for (final item in items) {
        final raw = await txn.query(
          'products',
          columns: ['id', 'track_inventory', 'active', 'deleted_at'],
          where: 'id = ?',
          whereArgs: [item.rawProductId],
          limit: 1,
        );
        if (raw.isEmpty ||
            (raw.first['track_inventory'] as int? ?? 0) != 1 ||
            (raw.first['active'] as int? ?? 0) != 1 ||
            raw.first['deleted_at'] != null) {
          throw StateError(
              '${item.productName} is not an active tracked raw product');
        }
        await txn.insert('product_recipe_items', {
          'recipe_id': recipeId,
          'raw_product_id': item.rawProductId,
          'quantity': item.quantity,
          'unit': item.unit,
        });
      }
    });
  }

  Future<int> saveBouquetRecipe({
    int? finishedProductId,
    String? productName,
    String? category,
    required List<RecipeItem> items,
    int sellingPricePaise = 0,
    int shelfLifeDays = 3,
    int refreshAfterDays = 2,
    String? occasion,
    String? imagePath,
  }) async {
    if (items.isEmpty) {
      throw StateError('Add at least one component to the recipe');
    }
    if (items.any((item) => item.quantity <= 0)) {
      throw StateError('Recipe quantities must be greater than zero');
    }
    if (items.map((item) => item.rawProductId).toSet().length != items.length) {
      throw StateError('Each component can only be added once');
    }

    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    return db.transaction((txn) async {
      late int productId;
      if (finishedProductId != null) {
        final existing = await txn.query(
          'products',
          columns: [
            'id',
            'category',
            'track_inventory',
            'active',
            'deleted_at'
          ],
          where: 'id = ?',
          whereArgs: [finishedProductId],
          limit: 1,
        );
        if (existing.isEmpty ||
            !isFinishedProductCategory(existing.first['category'] as String?) ||
            (existing.first['track_inventory'] as int? ?? 0) != 1 ||
            (existing.first['active'] as int? ?? 0) != 1 ||
            existing.first['deleted_at'] != null) {
          throw StateError(
              'Select an active finished product with inventory tracking enabled');
        }
        productId = finishedProductId;
        await txn.update(
          'products',
          {
            'selling_price_paise': sellingPricePaise,
            'image_path':
                imagePath?.trim().isEmpty ?? true ? null : imagePath!.trim(),
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [productId],
        );
      } else {
        final trimmedName = (productName ?? '').trim();
        if (trimmedName.isEmpty) {
          throw StateError('Recipe name is required');
        }
        final trimmedCategory = (category ?? 'Bouquet').trim();
        productId = await txn.insert('products', {
          'name': trimmedName,
          'category': trimmedCategory.isEmpty ? 'Bouquet' : trimmedCategory,
          'default_unit': 'Piece',
          'selling_price_paise': sellingPricePaise,
          'purchase_price_paise': 0,
          'gst_percent': 0,
          'track_inventory': 1,
          'min_stock': 0,
          'active': 1,
          'image_path':
              imagePath?.trim().isEmpty ?? true ? null : imagePath!.trim(),
          'created_at': now,
          'updated_at': now,
          'deleted_at': null,
        });
        await txn.update(
          'products',
          {'floraprise_barcode': 'FLR-$productId'},
          where: 'id = ?',
          whereArgs: [productId],
        );
        await txn.insert('inventory_items', {
          'product_id': productId,
          'current_qty': 0,
          'min_qty': 0,
          'updated_at': now,
        });
      }

      final recipeRows = await txn.query(
        'product_recipes',
        columns: ['id'],
        where: 'finished_product_id = ?',
        whereArgs: [productId],
        limit: 1,
      );
      final recipeId = recipeRows.isEmpty
          ? await txn.insert('product_recipes', {
              'finished_product_id': productId,
              'shelf_life_days': shelfLifeDays,
              'refresh_after_days': refreshAfterDays,
              'occasion': occasion,
              'created_at': now,
              'updated_at': now,
            })
          : recipeRows.first['id'] as int;
      if (recipeRows.isNotEmpty) {
        await txn.update(
          'product_recipes',
          {
            'shelf_life_days': shelfLifeDays,
            'refresh_after_days': refreshAfterDays,
            'occasion': occasion,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [recipeId],
        );
        await txn.delete('product_recipe_items',
            where: 'recipe_id = ?', whereArgs: [recipeId]);
      }

      for (final item in items) {
        final raw = await txn.query(
          'products',
          columns: ['id', 'track_inventory', 'active', 'deleted_at'],
          where: 'id = ?',
          whereArgs: [item.rawProductId],
          limit: 1,
        );
        if (raw.isEmpty ||
            (raw.first['track_inventory'] as int? ?? 0) != 1 ||
            (raw.first['active'] as int? ?? 0) != 1 ||
            raw.first['deleted_at'] != null) {
          throw StateError(
              '${item.productName} is not an active tracked raw product');
        }
        await txn.insert('product_recipe_items', {
          'recipe_id': recipeId,
          'raw_product_id': item.rawProductId,
          'quantity': item.quantity,
          'unit': item.unit,
        });
      }

      return productId;
    });
  }

  Future<Map<String, dynamic>?> getRecipeMetadata(int finishedProductId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'product_recipes',
      columns: ['id', 'shelf_life_days', 'refresh_after_days', 'occasion'],
      where: 'finished_product_id = ?',
      whereArgs: [finishedProductId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<int> getMaximumProducibleQuantity(int finishedProductId) async {
    final items = await getRecipeItems(finishedProductId);
    if (items.isEmpty) return 0;
    return items
        .map((item) => item.currentQty ~/ item.quantity)
        .reduce((lowest, available) => available < lowest ? available : lowest);
  }

  Future<ProductionResult> produce({
    required int finishedProductId,
    required int quantity,
    String? note,
    String operatorName = 'Admin',
    String? deviceName,
  }) async {
    if (quantity <= 0) {
      throw StateError('Production quantity must be greater than zero');
    }
    final db = await AppDatabase.instance.database;
    return db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final finishedRows = await txn.query(
        'products',
        columns: [
          'id',
          'name',
          'category',
          'track_inventory',
          'min_stock',
          'active',
          'deleted_at'
        ],
        where: 'id = ?',
        whereArgs: [finishedProductId],
        limit: 1,
      );
      if (finishedRows.isEmpty ||
          !isFinishedProductCategory(
              finishedRows.first['category'] as String?) ||
          (finishedRows.first['track_inventory'] as int? ?? 0) != 1 ||
          (finishedRows.first['active'] as int? ?? 0) != 1 ||
          finishedRows.first['deleted_at'] != null) {
        throw StateError(
            'Select an active finished product with inventory tracking enabled');
      }

      final recipe = await txn.query(
        'product_recipes',
        columns: ['id', 'shelf_life_days', 'refresh_after_days'],
        where: 'finished_product_id = ?',
        whereArgs: [finishedProductId],
        limit: 1,
      );
      if (recipe.isEmpty) {
        throw StateError('This finished product has no recipe');
      }
      final recipeId = recipe.first['id'] as int;
      final shelfLifeDays = recipe.first['shelf_life_days'] as int? ?? 3;
      final refreshAfterDays = recipe.first['refresh_after_days'] as int? ?? 2;
      final recipeItems = await txn.query(
        'product_recipe_items',
        where: 'recipe_id = ?',
        whereArgs: [recipeId],
      );
      if (recipeItems.isEmpty) {
        throw StateError('This finished product has no recipe items');
      }

      var totalCost = 0;
      final consumptions = <Map<String, Object>>[];
      for (final item in recipeItems) {
        final rawProductId = item['raw_product_id'] as int;
        final requiredQty = (item['quantity'] as int) * quantity;
        final rawRows = await txn.rawQuery('''
          SELECT p.name, p.default_unit, p.track_inventory, p.purchase_price_paise,
                 COALESCE(i.current_qty, 0) AS current_qty,
                 COALESCE(i.min_qty, p.min_stock, 0) AS min_qty
          FROM products p
          LEFT JOIN inventory_items i ON i.product_id = p.id
          WHERE p.id = ? AND p.active = 1 AND p.deleted_at IS NULL
        ''', [rawProductId]);
        if (rawRows.isEmpty ||
            (rawRows.first['track_inventory'] as int? ?? 0) != 1) {
          throw StateError('A recipe raw product is no longer available');
        }
        final availableQty = rawRows.first['current_qty'] as int;
        final name = rawRows.first['name'] as String;
        if (availableQty < requiredQty) {
          throw StateError(
              'Insufficient stock: $name needs $requiredQty, available $availableQty');
        }
        final unitCost = rawRows.first['purchase_price_paise'] as int? ?? 0;
        final lineCost = unitCost * requiredQty;
        totalCost += lineCost;
        consumptions.add({
          'rawProductId': rawProductId,
          'name': name,
          'unit': rawRows.first['default_unit'] as String,
          'quantity': requiredQty,
          'unitCost': unitCost,
          'lineCost': lineCost,
          'minQty': rawRows.first['min_qty'] as int,
        });
      }

      final productionId = await txn.insert('productions', {
        'finished_product_id': finishedProductId,
        'quantity': quantity,
        'production_cost_paise': totalCost,
        'note': note?.trim().isEmpty ?? true ? null : note!.trim(),
        'operator_name':
            operatorName.trim().isEmpty ? 'Admin' : operatorName.trim(),
        'device_name':
            deviceName?.trim().isEmpty ?? true ? null : deviceName!.trim(),
        'produced_at': now,
        'created_at': now,
      });

      for (final consumption in consumptions) {
        final rawProductId = consumption['rawProductId'] as int;
        final amount = consumption['quantity'] as int;
        await _changeStock(
          txn: txn,
          productId: rawProductId,
          delta: -amount,
          minQty: consumption['minQty'] as int,
          updatedAt: now,
        );
        await txn.insert('inventory_transactions', {
          'product_id': rawProductId,
          'txn_type': 'production',
          'qty': amount,
          'source': 'Production',
          'reason': 'Produced From Recipe',
          'note': 'Production #$productionId',
          'purchase_price_paise': consumption['unitCost'],
          'created_at': now,
        });
        await txn.insert('production_consumptions', {
          'production_id': productionId,
          'raw_product_id': rawProductId,
          'raw_product_name': consumption['name'],
          'unit': consumption['unit'],
          'quantity': amount,
          'unit_cost_paise': consumption['unitCost'],
          'total_cost_paise': consumption['lineCost'],
        });
      }

      await _changeStock(
        txn: txn,
        productId: finishedProductId,
        delta: quantity,
        minQty: finishedRows.first['min_stock'] as int? ?? 0,
        updatedAt: now,
      );
      await txn.insert('inventory_transactions', {
        'product_id': finishedProductId,
        'txn_type': 'production',
        'qty': quantity,
        'source': 'Production',
        'reason': 'Produced From Recipe',
        'note': 'Production #$productionId',
        'purchase_price_paise': totalCost ~/ quantity,
        'created_at': now,
      });

      final producedAt = DateTime.parse(now);
      final expiryAt = producedAt.add(Duration(days: shelfLifeDays));
      await txn.insert('ready_bouquet_batches', {
        'finished_product_id': finishedProductId,
        'recipe_id': recipeId,
        'production_id': productionId,
        'initial_quantity': quantity,
        'remaining_quantity': quantity,
        'shelf_life_days': shelfLifeDays,
        'refresh_after_days': refreshAfterDays,
        'produced_at': now,
        'expiry_at': expiryAt.toIso8601String(),
        'status': 'fresh',
        'location': 'Store',
        'note': note?.trim().isEmpty ?? true ? null : note!.trim(),
        'created_at': now,
      });

      return ProductionResult(
        productionId: productionId,
        productionCostPaise: totalCost,
        finishedQuantity: quantity,
        finishedProductId: finishedProductId,
      );
    });
  }

  Future<ProductionResult> produceBouquet({
    required int? finishedProductId,
    required String productName,
    required String category,
    required int quantity,
    required List<RecipeItem> components,
    required int sellingPricePaise,
    int labourCostPaise = 0,
    String? imagePath,
    int shelfLifeDays = 3,
    int refreshAfterDays = 2,
    String? note,
    String operatorName = 'Admin',
    String? deviceName,
  }) async {
    if (quantity <= 0) {
      throw StateError('Production quantity must be greater than zero');
    }
    if (components.isEmpty) {
      throw StateError('Add at least one component to the bouquet');
    }
    if (components.any((c) => c.quantity <= 0)) {
      throw StateError('Component quantities must be greater than zero');
    }

    final db = await AppDatabase.instance.database;
    return db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();

      // Ensure finished product exists.
      late int productId;
      if (finishedProductId != null) {
        final existing = await txn.query(
          'products',
          columns: [
            'id',
            'category',
            'track_inventory',
            'active',
            'deleted_at'
          ],
          where: 'id = ?',
          whereArgs: [finishedProductId],
          limit: 1,
        );
        if (existing.isEmpty ||
            !isFinishedProductCategory(existing.first['category'] as String?) ||
            (existing.first['track_inventory'] as int? ?? 0) != 1 ||
            (existing.first['active'] as int? ?? 0) != 1 ||
            existing.first['deleted_at'] != null) {
          throw StateError(
              'Select an active finished product with inventory tracking enabled');
        }
        productId = finishedProductId;
        if (imagePath?.trim().isNotEmpty ?? false) {
          await txn.update(
            'products',
            {
              'image_path': imagePath!.trim(),
              'updated_at': now,
            },
            where: 'id = ?',
            whereArgs: [productId],
          );
        }
      } else {
        final trimmedName = productName.trim();
        if (trimmedName.isEmpty) {
          throw StateError('Bouquet name is required');
        }
        final trimmedCategory = category.trim();
        productId = await txn.insert('products', {
          'name': trimmedName,
          'category': trimmedCategory.isEmpty ? 'Bouquet' : trimmedCategory,
          'default_unit': 'Piece',
          'selling_price_paise': sellingPricePaise,
          'purchase_price_paise': 0,
          'gst_percent': 0,
          'track_inventory': 1,
          'min_stock': 0,
          'active': 1,
          'image_path':
              imagePath?.trim().isEmpty ?? true ? null : imagePath!.trim(),
          'created_at': now,
          'updated_at': now,
          'deleted_at': null,
        });
        await const BarcodeService().generateInternalBarcodeForProductInDb(
          txn,
          productId,
        );
        await txn.insert('inventory_items', {
          'product_id': productId,
          'current_qty': 0,
          'min_qty': 0,
          'updated_at': now,
        });
      }

      var materialCost = 0;
      final consumptions = <Map<String, Object>>[];
      for (final item in components) {
        final requiredQty = item.quantity * quantity;
        final rawRows = await txn.rawQuery('''
          SELECT p.name, p.default_unit, p.track_inventory,
                 COALESCE((
                   SELECT purchase_price_paise
                   FROM inventory_transactions
                   WHERE product_id = p.id
                     AND txn_type = 'purchase'
                     AND purchase_price_paise IS NOT NULL
                   ORDER BY created_at DESC, id DESC
                   LIMIT 1
                 ), 0) AS purchase_price_paise,
                 COALESCE(i.current_qty, 0) AS current_qty,
                 COALESCE(i.min_qty, p.min_stock, 0) AS min_qty
          FROM products p
          LEFT JOIN inventory_items i ON i.product_id = p.id
          WHERE p.id = ? AND p.active = 1 AND p.deleted_at IS NULL
        ''', [item.rawProductId]);
        if (rawRows.isEmpty ||
            (rawRows.first['track_inventory'] as int? ?? 0) != 1) {
          throw StateError('Component ${item.productName} is not available');
        }
        final availableQty = rawRows.first['current_qty'] as int;
        final name = rawRows.first['name'] as String;
        if (availableQty < requiredQty) {
          throw StateError(
              'Insufficient stock: $name needs $requiredQty, available $availableQty');
        }
        final unitCost = rawRows.first['purchase_price_paise'] as int? ?? 0;
        final lineCost = unitCost * requiredQty;
        materialCost += lineCost;
        consumptions.add({
          'rawProductId': item.rawProductId,
          'name': name,
          'unit': rawRows.first['default_unit'] as String,
          'quantity': requiredQty,
          'unitCost': unitCost,
          'lineCost': lineCost,
          'minQty': rawRows.first['min_qty'] as int,
        });
      }

      final totalCost = materialCost + labourCostPaise;

      final productionId = await txn.insert('productions', {
        'finished_product_id': productId,
        'quantity': quantity,
        'production_cost_paise': totalCost,
        'note': note?.trim().isEmpty ?? true ? null : note!.trim(),
        'operator_name':
            operatorName.trim().isEmpty ? 'Admin' : operatorName.trim(),
        'device_name':
            deviceName?.trim().isEmpty ?? true ? null : deviceName!.trim(),
        'produced_at': now,
        'created_at': now,
      });

      for (final consumption in consumptions) {
        final rawProductId = consumption['rawProductId'] as int;
        final amount = consumption['quantity'] as int;
        await _changeStock(
          txn: txn,
          productId: rawProductId,
          delta: -amount,
          minQty: consumption['minQty'] as int,
          updatedAt: now,
        );
        await txn.insert('inventory_transactions', {
          'product_id': rawProductId,
          'txn_type': 'production',
          'qty': amount,
          'source': 'Production',
          'reason': 'Produced Bouquet',
          'note': 'Production #$productionId',
          'purchase_price_paise': consumption['unitCost'],
          'created_at': now,
        });
        await txn.insert('production_consumptions', {
          'production_id': productionId,
          'raw_product_id': rawProductId,
          'raw_product_name': consumption['name'],
          'unit': consumption['unit'],
          'quantity': amount,
          'unit_cost_paise': consumption['unitCost'],
          'total_cost_paise': consumption['lineCost'],
        });
      }

      await _changeStock(
        txn: txn,
        productId: productId,
        delta: quantity,
        minQty: 0,
        updatedAt: now,
      );
      await txn.insert('inventory_transactions', {
        'product_id': productId,
        'txn_type': 'production',
        'qty': quantity,
        'source': 'Production',
        'reason': 'Produced Bouquet',
        'note': 'Production #$productionId',
        'purchase_price_paise': totalCost ~/ quantity,
        'created_at': now,
      });

      final producedAt = DateTime.parse(now);
      final expiryAt = producedAt.add(Duration(days: shelfLifeDays));
      await txn.insert('ready_bouquet_batches', {
        'finished_product_id': productId,
        'recipe_id': null,
        'production_id': productionId,
        'initial_quantity': quantity,
        'remaining_quantity': quantity,
        'shelf_life_days': shelfLifeDays,
        'refresh_after_days': refreshAfterDays,
        'produced_at': now,
        'expiry_at': expiryAt.toIso8601String(),
        'status': 'fresh',
        'location': 'Store',
        'note': note?.trim().isEmpty ?? true ? null : note!.trim(),
        'created_at': now,
      });

      return ProductionResult(
        productionId: productionId,
        productionCostPaise: totalCost,
        finishedQuantity: quantity,
        finishedProductId: productId,
      );
    });
  }

  Future<List<ProductionReportRecord>> getProductionReport({
    required DateTime startDate,
    required DateTime endDate,
    int? productId,
  }) async {
    final db = await AppDatabase.instance.database;
    final where = <String>['pr.produced_at >= ?', 'pr.produced_at <= ?'];
    final args = <Object?>[
      DateTime(startDate.year, startDate.month, startDate.day)
          .toIso8601String(),
      DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59)
          .toIso8601String(),
    ];
    if (productId != null) {
      where.add('pr.finished_product_id = ?');
      args.add(productId);
    }
    final rows = await db.rawQuery('''
      SELECT pr.id, pr.produced_at, p.name, pr.quantity, pr.production_cost_paise,
             pr.reversed_at,
             COALESCE(i.current_qty, 0) AS current_stock
      FROM productions pr
      JOIN products p ON p.id = pr.finished_product_id
      LEFT JOIN inventory_items i ON i.product_id = p.id
      WHERE ${where.join(' AND ')}
      ORDER BY pr.produced_at DESC, pr.id DESC
    ''', args);
    return rows
        .map((row) => ProductionReportRecord(
              id: row['id'] as int,
              producedAt: row['produced_at'] as String,
              productName: row['name'] as String,
              quantity: row['quantity'] as int,
              productionCostPaise: row['production_cost_paise'] as int,
              currentStock: row['current_stock'] as int,
              isReversed: row['reversed_at'] != null,
            ))
        .toList();
  }

  Future<ProductionDetail?> getProductionDetail(int productionId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT pr.id, pr.finished_product_id, pr.quantity, pr.production_cost_paise, pr.produced_at,
             pr.operator_name, pr.device_name, pr.note, pr.reversed_at,
             pr.reversal_note, p.name AS product_name
      FROM productions pr
      JOIN products p ON p.id = pr.finished_product_id
      WHERE pr.id = ?
      LIMIT 1
    ''', [productionId]);
    if (rows.isEmpty) return null;
    final row = rows.first;
    final consumptions = await db.query(
      'production_consumptions',
      where: 'production_id = ?',
      whereArgs: [productionId],
      orderBy: 'id ASC',
    );
    return ProductionDetail(
      id: row['id'] as int,
      finishedProductId: row['finished_product_id'] as int,
      productName: row['product_name'] as String,
      quantity: row['quantity'] as int,
      productionCostPaise: row['production_cost_paise'] as int,
      producedAt: row['produced_at'] as String,
      operatorName: row['operator_name'] as String? ?? 'Admin',
      deviceName: row['device_name'] as String?,
      note: row['note'] as String?,
      reversedAt: row['reversed_at'] as String?,
      reversalNote: row['reversal_note'] as String?,
      consumptions: consumptions
          .map((item) => ProductionConsumptionDetail(
                rawProductId: item['raw_product_id'] as int,
                productName: item['raw_product_name'] as String? ?? '',
                unit: item['unit'] as String? ?? 'Piece',
                quantity: item['quantity'] as int,
                unitCostPaise: item['unit_cost_paise'] as int,
                totalCostPaise: item['total_cost_paise'] as int,
              ))
          .toList(),
    );
  }

  Future<void> reverseProduction({
    required int productionId,
    String? note,
  }) async {
    final db = await AppDatabase.instance.database;
    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final productionRows = await txn.query(
        'productions',
        where: 'id = ?',
        whereArgs: [productionId],
        limit: 1,
      );
      if (productionRows.isEmpty) {
        throw StateError('Production record not found');
      }
      final production = productionRows.first;
      if (production['reversed_at'] != null) {
        throw StateError('This production has already been reversed');
      }
      final finishedProductId = production['finished_product_id'] as int;
      final finishedQuantity = production['quantity'] as int;
      final finishedItems = await txn.query('inventory_items',
          where: 'product_id = ?', whereArgs: [finishedProductId], limit: 1);
      final finishedAvailable =
          finishedItems.isEmpty ? 0 : finishedItems.first['current_qty'] as int;
      if (finishedAvailable < finishedQuantity) {
        throw StateError(
            'Cannot reverse: only $finishedAvailable finished items remain in stock');
      }
      final consumptions = await txn.query('production_consumptions',
          where: 'production_id = ?', whereArgs: [productionId]);
      if (consumptions.isEmpty) {
        throw StateError('Production recipe snapshot is unavailable');
      }

      for (final consumption in consumptions) {
        final rawProductId = consumption['raw_product_id'] as int;
        final rawItems = await txn.query('inventory_items',
            where: 'product_id = ?', whereArgs: [rawProductId], limit: 1);
        final minQty = rawItems.isEmpty ? 0 : rawItems.first['min_qty'] as int;
        final amount = consumption['quantity'] as int;
        await _changeStock(
            txn: txn,
            productId: rawProductId,
            delta: amount,
            minQty: minQty,
            updatedAt: now);
        await txn.insert('inventory_transactions', {
          'product_id': rawProductId,
          'txn_type': 'production_reversal',
          'qty': amount,
          'source': 'Production',
          'reason': 'Production Reversal',
          'note': 'Reversal of PROD-${productionId.toString().padLeft(6, '0')}',
          'purchase_price_paise': consumption['unit_cost_paise'],
          'created_at': now,
        });
      }
      final finishedMinQty =
          finishedItems.isEmpty ? 0 : finishedItems.first['min_qty'] as int;
      await _changeStock(
          txn: txn,
          productId: finishedProductId,
          delta: -finishedQuantity,
          minQty: finishedMinQty,
          updatedAt: now);
      await txn.insert('inventory_transactions', {
        'product_id': finishedProductId,
        'txn_type': 'production_reversal',
        'qty': finishedQuantity,
        'source': 'Production',
        'reason': 'Production Reversal',
        'note': 'Reversal of PROD-${productionId.toString().padLeft(6, '0')}',
        'purchase_price_paise':
            (production['production_cost_paise'] as int) ~/ finishedQuantity,
        'created_at': now,
      });
      await txn.update(
        'productions',
        {
          'reversed_at': now,
          'reversal_note': note?.trim().isEmpty ?? true ? null : note!.trim(),
        },
        where: 'id = ?',
        whereArgs: [productionId],
      );
    });
  }

  Future<void> _changeStock({
    required Transaction txn,
    required int productId,
    required int delta,
    required int minQty,
    required String updatedAt,
  }) async {
    final rows = await txn.query('inventory_items',
        where: 'product_id = ?', whereArgs: [productId], limit: 1);
    if (rows.isEmpty) {
      await txn.insert('inventory_items', {
        'product_id': productId,
        'current_qty': delta,
        'min_qty': minQty,
        'updated_at': updatedAt,
      });
      return;
    }
    final currentQty = rows.first['current_qty'] as int;
    await txn.update(
      'inventory_items',
      {
        'current_qty': currentQty + delta,
        'min_qty': minQty,
        'updated_at': updatedAt
      },
      where: 'product_id = ?',
      whereArgs: [productId],
    );
  }

  ProductionProduct _mapProductionProduct(Map<String, Object?> row) {
    return ProductionProduct(
      id: row['id'] as int,
      name: row['name'] as String,
      unit: row['default_unit'] as String,
      barcode: row['barcode'] as String? ?? '',
      sellingPricePaise: row['selling_price_paise'] as int,
      purchasePricePaise: (row['purchase_price_paise'] as int?) ?? 0,
      currentQty: row['current_qty'] as int,
      hasRecipe: (row['has_recipe'] as int) == 1,
    );
  }
}
