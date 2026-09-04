import 'package:flutter/foundation.dart';

import '../data/repositories/inventory_repository.dart';
import '../data/repositories/cloud_inventory_repository.dart';
import '../managers/inventory_manager.dart';
import '../services/business_data_event_bus.dart';
import 'storage_mode_provider.dart';

class InventoryProvider extends ChangeNotifier {
  InventoryProvider(
    this._inventoryManager,
    this._storageModeProvider,
    this._cloudRepository, [
    this._businessDataEvents,
  ]);

  final InventoryManager _inventoryManager;
  final StorageModeProvider _storageModeProvider;
  final CloudInventoryRepository _cloudRepository;
  final BusinessDataEventBus? _businessDataEvents;

  List<InventoryProductRecord> _products = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  String _query = '';
  String _filter = 'all';

  List<InventoryProductRecord> get products => _products;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  String get query => _query;
  String get filter => _filter;
  bool get isCloud => _storageModeProvider.isCloud;

  Future<void> loadProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
        _products = isCloud
          ? await _cloudRepository.listInventoryProducts()
          : await _inventoryManager.listInventoryProducts();
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
            product.barcode.toLowerCase().contains(query) ||
            (product.manufacturerBarcode?.toLowerCase().contains(query) ??
              false) ||
            (product.internalBarcode?.toLowerCase().contains(query) ?? false);
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
    if (!isCloud) {
      return _inventoryManager.listTransactionsForProduct(productId);
    }
    return _cloudRepository.loadHistory(
      productId: _cloudProductId(productId),
      localProductId: productId,
    );
  }

  Future<InventoryProductRecord?> lookupCloudProduct(String value) async {
    final query = value.trim().toLowerCase();
    if (!isCloud || query.isEmpty) return null;
    for (final product in _products) {
      if (product.sku.toLowerCase() == query ||
          product.barcode.toLowerCase() == query ||
          product.manufacturerBarcode?.toLowerCase() == query ||
          product.internalBarcode?.toLowerCase() == query) {
        return product;
      }
    }
    final cloudProductId = await _cloudRepository.findProductIdByBarcode(value);
    if (cloudProductId == null) return null;
    for (final product in _products) {
      if (product.cloudProductId == cloudProductId) return product;
    }
    await loadProducts();
    for (final product in _products) {
      if (product.cloudProductId == cloudProductId) return product;
    }
    return null;
  }

  Future<void> purchase({
    required int productId,
    required int quantity,
    required int purchasePricePaise,
    String? supplier,
    String? note,
  }) async {
    await _runStockChange(() async {
    if (isCloud) {
      await _cloudRepository.applyStockChange(
        productId: _cloudProductId(productId),
        operation: 'purchase',
        quantity: quantity,
        purchasePricePaise: purchasePricePaise,
        supplier: supplier,
        note: note,
      );
    } else {
      await _inventoryManager.recordPurchase(
        productId: productId,
        quantity: quantity,
        purchasePricePaise: purchasePricePaise,
        supplier: supplier,
        note: note,
      );
    }
    await loadProducts();
    _businessDataEvents?.publish(source: BusinessDataChangeSource.purchase);
    });
  }

  Future<void> sale({
    required int productId,
    required int quantity,
    String? note,
  }) async {
    await _runStockChange(() async {
    if (isCloud) {
      await _cloudRepository.applyStockChange(
        productId: _cloudProductId(productId),
        operation: 'sale',
        quantity: quantity,
        note: note,
      );
    } else {
      await _inventoryManager.recordManualSale(
        productId: productId,
        quantity: quantity,
        note: note,
      );
    }
    await loadProducts();
    _businessDataEvents?.publish(source: BusinessDataChangeSource.sale);
    });
  }

  Future<void> wastage({
    required int productId,
    required int quantity,
    required String reason,
    String? note,
  }) async {
    await _runStockChange(() async {
    if (isCloud) {
      await _cloudRepository.applyStockChange(
        productId: _cloudProductId(productId),
        operation: 'wastage',
        quantity: quantity,
        reason: reason,
        note: note,
      );
    } else {
      await _inventoryManager.recordWastage(
        productId: productId,
        quantity: quantity,
        reason: reason,
        note: note,
      );
    }
    await loadProducts();
    _businessDataEvents?.publish(source: BusinessDataChangeSource.wastage);
    });
  }

  Future<void> adjustment({
    required int productId,
    required int quantity,
    required bool increase,
    String? note,
  }) async {
    await _runStockChange(() async {
    if (isCloud) {
      await _cloudRepository.applyStockChange(
        productId: _cloudProductId(productId),
        operation: 'adjustment',
        quantity: quantity,
        increase: increase,
        note: note,
      );
    } else {
      await _inventoryManager.recordAdjustment(
        productId: productId,
        quantity: quantity,
        increase: increase,
        note: note,
      );
    }
    await loadProducts();
    _businessDataEvents?.publish(source: BusinessDataChangeSource.inventory);
    });
  }

  String _cloudProductId(int productId) {
    for (final product in _products) {
      if (product.productId == productId && product.cloudProductId != null) {
        return product.cloudProductId!;
      }
    }
    throw StateError('Cloud inventory product is no longer available.');
  }

  Future<void> _runStockChange(Future<void> Function() action) async {
    if (_isSaving) {
      throw StateError('Another inventory change is already being saved.');
    }
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } catch (_) {
      _error = 'Inventory change could not be saved. Please try again.';
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
