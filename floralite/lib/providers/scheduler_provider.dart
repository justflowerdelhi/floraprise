import 'package:flutter/foundation.dart';

import '../data/repositories/cloud_scheduler_repository.dart';
import '../managers/scheduler_manager.dart';
import '../models/scheduler_task.dart';
import '../services/business_data_event_bus.dart';
import 'storage_mode_provider.dart';

class SchedulerProvider extends ChangeNotifier {
  SchedulerProvider(
    this._schedulerManager, [
    this._businessDataEvents,
    this._storageModeProvider,
    this._cloudRepo,
  ]);

  final SchedulerManager _schedulerManager;
  final BusinessDataEventBus? _businessDataEvents;
  final StorageModeProvider? _storageModeProvider;
  final CloudSchedulerRepository? _cloudRepo;

  bool get isCloud => _storageModeProvider?.isCloud == true;

  DateTime _selectedDate = DateTime.now();
  List<SchedulerTask> _queueTasks = const [];
  List<SchedulerTask> _historyTasks = const [];
  List<SchedulerTask> _completedTasks = const [];
  SchedulerTodaySummary _todaySummary = const SchedulerTodaySummary(
    pending: 0,
    completed: 0,
    overdue: 0,
    urgent: 0,
    todayDeliveries: 0,
    todayPickups: 0,
  );
  bool _isLoading = false;
  String _searchQuery = '';
  String? _error;

  DateTime get selectedDate => _selectedDate;
  List<SchedulerTask> get queueTasks => _queueTasks;
  List<SchedulerTask> get historyTasks => _historyTasks;
  List<SchedulerTask> get completedTasks => _completedTasks;
  SchedulerTodaySummary get todaySummary => _todaySummary;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get error => _error;

  SchedulerTask? _findTask(int taskId) {
    for (final t in _queueTasks) {
      if (t.id == taskId) return t;
    }
    for (final t in _historyTasks) {
      if (t.id == taskId) return t;
    }
    for (final t in _completedTasks) {
      if (t.id == taskId) return t;
    }
    return null;
  }

  String? _findCloudId(int taskId) {
    final t = _findTask(taskId);
    return t?.cloudId;
  }

  Future<void> loadOperationalQueue({DateTime? date}) async {
    _isLoading = true;
    _error = null;
    if (date != null) {
      _selectedDate = DateTime(date.year, date.month, date.day);
    }
    notifyListeners();

    try {
      if (isCloud && _cloudRepo != null) {
        _queueTasks = await _cloudRepo!.getOperationalQueue(
          selectedDate: _selectedDate,
          searchQuery: _searchQuery,
        );
        _todaySummary = await _cloudRepo!.getTodaySummary();
      } else {
        _queueTasks = await _schedulerManager.getOperationalQueue(
          selectedDate: _selectedDate,
          searchQuery: _searchQuery,
        );
        _todaySummary = await _schedulerManager.getTodaySummary();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTodayScheduledTasks() async {
    _isLoading = true;
    _error = null;
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _searchQuery = '';
    notifyListeners();

    try {
      if (isCloud && _cloudRepo != null) {
        _queueTasks = await _cloudRepo!.getTodayScheduledTasks(_selectedDate);
        _todaySummary = await _cloudRepo!.getTodaySummary();
      } else {
        _queueTasks =
            await _schedulerManager.getTodayScheduledTasks(_selectedDate);
        _todaySummary = await _schedulerManager.getTodaySummary();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> nextDay() async {
    await loadOperationalQueue(
      date: _selectedDate.add(const Duration(days: 1)),
    );
  }

  Future<void> previousDay() async {
    await loadOperationalQueue(
      date: _selectedDate.subtract(const Duration(days: 1)),
    );
  }

  Future<void> setSearchQuery(String query) async {
    _searchQuery = query.trim();
    await loadOperationalQueue();
  }

  Future<void> loadHistory({int limit = 100, int offset = 0}) async {
    if (isCloud && _cloudRepo != null) {
      _historyTasks = await _cloudRepo!.listTasks(query: _searchQuery);
    } else {
      _historyTasks =
          await _schedulerManager.getHistory(limit: limit, offset: offset);
    }
    notifyListeners();
  }

  Future<void> loadCompleted({DateTime? start, DateTime? end}) async {
    if (isCloud && _cloudRepo != null) {
      _completedTasks = await _cloudRepo!.listTasks(
        from: start,
        to: end,
        status: TaskStatus.completed.name,
      );
    } else {
      _completedTasks = await _schedulerManager.getCompleted(
        start: start,
        end: end,
      );
    }
    notifyListeners();
  }

  Future<void> markTaskInProgress(int taskId) async {
    if (isCloud && _cloudRepo != null) {
      final cloudId = _findCloudId(taskId);
      if (cloudId != null) {
        await _cloudRepo!.setStatus(cloudId, TaskStatus.inProgress);
      }
    } else {
      await _schedulerManager.markInProgress(taskId);
    }
    await loadOperationalQueue();
    _businessDataEvents?.publish(source: BusinessDataChangeSource.scheduler);
  }

  Future<void> markTaskCompleted(int taskId) async {
    try {
      if (isCloud && _cloudRepo != null) {
        final cloudId = _findCloudId(taskId);
        if (cloudId != null) {
          await _cloudRepo!.setStatus(cloudId, TaskStatus.completed);
        }
      } else {
        await _schedulerManager.markCompleted(taskId);
      }
    } catch (e) {
      _error = 'Failed to complete task: $e';
      rethrow;
    } finally {
      await loadOperationalQueue();
    }
    _businessDataEvents?.publish(source: BusinessDataChangeSource.scheduler);
  }

  Future<void> markTaskDeferred(int taskId) async {
    if (isCloud && _cloudRepo != null) {
      final cloudId = _findCloudId(taskId);
      if (cloudId != null) {
        await _cloudRepo!.setStatus(cloudId, TaskStatus.deferred);
      }
    } else {
      await _schedulerManager.markDeferred(taskId);
    }
    await loadOperationalQueue();
    _businessDataEvents?.publish(source: BusinessDataChangeSource.scheduler);
  }

  Future<bool> createTask({
    required String title,
    required DateTime scheduledAt,
    required TaskPriority priority,
    bool requiresAlarm = false,
    String? notes,
  }) async {
    _error = null;
    notifyListeners();
    try {
      if (isCloud && _cloudRepo != null) {
        final now = DateTime.now();
        final task = SchedulerTask(
          title: title,
          type: TaskType.personalTask,
          category: TaskCategory.operational,
          priority: priority,
          status: TaskStatus.pending,
          scheduledAt: scheduledAt,
          notes: notes,
          producer: TaskProducer.manual,
          sourceRef: 'manual_${now.millisecondsSinceEpoch}',
          requiresAlarm: requiresAlarm,
          createdAt: now,
          updatedAt: now,
        );
        await _cloudRepo!.publishTask(task);
      } else {
        await _schedulerManager.createManualTask(
          title: title,
          scheduledAt: scheduledAt,
          priority: priority,
          requiresAlarm: requiresAlarm,
          notes: notes,
        );
      }
      await loadOperationalQueue(date: scheduledAt);
      _businessDataEvents?.publish(source: BusinessDataChangeSource.scheduler);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> editTask({
    required int taskId,
    required String title,
    required DateTime scheduledAt,
    required TaskPriority priority,
    bool requiresAlarm = false,
    String? notes,
  }) async {
    _error = null;
    notifyListeners();
    try {
      if (isCloud && _cloudRepo != null) {
        final existing = _findTask(taskId);
        final cloudId = existing?.cloudId ?? taskId.toString();
        final now = DateTime.now();
        final updated = (existing ??
                SchedulerTask(
                  title: title,
                  type: TaskType.personalTask,
                  category: TaskCategory.operational,
                  priority: priority,
                  status: TaskStatus.pending,
                  scheduledAt: scheduledAt,
                  producer: TaskProducer.manual,
                  createdAt: now,
                  updatedAt: now,
                ))
            .copyWith(
          title: title,
          scheduledAt: scheduledAt,
          priority: priority,
          requiresAlarm: requiresAlarm,
          notes: notes,
          updatedAt: now,
        );
        await _cloudRepo!.updateTask(cloudId, updated);
      } else {
        await _schedulerManager.editTask(
          taskId: taskId,
          title: title,
          scheduledAt: scheduledAt,
          priority: priority,
          requiresAlarm: requiresAlarm,
          notes: notes,
        );
      }
      await loadOperationalQueue(date: scheduledAt);
      _businessDataEvents?.publish(source: BusinessDataChangeSource.scheduler);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTask(int taskId) async {
    _error = null;
    notifyListeners();
    try {
      if (isCloud && _cloudRepo != null) {
        final cloudId = _findCloudId(taskId);
        if (cloudId != null) {
          await _cloudRepo!.deleteTask(cloudId);
        }
      } else {
        await _schedulerManager.deleteTask(taskId);
      }
      await loadOperationalQueue();
      _businessDataEvents?.publish(source: BusinessDataChangeSource.scheduler);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> restorePendingSchedules() async {
    if (isCloud || kIsWeb) return;
    await _schedulerManager.restorePendingSchedules();
    await loadOperationalQueue();
  }

  Future<void> snoozeTask(int taskId, Duration duration) async {
    if (isCloud && _cloudRepo != null) {
      final cloudId = _findCloudId(taskId);
      if (cloudId != null) {
        await _cloudRepo!.setStatus(cloudId, TaskStatus.deferred);
      }
    } else {
      await _schedulerManager.snoozeTask(taskId, duration);
    }
    await loadOperationalQueue();
    _businessDataEvents?.publish(source: BusinessDataChangeSource.scheduler);
  }
}
