import 'package:flutter/foundation.dart';

import '../data/repositories/cloud_product_repository.dart';
import '../data/repositories/product_repository.dart';

class CloudProductProvider extends ChangeNotifier {
  CloudProductProvider(this._repository);

  final CloudProductRepository _repository;
  List<CloudProduct> _products = const [];
  List<CloudCategory> _categories = const [];
  bool _isLoading = false;
  String? _error;
  String _query = '';
  String _category = 'all';
  ProductSort _sort = ProductSort.nameAsc;
  bool _favoriteOnly = false;
  final Set<String> _favoriteIds = {};

  static const Map<String, String> _legacyCategoryLabels = {
    'Finished Product': 'Finished Products',
    'Flower': 'Flowers',
    'Filler': 'Fillers',
    'Accessory': 'Accessories',
    'Other': 'Others',
  };

  List<CloudProduct> get products {
    var list = List<CloudProduct>.from(_products);

    if (_category != 'all') {
      final categoryLower = _category.toLowerCase();
      final legacyMapped = _legacyCategoryLabels[_category]?.toLowerCase();
      list = list.where((p) {
        final prodCat = p.category.toLowerCase();
        return prodCat == categoryLower ||
            (legacyMapped != null && prodCat == legacyMapped);
      }).toList();
    }

    if (_favoriteOnly) {
      list = list.where((p) => _favoriteIds.contains(p.id)).toList();
    }

    switch (_sort) {
      case ProductSort.nameAsc:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case ProductSort.nameDesc:
        list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case ProductSort.priceLowToHigh:
        list.sort((a, b) => a.retailPrice.compareTo(b.retailPrice));
        break;
      case ProductSort.priceHighToLow:
        list.sort((a, b) => b.retailPrice.compareTo(a.retailPrice));
        break;
      case ProductSort.latestUpdated:
        list.sort((a, b) =>
            (b.updatedAtUtc ?? b.createdAtUtc).compareTo(a.updatedAtUtc ?? a.createdAtUtc));
        break;
    }

    return list;
  }

  List<CloudCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get query => _query;
  String get category => _category;
  ProductSort get sort => _sort;
  bool get favoriteOnly => _favoriteOnly;
  Set<String> get favoriteIds => _favoriteIds;

  bool isFavorite(String productId) => _favoriteIds.contains(productId);

  void toggleFavorite(String productId) {
    if (_favoriteIds.contains(productId)) {
      _favoriteIds.remove(productId);
    } else {
      _favoriteIds.add(productId);
    }
    notifyListeners();
  }

  void setCategory(String category) {
    _category = category;
    notifyListeners();
  }

  void setSort(ProductSort sort) {
    _sort = sort;
    notifyListeners();
  }

  void setFavoriteOnly(bool favoriteOnly) {
    _favoriteOnly = favoriteOnly;
    notifyListeners();
  }

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
