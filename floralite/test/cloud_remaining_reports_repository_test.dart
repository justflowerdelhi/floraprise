import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/data/repositories/cloud_remaining_reports_repository.dart';

void main() {
  test('cloud rewards parses totals and ranked customers', () async {
    final repository = CloudRemainingReportsRepository(
      sender: (uri) async {
        expect(uri.path, '/api/accounting/rewards-summary');
        return {
          'currentPoints': 30,
          'lifetimePoints': 50,
          'redeemedPoints': 20,
          'rewardOrders': 4,
          'discountAmount': 125.50,
          'customers': [
            {
              'customerId': 'customer-1',
              'customerName': 'Anita',
              'phone': '9876543210',
              'rewardPoints': 20,
              'lifetimeRewardPoints': 30,
              'redeemedRewardPoints': 10,
            },
          ],
        };
      },
    );

    final report = await repository.getRewardsReport();

    expect(report, isNotNull);
    expect(report!.currentPoints, 30);
    expect(report.discountPaise, 12550);
    expect(report.rewardOrders, 4);
    expect(report.customers.single['name'], 'Anita');
    expect(report.customers.single['reward_points'], 20);
  });

  test('cloud top products sends range and parses line metrics', () async {
    final repository = CloudRemainingReportsRepository(
      sender: (uri) async {
        expect(uri.path, '/api/accounting/top-products');
        expect(uri.queryParameters['from'], '2026-09-08');
        expect(uri.queryParameters['to'], '2026-09-10');
        expect(uri.queryParameters['limit'], '10');
        return [
          {
            'productId': 'product-1',
            'productName': 'Rose Bouquet',
            'quantitySold': 3,
            'totalRevenue': 450.75,
          },
        ];
      },
    );

    final products = await repository.getTopProducts(
      fromDate: DateTime(2026, 9, 8),
      toDate: DateTime(2026, 9, 10),
    );

    expect(products.single.productName, 'Rose Bouquet');
    expect(products.single.quantitySold, 3);
    expect(products.single.totalRevenuePaise, 45075);
  });

  test('cloud reports return empty results on failure without SQLite fallback',
      () async {
    final repository = CloudRemainingReportsRepository(
      sender: (_) async => throw const SocketException('offline'),
    );

    final rewards = await repository.getRewardsReport();
    final products = await repository.getTopProducts(
      fromDate: DateTime(2026, 9, 10),
      toDate: DateTime(2026, 9, 10),
    );

    expect(rewards, isNull);
    expect(products, isEmpty);
  });
}