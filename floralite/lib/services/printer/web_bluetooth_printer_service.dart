import 'dart:async';
import 'dart:typed_data';

import '../../models/printer_device.dart';
import 'printer_service.dart';
import 'web_bluetooth_adapter.dart';
import 'web_bluetooth_adapter_factory.dart';

/// Web Bluetooth thermal printer service using browser BLE GATT APIs.
class WebBluetoothPrinterService implements PrinterService {
  WebBluetoothPrinterService({
    WebBluetoothAdapter? adapter,
    this.chunkSize = defaultChunkSize,
    this.chunkDelay = defaultChunkDelay,
  }) : _adapter = adapter ?? createDefaultWebBluetoothAdapter();

  static const int defaultChunkSize = 100;
  static const Duration defaultChunkDelay = Duration(milliseconds: 15);

  final WebBluetoothAdapter _adapter;
  final int chunkSize;
  final Duration chunkDelay;

  WebBluetoothDevice? _activeDevice;
  bool _isReconnecting = false;

  WebBluetoothAdapter get adapter => _adapter;
  WebBluetoothDevice? get activeDevice => _activeDevice;

  @override
  Future<List<PrinterDevice>> scan() async {
    if (!_adapter.isSupported) {
      throw const PrinterServiceException(
        'Bluetooth is not available in this browser. Please use Chrome or Edge over HTTPS.',
      );
    }

    try {
      final device = await _adapter.requestDevice(
        optionalServices: knownThermalServiceUuids,
      );
      if (device == null) {
        return const [];
      }

      _activeDevice = device;
      _setupDisconnectListener(device);

      return [
        PrinterDevice(
          name: device.name,
          address: device.id,
        ),
      ];
    } catch (e) {
      if (e is PrinterServiceException) rethrow;
      final msg = e.toString().toLowerCase();
      if (msg.contains('user cancelled') || msg.contains('user canceled')) {
        return const [];
      }
      throw PrinterServiceException(_friendlyError(e));
    }
  }

  @override
  Future<bool> connect(PrinterDevice printer) async {
    if (!_adapter.isSupported) {
      throw const PrinterServiceException(
        'Bluetooth is not available in this browser. Please use Chrome or Edge over HTTPS.',
      );
    }

    if (printer.address.trim().isEmpty) {
      throw const PrinterServiceException('Please select a printer first.');
    }

    // Try to find previously held device or match from getDevices()
    if (_activeDevice == null || _activeDevice!.id != printer.address) {
      try {
        final existingDevices = await _adapter.getDevices();
        _activeDevice = existingDevices
            .where((d) => d.id == printer.address)
            .firstOrNull;
      } catch (_) {}
    }

    final dev = _activeDevice;
    if (dev == null) {
      throw const PrinterServiceException(
        'Please select your printer using Search Printers.',
      );
    }

    try {
      await dev.connect();
      final char = await dev.findWritableCharacteristic();
      if (char == null) {
        await dev.disconnect();
        throw const PrinterServiceException(
          'This printer does not expose a compatible BLE printing service.',
        );
      }
      _setupDisconnectListener(dev);
      return true;
    } on PrinterServiceException {
      rethrow;
    } catch (e) {
      throw PrinterServiceException(_friendlyError(e));
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await _activeDevice?.disconnect();
    } catch (_) {}
  }

  @override
  Future<bool> isConnected() async {
    final dev = _activeDevice;
    if (dev == null) return false;
    return dev.isConnected;
  }

  @override
  Future<void> printBytes(Uint8List bytes) async {
    if (bytes.isEmpty) return;

    var dev = _activeDevice;
    if (dev == null || !dev.isConnected) {
      if (dev != null && !_isReconnecting) {
        _isReconnecting = true;
        try {
          await dev.connect();
        } catch (_) {} finally {
          _isReconnecting = false;
        }
      }
    }

    dev = _activeDevice;
    if (dev == null || !dev.isConnected) {
      throw const PrinterServiceException('Printer Not Connected');
    }

    try {
      await dev.writeBytes(
        bytes,
        chunkSize: chunkSize,
        delay: chunkDelay,
      );
    } catch (e) {
      throw PrinterServiceException(_friendlyError(e));
    }
  }

  @override
  Future<void> printReceipt(ReceiptData receipt) {
    throw const PrinterServiceException(
      'Receipt bytes must be built before printing.',
    );
  }

  @override
  Future<void> printLabel(LabelData label) {
    throw const PrinterServiceException(
      'Label bytes must be built before printing.',
    );
  }

  void _setupDisconnectListener(WebBluetoothDevice device) {
    device.onDisconnected(() {
      // Disconnection handled; status will reflect in isConnected()
    });
  }

  String _friendlyError(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('compatible ble') ||
        text.contains('characteristic') ||
        text.contains('service')) {
      return 'This printer does not expose a compatible BLE printing service.';
    }
    if (text.contains('not connected') || text.contains('disconnected')) {
      return 'Printer Not Connected';
    }
    if (text.contains('permission') || text.contains('not allowed')) {
      return 'Bluetooth permission was not granted in browser.';
    }
    if (text.contains('user cancelled') || text.contains('user canceled')) {
      return 'Printer selection cancelled.';
    }
    return error.toString().replaceFirst('Exception: ', '').trim();
  }
}
