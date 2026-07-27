import 'package:flutter/foundation.dart';
import '../data/repositories/purchase_repository.dart';
import '../managers/purchase_manager.dart';
import '../services/business_data_event_bus.dart';
import '../services/whatsapp_template_service.dart';

class VoicePurchaseUpsertResult {
  const VoicePurchaseUpsertResult({
    required this.merged,
    required this.totalQuantity,
  });

  final bool merged;
  final int totalQuantity;
}

class PurchaseProvider extends ChangeNotifier {
  PurchaseProvider(this._purchaseManager, [this._businessDataEvents]);

  final PurchaseManager _purchaseManager;
  final BusinessDataEventBus? _businessDataEvents;

  List<PurchaseListItem> _items = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _filterStatus = 'all'; // 'all', 'pending', 'purchased'
  String _filterCategory = 'all';

  List<PurchaseListItem> get items => _filteredItems;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get pendingCount => _items.where((i) => !i.purchased).length;
  int get purchasedCount => _items.where((i) => i.purchased).length;
  String get filterStatus => _filterStatus;
  String get filterCategory => _filterCategory;

  List<PurchaseListItem> get _filteredItems {
    var filtered = _items;

    // Apply search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        final name = item.productName.toLowerCase();
        final category = item.productCategory.toLowerCase();
        return name.contains(_searchQuery.toLowerCase()) ||
            category.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply status filter
    if (_filterStatus == 'pending') {
      filtered = filtered.where((i) => !i.purchased).toList();
    } else if (_filterStatus == 'purchased') {
      filtered = filtered.where((i) => i.purchased).toList();
    }

    // Apply category filter
    if (_filterCategory != 'all') {
      filtered =
          filtered.where((i) => i.productCategory == _filterCategory).toList();
    }

    return filtered;
  }

  Map<String, List<PurchaseListItem>> get groupedItems {
    final grouped = <String, List<PurchaseListItem>>{};
    for (final item in _filteredItems) {
      grouped.putIfAbsent(item.productCategory, () => []).add(item);
    }
    return grouped;
  }

  List<String> get categories {
    final cats = _items.map((i) => i.productCategory).toSet().toList();
    cats.sort();
    return cats;
  }

  Future<void> loadItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _purchaseManager.getTodayList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String value) {
    _filterStatus = value;
    notifyListeners();
  }

  void setCategoryFilter(String value) {
    _filterCategory = value;
    notifyListeners();
  }

  void clearFilters() {
    _filterStatus = 'all';
    _filterCategory = 'all';
    _searchQuery = '';
    notifyListeners();
  }

  Future<bool> addItem({
    required int productId,
    required int quantity,
    required String unit,
    String? supplier,
    String priority = 'Normal',
    String? remarks,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _purchaseManager.addItem(
        productId: productId,
        quantity: quantity,
        unit: unit,
        supplier: supplier,
        priority: priority,
        remarks: remarks,
      );

      await loadItems();
      _businessDataEvents?.publish(source: BusinessDataChangeSource.purchase);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<VoicePurchaseUpsertResult> addOrMergeVoiceItem({
    required int productId,
    required int quantity,
    required String unit,
  }) async {
    if (quantity <= 0) {
      throw ArgumentError.value(quantity, 'quantity', 'Must be greater than 0');
    }

    try {
      PurchaseListItem? existing;
      for (final item in _items) {
        if (item.productId == productId) {
          existing = item;
          break;
        }
      }

      var merged = false;
      var totalQuantity = quantity;

      if (existing != null) {
        merged = true;
        totalQuantity = existing.quantity + quantity;
        await _purchaseManager.updateItem(
          id: existing.id,
          quantity: totalQuantity,
          unit: existing.unit,
        );
      } else {
        await _purchaseManager.addItem(
          productId: productId,
          quantity: quantity,
          unit: unit,
        );
      }

      _items = await _purchaseManager.getTodayList();

      for (final item in _items) {
        if (item.productId == productId) {
          totalQuantity = item.quantity;
          break;
        }
      }

      _businessDataEvents?.publish(source: BusinessDataChangeSource.purchase);
      notifyListeners();

      return VoicePurchaseUpsertResult(
        merged: merged,
        totalQuantity: totalQuantity,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> updateItem({
    required int id,
    int? quantity,
    String? unit,
    String? supplier,
    String? priority,
    String? remarks,
    bool? purchased,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _purchaseManager.updateItem(
        id: id,
        quantity: quantity,
        unit: unit,
        supplier: supplier,
        priority: priority,
        remarks: remarks,
        purchased: purchased,
      );

      await loadItems();
      _businessDataEvents?.publish(source: BusinessDataChangeSource.purchase);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteItem(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _purchaseManager.deleteItem(id);

      _items.removeWhere((i) => i.id == id);
      _businessDataEvents?.publish(source: BusinessDataChangeSource.purchase);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> togglePurchased(int id) async {
    final item = _items.firstWhere((i) => i.id == id);
    final newPurchased = !item.purchased;

    return updateItem(id: id, purchased: newPurchased);
  }

  Future<bool> clearPurchased() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _purchaseManager.clearAllPurchased();

      await loadItems();
      _businessDataEvents?.publish(source: BusinessDataChangeSource.purchase);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getInventoryTrackedProducts() async {
    return _purchaseManager.getInventoryTrackedProducts();
  }

  Future<List<Map<String, dynamic>>> getLowStockProducts() async {
    return _purchaseManager.getLowStockProducts();
  }

  Future<bool> generateAutoSuggestedItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _purchaseManager.generateAutoSuggestedItems();

      await loadItems();
      _businessDataEvents?.publish(source: BusinessDataChangeSource.purchase);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String> generateWhatsAppText() async {
    final items = _items
        .where((item) => !item.purchased)
        .map(
          (item) => WhatsAppItemLine(
            name: item.productName,
            quantity: item.quantity,
            unit: item.unit,
            category: item.productCategory,
          ),
        )
        .toList();
    return WhatsAppTemplateService().purchaseList(
      items: items,
      requestedBy: null,
    );
  }

  Future<void> refresh() async {
    await loadItems();
  }
}
