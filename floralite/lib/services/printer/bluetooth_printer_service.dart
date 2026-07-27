import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../../models/printer_device.dart';
import 'printer_service.dart';

class BluetoothPrinterService implements PrinterService {
  BluetoothPrinterService({MethodChannel? channel})
      : _channel =
            channel ?? const MethodChannel('floraprise/printer_bluetooth');

  final MethodChannel _channel;

  @override
  Future<List<PrinterDevice>> scan() async {
    _ensureAndroid();
    try {
      final devices =
          await _channel.invokeListMethod<Object?>('scan') ?? const [];
      return devices
          .whereType<Map<Object?, Object?>>()
          .map(PrinterDevice.fromMap)
          .where((device) => device.address.isNotEmpty)
          .toList();
    } on PlatformException catch (error) {
      throw PrinterServiceException(_friendlyError(error));
    }
  }

  @override
  Future<bool> connect(PrinterDevice printer) async {
    _ensureAndroid();
    try {
      final connected = await _channel.invokeMethod<bool>('connect', {
        'name': printer.name,
        'address': printer.address,
      }).timeout(const Duration(seconds: 18));
      return connected ?? false;
    } on PlatformException catch (error) {
      throw PrinterServiceException(_friendlyError(error));
    } on TimeoutException {
      throw const PrinterServiceException(
          'Printer connection timed out. Keep the printer nearby and try again.');
    }
  }

  @override
  Future<void> disconnect() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('disconnect');
    } on PlatformException catch (error) {
      throw PrinterServiceException(_friendlyError(error));
    }
  }

  @override
  Future<bool> isConnected() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('isConnected') ?? false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<void> printBytes(Uint8List bytes) async {
    _ensureAndroid();
    try {
      await _channel.invokeMethod<void>('printBytes', bytes);
    } on PlatformException catch (error) {
      throw PrinterServiceException(_friendlyError(error));
    }
  }

  @override
  Future<void> printReceipt(ReceiptData receipt) {
    throw const PrinterServiceException(
        'Receipt bytes must be built before printing.');
  }

  @override
  Future<void> printLabel(LabelData label) {
    throw const PrinterServiceException(
        'Label bytes must be built before printing.');
  }

  void _ensureAndroid() {
    if (!Platform.isAndroid) {
      throw const PrinterServiceException(
          'Bluetooth printing is currently available on Android only.');
    }
  }

  String _friendlyError(PlatformException error) {
    final text = '${error.code} ${error.message}'.toLowerCase();
    if (text.contains('permission')) {
      return 'Bluetooth permission was not granted.';
    }
    if (text.contains('disabled')) {
      return 'Bluetooth is turned off. Please enable Bluetooth and try again.';
    }
    if (text.contains('not_found')) {
      return 'Printer unavailable. Please pair the printer in Android Bluetooth settings.';
    }
    if (text.contains('not_connected') || text.contains('connection')) {
      return 'Connection lost. Keep the printer nearby and try again.';
    }
    if (text.contains('paper')) {
      return 'Printer may be out of paper.';
    }
    if (text.contains('cancel')) {
      return 'Print cancelled.';
    }
    return 'Printing failed. Please check the printer and try again.';
  }
}
