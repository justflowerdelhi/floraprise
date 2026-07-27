import '../data/repositories/morning_purchase_list_repository.dart';

class MorningPurchaseListManager {
  MorningPurchaseListManager(this._repository);

  final MorningPurchaseListRepository _repository;

  Future<List<MarketProductRecord>> trackedProducts({
    String search = '',
    String category = 'All',
  }) {
    return _repository.listTrackedProducts(search: search, category: category);
  }

  Future<List<MorningPurchaseListItem>> todayItems({
    String search = '',
    String statusFilter = 'All',
    String category = 'All',
  }) {
    return _repository.listTodayItems(
      search: search,
      statusFilter: statusFilter,
      category: category,
    );
  }

  Future<void> addOrUpdateItem({
    required int productId,
    required int quantity,
    required String unit,
    String supplier = '',
    String priority = 'Normal',
    String remarks = '',
  }) {
    if (quantity <= 0) {
      throw ArgumentError('Quantity should be greater than zero');
    }
    return _repository.addOrUpdateTodayItem(
      productId: productId,
      quantity: quantity,
      unit: unit,
      supplier: supplier,
      priority: priority,
      remarks: remarks,
    );
  }

  Future<void> editItem({
    required int id,
    required int quantity,
    required String unit,
    String supplier = '',
    String priority = 'Normal',
    String remarks = '',
  }) {
    if (quantity <= 0) {
      throw ArgumentError('Quantity should be greater than zero');
    }
    return _repository.updateItem(
      id: id,
      quantity: quantity,
      unit: unit,
      supplier: supplier,
      priority: priority,
      remarks: remarks,
    );
  }

  Future<void> deleteItem(int id) => _repository.deleteItem(id);

  Future<void> markPurchased({required int id, required bool purchased}) {
    return _repository.setPurchased(id: id, purchased: purchased);
  }

  Future<void> clearPurchased() => _repository.clearPurchased();

  Future<int> generateTodayList() => _repository.generateFromLowStock();

  Future<List<MorningPurchaseListItem>> purchasedForInventoryUpdate() {
    return _repository.listPurchasedForInventoryUpdate();
  }

  Future<void> markInventoryUpdated(int id) =>
      _repository.markInventoryUpdated(id);

  Future<String> whatsappShareText() => _repository.buildWhatsappText();

  Future<int> todayCount() => _repository.todayCount();
}
