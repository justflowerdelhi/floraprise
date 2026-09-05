import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/data/repositories/cloud_product_repository.dart';
import 'package:floraprise/data/repositories/inventory_repository.dart';
import 'package:floraprise/data/repositories/product_repository.dart';
import 'package:floraprise/models/gst_calculation_type.dart';
import 'package:floraprise/services/cloud_product_local_catalog_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const companyId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const otherCompanyId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const cloudProductId = '11111111-1111-4111-8111-111111111111';
const secondCloudProductId = '22222222-2222-4222-8222-222222222222';

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

  test('authenticated company is required', () async {
    final service = _service(
      currentCompanyId: () async => null,
      products: [_cloudProduct()],
    );

    await expectLater(
      service.syncForCurrentCompany(),
      throwsA(isA<StateError>()),
    );
    expect(await _productCount(), 0);
  });

  test('active Cloud product creates one mapped local product', () async {
    final result = await _service(products: [_cloudProduct()]).syncForCurrentCompany();

    expect(result.createdCount, 1);
    final rows = await _products();
    expect(rows, hasLength(1));
    expect(rows.single['name'], 'Red Rose');
    expect(rows.single['cloud_product_id'], cloudProductId);
    expect(rows.single['cloud_product_company_id'], companyId);
    expect(rows.single['active'], 1);
  });

  test('Cloud product without companyId imports under authenticated company', () async {
    final result = await _service(
      products: [_cloudProduct(companyId: '')],
      inventory: [_cloudStock(currentQty: 195)],
    ).syncForCurrentCompany();

    expect(result.createdCount, 1);
    expect(result.skippedCount, 0);
    final rows = await _products();
    expect(rows.single['cloud_product_id'], cloudProductId);
    expect(rows.single['cloud_product_company_id'], companyId);
  });

  test('mapping is present immediately after creation', () async {
    await _service(products: [_cloudProduct()]).syncForCurrentCompany();
    final product = (await ProductRepository().listProducts()).single;
    final mapping = await ProductRepository().getCloudProductMapping(product.id);

    expect(mapping?.cloudProductId, cloudProductId);
    expect(mapping?.cloudProductCompanyId, companyId);
  });

  test('repeated sync does not create duplicates', () async {
    final service = _service(products: [_cloudProduct()]);

    await service.syncForCurrentCompany();
    await service.syncForCurrentCompany();

    expect(await _productCount(), 1);
  });

  test('existing mapped local product is updated and ID remains unchanged', () async {
    await _service(products: [_cloudProduct(name: 'Red Rose')]).syncForCurrentCompany();
    final before = (await ProductRepository().listProducts()).single;

    final result = await _service(
      products: [_cloudProduct(name: 'Premium Red Rose', retailPrice: 15)],
    ).syncForCurrentCompany();

    final after = (await ProductRepository().listProducts()).single;
    expect(result.updatedCount, 1);
    expect(after.id, before.id);
    expect(after.name, 'Premium Red Rose');
    expect(after.sellingPricePaise, 1500);
  });

  test('existing local current_qty is not overwritten', () async {
    await _service(
      products: [_cloudProduct()],
      inventory: [_cloudStock(currentQty: 195)],
    ).syncForCurrentCompany();
    final db = await AppDatabase.instance.database;
    final product = (await ProductRepository().listProducts()).single;
    await db.update(
      'inventory_items',
      {'current_qty': 123},
      where: 'product_id = ?',
      whereArgs: [product.id],
    );

    await _service(
      products: [_cloudProduct(name: 'Red Rose Updated')],
      inventory: [_cloudStock(currentQty: 195)],
    ).syncForCurrentCompany();

    final stock = await db.query(
      'inventory_items',
      where: 'product_id = ?',
      whereArgs: [product.id],
    );
    expect(stock.single['current_qty'], 123);
  });

  test('new local product gets initial Cloud stock', () async {
    final result = await _service(
      products: [_cloudProduct()],
      inventory: [_cloudStock(currentQty: 195, minQty: 10)],
    ).syncForCurrentCompany();

    final db = await AppDatabase.instance.database;
    final product = (await ProductRepository().listProducts()).single;
    final stock = await db.query(
      'inventory_items',
      where: 'product_id = ?',
      whereArgs: [product.id],
    );
    expect(result.stockInitializedCount, 1);
    expect(stock.single['current_qty'], 195);
    expect(stock.single['min_qty'], 10);
    expect(await db.query('inventory_transactions'), isEmpty);
  });

  test('inactive Cloud product becomes inactive locally', () async {
    await _service(
      products: [_cloudProduct(isActive: false)],
    ).syncForCurrentCompany(includeInactive: true);

    final rows = await ProductRepository().listProducts(
      showActive: false,
      showInactive: true,
    );
    expect(rows, hasLength(1));
    expect(rows.single.active, isFalse);
    expect(rows.single.deletedAt, isNull);
  });

  test('missing Cloud product does not delete local mapped product', () async {
    await _service(products: [_cloudProduct()]).syncForCurrentCompany();
    final before = (await ProductRepository().listProducts()).single;

    await _service(products: const []).syncForCurrentCompany();

    final after = await ProductRepository().getProductById(before.id);
    expect(after, isNotNull);
    expect(after!.deletedAt, isNull);
    expect(after.cloudProductId, cloudProductId);
  });

  test('different company cannot import into current company', () async {
    final result = await _service(
      products: [_cloudProduct(companyId: otherCompanyId)],
    ).syncForCurrentCompany();

    expect(result.createdCount, 0);
    expect(result.skippedCount, 1);
    expect(result.errors.single, contains('another company'));
    expect(await _productCount(), 0);
  });

  test('invalid Cloud UUID is skipped safely', () async {
    final result = await _service(
      products: [_cloudProduct(id: 'not-a-uuid')],
    ).syncForCurrentCompany();

    expect(result.createdCount, 0);
    expect(result.skippedCount, 1);
    expect(result.errors.single, contains('invalid Cloud product ID'));
    expect(await _productCount(), 0);
  });

  test('Cloud API failure does not partially corrupt local catalog', () async {
    final service = CloudProductLocalCatalogSyncService(
      productRepository: ProductRepository(),
      currentCompanyId: () async => companyId,
      loadCloudProducts: ({
        String query = '',
        String? category,
        bool? trackInventory,
        bool showActive = true,
        bool showInactive = false,
      }) async => throw StateError('Cloud unavailable'),
      loadCloudInventory: () async => [_cloudStock()],
    );

    await expectLater(
      service.syncForCurrentCompany(),
      throwsA(isA<StateError>()),
    );
    expect(await _productCount(), 0);
  });

  test('CloudProductRepository.listProducts retrieves all paged results', () async {
    final requestedPages = <int>[];
    final repository = CloudProductRepository(
      send: (method, uri, {body}) async {
        expect(method, 'GET');
        final page = int.parse(uri.queryParameters['page']!);
        final pageSize = int.parse(uri.queryParameters['pageSize']!);
        requestedPages.add(page);
        final start = (page - 1) * pageSize;
        final remaining = 250 - start;
        final count = remaining <= 0 ? 0 : remaining.clamp(0, pageSize);
        return {
          'items': List.generate(
            count,
            (index) => _cloudProductJson(start + index),
          ),
          'totalCount': 250,
          'page': page,
          'pageSize': pageSize,
        };
      },
    );

    final products = await repository.listProducts();

    expect(products, hasLength(250));
    expect(requestedPages, [1, 2]);
  });

  test('sync imports multiple products and avoids SKU or name matching', () async {
    await ProductRepository().createProduct(
      const ProductUpsertInput(
        name: 'Red Rose',
        category: 'Flowers',
        defaultUnit: 'Stem',
        sellingPricePaise: 1000,
        sku: 'RED',
      ),
    );

    await _service(
      products: [
        _cloudProduct(id: cloudProductId, name: 'Red Rose', sku: 'CLOUD-RED'),
        _cloudProduct(id: secondCloudProductId, name: 'Yellow Rose', sku: 'YELLOW'),
      ],
    ).syncForCurrentCompany();

    final rows = await ProductRepository().listProducts();
    expect(rows, hasLength(3));
    expect(rows.where((product) => product.cloudProductId == cloudProductId), hasLength(1));
    expect(rows.where((product) => product.name == 'Red Rose'), hasLength(2));
  });
}

CloudProductLocalCatalogSyncService _service({
  CurrentCompanyIdLoader? currentCompanyId,
  List<CloudProduct> products = const [],
  List<InventoryProductRecord> inventory = const [],
}) {
  return CloudProductLocalCatalogSyncService(
    productRepository: ProductRepository(),
    currentCompanyId: currentCompanyId ?? () async => companyId,
    loadCloudProducts: ({
      String query = '',
      String? category,
      bool? trackInventory,
      bool showActive = true,
      bool showInactive = false,
    }) async => products
        .where((product) => showInactive || product.isActive)
        .toList(),
    loadCloudInventory: () async => inventory,
  );
}

Future<List<Map<String, Object?>>> _products() async {
  final db = await AppDatabase.instance.database;
  return db.query('products', orderBy: 'id ASC');
}

Future<int> _productCount() async => (await _products()).length;

CloudProduct _cloudProduct({
  String id = cloudProductId,
  String companyId = companyId,
  String name = 'Red Rose',
  String sku = 'RED',
  double retailPrice = 10,
  double costPrice = 6,
  bool trackInventory = true,
  bool isActive = true,
}) {
  return CloudProduct(
    id: id,
    companyId: companyId,
    name: name,
    sku: sku,
    barcode: 'BAR-$sku',
    manufacturerBarcode: 'MFG-$sku',
    internalBarcode: null,
    brand: null,
    description: 'Cloud product',
    category: 'Flowers',
    categoryId: null,
    unitOfMeasure: 'Stem',
    retailPrice: retailPrice,
    costPrice: costPrice,
    wholesalePrice: null,
    weddingEventPrice: null,
    taxCategory: 'Reduced',
    trackInventory: trackInventory,
    trackBatch: false,
    stockQuantity: 0,
    minimumStockLevel: 10,
    reorderLevel: 5,
    isActive: isActive,
    shelfLifeDays: null,
    expiryAlertDays: null,
    temperatureNotes: null,
    createdAtUtc: DateTime.utc(2026, 1, 1),
    updatedAtUtc: null,
  );
}

InventoryProductRecord _cloudStock({
  String id = cloudProductId,
  int currentQty = 195,
  int minQty = 10,
}) {
  return InventoryProductRecord(
    productId: -1,
    cloudProductId: id,
    name: 'Red Rose',
    category: 'Flowers',
    unit: 'Stem',
    sku: 'RED',
    barcode: 'MFG-RED',
    manufacturerBarcode: 'MFG-RED',
    internalBarcode: null,
    trackInventory: true,
    gstPercent: 0,
    gstCalculationType: GstCalculationType.inclusive,
    currentQty: currentQty,
    minQty: minQty,
  );
}

Map<String, Object?> _cloudProductJson(int index) {
  final number = index + 1;
  return {
    'id': '${number.toRadixString(16).padLeft(8, '0')}-0000-4000-8000-000000000000',
    'companyId': companyId,
    'name': 'Cloud Product $number',
    'sku': 'SKU-$number',
    'barcode': 'BAR-$number',
    'manufacturerBarcode': 'MFG-$number',
    'category': 'Flowers',
    'unitOfMeasure': 'Stem',
    'retailPrice': 10,
    'costPrice': 6,
    'taxCategory': 'Reduced',
    'trackInventory': true,
    'trackBatch': false,
    'stockQuantity': 0,
    'minimumStockLevel': 10,
    'reorderLevel': 5,
    'isActive': true,
    'createdAtUtc': '2026-01-01T00:00:00Z',
  };
}
