import '../database/app_database.dart';
import '../../services/barcode_service.dart';

enum ProductSort {
  nameAsc,
  nameDesc,
  latestUpdated,
  priceLowToHigh,
  priceHighToLow,
}

class ProductRecord {
  final int id;
  final String name;
  final String category;
  final String defaultUnit;
  final int sellingPricePaise;
  final int? purchasePricePaise;
  final int gstPercent;
  final String sku;
  final String manufacturerBarcode;
  final String florapriseBarcode;
  final bool trackInventory;
  final int minStock;
  final String supplier;
  final String notes;
  final bool active;
  final bool favorite;
  final String? imagePath;
  final String? deletedAt;
  final String createdAt;
  final String updatedAt;

  const ProductRecord({
    required this.id,
    required this.name,
    required this.category,
    required this.defaultUnit,
    required this.sellingPricePaise,
    required this.purchasePricePaise,
    required this.gstPercent,
    required this.sku,
    required this.manufacturerBarcode,
    required this.florapriseBarcode,
    required this.trackInventory,
    required this.minStock,
    required this.supplier,
    required this.notes,
    required this.active,
    required this.favorite,
    this.imagePath,
    required this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });
}

class ProductUpsertInput {
  final String name;
  final String category;
  final String defaultUnit;
  final int sellingPricePaise;
  final int? purchasePricePaise;
  final int gstPercent;
  final String sku;
  final String manufacturerBarcode;
  final String florapriseBarcode;
  final bool trackInventory;
  final int minStock;
  final String supplier;
  final String notes;
  final bool active;
  final bool favorite;

  const ProductUpsertInput({
    required this.name,
    required this.category,
    this.defaultUnit = 'Piece',
    required this.sellingPricePaise,
    this.purchasePricePaise,
    this.gstPercent = 12,
    this.sku = '',
    this.manufacturerBarcode = '',
    this.florapriseBarcode = '',
    this.trackInventory = false,
    this.minStock = 0,
    this.supplier = '',
    this.notes = '',
    this.active = true,
    this.favorite = false,
  });
}

class ProductLookupRecord {
  final int id;
  final String code;
  final String name;
  final int sellingPricePaise;
  final int gstPercent;
  final bool trackInventory;

  const ProductLookupRecord({
    required this.id,
    required this.code,
    required this.name,
    required this.sellingPricePaise,
    required this.gstPercent,
    required this.trackInventory,
  });
}

class ProductInventoryRecord {
  final int id;
  final String code;
  final String name;
  final String category;
  final String defaultUnit;
  final String sku;
  final String barcode;
  final String manufacturerBarcode;
  final String florapriseBarcode;
  final int sellingPricePaise;
  final int? purchasePricePaise;
  final int gstPercent;
  final bool trackInventory;
  final bool active;
  final bool favorite;
  final int currentQty;
  final int minQty;

  const ProductInventoryRecord({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.defaultUnit,
    required this.sku,
    required this.barcode,
    required this.manufacturerBarcode,
    required this.florapriseBarcode,
    required this.sellingPricePaise,
    required this.purchasePricePaise,
    required this.gstPercent,
    required this.trackInventory,
    required this.active,
    required this.favorite,
    required this.currentQty,
    required this.minQty,
  });
}

class ProductRepository {
  ProductRepository({BarcodeService? barcodeService})
      : _barcodeService = barcodeService ?? const BarcodeService();

  final BarcodeService _barcodeService;

  static const List<String> allowedCategories = [
    'Flowers',
    'Fillers',
    'Foliage',
    'Packing',
    'Accessories',
    'Finished Products',
    'Bouquet',
    'Bunch',
    'Arrangement',
    'Centerpiece',
    'Basket Arrangement',
    'Vase Arrangement',
    'Wreath',
    'Corsage',
    'Boutonniere',
    'Garland',
    'Floral Box',
    'Gift Hamper',
    'Custom',
    'Others',
  ];

  static const List<String> allowedUnits = [
    'Stem',
    'Bunch',
    'Piece',
    'Box',
    'Roll',
    'Pot',
    'Packet',
    'Kg',
    'Meter',
  ];

  static String defaultUnitForCategory(String category) {
    switch (category) {
      case 'Flowers':
        return 'Stem';
      case 'Fillers':
      case 'Foliage':
        return 'Bunch';
      case 'Finished Products':
      case 'Packing':
      case 'Accessories':
      case 'Others':
      default:
        return 'Piece';
    }
  }

  String _categoryOrDefault(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'Others' : trimmed;
  }

  String _unitOrDefault(String value) {
    return allowedUnits.contains(value) ? value : 'Piece';
  }

  Future<List<ProductRecord>> listProducts({
    String query = '',
    String? category,
    bool? trackInventory,
    bool showActive = true,
    bool showInactive = true,
    bool favoriteOnly = false,
    bool includeDeleted = false,
    ProductSort sort = ProductSort.nameAsc,
  }) async {
    final db = await AppDatabase.instance.database;

    final where = <String>[];
    final args = <Object?>[];

    if (!includeDeleted) {
      where.add('deleted_at IS NULL');
    }

    if (category != null && category.trim().isNotEmpty) {
      where.add('category = ?');
      args.add(category.trim());
    }

    if (trackInventory != null) {
      where.add('track_inventory = ?');
      args.add(trackInventory ? 1 : 0);
    }

    if (!showActive || !showInactive) {
      if (showActive && !showInactive) {
        where.add('active = 1');
      } else if (!showActive && showInactive) {
        where.add('active = 0');
      } else {
        where.add('1 = 0');
      }
    }

    if (favoriteOnly) {
      where.add('is_favorite = 1');
    }

    final trimmedQuery = query.trim().toLowerCase();
    if (trimmedQuery.isNotEmpty) {
      where.add('''
        (
          LOWER(name) LIKE ?
          OR LOWER(COALESCE(sku, '')) LIKE ?
          OR LOWER(COALESCE(manufacturer_barcode, '')) LIKE ?
          OR LOWER(COALESCE(floraprise_barcode, '')) LIKE ?
          OR LOWER(COALESCE(code, '')) LIKE ?
          OR LOWER(COALESCE(barcode, '')) LIKE ?
        )
      ''');
      final pattern = '%$trimmedQuery%';
      args
        ..add(pattern)
        ..add(pattern)
        ..add(pattern)
        ..add(pattern)
        ..add(pattern)
        ..add(pattern);
    }

    final orderBy = switch (sort) {
      ProductSort.nameAsc => 'name COLLATE NOCASE ASC',
      ProductSort.nameDesc => 'name COLLATE NOCASE DESC',
      ProductSort.latestUpdated => 'updated_at DESC',
      ProductSort.priceLowToHigh => 'selling_price_paise ASC',
      ProductSort.priceHighToLow => 'selling_price_paise DESC',
    };

    final rows = await db.query(
      'products',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args,
      orderBy: orderBy,
    );

    return rows.map(_mapProductRecord).toList();
  }

  Future<ProductRecord?> getProductById(int id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'products',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _mapProductRecord(rows.first);
  }

  Future<int> createProduct(ProductUpsertInput input) async {
    _validateInput(input);
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    final row = <String, Object?>{
      'code': input.sku.trim().isEmpty ? null : input.sku.trim(),
      'name': input.name.trim(),
      'category': _categoryOrDefault(input.category.trim()),
      'default_unit': _unitOrDefault(input.defaultUnit.trim()),
      'selling_price_paise': input.sellingPricePaise,
      'purchase_price_paise': input.purchasePricePaise,
      'gst_percent': input.gstPercent,
      'sku': input.sku.trim().isEmpty ? null : input.sku.trim(),
      'barcode': input.manufacturerBarcode.trim().isEmpty
          ? null
          : input.manufacturerBarcode.trim(),
      'manufacturer_barcode': input.manufacturerBarcode.trim().isEmpty
          ? null
          : input.manufacturerBarcode.trim(),
      'floraprise_barcode': input.florapriseBarcode.trim().isEmpty
          ? null
          : input.florapriseBarcode.trim(),
      'track_inventory': input.trackInventory ? 1 : 0,
      'min_stock': input.trackInventory ? input.minStock : 0,
      'supplier': input.supplier.trim().isEmpty ? null : input.supplier.trim(),
      'notes': input.notes.trim().isEmpty ? null : input.notes.trim(),
      'is_favorite': input.favorite ? 1 : 0,
      'active': input.active ? 1 : 0,
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
    };

    final id = await db.insert('products', row);

    await _barcodeService.generateInternalBarcodeForProduct(id);

    await _syncInventoryRow(
      db: db,
      productId: id,
      trackInventory: input.trackInventory,
      minStock: input.minStock,
    );

    return id;
  }

  Future<void> updateProduct(int id, ProductUpsertInput input) async {
    _validateInput(input);
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'products',
      {
        'code': input.sku.trim().isEmpty ? null : input.sku.trim(),
        'name': input.name.trim(),
        'category': _categoryOrDefault(input.category.trim()),
        'default_unit': _unitOrDefault(input.defaultUnit.trim()),
        'selling_price_paise': input.sellingPricePaise,
        'purchase_price_paise': input.purchasePricePaise,
        'gst_percent': input.gstPercent,
        'sku': input.sku.trim().isEmpty ? null : input.sku.trim(),
        'barcode': input.manufacturerBarcode.trim().isEmpty
            ? null
            : input.manufacturerBarcode.trim(),
        'manufacturer_barcode': input.manufacturerBarcode.trim().isEmpty
            ? null
            : input.manufacturerBarcode.trim(),
        'floraprise_barcode': input.florapriseBarcode.trim().isEmpty
            ? null
            : input.florapriseBarcode.trim(),
        'track_inventory': input.trackInventory ? 1 : 0,
        'min_stock': input.trackInventory ? input.minStock : 0,
        'supplier':
            input.supplier.trim().isEmpty ? null : input.supplier.trim(),
        'notes': input.notes.trim().isEmpty ? null : input.notes.trim(),
        'is_favorite': input.favorite ? 1 : 0,
        'active': input.active ? 1 : 0,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    final floraprise = input.florapriseBarcode.trim();
    if (floraprise.isEmpty) {
      await _barcodeService.generateInternalBarcodeForProduct(id);
    }

    await _syncInventoryRow(
      db: db,
      productId: id,
      trackInventory: input.trackInventory,
      minStock: input.minStock,
    );
  }

  Future<void> softDeleteProduct(int id) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'products',
      {
        'deleted_at': now,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> restoreProduct(int id) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'products',
      {
        'deleted_at': null,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setFavorite({required int id, required bool favorite}) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'products',
      {
        'is_favorite': favorite ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setActive({required int id, required bool active}) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'products',
      {
        'active': active ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ProductInventoryRecord>> listActiveProductsWithInventory() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT
        p.id,
        p.code,
        p.name,
        p.category,
        p.default_unit,
        p.sku,
        p.barcode,
        p.manufacturer_barcode,
        p.floraprise_barcode,
        p.selling_price_paise,
        (
          SELECT purchase_price_paise
          FROM inventory_transactions
          WHERE product_id = p.id
            AND txn_type = 'purchase'
            AND purchase_price_paise IS NOT NULL
          ORDER BY created_at DESC, id DESC
          LIMIT 1
        ) AS latest_purchase_price_paise,
        p.gst_percent,
        p.track_inventory,
        p.active,
        p.is_favorite,
        COALESCE(i.current_qty, 0) AS current_qty,
        COALESCE(i.min_qty, p.min_stock, 0) AS min_qty
      FROM products p
      LEFT JOIN inventory_items i ON i.product_id = p.id
      WHERE p.active = 1 AND p.deleted_at IS NULL
      ORDER BY p.name COLLATE NOCASE ASC
    ''');

    return rows.map((row) {
      final id = row['id'] as int;
      final sku = (row['sku'] as String?)?.trim() ?? '';
      final manufacturer = (row['manufacturer_barcode'] as String?)?.trim() ??
          (row['barcode'] as String?)?.trim() ??
          '';
      final floraprise = (row['floraprise_barcode'] as String?)?.trim() ?? '';
      return ProductInventoryRecord(
        id: id,
        code: (row['code'] as String?) ?? (sku.isEmpty ? 'P-$id' : sku),
        name: row['name'] as String,
        category: (row['category'] as String?) ?? 'Other',
        defaultUnit: (row['default_unit'] as String?) ?? 'Piece',
        sku: sku,
        barcode: manufacturer,
        manufacturerBarcode: manufacturer,
        florapriseBarcode: floraprise,
        sellingPricePaise: row['selling_price_paise'] as int,
        purchasePricePaise: row['latest_purchase_price_paise'] as int?,
        gstPercent: row['gst_percent'] as int,
        trackInventory: (row['track_inventory'] as int? ?? 0) == 1,
        active: (row['active'] as int? ?? 1) == 1,
        favorite: (row['is_favorite'] as int? ?? 0) == 1,
        currentQty: row['current_qty'] as int,
        minQty: row['min_qty'] as int,
      );
    }).toList();
  }

  Future<List<ProductRecord>> listProductsMissingFlorapriseBarcode() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'products',
      where: '''
        active = 1
        AND deleted_at IS NULL
        AND (floraprise_barcode IS NULL OR TRIM(floraprise_barcode) = '')
      ''',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(_mapProductRecord).toList();
  }

  Future<String> generateFlorapriseBarcode(int productId) async {
    return _barcodeService.generateInternalBarcodeForProduct(productId);
  }

  Future<ProductInventoryRecord?> lookupProductBySearchPriority(
      String value) async {
    final rawInput = value.trim();
    if (rawInput.isEmpty) {
      return null;
    }

    final needle = rawInput.toLowerCase();
    final likeNeedle = '%$needle%';
    final db = await AppDatabase.instance.database;

    final rows = await db.rawQuery(
      '''
      SELECT
        p.id,
        p.code,
        p.name,
        p.category,
        p.default_unit,
        p.sku,
        p.barcode,
        p.manufacturer_barcode,
        p.floraprise_barcode,
        p.selling_price_paise,
        p.purchase_price_paise,
        p.gst_percent,
        p.track_inventory,
        p.active,
        p.is_favorite,
        COALESCE(i.current_qty, 0) AS current_qty,
        COALESCE(i.min_qty, p.min_stock, 0) AS min_qty
      FROM products p
      LEFT JOIN inventory_items i ON i.product_id = p.id
      WHERE p.active = 1
        AND p.deleted_at IS NULL
        AND (
          LOWER(COALESCE(p.manufacturer_barcode, '')) = ?
          OR LOWER(COALESCE(p.barcode, '')) = ?
          OR LOWER(COALESCE(p.floraprise_barcode, '')) = ?
          OR LOWER(COALESCE(p.sku, '')) = ?
          OR LOWER(COALESCE(p.code, '')) = ?
          OR LOWER(p.name) LIKE ?
        )
      ORDER BY
        CASE
          WHEN LOWER(COALESCE(p.manufacturer_barcode, '')) = ? OR LOWER(COALESCE(p.barcode, '')) = ? THEN 1
          WHEN LOWER(COALESCE(p.floraprise_barcode, '')) = ? THEN 2
          WHEN LOWER(COALESCE(p.sku, '')) = ? OR LOWER(COALESCE(p.code, '')) = ? THEN 3
          WHEN LOWER(p.name) LIKE ? THEN 4
          ELSE 5
        END,
        p.name COLLATE NOCASE ASC
      LIMIT 1
      ''',
      [
        needle,
        needle,
        needle,
        needle,
        needle,
        likeNeedle,
        needle,
        needle,
        needle,
        needle,
        needle,
        likeNeedle,
      ],
    );

    if (rows.isEmpty) {
      await _insertLookupAudit(rawInput, null);
      return null;
    }

    final row = rows.first;
    final id = row['id'] as int;
    await _insertLookupAudit(rawInput, id);

    final sku = (row['sku'] as String?)?.trim() ?? '';
    final manufacturer = (row['manufacturer_barcode'] as String?)?.trim() ??
        (row['barcode'] as String?)?.trim() ??
        '';
    final floraprise = (row['floraprise_barcode'] as String?)?.trim() ?? '';

    return ProductInventoryRecord(
      id: id,
      code: (row['code'] as String?) ?? (sku.isEmpty ? 'P-$id' : sku),
      name: row['name'] as String,
      category: (row['category'] as String?) ?? 'Other',
      defaultUnit: (row['default_unit'] as String?) ?? 'Piece',
      sku: sku,
      barcode: manufacturer,
      manufacturerBarcode: manufacturer,
      florapriseBarcode: floraprise,
      sellingPricePaise: row['selling_price_paise'] as int,
      purchasePricePaise: row['purchase_price_paise'] as int?,
      gstPercent: row['gst_percent'] as int,
      trackInventory: (row['track_inventory'] as int? ?? 0) == 1,
      active: (row['active'] as int? ?? 1) == 1,
      favorite: (row['is_favorite'] as int? ?? 0) == 1,
      currentQty: row['current_qty'] as int,
      minQty: row['min_qty'] as int,
    );
  }

  Future<ProductLookupRecord?> findByLookup(String value) async {
    final matched = await lookupProductBySearchPriority(value);
    if (matched == null) {
      return null;
    }

    return ProductLookupRecord(
      id: matched.id,
      code: matched.code,
      name: matched.name,
      sellingPricePaise: matched.sellingPricePaise,
      gstPercent: matched.gstPercent,
      trackInventory: matched.trackInventory,
    );
  }

  Future<ProductLookupRecord?> findByBarcode(String barcode) {
    return findByLookup(barcode);
  }

  ProductRecord _mapProductRecord(Map<String, Object?> row) {
    final id = row['id'] as int;
    final sku = (row['sku'] as String?)?.trim() ??
        (row['code'] as String?)?.trim() ??
        '';
    final manufacturer = (row['manufacturer_barcode'] as String?)?.trim() ??
        (row['barcode'] as String?)?.trim() ??
        '';
    final floraprise =
        (row['floraprise_barcode'] as String?)?.trim() ?? 'FLR-$id';

    return ProductRecord(
      id: id,
      name: (row['name'] as String?) ?? '',
      category: (row['category'] as String?) ?? 'Other',
      defaultUnit: (row['default_unit'] as String?) ?? 'Piece',
      sellingPricePaise: (row['selling_price_paise'] as int?) ?? 0,
      purchasePricePaise: row['purchase_price_paise'] as int?,
      gstPercent: (row['gst_percent'] as int?) ?? 0,
      sku: sku,
      manufacturerBarcode: manufacturer,
      florapriseBarcode: floraprise,
      trackInventory: (row['track_inventory'] as int? ?? 0) == 1,
      minStock: (row['min_stock'] as int? ?? 0),
      supplier: (row['supplier'] as String?)?.trim() ?? '',
      notes: (row['notes'] as String?)?.trim() ?? '',
      active: (row['active'] as int? ?? 1) == 1,
      favorite: (row['is_favorite'] as int? ?? 0) == 1,
      imagePath: (row['image_path'] as String?)?.trim(),
      deletedAt: row['deleted_at'] as String?,
      createdAt: (row['created_at'] as String?) ?? '',
      updatedAt: (row['updated_at'] as String?) ?? '',
    );
  }

  void _validateInput(ProductUpsertInput input) {
    if (input.name.trim().isEmpty) {
      throw ArgumentError('Product name is required');
    }
    if (input.sellingPricePaise < 0) {
      throw ArgumentError('Selling price cannot be negative');
    }
    if ((input.purchasePricePaise ?? 0) < 0) {
      throw ArgumentError('Purchase price cannot be negative');
    }
    if (input.minStock < 0) {
      throw ArgumentError('Minimum stock cannot be negative');
    }
    if (!allowedUnits.contains(input.defaultUnit.trim())) {
      throw ArgumentError('Default unit is invalid');
    }
  }

  Future<void> _syncInventoryRow({
    required dynamic db,
    required int productId,
    required bool trackInventory,
    required int minStock,
  }) async {
    final rows = await db.query(
      'inventory_items',
      where: 'product_id = ?',
      whereArgs: [productId],
      limit: 1,
    );

    final now = DateTime.now().toIso8601String();

    if (rows.isEmpty) {
      await db.insert('inventory_items', {
        'product_id': productId,
        'current_qty': 0,
        'min_qty': trackInventory ? minStock : 0,
        'updated_at': now,
      });
      return;
    }

    await db.update(
      'inventory_items',
      {
        'min_qty': trackInventory ? minStock : 0,
        'updated_at': now,
      },
      where: 'product_id = ?',
      whereArgs: [productId],
    );
  }

  Future<void> _insertLookupAudit(String query, int? productId) async {
    final db = await AppDatabase.instance.database;
    await db.insert('barcode_lookup_audit', {
      'barcode': query,
      'matched_product_id': productId,
      'requested_at': DateTime.now().toIso8601String(),
    });
  }
}
