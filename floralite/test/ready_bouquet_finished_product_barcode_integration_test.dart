import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/data/repositories/cloud_product_repository.dart';
import 'package:floraprise/data/repositories/inventory_repository.dart';
import 'package:floraprise/data/repositories/product_repository.dart';
import 'package:floraprise/data/repositories/production_repository.dart';
import 'package:floraprise/models/gst_calculation_type.dart';
import 'package:floraprise/models/storage_mode.dart';
import 'package:floraprise/services/storage_mode_service.dart';
import 'package:floraprise/widgets/product_picker_sheet.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeStorageModeService extends StorageModeService {
  final StorageMode _mode;
  _FakeStorageModeService(this._mode);

  @override
  Future<StorageMode?> getCurrentMode() async => _mode;
  @override
  Future<bool> isCloud() async => _mode == StorageMode.cloud;
  @override
  Future<bool> isLocal() async => _mode == StorageMode.local;
  @override
  Future<bool> hasSelectedMode() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    AppDatabase.useInMemoryForTests = true;
  });

  tearDown(() async {
    await AppDatabase.instance.close();
  });

  group('Ready Bouquet → Finished Product → Barcode Integration Tests', () {
    test('Solo: ONE Product Master is reused for repeated production of the same bouquet', () async {
      final db = await AppDatabase.instance.database;
      final prodRepo = ProductionRepository(storageModeService: _FakeStorageModeService(StorageMode.local));

      // 1. Setup raw materials in SQLite
      final rawRoseId = await db.insert('products', {
        'name': 'Red Rose Stem',
        'category': 'Flowers',
        'default_unit': 'Stem',
        'selling_price_paise': 2000,
        'purchase_price_paise': 1000,
        'track_inventory': 1,
        'active': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      await db.insert('inventory_items', {
        'product_id': rawRoseId,
        'current_qty': 50,
        'min_qty': 5,
        'updated_at': DateTime.now().toIso8601String(),
      });

      final components = [
        RecipeItem(
          rawProductId: rawRoseId,
          productName: 'Red Rose Stem',
          unit: 'Stem',
          quantity: 10,
          currentQty: 50,
          purchasePricePaise: 1000,
        ),
      ];

      // 2. Produce first bouquet unit
      final result1 = await prodRepo.produceBouquet(
        finishedProductId: null,
        productName: 'Grand Crimson Bouquet',
        category: 'Bouquet',
        quantity: 1,
        components: components,
        sellingPricePaise: 50000,
        labourCostPaise: 5000,
      );

      expect(result1.finishedProductId, isNotNull);
      final firstProductId = result1.finishedProductId;

      // Verify 1 product record exists for 'Grand Crimson Bouquet'
      var productRows = await db.query(
        'products',
        where: 'name = ?',
        whereArgs: ['Grand Crimson Bouquet'],
      );
      expect(productRows.length, 1);
      expect(productRows.first['id'], firstProductId);
      expect(productRows.first['category'], 'Bouquet');
      expect(productRows.first['floraprise_barcode'], isNotNull);

      // Verify 1 physical batch record exists
      var batchRows = await db.query(
        'ready_bouquet_batches',
        where: 'finished_product_id = ?',
        whereArgs: [firstProductId],
      );
      expect(batchRows.length, 1);
      expect(batchRows.first['initial_quantity'], 1);
      expect(batchRows.first['remaining_quantity'], 1);

      // 3. Produce second bouquet of the exact SAME name
      final result2 = await prodRepo.produceBouquet(
        finishedProductId: null, // null triggers lookup by name
        productName: 'Grand Crimson Bouquet',
        category: 'Bouquet',
        quantity: 1,
        components: components,
        sellingPricePaise: 50000,
        labourCostPaise: 5000,
      );

      // Verify the SAME Product Master ID is reused
      expect(result2.finishedProductId, firstProductId);

      // Verify STILL only ONE product master record exists
      productRows = await db.query(
        'products',
        where: 'name = ?',
        whereArgs: ['Grand Crimson Bouquet'],
      );
      expect(productRows.length, 1, reason: 'Must NOT duplicate Product master for repeated production');

      // Verify TWO distinct physical batch records exist
      batchRows = await db.query(
        'ready_bouquet_batches',
        where: 'finished_product_id = ?',
        whereArgs: [firstProductId],
      );
      expect(batchRows.length, 2, reason: 'Each produce action must create a distinct physical batch');
      expect(batchRows[0]['id'], isNot(equals(batchRows[1]['id'])));

      // Verify inventory item current_qty is aggregated to 2
      final invItem = await db.query(
        'inventory_items',
        where: 'product_id = ?',
        whereArgs: [firstProductId],
      );
      expect(invItem.first['current_qty'], 2);
    });

    test('Inventory Finished Products filter correctly classifies all finished good categories', () {
      expect(ProductionRepository.isFinishedProductCategory('Finished Products'), isTrue);
      expect(ProductionRepository.isFinishedProductCategory('Finished Product'), isTrue);
      expect(ProductionRepository.isFinishedProductCategory('Bouquet'), isTrue);
      expect(ProductionRepository.isFinishedProductCategory('Bouquets'), isTrue);
      expect(ProductionRepository.isFinishedProductCategory('Bunch'), isTrue);
      expect(ProductionRepository.isFinishedProductCategory('Bunches'), isTrue);
      expect(ProductionRepository.isFinishedProductCategory('Arrangement'), isTrue);
      expect(ProductionRepository.isFinishedProductCategory('Arrangements'), isTrue);
      expect(ProductionRepository.isFinishedProductCategory('Centerpiece'), isTrue);
      expect(ProductionRepository.isFinishedProductCategory('Floral Box'), isTrue);

      expect(ProductionRepository.isFinishedProductCategory('Flowers'), isFalse);
      expect(ProductionRepository.isFinishedProductCategory('Fillers'), isFalse);
      expect(ProductionRepository.isFinishedProductCategory('Packing'), isFalse);
      expect(ProductionRepository.isFinishedProductCategory('Accessories'), isFalse);
    });

    test('Solo: ProductRepository.listProducts(category: Finished Products) returns bouquets and arrangements', () async {
      final db = await AppDatabase.instance.database;
      final productRepo = ProductRepository();

      await db.insert('products', {
        'name': 'Rose Bouquet Luxury',
        'category': 'Bouquet',
        'default_unit': 'Piece',
        'selling_price_paise': 3500,
        'track_inventory': 1,
        'active': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      await db.insert('products', {
        'name': 'Table Centerpiece Arrangement',
        'category': 'Arrangement',
        'default_unit': 'Piece',
        'selling_price_paise': 4500,
        'track_inventory': 1,
        'active': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      await db.insert('products', {
        'name': 'Red Rose Single Stem',
        'category': 'Flowers',
        'default_unit': 'Stem',
        'selling_price_paise': 100,
        'track_inventory': 1,
        'active': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      final finishedProducts = await productRepo.listProducts(category: 'Finished Products');
      final names = finishedProducts.map((p) => p.name).toList();

      expect(names, contains('Rose Bouquet Luxury'));
      expect(names, contains('Table Centerpiece Arrangement'));
      expect(names, isNot(contains('Red Rose Single Stem')));
    });

    test('Cloud: CloudProductRepository.listProducts(category: Finished Products) merges sellable finished goods', () async {
      final cloudRepo = CloudProductRepository(
        send: (method, uri, {body}) async {
          if (uri.path.contains('/api/products/search')) {
            return {
              'items': <Map<String, dynamic>>[],
              'totalCount': 0,
            };
          }
          if (uri.path.contains('/api/production/finished-goods/sellable')) {
            return [
              {
                'id': 'fg-batch-1',
                'name': 'Cloud Silk Bouquet',
                'category': 'Bouquet',
                'sku': 'BATCH-001',
                'barcode': 'FL00000001',
                'retailPrice': 65.0,
                'costPrice': 25.0,
                'stockQuantity': 3,
                'isActive': true,
              }
            ];
          }
          return <Map<String, dynamic>>[];
        },
      );

      final products = await cloudRepo.listProducts(category: 'Finished Products');
      expect(products.length, 1);
      expect(products.first.name, 'Cloud Silk Bouquet');
      expect(products.first.barcode, 'FL00000001');
      expect(products.first.sku, 'BATCH-001');
      expect(products.first.category, 'Bouquet');
    });

    test('POS: FinishedGoodsBatch (BatchId != RecipeId) reconciles to single POS row with correct non-zero selling price', () {
      final inventoryProducts = [
        const InventoryProductRecord(
          productId: -1,
          cloudProductId: 'recipe-guid-8888', // Recipe GUID from CloudInventoryRepository
          name: 'Royal Velvet Bouquet',
          category: 'Bouquets',
          unit: 'Piece',
          sku: 'FG-20260929-001',
          barcode: '8901234560001',
          manufacturerBarcode: '8901234560001',
          internalBarcode: 'FG-20260929-001',
          trackInventory: true,
          gstPercent: 0,
          gstCalculationType: GstCalculationType.inclusive,
          currentQty: 1,
          minQty: 0,
        ),
      ];

      final cloudProducts = [
        CloudProduct(
          id: 'batch-guid-1111', // Batch GUID from CloudProductRepository.listSellableFinishedGoods
          companyId: 'comp-1',
          name: 'Royal Velvet Bouquet',
          sku: 'FG-20260929-001',
          barcode: '8901234560001',
          manufacturerBarcode: '8901234560001',
          internalBarcode: 'FG-20260929-001',
          brand: null,
          description: null,
          category: 'Bouquets',
          categoryId: null,
          unitOfMeasure: 'Piece',
          retailPrice: 800.0, // Master recipe price: ₹800
          costPrice: 350.0,
          wholesalePrice: null,
          weddingEventPrice: null,
          taxCategory: 'Standard',
          trackInventory: true,
          trackBatch: true,
          stockQuantity: 1,
          minimumStockLevel: 0,
          reorderLevel: 0,
          isActive: true,
          shelfLifeDays: null,
          expiryAlertDays: null,
          temperatureNotes: null,
          createdAtUtc: DateTime.now(),
          updatedAtUtc: null,
        ),
      ];

      final rows = productPickerRowsFromCloudInventory(inventoryProducts, cloudProducts);

      // Must produce exactly ONE row
      expect(rows.length, 1, reason: 'Must not emit duplicate rows for the same produced bouquet');
      final posRow = rows.first;
      expect(posRow.name, 'Royal Velvet Bouquet');
      expect(posRow.sku, 'FG-20260929-001');
      expect(posRow.barcode, '8901234560001');
      // Selling price must be ₹800 (80000 paise), NOT ₹0
      expect(posRow.sellingPricePaise, 80000, reason: 'POS row must use recipe retailPrice ₹800');
      expect(posRow.currentQty, 1);
      // Ensure zero ₹0 rows exist
      expect(rows.any((r) => r.sellingPricePaise == 0), isFalse);
    });

    test('POS: Repeated production batches (Batch 1 + Batch 2) both receive master selling price with no duplicate ₹0 rows', () {
      final inventoryProducts = [
        const InventoryProductRecord(
          productId: -1,
          cloudProductId: 'recipe-guid-8888',
          name: 'Royal Velvet Bouquet',
          category: 'Bouquets',
          unit: 'Piece',
          sku: 'FG-20260929-001',
          barcode: '8901234560001',
          manufacturerBarcode: '8901234560001',
          internalBarcode: 'FG-20260929-001',
          trackInventory: true,
          gstPercent: 0,
          gstCalculationType: GstCalculationType.inclusive,
          currentQty: 2,
          minQty: 0,
        ),
      ];

      final cloudProducts = [
        CloudProduct(
          id: 'batch-guid-1111',
          companyId: 'comp-1',
          name: 'Royal Velvet Bouquet',
          sku: 'FG-20260929-001',
          barcode: '8901234560001',
          manufacturerBarcode: '8901234560001',
          internalBarcode: 'FG-20260929-001',
          brand: null,
          description: null,
          category: 'Bouquets',
          categoryId: null,
          unitOfMeasure: 'Piece',
          retailPrice: 800.0,
          costPrice: 350.0,
          wholesalePrice: null,
          weddingEventPrice: null,
          taxCategory: 'Standard',
          trackInventory: true,
          trackBatch: true,
          stockQuantity: 1,
          minimumStockLevel: 0,
          reorderLevel: 0,
          isActive: true,
          shelfLifeDays: null,
          expiryAlertDays: null,
          temperatureNotes: null,
          createdAtUtc: DateTime.now(),
          updatedAtUtc: null,
        ),
        CloudProduct(
          id: 'batch-guid-2222',
          companyId: 'comp-1',
          name: 'Royal Velvet Bouquet',
          sku: 'FG-20260929-002',
          barcode: '8901234560002',
          manufacturerBarcode: '8901234560002',
          internalBarcode: 'FG-20260929-002',
          brand: null,
          description: null,
          category: 'Bouquets',
          categoryId: null,
          unitOfMeasure: 'Piece',
          retailPrice: 800.0,
          costPrice: 350.0,
          wholesalePrice: null,
          weddingEventPrice: null,
          taxCategory: 'Standard',
          trackInventory: true,
          trackBatch: true,
          stockQuantity: 1,
          minimumStockLevel: 0,
          reorderLevel: 0,
          isActive: true,
          shelfLifeDays: null,
          expiryAlertDays: null,
          temperatureNotes: null,
          createdAtUtc: DateTime.now(),
          updatedAtUtc: null,
        ),
      ];

      final rows = productPickerRowsFromCloudInventory(inventoryProducts, cloudProducts);

      // Exactly 2 physical batch rows, zero ₹0 duplicates
      expect(rows.length, 2);
      expect(rows.every((r) => r.sellingPricePaise == 80000), isTrue);
      expect(rows.map((r) => r.sku).toList(), containsAll(['FG-20260929-001', 'FG-20260929-002']));
      expect(rows.any((r) => r.sellingPricePaise == 0), isFalse);
    });

    test('POS: Regular catalogue products match by Product.Id and retain selling price unchanged', () {
      final inventoryProducts = [
        const InventoryProductRecord(
          productId: 101,
          cloudProductId: 'product-guid-101',
          name: 'Dutch Red Rose Stem',
          category: 'Flowers',
          unit: 'Stem',
          sku: 'ROSE-DUTCH-RED',
          barcode: '8909990001',
          manufacturerBarcode: '8909990001',
          internalBarcode: 'ROSE-DUTCH-RED',
          trackInventory: true,
          gstPercent: 5,
          gstCalculationType: GstCalculationType.inclusive,
          currentQty: 45,
          minQty: 10,
        ),
      ];

      final cloudProducts = [
        CloudProduct(
          id: 'product-guid-101',
          companyId: 'comp-1',
          name: 'Dutch Red Rose Stem',
          sku: 'ROSE-DUTCH-RED',
          barcode: '8909990001',
          manufacturerBarcode: '8909990001',
          internalBarcode: 'ROSE-DUTCH-RED',
          brand: null,
          description: null,
          category: 'Flowers',
          categoryId: null,
          unitOfMeasure: 'Stem',
          retailPrice: 40.0,
          costPrice: 15.0,
          wholesalePrice: null,
          weddingEventPrice: null,
          taxCategory: 'Standard',
          trackInventory: true,
          trackBatch: false,
          stockQuantity: 45,
          minimumStockLevel: 10,
          reorderLevel: 20,
          isActive: true,
          shelfLifeDays: null,
          expiryAlertDays: null,
          temperatureNotes: null,
          createdAtUtc: DateTime.now(),
          updatedAtUtc: null,
        ),
      ];

      final rows = productPickerRowsFromCloudInventory(inventoryProducts, cloudProducts);

      expect(rows.length, 1);
      final row = rows.first;
      expect(row.name, 'Dutch Red Rose Stem');
      expect(row.sellingPricePaise, 4000); // ₹40
      expect(row.currentQty, 45);
      expect(row.gstPercent, 5);
    });
  });
}
