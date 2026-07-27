import '../data/repositories/category_repository.dart';
import '../data/repositories/product_repository.dart';

class CategoryManager {
  CategoryManager(this._repository);

  final CategoryRepository _repository;

  Future<List<ProductCategoryRecord>> listCategories({
    bool includeInactive = true,
  }) {
    return _repository.listCategories(includeInactive: includeInactive);
  }

  Future<ProductCategoryRecord?> createCategory({
    required String name,
    required String defaultUnit,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Category name is required');
    }

    if (!ProductRepository.allowedUnits.contains(defaultUnit.trim())) {
      throw ArgumentError('Default unit is invalid');
    }

    return _repository.createCategory(
      name: trimmed,
      defaultUnit: defaultUnit.trim(),
    );
  }

  Future<ProductCategoryRecord?> updateCategory({
    required int id,
    required String name,
    required String defaultUnit,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Category name is required');
    }

    if (!ProductRepository.allowedUnits.contains(defaultUnit.trim())) {
      throw ArgumentError('Default unit is invalid');
    }

    return _repository.updateCategory(
      id: id,
      name: trimmed,
      defaultUnit: defaultUnit.trim(),
    );
  }

  Future<void> setCategoryActive({
    required int id,
    required bool isActive,
  }) {
    return _repository.setCategoryActive(id: id, isActive: isActive);
  }

  Future<bool> deleteCategoryIfUnused(int id) {
    return _repository.deleteCategoryIfUnused(id);
  }
}
