import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/models/attendance.dart';
import 'package:floraprise/data/repositories/attendance_repository.dart';
import 'package:floraprise/data/repositories/cloud_attendance_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Attendance Cloud Submit & Guid.Empty Parsing Tests', () {
    test('Attendance.fromCloudJson correctly parses Guid.Empty as unpersisted record', () {
      final json = {
        'id': '00000000-0000-0000-0000-000000000000',
        'staffId': '11111111-1111-1111-1111-111111111111',
        'staffName': 'Ramesh Kumar',
        'staffRole': 'Florist',
        'status': 'NotMarked',
        'attendanceDate': '2026-09-20',
        'overtimeHours': 0,
        'notes': null,
      };

      final attendance = Attendance.fromCloudJson(json);
      expect(attendance.id, equals(0));
      expect(attendance.cloudId, isNull);
      expect(attendance.status, equals(AttendanceStatus.notMarked));
      expect(attendance.staffName, equals('Ramesh Kumar'));
    });

    test('Attendance.fromCloudJson correctly parses real Guid as persisted record', () {
      final json = {
        'id': '22222222-2222-2222-2222-222222222222',
        'staffId': '11111111-1111-1111-1111-111111111111',
        'staffName': 'Ramesh Kumar',
        'staffRole': 'Florist',
        'status': 'Present',
        'attendanceDate': '2026-09-20',
        'checkIn': '09:00',
        'overtimeHours': 1,
        'notes': 'On time',
      };

      final attendance = Attendance.fromCloudJson(json);
      expect(attendance.id, isNonZero);
      expect(attendance.cloudId, equals('22222222-2222-2222-2222-222222222222'));
      expect(attendance.status, equals(AttendanceStatus.present));
      expect(attendance.overtimeHours, equals(1));
    });

    test('CloudAttendanceRepository update with Guid.Empty redirects to POST create', () async {
      String? sentMethod;
      Uri? sentUri;

      final repo = CloudAttendanceRepository(
        sender: (method, uri, {body}) async {
          sentMethod = method;
          sentUri = uri;
          return {
            'id': 'new-attendance-id-123',
            'staffId': '11111111-1111-1111-1111-111111111111',
            'status': 'Present',
            'attendanceDate': '2026-09-20',
          };
        },
      );

      final input = AttendanceUpsertInput(
        staffId: 1,
        cloudStaffId: '11111111-1111-1111-1111-111111111111',
        attendanceDate: DateTime.utc(2026, 9, 20),
        status: AttendanceStatus.present,
      );

      final result = await repo.update('00000000-0000-0000-0000-000000000000', input);
      expect(sentMethod, equals('POST'));
      expect(sentUri.toString(), endsWith('/api/staff/attendance'));
      expect(result.cloudId, equals('new-attendance-id-123'));
    });
  });
}
