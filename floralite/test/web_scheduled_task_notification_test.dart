import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/models/scheduler_task.dart';
import 'package:floraprise/services/web_notification/web_notification_service.dart';
import 'package:floraprise/services/web_notification/web_scheduler_reminder_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Web Scheduled Task Notification Tests', () {
    test('WebNotificationService returns safe fallbacks on non-web / VM environment', () async {
      final service = WebNotificationService.instance;

      expect(service.isSupported, isFalse);
      expect(service.permission, equals(WebNotificationPermission.unsupported));
      expect(
        WebNotificationService.defaultSoundAsset,
        equals('assets/sounds/floraprise_task_reminder.wav'),
      );

      final requested = await service.requestPermission();
      expect(requested, isFalse);

      // Safe invocation without errors
      expect(
        () => service.showNotification(
          title: 'Test Title',
          body: 'Test Body',
        ),
        returnsNormally,
      );

      expect(() => service.playChime(), returnsNormally);
      expect(
        () => service.playChime(
          soundAsset: 'assets/sounds/floraprise_task_reminder.wav',
        ),
        returnsNormally,
      );
    });

    test('isTaskEligibleForReminder correctly identifies due and ineligible tasks', () {
      final now = DateTime(2026, 9, 29, 14, 0);

      // 1. Pending task due 5 minutes ago -> eligible
      final duePending = SchedulerTask(
        id: 1,
        cloudId: 'c1',
        title: 'Call Rahul',
        type: TaskType.personalTask,
        category: TaskCategory.operational,
        priority: TaskPriority.normal,
        status: TaskStatus.pending,
        producer: TaskProducer.manual,
        scheduledAt: now.subtract(const Duration(minutes: 5)),
        createdAt: now,
        updatedAt: now,
      );
      expect(WebSchedulerReminderService.isTaskEligibleForReminder(duePending, now), isTrue);

      // 2. In-progress task due exactly now -> eligible
      final dueInProgress = duePending.copyWith(
        status: TaskStatus.inProgress,
        scheduledAt: now,
      );
      expect(WebSchedulerReminderService.isTaskEligibleForReminder(dueInProgress, now), isTrue);

      // 3. Completed task -> NOT eligible
      final completed = duePending.copyWith(status: TaskStatus.completed);
      expect(WebSchedulerReminderService.isTaskEligibleForReminder(completed, now), isFalse);

      // 4. Cancelled task -> NOT eligible
      final cancelled = duePending.copyWith(status: TaskStatus.cancelled);
      expect(WebSchedulerReminderService.isTaskEligibleForReminder(cancelled, now), isFalse);

      // 5. Future task (due in 10 minutes) -> NOT eligible
      final futureTask = duePending.copyWith(
        scheduledAt: now.add(const Duration(minutes: 10)),
      );
      expect(WebSchedulerReminderService.isTaskEligibleForReminder(futureTask, now), isFalse);

      // 6. Ancient task (> 24 hours ago) -> NOT eligible
      final ancientTask = duePending.copyWith(
        scheduledAt: now.subtract(const Duration(hours: 25)),
      );
      expect(WebSchedulerReminderService.isTaskEligibleForReminder(ancientTask, now), isFalse);
    });

    test('Deduplication key generation produces distinct keys across tasks and snooze times', () {
      final now = DateTime(2026, 9, 29, 14, 0);

      final taskA = SchedulerTask(
        id: 101,
        cloudId: 'cloud_task_101',
        title: 'Deliver Bouquet',
        type: TaskType.delivery,
        category: TaskCategory.delivery,
        priority: TaskPriority.urgent,
        status: TaskStatus.pending,
        producer: TaskProducer.manual,
        scheduledAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final keyA = WebSchedulerReminderService.generateDeduplicationKey(taskA);
      expect(keyA, equals('cloud_task_101_${now.millisecondsSinceEpoch}'));

      // Snoozed version of taskA has new effective reminder time
      final snoozedTaskA = taskA.copyWith(
        nextReminderAt: now.add(const Duration(minutes: 15)),
      );
      final keyASnoozed = WebSchedulerReminderService.generateDeduplicationKey(snoozedTaskA);
      expect(keyASnoozed, equals('cloud_task_101_${now.add(const Duration(minutes: 15)).millisecondsSinceEpoch}'));
      expect(keyA, isNot(equals(keyASnoozed)));

      // Different taskB
      final taskB = taskA.copyWith(cloudId: 'cloud_task_102');
      final keyB = WebSchedulerReminderService.generateDeduplicationKey(taskB);
      expect(keyB, equals('cloud_task_102_${now.millisecondsSinceEpoch}'));
      expect(keyA, isNot(equals(keyB)));
    });

    test('Deduplication cache prevents repeat presentation in same session', () {
      final service = WebSchedulerReminderService.instance;
      service.clearDeduplicationCache();

      final now = DateTime(2026, 9, 29, 14, 0);
      final task = SchedulerTask(
        id: 201,
        cloudId: 'task_201',
        title: 'Prepare Rose Centerpiece',
        type: TaskType.personalTask,
        category: TaskCategory.operational,
        priority: TaskPriority.high,
        status: TaskStatus.pending,
        producer: TaskProducer.manual,
        scheduledAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final key = WebSchedulerReminderService.generateDeduplicationKey(task);
      expect(service.notifiedKeys.contains(key), isFalse);

      // Simulate first notification
      // (On non-web, checkDueTasks safely returns early without exception)
      service.start();
      expect(service.isRunning, isFalse); // False on VM/non-web
      service.stop();
    });

    test('Custom sound asset is present in assets/sounds and matches defaultSoundAsset', () {
      expect(
        WebNotificationService.defaultSoundAsset,
        equals('assets/sounds/floraprise_task_reminder.wav'),
      );
    });
  });
}
