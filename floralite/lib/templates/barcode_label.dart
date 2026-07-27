import 'dart:typed_data';

import '../models/printer_models.dart';
import '../services/printer/receipt_builder.dart';

class BarcodeLabelTemplate {
  const BarcodeLabelTemplate(this._builder);

  final ReceiptBuilder _builder;

  Future<Uint8List> build(
      Map<String, dynamic> payload, PrinterConfig settings) {
    return _builder.build(
      type: PrintJobType.bouquetBarcodeLabel,
      payload: payload,
      settings: settings,
    );
  }
}
