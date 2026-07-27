import '../database/app_database.dart';
import '../../models/attendance.dart';

class AttendanceUpsertInput {
  final int staffId;
  final DateTime attendanceDate;
  final AttendanceStatus status;
  final DateTime? clockIn;
  final DateTime? clockOut;
  final int overtimeHours;
  final String? notes;

  const AttendanceUpsertInput({
    required this.staffId,
    required this.attendanceDate,
    required this.status,
    this.clockIn,
    this.clockOut,
    this.overtimeHours = 0,
    this.notes,
  });
}

class AttendanceRepository {
  Attendance _fromRow(Map<String, Object?> row) {
    return Attendance(
      id: row['id'] as int,
      staffId: row['staff_id'] as int,
      attendanceDate: DateTime.parse(row['attendance_date'] as String),
      status: _parseStatus(row['status'] as String),
      clockIn: row['clock_in'] != null
          ? DateTime.parse(row['clock_in'] as String)
          : null,
      clockOut: row['clock_out'] != null
          ? DateTime.parse(row['clock_out'] as String)
          : null,
      overtimeHours: (row['overtime_hours'] as int?) ?? 0,
      notes: row['notes'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  AttendanceStatus _parseStatus(String value) {
    return AttendanceStatus.values.firstWhere(
      (status) => status.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AttendanceStatus.notMarked,
    );
  }

  Future<Attendance?> getAttendance(int staffId, DateTime date) async {
    final db = await AppDatabase.instance.database;
    final dateStr = _dateToIso(date);
    final rows = await db.query(
      'attendance',
      where: 'staff_id = ? AND attendance_date = ?',
      whereArgs: [staffId, dateStr],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  Future<List<Attendance>> getAttendanceForDate(DateTime date) async {
    try {
      final db = await AppDatabase.instance.database;
      final dateStr = _dateToIso(date);
      final rows = await db.query(
        'attendance',
        where: 'attendance_date = ?',
        whereArgs: [dateStr],
        orderBy: 'id ASC',
      );
      return rows.map(_fromRow).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Attendance>> getAttendanceForStaff(
    int staffId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await AppDatabase.instance.database;
    final startStr = _dateToIso(startDate);
    final endStr = _dateToIso(endDate);
    final rows = await db.query(
      'attendance',
      where: 'staff_id = ? AND attendance_date BETWEEN ? AND ?',
      whereArgs: [staffId, startStr, endStr],
      orderBy: 'attendance_date DESC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<Attendance> create(AttendanceUpsertInput input) async {
    _validate(input);
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final dateStr = _dateToIso(input.attendanceDate);

    await _ensureUniqueRecord(input.staffId, dateStr);

    final id = await db.insert('attendance', {
      'staff_id': input.staffId,
      'attendance_date': dateStr,
      'status': input.status.displayName,
      'clock_in': input.clockIn?.toIso8601String(),
      'clock_out': input.clockOut?.toIso8601String(),
      'overtime_hours': input.overtimeHours,
      'notes': input.notes,
      'created_at': now,
      'updated_at': now,
    });

    final row = await db.query(
      'attendance',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return _fromRow(row.first);
  }

  Future<Attendance> update(int id, AttendanceUpsertInput input) async {
    _validate(input);
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final dateStr = _dateToIso(input.attendanceDate);

    await db.update(
      'attendance',
      {
        'staff_id': input.staffId,
        'attendance_date': dateStr,
        'status': input.status.displayName,
        'clock_in': input.clockIn?.toIso8601String(),
        'clock_out': input.clockOut?.toIso8601String(),
        'overtime_hours': input.overtimeHours,
        'notes': input.notes,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    final row = await db.query(
      'attendance',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return _fromRow(row.first);
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      'attendance',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<AttendanceSummary> getSummaryForDate(DateTime date) async {
    try {
      final db = await AppDatabase.instance.database;
      final dateStr = _dateToIso(date);
      final rows = await db.rawQuery('''
        SELECT 
          status,
          COUNT(*) as count,
          SUM(overtime_hours) as total_overtime
        FROM attendance
        WHERE attendance_date = ?
        GROUP BY status
      ''', [dateStr]);

      int present = 0;
      int absent = 0;
      int leave = 0;
      int halfDay = 0;
      int notMarked = 0;
      int totalOvertime = 0;

      for (final row in rows) {
        final status = _parseStatus(row['status'] as String);
        final count = row['count'] as int;
        final overtime = (row['total_overtime'] as int?) ?? 0;

        switch (status) {
          case AttendanceStatus.present:
            present = count;
          case AttendanceStatus.absent:
            absent = count;
          case AttendanceStatus.leave:
            leave = count;
          case AttendanceStatus.halfDay:
            halfDay = count;
          case AttendanceStatus.notMarked:
            notMarked = count;
        }
        totalOvertime += overtime;
      }

      return AttendanceSummary(
        present: present,
        absent: absent,
        leave: leave,
        halfDay: halfDay,
        notMarked: notMarked,
        totalOvertimeHours: totalOvertime,
      );
    } catch (e) {
      return const AttendanceSummary(
        present: 0,
        absent: 0,
        leave: 0,
        halfDay: 0,
        notMarked: 0,
        totalOvertimeHours: 0,
      );
    }
  }

  Future<AttendanceSummary> getSummaryForStaff(
    int staffId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final db = await AppDatabase.instance.database;
      final startStr = _dateToIso(startDate);
      final endStr = _dateToIso(endDate);
      final rows = await db.rawQuery('''
        SELECT 
          status,
          COUNT(*) as count,
          SUM(overtime_hours) as total_overtime
        FROM attendance
        WHERE staff_id = ? AND attendance_date BETWEEN ? AND ?
        GROUP BY status
      ''', [staffId, startStr, endStr]);

      int present = 0;
      int absent = 0;
      int leave = 0;
      int halfDay = 0;
      int notMarked = 0;
      int totalOvertime = 0;

      for (final row in rows) {
        final status = _parseStatus(row['status'] as String);
        final count = row['count'] as int;
        final overtime = (row['total_overtime'] as int?) ?? 0;

        switch (status) {
          case AttendanceStatus.present:
            present = count;
          case AttendanceStatus.absent:
            absent = count;
          case AttendanceStatus.leave:
            leave = count;
          case AttendanceStatus.halfDay:
            halfDay = count;
          case AttendanceStatus.notMarked:
            notMarked = count;
        }
        totalOvertime += overtime;
      }

      return AttendanceSummary(
        present: present,
        absent: absent,
        leave: leave,
        halfDay: halfDay,
        notMarked: notMarked,
        totalOvertimeHours: totalOvertime,
      );
    } catch (e) {
      return const AttendanceSummary(
        present: 0,
        absent: 0,
        leave: 0,
        halfDay: 0,
        notMarked: 0,
        totalOvertimeHours: 0,
      );
    }
  }

  Future<int> getUnmarkedCount(DateTime date) async {
    try {
      final db = await AppDatabase.instance.database;
      final dateStr = _dateToIso(date);
      final result = await db.rawQuery('''
        SELECT COUNT(*) as count
        FROM staff
        WHERE active = 1
        AND id NOT IN (
          SELECT staff_id FROM attendance WHERE attendance_date = ?
        )
      ''', [dateStr]);
      return (result.first['count'] as int? ?? 0);
    } catch (e) {
      return 0;
    }
  }

  void _validate(AttendanceUpsertInput input) {
    if (input.attendanceDate.isAfter(DateTime.now())) {
      throw ArgumentError('Future dates are not allowed');
    }

    if (input.status == AttendanceStatus.present && input.clockIn == null) {
      throw ArgumentError('Clock In is required for Present status');
    }

    if (input.overtimeHours < 0) {
      throw ArgumentError('Overtime hours cannot be negative');
    }

    if (input.overtimeHours > 5) {
      throw ArgumentError('Overtime hours cannot exceed 5');
    }
  }

  Future<void> _ensureUniqueRecord(int staffId, String dateStr) async {
    final existing = await getAttendance(staffId, DateTime.parse(dateStr));
    if (existing != null) {
      throw ArgumentError(
        'Attendance already exists for staff $staffId on $dateStr',
      );
    }
  }

  String _dateToIso(DateTime date) {
    return DateTime(date.year, date.month, date.day).toIso8601String();
  }
}
