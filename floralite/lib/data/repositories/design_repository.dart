import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../models/design.dart';
import '../database/app_database.dart';

class DesignRepository {
  Future<String> storeImageLocally(String sourcePath) async {
    final dbPath = await getDatabasesPath();
    final imagesDir = Directory(p.join(dbPath, 'design_images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final extension =
        p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);
    final fileName =
        'design_${DateTime.now().millisecondsSinceEpoch}$extension';
    final targetPath = p.join(imagesDir.path, fileName);

    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw StateError('Image file not found');
    }

    final copied = await sourceFile.copy(targetPath);
    return copied.path;
  }

  Future<List<DesignRecord>> listDesigns({
    String? query,
    String? flower,
    String? occasion,
    String? color,
    String? status,
    bool? favourite,
    int? minPricePaise,
    int? maxPricePaise,
  }) async {
    final db = await AppDatabase.instance.database;
    final where = <String>['deleted_at IS NULL'];
    final args = <Object?>[];

    final q = (query ?? '').trim().toLowerCase();
    if (q.isNotEmpty) {
      where.add('('
          'LOWER(bouquet_id) LIKE ? OR '
          'LOWER(description) LIKE ? OR '
          'LOWER(COALESCE(flowers, "")) LIKE ? OR '
          'LOWER(COALESCE(occasion, "")) LIKE ? OR '
          'LOWER(COALESCE(color, "")) LIKE ? OR '
          'LOWER(COALESCE(collection, "")) LIKE ? OR '
          'LOWER(COALESCE(notes, "")) LIKE ?'
          ')');
      final like = '%$q%';
      args.addAll([like, like, like, like, like, like, like]);
    }

    if ((flower ?? '').trim().isNotEmpty) {
      where.add('LOWER(COALESCE(flowers, "")) LIKE ?');
      args.add('%${flower!.trim().toLowerCase()}%');
    }
    if ((occasion ?? '').trim().isNotEmpty) {
      where.add('('
          'LOWER(COALESCE(occasion, "")) LIKE ? OR '
          'LOWER(COALESCE(occasion, "")) = ?'
          ')');
      final occasionQuery = occasion!.trim().toLowerCase();
      args.addAll(['%$occasionQuery%', 'all']);
    }
    if ((color ?? '').trim().isNotEmpty) {
      where.add('LOWER(COALESCE(color, "")) LIKE ?');
      args.add('%${color!.trim().toLowerCase()}%');
    }
    final normalizedStatus = _normalizeStatusFilter(status);
    if (normalizedStatus != null) {
      if (normalizedStatus == 'needs_review') {
        where.add('(LOWER(COALESCE(status, "")) IN (?, ?, ?))');
        args.addAll(['needs_review', 'needs review', 'draft']);
      } else {
        where.add('LOWER(COALESCE(status, "")) = ?');
        args.add(normalizedStatus);
      }
    }
    if (favourite != null) {
      where.add('is_favorite = ?');
      args.add(favourite ? 1 : 0);
    }
    if (minPricePaise != null) {
      where.add('COALESCE(selling_price_paise, 0) >= ?');
      args.add(minPricePaise);
    }
    if (maxPricePaise != null) {
      where.add('COALESCE(selling_price_paise, 0) <= ?');
      args.add(maxPricePaise);
    }

    final rows = await db.query(
      'designs',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'updated_at DESC',
    );

    return rows.map(DesignRecord.fromMap).toList();
  }

  Future<DesignRecord?> getById(int id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'designs',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DesignRecord.fromMap(rows.first);
  }

  Future<DesignRecord> create({
    required String description,
    required String? imagePath,
    required int? sellingPricePaise,
    String? flowers,
    String? occasion,
    String? color,
    String? collection,
    String? notes,
  }) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    String? storedImagePath;
    if (imagePath != null && imagePath.trim().isNotEmpty) {
      storedImagePath = await storeImageLocally(imagePath);
    }

    final normalizedDescription = description.trim();
    final derivedStatus = _deriveStatus(
      imagePath: storedImagePath,
      description: normalizedDescription,
      sellingPricePaise: sellingPricePaise,
    );

    final id = await db.insert('designs', {
      'bouquet_id': '',
      'image_path': storedImagePath,
      'description': normalizedDescription,
      'selling_price_paise': sellingPricePaise,
      'flowers': _nullIfEmpty(flowers),
      'occasion': _nullIfEmpty(occasion),
      'color': _nullIfEmpty(color),
      'collection': _nullIfEmpty(collection),
      'notes': _nullIfEmpty(notes),
      'status': derivedStatus,
      'is_favorite': 0,
      'created_at': now,
      'updated_at': now,
    });

    final bouquetId = 'B-${id.toString().padLeft(4, '0')}';
    await db.update(
      'designs',
      {'bouquet_id': bouquetId},
      where: 'id = ?',
      whereArgs: [id],
    );

    final created = await getById(id);
    if (created == null) {
      throw StateError('Failed to create design');
    }
    return created;
  }

  Future<DesignRecord> update({
    required int id,
    required String description,
    required int? sellingPricePaise,
    String? flowers,
    String? occasion,
    String? color,
    String? collection,
    String? notes,
    String? replaceImagePath,
    bool removeImage = false,
  }) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final current = await getById(id);
    if (current == null) {
      throw StateError('Design not found');
    }

    String? nextImagePath = current.imagePath;
    if (removeImage) {
      nextImagePath = null;
    } else if (replaceImagePath != null && replaceImagePath.trim().isNotEmpty) {
      nextImagePath = await storeImageLocally(replaceImagePath);
    }

    final normalizedDescription = description.trim();
    final derivedStatus = _deriveStatus(
      imagePath: nextImagePath,
      description: normalizedDescription,
      sellingPricePaise: sellingPricePaise,
    );

    await db.update(
      'designs',
      {
        'image_path': nextImagePath,
        'description': normalizedDescription,
        'selling_price_paise': sellingPricePaise,
        'flowers': _nullIfEmpty(flowers),
        'occasion': _nullIfEmpty(occasion),
        'color': _nullIfEmpty(color),
        'collection': _nullIfEmpty(collection),
        'notes': _nullIfEmpty(notes),
        'status': derivedStatus,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    final updated = await getById(id);
    if (updated == null) {
      throw StateError('Failed to update design');
    }
    return updated;
  }

  Future<void> softDelete(int id) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'designs',
      {
        'deleted_at': now,
        'updated_at': now,
      },
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
  }

  Future<void> setFavourite(int id, bool value) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'designs',
      {
        'is_favorite': value ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
  }

  Future<void> bulkCreate({
    required List<String> imagePaths,
    int? sellingPricePaise,
    String? flowers,
    String? occasion,
    String? color,
    String? collection,
    String? notes,
  }) async {
    if (imagePaths.isEmpty) return;

    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      for (final sourcePath in imagePaths) {
        if (sourcePath.trim().isEmpty) {
          continue;
        }

        final storedImagePath = await storeImageLocally(sourcePath);
        const normalizedDescription = 'Imported design';
        final derivedStatus = _deriveStatus(
          imagePath: storedImagePath,
          description: normalizedDescription,
          sellingPricePaise: sellingPricePaise,
        );

        final id = await txn.insert('designs', {
          'bouquet_id': '',
          'image_path': storedImagePath,
          'description': normalizedDescription,
          'selling_price_paise': sellingPricePaise,
          'flowers': _nullIfEmpty(flowers),
          'occasion': _nullIfEmpty(occasion),
          'color': _nullIfEmpty(color),
          'collection': _nullIfEmpty(collection),
          'notes': _nullIfEmpty(notes),
          'status': derivedStatus,
          'is_favorite': 0,
          'created_at': now,
          'updated_at': now,
        });

        final bouquetId = 'B-${id.toString().padLeft(4, '0')}';
        await txn.update(
          'designs',
          {'bouquet_id': bouquetId},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    });
  }

  String? _nullIfEmpty(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _deriveStatus({
    required String? imagePath,
    required String description,
    required int? sellingPricePaise,
  }) {
    final hasImage = imagePath != null && imagePath.trim().isNotEmpty;
    final hasDescription = description.trim().isNotEmpty;
    final hasSellingPrice = (sellingPricePaise ?? 0) > 0;
    if (hasImage && hasDescription && hasSellingPrice) {
      return 'ready';
    }
    return 'needs_review';
  }

  String? _normalizeStatusFilter(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    if (normalized == 'all') return null;
    if (normalized == 'draft') return 'needs_review';
    if (normalized == 'needs review') return 'needs_review';
    if (normalized == 'needs_review') return 'needs_review';
    if (normalized == 'ready') return 'ready';
    return null;
  }
}
