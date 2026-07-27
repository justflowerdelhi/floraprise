import 'dart:async';
import 'dart:typed_data';

import '../../data/repositories/printer_repository.dart';
import '../../models/printer_models.dart';
import 'bluetooth_printer_service.dart';
import 'printer_service.dart';
import 'receipt_builder.dart';

class PrinterManager {
  PrinterManager({
    PrinterRepository? repository,
    ReceiptBuilder? receiptBuilder,
    PrinterService? transport,
  })  : _repository = repository ?? PrinterRepository(),
        _receiptBuilder = receiptBuilder ?? ReceiptBuilder(),
        _transport = transport ?? BluetoothPrinterService();

  final PrinterRepository _repository;
  final ReceiptBuilder _receiptBuilder;
  final PrinterService _transport;

  bool _isConnected = false;

  bool get isConnected => _isConnected;

  Future<PrinterConfig> loadConfig() => _repository.getConfig();

  Future<List<PrinterDeviceInfo>> scanBluetoothPrinters({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    return _transport.scan();
  }

  Future<void> connect(PrinterDeviceInfo device) async {
    try {
      _isConnected = await _transport.connect(device);
      if (_isConnected) {
        await _repository.saveSelectedPrinter(device);
        unawaited(processQueue());
      }
    } catch (error) {
      _isConnected = false;
      throw PrinterServiceException(_friendlyError(error));
    }
  }

  Future<bool> autoConnect() async {
    final config = await _repository.getConfig();
    if (!config.autoConnect || !config.hasPrinter) return false;
    try {
      await connect(
        PrinterDeviceInfo(
          name: config.printerName!,
          address: config.printerAddress!,
        ),
      );
      return _isConnected;
    } catch (_) {
      return false;
    }
  }

  Future<void> disconnect() async {
    await _transport.disconnect();
    _isConnected = false;
  }

  Future<void> saveConfig(PrinterConfig config) =>
      _repository.saveConfig(config);

  Future<void> clearSelectedPrinter() async {
    await disconnect();
    await _repository.clearSelectedPrinter();
  }

  Future<int> enqueue({
    required PrintJobType type,
    required Map<String, dynamic> payload,
    int? copies,
    bool tryPrintNow = true,
  }) async {
    final id =
        await _repository.enqueue(type: type, payload: payload, copies: copies);
    if (tryPrintNow) unawaited(processQueue());
    return id;
  }

  Future<void> printTestPage() async {
    await enqueue(
        type: PrintJobType.testPage, payload: const {}, tryPrintNow: true);
  }

  Future<bool> hasLastSuccessfulReceipt() async {
    return await _repository.getLastSuccessfulReceipt() != null;
  }

  Future<bool> reprintLastReceipt() async {
    final lastReceipt = await _repository.getLastSuccessfulReceipt();
    if (lastReceipt == null) return false;
    await enqueue(
      type: lastReceipt.type,
      payload: lastReceipt.payload,
      copies: 1,
      tryPrintNow: true,
    );
    return true;
  }

  Future<void> printBytes(Uint8List bytes) => _transport.printBytes(bytes);

  Future<List<PrintQueueJob>> listQueue() => _repository.listQueue();

  Future<void> retryJob(int id) async {
    await _repository.retry(id);
    await processQueue();
  }

  Future<void> cancelJob(int id) => _repository.cancel(id);

  Future<void> processQueue() async {
    _isConnected = await _transport.isConnected();
    if (!_isConnected) {
      final connected = await autoConnect();
      if (!connected) return;
    }

    final config = await _repository.getConfig();
    final jobs = await _repository.listQueue(statuses: const {
      PrintJobStatus.pending,
      PrintJobStatus.failed,
    });

    for (final job in jobs) {
      await _repository.markPrinting(job.id);
      try {
        final bytes = await _receiptBuilder.build(
          type: job.type,
          payload: job.payload,
          settings: config,
        );
        for (var copy = 0; copy < job.copies; copy++) {
          await _transport.printBytes(bytes);
        }
        await _repository.markPrinted(job.id);
      } catch (error) {
        await _repository.markFailed(job.id, _friendlyError(error));
        rethrow;
      }
    }
  }

  String _friendlyError(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('bluetooth') && text.contains('permission')) {
      return 'Bluetooth permission was not granted.';
    }
    if (text.contains('bluetooth') && text.contains('off')) {
      return 'Bluetooth is turned off. Please enable Bluetooth and try again.';
    }
    if (text.contains('not connected') || text.contains('connection')) {
      return 'Printer Not Connected';
    }
    if (text.contains('paper')) {
      return 'Printer may be out of paper.';
    }
    if (text.contains('cancel')) {
      return 'Print cancelled.';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }
}
