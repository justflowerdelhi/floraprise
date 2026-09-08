import 'package:floraprise/data/repositories/cloud_finance_repository.dart';
import 'package:floraprise/models/expense.dart';
import 'package:floraprise/models/expense_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const locationId = '11111111-1111-4111-8111-111111111111';
  final date = DateTime.utc(2026, 9, 8);

  test('Cloud cash expense posts to accounting expenses with cash payment mode', () async {
    final requests = <({String method, Uri uri, Map<String, dynamic>? body})>[];
    final repository = CloudExpenseRepository(
      sender: (method, uri, {body}) async {
        requests.add((method: method, uri: uri, body: body));
        return <String, dynamic>{};
      },
    );

    await repository.create(
      category: ExpenseCategory(id: -1, name: 'Petrol', emoji: 'P', groupName: 'Delivery', active: true, createdAt: date, updatedAt: date),
      amountPaise: 12500,
      paymentMode: PaymentMode.cash,
      notes: 'Route fuel',
      date: date,
    );

    expect(requests.single.method, 'POST');
    expect(requests.single.uri.path, '/api/accounting/expenses');
    expect(requests.single.body?['paymentMode'], 'cash');
    expect(requests.single.body?['amount'], 125);
  });

  test('Cloud expense categories fall back to active standard choices when none are configured', () async {
    final repository = CloudExpenseRepository(
      sender: (method, uri, {body}) async => <Map<String, dynamic>>[],
    );

    final categories = await repository.getCategories();

    expect(categories, hasLength(12));
    expect(categories.every((category) => category.active), isTrue);
    expect(categories.map((category) => category.name), containsAll(['Purchase', 'Fuel', 'Miscellaneous']));
  });

  test('Cloud Day Close reads summary and posts counted cash using Cloud location', () async {
    final requests = <({String method, Uri uri, Map<String, dynamic>? body})>[];
    final repository = CloudDayCloseRepository(
      sender: (method, uri, {body}) async {
        requests.add((method: method, uri: uri, body: body));
        if (uri.path == '/api/locations') return [{'id': locationId}];
        if (method == 'GET') return {'openingCash': 100, 'cashSales': 500, 'cashExpenses': 50};
        return <String, dynamic>{};
      },
    );

    final summary = await repository.summary(date);
    await repository.close(date, 55000, 'Balanced');

    expect(summary['cashSales'], 500);
    expect(requests.map((request) => request.uri.path), [
      '/api/locations',
      '/api/day-close/summary',
      '/api/locations',
      '/api/day-close',
    ]);
    expect(requests.last.body?['actualCash'], 550);
  });
}