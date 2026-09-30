import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/models/library_models.dart';
import 'package:floraprise/data/repositories/library_repository.dart';
import 'package:floraprise/providers/library_provider.dart';

void main() {
  group('Floraprise Library Models and Parser Tests', () {
    test('LibraryCategory parses JSON correctly', () {
      final json = {
        'id': 'cat-1',
        'name': 'Roses & Stems',
        'slug': 'roses-stems',
        'description': 'Fresh cut roses',
        'productCount': 42,
        'isActive': true,
      };

      final cat = LibraryCategory.fromJson(json);
      expect(cat.id, 'cat-1');
      expect(cat.name, 'Roses & Stems');
      expect(cat.slug, 'roses-stems');
      expect(cat.productCount, 42);
      expect(cat.isActive, isTrue);
    });

    test('LibraryProduct parses JSON correctly', () {
      final json = {
        'id': 'prod-1',
        'name': 'Red Naomi Rose',
        'slug': 'red-naomi-rose',
        'productType': 'SingleFlower',
        'standardUnit': 'Stem',
        'standardSku': 'ROSE-RED-NAOMI',
        'isActive': true,
      };

      final prod = LibraryProduct.fromJson(json);
      expect(prod.id, 'prod-1');
      expect(prod.name, 'Red Naomi Rose');
      expect(prod.standardSku, 'ROSE-RED-NAOMI');
      expect(prod.standardUnit, 'Stem');
    });

    test('LibraryRecipe parses JSON with items correctly', () {
      final json = {
        'id': 'rec-1',
        'name': 'Dozen Red Roses Hand-Tied',
        'slug': 'dozen-red-roses',
        'yieldQuantity': 1.0,
        'yieldUnit': 'Bouquet',
        'itemCount': 2,
        'items': [
          {
            'id': 'item-1',
            'productName': 'Red Naomi Rose',
            'quantity': 12.0,
            'unit': 'Stem',
          },
          {
            'id': 'item-2',
            'productName': 'Gypsophila',
            'quantity': 2.0,
            'unit': 'Stem',
          }
        ]
      };

      final recipe = LibraryRecipe.fromJson(json);
      expect(recipe.id, 'rec-1');
      expect(recipe.name, 'Dozen Red Roses Hand-Tied');
      expect(recipe.items.length, 2);
      expect(recipe.items[0].productName, 'Red Naomi Rose');
      expect(recipe.items[0].quantity, 12.0);
    });

    test('LibraryDesign parses JSON correctly', () {
      final json = {
        'id': 'des-1',
        'title': 'Velvet Dreams',
        'slug': 'velvet-dreams',
        'occasion': 'Anniversary',
        'style': 'Luxury',
        'colorPalette': 'Purple, Pink',
        'flowerTypes': 'Roses, Orchids',
      };

      final design = LibraryDesign.fromJson(json);
      expect(design.id, 'des-1');
      expect(design.title, 'Velvet Dreams');
      expect(design.occasion, 'Anniversary');
      expect(design.style, 'Luxury');
    });

    test('LibraryCardTemplate parses JSON correctly', () {
      final json = {
        'id': 'card-1',
        'title': 'Happy Birthday Love',
        'slug': 'happy-birthday-love',
        'content': 'Wishing you all the happiness in the world!',
        'occasion': 'Birthday',
        'tone': 'Warm',
        'language': 'en',
      };

      final card = LibraryCardTemplate.fromJson(json);
      expect(card.id, 'card-1');
      expect(card.title, 'Happy Birthday Love');
      expect(card.occasion, 'Birthday');
      expect(card.tone, 'Warm');
    });

    test('LibraryTutorial parses JSON correctly', () {
      final json = {
        'id': 'tut-1',
        'title': 'Spiral Technique Masterclass',
        'slug': 'spiral-technique-masterclass',
        'contentMarkdown': '# Spiral Technique',
        'difficultyLevel': 'Intermediate',
        'estimatedReadingMinutes': 8,
      };

      final tut = LibraryTutorial.fromJson(json);
      expect(tut.id, 'tut-1');
      expect(tut.title, 'Spiral Technique Masterclass');
      expect(tut.difficultyLevel, 'Intermediate');
      expect(tut.estimatedReadingMinutes, 8);
    });

    test('LibraryManifest parses JSON correctly', () {
      final json = {
        'categoriesVersion': '20260919-5',
        'categoriesCount': 5,
        'productsVersion': '20260919-42',
        'productsCount': 42,
        'recipesVersion': '20260919-10',
        'recipesCount': 10,
        'designsVersion': '20260919-15',
        'designsCount': 15,
        'cardsVersion': '20260919-30',
        'cardsCount': 30,
        'tutorialsVersion': '20260919-8',
        'tutorialsCount': 8,
        'globalManifestHash': 'a1b2c3d4e5f60718',
        'generatedAtUtc': '2026-09-19T10:00:00Z',
      };

      final manifest = LibraryManifest.fromJson(json);
      expect(manifest.categoriesCount, 5);
      expect(manifest.productsCount, 42);
      expect(manifest.recipesCount, 10);
      expect(manifest.designsCount, 15);
      expect(manifest.cardsCount, 30);
      expect(manifest.tutorialsCount, 8);
      expect(manifest.globalManifestHash, 'a1b2c3d4e5f60718');
    });

    test('LibraryFestival parses JSON correctly', () {
      final json = {
        'id': 'fest-1',
        'name': 'Valentine\'s Day',
        'slug': 'valentines-day',
        'festivalDate': '2026-02-14T00:00:00Z',
        'month': 2,
        'day': 14,
        'description': 'Global celebration of romance and roses.',
        'isRecurring': true,
        'flowerDemands': 'Red Roses, Carnations, Lilies',
        'isActive': true,
      };

      final fest = LibraryFestival.fromJson(json);
      expect(fest.id, 'fest-1');
      expect(fest.name, 'Valentine\'s Day');
      expect(fest.month, 2);
      expect(fest.day, 14);
      expect(fest.flowerDemands, contains('Red Roses'));
      expect(fest.isRecurring, isTrue);
    });

    test('LibraryWeddingDate parses JSON correctly', () {
      final json = {
        'id': 'wed-1',
        'title': 'Auspicious Winter Vivah Muhurat',
        'slug': 'winter-muhurat-2026-01-22',
        'weddingDate': '2026-01-22T00:00:00Z',
        'tithi': 'Shukla Panchami',
        'nakshatra': 'Uttara Phalguni',
        'season': 'Winter',
        'demandLevel': 'High',
        'isActive': true,
      };

      final wed = LibraryWeddingDate.fromJson(json);
      expect(wed.id, 'wed-1');
      expect(wed.title, contains('Vivah Muhurat'));
      expect(wed.tithi, 'Shukla Panchami');
      expect(wed.nakshatra, 'Uttara Phalguni');
      expect(wed.season, 'Winter');
      expect(wed.demandLevel, 'High');
    });
  });

  group('LibraryRepository and Provider Mock Tests', () {
    test('LibraryProvider tab navigation and mock dispatch', () async {
      final repo = LibraryRepository(
        sender: (method, uri, {body}) async {
          if (uri.path.contains('/api/v1/library/manifest')) {
            return {
              'categoriesVersion': '1',
              'categoriesCount': 2,
              'productsVersion': '1',
              'productsCount': 10,
              'recipesVersion': '1',
              'recipesCount': 4,
              'designsVersion': '1',
              'designsCount': 6,
              'cardsVersion': '1',
              'cardsCount': 8,
              'tutorialsVersion': '1',
              'tutorialsCount': 3,
              'globalManifestHash': 'hash123',
              'generatedAtUtc': '2026-09-19T10:00:00Z',
            };
          }
          if (uri.path.contains('/api/v1/library/categories/tree')) {
            return [
              {
                'id': 'cat-1',
                'name': 'Roses',
                'slug': 'roses',
                'children': [],
              }
            ];
          }
          if (uri.path.contains('/api/v1/library/products')) {
            return {
              'items': [
                {
                  'id': 'prod-1',
                  'name': 'Dutch Red Rose',
                  'slug': 'dutch-red-rose',
                  'standardSku': 'ROSE-DUTCH-RED',
                }
              ],
              'totalCount': 1,
            };
          }
          if (uri.path.contains('/api/v1/library/recipes')) {
            return {
              'items': [
                {
                  'id': 'rec-1',
                  'name': 'Classic Rose Bouquet',
                  'slug': 'classic-rose-bouquet',
                  'yieldQuantity': 1,
                  'yieldUnit': 'Piece',
                  'itemCount': 1,
                }
              ],
              'totalCount': 1,
            };
          }
          return null;
        },
      );

      final provider = LibraryProvider(repository: repo);
      await provider.init();

      expect(provider.manifest?.globalManifestHash, 'hash123');
      expect(provider.products.length, 1);
      expect(provider.products[0].name, 'Dutch Red Rose');

      provider.setTab(LibraryTab.recipes);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(provider.recipes.length, 1);
      expect(provider.recipes[0].name, 'Classic Rose Bouquet');
    });

    test('LibraryProvider importProduct calls API and returns result', () async {
      final repo = LibraryRepository(
        sender: (method, uri, {body}) async {
          if (uri.path.endsWith('/import')) {
            return {
              'success': true,
              'alreadyImported': false,
              'productId': 'company-prod-123',
              'message': 'Product successfully imported from library.',
            };
          }
          return null;
        },
      );

      final provider = LibraryProvider(repository: repo);
      final result = await provider.importProduct('prod-1');

      expect(result.success, isTrue);
      expect(result.alreadyImported, isFalse);
      expect(result.importedId, 'company-prod-123');
    });

    test('LibraryProvider importRecipe calls API and returns result', () async {
      final repo = LibraryRepository(
        sender: (method, uri, {body}) async {
          if (uri.path.endsWith('/import')) {
            return {
              'success': true,
              'alreadyImported': false,
              'recipeId': 'company-rec-456',
              'message': 'Recipe successfully imported from library.',
            };
          }
          return null;
        },
      );

      final provider = LibraryProvider(repository: repo);
      final result = await provider.importRecipe('rec-1');

      expect(result.success, isTrue);
      expect(result.alreadyImported, isFalse);
      expect(result.importedId, 'company-rec-456');
    });

    test('LibraryProvider importDesign calls API and returns result', () async {
      final repo = LibraryRepository(
        sender: (method, uri, {body}) async {
          if (uri.path.endsWith('/import')) {
            return {
              'success': true,
              'alreadyImported': false,
              'designId': 'company-des-789',
              'message': 'Design successfully imported from library.',
            };
          }
          return null;
        },
      );

      final provider = LibraryProvider(repository: repo);
      final result = await provider.importDesign('des-1');

      expect(result.success, isTrue);
      expect(result.alreadyImported, isFalse);
      expect(result.importedId, 'company-des-789');
    });

    test('LibraryProvider loads festivals and wedding dates correctly', () async {
      final repo = LibraryRepository(
        sender: (method, uri, {body}) async {
          if (uri.path.contains('/api/v1/library/festivals')) {
            return {
              'items': [
                {
                  'id': 'fest-1',
                  'name': 'Diwali',
                  'slug': 'diwali',
                  'festivalDate': '2026-11-08T00:00:00Z',
                  'month': 11,
                  'day': 8,
                  'flowerDemands': 'Marigold, Jasmine',
                }
              ],
              'totalCount': 1,
            };
          }
          if (uri.path.contains('/api/v1/library/wedding-dates')) {
            return {
              'items': [
                {
                  'id': 'wed-1',
                  'title': 'Spring Wedding Muhurat',
                  'slug': 'spring-muhurat-2026',
                  'weddingDate': '2026-02-18T00:00:00Z',
                  'demandLevel': 'Peak',
                }
              ],
              'totalCount': 1,
            };
          }
          return null;
        },
      );

      final provider = LibraryProvider(repository: repo);
      provider.setTab(LibraryTab.festivals);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(provider.festivals.length, 1);
      expect(provider.festivals[0].name, 'Diwali');

      provider.setTab(LibraryTab.weddingDates);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(provider.weddingDates.length, 1);
      expect(provider.weddingDates[0].title, 'Spring Wedding Muhurat');
    });
  });
}
