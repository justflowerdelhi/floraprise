import 'dart:convert';
import 'dart:io';

import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/data/repositories/cloud_product_repository.dart';
import 'package:floraprise/data/repositories/product_repository.dart';
import 'package:floraprise/services/product_cloud_linking_service.dart';
import 'package:floraprise/services/product_cloud_syncability_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const firstCloudId = '11111111-1111-4111-8111-111111111111';
const secondCloudId = '22222222-2222-4222-8222-222222222222';
const currentCompanyId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const otherCompanyId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';

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
    AppDatabase.testDatabaseName = null;
    AppDatabase.useInMemoryForTests = false;
  });

  test('cloud product mapping migration adds nullable columns and partial unique index', () async {
    final db = await AppDatabase.instance.database;
    final version = await db.rawQuery('PRAGMA user_version');
    final columns = await db.rawQuery('PRAGMA table_info(products)');
    final indexes = await db.rawQuery(
      "SELECT sql FROM sqlite_master WHERE type = 'index' AND name = 'idx_products_cloud_product_id_unique'",
    );

    expect(version.single['user_version'], 44);
    final productColumn = columns.singleWhere((row) => row['name'] == 'cloud_product_id');
    final companyColumn = columns.singleWhere((row) => row['name'] == 'cloud_product_company_id');
    expect(productColumn['type'], 'TEXT');
    expect(productColumn['notnull'], 0);
    expect(companyColumn['type'], 'TEXT');
    expect(companyColumn['notnull'], 0);
    expect(indexes.single['sql'],
        "CREATE UNIQUE INDEX idx_products_cloud_product_id_unique ON products(cloud_product_id) WHERE cloud_product_id IS NOT NULL AND TRIM(cloud_product_id) <> ''");
  });

  test('existing products with null mappings remain valid', () async {
    final repository = ProductRepository();
    final first = await _createProduct(repository, 'Rose');
    final second = await _createProduct(repository, 'Lily');

    expect(await repository.getCloudProductId(first), isNull);
    expect(await repository.getCloudProductId(second), isNull);
  });

  test('cloud product mapping persists after database close and reopen', () async {
    AppDatabase.useInMemoryForTests = false;
    AppDatabase.testDatabaseName = 'product_cloud_linking_reopen_test.db';
    final databasePath = path.join(
      await getDatabasesPath(),
      AppDatabase.testDatabaseName!,
    );
    await deleteDatabase(databasePath);

    final repository = ProductRepository();
    final localProductId = await _createProduct(repository, 'Rose');
    await repository.setCloudProductId(localProductId, firstCloudId, currentCompanyId);
    await AppDatabase.instance.close();

    expect(File(databasePath).existsSync(), isTrue);
    final mapping = await ProductRepository().getCloudProductMapping(localProductId);
    expect(mapping?.cloudProductId, firstCloudId);
    expect(mapping?.cloudProductCompanyId, currentCompanyId);
  });

  test('valid UUID persistence lowercases the stored value', () async {
    final repository = ProductRepository();
    final localProductId = await _createProduct(repository, 'Rose');

    await repository.setCloudProductId(
      localProductId,
      'AAAAAAAA-AAAA-4AAA-8AAA-AAAAAAAAAAAA',
      'BBBBBBBB-BBBB-4BBB-8BBB-BBBBBBBBBBBB',
    );

    final mapping = await repository.getCloudProductMapping(localProductId);
    expect(mapping?.cloudProductId, 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
    expect(mapping?.cloudProductCompanyId, 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb');
  });

  test('invalid UUID is rejected before persistence', () async {
    final repository = ProductRepository();
    final localProductId = await _createProduct(repository, 'Rose');

    await expectLater(
      () => repository.setCloudProductId(
        localProductId,
        'not-a-uuid',
        currentCompanyId,
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(await repository.getCloudProductId(localProductId), isNull);
  });

  test('invalid company UUID is rejected before persistence', () async {
    final repository = ProductRepository();
    final localProductId = await _createProduct(repository, 'Rose');

    await expectLater(
      () => repository.setCloudProductId(localProductId, firstCloudId, 'not-a-uuid'),
      throwsA(isA<ArgumentError>()),
    );
    expect(await repository.getCloudProductMapping(localProductId), isNull);
  });

  test('duplicate Cloud UUID is rejected within the same SQLite database', () async {
    final repository = ProductRepository();
    final first = await _createProduct(repository, 'Rose');
    final second = await _createProduct(repository, 'Lily');
    await repository.setCloudProductId(first, firstCloudId, currentCompanyId);

    await expectLater(
      () => repository.setCloudProductId(second, firstCloudId, currentCompanyId),
      throwsA(isA<DatabaseException>()),
    );
    expect(await repository.getCloudProductId(second), isNull);
  });

  test('failed Cloud verification does not persist mapping', () async {
    await _expectVerificationFailureDoesNotPersist(StateError('Cloud API HTTP 500: {}'));
  });

  test('401 does not persist mapping', () async {
    await _expectVerificationFailureDoesNotPersist(StateError('Cloud API HTTP 401: {}'));
  });

  test('403 does not persist mapping', () async {
    await _expectVerificationFailureDoesNotPersist(StateError('Cloud API HTTP 403: {}'));
  });

  test('404 does not persist mapping', () async {
    await _expectVerificationFailureDoesNotPersist(StateError('Cloud API HTTP 404: {}'));
  });

  test('inactive Cloud product cannot be newly linked', () async {
    final repository = ProductRepository();
    final localProductId = await _createProduct(repository, 'Rose');
    final service = ProductCloudLinkingService(
      productRepository: repository,
      isOnline: () async => true,
      currentCompanyId: () async => currentCompanyId,
      verifyCloudProduct: (_) async => _cloudProduct(firstCloudId, isActive: false),
    );

    await expectLater(
      () => service.linkCloudProduct(
        localProductId: localProductId,
        cloudProductId: firstCloudId,
      ),
      throwsA(isA<StateError>()),
    );
    expect(await repository.getCloudProductId(localProductId), isNull);
  });

  test('explicit Link works after Cloud verification', () async {
    final repository = ProductRepository();
    final localProductId = await _createProduct(repository, 'Rose');
    final service = _service(repository, firstCloudId);

    await service.linkCloudProduct(
      localProductId: localProductId,
      cloudProductId: firstCloudId,
    );

    final mapping = await repository.getCloudProductMapping(localProductId);
    expect(mapping?.cloudProductId, firstCloudId);
    expect(mapping?.cloudProductCompanyId, currentCompanyId);
  });

  test('Change works when no protected outbox exists', () async {
    final repository = ProductRepository();
    final localProductId = await _createProduct(repository, 'Rose');
    await repository.setCloudProductId(localProductId, firstCloudId, currentCompanyId);

    await _service(repository, secondCloudId).changeCloudProduct(
      localProductId: localProductId,
      cloudProductId: secondCloudId,
    );

    expect(await repository.getCloudProductId(localProductId), secondCloudId);
  });

  test('Unlink works when no protected outbox exists', () async {
    final repository = ProductRepository();
    final localProductId = await _createProduct(repository, 'Rose');
    await repository.setCloudProductId(localProductId, firstCloudId, currentCompanyId);

    await _service(repository, firstCloudId).unlinkCloudProduct(
      localProductId: localProductId,
    );

    expect(await repository.getCloudProductId(localProductId), isNull);
  });

  test('Change is blocked when pending outbox references the product', () async {
    final repository = ProductRepository();
    final localProductId = await _createProduct(repository, 'Rose');
    await repository.setCloudProductId(localProductId, firstCloudId, currentCompanyId);
    await _insertOutbox(localProductId: localProductId, state: 'pending');

    await expectLater(
      () => _service(repository, secondCloudId).changeCloudProduct(
        localProductId: localProductId,
        cloudProductId: secondCloudId,
      ),
      throwsA(isA<StateError>()),
    );
    expect(await repository.getCloudProductId(localProductId), firstCloudId);
  });

  test('Unlink is blocked when syncing outbox references the product', () async {
    final repository = ProductRepository();
    final localProductId = await _createProduct(repository, 'Rose');
    await repository.setCloudProductId(localProductId, firstCloudId, currentCompanyId);
    await _insertOutbox(localProductId: localProductId, state: 'syncing');

    await expectLater(
      () => _service(repository, firstCloudId).unlinkCloudProduct(
        localProductId: localProductId,
      ),
      throwsA(isA<StateError>()),
    );
    expect(await repository.getCloudProductId(localProductId), firstCloudId);
  });

  test('historical outbox payload is never modified and does not block unlink', () async {
    final repository = ProductRepository();
    final localProductId = await _createProduct(repository, 'Rose');
    await repository.setCloudProductId(localProductId, firstCloudId, currentCompanyId);
    final outboxId = await _insertOutbox(localProductId: localProductId, state: 'completed');
    final before = await _outboxPayload(outboxId);

    await _service(repository, firstCloudId).unlinkCloudProduct(
      localProductId: localProductId,
    );

    expect(await repository.getCloudProductId(localProductId), isNull);
    expect(await _outboxPayload(outboxId), before);
  });

  test('name SKU and barcode matches do not automatically create mapping', () async {
    final repository = ProductRepository();
    final localProductId = await repository.createProduct(
      const ProductUpsertInput(
        name: 'Same Name',
        category: 'Flowers',
        defaultUnit: 'Stem',
        sellingPricePaise: 1000,
        sku: 'SAME-SKU',
        manufacturerBarcode: 'SAME-BARCODE',
      ),
    );
    var verifiedId = '';
    final service = ProductCloudLinkingService(
      productRepository: repository,
      isOnline: () async => true,
      currentCompanyId: () async => currentCompanyId,
      verifyCloudProduct: (id) async {
        verifiedId = id;
        return _cloudProduct(id, name: 'Same Name', sku: 'SAME-SKU', barcode: 'SAME-BARCODE');
      },
    );

    expect(await repository.getCloudProductId(localProductId), isNull);
    await service.linkCloudProduct(
      localProductId: localProductId,
      cloudProductId: secondCloudId,
    );

    expect(verifiedId, secondCloudId);
    expect(await repository.getCloudProductId(localProductId), secondCloudId);
  });

  test('legacy cloud_product_id with null company is not syncable', () async {
    final repository = ProductRepository();
    final localProductId = await _createProduct(repository, 'Rose');
    final db = await AppDatabase.instance.database;
    await db.update(
      'products',
      {'cloud_product_id': firstCloudId, 'cloud_product_company_id': null},
      where: 'id = ?',
      whereArgs: [localProductId],
    );

    final result = await _syncability().evaluate(localProductId: localProductId);
    expect(result.isSyncable, isFalse);
  });

  test('mapping for wrong company is not syncable', () async {
    final repository = ProductRepository();
    final localProductId = await _createProduct(repository, 'Rose');
    await repository.setCloudProductId(localProductId, firstCloudId, otherCompanyId);

    final result = await _syncability().evaluate(localProductId: localProductId);
    expect(result.isSyncable, isFalse);
  });

  test('mapping for current company is syncable', () async {
    final repository = ProductRepository();
    final localProductId = await _createProduct(repository, 'Rose');
    await repository.setCloudProductId(localProductId, firstCloudId, currentCompanyId);

    final result = await _syncability().evaluate(localProductId: localProductId);
    expect(result.isSyncable, isTrue);
    expect(result.localProductId, localProductId);
    expect(result.cloudProductId, firstCloudId);
  });

  test('logged-out no-company state is not syncable', () async {
    final repository = ProductRepository();
    final localProductId = await _createProduct(repository, 'Rose');
    await repository.setCloudProductId(localProductId, firstCloudId, currentCompanyId);

    final result = await ProductCloudSyncabilityService(
      currentCompanyId: () async => null,
    ).evaluate(localProductId: localProductId);
    expect(result.isSyncable, isFalse);
  });

  test('offline mode does not attempt linking', () async {
    final repository = ProductRepository();
    final localProductId = await _createProduct(repository, 'Rose');
    var verifyCalls = 0;
    final service = ProductCloudLinkingService(
      productRepository: repository,
      isOnline: () async => false,
      currentCompanyId: () async => currentCompanyId,
      verifyCloudProduct: (_) async {
        verifyCalls++;
        return _cloudProduct(firstCloudId);
      },
    );

    await expectLater(
      () => service.linkCloudProduct(
        localProductId: localProductId,
        cloudProductId: firstCloudId,
      ),
      throwsA(isA<StateError>()),
    );
    expect(verifyCalls, 0);
    expect(await repository.getCloudProductId(localProductId), isNull);
  });
}

Future<int> _createProduct(ProductRepository repository, String name) {
  return repository.createProduct(
    ProductUpsertInput(
      name: name,
      category: 'Flowers',
      defaultUnit: 'Stem',
      sellingPricePaise: 1000,
    ),
  );
}

ProductCloudLinkingService _service(
  ProductRepository repository,
  String expectedCloudId,
) {
  return ProductCloudLinkingService(
    productRepository: repository,
    isOnline: () async => true,
    currentCompanyId: () async => currentCompanyId,
    verifyCloudProduct: (id) async => _cloudProduct(id == expectedCloudId ? id : expectedCloudId),
  );
}

ProductCloudSyncabilityService _syncability() {
  return ProductCloudSyncabilityService(
    currentCompanyId: () async => currentCompanyId,
  );
}

Future<void> _expectVerificationFailureDoesNotPersist(Object error) async {
  final repository = ProductRepository();
  final localProductId = await _createProduct(repository, 'Rose');
  final service = ProductCloudLinkingService(
    productRepository: repository,
    isOnline: () async => true,
    currentCompanyId: () async => currentCompanyId,
    verifyCloudProduct: (_) async => throw error,
  );

  await expectLater(
    () => service.linkCloudProduct(
      localProductId: localProductId,
      cloudProductId: firstCloudId,
    ),
    throwsA(anything),
  );
  expect(await repository.getCloudProductId(localProductId), isNull);
}

Future<int> _insertOutbox({
  required int localProductId,
  required String state,
}) async {
  final db = await AppDatabase.instance.database;
  final now = DateTime.now().toIso8601String();
  return db.insert('pos_sync_outbox', {
    'operation_type': 'completed_pos_sale',
    'client_sync_id': 'sync-$state-$localProductId',
    'local_order_id': localProductId + 1000,
    'payload_json': jsonEncode({
      'lines': [
        {'product_id': localProductId, 'description': 'Rose'}
      ],
      'inventoryTransactions': [
        {'product_id': localProductId, 'qty': 1}
      ],
    }),
    'state': state,
    'attempt_count': 0,
    'created_at': now,
    'updated_at': now,
  });
}

Future<String> _outboxPayload(int outboxId) async {
  final db = await AppDatabase.instance.database;
  final rows = await db.query(
    'pos_sync_outbox',
    columns: ['payload_json'],
    where: 'id = ?',
    whereArgs: [outboxId],
    limit: 1,
  );
  return rows.single['payload_json'] as String;
}

CloudProduct _cloudProduct(
  String id, {
  bool isActive = true,
  String name = 'Cloud Rose',
  String sku = 'CLOUD-ROSE',
  String? barcode,
}) {
  return CloudProduct(
    id: id,
    companyId: currentCompanyId,
    name: name,
    sku: sku,
    barcode: barcode,
    manufacturerBarcode: barcode,
    internalBarcode: null,
    brand: null,
    description: null,
    category: 'Flowers',
    categoryId: null,
    unitOfMeasure: 'Stem',
    retailPrice: 10,
    costPrice: 5,
    wholesalePrice: null,
    weddingEventPrice: null,
    taxCategory: 'Standard',
    trackInventory: true,
    trackBatch: false,
    stockQuantity: 10,
    minimumStockLevel: 1,
    reorderLevel: 1,
    isActive: isActive,
    shelfLifeDays: null,
    expiryAlertDays: null,
    temperatureNotes: null,
    createdAtUtc: DateTime.utc(2026, 1, 1),
    updatedAtUtc: null,
  );
}