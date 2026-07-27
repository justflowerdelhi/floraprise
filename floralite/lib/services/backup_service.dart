import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../data/database/app_database.dart';

class BackupService {
  Future<String> createManualBackup() async {
    await AppDatabase.instance.close();
    final dbPath = p.join(await getDatabasesPath(), 'floraprise.db');
    final source = File(dbPath);
    if (!source.existsSync()) {
      throw StateError('Floraprise database was not found on this device.');
    }

    final directory = await getApplicationDocumentsDirectory();
    final backupDirectory =
        Directory(p.join(directory.path, 'floraprise_backups'));
    if (!backupDirectory.existsSync()) {
      backupDirectory.createSync(recursive: true);
    }

    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('.', '');
    final backupPath = p.join(
      backupDirectory.path,
      'floraprise_backup_$timestamp.db',
    );
    await source.copy(backupPath);
    return backupPath;
  }

  Future<bool> restoreManualBackup() async {
    const typeGroup = XTypeGroup(
      label: 'Floraprise backup',
      extensions: ['db'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return false;

    await AppDatabase.instance.close();
    final dbPath = p.join(await getDatabasesPath(), 'floraprise.db');
    await File(file.path).copy(dbPath);
    return true;
  }
}
