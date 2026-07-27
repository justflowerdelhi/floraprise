import '../database/app_database.dart';
import '../../models/scheduler_task.dart';

class SchedulerRepository {
  static const activeStatuses = ['pending', 'inProgress', 'deferred'];

  String _enumName(Object value) {
    return value.toString().split('.').last;
  }

  String get _effectiveReminderSql =>
      'COALESCE(next_reminder_at, scheduled_at)';

  TaskType _taskTypeFromDb(String value) {
    return TaskType.values.firstWhere(
      (item) => _enumName(item) == value,
      orElse: () => TaskType.reminder,
    );
  }

  TaskCategory _taskCategoryFromDb(String value) {
    return TaskCategory.values.firstWhere(
      (item) => _enumName(item) == value,
      orElse: () => TaskCategory.operational,
    );
  }

  TaskPriority _taskPriorityFromDb(String value) {
    return TaskPriority.values.firstWhere(
      (item) => _enumName(item) == value,
      orElse: () => TaskPriority.normal,
    );
  }

  TaskStatus _taskStatusFromDb(String value) {
    return TaskStatus.values.firstWhere(
      (item) => _enumName(item) == value,
      orElse: () => TaskStatus.pending,
    );
  }

  TaskProducer _taskProducerFromDb(String value) {
    return TaskProducer.values.firstWhere(
      (item) => _enumName(item) == value,
      orElse: () => TaskProducer.system,
    );
  }

  SchedulerTask _toTask(Map<String, Object?> row) {
    return SchedulerTask(
      id: row['id'] as int,
      title: row['title'] as String,
      type: _taskTypeFromDb(row['type'] as String),
      category: _taskCategoryFromDb(row['category'] as String),
      priority: _taskPriorityFromDb(row['priority'] as String),
      status: _taskStatusFromDb(row['status'] as String),
      scheduledAt: DateTime.parse(row['scheduled_at'] as String),
      nextReminderAt: row['next_reminder_at'] == null
          ? null
          : DateTime.parse(row['next_reminder_at'] as String),
      deadlineAt: row['deadline_at'] == null
          ? null
          : DateTime.parse(row['deadline_at'] as String),
      notes: row['notes'] as String?,
      linkedCustomerId: row['linked_customer_id'] as int?,
      linkedOrderId: row['linked_order_id'] as int?,
      assignedStaffId: row['assigned_staff_id'] as int?,
      producer: _taskProducerFromDb(row['producer'] as String),
      sourceRef: row['source_ref'] as String?,
      requiresConfirmation: (row['requires_confirmation'] as int) == 1,
      requiresAlarm: (row['requires_alarm'] as int? ?? 0) == 1,
      startedAt: row['started_at'] == null
          ? null
          : DateTime.parse(row['started_at'] as String),
      completedAt: row['completed_at'] == null
          ? null
          : DateTime.parse(row['completed_at'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  Future<int> publishTask(SchedulerTask task) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    if (task.sourceRef != null && task.sourceRef!.isNotEmpty) {
      final existing = await db.query(
        'scheduler_tasks',
        columns: ['id'],
        where: 'producer = ? AND source_ref = ? AND deleted_at IS NULL',
        whereArgs: [_enumName(task.producer), task.sourceRef],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        final taskId = existing.first['id'] as int;
        await db.update(
          'scheduler_tasks',
          {
            'title': task.title,
            'type': _enumName(task.type),
            'category': _enumName(task.category),
            'priority': _enumName(task.priority),
            'status': _enumName(task.status),
            'scheduled_at': task.scheduledAt.toIso8601String(),
            'deadline_at': task.deadlineAt?.toIso8601String(),
            'notes': task.notes,
            'linked_customer_id': task.linkedCustomerId,
            'linked_order_id': task.linkedOrderId,
            'assigned_staff_id': task.assignedStaffId,
            'requires_confirmation': task.requiresConfirmation ? 1 : 0,
            'requires_alarm': task.requiresAlarm ? 1 : 0,
            'next_reminder_at': task.nextReminderAt?.toIso8601String(),
            'updated_at': now,
            'deleted_at': null,
          },
          where: 'id = ?',
          whereArgs: [taskId],
        );
        return taskId;
      }
    }

    return db.insert('scheduler_tasks', {
      'title': task.title,
      'type': _enumName(task.type),
      'category': _enumName(task.category),
      'priority': _enumName(task.priority),
      'status': _enumName(task.status),
      'scheduled_at': task.scheduledAt.toIso8601String(),
      'deadline_at': task.deadlineAt?.toIso8601String(),
      'notes': task.notes,
      'linked_customer_id': task.linkedCustomerId,
      'linked_order_id': task.linkedOrderId,
      'assigned_staff_id': task.assignedStaffId,
      'producer': _enumName(task.producer),
      'source_ref': task.sourceRef,
      'requires_confirmation': task.requiresConfirmation ? 1 : 0,
      'requires_alarm': task.requiresAlarm ? 1 : 0,
      'next_reminder_at': task.nextReminderAt?.toIso8601String(),
      'started_at': task.startedAt?.toIso8601String(),
      'completed_at': task.completedAt?.toIso8601String(),
      'created_at': task.createdAt.toIso8601String(),
      'updated_at': task.updatedAt.toIso8601String(),
      'deleted_at': null,
    });
  }

  Future<void> enqueueLocalNotificationJob({
    required int taskId,
    required String action,
    required DateTime runAt,
    String? payloadJson,
  }) async {
    final db = await AppDatabase.instance.database;
    await db.insert('scheduler_notification_jobs', {
      'task_id': taskId,
      'action': action,
      'run_at': runAt.toIso8601String(),
      'status': 'pending',
      'payload_json': payloadJson,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> replaceNotificationJobs({
    required int taskId,
    required List<({String action, DateTime runAt, String? payloadJson})> jobs,
  }) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      'scheduler_notification_jobs',
      where: 'task_id = ?',
      whereArgs: [taskId],
    );
    for (final job in jobs) {
      await db.insert('scheduler_notification_jobs', {
        'task_id': taskId,
        'action': job.action,
        'run_at': job.runAt.toIso8601String(),
        'status': 'pending',
        'payload_json': job.payloadJson,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> clearNotificationJobs(int taskId) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      'scheduler_notification_jobs',
      where: 'task_id = ?',
      whereArgs: [taskId],
    );
  }

  Future<SchedulerTask?> getTask(int taskId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'scheduler_tasks',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [taskId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _toTask(rows.first);
  }

  Future<List<SchedulerTask>> listActiveTasks() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'scheduler_tasks',
      where: 'deleted_at IS NULL AND status IN (?, ?, ?)',
      whereArgs: activeStatuses,
      orderBy: 'COALESCE(next_reminder_at, scheduled_at) ASC, created_at ASC',
    );
    return rows.map(_toTask).toList();
  }

  Future<List<SchedulerTask>> getOperationalQueue({
    required DateTime selectedDate,
    String? searchQuery,
  }) async {
    final db = await AppDatabase.instance.database;
    final dayStart =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final now = DateTime.now().toIso8601String();

    final query = (searchQuery ?? '').trim();

    final baseSql = StringBuffer()
      ..writeln('SELECT t.* FROM scheduler_tasks t')
      ..writeln('LEFT JOIN customers c ON c.id = t.linked_customer_id')
      ..writeln('WHERE t.deleted_at IS NULL')
      ..writeln("AND t.status IN ('pending', 'inProgress', 'deferred')")
      ..writeln('AND (')
      ..writeln(
          '  ($_effectiveReminderSql >= ? AND $_effectiveReminderSql < ?)')
      ..writeln('  OR')
      ..writeln('  ($_effectiveReminderSql < ?)')
      ..writeln(')');

    final args = <Object?>[
      dayStart.toIso8601String(),
      dayEnd.toIso8601String(),
      dayStart.toIso8601String(),
    ];

    if (query.isNotEmpty) {
      baseSql.writeln('AND (');
      baseSql.writeln('  LOWER(t.title) LIKE ? OR');
      baseSql.writeln('  LOWER(COALESCE(t.notes, "")) LIKE ? OR');
      baseSql.writeln('  LOWER(COALESCE(c.phone, "")) LIKE ?');
      baseSql.writeln(')');
      final like = '%${query.toLowerCase()}%';
      args.addAll([like, like, like]);
    }

    baseSql.writeln('ORDER BY');
    baseSql.writeln(
        '  CASE WHEN t.deadline_at IS NOT NULL AND t.deadline_at < ? THEN 0 ELSE 1 END,');
    baseSql.writeln(
        "  CASE t.priority WHEN 'urgent' THEN 0 WHEN 'high' THEN 1 WHEN 'normal' THEN 2 ELSE 3 END,");
    baseSql.writeln('  $_effectiveReminderSql ASC,');
    baseSql.writeln('  t.created_at ASC');
    args.add(now);

    final rows = await db.rawQuery(baseSql.toString(), args);
    return rows.map(_toTask).toList();
  }

  Future<List<SchedulerTask>> getTodayScheduledTasks(DateTime date) async {
    final db = await AppDatabase.instance.database;
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final rows = await db.query(
      'scheduler_tasks',
      where:
          'deleted_at IS NULL AND status IN (?, ?, ?) AND $_effectiveReminderSql >= ? AND $_effectiveReminderSql < ?',
      whereArgs: [
        _enumName(TaskStatus.pending),
        _enumName(TaskStatus.inProgress),
        _enumName(TaskStatus.deferred),
        dayStart.toIso8601String(),
        dayEnd.toIso8601String(),
      ],
      orderBy:
          "CASE priority WHEN 'urgent' THEN 0 WHEN 'high' THEN 1 WHEN 'normal' THEN 2 ELSE 3 END, $_effectiveReminderSql ASC, created_at ASC",
    );
    return rows.map(_toTask).toList();
  }

  Future<SchedulerDashboardBuckets> getDashboardBuckets({
    DateTime? now,
    Duration dueSoonWindow = const Duration(hours: 2),
  }) async {
    final db = await AppDatabase.instance.database;
    final current = now ?? DateTime.now();
    final currentIso = current.toIso8601String();
    final soonIso = current.add(dueSoonWindow).toIso8601String();
    final dayStart = DateTime(current.year, current.month, current.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final overdueRows = await db.query(
      'scheduler_tasks',
      where:
          'deleted_at IS NULL AND status IN (?, ?, ?) AND $_effectiveReminderSql < ?',
      whereArgs: [
        _enumName(TaskStatus.pending),
        _enumName(TaskStatus.inProgress),
        _enumName(TaskStatus.deferred),
        currentIso,
      ],
      orderBy:
          "CASE priority WHEN 'urgent' THEN 0 WHEN 'high' THEN 1 WHEN 'normal' THEN 2 ELSE 3 END, $_effectiveReminderSql ASC",
      limit: 5,
    );

    final dueSoonRows = await db.query(
      'scheduler_tasks',
      where:
          'deleted_at IS NULL AND status IN (?, ?, ?) AND $_effectiveReminderSql >= ? AND $_effectiveReminderSql <= ?',
      whereArgs: [
        _enumName(TaskStatus.pending),
        _enumName(TaskStatus.inProgress),
        _enumName(TaskStatus.deferred),
        currentIso,
        soonIso,
      ],
      orderBy:
          "CASE priority WHEN 'urgent' THEN 0 WHEN 'high' THEN 1 WHEN 'normal' THEN 2 ELSE 3 END, $_effectiveReminderSql ASC",
      limit: 5,
    );

    final completedRows = await db.query(
      'scheduler_tasks',
      where:
          'deleted_at IS NULL AND status = ? AND completed_at >= ? AND completed_at < ?',
      whereArgs: [
        _enumName(TaskStatus.completed),
        dayStart.toIso8601String(),
        dayEnd.toIso8601String(),
      ],
      orderBy: 'completed_at DESC',
      limit: 5,
    );

    return SchedulerDashboardBuckets(
      overdue: overdueRows.map(_toTask).toList(),
      dueSoon: dueSoonRows.map(_toTask).toList(),
      completed: completedRows.map(_toTask).toList(),
    );
  }

  Future<List<SchedulerTask>> getHistory({
    required int limit,
    required int offset,
  }) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'scheduler_tasks',
      where: 'deleted_at IS NULL',
      orderBy: 'scheduled_at DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map(_toTask).toList();
  }

  Future<List<SchedulerTask>> getCompleted({
    DateTime? start,
    DateTime? end,
  }) async {
    final db = await AppDatabase.instance.database;
    String where = 'deleted_at IS NULL AND status = ?';
    final whereArgs = <Object?>['completed'];

    if (start != null) {
      where += ' AND completed_at >= ?';
      whereArgs.add(start.toIso8601String());
    }

    if (end != null) {
      where += ' AND completed_at <= ?';
      whereArgs.add(end.toIso8601String());
    }

    final rows = await db.query(
      'scheduler_tasks',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'completed_at DESC',
    );
    return rows.map(_toTask).toList();
  }

  Future<void> updateTaskStatus(int taskId, TaskStatus status) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'scheduler_tasks',
      {
        'status': _enumName(status),
        'started_at': status == TaskStatus.inProgress ? now : null,
        'completed_at': status == TaskStatus.completed ? now : null,
        'next_reminder_at': status == TaskStatus.completed ? null : null,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<void> updateTask({
    required int taskId,
    required String title,
    required TaskPriority priority,
    required DateTime scheduledAt,
    bool? requiresAlarm,
    String? notes,
  }) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'scheduler_tasks',
      {
        'title': title.trim(),
        'priority': _enumName(priority),
        'scheduled_at': scheduledAt.toIso8601String(),
        'next_reminder_at': null,
        if (requiresAlarm != null) 'requires_alarm': requiresAlarm ? 1 : 0,
        'notes': notes?.trim().isEmpty ?? true ? null : notes!.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [taskId],
    );
  }

  Future<void> updateReminderState({
    required int taskId,
    DateTime? scheduledAt,
    DateTime? nextReminderAt,
    bool? requiresAlarm,
    TaskStatus? status,
    DateTime? completedAt,
  }) async {
    final db = await AppDatabase.instance.database;
    final values = <String, Object?>{
      'updated_at': DateTime.now().toIso8601String(),
      if (scheduledAt != null) 'scheduled_at': scheduledAt.toIso8601String(),
      'next_reminder_at': nextReminderAt?.toIso8601String(),
      if (requiresAlarm != null) 'requires_alarm': requiresAlarm ? 1 : 0,
      if (status != null) 'status': _enumName(status),
      if (completedAt != null) 'completed_at': completedAt.toIso8601String(),
    };
    await db.update(
      'scheduler_tasks',
      values,
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [taskId],
    );
  }

  Future<void> softDeleteTask(int taskId) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'scheduler_tasks',
      {
        'deleted_at': now,
        'updated_at': now,
      },
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [taskId],
    );
  }

  Future<SchedulerTodaySummary> getTodaySummary() async {
    final db = await AppDatabase.instance.database;
    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final nowIso = DateTime.now().toIso8601String();

    Future<int> scalar(String sql, List<Object?> args) async {
      final rows = await db.rawQuery(sql, args);
      return (rows.first['count_value'] as int?) ?? 0;
    }

    final pending = await scalar(
      'SELECT COUNT(*) AS count_value FROM scheduler_tasks WHERE deleted_at IS NULL AND status IN (\'pending\', \'inProgress\', \'deferred\')',
      const [],
    );

    final completed = await scalar(
      'SELECT COUNT(*) AS count_value FROM scheduler_tasks WHERE deleted_at IS NULL AND status = \'completed\' AND completed_at >= ? AND completed_at < ?',
      [dayStart.toIso8601String(), dayEnd.toIso8601String()],
    );

    final overdue = await scalar(
      'SELECT COUNT(*) AS count_value FROM scheduler_tasks WHERE deleted_at IS NULL AND status IN (\'pending\', \'inProgress\', \'deferred\') AND $_effectiveReminderSql < ?',
      [nowIso],
    );

    final urgent = await scalar(
      'SELECT COUNT(*) AS count_value FROM scheduler_tasks WHERE deleted_at IS NULL AND status IN (\'pending\', \'inProgress\', \'deferred\') AND priority = \'urgent\'',
      const [],
    );

    final deliveries = await scalar(
      'SELECT COUNT(*) AS count_value FROM scheduler_tasks WHERE deleted_at IS NULL AND type = \'delivery\' AND $_effectiveReminderSql >= ? AND $_effectiveReminderSql < ?',
      [dayStart.toIso8601String(), dayEnd.toIso8601String()],
    );

    final pickups = await scalar(
      'SELECT COUNT(*) AS count_value FROM scheduler_tasks WHERE deleted_at IS NULL AND type = \'pickup\' AND $_effectiveReminderSql >= ? AND $_effectiveReminderSql < ?',
      [dayStart.toIso8601String(), dayEnd.toIso8601String()],
    );

    return SchedulerTodaySummary(
      pending: pending,
      completed: completed,
      overdue: overdue,
      urgent: urgent,
      todayDeliveries: deliveries,
      todayPickups: pickups,
    );
  }
}
