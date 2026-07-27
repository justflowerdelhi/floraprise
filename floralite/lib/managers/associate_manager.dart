import '../data/repositories/associate_repository.dart';

class AssociateManager {
  AssociateManager(this._associateRepository);

  final AssociateRepository _associateRepository;

  Future<List<AssociateRecord>> getAllAssociates({
    bool includeDeleted = false,
    bool activeOnly = false,
  }) async {
    return _associateRepository.getAll(
      includeDeleted: includeDeleted,
      activeOnly: activeOnly,
    );
  }

  Future<List<AssociateRecord>> searchAssociates({
    String? query,
    List<AssociateType>? types,
    bool activeOnly = true,
  }) async {
    return _associateRepository.searchAssociates(
      query: query,
      types: types,
      activeOnly: activeOnly,
    );
  }

  Future<AssociateRecord?> getAssociateById(int id) async {
    return _associateRepository.findById(id);
  }

  Future<AssociateRecord> createAssociate(AssociateUpsertInput input) async {
    return _associateRepository.create(input);
  }

  Future<AssociateRecord> updateAssociate(
    int id,
    AssociateUpsertInput input,
  ) async {
    return _associateRepository.update(id, input);
  }

  Future<void> deactivateAssociate(int id) async {
    await _associateRepository.deactivate(id);
  }

  Future<void> reactivateAssociate(int id) async {
    await _associateRepository.reactivate(id);
  }

  Future<bool> canDeleteAssociate(int id) async {
    return _associateRepository.canDelete(id);
  }

  Future<void> deleteAssociate(int id) async {
    await _associateRepository.delete(id);
  }

  Future<int> getActiveAssociateCount() async {
    return _associateRepository.getActiveCount();
  }
}
