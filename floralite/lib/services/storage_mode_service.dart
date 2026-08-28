import 'package:sqflite/sqflite.dart';

import '../data/database/app_database.dart';
import '../models/storage_mode.dart';

class StorageModeService {
  static const String _storageModeKey = 'storage.mode';

  Future<StorageMode?> getCurrentMode() async {
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

  Future<bool> hasSelectedMode() async => getCurrentMode().then(
        (mode) => mode != null,
      );

  Future<bool> isLocal() async => getCurrentMode().then(
        (mode) => mode == null || mode == StorageMode.local,
      );

  Future<bool> isCloud() async => getCurrentMode().then(
        (mode) => mode == StorageMode.cloud,
      );
}