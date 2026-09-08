import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/data/repositories/cloud_customer_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Cloud customer statistics parses the server response and caches it', () async {
    var calls = 0;
    final repo = CloudCustomerRepository(
      sender: (method, uri, {body}) async {
        calls++;
        expect(method, 'GET');
        expect(
          uri.path,
          '/api/v1/mobile/customers/cloud-customer-1/statistics',
        );
        return {
          'customerId': 'cloud-customer-1',
          'totalOrders': 3,
          'lastOrderAt': '2026-09-08T12:30:00Z',
          'lifetimePurchasePaise': 12345,
          'pendingPaymentPaise': 2345,
        };
      },
    );

    final first = await repo.getStatistics(
      'cloud-customer-1',
      companyId: '11111111-1111-4111-8111-111111111111',
    );
    expect(calls, 1);
    expect(first, isNotNull);
    expect(first!.totalOrders, 3);
    expect(first.lastOrderAt, '2026-09-08T12:30:00Z');
    expect(first.lifetimePurchasePaise, 12345);
    expect(first.pendingPaymentPaise, 2345);

    final second = await repo.getStatistics(
      'cloud-customer-1',
      companyId: '11111111-1111-4111-8111-111111111111',
    );
    expect(calls, 2);
    expect(second!.totalOrders, 3);
  });

  test('Cloud customer statistics falls back to cache on API failure', () async {
    var shouldFail = false;
    final repo = CloudCustomerRepository(
      sender: (method, uri, {body}) async {
        if (shouldFail) {
          throw const CloudCustomerException('offline');
        }
        return {
          'customerId': 'cloud-customer-2',
          'totalOrders': 5,
          'lastOrderAt': '2026-09-07T09:15:00Z',
          'lifetimePurchasePaise': 77700,
          'pendingPaymentPaise': 0,
        };
      },
    );

    final online = await repo.getStatistics('cloud-customer-2');
    expect(online, isNotNull);
    expect(online!.totalOrders, 5);

    shouldFail = true;
    final offline = await repo.getStatistics('cloud-customer-2');
    expect(offline, isNotNull);
    expect(offline!.lifetimePurchasePaise, 77700);
    expect(offline.pendingPaymentPaise, 0);
  });
}
