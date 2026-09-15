import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/data/repositories/cloud_top_customers_repository.dart';

void main() {
  test('cloud top customers sends date range and parses ranking metrics',
      () async {
    final repository = CloudTopCustomersRepository(
      sender: (uri) async {
        expect(uri.path, '/api/accounting/top-customers');
        expect(uri.queryParameters['from'], '2026-09-08');
        expect(uri.queryParameters['to'], '2026-09-10');
        expect(uri.queryParameters['limit'], '10');
        return [
          {
            'customerId': 'a761c55c-2479-47eb-9aac-c5c910ba7306',
            'customerName': 'Anita',
            'totalAmount': 1250.75,
            'orderCount': 4,
          },
          {
            'customerId': '2542ed65-511b-435f-a2bb-57e256209aaa',
            'customerName': 'Bina',
            'totalAmount': 800,
            'orderCount': 2,
          },
        ];
      },
    );

    final customers = await repository.getTopCustomers(
      fromDate: DateTime(2026, 9, 8),
      toDate: DateTime(2026, 9, 10),
    );

    expect(customers.map((customer) => customer.customerName), ['Anita', 'Bina']);
    expect(customers.first.totalPaise, 125075);
    expect(customers.first.orderCount, 4);
  });

  test('cloud top customers accepts backend PascalCase contract', () async {
    final repository = CloudTopCustomersRepository(
      sender: (_) async => [
        {
          'CustomerId': '3dd79b71-84c3-4c02-b903-b379df3d6274',
          'CustomerName': 'Chitra',
          'TotalAmount': '45.50',
          'OrderCount': 1,
        },
      ],
    );

    final customers = await repository.getTopCustomers(
      fromDate: DateTime(2026, 9, 10),
      toDate: DateTime(2026, 9, 10),
    );

    expect(customers.single.customerName, 'Chitra');
    expect(customers.single.totalPaise, 4550);
  });

  test('cloud top customers returns empty on failure without SQLite fallback',
      () async {
    final repository = CloudTopCustomersRepository(
      sender: (_) async => throw const SocketException('offline'),
    );

    final customers = await repository.getTopCustomers(
      fromDate: DateTime(2026, 9, 10),
      toDate: DateTime(2026, 9, 10),
    );

    expect(customers, isEmpty);
  });
}