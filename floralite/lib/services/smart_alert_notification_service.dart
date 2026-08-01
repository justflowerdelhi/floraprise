import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/smart_alert.dart';

class SmartAlertNotificationService {
  SmartAlertNotificationService._({
    FlutterLocalNotificationsPlugin? notifications,
  }) : _notifications = notifications ?? FlutterLocalNotificationsPlugin();

  static final SmartAlertNotificationService instance = SmartAlertNotificationService._();

  final FlutterLocalNotificationsPlugin _notifications;
  bool _initialized = false;

  FlutterLocalNotificationsPlugin get notifications => _notifications;

  Future<void> initialize() async {
    if (_initialized) return;

    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (android == null) {
      debugPrint('SmartAlert: Android platform not available');
      return;
    }

    // Request necessary permissions
    await android.requestNotificationsPermission();
    await android.requestExactAlarmsPermission();
    await android.requestFullScreenIntentPermission();

    // Create Floraprise Info Channel
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        'floraprise_info',
        'Floraprise Info',
        description: 'Silent notifications for informational alerts',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
        showBadge: false,
      ),
    );

    // Create Floraprise Reminder Channel
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        'floraprise_reminder',
        'Floraprise Reminder',
        description: 'Standard reminders with default sound',
        importance: Importance.defaultImportance,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );

    // Create Floraprise Important Channel
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        'floraprise_important',
        'Floraprise Important',
        description: 'High priority notifications with custom sound',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    // Create Floraprise Critical Channel
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        'floraprise_critical',
        'Floraprise Critical',
        description: 'Critical alarm-style notifications with full screen intent',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );

    _initialized = true;
    debugPrint('SmartAlert: Notification channels initialized');
  }

  String getChannelId(AlertLevel level) {
    switch (level) {
      case AlertLevel.info:
        return 'floraprise_info';
      case AlertLevel.reminder:
        return 'floraprise_reminder';
      case AlertLevel.important:
        return 'floraprise_important';
      case AlertLevel.critical:
        return 'floraprise_critical';
    }
  }

  AndroidNotificationDetails getAndroidDetails(
    AlertLevel level,
    AlertCustomizationSettings settings,
  ) {
    final channelId = getChannelId(level);
    
    switch (level) {
      case AlertLevel.info:
        return AndroidNotificationDetails(
          channelId,
          'Floraprise Info',
          channelDescription: 'Silent notifications for informational alerts',
          importance: Importance.low,
          priority: Priority.low,
          playSound: false,
          enableVibration: false,
          autoCancel: true,
        );
      
      case AlertLevel.reminder:
        return AndroidNotificationDetails(
          channelId,
          'Floraprise Reminder',
          channelDescription: 'Standard reminders with default sound',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: settings.vibrationEnabled,
          enableVibration: settings.vibrationEnabled,
          autoCancel: true,
          sound: settings.notificationSound != 'default' 
              ? RawResourceAndroidNotificationSound(settings.notificationSound)
              : null,
        );
      
      case AlertLevel.important:
        return AndroidNotificationDetails(
          channelId,
          'Floraprise Important',
          channelDescription: 'High priority notifications with custom sound',
          importance: Importance.high,
          priority: Priority.high,
          playSound: settings.vibrationEnabled,
          enableVibration: settings.vibrationEnabled,
          autoCancel: false,
          ongoing: true,
          sound: settings.notificationSound != 'default'
              ? RawResourceAndroidNotificationSound(settings.notificationSound)
              : null,
          vibrationPattern: settings.vibrationEnabled 
              ? Int64List.fromList([0, 1000]) 
              : Int64List.fromList([0]),
          ledColor: const Color(0xFFFF5722),
          ledOnMs: 500,
          ledOffMs: 500,
        );
      
      case AlertLevel.critical:
        return AndroidNotificationDetails(
          channelId,
          'Floraprise Critical',
          channelDescription: 'Critical alarm-style notifications with full screen intent',
          importance: Importance.max,
          priority: Priority.max,
          playSound: settings.vibrationEnabled,
          enableVibration: settings.vibrationEnabled,
          autoCancel: false,
          ongoing: true,
          visibility: NotificationVisibility.public,
          sound: settings.alarmSound != 'alarm'
              ? RawResourceAndroidNotificationSound(settings.alarmSound)
              : null,
          vibrationPattern: settings.vibrationEnabled
              ? Int64List.fromList([0, 500, 200, 500, 200, 500])
              : Int64List.fromList([0]),
          ledColor: const Color(0xFFD32F2F),
          ledOnMs: 300,
          ledOffMs: 300,
          ticker: 'Critical task requires attention',
        );
    }
  }

  DarwinNotificationDetails getDarwinDetails(AlertLevel level) {
    switch (level) {
      case AlertLevel.info:
        return const DarwinNotificationDetails(
          presentAlert: false,
          presentBadge: false,
          presentSound: false,
          interruptionLevel: InterruptionLevel.passive,
        );
      
      case AlertLevel.reminder:
        return const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.active,
        );
      
      case AlertLevel.important:
        return const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        );
      
      case AlertLevel.critical:
        return const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.critical,
        );
    }
  }

  NotificationDetails getNotificationDetails(
    AlertLevel level,
    AlertCustomizationSettings settings,
  ) {
    return NotificationDetails(
      android: getAndroidDetails(level, settings),
      iOS: getDarwinDetails(level),
      macOS: getDarwinDetails(level),
    );
  }
}
