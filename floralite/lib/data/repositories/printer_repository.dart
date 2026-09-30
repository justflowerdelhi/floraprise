import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/printer_models.dart';
import '../database/app_database.dart';

class PrinterRepository {
  PrinterRepository({
    SharedPreferences? prefs,
    bool? isWeb,
  })  : _prefs = prefs,
        _isWeb = isWeb ?? kIsWeb;

  final bool _isWeb;
  SharedPreferences? _prefs;
  static const String _webConfigKey = 'floraprise_printer_config_v1';
  static const String _webLastReceiptKey = 'floraprise_last_receipt_v1';

  static PrinterConfig _webConfig = const PrinterConfig(
    connectionKind: PrinterConnectionKind.bluetooth,
    paperWidth: PrinterPaperWidth.mm80,
    autoConnect: false,
    autoPrintAfterBilling: false,
    copies: 1,
    cutPaper: true,
    printLogo: false,
    printQrCode: false,
    printBarcode: true,
    printDuplicateCopy: false,
    thankYouMessage: 'Thank you for shopping with us',
  );

  final List<PrintQueueJob> _webQueue = [];
  int _webNextJobId = 1;
  PrintQueueJob? _webLastSuccessfulReceipt;

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<PrinterConfig> getConfig() async {
    if (_isWeb) {
      try {
        final prefs = await _getPrefs();
        final jsonStr = prefs.getString(_webConfigKey);
        if (jsonStr != null && jsonStr.trim().isNotEmpty) {
          final decoded = jsonDecode(jsonStr);
          if (decoded is Map<String, dynamic>) {
            _webConfig = PrinterConfig.fromMap(decoded);
            return _webConfig;
          }
        }
      } catch (_) {}
      return _webConfig;
    }

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
    if (_isWeb) {
      _webConfig = config;
      try {
        final prefs = await _getPrefs();
        await prefs.setString(_webConfigKey, jsonEncode(config.toMap()));
      } catch (_) {}
      return;
    }

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
    final now = DateTime.now().toIso8601String();
    final config = await getConfig();

    if (_isWeb) {
      final id = _webNextJobId++;
      final job = PrintQueueJob(
        id: id,
        type: type,
        payload: payload,
        status: PrintJobStatus.pending,
        copies: (copies ?? config.copies).clamp(1, 5),
        retryCount: 0,
        createdAt: now,
        updatedAt: now,
      );
      _webQueue.add(job);
      return id;
    }

    final db = await AppDatabase.instance.database;
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
    if (_isWeb) {
      return _webQueue
          .where((job) => statuses.contains(job.status))
          .take(limit)
          .toList();
    }

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
    if (_isWeb) {
      if (_webLastSuccessfulReceipt != null) {
        return _webLastSuccessfulReceipt;
      }
      try {
        final prefs = await _getPrefs();
        final jsonStr = prefs.getString(_webLastReceiptKey);
        if (jsonStr != null && jsonStr.trim().isNotEmpty) {
          final decoded = jsonDecode(jsonStr);
          if (decoded is Map<String, dynamic>) {
            _webLastSuccessfulReceipt = PrintQueueJob.fromMap(decoded);
            return _webLastSuccessfulReceipt;
          }
        }
      } catch (_) {}
      return null;
    }

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

  Future<void> markPrinted(int id) async {
    final now = DateTime.now().toIso8601String();
    if (_isWeb) {
      final index = _webQueue.indexWhere((j) => j.id == id);
      if (index >= 0) {
        final old = _webQueue[index];
        final updated = PrintQueueJob(
          id: old.id,
          type: old.type,
          payload: old.payload,
          status: PrintJobStatus.printed,
          copies: old.copies,
          retryCount: old.retryCount,
          lastError: null,
          createdAt: old.createdAt,
          updatedAt: now,
          printedAt: now,
        );
        _webQueue[index] = updated;
        if (updated.type == PrintJobType.posBill) {
          _webLastSuccessfulReceipt = updated;
          try {
            final prefs = await _getPrefs();
            await prefs.setString(
                _webLastReceiptKey, jsonEncode(updated.toMap()));
          } catch (_) {}
        }
      }
      return;
    }
    await _updateStatus(
      id,
      PrintJobStatus.printed,
      printedAt: now,
    );
  }

  Future<void> markFailed(int id, Object error) async {
    final now = DateTime.now().toIso8601String();
    if (_isWeb) {
      final index = _webQueue.indexWhere((j) => j.id == id);
      if (index >= 0) {
        final old = _webQueue[index];
        _webQueue[index] = PrintQueueJob(
          id: old.id,
          type: old.type,
          payload: old.payload,
          status: PrintJobStatus.failed,
          copies: old.copies,
          retryCount: old.retryCount + 1,
          lastError: error.toString(),
          createdAt: old.createdAt,
          updatedAt: now,
          printedAt: old.printedAt,
        );
      }
      return;
    }

    final db = await AppDatabase.instance.database;
    await db.rawUpdate('''
      UPDATE print_queue
      SET status = ?, retry_count = retry_count + 1, last_error = ?, updated_at = ?
      WHERE id = ?
    ''', [
      PrintJobStatus.failed.name,
      error.toString(),
      now,
      id,
    ]);
  }

  Future<void> cancel(int id) async {
    if (_isWeb) {
      final index = _webQueue.indexWhere((j) => j.id == id);
      if (index >= 0) {
        final old = _webQueue[index];
        _webQueue[index] = PrintQueueJob(
          id: old.id,
          type: old.type,
          payload: old.payload,
          status: PrintJobStatus.cancelled,
          copies: old.copies,
          retryCount: old.retryCount,
          lastError: old.lastError,
          createdAt: old.createdAt,
          updatedAt: DateTime.now().toIso8601String(),
          printedAt: old.printedAt,
        );
      }
      return;
    }
    await _updateStatus(id, PrintJobStatus.cancelled);
  }

  Future<void> retry(int id) async {
    if (_isWeb) {
      final index = _webQueue.indexWhere((j) => j.id == id);
      if (index >= 0) {
        final old = _webQueue[index];
        _webQueue[index] = PrintQueueJob(
          id: old.id,
          type: old.type,
          payload: old.payload,
          status: PrintJobStatus.pending,
          copies: old.copies,
          retryCount: old.retryCount,
          lastError: null,
          createdAt: old.createdAt,
          updatedAt: DateTime.now().toIso8601String(),
          printedAt: old.printedAt,
        );
      }
      return;
    }
    await _updateStatus(
      id,
      PrintJobStatus.pending,
      clearError: true,
    );
  }

  Future<void> _updateStatus(
    int id,
    PrintJobStatus status, {
    String? printedAt,
    bool clearError = false,
  }) async {
    if (kIsWeb) return;
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
    if (kIsWeb) return;
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
