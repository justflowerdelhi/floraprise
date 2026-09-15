import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/data/repositories/cloud_finance_repository.dart';
import 'package:floraprise/data/repositories/cloud_inventory_repository.dart';
import 'package:floraprise/data/repositories/cloud_production_repository.dart';

void main() {
  group('CloudDayCloseRepository', () {
    test('getByDateRange fetches history with date filters and maps CashExpenses', () async {
      final repo = CloudDayCloseRepository(
        sender: (method, uri, {body}) async {
          expect(method, 'GET');
          if (uri.path == '/api/locations') {
            return [
              {'id': 'loc-123', 'name': 'Main Store'}
            ];
          }
          if (uri.path == '/api/day-close/history') {
            expect(uri.queryParameters['locationId'], 'loc-123');
            expect(uri.queryParameters['startDate'], isNotNull);
            expect(uri.queryParameters['endDate'], isNotNull);
            return [
              {
                'id': 'dc-001',
                'locationId': 'loc-123',
                'businessDate': '2026-09-12T00:00:00Z',
                'closedAt': '2026-09-12T18:00:00Z',
                'cashTotal': 1500.50,
                'cardTotal': 800.00,
                'upiTotal': 1200.00,
                'cashExpenses': 350.25,
                'expectedCash': 1150.25,
                'actualCash': 1150.00,
                'cashVariance': -0.25,
                'notes': 'All balanced'
              }
            ];
          }
          throw StateError('Unexpected URI: $uri');
        },
      );

      final results = await repo.getByDateRange(
        DateTime(2026, 9, 1),
        DateTime(2026, 9, 12),
      );

      expect(results.length, 1);
      final dc = results.first;
      expect(dc.cashSales, 150050); // ₹1500.50 -> 150050 paise
      expect(dc.cardSales, 80000);
      expect(dc.upiSales, 120000);
      expect(dc.cashExpenses, 35025); // ₹350.25 -> 35025 paise
      expect(dc.expectedCash, 115025);
      expect(dc.countedCash, 115000);
      expect(dc.difference, -25);
      expect(dc.notes, 'All balanced');
    });
  });

  group('CloudInventoryRepository - Wastage', () {
    test('getWastageTransactions queries wastageOnly=true and maps parity fields', () async {
      final repo = CloudInventoryRepository(
        sender: (method, uri, {body}) async {
          expect(method, 'GET');
          expect(uri.path, '/api/inventory/adjustments');
          expect(uri.queryParameters['wastageOnly'], 'true');
          expect(uri.queryParameters['fromDate'], isNotNull);
          expect(uri.queryParameters['toDate'], isNotNull);

          return {
            'items': [
              {
                'id': 'adj-01',
                'productId': 'prod-rose',
                'productName': 'Red Rose Dutch',
                'category': 'Roses',
                'unit': 'Stem',
                'supplierName': 'Bharat Florals',
                'reason': 'Damaged',
                'adjustmentType': 'Damaged',
                'quantity': -10,
                'costPerUnit': 15.0,
                'totalValue': -150.0,
                'notes': 'Supplier: Bharat Florals | Crushed in box',
                'adjustmentDate': '2026-09-12T10:00:00Z'
              },
              {
                'id': 'adj-02',
                'productId': 'prod-lily',
                'productName': 'White Lily',
                'category': 'Lilies',
                'unit': 'Stem',
                'supplierName': 'Himalayan Blooms',
                'reason': 'Spoiled',
                'adjustmentType': 'Spoiled',
                'quantity': -5,
                'costPerUnit': 40.0,
                'totalValue': -200.0,
                'notes': 'Supplier: Himalayan Blooms',
                'adjustmentDate': '2026-09-12T11:00:00Z'
              }
            ],
            'totalCount': 2
          };
        },
      );

      final transactions = await repo.getWastageTransactions(
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 12),
      );

      expect(transactions.length, 2);

      final t1 = transactions.first;
      expect(t1.productName, 'Red Rose Dutch');
      expect(t1.category, 'Roses');
      expect(t1.unit, 'Stem');
      expect(t1.supplier, 'Bharat Florals');
      expect(t1.qty, 10); // Absolute wastage quantity
      expect(t1.purchasePricePaise, 1500); // ₹15.00 -> 1500 paise
      expect(t1.reason, 'Damaged');

      // Test category filter
      final roseOnly = await repo.getWastageTransactions(
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 12),
        category: 'Roses',
      );
      expect(roseOnly.length, 1);
      expect(roseOnly.first.productName, 'Red Rose Dutch');
    });
  });

  group('CloudProductionRepository', () {
    test('getProductionReport fetches batches and parses fields', () async {
      final repo = CloudProductionRepository(
        sender: (method, uri, {body}) async {
          expect(method, 'GET');
          expect(uri.path, '/api/production/finished-goods');
          expect(uri.queryParameters['startDate'], isNotNull);
          expect(uri.queryParameters['endDate'], isNotNull);

          return [
            {
              'id': 'batch-001',
              'recipeName': 'Bridal Rose Bouquet',
              'batchCode': 'FG-20260912-001',
              'quantityProduced': 5,
              'quantityAvailable': 5,
              'totalCost': 1250.50,
              'status': 'Active',
              'isReversed': false,
              'producedAt': '2026-09-12T09:00:00Z',
              'operatorName': 'Master Florist Sunita'
            }
          ];
        },
      );

      final records = await repo.getProductionReport(
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 12),
      );

      expect(records.length, 1);
      final r = records.first;
      expect(r.productName, 'Bridal Rose Bouquet');
      expect(r.quantity, 5);
      expect(r.productionCostPaise, 125050); // ₹1250.50 -> 125050 paise
      expect(r.currentStock, 5);
      expect(r.isReversed, isFalse);
    });

    test('getProductionDetail and reverseProduction work end-to-end', () async {
      var reversedCalled = false;

      final repo = CloudProductionRepository(
        sender: (method, uri, {body}) async {
          if (method == 'GET' && uri.path.startsWith('/api/production/finished-goods/')) {
            return {
              'id': 'batch-001',
              'recipeName': 'Bridal Rose Bouquet',
              'batchCode': 'FG-20260912-001',
              'quantityProduced': 5,
              'quantityAvailable': 5,
              'totalCost': 1250.50,
              'status': 'Active',
              'isReversed': false,
              'producedAt': '2026-09-12T09:00:00Z',
              'operatorName': 'Master Florist Sunita',
              'locationName': 'Delhi Connaught Place',
              'consumptions': [
                {
                  'rawProductId': 'prod-rose',
                  'productName': 'Red Rose Stem',
                  'unit': 'Stem',
                  'quantity': 25,
                  'unitCost': 40.0,
                  'totalCost': 1000.0
                },
                {
                  'rawProductId': 'prod-ribbon',
                  'productName': 'Satin Ribbon White',
                  'unit': 'Piece',
                  'quantity': 5,
                  'unitCost': 50.0,
                  'totalCost': 250.0
                }
              ]
            };
          }

          if (method == 'POST' && uri.path.endsWith('/reverse')) {
            reversedCalled = true;
            expect(body?['reason'], 'Cancelled event order');
            return {
              'id': 'batch-001',
              'status': 'Reversed',
              'isReversed': true,
              'reversalNote': 'Cancelled event order'
            };
          }

          throw StateError('Unexpected request: $method $uri');
        },
      );

      final detail = await repo.getProductionDetail(1);
      expect(detail, isNotNull);
      expect(detail!.productName, 'Bridal Rose Bouquet');
      expect(detail.quantity, 5);
      expect(detail.productionCostPaise, 125050);
      expect(detail.operatorName, 'Master Florist Sunita');
      expect(detail.deviceName, 'Delhi Connaught Place');
      expect(detail.consumptions.length, 2);

      final c1 = detail.consumptions.first;
      expect(c1.productName, 'Red Rose Stem');
      expect(c1.unit, 'Stem');
      expect(c1.quantity, 25);
      expect(c1.unitCostPaise, 4000);
      expect(c1.totalCostPaise, 100000);

      // Perform reversal
      await repo.reverseProduction(
        productionId: 1,
        note: 'Cancelled event order',
      );
      expect(reversedCalled, isTrue);
    });
  });
}
