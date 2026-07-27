import 'package:flutter/foundation.dart';

import '../data/repositories/category_repository.dart';
import '../managers/category_manager.dart';

class CategoryProvider extends ChangeNotifier {
  CategoryProvider(this._manager);

  final CategoryManager _manager;

  bool _disposed = false;

  List<ProductCategoryRecord> _categories = const [];
  bool _isLoading = false;
  String? _error;

  List<ProductCategoryRecord> get categories => _categories;
  List<ProductCategoryRecord> get activeCategories =>
      _categories.where((c) => c.isActive).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notifyIfActive() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> loadCategories({bool includeInactive = true}) async {
    if (_disposed) return;
    _isLoading = true;
    _error = null;
    _notifyIfActive();

    try {
      _categories = await _manager.listCategories(
        includeInactive: includeInactive,
      );
    } catch (e, st) {
      if (!_disposed) {
        if (kDebugMode) {
          debugPrint('CategoryProvider.loadCategories failed: $e');
          debugPrintStack(stackTrace: st);
        }
        _error = 'Could not load categories right now. Please try again.';
      }
    } finally {
      if (!_disposed) {
        _isLoading = false;
        _notifyIfActive();
      }
    }
  }

  Future<ProductCategoryRecord?> createCategory({
    required String name,
    required String defaultUnit,
  }) async {
    final created = await _manager.createCategory(
      name: name,
      defaultUnit: defaultUnit,
    );
    await loadCategories();
    return created;
  }

  Future<ProductCategoryRecord?> updateCategory({
    required int id,
    required String name,
    required String defaultUnit,
  }) async {
    final updated = await _manager.updateCategory(
      id: id,
      name: name,
      defaultUnit: defaultUnit,
    );
    await loadCategories();
    return updated;
  }

  Future<void> setCategoryActive({
    required int id,
    required bool isActive,
  }) async {
    await _manager.setCategoryActive(id: id, isActive: isActive);
    await loadCategories();
  }

  Future<bool> deleteCategoryIfUnused(int id) async {
    final deleted = await _manager.deleteCategoryIfUnused(id);
    await loadCategories();
    return deleted;
  }

  String defaultUnitForCategory(String categoryName) {
    for (final category in _categories) {
      if (category.name == categoryName) {
        return category.defaultUnit;
      }
    }
    return 'Piece';
  }
}
