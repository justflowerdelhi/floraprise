import 'package:flutter/foundation.dart';

import '../data/repositories/scheduler_repository.dart';
import '../models/scheduler_task.dart';
import '../services/scheduler_service.dart';
import '../services/smart_alert_engine.dart';
import '../models/walk_in_enums.dart';

class SchedulerManager {
  SchedulerManager(this._schedulerRepository, [SchedulerService? schedulerService])
      : _schedulerService = schedulerService ?? SchedulerService.instance;

  final SchedulerRepository _schedulerRepository;
  final SchedulerService _schedulerService;

  Future<int> publishTask(PublishTaskCommand command) async {
    final now = DateTime.now();
    final task = SchedulerTask(
      title: command.title,
      type: command.type,
      category: command.category,
      priority: command.priority,
      status: TaskStatus.pending,
      scheduledAt: command.scheduledAt,
      deadlineAt: command.deadlineAt,
      notes: command.notes,
      linkedCustomerId: command.linkedCustomerId,
      linkedOrderId: command.linkedOrderId,
      assignedStaffId: command.assignedStaffId,
      producer: command.producer,
      sourceRef: command.sourceRef,
      requiresConfirmation: command.requiresConfirmation,
      requiresAlarm: command.requiresAlarm,
      createdAt: now,
      updatedAt: now,
    );

    final taskId = await _schedulerRepository.publishTask(task);
    try {
      await _schedulerService.scheduleTask(taskId);
    } catch (e) {
      debugPrint('SchedulerManager.publishTask notification error: $e');
    }

    return taskId;
  }

  Future<void> publishWalkInOrderTask({
    required int orderId,
    required FulfilmentType fulfilmentType,
    required DateTime? scheduledAt,
    String? deliverySlotLabel,
  }) async {
    if (scheduledAt == null || fulfilmentType == FulfilmentType.takeAway) {
      return;
    }

    final taskType = fulfilmentType == FulfilmentType.pickupLater
        ? TaskType.pickup
        : TaskType.delivery;
    final title = fulfilmentType == FulfilmentType.pickupLater
        ? 'Pickup order #$orderId'
        : 'Delivery order #$orderId';

    final slotNote = _deliverySlotLabel((deliverySlotLabel ?? '').trim());

    await publishTask(
      PublishTaskCommand(
        title: title,
        type: taskType,
        category: TaskCategory.delivery,
        priority: TaskPriority.high,
        scheduledAt: scheduledAt,
        linkedOrderId: orderId,
        producer: TaskProducer.walkIn,
        sourceRef: 'walkin_order_${orderId}_${taskType.name}',
        requiresConfirmation: true,
        notes: slotNote.isEmpty
            ? 'Published from walk-in confirmation'
            : 'Published from walk-in confirmation ($slotNote)',
      ),
    );
  }

  Future<List<SchedulerTask>> getOperationalQueue({
    required DateTime selectedDate,
    String? searchQuery,
  }) {
    return _schedulerRepository.getOperationalQueue(
      selectedDate: selectedDate,
      searchQuery: searchQuery,
    );
  }

  Future<List<SchedulerTask>> getTodayScheduledTasks(DateTime date) {
    return _schedulerRepository.getTodayScheduledTasks(date);
  }

  Future<List<SchedulerTask>> getHistory({
    int limit = 100,
    int offset = 0,
  }) {
    return _schedulerRepository.getHistory(limit: limit, offset: offset);
  }

  Future<List<SchedulerTask>> getCompleted({
    DateTime? start,
    DateTime? end,
  }) {
    return _schedulerRepository.getCompleted(start: start, end: end);
  }

  Future<SchedulerTodaySummary> getTodaySummary() {
    return _schedulerRepository.getTodaySummary();
  }

  Future<void> markInProgress(int taskId) {
    return _schedulerRepository.updateTaskStatus(taskId, TaskStatus.inProgress);
  }

  Future<void> markCompleted(int taskId) async {
    await _schedulerRepository.updateTaskStatus(taskId, TaskStatus.completed);
    try {
      await _schedulerService.cancelTask(taskId);
    } catch (e) {
      debugPrint('SchedulerManager.markCompleted cancelTask error: $e');
    }
    try {
      await SmartAlertEngine.instance.acknowledgeAlert(taskId);
    } catch (e) {
      debugPrint('SchedulerManager.markCompleted acknowledgeAlert error: $e');
    }
  }

  Future<void> markDeferred(int taskId) {
    return _schedulerRepository.updateTaskStatus(taskId, TaskStatus.deferred);
  }

  Future<int> createManualTask({
    required String title,
    required DateTime scheduledAt,
    required TaskPriority priority,
    bool requiresAlarm = false,
    String? notes,
  }) {
    return publishTask(
      PublishTaskCommand(
        title: title,
        type: TaskType.personalTask,
        category: TaskCategory.operational,
        priority: priority,
        scheduledAt: scheduledAt,
        notes: notes,
        producer: TaskProducer.manual,
        requiresAlarm: requiresAlarm,
      ),
    );
  }

  Future<void> editTask({
    required int taskId,
    required String title,
    required TaskPriority priority,
    required DateTime scheduledAt,
    bool requiresAlarm = false,
    String? notes,
  }) async {
    await _schedulerRepository.updateTask(
      taskId: taskId,
      title: title,
      priority: priority,
      scheduledAt: scheduledAt,
      requiresAlarm: requiresAlarm,
      notes: notes,
    );
    try {
      await _schedulerService.rescheduleTask(taskId);
    } catch (e) {
      debugPrint('SchedulerManager.editTask rescheduleTask error: $e');
    }
  }

  Future<void> deleteTask(int taskId) async {
    await _schedulerRepository.softDeleteTask(taskId);
    try {
      await _schedulerService.cancelTask(taskId);
    } catch (e) {
      debugPrint('SchedulerManager.deleteTask cancelTask error: $e');
    }
    try {
      await SmartAlertEngine.instance.acknowledgeAlert(taskId);
    } catch (e) {
      debugPrint('SchedulerManager.deleteTask acknowledgeAlert error: $e');
    }
  }

  Future<void> restorePendingSchedules() {
    return _schedulerService.restorePendingSchedules();
  }

  Future<void> snoozeTask(int taskId, Duration duration) async {
    final nextReminder = DateTime.now().add(duration);
    await _schedulerRepository.updateReminderState(
      taskId: taskId,
      nextReminderAt: nextReminder,
      status: TaskStatus.pending,
    );
    try {
      await _schedulerService.snoozeTask(taskId, duration);
    } catch (e) {
      debugPrint('SchedulerManager.snoozeTask error: $e');
    }
  }

  String _deliverySlotLabel(String raw) {
    if (raw.isEmpty) return '';
    if (raw.startsWith('custom_')) {
      final time = raw.replaceFirst('custom_', '');
      return 'Custom Time ($time)';
    }

    switch (raw) {
      case 'morning':
        return 'Morning (8-10)';
      case 'late_morning':
        return 'Late Morning (10-1)';
      case 'afternoon':
        return 'Afternoon (1-4)';
      case 'evening':
        return 'Evening (4-7)';
      case 'night':
        return 'Night (7-10)';
      case 'midnight':
        return 'Midnight (11-12:30)';
      case 'custom':
        return 'Custom Time';
      default:
        return raw;
    }
  }
}
