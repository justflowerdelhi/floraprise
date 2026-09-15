import 'package:flutter/foundation.dart';

import '../data/repositories/attendance_repository.dart';
import '../data/repositories/cloud_attendance_repository.dart';
import '../models/attendance.dart';
import 'storage_mode_provider.dart';

class AttendanceProvider extends ChangeNotifier {
  AttendanceProvider(
    this._repository, [
    this._storageModeProvider,
    this._cloudRepo,
  ]);

  final AttendanceRepository _repository;
  final StorageModeProvider? _storageModeProvider;
  final CloudAttendanceRepository? _cloudRepo;

  bool get isCloud => _storageModeProvider?.isCloud == true;

  DateTime _selectedDate = DateTime.now();
  List<Attendance> _attendanceList = const [];
  AttendanceSummary? _summary;
  int _unmarkedCount = 0;
  bool _isLoading = false;
  String? _error;

  DateTime get selectedDate => _selectedDate;
  List<Attendance> get attendanceList => _attendanceList;
  AttendanceSummary? get summary => _summary;
  int get unmarkedCount => _unmarkedCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Attendance? _findAttendance(int id) {
    for (final a in _attendanceList) {
      if (a.id == id) return a;
    }
    return null;
  }

  String? _findAttendanceCloudId(int id) {
    final a = _findAttendance(id);
    return a?.cloudId;
  }

  Future<void> loadAttendanceForDate(DateTime date) async {
    _selectedDate = date;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (isCloud && _cloudRepo != null) {
        _attendanceList = await _cloudRepo!.getAttendanceForDate(date);
        _summary = await _cloudRepo!.getSummaryForDate(date);
        _unmarkedCount = await _cloudRepo!.getUnmarkedCount(date);
      } else {
        _attendanceList = await _repository.getAttendanceForDate(date);
        _summary = await _repository.getSummaryForDate(date);
        _unmarkedCount = await _repository.getUnmarkedCount(date);
      }
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAttendanceForStaff(
    int staffId,
    DateTime startDate,
    DateTime endDate, [
    String? cloudStaffId,
  ]) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (isCloud && _cloudRepo != null) {
        final staffIdToUse = cloudStaffId ??
            _attendanceList
                .firstWhere(
                  (a) => a.staffId == staffId,
                  orElse: () => Attendance(
                    id: 0,
                    staffId: staffId,
                    attendanceDate: startDate,
                    status: AttendanceStatus.notMarked,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                )
                .cloudStaffId ??
            staffId.toString();

        _attendanceList = await _cloudRepo!.getAttendanceForStaff(
          staffIdToUse,
          startDate,
          endDate,
        );
        _summary = await _cloudRepo!.getSummaryForStaff(
          staffIdToUse,
          startDate,
          endDate,
        );
      } else {
        _attendanceList = await _repository.getAttendanceForStaff(
          staffId,
          startDate,
          endDate,
        );
        _summary =
            await _repository.getSummaryForStaff(staffId, startDate, endDate);
      }
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Attendance?> getAttendance(int staffId, DateTime date) async {
    if (isCloud) {
      for (final a in _attendanceList) {
        if (a.staffId == staffId) return a;
      }
      return null;
    }
    return await _repository.getAttendance(staffId, date);
  }

  Future<void> createAttendance(AttendanceUpsertInput input) async {
    if (isCloud && _cloudRepo != null) {
      await _cloudRepo!.create(input);
    } else {
      await _repository.create(input);
    }
    await loadAttendanceForDate(_selectedDate);
  }

  Future<void> updateAttendance(int id, AttendanceUpsertInput input) async {
    if (isCloud && _cloudRepo != null) {
      final cloudId = _findAttendanceCloudId(id) ?? id.toString();
      await _cloudRepo!.update(cloudId, input);
    } else {
      await _repository.update(id, input);
    }
    await loadAttendanceForDate(_selectedDate);
  }

  Future<void> deleteAttendance(int id) async {
    if (isCloud && _cloudRepo != null) {
      final cloudId = _findAttendanceCloudId(id) ?? id.toString();
      await _cloudRepo!.delete(cloudId);
    } else {
      await _repository.delete(id);
    }
    await loadAttendanceForDate(_selectedDate);
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }
}
