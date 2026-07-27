import '../data/repositories/inventory_repository.dart';

class InventoryManager {
  InventoryManager(this._inventoryRepository);

  final InventoryRepository _inventoryRepository;

  Future<void> recordOrderSales({
    required int orderId,
    required List<Map<String, int>> lineProductLinks,
  }) async {
    for (final link in lineProductLinks) {
      await _inventoryRepository.createSaleTransaction(
        productId: link['productId']!,
        orderId: orderId,
        orderLineId: link['orderLineId']!,
        quantity: link['qty']!,
        note: 'Walk-in confirmed order deduction',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getLowStockItems({int limit = 5}) {
    return _inventoryRepository.getLowStockItems(limit: limit);
  }

  Future<int> getLowStockCount() {
    return _inventoryRepository.getLowStockCount();
  }

  Future<int> getOutOfStockCount() {
    return _inventoryRepository.getOutOfStockCount();
  }

  Future<List<InventoryProductRecord>> listInventoryProducts() {
    return _inventoryRepository.listInventoryProducts();
  }

  Future<List<InventoryTransactionRecord>> listTransactionsForProduct(
    int productId,
  ) {
    return _inventoryRepository.listTransactionsForProduct(productId);
  }

  Future<void> recordPurchase({
    required int productId,
    required int quantity,
    required int purchasePricePaise,
    String? supplier,
    String? note,
  }) {
    return _inventoryRepository.createPurchaseTransaction(
      productId: productId,
      quantity: quantity,
      purchasePricePaise: purchasePricePaise,
      supplier: supplier,
      note: note,
    );
  }

  Future<void> recordManualSale({
    required int productId,
    required int quantity,
    String? note,
  }) {
    return _inventoryRepository.createManualSaleTransaction(
      productId: productId,
      quantity: quantity,
      note: note,
    );
  }

  Future<void> recordWastage({
    required int productId,
    required int quantity,
    required String reason,
    String? note,
  }) {
    return _inventoryRepository.createWastageTransaction(
      productId: productId,
      quantity: quantity,
      reason: reason,
      note: note,
    );
  }

  Future<void> recordAdjustment({
    required int productId,
    required int quantity,
    required bool increase,
    String? note,
  }) {
    return _inventoryRepository.createAdjustmentTransaction(
      productId: productId,
      quantity: quantity,
      increase: increase,
      note: note,
    );
  }
}
