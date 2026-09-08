import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/data/repositories/cloud_dashboard_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('pending payments summary parses the response and caches it', () async {
    var calls = 0;
    final repository = CloudDashboardRepository(
      pendingPaymentsSender: (uri) async {
        calls++;
        expect(uri.path, '/api/v1/mobile/payments/pending');
        return {
          'pendingOrderCount': 2,
          'pendingPaymentPaise': 5500,
        };
      },
    );

    final first = await repository.getPendingPayments(
      asOf: DateTime(2026, 9, 8),
    );
    expect(calls, 1);
    expect(first, isNotNull);
    expect(first!.pendingOrderCount, 2);
    expect(first.pendingPaymentPaise, 5500);

    final second = await repository.getPendingPayments(
      asOf: DateTime(2026, 9, 8),
    );
    expect(calls, 2);
    expect(second!.pendingOrderCount, 2);
  });

  test('pending payments summary falls back to cache on failure', () async {
    var shouldFail = false;
    final repository = CloudDashboardRepository(
      pendingPaymentsSender: (uri) async {
        if (shouldFail) {
          throw const SocketException('offline');
        }
        return {
          'pendingOrderCount': 1,
          'pendingPaymentPaise': 2500,
        };
      },
    );

    final online = await repository.getPendingPayments(
      asOf: DateTime(2026, 9, 7),
    );
    expect(online, isNotNull);
    expect(online!.pendingPaymentPaise, 2500);

    shouldFail = true;
    final offline = await repository.getPendingPayments(
      asOf: DateTime(2026, 9, 7),
    );
    expect(offline, isNotNull);
    expect(offline!.pendingOrderCount, 1);
    expect(offline.pendingPaymentPaise, 2500);
  });

  test('pending payments summary returns zero values for an empty response', () async {
    final repository = CloudDashboardRepository(
      pendingPaymentsSender: (uri) async => {
        'pendingOrderCount': 0,
        'pendingPaymentPaise': 0,
      },
    );

    final summary = await repository.getPendingPayments(
      asOf: DateTime(2026, 9, 10),
    );

    expect(summary, isNotNull);
    expect(summary!.pendingOrderCount, 0);
    expect(summary.pendingPaymentPaise, 0);
  });
}
