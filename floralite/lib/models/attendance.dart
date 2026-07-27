enum AttendanceStatus {
  present,
  absent,
  leave,
  halfDay,
  notMarked,
}

extension AttendanceStatusExtension on AttendanceStatus {
  String get displayName => switch (this) {
        AttendanceStatus.present => 'Present',
        AttendanceStatus.absent => 'Absent',
        AttendanceStatus.leave => 'Leave',
        AttendanceStatus.halfDay => 'Half Day',
        AttendanceStatus.notMarked => 'Not Marked',
      };

  String get emoji => switch (this) {
        AttendanceStatus.present => '🟢',
        AttendanceStatus.absent => '🔴',
        AttendanceStatus.leave => '🟡',
        AttendanceStatus.halfDay => '🟠',
        AttendanceStatus.notMarked => '⚪',
      };
}

class Attendance {
  final int id;
  final int staffId;
  final DateTime attendanceDate;
  final AttendanceStatus status;
  final DateTime? clockIn;
  final DateTime? clockOut;
  final int overtimeHours;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Attendance({
    required this.id,
    required this.staffId,
    required this.attendanceDate,
    required this.status,
    this.clockIn,
    this.clockOut,
    this.overtimeHours = 0,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'] as int,
      staffId: map['staff_id'] as int,
      attendanceDate: DateTime.parse(map['attendance_date'] as String),
      status: _parseStatus(map['status'] as String),
      clockIn: map['clock_in'] != null
          ? DateTime.parse(map['clock_in'] as String)
          : null,
      clockOut: map['clock_out'] != null
          ? DateTime.parse(map['clock_out'] as String)
          : null,
      overtimeHours: (map['overtime_hours'] as int?) ?? 0,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  static AttendanceStatus _parseStatus(String value) {
    return AttendanceStatus.values.firstWhere(
      (status) => status.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AttendanceStatus.notMarked,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'staff_id': staffId,
      'attendance_date': attendanceDate.toIso8601String(),
      'status': status.displayName,
      'clock_in': clockIn?.toIso8601String(),
      'clock_out': clockOut?.toIso8601String(),
      'overtime_hours': overtimeHours,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Attendance copyWith({
    int? id,
    int? staffId,
    DateTime? attendanceDate,
    AttendanceStatus? status,
    DateTime? clockIn,
    DateTime? clockOut,
    int? overtimeHours,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Attendance(
      id: id ?? this.id,
      staffId: staffId ?? this.staffId,
      attendanceDate: attendanceDate ?? this.attendanceDate,
      status: status ?? this.status,
      clockIn: clockIn ?? this.clockIn,
      clockOut: clockOut ?? this.clockOut,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AttendanceSummary {
  final int present;
  final int absent;
  final int leave;
  final int halfDay;
  final int notMarked;
  final int totalOvertimeHours;

  const AttendanceSummary({
    required this.present,
    required this.absent,
    required this.leave,
    required this.halfDay,
    required this.notMarked,
    required this.totalOvertimeHours,
  });

  int get total => present + absent + leave + halfDay + notMarked;
}
