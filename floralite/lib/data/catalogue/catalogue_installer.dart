import '../repositories/product_repository.dart';
import '../repositories/inventory_repository.dart';
import 'starter_catalogue.dart';

class CatalogueInstaller {
  static const List<_LegacyDemoProductSpec> _legacyDemoProducts = [
    _LegacyDemoProductSpec(
      name: 'Red Rose Stem',
      category: 'Flowers',
      defaultUnit: 'Stem',
      sellingPricePaise: 3500,
      gstPercent: 5,
      manufacturerBarcode: '890100100001',
    ),
    _LegacyDemoProductSpec(
      name: 'White Lily Stem',
      category: 'Flowers',
      defaultUnit: 'Stem',
      sellingPricePaise: 9000,
      gstPercent: 5,
      manufacturerBarcode: '890100100002',
    ),
    _LegacyDemoProductSpec(
      name: 'Orchid Bunch',
      category: 'Flowers',
      defaultUnit: 'Bunch',
      sellingPricePaise: 18000,
      gstPercent: 5,
      manufacturerBarcode: '890100100003',
    ),
    _LegacyDemoProductSpec(
      name: 'Baby Breath Bunch',
      category: 'Fillers',
      defaultUnit: 'Bunch',
      sellingPricePaise: 7000,
      gstPercent: 5,
      manufacturerBarcode: '890100100004',
    ),
    _LegacyDemoProductSpec(
      name: 'Ruscus Bunch',
      category: 'Foliage',
      defaultUnit: 'Bunch',
      sellingPricePaise: 5500,
      gstPercent: 5,
      manufacturerBarcode: '890100100005',
    ),
    _LegacyDemoProductSpec(
      name: 'Ferrero Rocher 16pc',
      category: 'Chocolates',
      defaultUnit: 'Box',
      sellingPricePaise: 89000,
      gstPercent: 12,
      manufacturerBarcode: '8000500310428',
    ),
    _LegacyDemoProductSpec(
      name: 'Cadbury Celebrations',
      category: 'Chocolates',
      defaultUnit: 'Box',
      sellingPricePaise: 45000,
      gstPercent: 12,
      manufacturerBarcode: '7622201132529',
    ),
    _LegacyDemoProductSpec(
      name: 'Teddy Bear 12inch',
      category: 'Soft Toys',
      defaultUnit: 'Piece',
      sellingPricePaise: 65000,
      gstPercent: 12,
      manufacturerBarcode: '890100100006',
    ),
    _LegacyDemoProductSpec(
      name: 'Black Forest 1kg',
      category: 'Cakes',
      defaultUnit: 'Piece',
      sellingPricePaise: 95000,
      gstPercent: 5,
      manufacturerBarcode: '890100100007',
    ),
    _LegacyDemoProductSpec(
      name: 'Helium Balloon',
      category: 'Balloons',
      defaultUnit: 'Piece',
      sellingPricePaise: 12000,
      gstPercent: 12,
      manufacturerBarcode: '890100100008',
    ),
    _LegacyDemoProductSpec(
      name: 'Ceramic Vase Medium',
      category: 'Vases',
      defaultUnit: 'Piece',
      sellingPricePaise: 48000,
      gstPercent: 12,
      manufacturerBarcode: '890100100009',
    ),
    _LegacyDemoProductSpec(
      name: 'Willow Basket Large',
      category: 'Baskets',
      defaultUnit: 'Piece',
      sellingPricePaise: 55000,
      gstPercent: 12,
      manufacturerBarcode: '890100100010',
    ),
    _LegacyDemoProductSpec(
      name: 'Wrapper Sheet Premium',
      category: 'Packing',
      defaultUnit: 'Piece',
      sellingPricePaise: 3500,
      gstPercent: 12,
      manufacturerBarcode: '890100100011',
    ),
    _LegacyDemoProductSpec(
      name: 'Ribbon Roll Satin',
      category: 'Accessories',
      defaultUnit: 'Roll',
      sellingPricePaise: 9500,
      gstPercent: 12,
      manufacturerBarcode: '890100100012',
    ),
    _LegacyDemoProductSpec(
      name: 'Money Plant Pot',
      category: 'Plants',
      defaultUnit: 'Pot',
      sellingPricePaise: 32000,
      gstPercent: 5,
      manufacturerBarcode: '890100100013',
    ),
    _LegacyDemoProductSpec(
      name: 'Classic Rose Bouquet',
      category: 'Finished Bouquets',
      defaultUnit: 'Piece',
      sellingPricePaise: 149000,
      gstPercent: 12,
      manufacturerBarcode: '890100100014',
    ),
    _LegacyDemoProductSpec(
      name: 'Assorted Flower Basket',
      category: 'Finished Bouquets',
      defaultUnit: 'Piece',
      sellingPricePaise: 229000,
      gstPercent: 12,
      manufacturerBarcode: '890100100015',
    ),
  ];

  final ProductRepository _productRepository;

  CatalogueInstaller({
    required ProductRepository productRepository,
    required InventoryRepository inventoryRepository,
  }) : _productRepository = productRepository;

  Future<CatalogueInstallResult> installStarterCatalogue({
    bool replaceLegacyDemoOnly = false,
  }) async {
    int successCount = 0;
    int failureCount = 0;
    int skippedCount = 0;
    final List<String> errors = [];
    var existingProducts = await _productRepository.listProducts(
      showActive: true,
      showInactive: true,
      includeDeleted: false,
    );

    int removedLegacyDemoCount = 0;
    if (replaceLegacyDemoOnly && _isLegacyDemoOnlyDataset(existingProducts)) {
      for (final product in existingProducts) {
        await _productRepository.softDeleteProduct(product.id);
      }
      removedLegacyDemoCount = existingProducts.length;
      existingProducts = const [];
    }

    final existingNames = existingProducts
        .map((product) => product.name.trim().toLowerCase())
        .toSet();

    for (final product in StarterCatalogue.products) {
      final normalizedName = product.name.trim().toLowerCase();
      if (existingNames.contains(normalizedName)) {
        skippedCount++;
        continue;
      }

      try {
        final input = product.toProductInput();
        await _productRepository.createProduct(input);
        existingNames.add(normalizedName);

        // Skip inventory for now to isolate the issue
        // if (product.trackInventory) {
        //   await _inventoryRepository.createAdjustmentTransaction(
        //     productId: productId,
        //     quantity: 1,
        //     increase: true,
        //     note: 'Opening Stock - Starter Catalogue',
        //   );
        // }

        successCount++;
      } catch (e, stackTrace) {
        failureCount++;
        errors.add('${product.name}: $e\n$stackTrace');
      }
    }

    return CatalogueInstallResult(
      totalProducts: StarterCatalogue.products.length,
      successCount: successCount,
      failureCount: failureCount,
      skippedCount: skippedCount,
      replacedLegacyDemoProducts: removedLegacyDemoCount > 0,
      removedLegacyDemoCount: removedLegacyDemoCount,
      errors: errors,
    );
  }

  bool _isLegacyDemoOnlyDataset(List<ProductRecord> existingProducts) {
    if (existingProducts.isEmpty) {
      return false;
    }

    final specsByName = <String, _LegacyDemoProductSpec>{
      for (final spec in _legacyDemoProducts) spec.normalizedName: spec,
    };

    for (final product in existingProducts) {
      final spec = specsByName[product.name.trim().toLowerCase()];
      if (spec == null) {
        return false;
      }

      if (!_matchesLegacyDemoSpec(product, spec)) {
        return false;
      }

      final wasModified =
          product.updatedAt.trim() != product.createdAt.trim() ||
              !product.active ||
              product.favorite;
      if (wasModified) {
        return false;
      }
    }

    return true;
  }

  bool _matchesLegacyDemoSpec(
    ProductRecord product,
    _LegacyDemoProductSpec spec,
  ) {
    return product.category.trim() == spec.category &&
        product.defaultUnit.trim() == spec.defaultUnit &&
        product.sellingPricePaise == spec.sellingPricePaise &&
        product.gstPercent == spec.gstPercent &&
        product.manufacturerBarcode.trim().toLowerCase() ==
            spec.manufacturerBarcode;
  }

  Future<bool> isCatalogueInstalled() async {
    // Check if any product from the starter catalogue exists
    for (final product in StarterCatalogue.products) {
      final existing = await _productRepository.listProducts(
        includeDeleted: false,
        query: product.name,
      );
      if (existing.isNotEmpty) {
        return true;
      }
    }
    return false;
  }
}

class CatalogueInstallResult {
  final int totalProducts;
  final int successCount;
  final int failureCount;
  final int skippedCount;
  final bool replacedLegacyDemoProducts;
  final int removedLegacyDemoCount;
  final List<String> errors;

  CatalogueInstallResult({
    required this.totalProducts,
    required this.successCount,
    required this.failureCount,
    this.skippedCount = 0,
    this.replacedLegacyDemoProducts = false,
    this.removedLegacyDemoCount = 0,
    required this.errors,
  });

  bool get isSuccess => failureCount == 0;
  double get successPercentage =>
      totalProducts > 0 ? (successCount / totalProducts) * 100 : 0;
}

class _LegacyDemoProductSpec {
  const _LegacyDemoProductSpec({
    required this.name,
    required this.category,
    required this.defaultUnit,
    required this.sellingPricePaise,
    required this.gstPercent,
    required this.manufacturerBarcode,
  });

  final String name;
  final String category;
  final String defaultUnit;
  final int sellingPricePaise;
  final int gstPercent;
  final String manufacturerBarcode;

  String get normalizedName => name.trim().toLowerCase();
}
