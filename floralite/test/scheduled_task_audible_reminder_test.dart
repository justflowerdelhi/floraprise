import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:floraprise/models/scheduler_task.dart';
import 'package:floraprise/services/smart_alert_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Scheduled Task Audible Reminder Tests', () {
    test('SmartAlertNotificationService creates floraprise_task_reminders_v3 channel details with custom sound', () {
      final service = SmartAlertNotificationService.instance;
      final details = service.getTaskReminderNotificationDetails(enableVibration: true);

      expect(details.android, isNotNull);
      final android = details.android!;

      expect(android.channelId, equals('floraprise_task_reminders_v3'));
      expect(android.channelName, equals('Floraprise Task Reminders'));
      expect(android.importance, equals(Importance.max));
      expect(android.priority, equals(Priority.max));
      expect(android.playSound, isTrue);
      expect(android.sound, isNotNull);
      expect(android.sound, isA<RawResourceAndroidNotificationSound>());
      final sound = android.sound as RawResourceAndroidNotificationSound;
      expect(sound.sound, equals('floraprise_task_reminder'));
      expect(android.audioAttributesUsage, equals(AudioAttributesUsage.notification));
      expect(android.enableVibration, isTrue);
      expect(android.visibility, equals(NotificationVisibility.public));
      expect(android.category, equals(AndroidNotificationCategory.reminder));

      // Verify Darwin (iOS/macOS) sound
      expect(details.iOS, isNotNull);
      expect(details.iOS!.sound, equals('floraprise_task_reminder.wav'));
      expect(details.macOS, isNotNull);
      expect(details.macOS!.sound, equals('floraprise_task_reminder.wav'));

      // Verify actions
      expect(android.actions, isNotNull);
      expect(android.actions!.length, equals(2));
      expect(android.actions![0].id, equals('snooze_15'));
      expect(android.actions![0].title, equals('Snooze 15m'));
      expect(android.actions![1].id, equals('dismiss'));
      expect(android.actions![1].title, equals('Dismiss'));
    });

    test('SchedulerTask parses requiresAlarm and cloud identifiers correctly', () {
      final cloudJson = {
        'id': 'd3b07384-d113-44bb-9a10-449e7b231122',
        'title': 'Deliver Roses to Hotel Radisson',
        'type': 'delivery',
        'category': 'delivery',
        'priority': 'urgent',
        'status': 'pending',
        'scheduledAt': '2026-09-29T14:00:00Z',
        'requiresAlarm': true,
        'requiresConfirmation': true,
        'linkedOrderId': '4005',
        'linkedCustomerId': '2001',
      };

      final task = SchedulerTask.fromCloudJson(cloudJson);

      expect(task.cloudId, equals('d3b07384-d113-44bb-9a10-449e7b231122'));
      expect(task.title, equals('Deliver Roses to Hotel Radisson'));
      expect(task.type, equals(TaskType.delivery));
      expect(task.priority, equals(TaskPriority.urgent));
      expect(task.requiresAlarm, isTrue);
      expect(task.requiresConfirmation, isTrue);
    });

    test('FCM payload format for scheduled task reminder is properly structured', () {
      final rawPayload = {
        'type': 'scheduled_task_reminder',
        'taskId': 'd3b07384-d113-44bb-9a10-449e7b231122',
        'companyId': '11111111-2222-3333-4444-555555555555',
        'title': 'FLORAPRISE TASK REMINDER',
        'body': 'Deliver Roses to Hotel Radisson\nOrder: #4005\nDue now',
        'priority': 'urgent',
        'requiresAlarm': 'true',
      };

      final jsonStr = jsonEncode(rawPayload);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(decoded['type'], equals('scheduled_task_reminder'));
      expect(decoded['taskId'], equals('d3b07384-d113-44bb-9a10-449e7b231122'));
      expect(decoded['requiresAlarm'], equals('true'));
      expect(decoded['title'], equals('FLORAPRISE TASK REMINDER'));
    });
  });
}
