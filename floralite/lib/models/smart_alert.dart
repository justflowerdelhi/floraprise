import 'scheduler_task.dart';
import 'package:flutter/material.dart';

enum AlertLevel {
  info,
  reminder,
  important,
  critical,
}

enum AlertState {
  pending,
  escalated,
  acknowledged,
  completed,
  snoozed,
  dismissed,
}

class AlertConfig {
  final AlertLevel level;
  final bool silent;
  final bool playSound;
  final bool vibrate;
  final bool persistent;
  final bool fullScreen;
  final bool wakeScreen;
  final bool keepScreenOn;
  final String? soundPath;
  final VibrationPattern vibrationPattern;

  const AlertConfig({
    required this.level,
    this.silent = false,
    this.playSound = true,
    this.vibrate = true,
    this.persistent = false,
    this.fullScreen = false,
    this.wakeScreen = false,
    this.keepScreenOn = false,
    this.soundPath,
    this.vibrationPattern = VibrationPattern.normal,
  });

  static AlertConfig fromPriority(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return const AlertConfig(
          level: AlertLevel.info,
          silent: true,
          playSound: false,
          vibrate: false,
        );
      case TaskPriority.normal:
        return const AlertConfig(
          level: AlertLevel.reminder,
          playSound: true,
          vibrate: true,
          vibrationPattern: VibrationPattern.small,
        );
      case TaskPriority.high:
        return const AlertConfig(
          level: AlertLevel.important,
          playSound: true,
          vibrate: true,
          persistent: true,
          vibrationPattern: VibrationPattern.long,
        );
      case TaskPriority.urgent:
        return const AlertConfig(
          level: AlertLevel.critical,
          playSound: true,
          vibrate: true,
          persistent: true,
          fullScreen: true,
          wakeScreen: true,
          keepScreenOn: true,
          vibrationPattern: VibrationPattern.repeating,
        );
    }
  }
}

enum VibrationPattern {
  none,
  small,
  normal,
  long,
  repeating,
}

class SmartAlert {
  final int taskId;
  final AlertLevel level;
  final AlertState state;
  final DateTime createdAt;
  final DateTime? escalatedAt;
  final DateTime? acknowledgedAt;
  final DateTime? dismissedAt;
  final int snoozeCount;
  final DateTime? nextEscalationAt;
  final int escalationCount;
  final bool isQueued;

  const SmartAlert({
    required this.taskId,
    required this.level,
    required this.state,
    required this.createdAt,
    this.escalatedAt,
    this.acknowledgedAt,
    this.dismissedAt,
    this.snoozeCount = 0,
    this.nextEscalationAt,
    this.escalationCount = 0,
    this.isQueued = false,
  });

  SmartAlert copyWith({
    AlertLevel? level,
    AlertState? state,
    DateTime? createdAt,
    DateTime? escalatedAt,
    DateTime? acknowledgedAt,
    DateTime? dismissedAt,
    int? snoozeCount,
    DateTime? nextEscalationAt,
    int? escalationCount,
    bool? isQueued,
  }) {
    return SmartAlert(
      taskId: taskId,
      level: level ?? this.level,
      state: state ?? this.state,
      createdAt: createdAt ?? this.createdAt,
      escalatedAt: escalatedAt ?? this.escalatedAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      dismissedAt: dismissedAt ?? this.dismissedAt,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      nextEscalationAt: nextEscalationAt ?? this.nextEscalationAt,
      escalationCount: escalationCount ?? this.escalationCount,
      isQueued: isQueued ?? this.isQueued,
    );
  }

  bool get canSnooze => snoozeCount < 3;
  bool get canEscalate => escalationCount < 3;
  bool get isActive => state == AlertState.pending || state == AlertState.escalated;
}

class AlertQueue {
  final List<SmartAlert> alerts;
  final DateTime lastUpdated;

  const AlertQueue({
    required this.alerts,
    required this.lastUpdated,
  });

  int get count => alerts.length;
  SmartAlert? get current => alerts.isNotEmpty ? alerts.first : null;
  List<SmartAlert> get pending => alerts.where((a) => a.isActive).toList();

  AlertQueue copyWith({
    List<SmartAlert>? alerts,
    DateTime? lastUpdated,
  }) {
    return AlertQueue(
      alerts: alerts ?? this.alerts,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class QuietHoursConfig {
  final bool enabled;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool bypassCritical;

  const QuietHoursConfig({
    this.enabled = false,
    this.startTime = const TimeOfDay(hour: 23, minute: 0),
    this.endTime = const TimeOfDay(hour: 7, minute: 0),
    this.bypassCritical = true,
  });

  bool isInQuietHours(DateTime now) {
    if (!enabled) return false;
    
    final current = TimeOfDay(hour: now.hour, minute: now.minute);
    
    if (startTime.hour < endTime.hour) {
      // Same day range (e.g., 23:00 to 07:00 doesn't cross midnight)
      return current.hour >= startTime.hour && current.hour < endTime.hour;
    } else {
      // Crosses midnight (e.g., 23:00 to 07:00)
      return current.hour >= startTime.hour || current.hour < endTime.hour;
    }
  }

  bool shouldAllowAlert(AlertLevel level) {
    if (!enabled) return true;
    if (bypassCritical && level == AlertLevel.critical) return true;
    return !isInQuietHours(DateTime.now());
  }

  QuietHoursConfig copyWith({
    bool? enabled,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? bypassCritical,
  }) {
    return QuietHoursConfig(
      enabled: enabled ?? this.enabled,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      bypassCritical: bypassCritical ?? this.bypassCritical,
    );
  }
}

class AlertCustomizationSettings {
  final String notificationSound;
  final String alarmSound;
  final bool vibrationEnabled;
  final double alarmVolume;
  final Duration repeatInterval;
  final Duration escalationDelay;

  const AlertCustomizationSettings({
    this.notificationSound = 'default',
    this.alarmSound = 'alarm',
    this.vibrationEnabled = true,
    this.alarmVolume = 0.8,
    this.repeatInterval = const Duration(minutes: 5),
    this.escalationDelay = const Duration(seconds: 30),
  });

  AlertCustomizationSettings copyWith({
    String? notificationSound,
    String? alarmSound,
    bool? vibrationEnabled,
    double? alarmVolume,
    Duration? repeatInterval,
    Duration? escalationDelay,
  }) {
    return AlertCustomizationSettings(
      notificationSound: notificationSound ?? this.notificationSound,
      alarmSound: alarmSound ?? this.alarmSound,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      alarmVolume: alarmVolume ?? this.alarmVolume,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      escalationDelay: escalationDelay ?? this.escalationDelay,
    );
  }
}
