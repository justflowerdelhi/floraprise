import 'package:flutter/foundation.dart';
import 'web_notification_service_stub.dart'
    if (dart.library.html) 'web_notification_service_web.dart' as impl;

enum WebNotificationPermission {
  granted,
  defaultPermission,
  denied,
  unsupported,
}

/// Cross-platform wrapper for Web browser notifications.
/// On non-web platforms, all methods are safe no-ops.
class WebNotificationService {
  WebNotificationService._();

  static final WebNotificationService instance = WebNotificationService._();

  /// Whether the browser Notification API is available.
  bool get isSupported => kIsWeb && impl.isSupported;

  /// Current notification permission status.
  WebNotificationPermission get permission =>
      kIsWeb ? impl.getPermission() : WebNotificationPermission.unsupported;

  /// Request browser notification permission.
  /// Returns true if permission is granted.
  Future<bool> requestPermission() async {
    if (!kIsWeb) return false;
    return impl.requestPermission();
  }

  /// Displays a browser notification if permission is granted.
  void showNotification({
    required String title,
    required String body,
    String? tag,
    String? icon,
    VoidCallback? onClick,
  }) {
    if (!kIsWeb) return;
    impl.showNotification(
      title: title,
      body: body,
      tag: tag,
      icon: icon,
      onClick: onClick,
    );
  }

  /// Attempts to play a short chime on web if autoplay policy permits.
  void playChime() {
    if (!kIsWeb) return;
    impl.playChime();
  }
}
