import 'dart:typed_data';

import '../../models/printer_device.dart';

class ReceiptData {
  const ReceiptData(this.payload);

  final Map<String, dynamic> payload;
}

class LabelData {
  const LabelData(this.payload);

  final Map<String, dynamic> payload;
}

abstract class PrinterService {
  Future<List<PrinterDevice>> scan();

  Future<bool> connect(PrinterDevice printer);

  Future<void> disconnect();

  Future<bool> isConnected();

  Future<void> printReceipt(ReceiptData receipt);

  Future<void> printLabel(LabelData label);

  Future<void> printBytes(Uint8List bytes);
}

class PrinterServiceException implements Exception {
  const PrinterServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
