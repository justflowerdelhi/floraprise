import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/repositories/scheduler_repository.dart';
import '../models/scheduler_task.dart';
import '../models/smart_alert.dart';
import 'smart_alert_notification_service.dart';

const _alertActionAcknowledge = 'alert_acknowledge';
const _alertActionComplete = 'alert_complete';
const _alertActionSnooze5 = 'alert_snooze_5';
const _alertActionSnooze10 = 'alert_snooze_10';
const _alertActionSnooze15 = 'alert_snooze_15';
const _alertActionDismiss = 'alert_dismiss';
const _alertActionOpenOrder = 'alert_open_order';
const _alertActionNavigate = 'alert_navigate';
const _alertActionCallCustomer = 'alert_call_customer';
const _alertActionCallDriver = 'alert_call_driver';

@pragma('vm:entry-point')
void smartAlertNotificationTapBackground(NotificationResponse response) {
  unawaited(SmartAlertEngine.instance.handleNotificationResponse(response));
}

class SmartAlertEngine {
  SmartAlertEngine._({
    SchedulerRepository? repository,
    SmartAlertNotificationService? notificationService,
    SharedPreferences? prefs,
  })  : _repository = repository ?? SchedulerRepository(),
        _notificationService = notificationService ?? SmartAlertNotificationService.instance,
        _prefs = prefs;

  static final SmartAlertEngine instance = SmartAlertEngine._();

  final SchedulerRepository _repository;
  final SmartAlertNotificationService _notificationService;
  SharedPreferences? _prefs;

  bool _initialized = false;
  AlertQueue _alertQueue = AlertQueue(alerts: [], lastUpdated: DateTime.now());
  final Map<int, SmartAlert> _activeAlerts = {};
  Timer? _escalationTimer;
  Timer? _queueProcessingTimer;

  // Settings
  QuietHoursConfig _quietHoursConfig = const QuietHoursConfig();
  AlertCustomizationSettings _customizationSettings = const AlertCustomizationSettings();

  Future<void> initialize() async {
    if (_initialized) return;

    await _notificationService.initialize();
    await _loadSettings();

    // Register notification tap handler
    await _notificationService.notifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
        macOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          smartAlertNotificationTapBackground,
    );

    // Start escalation timer
    _startEscalationTimer();
    _startQueueProcessingTimer();

    _initialized = true;
    debugPrint('SmartAlertEngine: initialized');
  }

  Future<void> _loadSettings() async {
    _prefs ??= await SharedPreferences.getInstance();
    
    final quietHoursEnabled = _prefs!.getBool('quiet_hours_enabled') ?? false;
    final quietHoursStart = _prefs!.getString('quiet_hours_start') ?? '23:00';
    final quietHoursEnd = _prefs!.getString('quiet_hours_end') ?? '07:00';
    final quietHoursBypassCritical = _prefs!.getBool('quiet_hours_bypass_critical') ?? true;
    
    final startParts = quietHoursStart.split(':');
    final endParts = quietHoursEnd.split(':');
    
    _quietHoursConfig = QuietHoursConfig(
      enabled: quietHoursEnabled,
      startTime: TimeOfDay(
        hour: int.parse(startParts[0]),
        minute: int.parse(startParts[1]),
      ),
      endTime: TimeOfDay(
        hour: int.parse(endParts[0]),
        minute: int.parse(endParts[1]),
      ),
      bypassCritical: quietHoursBypassCritical,
    );

    final notificationSound = _prefs!.getString('notification_sound') ?? 'default';
    final alarmSound = _prefs!.getString('alarm_sound') ?? 'alarm';
    final vibrationEnabled = _prefs!.getBool('vibration_enabled') ?? true;
    final alarmVolume = _prefs!.getDouble('alarm_volume') ?? 0.8;
    final repeatIntervalMinutes = _prefs!.getInt('repeat_interval_minutes') ?? 5;
    final escalationDelaySeconds = _prefs!.getInt('escalation_delay_seconds') ?? 30;

    _customizationSettings = AlertCustomizationSettings(
      notificationSound: notificationSound,
      alarmSound: alarmSound,
      vibrationEnabled: vibrationEnabled,
      alarmVolume: alarmVolume,
      repeatInterval: Duration(minutes: repeatIntervalMinutes),
      escalationDelay: Duration(seconds: escalationDelaySeconds),
    );
  }

  Future<void> saveSettings({
    QuietHoursConfig? quietHours,
    AlertCustomizationSettings? customization,
  }) async {
    _prefs ??= await SharedPreferences.getInstance();

    if (quietHours != null) {
      _quietHoursConfig = quietHours;
      await _prefs!.setBool('quiet_hours_enabled', quietHours.enabled);
      await _prefs!.setString('quiet_hours_start', 
          '${quietHours.startTime.hour.toString().padLeft(2, '0')}:${quietHours.startTime.minute.toString().padLeft(2, '0')}');
      await _prefs!.setString('quiet_hours_end', 
          '${quietHours.endTime.hour.toString().padLeft(2, '0')}:${quietHours.endTime.minute.toString().padLeft(2, '0')}');
      await _prefs!.setBool('quiet_hours_bypass_critical', quietHours.bypassCritical);
    }

    if (customization != null) {
      _customizationSettings = customization;
      await _prefs!.setString('notification_sound', customization.notificationSound);
      await _prefs!.setString('alarm_sound', customization.alarmSound);
      await _prefs!.setBool('vibration_enabled', customization.vibrationEnabled);
      await _prefs!.setDouble('alarm_volume', customization.alarmVolume);
      await _prefs!.setInt('repeat_interval_minutes', customization.repeatInterval.inMinutes);
      await _prefs!.setInt('escalation_delay_seconds', customization.escalationDelay.inSeconds);
    }
  }

  void _startEscalationTimer() {
    _escalationTimer?.cancel();
    _escalationTimer = Timer.periodic(
      const Duration(seconds: 10),
      _checkEscalations,
    );
  }

  void _startQueueProcessingTimer() {
    _queueProcessingTimer?.cancel();
    _queueProcessingTimer = Timer.periodic(
      const Duration(seconds: 5),
      _processAlertQueue,
    );
  }

  Future<void> _checkEscalations(Timer timer) async {
    final now = DateTime.now();
    final alertsToEscalate = <SmartAlert>[];

    for (final alert in _activeAlerts.values) {
      if (!alert.isActive) continue;
      if (alert.nextEscalationAt == null) continue;
      if (alert.nextEscalationAt!.isBefore(now)) {
        alertsToEscalate.add(alert);
      }
    }

    for (final alert in alertsToEscalate) {
      await _escalateAlert(alert);
    }
  }

  Future<void> _processAlertQueue(Timer timer) async {
    if (_alertQueue.pending.isEmpty) return;

    final current = _alertQueue.current;
    if (current == null) return;

    // Check if current alert is already being handled
    if (current.state == AlertState.acknowledged || 
        current.state == AlertState.completed ||
        current.state == AlertState.dismissed) {
      // Move to next in queue
      await _advanceQueue();
      return;
    }

    // If current alert is critical and not yet escalated, trigger escalation
    if (current.level == AlertLevel.critical && 
        current.state == AlertState.pending &&
        current.escalationCount == 0) {
      await _escalateAlert(current);
    }
  }

  Future<void> _escalateAlert(SmartAlert alert) async {
    if (!alert.canEscalate) {
      debugPrint('SmartAlertEngine: Alert ${alert.taskId} cannot escalate further');
      return;
    }

    final task = await _repository.getTask(alert.taskId);
    if (task == null) {
      await dismissAlert(alert.taskId);
      return;
    }

    // Check quiet hours
    if (!_quietHoursConfig.shouldAllowAlert(alert.level)) {
      debugPrint('SmartAlertEngine: Alert ${alert.taskId} blocked by quiet hours');
      return;
    }

    final escalatedAlert = alert.copyWith(
      state: AlertState.escalated,
      escalatedAt: DateTime.now(),
      escalationCount: alert.escalationCount + 1,
      nextEscalationAt: alert.escalationCount + 1 < 3
          ? DateTime.now().add(_customizationSettings.repeatInterval)
          : null,
    );

    _activeAlerts[alert.taskId] = escalatedAlert;

    // Show full-screen alarm for critical alerts
    if (alert.level == AlertLevel.critical) {
      await _showFullScreenAlarm(task, escalatedAlert);
    } else {
      await _showEscalatedNotification(task, escalatedAlert);
    }

    debugPrint('SmartAlertEngine: Escalated alert ${alert.taskId} to ${escalatedAlert.state}');
  }

  Future<void> _showFullScreenAlarm(SchedulerTask task, SmartAlert alert) async {
    final payload = jsonEncode({
      'taskId': task.id,
      'alertLevel': alert.level.name,
      'isAlarm': true,
    });

    final notificationDetails = _notificationService.getNotificationDetails(
      alert.level,
      _customizationSettings,
    );

    await _notificationService.notifications.show(
      _generateNotificationId(task.id!, 'alarm'),
      task.title,
      _buildAlarmBody(task),
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> _showEscalatedNotification(SchedulerTask task, SmartAlert alert) async {
    final payload = jsonEncode({
      'taskId': task.id,
      'alertLevel': alert.level.name,
      'isAlarm': false,
    });

    final notificationDetails = _notificationService.getNotificationDetails(
      alert.level,
      _customizationSettings,
    );

    await _notificationService.notifications.show(
      _generateNotificationId(task.id!, 'escalated'),
      task.title,
      _buildEscalatedBody(task, alert.escalationCount),
      notificationDetails,
      payload: payload,
    );
  }

  String _buildAlarmBody(SchedulerTask task) {
    final buffer = StringBuffer();
    
    if (task.linkedOrderId != null) {
      buffer.write('Order #$task.linkedOrderId\n');
    }
    
    if (task.linkedCustomerId != null) {
      buffer.write('Customer ID: $task.linkedCustomerId\n');
    }
    
    buffer.write('Requires immediate attention');
    
    return buffer.toString().trim();
  }

  String _buildEscalatedBody(SchedulerTask task, int escalationCount) {
    final buffer = StringBuffer();
    buffer.write('Reminder #${escalationCount + 1}\n');
    
    if (task.linkedOrderId != null) {
      buffer.write('Order #$task.linkedOrderId\n');
    }
    
    buffer.write('Please address this task');
    
    return buffer.toString().trim();
  }

  Future<void> triggerAlert(SchedulerTask task) async {
    await initialize();

    // Safety checks
    if (task.status == TaskStatus.completed ||
        task.status == TaskStatus.cancelled) {
      debugPrint('SmartAlertEngine: Task ${task.id} is ${task.status}, skipping alert');
      return;
    }

    if (task.priority == TaskPriority.low || task.priority == TaskPriority.normal) {
      debugPrint('SmartAlertEngine: Task ${task.id} has low/normal priority, skipping alert');
      return;
    }

    final config = AlertConfig.fromPriority(task.priority);
    
    // Check quiet hours
    if (!_quietHoursConfig.shouldAllowAlert(config.level)) {
      debugPrint('SmartAlertEngine: Alert for task ${task.id} blocked by quiet hours');
      return;
    }

    // Check for duplicate alert
    if (_activeAlerts.containsKey(task.id)) {
      debugPrint('SmartAlertEngine: Alert already exists for task ${task.id}');
      return;
    }

    final alert = SmartAlert(
      taskId: task.id!,
      level: config.level,
      state: AlertState.pending,
      createdAt: DateTime.now(),
      nextEscalationAt: config.level == AlertLevel.critical
          ? DateTime.now().add(_customizationSettings.escalationDelay)
          : null,
    );

    _activeAlerts[task.id!] = alert;

    // For critical alerts, add to queue
    if (config.level == AlertLevel.critical) {
      final updatedQueue = AlertQueue(
        alerts: [..._alertQueue.alerts, alert],
        lastUpdated: DateTime.now(),
      );
      _alertQueue = updatedQueue;
    }

    // Show initial notification
    await _showInitialNotification(task, alert);

    debugPrint('SmartAlertEngine: Alert triggered for task ${task.id}');
  }

  Future<void> _showInitialNotification(SchedulerTask task, SmartAlert alert) async {
    final payload = jsonEncode({
      'taskId': task.id,
      'alertLevel': alert.level.name,
      'isAlarm': false,
    });

    final notificationDetails = _notificationService.getNotificationDetails(
      alert.level,
      _customizationSettings,
    );

    await _notificationService.notifications.show(
      _generateNotificationId(task.id!, 'initial'),
      task.title,
      _buildInitialBody(task),
      notificationDetails,
      payload: payload,
    );
  }

  String _buildInitialBody(SchedulerTask task) {
    if (task.linkedOrderId != null) {
      return 'Order #$task.linkedOrderId';
    }
    return task.notes?.trim().isNotEmpty == true
        ? task.notes!
        : 'Scheduled for ${task.effectiveReminderAt.hour.toString().padLeft(2, '0')}:${task.effectiveReminderAt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> acknowledgeAlert(int taskId) async {
    final alert = _activeAlerts[taskId];
    if (alert == null) return;

    final acknowledgedAlert = alert.copyWith(
      state: AlertState.acknowledged,
      acknowledgedAt: DateTime.now(),
    );

    _activeAlerts[taskId] = acknowledgedAlert;

    // Cancel all notifications for this task
    await _cancelAllNotificationsForTask(taskId);

    // Remove from queue if present
    await _removeFromQueue(taskId);

    debugPrint('SmartAlertEngine: Alert acknowledged for task $taskId');
  }

  Future<void> completeAlert(int taskId) async {
    await acknowledgeAlert(taskId);
    
    final alert = _activeAlerts[taskId];
    if (alert != null) {
      final completedAlert = alert.copyWith(
        state: AlertState.completed,
      );
      _activeAlerts[taskId] = completedAlert;
    }

    // Mark task as completed in repository
    await _repository.updateReminderState(
      taskId: taskId,
      status: TaskStatus.completed,
      completedAt: DateTime.now(),
      nextReminderAt: null,
    );

    debugPrint('SmartAlertEngine: Alert completed for task $taskId');
  }

  Future<void> snoozeAlert(int taskId, Duration duration) async {
    final alert = _activeAlerts[taskId];
    if (alert == null) return;

    if (!alert.canSnooze) {
      debugPrint('SmartAlertEngine: Maximum snooze limit reached for task $taskId');
      return;
    }

    final snoozedAlert = alert.copyWith(
      state: AlertState.snoozed,
      snoozeCount: alert.snoozeCount + 1,
    );

    _activeAlerts[taskId] = snoozedAlert;

    // Cancel all notifications for this task
    await _cancelAllNotificationsForTask(taskId);

    // Remove from queue if present
    await _removeFromQueue(taskId);

    // Reschedule task
    final nextReminder = DateTime.now().add(duration);
    await _repository.updateReminderState(
      taskId: taskId,
      nextReminderAt: nextReminder,
      status: TaskStatus.pending,
    );

    debugPrint('SmartAlertEngine: Alert snoozed for task $taskId until $nextReminder');
  }

  Future<void> dismissAlert(int taskId) async {
    final alert = _activeAlerts[taskId];
    if (alert == null) return;

    final dismissedAlert = alert.copyWith(
      state: AlertState.dismissed,
      dismissedAt: DateTime.now(),
    );

    _activeAlerts[taskId] = dismissedAlert;

    // Cancel all notifications for this task
    await _cancelAllNotificationsForTask(taskId);

    // Remove from queue if present
    await _removeFromQueue(taskId);

    debugPrint('SmartAlertEngine: Alert dismissed for task $taskId');
  }

  Future<void> _cancelAllNotificationsForTask(int taskId) async {
    final notifications = _notificationService.notifications;
    await notifications.cancel(_generateNotificationId(taskId, 'initial'));
    await notifications.cancel(_generateNotificationId(taskId, 'escalated'));
    await notifications.cancel(_generateNotificationId(taskId, 'alarm'));
  }

  Future<void> _removeFromQueue(int taskId) async {
    final updatedAlerts = _alertQueue.alerts.where((a) => a.taskId != taskId).toList();
    _alertQueue = AlertQueue(
      alerts: updatedAlerts,
      lastUpdated: DateTime.now(),
    );
  }

  Future<void> _advanceQueue() async {
    if (_alertQueue.alerts.isEmpty) return;

    final updatedAlerts = _alertQueue.alerts.skip(1).toList();
    _alertQueue = AlertQueue(
      alerts: updatedAlerts,
      lastUpdated: DateTime.now(),
    );

    if (_alertQueue.current != null) {
      final task = await _repository.getTask(_alertQueue.current!.taskId);
      if (task != null) {
        await _showFullScreenAlarm(task, _alertQueue.current!);
      }
    }
  }

  Future<void> handleNotificationResponse(NotificationResponse response) async {
    final payload = response.payload;
    if (payload == null || payload.trim().isEmpty) return;

    final decoded = jsonDecode(payload) as Map<String, dynamic>;
    final taskId = decoded['taskId'] as int?;
    if (taskId == null) return;

    switch (response.actionId) {
      case _alertActionAcknowledge:
        await acknowledgeAlert(taskId);
        break;
      case _alertActionComplete:
        await completeAlert(taskId);
        break;
      case _alertActionSnooze5:
        await snoozeAlert(taskId, const Duration(minutes: 5));
        break;
      case _alertActionSnooze10:
        await snoozeAlert(taskId, const Duration(minutes: 10));
        break;
      case _alertActionSnooze15:
        await snoozeAlert(taskId, const Duration(minutes: 15));
        break;
      case _alertActionDismiss:
        await dismissAlert(taskId);
        break;
      case _alertActionOpenOrder:
        await acknowledgeAlert(taskId);
        // TODO: Navigate to order screen
        break;
      case _alertActionNavigate:
        await acknowledgeAlert(taskId);
        // TODO: Open navigation
        break;
      case _alertActionCallCustomer:
        await acknowledgeAlert(taskId);
        // TODO: Call customer
        break;
      case _alertActionCallDriver:
        await acknowledgeAlert(taskId);
        // TODO: Call driver
        break;
      default:
        // Default action is acknowledge
        await acknowledgeAlert(taskId);
        break;
    }
  }

  int _generateNotificationId(int taskId, String type) {
    final typeHash = type.hashCode;
    return (taskId * 1000) + (typeHash % 1000);
  }

  AlertQueue get alertQueue => _alertQueue;
  QuietHoursConfig get quietHoursConfig => _quietHoursConfig;
  AlertCustomizationSettings get customizationSettings => _customizationSettings;

  void dispose() {
    _escalationTimer?.cancel();
    _queueProcessingTimer?.cancel();
  }
}
