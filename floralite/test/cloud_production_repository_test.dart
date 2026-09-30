import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/data/repositories/cloud_production_repository.dart';
import 'package:floraprise/data/repositories/production_repository.dart';
import 'package:floraprise/services/storage_mode_service.dart';
import 'package:floraprise/models/storage_mode.dart';

class _FakeStorageModeService extends StorageModeService {
  final StorageMode _mode;
  _FakeStorageModeService(this._mode);

  @override
  Future<StorageMode?> getCurrentMode() async => _mode;
  @override
  Future<bool> isCloud() async => _mode == StorageMode.cloud;
  @override
  Future<bool> isLocal() async => _mode == StorageMode.local;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CloudProductionRepository Unit Tests', () {
    test('listFinishedProducts fetches recipes from GET /api/production/recipes', () async {
      final repo = CloudProductionRepository(
        sender: (method, uri, {body}) async {
          expect(method, 'GET');
          expect(uri.path, '/api/production/recipes');
          return [
            {
              'id': 'recipe-guid-1',
              'name': 'Luxury Rose Bunch',
              'category': 'Bouquet',
              'sellingPrice': 45.0,
              'laborCost': 5.0,
              'sampleImages': ['https://images.example.com/rose.jpg'],
              'isActive': true,
            }
          ];
        },
      );

      final products = await repo.listFinishedProducts();
      expect(products.length, 1);
      expect(products.first.name, 'Luxury Rose Bunch');
      expect(products.first.sellingPricePaise, 4500);
      expect(products.first.hasRecipe, isTrue);
      expect(products.first.unit, 'Piece');
    });

    test('getRecipeDetail fetches recipe and its components', () async {
      final repo = CloudProductionRepository(
        sender: (method, uri, {body}) async {
          expect(method, 'GET');
          expect(uri.path, contains('/api/production/recipes/'));
          return {
            'id': 'recipe-guid-1',
            'name': 'Luxury Rose Bunch',
            'category': 'Bouquet',
            'sellingPrice': 45.0,
            'laborCost': 5.0,
            'sampleImages': ['https://images.example.com/rose.jpg'],
            'components': [
              {
                'productId': 'prod-rose-guid',
                'productName': 'Red Rose',
                'quantityRequired': 12,
                'unitCost': 1.5,
              }
            ],
            'isActive': true,
          };
        },
      );

      final detail = await repo.getRecipeDetail(1);
      expect(detail, isNotNull);
      expect(detail!.name, 'Luxury Rose Bunch');
      expect(detail.sellingPricePaise, 4500);
      expect(detail.labourCostPaise, 500);
      expect(detail.imagePath, 'https://images.example.com/rose.jpg');
      expect(detail.items.length, 1);
      expect(detail.items.first.productName, 'Red Rose');
      expect(detail.items.first.quantity, 12);
      expect(detail.items.first.purchasePricePaise, 150);
      expect(detail.items.first.cloudProductId, 'prod-rose-guid');
    });

    test('saveBouquetRecipe calls POST /api/production/recipes for new recipe', () async {
      var postCalled = false;
      final repo = CloudProductionRepository(
        sender: (method, uri, {body}) async {
          expect(method, 'POST');
          expect(uri.path, '/api/production/recipes');
          expect(body!['name'], 'Exotic Orchid Basket');
          expect(body['category'], 'Basket Arrangement');
          expect(body['sellingPrice'], 60.0);
          expect(body['laborCost'], 10.0);
          expect((body['components'] as List).length, 1);
          postCalled = true;
          return {
            'id': 'new-recipe-guid-99',
            'name': 'Exotic Orchid Basket',
            'category': 'Basket Arrangement',
            'sellingPrice': 60.0,
          };
        },
      );

      final recipeId = await repo.saveBouquetRecipe(
        productName: 'Exotic Orchid Basket',
        category: 'Basket Arrangement',
        sellingPricePaise: 6000,
        labourCostPaise: 1000,
        items: const [
          RecipeItem(
            rawProductId: 10,
            cloudProductId: 'orchid-guid',
            productName: 'Purple Orchid',
            unit: 'Stem',
            quantity: 5,
            currentQty: 20,
            purchasePricePaise: 400,
          ),
        ],
      );

      expect(postCalled, isTrue);
      expect(recipeId, isPositive);
    });

    test('produceBouquet creates recipe if needed and calls POST /api/production/runs', () async {
      final requests = <String>[];
      final repo = CloudProductionRepository(
        sender: (method, uri, {body}) async {
          requests.add('$method ${uri.path}');
          if (uri.path == '/api/locations') {
            return [
              {'id': 'location-store-guid', 'name': 'Main Store'}
            ];
          }
          if (method == 'POST' && uri.path == '/api/production/recipes') {
            return {
              'id': 'recipe-guid-abc',
              'name': 'Sunflower Delight',
              'category': 'Bouquet',
              'sellingPrice': 35.0,
            };
          }
          if (method == 'POST' && uri.path == '/api/production/runs') {
            expect(body!['recipeId'], 'recipe-guid-abc');
            expect(body['quantity'], 3);
            expect(body['locationId'], 'location-store-guid');
            expect(body['operatorName'], 'Florist Sunita');
            return {
              'batchId': 'batch-guid-xyz',
              'batchCode': 'FG-2026-SUNFLOWER',
              'barcode': 'FLR-SUN-123',
              'quantityProduced': 3,
              'totalCost': 45.0,
            };
          }
          throw UnimplementedError('Unexpected uri: $uri');
        },
      );

      final result = await repo.produceBouquet(
        finishedProductId: null,
        productName: 'Sunflower Delight',
        category: 'Bouquet',
        quantity: 3,
        components: const [
          RecipeItem(
            rawProductId: 5,
            cloudProductId: 'sunflower-stem-guid',
            productName: 'Sunflower',
            unit: 'Stem',
            quantity: 4,
            currentQty: 50,
            purchasePricePaise: 300,
          ),
        ],
        sellingPricePaise: 3500,
        labourCostPaise: 500,
        operatorName: 'Florist Sunita',
      );

      expect(requests, contains('GET /api/locations'));
      expect(requests, contains('POST /api/production/recipes'));
      expect(requests, contains('POST /api/production/runs'));
      expect(result.finishedQuantity, 3);
      expect(result.productionCostPaise, 4500);
      expect(result.barcode, 'FLR-SUN-123');
      expect(result.productName, 'Sunflower Delight');
      expect(result.sellingPricePaise, 3500);
    });

    test('produceBouquet defaults to quantity 1 for single-unit physical bouquet production', () async {
      final requests = <String>[];
      final repo = CloudProductionRepository(
        sender: (method, uri, {body}) async {
          requests.add('$method ${uri.path}');
          if (uri.path == '/api/locations') {
            return [
              {'id': 'location-store-guid', 'name': 'Main Store'}
            ];
          }
          if (method == 'POST' && uri.path == '/api/production/recipes') {
            return {
              'id': 'recipe-guid-unit-1',
              'name': 'Single Red Rose Bouquet',
              'category': 'Bouquet',
              'sellingPrice': 25.0,
            };
          }
          if (method == 'POST' && uri.path == '/api/production/runs') {
            expect(body!['quantity'], 1);
            return {
              'batchId': 'batch-guid-unit-1',
              'batchCode': 'FG-2026-UNIT-001',
              'barcode': 'FLR-UNIT-001',
              'quantityProduced': 1,
              'totalCost': 15.0,
            };
          }
          throw UnimplementedError('Unexpected uri: $uri');
        },
      );

      final result = await repo.produceBouquet(
        finishedProductId: null,
        productName: 'Single Red Rose Bouquet',
        category: 'Bouquet',
        components: const [
          RecipeItem(
            rawProductId: 1,
            cloudProductId: 'rose-guid',
            productName: 'Red Rose',
            unit: 'Stem',
            quantity: 12,
            currentQty: 50,
            purchasePricePaise: 100,
          ),
        ],
        sellingPricePaise: 2500,
      );

      expect(result.finishedQuantity, 1);
      expect(result.barcode, 'FLR-UNIT-001');
      expect(result.productName, 'Single Red Rose Bouquet');
    });
  });

  group('ProductionRepository Delegation', () {
    test('ProductionRepository delegates to CloudProductionRepository in cloud mode', () async {
      var cloudCalled = false;
      final cloudRepo = CloudProductionRepository(
        sender: (method, uri, {body}) async {
          cloudCalled = true;
          return [
            {
              'id': 'recipe-guid-cloud',
              'name': 'Cloud Tulip Bouquet',
              'category': 'Bouquet',
              'sellingPrice': 50.0,
            }
          ];
        },
      );

      final repo = ProductionRepository(
        storageModeService: _FakeStorageModeService(StorageMode.cloud),
        cloudRepository: cloudRepo,
      );

      final products = await repo.listFinishedProducts();
      expect(cloudCalled, isTrue);
      expect(products.length, 1);
      expect(products.first.name, 'Cloud Tulip Bouquet');
    });
  });
}
