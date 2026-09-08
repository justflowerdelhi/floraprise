import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/data/repositories/cloud_dashboard_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cloud dashboard summary parses response and caches it', () async {
    var calls = 0;
    final repository = CloudDashboardRepository(
      summarySender: (uri) async {
        calls++;
        expect(uri.path, '/api/v1/mobile/dashboard/summary');
        expect(uri.queryParameters['fromDate'], isNotNull);
        expect(uri.queryParameters['toDate'], isNotNull);
        return {
          'totalSalesPaise': 20000,
          'orderCount': 2,
          'cashPaise': 7000,
          'upiPaise': 4000,
          'cardPaise': 3000,
          'creditPaise': 0,
          'pendingOrderCount': 1,
          'preparingOrderCount': 1,
          'readyOrderCount': 1,
          'outForDeliveryCount': 0,
          'deliveryCount': 1,
          'pickupCount': 1,
          'expensePaise': 1500,
        };
      },
    );

    final first = await repository.getSummary(
      fromDate: DateTime(2026, 9, 8),
      toDate: DateTime(2026, 9, 8),
    );

    expect(calls, 1);
    expect(first, isNotNull);
    expect(first!.totalSalesPaise, 20000);
    expect(first.orderCount, 2);
    expect(first.expensePaise, 1500);

    final second = await repository.getSummary(
      fromDate: DateTime(2026, 9, 8),
      toDate: DateTime(2026, 9, 8),
    );
    expect(calls, 2);
    expect(second!.orderCount, 2);
  });

  test('cloud dashboard summary falls back to cache on failure', () async {
    var shouldFail = false;
    final repository = CloudDashboardRepository(
      summarySender: (uri) async {
        if (shouldFail) {
          throw const SocketException('offline');
        }
        return {
          'totalSalesPaise': 5000,
          'orderCount': 1,
          'cashPaise': 5000,
          'upiPaise': 0,
          'cardPaise': 0,
          'creditPaise': 0,
          'pendingOrderCount': 0,
          'preparingOrderCount': 0,
          'readyOrderCount': 0,
          'outForDeliveryCount': 0,
          'deliveryCount': 1,
          'pickupCount': 0,
          'expensePaise': 100,
        };
      },
    );

    final online = await repository.getSummary(
      fromDate: DateTime(2026, 9, 7),
      toDate: DateTime(2026, 9, 7),
    );
    expect(online, isNotNull);
    expect(online!.totalSalesPaise, 5000);

    shouldFail = true;
    final offline = await repository.getSummary(
      fromDate: DateTime(2026, 9, 7),
      toDate: DateTime(2026, 9, 7),
    );
    expect(offline, isNotNull);
    expect(offline!.totalSalesPaise, 5000);
    expect(offline.expensePaise, 100);
  });

  test('cloud dashboard summary returns zero values for an empty period', () async {
    final repository = CloudDashboardRepository(
      summarySender: (uri) async => {
        'totalSalesPaise': 0,
        'orderCount': 0,
        'cashPaise': 0,
        'upiPaise': 0,
        'cardPaise': 0,
        'creditPaise': 0,
        'pendingOrderCount': 0,
        'preparingOrderCount': 0,
        'readyOrderCount': 0,
        'outForDeliveryCount': 0,
        'deliveryCount': 0,
        'pickupCount': 0,
        'expensePaise': 0,
      },
    );

    final summary = await repository.getSummary(
      fromDate: DateTime(2026, 9, 10),
      toDate: DateTime(2026, 9, 10),
    );

    expect(summary, isNotNull);
    expect(summary!.orderCount, 0);
    expect(summary.totalSalesPaise, 0);
    expect(summary.expensePaise, 0);
  });
}
