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
  final String? cloudId;
  final int staffId;
  final String? cloudStaffId;
  final String? staffName;
  final String? staffRole;
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
    this.cloudId,
    required this.staffId,
    this.cloudStaffId,
    this.staffName,
    this.staffRole,
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

  factory Attendance.fromCloudJson(Map<String, dynamic> json) {
    final idStr = (json['id'] ?? json['Id'])?.toString() ?? '';
    final sIdStr = (json['staffId'] ?? json['StaffId'])?.toString() ?? '';
    final sName = (json['staffName'] ?? json['StaffName'])?.toString();
    final sRole = (json['staffRole'] ?? json['StaffRole'])?.toString();
    final statusStr =
        (json['status'] ?? json['Status'])?.toString() ?? 'NotMarked';
    final dateStr =
        (json['attendanceDate'] ?? json['AttendanceDate'])?.toString() ?? '';
    final checkInStr = (json['checkIn'] ?? json['CheckIn'])?.toString();
    final checkOutStr = (json['checkOut'] ?? json['CheckOut'])?.toString();
    final ot = (json['overtimeHours'] ?? json['OvertimeHours'] ?? 0) as int;
    final notes = (json['notes'] ?? json['Notes'])?.toString();

    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(dateStr);
    } catch (_) {
      parsedDate = DateTime.now();
    }

    DateTime? parseTime(String? timeStr, DateTime baseDate) {
      if (timeStr == null || timeStr.trim().isEmpty) return null;
      try {
        if (timeStr.contains('T')) return DateTime.parse(timeStr);
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          final h = int.parse(parts[0]);
          final m = int.parse(parts[1]);
          return DateTime(baseDate.year, baseDate.month, baseDate.day, h, m);
        }
      } catch (_) {}
      return null;
    }

    AttendanceStatus parsedStatus;
    switch (statusStr.toLowerCase()) {
      case 'present':
      case 'working':
      case 'completed':
        parsedStatus = AttendanceStatus.present;
        break;
      case 'absent':
        parsedStatus = AttendanceStatus.absent;
        break;
      case 'leave':
        parsedStatus = AttendanceStatus.leave;
        break;
      case 'halfday':
        parsedStatus = AttendanceStatus.halfDay;
        break;
      default:
        parsedStatus = AttendanceStatus.notMarked;
        break;
    }

    return Attendance(
      id: int.tryParse(idStr) ?? (idStr.isEmpty ? 0 : idStr.hashCode.abs()),
      cloudId: idStr.isEmpty ? null : idStr,
      staffId:
          int.tryParse(sIdStr) ?? (sIdStr.isEmpty ? 0 : sIdStr.hashCode.abs()),
      cloudStaffId: sIdStr.isEmpty ? null : sIdStr,
      staffName: sName,
      staffRole: sRole,
      attendanceDate: parsedDate,
      status: parsedStatus,
      clockIn: parseTime(checkInStr, parsedDate),
      clockOut: parseTime(checkOutStr, parsedDate),
      overtimeHours: ot,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
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
    String? cloudId,
    int? staffId,
    String? cloudStaffId,
    String? staffName,
    String? staffRole,
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
      cloudId: cloudId ?? this.cloudId,
      staffId: staffId ?? this.staffId,
      cloudStaffId: cloudStaffId ?? this.cloudStaffId,
      staffName: staffName ?? this.staffName,
      staffRole: staffRole ?? this.staffRole,
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

  factory AttendanceSummary.fromCloudJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      present: (json['present'] ?? json['Present'] ?? 0) as int,
      absent: (json['absent'] ?? json['Absent'] ?? 0) as int,
      leave: (json['leave'] ?? json['Leave'] ?? 0) as int,
      halfDay: (json['halfDay'] ?? json['HalfDay'] ?? 0) as int,
      notMarked: (json['notMarked'] ?? json['NotMarked'] ?? 0) as int,
      totalOvertimeHours:
          (json['totalOvertimeHours'] ?? json['TotalOvertimeHours'] ?? 0)
              as int,
    );
  }

  int get total => present + absent + leave + halfDay + notMarked;
}
