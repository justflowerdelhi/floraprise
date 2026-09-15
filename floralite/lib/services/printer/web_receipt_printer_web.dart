// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:js' as js;

/// Web implementation for printing HTML receipts via an iframe with popup fallback.
Future<void> printHtmlReceipt(String htmlContent) async {
  try {
    final oldFrame = html.document.getElementById('pos-receipt-print-frame');
    oldFrame?.remove();

    final iframe = html.IFrameElement()
      ..id = 'pos-receipt-print-frame'
      ..style.position = 'fixed'
      ..style.right = '0'
      ..style.bottom = '0'
      ..style.width = '1px'
      ..style.height = '1px'
      ..style.opacity = '0.01'
      ..style.border = '0';

    html.document.body?.append(iframe);

    bool printed = false;
    void triggerPrint() {
      if (printed) return;
      printed = true;
      final win = iframe.contentWindow;
      if (win != null) {
        final jsWin = js.JsObject.fromBrowserObject(win);
        jsWin.callMethod('focus');
        jsWin.callMethod('print');
      }
    }

    final win = iframe.contentWindow;
    if (win != null) {
      try {
        final jsWin = js.JsObject.fromBrowserObject(win);
        final doc = jsWin['document'] as js.JsObject?;
        if (doc != null) {
          doc.callMethod('open');
          doc.callMethod('write', [htmlContent]);
          doc.callMethod('close');
          html.window.animationFrame.then((_) => triggerPrint());
          return;
        }
      } catch (_) {}
    }

    iframe.srcdoc = htmlContent;
    iframe.onLoad.first.then((_) => triggerPrint());
  } catch (_) {
    // Fallback if iframe fails or is blocked: popup window
    try {
      final printWindow = html.window.open('', '_blank');
      final jsWin = js.JsObject.fromBrowserObject(printWindow);
      final doc = jsWin['document'] as js.JsObject?;
      doc?.callMethod('write', [htmlContent]);
      doc?.callMethod('close');
      jsWin.callMethod('focus');
      jsWin.callMethod('print');
    } catch (_) {}
  }
}
