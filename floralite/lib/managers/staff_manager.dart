import '../data/repositories/staff_repository.dart';

class StaffManager {
  StaffManager(this._repository);

  final StaffRepository _repository;

  Future<List<Staff>> getAllStaff() => _repository.getAll();

  Future<List<Staff>> searchStaff({
    String? query,
    List<StaffRole>? roles,
    bool activeOnly = true,
  }) {
    return _repository.searchStaff(
      query: query,
      roles: roles,
      activeOnly: activeOnly,
    );
  }

  Future<Staff?> getStaffById(int id) => _repository.findById(id);

  Future<Staff> createStaff(StaffUpsertInput input) =>
      _repository.create(input);

  Future<Staff> updateStaff(int id, StaffUpsertInput input) =>
      _repository.update(id, input);

  Future<void> deactivateStaff(int id) => _repository.setActive(id, false);

  Future<void> reactivateStaff(int id) => _repository.setActive(id, true);

  Future<bool> canDeleteStaff(int id) => _repository.canDelete(id);

  Future<void> deleteStaff(int id) => _repository.delete(id);

  Future<int> getActiveStaffCount() => _repository.getActiveCount();
}
