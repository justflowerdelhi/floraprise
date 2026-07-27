import 'package:flutter/foundation.dart';

import '../data/repositories/product_repository.dart';

class ProductProvider extends ChangeNotifier {
  ProductProvider(this._repository);

  final ProductRepository _repository;

  bool _disposed = false;

  List<ProductRecord> _products = const [];
  bool _isLoading = false;
  String? _error;

  String _query = '';
  String _category = 'all';
  bool? _trackInventory;
  bool _showActive = true;
  bool _showInactive = false;
  bool _favoriteOnly = false;
  bool _showDeleted = false;
  ProductSort _sort = ProductSort.nameAsc;

  List<ProductRecord> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String get query => _query;
  String get category => _category;
  bool? get trackInventory => _trackInventory;
  bool get showActive => _showActive;
  bool get showInactive => _showInactive;
  bool get favoriteOnly => _favoriteOnly;
  bool get showDeleted => _showDeleted;
  ProductSort get sort => _sort;

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

  Future<void> loadProducts() async {
    if (_disposed) return;
    _isLoading = true;
    _error = null;
    _notifyIfActive();

    try {
      _products = await _repository.listProducts(
        query: _query,
        category: _category == 'all' ? null : _category,
        trackInventory: _trackInventory,
        showActive: _showActive,
        showInactive: _showInactive,
        favoriteOnly: _favoriteOnly,
        includeDeleted: _showDeleted,
        sort: _sort,
      );
    } catch (e, st) {
      if (!_disposed) {
        if (kDebugMode) {
          debugPrint('ProductProvider.loadProducts failed: $e');
          debugPrintStack(stackTrace: st);
        }
        _error = 'Could not load products right now. Please try again.';
      }
    } finally {
      if (!_disposed) {
        _isLoading = false;
        _notifyIfActive();
      }
    }
  }

  Future<void> refresh() => loadProducts();

  Future<void> setQuery(String value) async {
    _query = value;
    await loadProducts();
  }

  Future<void> setCategory(String value) async {
    _category = value;
    await loadProducts();
  }

  Future<void> setTrackInventory(bool? value) async {
    _trackInventory = value;
    await loadProducts();
  }

  Future<void> setStatusFilters({
    required bool showActive,
    required bool showInactive,
  }) async {
    _showActive = showActive;
    _showInactive = showInactive;
    await loadProducts();
  }

  Future<void> setFavoriteOnly(bool value) async {
    _favoriteOnly = value;
    await loadProducts();
  }

  Future<void> setShowDeleted(bool value) async {
    _showDeleted = value;
    await loadProducts();
  }

  Future<void> setSort(ProductSort sort) async {
    _sort = sort;
    await loadProducts();
  }

  Future<void> createProduct(ProductUpsertInput input) async {
    try {
      await _repository.createProduct(input);
      await loadProducts();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('ProductProvider.createProduct failed: $e');
        debugPrintStack(stackTrace: st);
      }
      rethrow;
    }
  }

  Future<void> updateProduct(int id, ProductUpsertInput input) async {
    try {
      await _repository.updateProduct(id, input);
      await loadProducts();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('ProductProvider.updateProduct failed: $e');
        debugPrintStack(stackTrace: st);
      }
      rethrow;
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await _repository.softDeleteProduct(id);
      await loadProducts();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('ProductProvider.deleteProduct failed: $e');
        debugPrintStack(stackTrace: st);
      }
      rethrow;
    }
  }

  Future<void> restoreProduct(int id) async {
    try {
      await _repository.restoreProduct(id);
      await loadProducts();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('ProductProvider.restoreProduct failed: $e');
        debugPrintStack(stackTrace: st);
      }
      rethrow;
    }
  }

  Future<void> toggleFavorite(ProductRecord product) async {
    try {
      await _repository.setFavorite(
          id: product.id, favorite: !product.favorite);
      await loadProducts();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('ProductProvider.toggleFavorite failed: $e');
        debugPrintStack(stackTrace: st);
      }
      rethrow;
    }
  }
}
