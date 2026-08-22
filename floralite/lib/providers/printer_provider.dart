import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/printer_models.dart';
import '../services/first_use_permission_service.dart';
import '../services/printer/printer_manager.dart';
import '../services/printer/printer_service.dart';

class PrinterProvider extends ChangeNotifier {
  PrinterProvider(
    this._printerManager, {
    BuildContext? Function()? contextProvider,
  }) : _contextProvider = contextProvider;

  final PrinterManager _printerManager;
  final BuildContext? Function()? _contextProvider;

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
      final isConnected = await _printerManager.refreshConnectionState();
      if (!isConnected && _config?.autoConnect == true) {
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
      if (_discoveredPrinters.isEmpty) {
        _error =
            'No Bluetooth printers found. Make sure the printer is switched on and nearby.';
      }
    } catch (error) {
      final isConnected = await _printerManager.refreshConnectionState();
      _error =
          isConnected ? null : _friendlyPrinterError(error, operation: 'scan');
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
      if (device.address.trim().isEmpty) {
        throw const PrinterServiceException('Please select a printer first.');
      }
      await _ensureBluetoothPermission();
      await _printerManager.connect(device);
      _config = await _printerManager.loadConfig();
      _queue = await _printerManager.listQueue();
    } catch (error) {
      _error = _friendlyPrinterError(error, operation: 'connect');
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
      if (_config?.hasPrinter != true) {
        throw const PrinterServiceException('Please select a printer first.');
      }
      await _ensureBluetoothPermission();
      await _printerManager.printTestPage();
      await _printerManager.processQueue();
      _queue = await _printerManager.listQueue();
      _hasLastReceipt = await _printerManager.hasLastSuccessfulReceipt();
    } catch (error) {
      _error = _friendlyPrinterError(error, operation: 'print');
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
    final permissionContext = _contextProvider?.call();
    if (permissionContext != null && permissionContext.mounted) {
      final proceed = await FirstUsePermissionService.ensureExplainedOnce(
        context: permissionContext,
        flowKey: 'bluetooth.printer',
        title: 'Bluetooth is required to print bills.',
        body: 'Floraprise uses Bluetooth only to connect your printer.',
      );
      if (!proceed) {
        throw Exception('Bluetooth permission was not granted.');
      }
    }

    final scan = await Permission.bluetoothScan.request();
    final connect = await Permission.bluetoothConnect.request();
    if (!scan.isGranted || !connect.isGranted) {
      if ((scan.isPermanentlyDenied ||
              scan.isRestricted ||
              connect.isPermanentlyDenied ||
              connect.isRestricted) &&
          permissionContext != null &&
          permissionContext.mounted) {
        await FirstUsePermissionService.showPermanentlyDeniedMessage(
          permissionContext,
          'Bluetooth permission is disabled. You can enable it anytime from Settings > Apps > Floraprise > Permissions to print bills.',
        );
      }
      throw Exception('Bluetooth permission was not granted.');
    }
  }

  String _friendlyPrinterError(Object error, {required String operation}) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    final normalized = message.toLowerCase();
    if (normalized.contains('null check operator') ||
        normalized.contains('not initialized')) {
      return 'Bluetooth is unavailable. Please turn on Bluetooth and try again.';
    }
    if (normalized.contains('permission')) {
      return 'Bluetooth permission is required. Allow Nearby devices permission in Android Settings and try again.';
    }
    if (normalized.contains('disabled') ||
        normalized.contains('turned off') ||
        normalized.contains('unavailable')) {
      return 'Bluetooth is unavailable. Please turn on Bluetooth and try again.';
    }
    if (message.isNotEmpty) return message;
    return operation == 'scan'
        ? 'Bluetooth is unavailable. Please turn on Bluetooth and try again.'
        : 'Could not $operation with the printer. Please try again.';
  }
}
