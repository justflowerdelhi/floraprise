import 'web_receipt_printer_stub.dart'
    if (dart.library.html) 'web_receipt_printer_web.dart' as impl;

/// Prints the given HTML content on web browsers using the browser print dialog.
/// On non-web platforms, this is a safe no-op.
Future<void> printHtmlReceipt(String htmlContent) =>
    impl.printHtmlReceipt(htmlContent);
