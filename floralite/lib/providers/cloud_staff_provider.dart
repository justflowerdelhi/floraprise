import 'package:flutter/foundation.dart';

import '../data/repositories/cloud_staff_repository.dart';
import '../data/repositories/staff_repository.dart';
import 'staff_provider.dart';
import 'storage_mode_provider.dart';

/// Cloud-only staff state. The local SQLite [StaffProvider] is untouched.
class CloudStaffProvider extends ChangeNotifier {
  CloudStaffProvider(
    this._storageModeProvider, [
    CloudStaffRepository? repository,
  ]) : _repository = repository ?? CloudStaffRepository();

  final StorageModeProvider? _storageModeProvider;
  final CloudStaffRepository _repository;

  List<CloudStaff> _staff = const [];
  bool _isLoading = false;
  String? _error;
  String _query = '';
  StaffRole? _roleFilter;
  StaffStatusFilter _statusFilter = StaffStatusFilter.all;
  StaffSort _sort = StaffSort.name;

  bool get _isCloud => _storageModeProvider?.isCloud == true;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get query => _query;
  StaffRole? get roleFilter => _roleFilter;
  StaffStatusFilter get statusFilter => _statusFilter;
  StaffSort get sort => _sort;

  List<CloudStaff> get staff {
    final needle = _query.trim().toLowerCase();
    final result = _staff.where((member) {
      final matchesQuery = needle.isEmpty ||
          member.name.toLowerCase().contains(needle) ||
          (member.phone ?? '').toLowerCase().contains(needle) ||
          member.roleLabel.toLowerCase().contains(needle);
      final matchesRole = _roleFilter == null || member.appRole == _roleFilter;
      final matchesStatus = switch (_statusFilter) {
        StaffStatusFilter.active => member.isActive,
        StaffStatusFilter.inactive => !member.isActive,
        StaffStatusFilter.all => true,
      };
      return matchesQuery && matchesRole && matchesStatus;
    }).toList();

    switch (_sort) {
      case StaffSort.name:
        result.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case StaffSort.role:
        result.sort((a, b) =>
            a.roleLabel.toLowerCase().compareTo(b.roleLabel.toLowerCase()));
      case StaffSort.recentlyAdded:
        result.sort((a, b) => (b.createdAtUtc ?? DateTime(0))
            .compareTo(a.createdAtUtc ?? DateTime(0)));
    }
    return result;
  }

  Future<void> loadStaff() async {
    _requireCloud();
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _staff = await _repository.list();
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

  Future<List<CloudStaff>> searchStaff({
    String? query,
    StaffRole? role,
    bool? isActive,
  }) {
    _requireCloud();
    return _repository.search(query: query, role: role, isActive: isActive);
  }

  Future<CloudStaff?> getStaff(String staffId) {
    _requireCloud();
    return _repository.getById(staffId);
  }

  Future<void> createStaff(CloudStaffInput input) async {
    _requireCloud();
    await _repository.create(input);
    await loadStaff();
  }

  Future<void> updateStaff(String staffId, CloudStaffInput input) async {
    _requireCloud();
    await _repository.update(staffId, input);
    await loadStaff();
  }

  Future<void> deactivateStaff(String staffId) async {
    _requireCloud();
    await _repository.setActive(staffId, false);
    await loadStaff();
  }

  Future<void> reactivateStaff(String staffId) async {
    _requireCloud();
    await _repository.setActive(staffId, true);
    await loadStaff();
  }

  void _requireCloud() {
    if (!_isCloud) {
      throw StateError('Cloud staff management requires Cloud mode.');
    }
  }
}
