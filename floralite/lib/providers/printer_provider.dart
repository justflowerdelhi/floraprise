import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/printer_models.dart';
import '../services/printer/printer_manager.dart';

class PrinterProvider extends ChangeNotifier {
  PrinterProvider(this._printerManager);

  final PrinterManager _printerManager;

  PrinterConfig? _config;
  List<PrinterDeviceInfo> _discoveredPrinters = const [];
  List<PrintQueueJob> _queue = const [];
  bool _isLoading = false;
  bool _isScanning = false;
  bool _isPrinting = false;
  bool _hasLastReceipt = false;
  String? _connectingAddress;
  String? _error;

  PrinterConfig? get config => _config;
  List<PrinterDeviceInfo> get discoveredPrinters => _discoveredPrinters;
  List<PrintQueueJob> get queue => _queue;
  bool get isLoading => _isLoading;
  bool get isScanning => _isScanning;
  bool get isPrinting => _isPrinting;
  bool get hasLastReceipt => _hasLastReceipt;
  String? get connectingAddress => _connectingAddress;
  bool get isConnected => _printerManager.isConnected;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _config = await _printerManager.loadConfig();
      _queue = await _printerManager.listQueue();
      _hasLastReceipt = await _printerManager.hasLastSuccessfulReceipt();
      if (_config?.autoConnect == true) {
        await _printerManager.autoConnect();
      }
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> scanBluetoothPrinters() async {
    _isScanning = true;
    _error = null;
    notifyListeners();
    try {
      await _ensureBluetoothPermission();
      _discoveredPrinters = await _printerManager.scanBluetoothPrinters();
    } catch (error) {
      _error = error.toString();
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> connect(PrinterDeviceInfo device) async {
    _isLoading = true;
    _connectingAddress = device.address;
    _error = null;
    notifyListeners();
    try {
      await _ensureBluetoothPermission();
      await _printerManager.connect(device);
      _config = await _printerManager.loadConfig();
      _queue = await _printerManager.listQueue();
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      _connectingAddress = null;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _printerManager.disconnect();
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearPrinter() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _printerManager.clearSelectedPrinter();
      _config = await _printerManager.loadConfig();
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveConfig(PrinterConfig config) async {
    _config = config;
    notifyListeners();
    try {
      await _printerManager.saveConfig(config);
    } catch (error) {
      _error = error.toString();
      notifyListeners();
    }
  }

  Future<void> printTestPage() async {
    _isPrinting = true;
    _error = null;
    notifyListeners();
    try {
      await _ensureBluetoothPermission();
      await _printerManager.printTestPage();
      await _printerManager.processQueue();
      _queue = await _printerManager.listQueue();
      _hasLastReceipt = await _printerManager.hasLastSuccessfulReceipt();
    } catch (error) {
      _error = error.toString();
      _queue = await _printerManager.listQueue();
      _hasLastReceipt = await _printerManager.hasLastSuccessfulReceipt();
    } finally {
      _isPrinting = false;
      notifyListeners();
    }
  }

  Future<void> reprintLastReceipt() async {
    _isPrinting = true;
    _error = null;
    notifyListeners();
    try {
      await _ensureBluetoothPermission();
      final queued = await _printerManager.reprintLastReceipt();
      if (!queued) {
        _error = 'No successful receipt has been printed yet.';
      }
      await _printerManager.processQueue();
      _queue = await _printerManager.listQueue();
      _hasLastReceipt = await _printerManager.hasLastSuccessfulReceipt();
    } catch (error) {
      _error = error.toString();
      _queue = await _printerManager.listQueue();
      _hasLastReceipt = await _printerManager.hasLastSuccessfulReceipt();
    } finally {
      _isPrinting = false;
      notifyListeners();
    }
  }

  Future<void> enqueueBarcodeLabel({
    required String productName,
    required String barcode,
    int quantity = 1,
    int? sellingPricePaise,
  }) async {
    _error = null;
    try {
      await _ensureBluetoothPermission();
      await _printerManager.enqueue(
        type: PrintJobType.bouquetBarcodeLabel,
        payload: {
          'productName': productName,
          'barcode': barcode,
          'quantity': quantity,
          if (sellingPricePaise != null) 'sellingPricePaise': sellingPricePaise,
        },
        tryPrintNow: true,
      );
      _queue = await _printerManager.listQueue();
    } catch (error) {
      _error = error.toString();
      _queue = await _printerManager.listQueue();
    } finally {
      notifyListeners();
    }
  }

  Future<void> enqueuePosBill(Map<String, dynamic> payload) async {
    _error = null;
    try {
      await _ensureBluetoothPermission();
      await _printerManager.enqueue(
        type: PrintJobType.posBill,
        payload: payload,
        tryPrintNow: true,
      );
      _queue = await _printerManager.listQueue();
      _hasLastReceipt = await _printerManager.hasLastSuccessfulReceipt();
    } catch (error) {
      _error = error.toString();
      _queue = await _printerManager.listQueue();
      _hasLastReceipt = await _printerManager.hasLastSuccessfulReceipt();
    } finally {
      notifyListeners();
    }
  }

  Future<void> enqueueDeliverySlip(Map<String, dynamic> payload) async {
    _error = null;
    try {
      await _ensureBluetoothPermission();
      await _printerManager.enqueue(
        type: PrintJobType.deliverySlip,
        payload: payload,
        tryPrintNow: true,
      );
      _queue = await _printerManager.listQueue();
    } catch (error) {
      _error = error.toString();
      _queue = await _printerManager.listQueue();
    } finally {
      notifyListeners();
    }
  }

  Future<void> retryJob(int id) async {
    _isPrinting = true;
    _error = null;
    notifyListeners();
    try {
      await _printerManager.retryJob(id);
      _queue = await _printerManager.listQueue();
    } catch (error) {
      _error = error.toString();
      _queue = await _printerManager.listQueue();
    } finally {
      _isPrinting = false;
      notifyListeners();
    }
  }

  Future<void> cancelJob(int id) async {
    await _printerManager.cancelJob(id);
    _queue = await _printerManager.listQueue();
    notifyListeners();
  }

  Future<void> _ensureBluetoothPermission() async {
    if (!Platform.isAndroid) return;
    final scan = await Permission.bluetoothScan.request();
    final connect = await Permission.bluetoothConnect.request();
    if (!scan.isGranted || !connect.isGranted) {
      throw Exception('Bluetooth permission was not granted.');
    }
  }
}
