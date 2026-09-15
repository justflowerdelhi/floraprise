import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/data/repositories/cloud_expense_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cloud expense summary parses response and caches it', () async {
    var calls = 0;
    final repository = CloudExpenseRepository(
      sender: (uri) async {
        calls++;
        expect(uri.path, '/api/accounting/expense-summary');
        expect(uri.queryParameters['from'], isNotNull);
        expect(uri.queryParameters['to'], isNotNull);
        return {
          'totalAmount': 175.0,
          'cashAmount': 100.0,
          'upiAmount': 50.0,
          'cardAmount': 25.0,
          'expenseCount': 3,
        };
      },
    );

    final first = await repository.getExpenseSummary(
      fromDate: DateTime(2026, 9, 8),
      toDate: DateTime(2026, 9, 8),
    );

    expect(calls, 1);
    expect(first, isNotNull);
    expect(first!.totalPaise, 17500);
    expect(first.cashPaise, 10000);
    expect(first.upiPaise, 5000);
    expect(first.cardPaise, 2500);
    expect(first.expenseCount, 3);

    final second = await repository.getExpenseSummary(
      fromDate: DateTime(2026, 9, 8),
      toDate: DateTime(2026, 9, 8),
    );
    expect(calls, 2);
    expect(second!.expenseCount, 3);
  });

  test('cloud expense summary falls back to cache on failure, never SQLite', () async {
    var shouldFail = false;
    final repository = CloudExpenseRepository(
      sender: (uri) async {
        if (shouldFail) {
          throw const SocketException('offline');
        }
        return {
          'totalAmount': 40.0,
          'cashAmount': 40.0,
          'upiAmount': 0.0,
          'cardAmount': 0.0,
          'expenseCount': 1,
        };
      },
    );

    final online = await repository.getExpenseSummary(
      fromDate: DateTime(2026, 9, 7),
      toDate: DateTime(2026, 9, 7),
    );
    expect(online, isNotNull);
    expect(online!.totalPaise, 4000);

    shouldFail = true;
    final cached = await repository.getExpenseSummary(
      fromDate: DateTime(2026, 9, 7),
      toDate: DateTime(2026, 9, 7),
    );

    expect(cached, isNotNull);
    expect(cached!.totalPaise, 4000);
  });

  test('cloud expense summary returns null when no cache and sender fails', () async {
    final repository = CloudExpenseRepository(
      sender: (uri) async => throw const SocketException('offline'),
    );

    final result = await repository.getExpenseSummary(
      fromDate: DateTime(2026, 1, 1),
      toDate: DateTime(2026, 1, 1),
    );

    expect(result, isNull);
  });
}
