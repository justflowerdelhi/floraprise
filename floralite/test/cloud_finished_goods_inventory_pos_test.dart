import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/data/repositories/cloud_inventory_repository.dart';
import 'package:floraprise/data/repositories/cloud_product_repository.dart';
import 'package:floraprise/data/repositories/inventory_repository.dart';
import 'package:floraprise/models/gst_calculation_type.dart';
import 'package:floraprise/widgets/product_picker_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CloudInventoryRepository - Finished Goods Parity', () {
    test('listInventoryProducts merges finished goods batches into inventory products', () async {
      final repository = CloudInventoryRepository(
        sender: (method, uri, {body}) async {
          if (uri.path == '/api/inventory/products') {
            return [
              {
                'id': 'raw-01',
                'name': 'Red Rose Stem',
                'category': 'Flowers',
                'unit': 'Stem',
                'sku': 'SKU-ROSE',
                'manufacturerBarcode': '8901111',
                'trackInventory': true,
                'currentQuantity': 50,
                'minimumQuantity': 10,
              },
            ];
          }
          if (uri.path == '/api/production/finished-goods') {
            return [
              {
                'id': 'fg-batch-01',
                'recipeId': 'recipe-01',
                'recipeName': 'Red Rose Deluxe Bouquet',
                'batchCode': 'FG-20260923-001',
                'barcode': '8902222',
                'quantityProduced': 5,
                'quantityAvailable': 3,
                'status': 'Active',
              },
              {
                'id': 'fg-batch-02',
                'recipeId': 'recipe-01',
                'recipeName': 'Red Rose Deluxe Bouquet',
                'batchCode': 'FG-20260923-002',
                'barcode': '8902222',
                'quantityProduced': 4,
                'quantityAvailable': 2,
                'status': 'Active',
              },
            ];
          }
          return null;
        },
      );

      final items = await repository.listInventoryProducts();
      expect(items.length, 2);

      // Raw product
      final rawItem = items.firstWhere((p) => p.cloudProductId == 'raw-01');
      expect(rawItem.name, 'Red Rose Stem');
      expect(rawItem.category, 'Flowers');
      expect(rawItem.currentQty, 50);

      // Aggregated finished good
      final fgItem = items.firstWhere((p) => p.cloudProductId == 'recipe-01');
      expect(fgItem.name, 'Red Rose Deluxe Bouquet');
      expect(fgItem.category, 'Bouquets');
      expect(fgItem.trackInventory, isTrue);
      expect(fgItem.currentQty, 5); // 3 + 2 = 5
      expect(fgItem.sku, 'FG-20260923-001');
      expect(fgItem.barcode, '8902222');
    });
  });

  group('CloudProductRepository & POS Finished Goods Parity', () {
    test('listSellableFinishedGoods fetches from /api/production/finished-goods/sellable', () async {
      final repository = CloudProductRepository(
        send: (method, uri, {body}) async {
          if (uri.path == '/api/production/finished-goods/sellable') {
            return [
              {
                'id': 'fg-sellable-01',
                'name': '150 Mix Roses Bouquet',
                'sku': 'FG-20260923-003',
                'barcode': '8903333',
                'category': 'Bouquets',
                'retailPrice': 3000.0,
                'costPrice': 1500.0,
                'stockQuantity': 2,
                'isActive': true,
              }
            ];
          }
          return null;
        },
      );

      final sellable = await repository.listSellableFinishedGoods();
      expect(sellable.length, 1);
      final item = sellable.first;
      expect(item.id, 'fg-sellable-01');
      expect(item.name, '150 Mix Roses Bouquet');
      expect(item.sku, 'FG-20260923-003');
      expect(item.category, 'Bouquets');
      expect(item.retailPrice, 3000.0);
      expect(item.stockQuantity, 2);
      expect(item.isActive, isTrue);
    });

    test('productPickerRowsFromCloudInventory includes sellable finished goods with stock and price', () {
      final inventoryProducts = [
        const InventoryProductRecord(
          productId: -1,
          cloudProductId: 'raw-01',
          name: 'Red Rose',
          category: 'Flowers',
          unit: 'Stem',
          sku: 'ROSE-01',
          barcode: '8901111',
          manufacturerBarcode: '8901111',
          internalBarcode: '',
          trackInventory: true,
          gstPercent: 0,
          gstCalculationType: GstCalculationType.inclusive,
          currentQty: 20,
          minQty: 5,
        ),
        const InventoryProductRecord(
          productId: -2,
          cloudProductId: 'fg-sellable-01',
          name: '150 Mix Roses Bouquet',
          category: 'Bouquets',
          unit: 'Piece',
          sku: 'FG-20260923-003',
          barcode: '8903333',
          manufacturerBarcode: '8903333',
          internalBarcode: 'FG-20260923-003',
          trackInventory: true,
          gstPercent: 0,
          gstCalculationType: GstCalculationType.inclusive,
          currentQty: 2,
          minQty: 0,
        ),
      ];

      final cloudProducts = [
        CloudProduct(
          id: 'raw-01',
          companyId: 'c1',
          name: 'Red Rose',
          sku: 'ROSE-01',
          barcode: '8901111',
          manufacturerBarcode: '8901111',
          internalBarcode: null,
          brand: null,
          description: null,
          category: 'Flowers',
          categoryId: null,
          unitOfMeasure: 'Stem',
          retailPrice: 50.0,
          costPrice: 20.0,
          wholesalePrice: null,
          weddingEventPrice: null,
          taxCategory: 'Standard',
          trackInventory: true,
          trackBatch: false,
          stockQuantity: 20,
          minimumStockLevel: 5,
          reorderLevel: 5,
          isActive: true,
          shelfLifeDays: null,
          expiryAlertDays: null,
          temperatureNotes: null,
          createdAtUtc: DateTime.now(),
          updatedAtUtc: null,
        ),
        CloudProduct(
          id: 'fg-sellable-01',
          companyId: 'c1',
          name: '150 Mix Roses Bouquet',
          sku: 'FG-20260923-003',
          barcode: '8903333',
          manufacturerBarcode: '8903333',
          internalBarcode: 'FG-20260923-003',
          brand: null,
          description: null,
          category: 'Bouquets',
          categoryId: null,
          unitOfMeasure: 'Piece',
          retailPrice: 3000.0,
          costPrice: 1500.0,
          wholesalePrice: null,
          weddingEventPrice: null,
          taxCategory: 'Standard',
          trackInventory: true,
          trackBatch: true,
          stockQuantity: 2,
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
      expect(rows.length, 2);

      final bouquetRow = rows.firstWhere((r) => r.name == '150 Mix Roses Bouquet');
      expect(bouquetRow.category, 'Bouquets');
      expect(bouquetRow.sellingPricePaise, 300000); // ₹3,000
      expect(bouquetRow.currentQty, 2);
      expect(productPickerCanSelect(bouquetRow), isTrue);
      expect(productPickerIsOutOfStock(bouquetRow), isFalse);
    });
  });
}
