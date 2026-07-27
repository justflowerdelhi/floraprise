import 'package:flutter/foundation.dart';

import '../data/repositories/attendance_repository.dart';
import '../models/attendance.dart';

class AttendanceProvider extends ChangeNotifier {
  AttendanceProvider(this._repository);

  final AttendanceRepository _repository;

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

  Future<void> loadAttendanceForDate(DateTime date) async {
    _selectedDate = date;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _attendanceList = await _repository.getAttendanceForDate(date);
      _summary = await _repository.getSummaryForDate(date);
      _unmarkedCount = await _repository.getUnmarkedCount(date);
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
    DateTime endDate,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _attendanceList = await _repository.getAttendanceForStaff(
        staffId,
        startDate,
        endDate,
      );
      _summary = await _repository.getSummaryForStaff(staffId, startDate, endDate);
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Attendance?> getAttendance(int staffId, DateTime date) async {
    return await _repository.getAttendance(staffId, date);
  }

  Future<void> createAttendance(AttendanceUpsertInput input) async {
    await _repository.create(input);
    await loadAttendanceForDate(_selectedDate);
  }

  Future<void> updateAttendance(int id, AttendanceUpsertInput input) async {
    await _repository.update(id, input);
    await loadAttendanceForDate(_selectedDate);
  }

  Future<void> deleteAttendance(int id) async {
    await _repository.delete(id);
    await loadAttendanceForDate(_selectedDate);
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }
}
