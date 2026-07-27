import 'package:flutter/foundation.dart';

import '../data/repositories/staff_repository.dart';
import '../managers/staff_manager.dart';

enum StaffSort { name, role, recentlyAdded }

enum StaffStatusFilter { all, active, inactive }

class StaffProvider extends ChangeNotifier {
  StaffProvider(this._manager);

  final StaffManager _manager;

  List<Staff> _staff = const [];
  bool _isLoading = false;
  String? _error;
  String _query = '';
  StaffRole? _roleFilter;
  StaffStatusFilter _statusFilter = StaffStatusFilter.all;
  StaffSort _sort = StaffSort.name;

  List<Staff> get staff {
    var result = _staff.where((member) {
      final query = _query.trim().toLowerCase();
      final matchesQuery = query.isEmpty ||
          member.name.toLowerCase().contains(query) ||
          member.phone.toLowerCase().contains(query) ||
          member.role.displayName.toLowerCase().contains(query);
      final matchesRole = _roleFilter == null || member.role == _roleFilter;
      final matchesStatus = switch (_statusFilter) {
        StaffStatusFilter.active => member.active,
        StaffStatusFilter.inactive => !member.active,
        StaffStatusFilter.all => true,
      };
      return matchesQuery && matchesRole && matchesStatus;
    }).toList();

    switch (_sort) {
      case StaffSort.name:
        result.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case StaffSort.role:
        result.sort((a, b) => a.role.displayName
            .toLowerCase()
            .compareTo(b.role.displayName.toLowerCase()));
      case StaffSort.recentlyAdded:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return result;
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get query => _query;
  StaffRole? get roleFilter => _roleFilter;
  StaffStatusFilter get statusFilter => _statusFilter;
  StaffSort get sort => _sort;

  Future<void> loadStaff() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _staff = await _manager.getAllStaff();
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setRoleFilter(StaffRole? value) {
    _roleFilter = value;
    notifyListeners();
  }

  void setStatusFilter(StaffStatusFilter value) {
    _statusFilter = value;
    notifyListeners();
  }

  void setSort(StaffSort value) {
    _sort = value;
    notifyListeners();
  }

  Future<void> createStaff(StaffUpsertInput input) async {
    await _manager.createStaff(input);
    await loadStaff();
  }

  Future<void> updateStaff(int id, StaffUpsertInput input) async {
    await _manager.updateStaff(id, input);
    await loadStaff();
  }

  Future<void> deactivateStaff(int id) async {
    await _manager.deactivateStaff(id);
    await loadStaff();
  }

  Future<void> reactivateStaff(int id) async {
    await _manager.reactivateStaff(id);
    await loadStaff();
  }

  Future<void> deleteStaff(int id) async {
    await _manager.deleteStaff(id);
    await loadStaff();
  }

  Future<List<Staff>> searchStaff({
    String? query,
    List<StaffRole>? roles,
    bool activeOnly = true,
  }) {
    return _manager.searchStaff(
      query: query,
      roles: roles,
      activeOnly: activeOnly,
    );
  }
}
