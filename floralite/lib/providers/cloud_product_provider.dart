import 'package:flutter/foundation.dart';

import '../data/repositories/cloud_product_repository.dart';

class CloudProductProvider extends ChangeNotifier {
  CloudProductProvider(this._repository);

  final CloudProductRepository _repository;
  List<CloudProduct> _products = const [];
  List<CloudCategory> _categories = const [];
  bool _isLoading = false;
  String? _error;
  String _query = '';

  List<CloudProduct> get products => _products;
  List<CloudCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get query => _query;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // Include inactive products too (not just active) so a deactivated
      // product remains visible and can be reactivated from this screen.
      _products = await _repository.listProducts(query: _query, showActive: true, showInactive: true);
      _categories = await _repository.listCategories();
    } catch (error, stackTrace) {
      _error = error.toString();
      if (kDebugMode) debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> search(String value) async {
    _query = value;
    await load();
  }

  Future<void> createProduct(CloudProductInput input) async {
    await _repository.createProduct(input);
    await load();
  }

  Future<void> updateProduct(String id, CloudProductInput input) async {
    await _repository.updateProduct(id, input);
    await load();
  }

  Future<void> setProductActive(String id, bool active) async {
    await _repository.setActive(id, active);
    await load();
  }

  Future<void> createCategory(String name) async {
    await _repository.createCategory(name);
    await load();
  }

  Future<void> updateCategory(String id, String name) async {
    await _repository.updateCategory(id, name);
    await load();
  }

  Future<void> setCategoryActive(String id, bool active) async {
    await _repository.setCategoryActive(id, active);
    await load();
  }
}
