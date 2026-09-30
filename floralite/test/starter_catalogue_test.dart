import 'dart:convert';
import 'dart:io';

import 'package:floraprise/data/catalogue/catalogue_installer.dart';
import 'package:floraprise/data/catalogue/starter_catalogue.dart';
import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/data/repositories/inventory_repository.dart';
import 'package:floraprise/data/repositories/product_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

File _findCanonicalStarterCatalogueJson() {
  final candidates = [
    File('../Sumpooj.Infrastructure/Data/starter_catalogue.json'),
    File('../../Sumpooj.Infrastructure/Data/starter_catalogue.json'),
    File('C:/floraprise/Sumpooj.Infrastructure/Data/starter_catalogue.json'),
  ];
  for (final file in candidates) {
    if (file.existsSync()) return file;
  }
  throw Exception('Canonical starter_catalogue.json not found');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await AppDatabase.instance.close();
    AppDatabase.useInMemoryForTests = true;
  });

  tearDown(() async {
    await AppDatabase.instance.close();
    AppDatabase.useInMemoryForTests = false;
  });

  test('starter catalogue includes professional flower catalog defaults', () {
    final rose = StarterCatalogue.products.singleWhere(
      (product) => product.name == 'Rose - Dark Red',
    );
    expect(rose.category, 'Flowers');
    expect(rose.defaultUnit, 'Stem');
    expect(rose.sellingPricePaise, 0);
    expect(rose.purchasePricePaise, 0);
    expect(rose.trackInventory, isTrue);
    expect(rose.minStock, 0);

    final filler = StarterCatalogue.products.singleWhere(
      (product) => product.name == 'Gypsophila (Baby\'s Breath) - White',
    );
    expect(filler.category, 'Fillers');
    expect(filler.defaultUnit, 'Bunch');

    final green = StarterCatalogue.products.singleWhere(
      (product) => product.name == 'Ruscus (Israeli)',
    );
    expect(green.category, 'Foliage');
    expect(green.defaultUnit, 'Bunch');
  });

  test('installer skips existing catalog product names', () async {
    final productRepository = ProductRepository();
    final installer = CatalogueInstaller(
      productRepository: productRepository,
      inventoryRepository: InventoryRepository(),
    );

    final firstResult = await installer.installStarterCatalogue();
    final secondResult = await installer.installStarterCatalogue();
    final products = await productRepository.listProducts(
      showActive: true,
      showInactive: true,
      includeDeleted: false,
    );
    final darkRedRoses =
        products.where((product) => product.name == 'Rose - Dark Red').toList();

    expect(firstResult.failureCount, 0);
    expect(secondResult.failureCount, 0);
    expect(secondResult.successCount, 0);
    expect(secondResult.skippedCount, StarterCatalogue.products.length);
    expect(darkRedRoses, hasLength(1));
    expect(darkRedRoses.single.sellingPricePaise, 0);
    expect(darkRedRoses.single.purchasePricePaise, 0);
    expect(darkRedRoses.single.trackInventory, isTrue);
    expect(darkRedRoses.single.minStock, 0);
  });

  test('Flutter StarterCatalogue maintains strict parity with canonical starter_catalogue.json', () {
    final jsonFile = _findCanonicalStarterCatalogueJson();
    final jsonList = jsonDecode(jsonFile.readAsStringSync()) as List<dynamic>;

    expect(jsonList.length, 142, reason: 'Canonical JSON must contain exactly 142 products');

    final flutterProductsByName = <String, StarterCatalogueProduct>{};
    for (final p in StarterCatalogue.products) {
      if (!flutterProductsByName.containsKey(p.name) || p.sellingPricePaise > 0) {
        flutterProductsByName[p.name] = p;
      }
    }

    final validCategories = {'Flowers', 'Fillers', 'Foliage', 'Packing', 'Accessories', 'Finished Products'};

    for (final raw in jsonList) {
      final item = raw as Map<String, dynamic>;
      final name = item['name'] as String;
      final category = item['category'] as String;
      final defaultUnit = item['defaultUnit'] as String;
      final sellingPricePaise = item['sellingPricePaise'] as int;
      final purchasePricePaise = item['purchasePricePaise'] as int?;
      final gstPercent = item['gstPercent'] as int;
      final trackInventory = item['trackInventory'] as bool;
      final minStock = item['minStock'] as int;

      expect(validCategories.contains(category), isTrue, reason: 'Category "$category" must be in the 6 source categories');
      expect(flutterProductsByName.containsKey(name), isTrue, reason: 'Flutter StarterCatalogue must contain "$name"');

      final flutterProduct = flutterProductsByName[name]!;
      expect(flutterProduct.category, category, reason: 'Category mismatch for "$name"');
      expect(flutterProduct.defaultUnit, defaultUnit, reason: 'Unit mismatch for "$name"');
      expect(flutterProduct.sellingPricePaise, sellingPricePaise, reason: 'Selling price mismatch for "$name"');
      expect(flutterProduct.purchasePricePaise, purchasePricePaise, reason: 'Purchase price mismatch for "$name"');
      expect(flutterProduct.gstPercent, gstPercent, reason: 'GST mismatch for "$name"');
      expect(flutterProduct.trackInventory, trackInventory, reason: 'Track inventory mismatch for "$name"');
      expect(flutterProduct.minStock, minStock, reason: 'Min stock mismatch for "$name"');
    }
  });
}
