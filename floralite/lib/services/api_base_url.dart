import 'package:flutter/foundation.dart';

String resolveFlorapriseApiBaseUrl({
  required String explicitValue,
  required bool isDebug,
  required TargetPlatform platform,
}) {
  final configured = explicitValue.trim();
  if (configured.isNotEmpty) {
    return configured.replaceFirst(RegExp(r'/+$'), '');
  }

  if (isDebug) {
    switch (platform) {
      case TargetPlatform.android:
        return 'https://api.floraprise.com';
      case TargetPlatform.iOS:
        return 'http://localhost:5148';
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
        return 'http://localhost:5148';
      case TargetPlatform.fuchsia:
        return 'http://localhost:5148';
    }
  }

  return 'https://api.floraprise.com';
}
