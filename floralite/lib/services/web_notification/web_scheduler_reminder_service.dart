import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/repositories/cloud_scheduler_repository.dart';
import '../../models/scheduler_task.dart';
import 'web_notification_service.dart';

/// Service responsible for polling and presenting due Scheduled Task
/// browser notifications in Floraprise Web.
class WebSchedulerReminderService {
  WebSchedulerReminderService._({
    CloudSchedulerRepository? cloudRepo,
    WebNotificationService? notificationService,
  })  : _cloudRepo = cloudRepo ?? CloudSchedulerRepository(),
        _notificationService =
            notificationService ?? WebNotificationService.instance;

  static final WebSchedulerReminderService instance =
      WebSchedulerReminderService._();

  CloudSchedulerRepository _cloudRepo;
  final WebNotificationService _notificationService;
  GlobalKey<NavigatorState>? _navigatorKey;
  VoidCallback? _customNavigateCallback;

  Timer? _pollTimer;
  bool _isRunning = false;

  /// In-memory deduplication set to ensure a task only alerts once per due timestamp.
  final Set<String> _notifiedKeys = <String>{};

  bool get isRunning => _isRunning;
  Set<String> get notifiedKeys => Set.unmodifiable(_notifiedKeys);

  /// Initializes and starts the background reminder polling loop on Web.
  void start({
    GlobalKey<NavigatorState>? navigatorKey,
    CloudSchedulerRepository? cloudRepo,
    VoidCallback? customNavigateCallback,
    Duration pollInterval = const Duration(seconds: 15),
  }) {
    if (!kIsWeb) return;
    if (navigatorKey != null) _navigatorKey = navigatorKey;
    if (cloudRepo != null) _cloudRepo = cloudRepo;
    if (customNavigateCallback != null) {
      _customNavigateCallback = customNavigateCallback;
    }

    if (_isRunning) return;
    _isRunning = true;

    // Run initial check immediately
    unawaited(checkDueTasks());

    // Setup periodic polling
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(pollInterval, (_) {
      unawaited(checkDueTasks());
    });

    debugPrint('WebSchedulerReminderService: Started with ${pollInterval.inSeconds}s interval');
  }

  /// Stops polling.
  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isRunning = false;
  }

  /// Clears in-memory notification cache (for testing or session reset).
  void clearDeduplicationCache() {
    _notifiedKeys.clear();
  }

  /// Checks for due tasks and triggers notifications for tasks that haven't been alerted.
  Future<void> checkDueTasks({DateTime? referenceTime}) async {
    if (!kIsWeb) return;

    // Only process if browser notification permission is granted
    if (_notificationService.permission != WebNotificationPermission.granted) {
      return;
    }

    final now = referenceTime ?? DateTime.now();

    try {
      final tasks = await _cloudRepo.getTodayScheduledTasks(now);
      for (final task in tasks) {
        if (!isTaskEligibleForReminder(task, now)) {
          continue;
        }

        final key = generateDeduplicationKey(task);
        if (_notifiedKeys.contains(key)) {
          continue;
        }

        // Mark as presented
        _notifiedKeys.add(key);

        _presentTaskNotification(task, key);
      }
    } catch (e) {
      debugPrint('WebSchedulerReminderService: Error checking due tasks: $e');
    }
  }

  /// Determines if a task is due for a reminder.
  static bool isTaskEligibleForReminder(SchedulerTask task, DateTime now) {
    // Only pending or in-progress tasks are eligible
    if (task.status != TaskStatus.pending &&
        task.status != TaskStatus.inProgress) {
      return false;
    }

    final reminderTime = task.effectiveReminderAt.toLocal();

    // Check if task is due now or in the past (within last 24 hours)
    final isDue = reminderTime.isBefore(now) || reminderTime.isAtSameMomentAs(now);
    final isRecent = now.difference(reminderTime).inHours < 24;

    return isDue && isRecent;
  }

  /// Generates a unique deduplication key based on task identity and reminder timestamp.
  static String generateDeduplicationKey(SchedulerTask task) {
    final id = task.cloudId ?? (task.id != null ? task.id.toString() : task.sourceRef ?? task.title);
    final timestamp = task.effectiveReminderAt.millisecondsSinceEpoch;
    return '${id}_$timestamp';
  }

  void _presentTaskNotification(SchedulerTask task, String key) {
    final isUrgent = task.priority.normalized == TaskPriority.urgent;
    final title = isUrgent ? '🔥 Floraprise — Urgent Task' : 'Floraprise — Scheduled Task';

    final bodyParts = <String>[task.title.trim()];
    if (task.notes != null && task.notes!.trim().isNotEmpty) {
      bodyParts.add(task.notes!.trim());
    }
    if (task.cloudLinkedOrderId != null && task.cloudLinkedOrderId!.trim().isNotEmpty) {
      bodyParts.add('Order #${task.cloudLinkedOrderId}');
    } else if (task.linkedOrderId != null) {
      bodyParts.add('Order #${task.linkedOrderId}');
    }

    final body = bodyParts.join(' • ');

    _notificationService.showNotification(
      title: title,
      body: body,
      tag: key,
      onClick: _handleNotificationClick,
    );

    _notificationService.playChime();

    debugPrint('WebSchedulerReminderService: Presented notification for "${task.title}" (key: $key)');
  }

  void _handleNotificationClick() {
    if (_customNavigateCallback != null) {
      _customNavigateCallback!();
      return;
    }

    if (_navigatorKey?.currentState != null) {
      _navigatorKey!.currentState!.pushNamed('/scheduler');
    }
  }
}
