import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../models/printer_models.dart';
import '../database/app_database.dart';

class PrinterRepository {
  Future<PrinterConfig> getConfig() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'printer_config',
      where: 'id = 1',
      limit: 1,
    );
    if (rows.isEmpty) {
      await _insertDefaultConfig();
      return getConfig();
    }
    return PrinterConfig.fromMap(rows.first);
  }

  Future<void> saveConfig(PrinterConfig config) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'printer_config',
      config.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveSelectedPrinter(PrinterDeviceInfo device) async {
    final config = await getConfig();
    await saveConfig(
      config.copyWith(
        connectionKind: device.connectionKind,
        printerName: device.name,
        printerAddress: device.address,
      ),
    );
  }

  Future<void> clearSelectedPrinter() async {
    final config = await getConfig();
    await saveConfig(config.copyWith(clearPrinter: true));
  }

  Future<int> enqueue({
    required PrintJobType type,
    required Map<String, dynamic> payload,
    int? copies,
  }) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final config = await getConfig();
    return db.insert('print_queue', {
      'job_type': type.name,
      'payload_json': jsonEncode(payload),
      'status': PrintJobStatus.pending.name,
      'copies': (copies ?? config.copies).clamp(1, 5),
      'retry_count': 0,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<List<PrintQueueJob>> listQueue({
    Set<PrintJobStatus> statuses = const {
      PrintJobStatus.pending,
      PrintJobStatus.failed,
    },
    int limit = 50,
  }) async {
    final db = await AppDatabase.instance.database;
    final statusArgs = statuses.map((status) => status.name).toList();
    final rows = await db.query(
      'print_queue',
      where: 'status IN (${List.filled(statusArgs.length, '?').join(',')})',
      whereArgs: statusArgs,
      orderBy: 'created_at ASC',
      limit: limit,
    );
    return rows.map(PrintQueueJob.fromMap).toList();
  }

  Future<PrintQueueJob?> getLastSuccessfulReceipt() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'print_queue',
      where: 'job_type = ? AND status = ?',
      whereArgs: [PrintJobType.posBill.name, PrintJobStatus.printed.name],
      orderBy: 'printed_at DESC, updated_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return PrintQueueJob.fromMap(rows.first);
  }

  Future<void> markPrinting(int id) => _updateStatus(
        id,
        PrintJobStatus.printing,
      );

  Future<void> markPrinted(int id) => _updateStatus(
        id,
        PrintJobStatus.printed,
        printedAt: DateTime.now().toIso8601String(),
      );

  Future<void> markFailed(int id, Object error) async {
    final db = await AppDatabase.instance.database;
    await db.rawUpdate('''
      UPDATE print_queue
      SET status = ?, retry_count = retry_count + 1, last_error = ?, updated_at = ?
      WHERE id = ?
    ''', [
      PrintJobStatus.failed.name,
      error.toString(),
      DateTime.now().toIso8601String(),
      id,
    ]);
  }

  Future<void> cancel(int id) => _updateStatus(id, PrintJobStatus.cancelled);

  Future<void> retry(int id) => _updateStatus(
        id,
        PrintJobStatus.pending,
        clearError: true,
      );

  Future<void> _updateStatus(
    int id,
    PrintJobStatus status, {
    String? printedAt,
    bool clearError = false,
  }) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'print_queue',
      {
        'status': status.name,
        'updated_at': DateTime.now().toIso8601String(),
        if (printedAt != null) 'printed_at': printedAt,
        if (clearError) 'last_error': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> _insertDefaultConfig() async {
    final db = await AppDatabase.instance.database;
    await db.insert('printer_config', {
      'id': 1,
      'connection_type': PrinterConnectionKind.bluetooth.name,
      'paper_width_mm': 80,
      'auto_connect': 1,
      'auto_print_after_billing': 0,
      'copies': 1,
      'cut_paper': 1,
      'print_logo': 0,
      'print_qr_code': 0,
      'print_barcode': 1,
      'print_duplicate_copy': 0,
      'thank_you_message': 'Thank you for shopping with us',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
