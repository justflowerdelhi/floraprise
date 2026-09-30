import 'package:flutter/foundation.dart';
import 'web_notification_service.dart';

bool get isSupported => false;

WebNotificationPermission getPermission() =>
    WebNotificationPermission.unsupported;

Future<bool> requestPermission() async => false;

void showNotification({
  required String title,
  required String body,
  String? tag,
  String? icon,
  VoidCallback? onClick,
}) {}

void playChime() {}
