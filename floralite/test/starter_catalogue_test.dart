import 'package:floraprise/data/catalogue/catalogue_installer.dart';
import 'package:floraprise/data/catalogue/starter_catalogue.dart';
import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/data/repositories/inventory_repository.dart';
import 'package:floraprise/data/repositories/product_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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
}
