import 'package:sqflite/sqflite.dart';

import '../data/database/app_database.dart';

class BarcodeService {
  static const String internalPrefix = 'FL';
  static const int internalDigits = 8;

  const BarcodeService();

  static String formatInternalBarcode(int sequence) {
    if (sequence <= 0) {
      throw ArgumentError('Barcode sequence must be greater than zero');
    }
    return '$internalPrefix${sequence.toString().padLeft(internalDigits, '0')}';
  }

  Future<String> generateInternalBarcodeForProduct(
    int productId, {
    bool overwrite = false,
  }) async {
    final db = await AppDatabase.instance.database;
    return generateInternalBarcodeForProductInDb(
      db,
      productId,
      overwrite: overwrite,
    );
  }

  Future<String> generateInternalBarcodeForProductInDb(
    DatabaseExecutor db,
    int productId, {
    bool overwrite = false,
  }) async {
    final product = await db.query(
      'products',
      columns: ['id', 'floraprise_barcode'],
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [productId],
      limit: 1,
    );
    if (product.isEmpty) {
      throw StateError('Product not found');
    }

    final existing = (product.first['floraprise_barcode'] as String?)?.trim();
    if (!overwrite && existing != null && existing.isNotEmpty) {
      return existing;
    }

    var sequence = productId;
    var candidate = formatInternalBarcode(sequence);
    while (!await isInternalBarcodeUniqueInDb(
      db,
      candidate,
      excludingProductId: productId,
    )) {
      sequence++;
      candidate = formatInternalBarcode(sequence);
    }

    await db.update(
      'products',
      {
        'floraprise_barcode': candidate,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [productId],
    );
    return candidate;
  }

  Future<bool> isInternalBarcodeUnique(
    String barcode, {
    int? excludingProductId,
  }) async {
    final db = await AppDatabase.instance.database;
    return isInternalBarcodeUniqueInDb(
      db,
      barcode,
      excludingProductId: excludingProductId,
    );
  }

  Future<bool> isInternalBarcodeUniqueInDb(
    DatabaseExecutor db,
    String barcode, {
    int? excludingProductId,
  }) async {
    final normalized = barcode.trim();
    if (normalized.isEmpty) return false;

    final where = StringBuffer('floraprise_barcode = ? AND deleted_at IS NULL');
    final args = <Object?>[normalized];
    if (excludingProductId != null) {
      where.write(' AND id <> ?');
      args.add(excludingProductId);
    }

    final rows = await db.query(
      'products',
      columns: ['id'],
      where: where.toString(),
      whereArgs: args,
      limit: 1,
    );
    return rows.isEmpty;
  }

  Future<void> ensureAllProductsHaveInternalBarcodes() async {
    final db = await AppDatabase.instance.database;
    await ensureAllProductsHaveInternalBarcodesInDb(db);
  }

  Future<void> ensureAllProductsHaveInternalBarcodesInDb(
    DatabaseExecutor db,
  ) async {
    final rows = await db.query(
      'products',
      columns: ['id'],
      where:
          "deleted_at IS NULL AND (floraprise_barcode IS NULL OR TRIM(floraprise_barcode) = '')",
      orderBy: 'id ASC',
    );
    for (final row in rows) {
      await generateInternalBarcodeForProductInDb(db, row['id'] as int);
    }
  }
}
