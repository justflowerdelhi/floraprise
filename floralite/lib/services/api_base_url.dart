import 'package:flutter/foundation.dart';

String resolveFlorapriseApiBaseUrl({
  required String explicitValue,
  required bool isDebug,
  required TargetPlatform platform,
  bool isWeb = kIsWeb,
}) {
  final configured = explicitValue.trim();
  if (configured.isNotEmpty) {
    return configured.replaceFirst(RegExp(r'/+$'), '');
  }

  if (isWeb) {
    return 'https://api.floraprise.com';
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

/// Resolves any relative or absolute business logo / media path to a full URL or valid path.
/// - Returns '' if [path] is null, empty, or whitespace.
/// - If [path] is already an absolute URL (http://, https://, blob:) or data URI (data:image) or asset path (assets/), returns trimmed [path].
/// - If [path] is a relative path (e.g., `/uploads/logos/logo.png` or `uploads/logos/logo.png`), prepends the resolved API base URL, ensuring exactly one `/` between host and path.
/// - [explicitBaseUrl] overrides the default API base URL resolution when provided.
String resolveBusinessLogoUrl(
  String? path, {
  String? explicitBaseUrl,
  String explicitApiBaseUrl = '',
  bool isDebug = kDebugMode,
  TargetPlatform? platform,
  bool isWeb = kIsWeb,
}) {
  if (path == null) return '';
  final trimmed = path.trim();
  if (trimmed.isEmpty) return '';

  if (trimmed.startsWith('http://') ||
      trimmed.startsWith('https://') ||
      trimmed.startsWith('blob:') ||
      trimmed.startsWith('data:image') ||
      trimmed.startsWith('assets/')) {
    return trimmed;
  }

  final effectivePlatform = platform ?? (isWeb ? TargetPlatform.android : defaultTargetPlatform);

  // If explicitBaseUrl is given, use it:
  String baseUrl;
  final explicit = explicitBaseUrl?.trim() ?? '';
  if (explicit.isNotEmpty) {
    baseUrl = explicit.replaceFirst(RegExp(r'/+$'), '');
  } else {
    baseUrl = resolveFlorapriseApiBaseUrl(
      explicitValue: explicitApiBaseUrl,
      isDebug: isDebug,
      platform: effectivePlatform,
      isWeb: isWeb,
    );
  }

  // On non-Web, check if this is an absolute local file path (e.g. C:\... or /data/... not starting with /uploads or /api)
  // when NO explicitBaseUrl was provided:
  if (!isWeb && explicit.isEmpty) {
    final isApiPath = trimmed.startsWith('/uploads/') ||
        trimmed.startsWith('uploads/') ||
        trimmed.startsWith('/api/') ||
        trimmed.startsWith('api/');
    if (!isApiPath && (trimmed.contains(r'\') || trimmed.startsWith('/') || RegExp(r'^[a-zA-Z]:').hasMatch(trimmed))) {
      return trimmed;
    }
  }

  final cleanPath = trimmed.replaceFirst(RegExp(r'^/+'), '');
  return '$baseUrl/$cleanPath';
}

