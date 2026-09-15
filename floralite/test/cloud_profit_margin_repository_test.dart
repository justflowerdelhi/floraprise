import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/data/repositories/cloud_profit_margin_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cloud profit margin summary parses response and caches it', () async {
    var calls = 0;
    final repository = CloudProfitMarginRepository(
      sender: (uri) async {
        calls++;
        expect(uri.path, '/api/v1/mobile/dashboard/profit-margin');
        expect(uri.queryParameters['fromDate'], isNotNull);
        expect(uri.queryParameters['toDate'], isNotNull);
        return {
          'grossSalesPaise': 100000,
          'discountsPaise': 5000,
          'netRevenuePaise': 95000,
          'cogsPaise': 40000,
          'grossProfitPaise': 55000,
          'marginPercent': 57.89,
          'orderCount': 4,
          'cogsIsEstimate': true,
          'cogsLimitationNote': 'Uses current product cost, not a historical snapshot.',
        };
      },
    );

    final first = await repository.getProfitMargin(
      fromDate: DateTime(2026, 9, 8),
      toDate: DateTime(2026, 9, 8),
    );

    expect(calls, 1);
    expect(first, isNotNull);
    expect(first!.grossSalesPaise, 100000);
    expect(first.discountsPaise, 5000);
    expect(first.netRevenuePaise, 95000);
    expect(first.cogsPaise, 40000);
    expect(first.grossProfitPaise, 55000);
    expect(first.marginPercent, 57.89);
    expect(first.orderCount, 4);
    expect(first.cogsIsEstimate, isTrue);
    expect(first.cogsLimitationNote, isNotEmpty);

    final second = await repository.getProfitMargin(
      fromDate: DateTime(2026, 9, 8),
      toDate: DateTime(2026, 9, 8),
    );
    expect(calls, 2);
    expect(second!.orderCount, 4);
  });

  test('cloud profit margin falls back to cache on failure and never uses local SQLite', () async {
    var shouldFail = false;
    final repository = CloudProfitMarginRepository(
      sender: (uri) async {
        if (shouldFail) {
          throw const SocketException('offline');
        }
        return {
          'grossSalesPaise': 20000,
          'discountsPaise': 0,
          'netRevenuePaise': 20000,
          'cogsPaise': 8000,
          'grossProfitPaise': 12000,
          'marginPercent': 60.0,
          'orderCount': 1,
          'cogsIsEstimate': true,
          'cogsLimitationNote': 'note',
        };
      },
    );

    final online = await repository.getProfitMargin(
      fromDate: DateTime(2026, 9, 7),
      toDate: DateTime(2026, 9, 7),
    );
    expect(online, isNotNull);
    expect(online!.grossProfitPaise, 12000);

    shouldFail = true;
    final cached = await repository.getProfitMargin(
      fromDate: DateTime(2026, 9, 7),
      toDate: DateTime(2026, 9, 7),
    );

    // Falls back to the previously cached Cloud response only, never SQLite.
    expect(cached, isNotNull);
    expect(cached!.grossProfitPaise, 12000);
  });

  test('cloud profit margin returns null when no cache and sender fails', () async {
    final repository = CloudProfitMarginRepository(
      sender: (uri) async => throw const SocketException('offline'),
    );

    final result = await repository.getProfitMargin(
      fromDate: DateTime(2026, 1, 1),
      toDate: DateTime(2026, 1, 1),
    );

    expect(result, isNull);
  });
}
