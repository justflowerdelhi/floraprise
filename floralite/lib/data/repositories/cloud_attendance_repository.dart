import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/attendance.dart';
import '../../services/mobile_auth_service.dart';
import 'attendance_repository.dart';

typedef CloudAttendanceSender = Future<dynamic> Function(
  String method,
  Uri uri, {
  dynamic body,
});

class CloudAttendanceRepository {
  CloudAttendanceRepository({
    MobileAuthService? auth,
    CloudAttendanceSender? sender,
  })  : _auth = auth ?? MobileAuthService(),
        _sender = sender;

  final MobileAuthService _auth;
  final CloudAttendanceSender? _sender;

  String _dateToIso(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<List<Attendance>> getAttendanceForDate(DateTime date) async {
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    final uri = isToday
        ? Uri.parse('${_auth.baseUrl}/api/staff/attendance/today')
        : Uri.parse('${_auth.baseUrl}/api/staff/attendance')
            .replace(queryParameters: {'date': _dateToIso(date)});

    final response = await _request('GET', uri);
    if (response is! List) return const [];

    return response
        .whereType<Map<String, dynamic>>()
        .map(Attendance.fromCloudJson)
        .toList();
  }

  Future<AttendanceSummary> getSummaryForDate(DateTime date) async {
    final dateStr = _dateToIso(date);
    final uri = Uri.parse('${_auth.baseUrl}/api/staff/attendance/summary')
        .replace(queryParameters: {'start': dateStr, 'end': dateStr});

    try {
      final response = await _request('GET', uri);
      if (response is Map<String, dynamic>) {
        return AttendanceSummary.fromCloudJson(response);
      }
    } catch (_) {}

    // Fallback: derive summary directly from getAttendanceForDate
    final list = await getAttendanceForDate(date);
    var present = 0;
    var absent = 0;
    var leave = 0;
    var halfDay = 0;
    var notMarked = 0;
    var totalOvertime = 0;

    for (final a in list) {
      switch (a.status) {
        case AttendanceStatus.present:
          present++;
          break;
        case AttendanceStatus.absent:
          absent++;
          break;
        case AttendanceStatus.leave:
          leave++;
          break;
        case AttendanceStatus.halfDay:
          halfDay++;
          break;
        case AttendanceStatus.notMarked:
          notMarked++;
          break;
      }
      totalOvertime += a.overtimeHours;
    }

    return AttendanceSummary(
      present: present,
      absent: absent,
      leave: leave,
      halfDay: halfDay,
      notMarked: notMarked,
      totalOvertimeHours: totalOvertime,
    );
  }

  Future<int> getUnmarkedCount(DateTime date) async {
    final list = await getAttendanceForDate(date);
    return list.where((a) => a.status == AttendanceStatus.notMarked).length;
  }

  Future<List<Attendance>> getAttendanceForStaff(
    String staffId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/staff/attendance').replace(
      queryParameters: {
        'staffId': staffId,
        'from': _dateToIso(startDate),
        'to': _dateToIso(endDate),
      },
    );

    final response = await _request('GET', uri);
    if (response is! List) return const [];

    return response
        .whereType<Map<String, dynamic>>()
        .map(Attendance.fromCloudJson)
        .toList();
  }

  Future<AttendanceSummary> getSummaryForStaff(
    String staffId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/staff/attendance/summary').replace(
      queryParameters: {
        'start': _dateToIso(startDate),
        'end': _dateToIso(endDate),
      },
    );

    try {
      final response = await _request('GET', uri);
      if (response is Map<String, dynamic>) {
        return AttendanceSummary.fromCloudJson(response);
      }
    } catch (_) {}

    final list = await getAttendanceForStaff(staffId, startDate, endDate);
    var present = 0;
    var absent = 0;
    var leave = 0;
    var halfDay = 0;
    var notMarked = 0;
    var totalOvertime = 0;

    for (final a in list) {
      switch (a.status) {
        case AttendanceStatus.present:
          present++;
          break;
        case AttendanceStatus.absent:
          absent++;
          break;
        case AttendanceStatus.leave:
          leave++;
          break;
        case AttendanceStatus.halfDay:
          halfDay++;
          break;
        case AttendanceStatus.notMarked:
          notMarked++;
          break;
      }
      totalOvertime += a.overtimeHours;
    }

    return AttendanceSummary(
      present: present,
      absent: absent,
      leave: leave,
      halfDay: halfDay,
      notMarked: notMarked,
      totalOvertimeHours: totalOvertime,
    );
  }

  Future<Attendance> create(AttendanceUpsertInput input) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/staff/attendance');
    final staffId = input.cloudStaffId ?? input.staffId.toString();

    final body = {
      'staffId': staffId,
      'attendanceDate': input.attendanceDate.toUtc().toIso8601String(),
      'status': input.status.displayName,
      if (input.clockIn != null)
        'checkIn': input.clockIn!.toUtc().toIso8601String(),
      if (input.clockOut != null)
        'checkOut': input.clockOut!.toUtc().toIso8601String(),
      'overtimeHours': input.overtimeHours,
      if (input.notes != null && input.notes!.trim().isNotEmpty)
        'notes': input.notes!.trim(),
    };

    final response = await _request('POST', uri, body: body);
    if (response is! Map<String, dynamic>) {
      throw StateError('Failed to create attendance in cloud');
    }
    return Attendance.fromCloudJson(response);
  }

  Future<Attendance> update(
    String cloudId,
    AttendanceUpsertInput input,
  ) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/staff/attendance/$cloudId');
    final staffId = input.cloudStaffId ?? input.staffId.toString();

    final body = {
      'staffId': staffId,
      'attendanceDate': input.attendanceDate.toUtc().toIso8601String(),
      'status': input.status.displayName,
      if (input.clockIn != null)
        'checkIn': input.clockIn!.toUtc().toIso8601String(),
      if (input.clockOut != null)
        'checkOut': input.clockOut!.toUtc().toIso8601String(),
      'overtimeHours': input.overtimeHours,
      if (input.notes != null && input.notes!.trim().isNotEmpty)
        'notes': input.notes!.trim(),
    };

    final response = await _request('PUT', uri, body: body);
    if (response is! Map<String, dynamic>) {
      throw StateError('Failed to update attendance in cloud');
    }
    return Attendance.fromCloudJson(response);
  }

  Future<void> delete(String cloudId) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/staff/attendance/$cloudId');
    await _request('DELETE', uri);
  }

  Future<dynamic> _request(
    String method,
    Uri uri, {
    dynamic body,
  }) async {
    final sender = _sender;
    if (sender != null) {
      return await sender(method, uri, body: body);
    }

    final token = await _auth.getStoredAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw StateError('Not authenticated with Floraprise Cloud.');
    }

    final client = http.Client();
    try {
      final request = http.Request(method, uri);
      request.headers['Accept'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $token';

      if (body != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode(body);
      }

      final streamedResponse =
          await client.send(request).timeout(const Duration(seconds: 20));
      final text = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode >= 200 &&
          streamedResponse.statusCode < 300) {
        if (text.trim().isEmpty) return null;
        return jsonDecode(text);
      }

      throw StateError(
        'Cloud API error ${streamedResponse.statusCode}: $text',
      );
    } finally {
      client.close();
    }
  }
}
