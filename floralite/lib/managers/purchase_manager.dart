import '../data/repositories/purchase_repository.dart';

class PurchaseManager {
  PurchaseManager(this._purchaseRepository);

  final PurchaseRepository _purchaseRepository;

  String getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<List<PurchaseListItem>> getTodayList() async {
    final today = getTodayDateString();
    return _purchaseRepository.getByDate(today);
  }

  Future<PurchaseListItem> addItem({
    required int productId,
    required int quantity,
    required String unit,
    String? supplier,
    String priority = 'Normal',
    String? remarks,
  }) async {
    final today = getTodayDateString();
    return _purchaseRepository.create(
      listDate: today,
      productId: productId,
      quantity: quantity,
      unit: unit,
      supplier: supplier,
      priority: priority,
      remarks: remarks,
    );
  }

  Future<void> updateItem({
    required int id,
    int? quantity,
    String? unit,
    String? supplier,
    String? priority,
    String? remarks,
    bool? purchased,
  }) async {
    await _purchaseRepository.update(
      id: id,
      quantity: quantity,
      unit: unit,
      supplier: supplier,
      priority: priority,
      remarks: remarks,
      purchased: purchased,
    );
  }

  Future<void> deleteItem(int id) async {
    await _purchaseRepository.delete(id);
  }

  Future<void> markAsPurchased(int id) async {
    await _purchaseRepository.update(id: id, purchased: true);
  }

  Future<void> markAsNotPurchased(int id) async {
    await _purchaseRepository.update(id: id, purchased: false);
  }

  Future<void> clearAllPurchased() async {
    final today = getTodayDateString();
    await _purchaseRepository.clearPurchased(today);
  }

  Future<int> getPendingCount() async {
    final today = getTodayDateString();
    return _purchaseRepository.getPendingCount(today);
  }

  Future<int> getPurchasedCount() async {
    final today = getTodayDateString();
    return _purchaseRepository.getPurchasedCount(today);
  }

  Future<List<Map<String, dynamic>>> getInventoryTrackedProducts() async {
    return _purchaseRepository.getInventoryTrackedProducts();
  }

  Future<List<Map<String, dynamic>>> getLowStockProducts() async {
    return _purchaseRepository.getLowStockProducts();
  }

  Future<void> generateAutoSuggestedItems() async {
    final lowStockProducts = await getLowStockProducts();
    final today = getTodayDateString();
    
    for (final product in lowStockProducts) {
      try {
        await _purchaseRepository.create(
          listDate: today,
          productId: product['id'] as int,
          quantity: product['suggested_qty'] as int,
          unit: product['default_unit'] as String,
          priority: 'High',
          remarks: 'Auto-generated based on low stock',
        );
      } catch (e) {
        // Ignore duplicate errors (product already in list)
        continue;
      }
    }
  }
}
