import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/data/repositories/scheduler_repository.dart';
import 'package:floraprise/managers/scheduler_manager.dart';
import 'package:floraprise/models/scheduler_task.dart';
import 'package:floraprise/providers/scheduler_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() {
    AppDatabase.useInMemoryForTests = true;
    AppDatabase.testDatabaseName = 'floraprise_solo_scheduler_test_${DateTime.now().microsecondsSinceEpoch}.db';
  });

  tearDown(() async {
    await AppDatabase.instance.close();
  });

  group('Solo Android Scheduled Tasks Workflow Tests', () {
    test('BUG 1: Creating a task in Solo mode saves to SQLite and updates operational queue', () async {
      final repo = SchedulerRepository();
      final manager = SchedulerManager(repo);
      final provider = SchedulerProvider(manager);

      final scheduledTime = DateTime(2026, 9, 29, 14, 30);
      final created = await provider.createTask(
        title: 'Flower Arrangement for Wedding',
        scheduledAt: scheduledTime,
        priority: TaskPriority.normal,
        requiresAlarm: false,
        notes: 'Prepare 5 bouquets',
      );

      expect(created, isTrue);
      expect(provider.error, isNull);

      // Verify operational queue contains the created task
      expect(provider.queueTasks.length, equals(1));
      final task = provider.queueTasks.first;
      expect(task.title, equals('Flower Arrangement for Wedding'));
      expect(task.priority, equals(TaskPriority.normal));
      expect(task.status, equals(TaskStatus.pending));
      expect(task.scheduledAt, equals(scheduledTime));

      // Verify in SQLite directly
      final directTask = await repo.getTask(task.id!);
      expect(directTask, isNotNull);
      expect(directTask!.title, equals('Flower Arrangement for Wedding'));
    });

    test('BUG 2 - Action DELETE: Soft deletes task in SQLite and removes from operational queue', () async {
      final repo = SchedulerRepository();
      final manager = SchedulerManager(repo);
      final provider = SchedulerProvider(manager);

      final scheduledTime = DateTime(2026, 9, 29, 10, 0);
      final created = await provider.createTask(
        title: 'Task to be deleted',
        scheduledAt: scheduledTime,
        priority: TaskPriority.normal,
      );
      expect(created, isTrue);
      expect(provider.queueTasks.length, equals(1));
      final taskId = provider.queueTasks.first.id!;

      // Execute deleteTask
      final deleted = await provider.deleteTask(taskId);
      expect(deleted, isTrue);
      expect(provider.error, isNull);

      // Operational queue should now be empty
      expect(provider.queueTasks.isEmpty, isTrue);

      // Direct lookup from repository should return null (soft deleted)
      final directTask = await repo.getTask(taskId);
      expect(directTask, isNull);

      // Verify raw row has deleted_at populated
      final db = await AppDatabase.instance.database;
      final rawRows = await db.query(
        'scheduler_tasks',
        where: 'id = ?',
        whereArgs: [taskId],
      );
      expect(rawRows.length, equals(1));
      expect(rawRows.first['deleted_at'], isNotNull);
    });

    test('BUG 2 - Action MARK DONE: Updates status to completed and removes from pending queue', () async {
      final repo = SchedulerRepository();
      final manager = SchedulerManager(repo);
      final provider = SchedulerProvider(manager);

      final scheduledTime = DateTime(2026, 9, 29, 11, 0);
      final created = await provider.createTask(
        title: 'Task to complete',
        scheduledAt: scheduledTime,
        priority: TaskPriority.urgent,
        requiresAlarm: true,
      );
      expect(created, isTrue);
      expect(provider.queueTasks.length, equals(1));
      final taskId = provider.queueTasks.first.id!;

      // Execute markTaskCompleted
      final completed = await provider.markTaskCompleted(taskId);
      expect(completed, isTrue);
      expect(provider.error, isNull);

      // Task should no longer be in the pending operational queue
      expect(provider.queueTasks.isEmpty, isTrue);

      // Directly verify in SQLite
      final directTask = await repo.getTask(taskId);
      expect(directTask, isNotNull);
      expect(directTask!.status, equals(TaskStatus.completed));
      expect(directTask.completedAt, isNotNull);
      expect(directTask.nextReminderAt, isNull);

      // Verify today summary completed count
      final summary = await repo.getTodaySummary();
      expect(summary.completed, equals(1));
      expect(summary.pending, equals(0));
    });

    test('Action MARK IN PROGRESS: Updates status in SQLite and keeps in queue', () async {
      final repo = SchedulerRepository();
      final manager = SchedulerManager(repo);
      final provider = SchedulerProvider(manager);

      final scheduledTime = DateTime(2026, 9, 29, 15, 0);
      await provider.createTask(
        title: 'Task in progress test',
        scheduledAt: scheduledTime,
        priority: TaskPriority.normal,
      );
      final taskId = provider.queueTasks.first.id!;

      final updated = await provider.markTaskInProgress(taskId);
      expect(updated, isTrue);

      final directTask = await repo.getTask(taskId);
      expect(directTask, isNotNull);
      expect(directTask!.status, equals(TaskStatus.inProgress));
      expect(directTask.startedAt, isNotNull);
    });

    test('Action SNOOZE: Updates nextReminderAt in SQLite', () async {
      final repo = SchedulerRepository();
      final manager = SchedulerManager(repo);
      final provider = SchedulerProvider(manager);

      final scheduledTime = DateTime(2026, 9, 29, 16, 0);
      await provider.createTask(
        title: 'Task snooze test',
        scheduledAt: scheduledTime,
        priority: TaskPriority.urgent,
      );
      final taskId = provider.queueTasks.first.id!;

      final snoozed = await provider.snoozeTask(taskId, const Duration(minutes: 10));
      expect(snoozed, isTrue);

      final directTask = await repo.getTask(taskId);
      expect(directTask, isNotNull);
      expect(directTask!.nextReminderAt, isNotNull);
      expect(directTask.status, equals(TaskStatus.pending));
    });
  });
}
