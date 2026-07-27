import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../data/repositories/scheduler_repository.dart';
import '../models/scheduler_task.dart';

const _schedulerActionComplete = 'complete';
const _schedulerActionSnooze5 = 'snooze_5';
const _schedulerActionSnooze10 = 'snooze_10';

@pragma('vm:entry-point')
void schedulerNotificationTapBackground(NotificationResponse response) {
  unawaited(SchedulerService.instance.handleNotificationResponse(response));
}

class SchedulerService {
  SchedulerService._({
    SchedulerRepository? repository,
    FlutterLocalNotificationsPlugin? notifications,
  })  : _repository = repository ?? SchedulerRepository(),
        _notifications = notifications ?? FlutterLocalNotificationsPlugin();

  static final SchedulerService instance = SchedulerService._();

  final SchedulerRepository _repository;
  final FlutterLocalNotificationsPlugin _notifications;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          schedulerNotificationTapBackground,
    );

    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
    await android?.requestFullScreenIntentPermission();

    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        'scheduler_low',
        'Scheduler Low',
        description: 'Silent reminders for low priority tasks',
        importance: Importance.low,
        playSound: false,
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        'scheduler_normal',
        'Scheduler Normal',
        description: 'Standard reminders for scheduled tasks',
        importance: Importance.defaultImportance,
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        'scheduler_high',
        'Scheduler High',
        description: 'High priority reminders with vibration',
        importance: Importance.high,
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        'scheduler_critical',
        'Scheduler Critical',
        description: 'Critical alarm-style reminders',
        importance: Importance.max,
      ),
    );

    _initialized = true;
  }

  Future<void> scheduleTask(int taskId) async {
    await initialize();
    final task = await _repository.getTask(taskId);
    if (task == null) return;
    if (task.status == TaskStatus.completed ||
        task.status == TaskStatus.cancelled) {
      await cancelTask(taskId);
      return;
    }

    await cancelTask(taskId, clearReminderState: false);

    final scheduledTimes = _buildScheduleTimes(task);
    if (scheduledTimes.isEmpty) {
      debugPrint('Scheduler: no future reminders for task $taskId');
      return;
    }

    final jobs = <({String action, DateTime runAt, String? payloadJson})>[];
    for (var index = 0; index < scheduledTimes.length; index++) {
      final when = scheduledTimes[index];
      final payload = jsonEncode({
        'taskId': taskId,
        'scheduledAt': when.toIso8601String(),
      });
      await _notifications.zonedSchedule(
        _notificationId(taskId, index),
        task.title,
        _bodyForTask(task),
        tz.TZDateTime.from(when, tz.local),
        _detailsForTask(task),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      jobs.add((action: 'schedule_created', runAt: when, payloadJson: payload));
    }

    await _repository.replaceNotificationJobs(taskId: taskId, jobs: jobs);
    await _repository.updateReminderState(
      taskId: taskId,
      nextReminderAt: task.requiresAlarm && task.priority == TaskPriority.urgent
          ? scheduledTimes.first
          : null,
    );
    debugPrint('Scheduler: schedule created for task $taskId');
  }

  Future<void> cancelTask(
    int taskId, {
    bool clearReminderState = true,
  }) async {
    await initialize();
    for (var index = 0; index < 290; index++) {
      await _notifications.cancel(_notificationId(taskId, index));
    }
    await _repository.clearNotificationJobs(taskId);
    if (clearReminderState) {
      await _repository.updateReminderState(
        taskId: taskId,
        nextReminderAt: null,
      );
    }
  }

  Future<void> rescheduleTask(int taskId) async {
    debugPrint('Scheduler: rescheduled task $taskId');
    await scheduleTask(taskId);
  }

  Future<void> restorePendingSchedules() async {
    await initialize();
    final activeTasks = await _repository.listActiveTasks();
    for (final task in activeTasks) {
      final taskId = task.id;
      if (taskId == null) continue;
      await scheduleTask(taskId);
    }
    debugPrint('Scheduler: restored ${activeTasks.length} pending schedules');
  }

  Future<void> markCompleted(int taskId) async {
    await cancelTask(taskId);
    await _repository.updateReminderState(
      taskId: taskId,
      status: TaskStatus.completed,
      completedAt: DateTime.now(),
      nextReminderAt: null,
    );
    debugPrint('Scheduler: completed task $taskId');
  }

  Future<void> snoozeTask(int taskId, Duration duration) async {
    final nextReminder = DateTime.now().add(duration);
    await cancelTask(taskId, clearReminderState: false);
    await _repository.updateReminderState(
      taskId: taskId,
      nextReminderAt: nextReminder,
      status: TaskStatus.pending,
    );
    debugPrint('Scheduler: snoozed task $taskId to $nextReminder');
    await scheduleTask(taskId);
  }

  Future<void> handleNotificationResponse(NotificationResponse response) async {
    final payload = response.payload;
    if (payload == null || payload.trim().isEmpty) return;
    final decoded = jsonDecode(payload) as Map<String, dynamic>;
    final taskId = decoded['taskId'] as int?;
    if (taskId == null) return;

    switch (response.actionId) {
      case _schedulerActionComplete:
        await markCompleted(taskId);
        break;
      case _schedulerActionSnooze5:
        await snoozeTask(taskId, const Duration(minutes: 5));
        break;
      case _schedulerActionSnooze10:
        await snoozeTask(taskId, const Duration(minutes: 10));
        break;
      default:
        debugPrint('Scheduler: notification fired for task $taskId');
        break;
    }
  }

  List<DateTime> _buildScheduleTimes(SchedulerTask task) {
    final now = DateTime.now();
    final first = task.effectiveReminderAt.isBefore(now)
        ? now.add(const Duration(seconds: 2))
        : task.effectiveReminderAt;

    if (!(task.requiresAlarm && task.priority == TaskPriority.urgent)) {
      return [first];
    }

    final times = <DateTime>[];
    for (var index = 0; index < 288; index++) {
      times.add(first.add(Duration(minutes: index * 5)));
    }
    return times;
  }

  NotificationDetails _detailsForTask(SchedulerTask task) {
    final isCritical =
        task.priority == TaskPriority.urgent && task.requiresAlarm;

    AndroidNotificationDetails android;
    if (isCritical) {
      android = const AndroidNotificationDetails(
        'scheduler_critical',
        'Scheduler Critical',
        channelDescription: 'Critical alarm-style reminders',
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        enableVibration: true,
        playSound: true,
        visibility: NotificationVisibility.public,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            _schedulerActionComplete,
            'Complete',
            showsUserInterface: true,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            _schedulerActionSnooze5,
            'Snooze 5 min',
            showsUserInterface: true,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            _schedulerActionSnooze10,
            'Snooze 10 min',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      );
    } else {
      switch (task.priority) {
        case TaskPriority.low:
          android = const AndroidNotificationDetails(
            'scheduler_low',
            'Scheduler Low',
            channelDescription: 'Silent reminders for low priority tasks',
            importance: Importance.low,
            priority: Priority.low,
            playSound: false,
            enableVibration: false,
          );
          break;
        case TaskPriority.high:
          android = const AndroidNotificationDetails(
            'scheduler_high',
            'Scheduler High',
            channelDescription: 'High priority reminders with vibration',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          );
          break;
        case TaskPriority.normal:
        case TaskPriority.urgent:
          android = const AndroidNotificationDetails(
            'scheduler_normal',
            'Scheduler Normal',
            channelDescription: 'Standard reminders for scheduled tasks',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            playSound: true,
          );
          break;
      }
    }

    final darwin = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: task.priority != TaskPriority.low,
      interruptionLevel:
          isCritical ? InterruptionLevel.critical : InterruptionLevel.active,
    );

    return NotificationDetails(android: android, iOS: darwin, macOS: darwin);
  }

  String _bodyForTask(SchedulerTask task) {
    if (task.requiresAlarm && task.priority == TaskPriority.urgent) {
      return 'Critical task requires attention now.';
    }
    return task.notes?.trim().isNotEmpty == true
        ? task.notes!.trim()
        : 'Scheduled for ${task.effectiveReminderAt.hour.toString().padLeft(2, '0')}:${task.effectiveReminderAt.minute.toString().padLeft(2, '0')}';
  }

  int _notificationId(int taskId, int offset) => taskId * 1000 + offset;
}
