import 'package:flutter/foundation.dart';

import '../managers/scheduler_manager.dart';
import '../models/scheduler_task.dart';
import '../services/business_data_event_bus.dart';

class SchedulerProvider extends ChangeNotifier {
  SchedulerProvider(this._schedulerManager, [this._businessDataEvents]);

  final SchedulerManager _schedulerManager;
  final BusinessDataEventBus? _businessDataEvents;

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

  Future<void> loadOperationalQueue({DateTime? date}) async {
    _isLoading = true;
    _error = null;
    if (date != null) {
      _selectedDate = DateTime(date.year, date.month, date.day);
    }
    notifyListeners();

    try {
      _queueTasks = await _schedulerManager.getOperationalQueue(
        selectedDate: _selectedDate,
        searchQuery: _searchQuery,
      );
      _todaySummary = await _schedulerManager.getTodaySummary();
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
      _queueTasks = await _schedulerManager.getTodayScheduledTasks(
        _selectedDate,
      );
      _todaySummary = await _schedulerManager.getTodaySummary();
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
    _historyTasks =
        await _schedulerManager.getHistory(limit: limit, offset: offset);
    notifyListeners();
  }

  Future<void> loadCompleted({DateTime? start, DateTime? end}) async {
    _completedTasks = await _schedulerManager.getCompleted(
      start: start,
      end: end,
    );
    notifyListeners();
  }

  Future<void> markTaskInProgress(int taskId) async {
    await _schedulerManager.markInProgress(taskId);
    await loadOperationalQueue();
    _businessDataEvents?.publish(source: BusinessDataChangeSource.scheduler);
  }

  Future<void> markTaskCompleted(int taskId) async {
    try {
      await _schedulerManager.markCompleted(taskId);
    } catch (e) {
      _error = 'Failed to complete task: $e';
      rethrow;
    } finally {
      await loadOperationalQueue();
    }
    _businessDataEvents?.publish(source: BusinessDataChangeSource.scheduler);
  }

  Future<void> markTaskDeferred(int taskId) async {
    await _schedulerManager.markDeferred(taskId);
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
      await _schedulerManager.createManualTask(
        title: title,
        scheduledAt: scheduledAt,
        priority: priority,
        requiresAlarm: requiresAlarm,
        notes: notes,
      );
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
      await _schedulerManager.editTask(
        taskId: taskId,
        title: title,
        scheduledAt: scheduledAt,
        priority: priority,
        requiresAlarm: requiresAlarm,
        notes: notes,
      );
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
      await _schedulerManager.deleteTask(taskId);
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
    await _schedulerManager.restorePendingSchedules();
    await loadOperationalQueue();
  }

  Future<void> snoozeTask(int taskId, Duration duration) async {
    await _schedulerManager.snoozeTask(taskId, duration);
    await loadOperationalQueue();
    _businessDataEvents?.publish(source: BusinessDataChangeSource.scheduler);
  }
}
