import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/models/scheduler_task.dart';

void main() {
  group('Scheduler Timezone & Round-Trip Tests', () {
    test('SchedulerTask.fromCloudJson converts UTC ISO timestamp to local DateTime', () {
      final cloudJson = {
        'id': 'task-123',
        'title': 'Night Delivery',
        'type': 'delivery',
        'category': 'operational',
        'priority': 'normal',
        'status': 'pending',
        'scheduledAt': '2026-09-18T18:28:00.000Z',
        'nextReminderAt': '2026-09-18T18:25:00.000Z',
        'deadlineAt': '2026-09-18T19:00:00.000Z',
        'producer': 'manual',
        'sourceRef': 'manual_1',
        'createdAtUtc': '2026-09-18T18:00:00.000Z',
        'updatedAtUtc': '2026-09-18T18:00:00.000Z',
      };

      final task = SchedulerTask.fromCloudJson(cloudJson);

      // Verify the parsed DateTime is local
      expect(task.scheduledAt.isUtc, isFalse);

      // Verify the instant matches the UTC representation
      expect(task.scheduledAt.toUtc(), equals(DateTime.utc(2026, 9, 18, 18, 28)));
      expect(task.nextReminderAt?.toUtc(), equals(DateTime.utc(2026, 9, 18, 18, 25)));
      expect(task.deadlineAt?.toUtc(), equals(DateTime.utc(2026, 9, 18, 19, 0)));
    });

    test('Local 11:58 PM round-trip through UTC serialization and fromCloudJson maintains exact local time', () {
      // 1. User picks 11:58 PM on 18 Sep 2026
      final initialLocalTime = DateTime(2026, 9, 18, 23, 58);

      // 2. Sent to API via toUtc().toIso8601String()
      final serializedForApi = initialLocalTime.toUtc().toIso8601String();

      // 3. Simulated API response
      final apiResponse = {
        'id': 'task-456',
        'title': 'Late Night Prep',
        'type': 'personalTask',
        'category': 'operational',
        'priority': 'urgent',
        'status': 'pending',
        'scheduledAt': serializedForApi,
        'producer': 'manual',
      };

      // 4. Client parses response
      final parsedTask = SchedulerTask.fromCloudJson(apiResponse);

      // 5. Verify local hour, minute, and date match exactly
      expect(parsedTask.scheduledAt.year, equals(2026));
      expect(parsedTask.scheduledAt.month, equals(9));
      expect(parsedTask.scheduledAt.day, equals(18));
      expect(parsedTask.scheduledAt.hour, equals(23));
      expect(parsedTask.scheduledAt.minute, equals(58));
    });

    test('Edit flow does not introduce compounding timezone drift across multiple saves', () {
      // Step 1: Initial local creation (11:58 PM)
      var currentLocal = DateTime(2026, 9, 18, 23, 58);

      for (var cycle = 1; cycle <= 5; cycle++) {
        // Publish to API
        final apiPayloadScheduledAt = currentLocal.toUtc().toIso8601String();

        // Response from API
        final apiJson = {
          'id': 'task-edit-loop',
          'title': 'Recurring Check',
          'type': 'reminder',
          'category': 'operational',
          'priority': 'normal',
          'status': 'pending',
          'scheduledAt': apiPayloadScheduledAt,
          'producer': 'manual',
        };

        // Client parses
        final task = SchedulerTask.fromCloudJson(apiJson);

        // Edit dialog initializes
        final timeOfDay = TimeOfDay.fromDateTime(task.scheduledAt.toLocal());
        expect(timeOfDay.hour, equals(23), reason: 'Cycle $cycle hour drift');
        expect(timeOfDay.minute, equals(58), reason: 'Cycle $cycle minute drift');

        // User saves without changes
        currentLocal = DateTime(
          task.scheduledAt.toLocal().year,
          task.scheduledAt.toLocal().month,
          task.scheduledAt.toLocal().day,
          timeOfDay.hour,
          timeOfDay.minute,
        );

        expect(currentLocal.hour, equals(23));
        expect(currentLocal.minute, equals(58));
        expect(currentLocal.day, equals(18));
      }
    });

    test('Multiple representative times round-trip without shifting', () {
      final testCases = [
        DateTime(2026, 9, 18, 0, 0),   // 12:00 AM (midnight)
        DateTime(2026, 9, 18, 12, 30), // 12:30 PM (midday)
        DateTime(2026, 9, 18, 18, 28), // 6:28 PM (evening)
        DateTime(2026, 9, 18, 23, 58), // 11:58 PM (late night)
      ];

      for (final localTime in testCases) {
        final apiJson = {
          'id': 'test-${localTime.hour}-${localTime.minute}',
          'title': 'Test Time',
          'type': 'reminder',
          'category': 'operational',
          'priority': 'normal',
          'status': 'pending',
          'scheduledAt': localTime.toUtc().toIso8601String(),
          'producer': 'manual',
        };

        final task = SchedulerTask.fromCloudJson(apiJson);

        expect(task.scheduledAt.year, equals(localTime.year));
        expect(task.scheduledAt.month, equals(localTime.month));
        expect(task.scheduledAt.day, equals(localTime.day));
        expect(task.scheduledAt.hour, equals(localTime.hour));
        expect(task.scheduledAt.minute, equals(localTime.minute));
      }
    });

    test('Calling .toLocal() on an already-local SQLite DateTime is idempotent', () {
      final localDateTime = DateTime(2026, 9, 18, 23, 58);
      expect(localDateTime.isUtc, isFalse);

      final doubleLocal = localDateTime.toLocal();
      expect(doubleLocal.isUtc, isFalse);
      expect(doubleLocal.hour, equals(23));
      expect(doubleLocal.minute, equals(58));
      expect(doubleLocal, equals(localDateTime));
    });
  });
}
