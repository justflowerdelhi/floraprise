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
  final String? cloudId;
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
  final String? cloudLinkedCustomerId;
  final int? linkedOrderId;
  final String? cloudLinkedOrderId;
  final int? assignedStaffId;
  final String? cloudAssignedStaffId;
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
    this.cloudId,
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
    this.cloudLinkedCustomerId,
    this.linkedOrderId,
    this.cloudLinkedOrderId,
    this.assignedStaffId,
    this.cloudAssignedStaffId,
    required this.producer,
    this.sourceRef,
    this.requiresConfirmation = false,
    this.requiresAlarm = false,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SchedulerTask.fromCloudJson(Map<String, dynamic> json) {
    final idStr = (json['id'] ?? json['Id'])?.toString() ?? '';
    final custIdStr = (json['linkedCustomerId'] ?? json['LinkedCustomerId'])?.toString();
    final orderIdStr = (json['linkedOrderId'] ?? json['LinkedOrderId'])?.toString();
    final staffIdStr = (json['assignedStaffId'] ?? json['AssignedStaffId'])?.toString();

    final typeStr = (json['type'] ?? json['Type'])?.toString() ?? 'reminder';
    final catStr = (json['category'] ?? json['Category'])?.toString() ?? 'operational';
    final prioStr = (json['priority'] ?? json['Priority'])?.toString() ?? 'normal';
    final statStr = (json['status'] ?? json['Status'])?.toString() ?? 'pending';
    final prodStr = (json['producer'] ?? json['Producer'])?.toString() ?? 'manual';

    final schedStr = (json['scheduledAt'] ?? json['ScheduledAt'])?.toString() ?? '';
    final reminderStr = (json['nextReminderAt'] ?? json['NextReminderAt'])?.toString();
    final deadStr = (json['deadlineAt'] ?? json['DeadlineAt'])?.toString();
    final startStr = (json['startedAt'] ?? json['StartedAt'])?.toString();
    final compStr = (json['completedAt'] ?? json['CompletedAt'])?.toString();
    final createdStr = (json['createdAtUtc'] ?? json['CreatedAtUtc'])?.toString() ?? '';
    final updatedStr = (json['updatedAtUtc'] ?? json['UpdatedAtUtc'])?.toString() ?? '';

    return SchedulerTask(
      id: int.tryParse(idStr) ?? idStr.hashCode,
      cloudId: idStr,
      title: (json['title'] ?? json['Title'])?.toString() ?? '',
      type: TaskType.values.firstWhere(
        (e) => e.name.toLowerCase() == typeStr.toLowerCase(),
        orElse: () => TaskType.reminder,
      ),
      category: TaskCategory.values.firstWhere(
        (e) => e.name.toLowerCase() == catStr.toLowerCase(),
        orElse: () => TaskCategory.operational,
      ),
      priority: TaskPriority.values.firstWhere(
        (e) => e.name.toLowerCase() == prioStr.toLowerCase(),
        orElse: () => TaskPriority.normal,
      ),
      status: TaskStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == statStr.toLowerCase(),
        orElse: () => TaskStatus.pending,
      ),
      scheduledAt: DateTime.tryParse(schedStr) ?? DateTime.now(),
      nextReminderAt: reminderStr != null ? DateTime.tryParse(reminderStr) : null,
      deadlineAt: deadStr != null ? DateTime.tryParse(deadStr) : null,
      startedAt: startStr != null ? DateTime.tryParse(startStr) : null,
      completedAt: compStr != null ? DateTime.tryParse(compStr) : null,
      notes: (json['notes'] ?? json['Notes'])?.toString(),
      linkedCustomerId: custIdStr != null ? (int.tryParse(custIdStr) ?? custIdStr.hashCode) : null,
      cloudLinkedCustomerId: custIdStr,
      linkedOrderId: orderIdStr != null ? (int.tryParse(orderIdStr) ?? orderIdStr.hashCode) : null,
      cloudLinkedOrderId: orderIdStr,
      assignedStaffId: staffIdStr != null ? (int.tryParse(staffIdStr) ?? staffIdStr.hashCode) : null,
      cloudAssignedStaffId: staffIdStr,
      producer: TaskProducer.values.firstWhere(
        (e) => e.name.toLowerCase() == prodStr.toLowerCase(),
        orElse: () => TaskProducer.manual,
      ),
      sourceRef: (json['sourceRef'] ?? json['SourceRef'])?.toString(),
      requiresConfirmation: (json['requiresConfirmation'] ?? json['RequiresConfirmation']) == true,
      requiresAlarm: (json['requiresAlarm'] ?? json['RequiresAlarm']) == true,
      createdAt: DateTime.tryParse(createdStr) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(updatedStr) ?? DateTime.now(),
    );
  }

  DateTime get effectiveReminderAt => nextReminderAt ?? scheduledAt;

  bool get isOverdue =>
      status != TaskStatus.completed &&
      status != TaskStatus.cancelled &&
      effectiveReminderAt.isBefore(DateTime.now());

  SchedulerTask copyWith({
    int? id,
    String? cloudId,
    String? title,
    TaskType? type,
    TaskCategory? category,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? scheduledAt,
    DateTime? nextReminderAt,
    DateTime? deadlineAt,
    String? notes,
    int? linkedCustomerId,
    String? cloudLinkedCustomerId,
    int? linkedOrderId,
    String? cloudLinkedOrderId,
    int? assignedStaffId,
    String? cloudAssignedStaffId,
    TaskProducer? producer,
    String? sourceRef,
    bool? requiresConfirmation,
    bool? requiresAlarm,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SchedulerTask(
      id: id ?? this.id,
      cloudId: cloudId ?? this.cloudId,
      title: title ?? this.title,
      type: type ?? this.type,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      nextReminderAt: nextReminderAt ?? this.nextReminderAt,
      deadlineAt: deadlineAt ?? this.deadlineAt,
      notes: notes ?? this.notes,
      linkedCustomerId: linkedCustomerId ?? this.linkedCustomerId,
      cloudLinkedCustomerId: cloudLinkedCustomerId ?? this.cloudLinkedCustomerId,
      linkedOrderId: linkedOrderId ?? this.linkedOrderId,
      cloudLinkedOrderId: cloudLinkedOrderId ?? this.cloudLinkedOrderId,
      assignedStaffId: assignedStaffId ?? this.assignedStaffId,
      cloudAssignedStaffId: cloudAssignedStaffId ?? this.cloudAssignedStaffId,
      producer: producer ?? this.producer,
      sourceRef: sourceRef ?? this.sourceRef,
      requiresConfirmation: requiresConfirmation ?? this.requiresConfirmation,
      requiresAlarm: requiresAlarm ?? this.requiresAlarm,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
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
