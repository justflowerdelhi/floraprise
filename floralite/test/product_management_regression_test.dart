import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/data/repositories/category_repository.dart';
import 'package:floraprise/data/repositories/inventory_repository.dart';
import 'package:floraprise/data/repositories/product_repository.dart';
import 'package:floraprise/data/repositories/production_repository.dart';
import 'package:floraprise/l10n/app_localizations.dart';
import 'package:floraprise/managers/category_manager.dart';
import 'package:floraprise/providers/category_provider.dart';
import 'package:floraprise/providers/product_provider.dart';
import 'package:floraprise/screens/categories_screen.dart';
import 'package:floraprise/screens/products_screen.dart';
import 'package:floraprise/services/printer/escpos_builder.dart';
import 'package:floraprise/models/printer_settings.dart';
import 'package:floraprise/widgets/product_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await AppDatabase.instance.close();
  });

  testWidgets('add product dialog opens with valid dropdown values',
      (tester) async {
    await tester.pumpWidget(
      _TestApp(
        child: ChangeNotifierProvider(
          create: (_) => ProductProvider(ProductRepository()),
          child: const ProductsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byTooltip('Add Product'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.text('Add Product'), findsWidgets);
    expect(find.text('Others'), findsAtLeastNWidgets(1));
    expect(find.text('Piece'), findsAtLeastNWidgets(1));
  });

  testWidgets('add category dialog opens without lifecycle assertion',
      (tester) async {
    await tester.pumpWidget(
      _TestApp(
        child: ChangeNotifierProvider(
          create: (_) =>
              CategoryProvider(CategoryManager(CategoryRepository())),
          child: const CategoriesScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Add Category'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.text('Category Name'), findsOneWidget);
    expect(find.text('Default Unit'), findsOneWidget);
  });

  test('product picker availability text uses inventory instead of sku', () {
    expect(
      productPickerAvailabilityText(
        _inventoryProduct(
          sku: 'ROSE-SKU',
          unit: 'Stem',
          currentQty: 85,
          minQty: 10,
        ),
      ),
      'Stock: 85 Stems',
    );
    expect(
      productPickerAvailabilityText(
        _inventoryProduct(
          sku: 'BOX-SKU',
          unit: 'Box',
          currentQty: 12,
          minQty: 20,
        ),
      ),
      'Stock: 12 Boxes',
    );
    expect(
      productPickerAvailabilityText(
        _inventoryProduct(
          sku: 'BOUQUET-SKU',
          unit: 'Piece',
          currentQty: 0,
          minQty: 5,
        ),
      ),
      'Out of Stock',
    );
    expect(
      productPickerAvailabilityText(
        _inventoryProduct(
          sku: 'GIFT-SKU',
          trackInventory: false,
          currentQty: 0,
          minQty: 0,
        ),
      ),
      isEmpty,
    );
  });

  test('production accepts legacy finished product category for recipes',
      () async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final finishedProductId = await db.insert('products', {
      'name': 'Classic Bouquet',
      'category': 'Finished Product',
      'selling_price_paise': 250000,
      'gst_percent': 5,
      'default_unit': 'Piece',
      'track_inventory': 1,
      'active': 1,
      'created_at': now,
      'updated_at': now,
    });
    final rawProductId = await db.insert('products', {
      'name': 'Red Rose',
      'category': 'Flowers',
      'selling_price_paise': 5000,
      'purchase_price_paise': 3000,
      'gst_percent': 5,
      'default_unit': 'Stem',
      'track_inventory': 1,
      'active': 1,
      'created_at': now,
      'updated_at': now,
    });
    await db.insert('inventory_items', {
      'product_id': rawProductId,
      'current_qty': 20,
      'min_qty': 5,
      'updated_at': now,
    });

    final repository = ProductionRepository();
    final finishedProducts = await repository.listFinishedProducts();

    expect(finishedProducts.map((product) => product.id),
        contains(finishedProductId));

    await repository.saveRecipe(
      finishedProductId: finishedProductId,
      items: [
        RecipeItem(
          rawProductId: rawProductId,
          productName: 'Red Rose',
          unit: 'Stem',
          quantity: 6,
          currentQty: 20,
          purchasePricePaise: 3000,
        ),
      ],
    );

    final recipeItems = await repository.getRecipeItems(finishedProductId);
    expect(recipeItems, hasLength(1));
    expect(recipeItems.single.rawProductId, rawProductId);
  });

  test('producing a new ad-hoc bouquet does not throw database errors',
      () async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final rawProductId = await db.insert('products', {
      'name': 'Carnation',
      'category': 'Flowers',
      'selling_price_paise': 800,
      'purchase_price_paise': 500,
      'gst_percent': 5,
      'default_unit': 'Stem',
      'track_inventory': 1,
      'active': 1,
      'created_at': now,
      'updated_at': now,
    });
    await db.insert('inventory_items', {
      'product_id': rawProductId,
      'current_qty': 50,
      'min_qty': 5,
      'updated_at': now,
    });

    final repository = ProductionRepository();
    final result = await repository.produceBouquet(
      finishedProductId: null,
      productName: 'Test Bouquet',
      category: 'Bouquet',
      quantity: 2,
      components: [
        RecipeItem(
          rawProductId: rawProductId,
          productName: 'Carnation',
          unit: 'Stem',
          quantity: 5,
          currentQty: 50,
          purchasePricePaise: 500,
        ),
      ],
      sellingPricePaise: 2500,
      labourCostPaise: 200,
      shelfLifeDays: 2,
      refreshAfterDays: 1,
    );

    expect(result.productionId, greaterThan(0));
    expect(result.finishedQuantity, 2);
    expect(result.productionCostPaise, greaterThan(0));

    final product = await ProductRepository().getProductById(
      result.finishedProductId,
    );
    expect(product, isNotNull);
    expect(product!.florapriseBarcode, matches(RegExp(r'^FL\d{8}$')));
  });

  test('new products keep manufacturer barcode and get internal barcode',
      () async {
    final repository = ProductRepository();
    final id = await repository.createProduct(
      const ProductUpsertInput(
        name: 'Imported Teddy',
        category: 'Accessories',
        defaultUnit: 'Piece',
        sellingPricePaise: 49900,
        manufacturerBarcode: '8901234567890',
        trackInventory: true,
      ),
    );

    final product = await repository.getProductById(id);
    expect(product, isNotNull);
    expect(product!.manufacturerBarcode, '8901234567890');
    expect(product.florapriseBarcode, matches(RegExp(r'^FL\d{8}$')));
    expect(product.florapriseBarcode, isNot(product.manufacturerBarcode));
  });

  test('barcode lookup prefers manufacturer then Floraprise then name',
      () async {
    final repository = ProductRepository();
    final manufacturerMatch = await repository.createProduct(
      const ProductUpsertInput(
        name: 'Lookup Rose Manufacturer',
        category: 'Flowers',
        defaultUnit: 'Stem',
        sellingPricePaise: 3000,
        manufacturerBarcode: 'LOOKUP-123',
      ),
    );
    await repository.createProduct(
      const ProductUpsertInput(
        name: 'LOOKUP-123 Bouquet Name',
        category: 'Bouquet',
        defaultUnit: 'Piece',
        sellingPricePaise: 90000,
      ),
    );

    final manufacturerLookup =
        await repository.lookupProductBySearchPriority('LOOKUP-123');
    expect(manufacturerLookup?.id, manufacturerMatch);

    final florapriseProduct =
        await repository.getProductById(manufacturerMatch);
    final florapriseLookup = await repository.lookupProductBySearchPriority(
      florapriseProduct!.florapriseBarcode,
    );
    expect(florapriseLookup?.id, manufacturerMatch);

    final nameLookup = await repository.lookupProductBySearchPriority(
      'Lookup Rose Manufacturer',
    );
    expect(nameLookup?.id, manufacturerMatch);
  });

  test('ESC/POS barcode command selects Code 128 set B', () {
    final builder = EscPosBuilder(paperWidth: PrinterPaperWidth.mm58)
      ..reset()
      ..barcode('FL00000001');

    final bytes = builder.bytes();
    final commandStart = _indexOfBytes(bytes, const [0x1D, 0x6B, 0x49]);
    expect(commandStart, isNonNegative);
    expect(
        bytes.sublist(commandStart, commandStart + 4), [0x1D, 0x6B, 0x49, 12]);
    expect(
        String.fromCharCodes(bytes.sublist(commandStart + 4, commandStart + 6)),
        '{B');
  });

  test('active product inventory records carry the latest purchase price',
      () async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final rawProductId = await db.insert('products', {
      'name': 'Pink Rose',
      'category': 'Flowers',
      'selling_price_paise': 1200,
      'gst_percent': 5,
      'default_unit': 'Stem',
      'track_inventory': 1,
      'active': 1,
      'created_at': now,
      'updated_at': now,
    });
    await db.insert('inventory_items', {
      'product_id': rawProductId,
      'current_qty': 30,
      'min_qty': 5,
      'updated_at': now,
    });

    await InventoryRepository().createPurchaseTransaction(
      productId: rawProductId,
      quantity: 10,
      purchasePricePaise: 700,
    );

    final products =
        await ProductRepository().listActiveProductsWithInventory();
    final selected = products.firstWhere((p) => p.id == rawProductId);
    expect(selected.purchasePricePaise, 700);
  });
}

int _indexOfBytes(List<int> bytes, List<int> pattern) {
  for (var index = 0; index <= bytes.length - pattern.length; index++) {
    var matches = true;
    for (var offset = 0; offset < pattern.length; offset++) {
      if (bytes[index + offset] != pattern[offset]) {
        matches = false;
        break;
      }
    }
    if (matches) return index;
  }
  return -1;
}

ProductInventoryRecord _inventoryProduct({
  String sku = '',
  String unit = 'Piece',
  bool trackInventory = true,
  int currentQty = 0,
  int minQty = 0,
}) {
  return ProductInventoryRecord(
    id: 1,
    code: sku,
    name: 'Test Product',
    category: 'Flowers',
    defaultUnit: unit,
    sku: sku,
    barcode: '',
    manufacturerBarcode: '',
    florapriseBarcode: '',
    sellingPricePaise: 10000,
    purchasePricePaise: null,
    gstPercent: 0,
    trackInventory: trackInventory,
    active: true,
    favorite: false,
    currentQty: currentQty,
    minQty: minQty,
  );
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('gu'),
      ],
      home: child,
    );
  }
}
