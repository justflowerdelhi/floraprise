import 'package:flutter/foundation.dart';

import 'bluetooth_printer_service.dart';
import 'printer_service.dart';
import 'web_bluetooth_printer_service.dart';

/// Platform transport factory that instantiates the appropriate [PrinterService]
/// for the current runtime platform.
class PrinterTransportFactory {
  const PrinterTransportFactory._();

  /// Returns [WebBluetoothPrinterService] on Flutter Web, and [BluetoothPrinterService]
  /// on native platforms (Android).
  static PrinterService createDefault() {
    if (kIsWeb) {
      return WebBluetoothPrinterService();
    }
    return BluetoothPrinterService();
  }
}
