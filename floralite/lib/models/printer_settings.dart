import 'printer_device.dart';

enum PrinterPaperWidth { mm58, mm80 }

class PrinterSettings {
  const PrinterSettings({
    required this.connectionKind,
    required this.paperWidth,
    required this.autoConnect,
    required this.autoPrintAfterBilling,
    required this.copies,
    required this.cutPaper,
    required this.printLogo,
    required this.printQrCode,
    required this.printBarcode,
    required this.printDuplicateCopy,
    required this.thankYouMessage,
    this.printerName,
    this.printerAddress,
    this.website,
    this.whatsappNumber,
  });

  final PrinterConnectionKind connectionKind;
  final PrinterPaperWidth paperWidth;
  final String? printerName;
  final String? printerAddress;
  final bool autoConnect;
  final bool autoPrintAfterBilling;
  final int copies;
  final bool cutPaper;
  final bool printLogo;
  final bool printQrCode;
  final bool printBarcode;
  final bool printDuplicateCopy;
  final String thankYouMessage;
  final String? website;
  final String? whatsappNumber;

  bool get hasPrinter =>
      (printerName?.trim().isNotEmpty ?? false) &&
      (printerAddress?.trim().isNotEmpty ?? false);

  PrinterSettings copyWith({
    PrinterConnectionKind? connectionKind,
    PrinterPaperWidth? paperWidth,
    String? printerName,
    String? printerAddress,
    bool clearPrinter = false,
    bool? autoConnect,
    bool? autoPrintAfterBilling,
    int? copies,
    bool? cutPaper,
    bool? printLogo,
    bool? printQrCode,
    bool? printBarcode,
    bool? printDuplicateCopy,
    String? thankYouMessage,
    String? website,
    String? whatsappNumber,
  }) {
    return PrinterSettings(
      connectionKind: connectionKind ?? this.connectionKind,
      paperWidth: paperWidth ?? this.paperWidth,
      printerName: clearPrinter ? null : printerName ?? this.printerName,
      printerAddress:
          clearPrinter ? null : printerAddress ?? this.printerAddress,
      autoConnect: autoConnect ?? this.autoConnect,
      autoPrintAfterBilling:
          autoPrintAfterBilling ?? this.autoPrintAfterBilling,
      copies: copies ?? this.copies,
      cutPaper: cutPaper ?? this.cutPaper,
      printLogo: printLogo ?? this.printLogo,
      printQrCode: printQrCode ?? this.printQrCode,
      printBarcode: printBarcode ?? this.printBarcode,
      printDuplicateCopy: printDuplicateCopy ?? this.printDuplicateCopy,
      thankYouMessage: thankYouMessage ?? this.thankYouMessage,
      website: website ?? this.website,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
    );
  }

  factory PrinterSettings.fromMap(Map<String, dynamic> map) {
    return PrinterSettings(
      connectionKind: PrinterConnectionKind.bluetooth,
      paperWidth: (map['paper_width_mm'] as int? ?? 80) == 58
          ? PrinterPaperWidth.mm58
          : PrinterPaperWidth.mm80,
      printerName: map['printer_name'] as String?,
      printerAddress: map['printer_address'] as String?,
      autoConnect: (map['auto_connect'] as int? ?? 1) == 1,
      autoPrintAfterBilling:
          (map['auto_print_after_billing'] as int? ?? 0) == 1,
      copies: (map['copies'] as int? ?? 1).clamp(1, 5),
      cutPaper: (map['cut_paper'] as int? ?? 1) == 1,
      printLogo: (map['print_logo'] as int? ?? 0) == 1,
      printQrCode: (map['print_qr_code'] as int? ?? 0) == 1,
      printBarcode: (map['print_barcode'] as int? ?? 1) == 1,
      printDuplicateCopy: (map['print_duplicate_copy'] as int? ?? 0) == 1,
      thankYouMessage: map['thank_you_message'] as String? ??
          'Thank you for shopping with us',
      website: map['website'] as String?,
      whatsappNumber: map['whatsapp_number'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': 1,
      'connection_type': connectionKind.name,
      'paper_width_mm': paperWidth == PrinterPaperWidth.mm58 ? 58 : 80,
      'printer_name': printerName,
      'printer_address': printerAddress,
      'auto_connect': autoConnect ? 1 : 0,
      'auto_print_after_billing': autoPrintAfterBilling ? 1 : 0,
      'copies': copies.clamp(1, 5),
      'cut_paper': cutPaper ? 1 : 0,
      'print_logo': printLogo ? 1 : 0,
      'print_qr_code': printQrCode ? 1 : 0,
      'print_barcode': printBarcode ? 1 : 0,
      'print_duplicate_copy': printDuplicateCopy ? 1 : 0,
      'thank_you_message': thankYouMessage,
      'website': website,
      'whatsapp_number': whatsappNumber,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

typedef PrinterConfig = PrinterSettings;
