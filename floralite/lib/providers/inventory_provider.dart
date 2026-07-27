import 'package:flutter/foundation.dart';

import '../data/repositories/inventory_repository.dart';
import '../managers/inventory_manager.dart';
import '../services/business_data_event_bus.dart';

class InventoryProvider extends ChangeNotifier {
  InventoryProvider(this._inventoryManager, [this._businessDataEvents]);

  final InventoryManager _inventoryManager;
  final BusinessDataEventBus? _businessDataEvents;

  List<InventoryProductRecord> _products = const [];
  bool _isLoading = false;
  String? _error;
  String _query = '';
  String _filter = 'all';

  List<InventoryProductRecord> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get query => _query;
  String get filter => _filter;

  Future<void> loadProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _inventoryManager.listInventoryProducts();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('InventoryProvider.loadProducts failed: $e');
        debugPrintStack(stackTrace: st);
      }
      _error = 'Could not load inventory right now. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadProducts();

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setFilter(String value) {
    _filter = value;
    notifyListeners();
  }

  List<InventoryProductRecord> get filteredProducts {
    final query = _query.trim().toLowerCase();
    return _products.where((product) {
      final matchesQuery = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.sku.toLowerCase().contains(query) ||
          product.barcode.toLowerCase().contains(query);
      if (!matchesQuery) {
        return false;
      }

      switch (_filter) {
        case 'flower':
          return product.category == 'Flowers';
        case 'filler':
          return product.category == 'Fillers';
        case 'packing':
          return product.category == 'Packing';
        case 'accessory':
          return product.category == 'Accessories';
        case 'finished_product':
          return product.category == 'Finished Products' ||
              product.category == 'Finished Product';
        case 'low_stock':
          return product.trackInventory &&
              product.currentQty > 0 &&
              product.currentQty <= product.minQty;
        case 'out_of_stock':
          return product.trackInventory && product.currentQty == 0;
        case 'track_inventory':
          return product.trackInventory;
        case 'all':
        default:
          return true;
      }
    }).toList();
  }

  int get lowStockCount => _products
      .where((p) =>
          p.trackInventory && p.currentQty > 0 && p.currentQty <= p.minQty)
      .length;

  int get outOfStockCount =>
      _products.where((p) => p.trackInventory && p.currentQty == 0).length;

  Future<List<InventoryTransactionRecord>> loadHistory(int productId) {
    return _inventoryManager.listTransactionsForProduct(productId);
  }

  Future<void> purchase({
    required int productId,
    required int quantity,
    required int purchasePricePaise,
    String? supplier,
    String? note,
  }) async {
    await _inventoryManager.recordPurchase(
      productId: productId,
      quantity: quantity,
      purchasePricePaise: purchasePricePaise,
      supplier: supplier,
      note: note,
    );
    await loadProducts();
    _businessDataEvents?.publish(source: BusinessDataChangeSource.purchase);
  }

  Future<void> sale({
    required int productId,
    required int quantity,
    String? note,
  }) async {
    await _inventoryManager.recordManualSale(
      productId: productId,
      quantity: quantity,
      note: note,
    );
    await loadProducts();
    _businessDataEvents?.publish(source: BusinessDataChangeSource.sale);
  }

  Future<void> wastage({
    required int productId,
    required int quantity,
    required String reason,
    String? note,
  }) async {
    await _inventoryManager.recordWastage(
      productId: productId,
      quantity: quantity,
      reason: reason,
      note: note,
    );
    await loadProducts();
    _businessDataEvents?.publish(source: BusinessDataChangeSource.wastage);
  }

  Future<void> adjustment({
    required int productId,
    required int quantity,
    required bool increase,
    String? note,
  }) async {
    await _inventoryManager.recordAdjustment(
      productId: productId,
      quantity: quantity,
      increase: increase,
      note: note,
    );
    await loadProducts();
    _businessDataEvents?.publish(source: BusinessDataChangeSource.inventory);
  }
}
