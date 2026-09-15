import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/data/repositories/cloud_product_repository.dart';
import 'package:floraprise/providers/cloud_product_provider.dart';
import 'package:floraprise/services/sku_generator_service.dart';

void main() {
  group('CloudCategory Model & Logic', () {
    test('parses json with full fields', () {
      final json = {
        'id': 'cat-123',
        'name': 'Exotics',
        'isActive': true,
        'isPerishable': true,
        'trackBatchByDefault': true,
        'defaultUnit': 'Stem',
        'productCount': 5,
      };

      final category = CloudCategory.fromJson(json);

      expect(category.id, 'cat-123');
      expect(category.name, 'Exotics');
      expect(category.isActive, isTrue);
      expect(category.isPerishable, isTrue);
      expect(category.trackBatchByDefault, isTrue);
      expect(category.defaultUnit, 'Stem');
      expect(category.effectiveDefaultUnit, 'Stem');
      expect(category.productCount, 5);
    });

    test('falls back to Solo default unit when defaultUnit is null or empty', () {
      final flowerCat = CloudCategory.fromJson({
        'id': '1',
        'name': 'Flowers',
        'isActive': true,
        'isPerishable': true,
        'trackBatchByDefault': true,
      });
      expect(flowerCat.effectiveDefaultUnit, 'Stem');

      final fillerCat = CloudCategory.fromJson({
        'id': '2',
        'name': 'Fillers',
        'isActive': true,
        'isPerishable': true,
        'trackBatchByDefault': true,
      });
      expect(fillerCat.effectiveDefaultUnit, 'Bunch');

      final packagingCat = CloudCategory.fromJson({
        'id': '3',
        'name': 'Packing',
        'isActive': true,
        'isPerishable': false,
        'trackBatchByDefault': false,
      });
      expect(packagingCat.effectiveDefaultUnit, 'Piece');
    });

    test('CloudCategoryInput formats request json properly', () {
      const inputWithUnit = CloudCategoryInput(
        name: 'Vases',
        defaultUnit: 'Piece',
        isPerishable: false,
        trackBatchByDefault: false,
      );
      expect(inputWithUnit.toJson(), {
        'name': 'Vases',
        'defaultUnit': 'Piece',
        'isPerishable': false,
        'trackBatchByDefault': false,
      });

      const inputWithoutUnit = CloudCategoryInput(
        name: 'Flowers',
      );
      expect(inputWithoutUnit.toJson(), {
        'name': 'Flowers',
        'isPerishable': false,
        'trackBatchByDefault': false,
      });
    });
  });

  group('CloudProductRepository category operations', () {
    test('creates and updates category with CloudCategoryInput', () async {
      final requests = <Map<String, dynamic>>[];

      final repo = CloudProductRepository(
        send: (method, uri, {body}) async {
          requests.add({
            'method': method,
            'path': uri.path,
            'body': body,
          });

          if (method == 'POST' && uri.path.endsWith('/api/categories')) {
            return {'id': 'cat-999'};
          }
          if (method == 'GET' && uri.path.endsWith('/api/categories')) {
            return [
              {
                'id': 'cat-999',
                'name': 'New Category',
                'isActive': true,
                'isPerishable': true,
                'trackBatchByDefault': true,
                'defaultUnit': 'Stem',
                'productCount': 0,
              }
            ];
          }
          return {};
        },
      );

      final created = await repo.createCategory(
        const CloudCategoryInput(
          name: 'New Category',
          defaultUnit: 'Stem',
          isPerishable: true,
          trackBatchByDefault: true,
        ),
      );

      expect(created.id, 'cat-999');
      expect(created.name, 'New Category');
      expect(created.effectiveDefaultUnit, 'Stem');

      await repo.updateCategory(
        'cat-999',
        const CloudCategoryInput(
          name: 'Updated Category',
          defaultUnit: 'Bunch',
          isPerishable: false,
          trackBatchByDefault: false,
        ),
      );

      await repo.deleteCategory('cat-999');

      expect(requests, hasLength(4)); // POST, GET list, PUT, DELETE
      expect(requests[0]['method'], 'POST');
      expect(requests[0]['body']['defaultUnit'], 'Stem');
      expect(requests[2]['method'], 'PUT');
      expect(requests[2]['body']['name'], 'Updated Category');
      expect(requests[2]['body']['defaultUnit'], 'Bunch');
      expect(requests[3]['method'], 'DELETE');
      expect(requests[3]['path'], '/api/categories/cat-999');
    });

    test('maintains backward compatibility with string category name', () async {
      final requests = <Map<String, dynamic>>[];

      final repo = CloudProductRepository(
        send: (method, uri, {body}) async {
          requests.add({'method': method, 'path': uri.path, 'body': body});
          if (method == 'POST') return {'id': 'cat-str'};
          if (method == 'GET') {
            return [
              {
                'id': 'cat-str',
                'name': 'String Category',
                'isActive': true,
                'isPerishable': false,
                'trackBatchByDefault': false,
              }
            ];
          }
          return {};
        },
      );

      final cat = await repo.createCategory('String Category');
      expect(cat.id, 'cat-str');
      expect(cat.name, 'String Category');

      await repo.updateCategory('cat-str', 'Updated String Category');
      expect(requests[2]['method'], 'PUT');
      expect(requests[2]['body']['name'], 'Updated String Category');
    });
  });

  group('CloudProductProvider category helpers', () {
    test('defaultUnitForCategory returns correct unit from categories or fallback', () async {
      final repo = CloudProductRepository(
        send: (method, uri, {body}) async {
          if (uri.path.endsWith('/api/products/search')) {
            return {'items': []};
          }
          if (uri.path.endsWith('/api/categories')) {
            return [
              {
                'id': 'c1',
                'name': 'Exotics',
                'isActive': true,
                'isPerishable': true,
                'trackBatchByDefault': true,
                'defaultUnit': 'Bunch',
              },
            ];
          }
          return {};
        },
      );

      final provider = CloudProductProvider(repo);
      await provider.load();

      // Custom category in list
      expect(provider.defaultUnitForCategory('Exotics'), 'Bunch');
      // Standard Solo category not in cloud list
      expect(provider.defaultUnitForCategory('Flowers'), 'Stem');
      expect(provider.defaultUnitForCategory('Fillers'), 'Bunch');
      expect(provider.defaultUnitForCategory('Packing'), 'Piece');
    });
  });

  group('Product SKU auto-generation and fallback', () {
    test('generates SKU for new product with blank SKU', () {
      final generated = SkuGeneratorService.generateSku(
        categoryName: 'Flowers',
        productName: 'Red Roses',
        randomDigits: 123,
      );
      expect(generated, 'FLW-RDR-123');
      expect(SkuGeneratorService.isValidSku(generated), isTrue);
    });

    test('generates SKU for empty product name', () {
      final generated = SkuGeneratorService.generateSku(
        categoryName: 'Bouquets',
        productName: '',
        randomDigits: 999,
      );
      expect(generated, 'BQT-999');
      expect(SkuGeneratorService.isValidSku(generated), isTrue);
    });
  });
}
