enum TaskProducer {
  walkIn,
  orders,
  inventory,
  customers,
  designs,
  staff,
  system,
  erp,
  manual,
}

enum TaskType {
  delivery,
  pickup,
  appointment,
  meeting,
  purchase,
  reminder,
  personalTask,
}

enum TaskCategory {
  operational,
  reminder,
  sales,
  inventory,
  delivery,
  administration,
}

enum TaskPriority {
  low,
  normal,
  high,
  urgent,
}

enum TaskStatus {
  pending,
  inProgress,
  completed,
  cancelled,
  deferred,
}

class SchedulerTask {
  final int? id;
  final String title;
  final TaskType type;
  final TaskCategory category;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime scheduledAt;
  final DateTime? nextReminderAt;
  final DateTime? deadlineAt;
  final String? notes;
  final int? linkedCustomerId;
  final int? linkedOrderId;
  final int? assignedStaffId;
  final TaskProducer producer;
  final String? sourceRef;
  final bool requiresConfirmation;
  final bool requiresAlarm;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SchedulerTask({
    this.id,
    required this.title,
    required this.type,
    required this.category,
    required this.priority,
    required this.status,
    required this.scheduledAt,
    this.nextReminderAt,
    this.deadlineAt,
    this.notes,
    this.linkedCustomerId,
    this.linkedOrderId,
    this.assignedStaffId,
    required this.producer,
    this.sourceRef,
    this.requiresConfirmation = false,
    this.requiresAlarm = false,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  DateTime get effectiveReminderAt => nextReminderAt ?? scheduledAt;

  bool get isOverdue =>
      status != TaskStatus.completed &&
      status != TaskStatus.cancelled &&
      effectiveReminderAt.isBefore(DateTime.now());
}

class SchedulerTodaySummary {
  final int pending;
  final int completed;
  final int overdue;
  final int urgent;
  final int todayDeliveries;
  final int todayPickups;

  const SchedulerTodaySummary({
    required this.pending,
    required this.completed,
    required this.overdue,
    required this.urgent,
    required this.todayDeliveries,
    required this.todayPickups,
  });
}

class PublishTaskCommand {
  final String title;
  final TaskType type;
  final TaskCategory category;
  final TaskPriority priority;
  final DateTime scheduledAt;
  final DateTime? deadlineAt;
  final String? notes;
  final int? linkedCustomerId;
  final int? linkedOrderId;
  final int? assignedStaffId;
  final TaskProducer producer;
  final String? sourceRef;
  final bool requiresConfirmation;
  final bool requiresAlarm;

  const PublishTaskCommand({
    required this.title,
    required this.type,
    required this.category,
    this.priority = TaskPriority.normal,
    required this.scheduledAt,
    this.deadlineAt,
    this.notes,
    this.linkedCustomerId,
    this.linkedOrderId,
    this.assignedStaffId,
    required this.producer,
    this.sourceRef,
    this.requiresConfirmation = false,
    this.requiresAlarm = false,
  });
}

class SchedulerDashboardBuckets {
  const SchedulerDashboardBuckets({
    required this.overdue,
    required this.dueSoon,
    required this.completed,
  });

  final List<SchedulerTask> overdue;
  final List<SchedulerTask> dueSoon;
  final List<SchedulerTask> completed;
}
