import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/data/repositories/cloud_inventory_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cloud low stock parses products and caches them', () async {
    var calls = 0;
    final repository = CloudInventoryRepository(
      lowStockSender: (uri) async {
        calls++;
        expect(uri.path, '/api/v1/mobile/inventory/low-stock');
        return [
          {
            'productId': 'p-1',
            'name': 'Rose Bunch',
            'sku': 'ROSE-001',
            'currentQuantity': 4,
            'minimumQuantity': 5,
            'status': 'lowStock',
          },
          {
            'productId': 'p-2',
            'name': 'Lily Box',
            'sku': 'LILY-002',
            'currentQuantity': 0,
            'minimumQuantity': 2,
            'status': 'outOfStock',
          },
        ];
      },
    );

    final first = await repository.listLowStockProducts();
    expect(calls, 1);
    expect(first.length, 2);
    expect(first.first.status, 'lowStock');
    expect(first.first.isLowStock, isTrue);
    expect(first.first.isOutOfStock, isFalse);
    expect(first.last.status, 'outOfStock');
    expect(first.last.isOutOfStock, isTrue);
    expect(first.last.isLowStock, isFalse);

    final second = await repository.listLowStockProducts();
    expect(calls, 2);
    expect(second.length, 2);
  });

  test('cloud low stock falls back to cache on failure', () async {
    var shouldFail = false;
    final repository = CloudInventoryRepository(
      lowStockSender: (uri) async {
        if (shouldFail) {
          throw const SocketException('offline');
        }
        return [
          {
            'productId': 'p-3',
            'name': 'Fern Pack',
            'sku': 'FERN-003',
            'currentQuantity': 1,
            'minimumQuantity': 3,
            'status': 'lowStock',
          },
        ];
      },
    );

    final online = await repository.listLowStockProducts();
    expect(online, isNotEmpty);

    shouldFail = true;
    final offline = await repository.listLowStockProducts();
    expect(offline, isNotEmpty);
    expect(offline.single.name, 'Fern Pack');
  });

  test('cloud low stock returns empty list for zero-stock period', () async {
    final repository = CloudInventoryRepository(
      lowStockSender: (uri) async => const [],
    );

    final items = await repository.listLowStockProducts();
    expect(items, isEmpty);
  });

  test('CloudLowStockProduct detects lowStock and outOfStock conditions', () {
    final lowStock = CloudLowStockProduct.fromJson({
      'productId': 'p-10',
      'name': 'Tulip',
      'sku': 'TUL-10',
      'currentQuantity': 3,
      'minimumQuantity': 5,
      'status': 'lowStock',
    });
    expect(lowStock.isLowStock, isTrue);
    expect(lowStock.isOutOfStock, isFalse);

    final outOfStockZero = CloudLowStockProduct.fromJson({
      'productId': 'p-11',
      'name': 'Orchid',
      'sku': 'ORC-11',
      'currentQuantity': 0,
      'minimumQuantity': 2,
      'status': 'outOfStock',
    });
    expect(outOfStockZero.isOutOfStock, isTrue);
    expect(outOfStockZero.isLowStock, isFalse);

    final outOfStockNegative = CloudLowStockProduct.fromJson({
      'productId': 'p-12',
      'name': 'Hydrangea',
      'sku': 'HYD-12',
      'currentQuantity': -3,
      'minimumQuantity': 2,
      'status': 'outOfStock',
    });
    expect(outOfStockNegative.isOutOfStock, isTrue);
    expect(outOfStockNegative.isLowStock, isFalse);
  });

  test('CloudLowStockRepository wrapper delegates to CloudInventoryRepository', () async {
    final inner = CloudInventoryRepository(
      lowStockSender: (uri) async => [
        {
          'productId': 'p-20',
          'name': 'Carnation',
          'sku': 'CAR-20',
          'currentQuantity': 2,
          'minimumQuantity': 10,
          'status': 'lowStock',
        }
      ],
    );
    final repo = CloudLowStockRepository(inventoryRepository: inner);
    final result = await repo.listLowStockProducts();
    expect(result.length, 1);
    expect(result.first.name, 'Carnation');
    expect(result.first.isLowStock, isTrue);
  });
}
