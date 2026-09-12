import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../data/database/app_database.dart';
import '../models/storage_mode.dart';

class StorageModeService {
  static const String _storageModeKey = 'storage.mode';

  Future<StorageMode?> getCurrentMode() async {
    if (kIsWeb) return StorageMode.cloud;
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [_storageModeKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return StorageMode.tryParse(rows.first['value'] as String?);
  }

  Future<void> setMode(StorageMode mode) async {
    if (kIsWeb) return;
    final db = await AppDatabase.instance.database;
    await db.insert(
      'settings',
      {
        'key': _storageModeKey,
        'value': mode.storageValue,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> hasSelectedMode() async {
    if (kIsWeb) return true;
    return (await getCurrentMode()) != null;
  }

  Future<bool> isLocal() async {
    if (kIsWeb) return false;
    final mode = await getCurrentMode();
    return mode == null || mode == StorageMode.local;
  }

  Future<bool> isCloud() async {
    if (kIsWeb) return true;
    final mode = await getCurrentMode();
    return mode == StorageMode.cloud;
  }
}