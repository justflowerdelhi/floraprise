// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'web_notification_service.dart';

bool get isSupported => html.Notification.supported;

WebNotificationPermission getPermission() {
  if (!html.Notification.supported) {
    return WebNotificationPermission.unsupported;
  }
  switch (html.Notification.permission) {
    case 'granted':
      return WebNotificationPermission.granted;
    case 'denied':
      return WebNotificationPermission.denied;
    case 'default':
    default:
      return WebNotificationPermission.defaultPermission;
  }
}

Future<bool> requestPermission() async {
  if (!html.Notification.supported) return false;
  try {
    final result = await html.Notification.requestPermission();
    return result == 'granted';
  } catch (e) {
    debugPrint('WebNotificationService: Permission request error: $e');
    return false;
  }
}

void showNotification({
  required String title,
  required String body,
  String? tag,
  String? icon,
  VoidCallback? onClick,
}) {
  if (!html.Notification.supported) return;
  if (html.Notification.permission != 'granted') return;

  try {
    final notification = html.Notification(
      title,
      body: body,
      icon: icon ?? 'assets/icon.png',
      tag: tag,
    );

    notification.onClick.listen((_) {
      try {
        js.context.callMethod('focus');
      } catch (_) {}
      onClick?.call();
      notification.close();
    });
  } catch (e) {
    debugPrint('WebNotificationService: Error showing notification: $e');
  }
}

void playChime(
    {String soundAsset = 'assets/sounds/floraprise_task_reminder.wav'}) {
  try {
    // In Flutter Web, assets packaged via pubspec.yaml are located under 'assets/' + assetKey
    final primarySrc = soundAsset.startsWith('assets/')
        ? 'assets/$soundAsset'
        : 'assets/assets/$soundAsset';

    final audio = html.AudioElement()
      ..src = primarySrc
      ..volume = 0.8;

    // Register error handler to attempt fallback to direct relative path if needed
    audio.onError.listen((_) {
      try {
        final fallbackAudio = html.AudioElement()
          ..src = soundAsset
          ..volume = 0.8;
        fallbackAudio.play().catchError((e) {
          debugPrint(
              'WebNotificationService: Fallback audio autoplay prevented: $e');
        });
      } catch (err) {
        debugPrint(
            'WebNotificationService: Fallback audio playback error: $err');
      }
    });

    audio.play().catchError((e) {
      debugPrint('WebNotificationService: Audio autoplay prevented: $e');
    });
  } catch (e) {
    debugPrint('WebNotificationService: Could not play chime: $e');
  }
}

