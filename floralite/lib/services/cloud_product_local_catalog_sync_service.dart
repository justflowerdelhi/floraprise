import '../data/repositories/cloud_inventory_repository.dart';
import '../data/repositories/cloud_product_repository.dart';
import '../data/repositories/inventory_repository.dart';
import '../data/repositories/product_repository.dart';
import '../models/gst_calculation_type.dart';
import 'mobile_auth_service.dart';
import 'product_cloud_syncability_service.dart';

typedef CloudProductListLoader = Future<List<CloudProduct>> Function({
  String query,
  String? category,
  bool? trackInventory,
  bool showActive,
  bool showInactive,
});
typedef CloudInventoryListLoader = Future<List<InventoryProductRecord>> Function();
typedef CurrentCompanyIdLoader = Future<String?> Function();

class CloudProductLocalCatalogSyncResult {
  const CloudProductLocalCatalogSyncResult({
    required this.createdCount,
    required this.updatedCount,
    required this.inactiveCount,
    required this.stockInitializedCount,
    required this.skippedCount,
    required this.errors,
  });

  final int createdCount;
  final int updatedCount;
  final int inactiveCount;
  final int stockInitializedCount;
  final int skippedCount;
  final List<String> errors;

  bool get hasErrors => errors.isNotEmpty;

  String get summary {
    final parts = <String>[
      '$createdCount Cloud products imported',
      '$updatedCount updated',
    ];
    if (inactiveCount > 0) parts.add('$inactiveCount inactive');
    if (stockInitializedCount > 0) {
      parts.add('$stockInitializedCount stock initialized');
    }
    if (skippedCount > 0) parts.add('$skippedCount skipped');
    return '${parts.join(', ')}.';
  }
}

class CloudProductLocalCatalogSyncService {
  CloudProductLocalCatalogSyncService({
    CloudProductRepository? cloudProductRepository,
    CloudInventoryRepository? cloudInventoryRepository,
    ProductRepository? productRepository,
    MobileAuthService? auth,
    CloudProductListLoader? loadCloudProducts,
    CloudInventoryListLoader? loadCloudInventory,
    CurrentCompanyIdLoader? currentCompanyId,
  })  : _cloudProductRepository =
            cloudProductRepository ?? CloudProductRepository(auth: auth),
        _cloudInventoryRepository =
            cloudInventoryRepository ?? CloudInventoryRepository(auth: auth),
        _productRepository = productRepository ?? ProductRepository(),
        _currentCompanyId = currentCompanyId ??
            (() => ProductCloudSyncabilityService.currentCompanyIdFromAuth(
                  auth ?? MobileAuthService(),
                )),
        _loadCloudProducts = loadCloudProducts,
        _loadCloudInventory = loadCloudInventory;

  final CloudProductRepository _cloudProductRepository;
  final CloudInventoryRepository _cloudInventoryRepository;
  final ProductRepository _productRepository;
  final CurrentCompanyIdLoader _currentCompanyId;
  final CloudProductListLoader? _loadCloudProducts;
  final CloudInventoryListLoader? _loadCloudInventory;

  Future<CloudProductLocalCatalogSyncResult> syncForCurrentCompany({
    bool includeInactive = false,
    bool updateExisting = true,
    bool refreshInitialStock = true,
  }) async {
    final companyId = ProductCloudSyncabilityService.normalizeUuid(
      await _currentCompanyId(),
    );
    if (companyId == null) {
      throw StateError('Current authenticated company is not available.');
    }

    final cloudProducts = await (_loadCloudProducts ?? _cloudProductRepository.listProducts)(
      query: '',
      category: null,
      trackInventory: null,
      showActive: true,
      showInactive: includeInactive,
    );
    final stockByCloudProductId = <String, InventoryProductRecord>{};
    if (refreshInitialStock) {
      final inventory = await (_loadCloudInventory ??
          _cloudInventoryRepository.listInventoryProducts)();
      for (final item in inventory) {
        final cloudProductId = ProductCloudSyncabilityService.normalizeUuid(
          item.cloudProductId,
        );
        if (cloudProductId != null) {
          stockByCloudProductId[cloudProductId] = item;
        }
      }
    }

    var created = 0;
    var updated = 0;
    var inactive = 0;
    var stockInitialized = 0;
    var skipped = 0;
    final errors = <String>[];

    for (final product in cloudProducts) {
      final cloudProductId = ProductCloudSyncabilityService.normalizeUuid(
        product.id,
      );
      if (cloudProductId == null) {
        skipped++;
        errors.add('${product.name}: invalid Cloud product ID');
        continue;
      }

      final productCompanyId = ProductCloudSyncabilityService.normalizeUuid(
        product.companyId,
      );
      if (productCompanyId != null && productCompanyId != companyId) {
        skipped++;
        errors.add('${product.name}: Cloud product belongs to another company');
        continue;
      }

      final stock = stockByCloudProductId[cloudProductId];
      final minStock = _minStock(product, stock);
      final input = ProductUpsertInput(
        name: product.name,
        category: _localCategory(product.category),
        defaultUnit: _localUnit(product.unitOfMeasure),
        sellingPricePaise: _moneyToPaise(product.retailPrice),
        purchasePricePaise: _moneyToPaise(product.costPrice),
        gstPercent: _gstPercent(product.taxCategory),
        gstCalculationType: GstCalculationType.inclusive,
        sku: product.sku,
        manufacturerBarcode:
            product.manufacturerBarcode ?? product.barcode ?? '',
        florapriseBarcode: '',
        trackInventory: product.trackInventory,
        minStock: minStock,
        supplier: '',
        notes: product.description ?? '',
        active: product.isActive,
        favorite: false,
      );

      try {
        final result = await _productRepository.upsertCloudImportedProduct(
          input: input,
          cloudProductId: cloudProductId,
          cloudProductCompanyId: companyId,
          updateExisting: updateExisting,
          initialCurrentQty: stock?.currentQty,
          initialMinQty: stock?.minQty ?? minStock,
        );
        if (result.created) created++;
        if (result.updated) updated++;
        if (result.stockInitialized) stockInitialized++;
        if (result.skipped) skipped++;
        if (!product.isActive) inactive++;
      } catch (error) {
        skipped++;
        errors.add('${product.name}: $error');
      }
    }

    return CloudProductLocalCatalogSyncResult(
      createdCount: created,
      updatedCount: updated,
      inactiveCount: inactive,
      stockInitializedCount: stockInitialized,
      skippedCount: skipped,
      errors: errors,
    );
  }

  static String _localCategory(String value) {
    final trimmed = value.trim();
    if (trimmed == 'Other') return 'Others';
    return ProductRepository.allowedCategories.contains(trimmed)
        ? trimmed
        : 'Others';
  }

  static String _localUnit(String value) {
    final trimmed = value.trim();
    final mapped = switch (trimmed) {
      'Kilogram' => 'Kg',
      'Pack' => 'Packet',
      _ => trimmed,
    };
    return ProductRepository.allowedUnits.contains(mapped) ? mapped : 'Piece';
  }

  static int _moneyToPaise(double value) => (value * 100).round();

  static int _minStock(CloudProduct product, InventoryProductRecord? stock) {
    if (stock != null && stock.minQty > 0) return stock.minQty;
    if (product.minimumStockLevel > 0) return product.minimumStockLevel;
    if (product.reorderLevel > 0) return product.reorderLevel;
    return 0;
  }

  static int _gstPercent(String taxCategory) {
    return switch (taxCategory.trim().toLowerCase()) {
      'none' || 'zero' => 0,
      'reduced' => 5,
      _ => 12,
    };
  }
}