import 'package:flutter/foundation.dart';

import '../data/repositories/morning_purchase_list_repository.dart';
import '../managers/morning_purchase_list_manager.dart';

class MorningPurchaseListProvider extends ChangeNotifier {
  MorningPurchaseListProvider(this._manager);

  final MorningPurchaseListManager _manager;

  List<MorningPurchaseListItem> _items = const [];
  List<MarketProductRecord> _trackedProducts = const [];
  bool _isLoading = false;
  bool _isBusy = false;
  String? _error;

  String _searchQuery = '';
  String _statusFilter = 'All';
  String _categoryFilter = 'All';

  List<MorningPurchaseListItem> get items => _items;
  List<MarketProductRecord> get trackedProducts => _trackedProducts;
  bool get isLoading => _isLoading;
  bool get isBusy => _isBusy;
  String? get error => _error;

  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;
  String get categoryFilter => _categoryFilter;

  Future<void> loadInitial() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _reloadData();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await _reloadData();
    notifyListeners();
  }

  Future<void> setSearchQuery(String value) async {
    _searchQuery = value;
    await _reloadItemsOnly();
    notifyListeners();
  }

  Future<void> setStatusFilter(String value) async {
    _statusFilter = value;
    await _reloadItemsOnly();
    notifyListeners();
  }

  Future<void> setCategoryFilter(String value) async {
    _categoryFilter = value;
    await _reloadData();
    notifyListeners();
  }

  Future<void> addOrUpdateItem({
    required int productId,
    required int quantity,
    required String unit,
    String supplier = '',
    String priority = 'Normal',
    String remarks = '',
  }) async {
    _isBusy = true;
    notifyListeners();

    try {
      await _manager.addOrUpdateItem(
        productId: productId,
        quantity: quantity,
        unit: unit,
        supplier: supplier,
        priority: priority,
        remarks: remarks,
      );
      await _reloadData();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> editItem({
    required int id,
    required int quantity,
    required String unit,
    String supplier = '',
    String priority = 'Normal',
    String remarks = '',
  }) async {
    _isBusy = true;
    notifyListeners();

    try {
      await _manager.editItem(
        id: id,
        quantity: quantity,
        unit: unit,
        supplier: supplier,
        priority: priority,
        remarks: remarks,
      );
      await _reloadData();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> deleteItem(int id) async {
    _isBusy = true;
    notifyListeners();

    try {
      await _manager.deleteItem(id);
      await _reloadData();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> togglePurchased(MorningPurchaseListItem item) async {
    _isBusy = true;
    notifyListeners();

    try {
      await _manager.markPurchased(id: item.id, purchased: !item.purchased);
      await _reloadItemsOnly();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> clearPurchased() async {
    _isBusy = true;
    notifyListeners();

    try {
      await _manager.clearPurchased();
      await _reloadData();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<int> generateTodayList() async {
    _isBusy = true;
    notifyListeners();

    try {
      final added = await _manager.generateTodayList();
      await _reloadData();
      return added;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<List<MorningPurchaseListItem>> purchasedForInventoryUpdate() {
    return _manager.purchasedForInventoryUpdate();
  }

  Future<void> markInventoryUpdated(int id) async {
    await _manager.markInventoryUpdated(id);
    await _reloadData();
    notifyListeners();
  }

  Future<String> whatsappText() => _manager.whatsappShareText();

  int get pendingCount => _items.where((item) => !item.purchased).length;

  int get purchasedCount => _items.where((item) => item.purchased).length;

  List<String> get categoryOptions {
    final values = <String>{'All'};
    for (final item in _trackedProducts) {
      values.add(item.category);
    }
    for (final item in _items) {
      values.add(item.category);
    }
    final list = values.toList();
    list.sort((a, b) {
      if (a == 'All') return -1;
      if (b == 'All') return 1;
      return a.compareTo(b);
    });
    return list;
  }

  Future<void> _reloadData() async {
    _trackedProducts = await _manager.trackedProducts(
      search: _searchQuery,
      category: _categoryFilter,
    );
    _items = await _manager.todayItems(
      search: _searchQuery,
      statusFilter: _statusFilter,
      category: _categoryFilter,
    );
    _error = null;
  }

  Future<void> _reloadItemsOnly() async {
    _items = await _manager.todayItems(
      search: _searchQuery,
      statusFilter: _statusFilter,
      category: _categoryFilter,
    );
    _error = null;
  }
}
