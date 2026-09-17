import 'package:flutter/widgets.dart';

/// Stub implementation for non-web platforms (Android, iOS, Desktop, unit tests).
void initWebBarcodeScannerDiagnostics({
  required void Function(String code) onCodeDetected,
  required FocusNode focusNode,
}) {
  // No-op on non-web platforms.
}

void stopWebBarcodeScannerDiagnostics() {
  // No-op on non-web platforms.
}
