import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/data/repositories/cash_book_repository.dart';
import 'package:floraprise/data/repositories/order_repository.dart';
import 'package:floraprise/models/cash_book.dart';
import 'package:floraprise/screens/cash_book_screen.dart';
import 'package:floraprise/screens/day_closing_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final _selectedDate = DateTime(2026, 9, 6);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await AppDatabase.instance.close();
    AppDatabase.useInMemoryForTests = true;
  });

  tearDown(() async {
    await AppDatabase.instance.close();
    AppDatabase.useInMemoryForTests = false;
  });

  test('online Cash Book uses Cloud data', () async {
    final localRepository = _FakeCashBookRepository([
      _cashBook(
        description: 'Local cash sale should not show',
        transactionType: CashBookTransactionType.cashSale,
        amount: 99900,
        cashIn: 99900,
      ),
    ]);
    final calls = <Uri>[];
    final cloudRepository = CloudCashBookRepository(
      sender: (method, uri) async {
        calls.add(uri);
        expect(method, 'GET');
        return [_cloudCashSale(description: 'Cloud POS cash sale')];
      },
    );

    final transactions = await loadCashBookTransactionsForMode(
      isCloud: true,
      date: _selectedDate,
      localRepository: localRepository,
      cloudRepository: cloudRepository,
    );

    expect(localRepository.called, isFalse);
    expect(calls, hasLength(1));
    expect(calls.single.path, '/api/accounting/cash-book');
    expect(calls.single.queryParameters['date'], '2026-09-06T00:00:00.000Z');
    expect(transactions, hasLength(1));
    expect(transactions.single.description, 'Cloud POS cash sale');
    expect(transactions.single.amount, 30000);
    expect(transactions.single.cashIn, 30000);
  });

  test('local Storage Cash Book still uses SQLite', () async {
    final cloudRepository = CloudCashBookRepository(
      sender: (method, uri) async {
        throw StateError('Cloud repository should not be called in local mode.');
      },
    );
    await CashBookRepository().create(
      date: _selectedDate,
      transactionType: CashBookTransactionType.cashSale,
      description: 'Local POS cash sale',
      amount: 30000,
      cashIn: 30000,
      cashOut: 0,
    );

    final transactions = await loadCashBookTransactionsForMode(
      isCloud: false,
      date: _selectedDate,
      localRepository: CashBookRepository(),
      cloudRepository: cloudRepository,
    );

    expect(transactions, hasLength(1));
    expect(transactions.single.description, 'Local POS cash sale');
    expect(transactions.single.transactionType, CashBookTransactionType.cashSale);
    expect(transactions.single.cashIn, 30000);
  });

  test('online cash sale appears in Cash Book data', () async {
    final cloudRepository = CloudCashBookRepository(
      sender: (method, uri) async {
        return [_cloudCashSale(description: 'POS cash sale ORD-POS-300')];
      },
    );

    final transactions = await loadCashBookTransactionsForMode(
      isCloud: true,
      date: _selectedDate,
      localRepository: _FakeCashBookRepository(const []),
      cloudRepository: cloudRepository,
    );

    expect(transactions.single.description, 'POS cash sale ORD-POS-300');
    expect(transactions.single.transactionType, CashBookTransactionType.cashSale);
    expect(transactions.single.amount, 30000);
    expect(transactions.single.cashIn, 30000);
    expect(transactions.single.cashOut, 0);
  });

  test('existing local cash expense behavior is preserved', () async {
    final cloudRepository = CloudCashBookRepository(
      sender: (method, uri) async {
        throw StateError('Cloud repository should not be called in local mode.');
      },
    );
    await CashBookRepository().create(
      date: _selectedDate,
      transactionType: CashBookTransactionType.cashExpense,
      description: 'Petrol expense',
      amount: 10000,
      cashIn: 0,
      cashOut: 10000,
    );

    final transactions = await loadCashBookTransactionsForMode(
      isCloud: false,
      date: _selectedDate,
      localRepository: CashBookRepository(),
      cloudRepository: cloudRepository,
    );

    expect(transactions, hasLength(1));
    expect(transactions.single.description, 'Petrol expense');
    expect(
      transactions.single.transactionType,
      CashBookTransactionType.cashExpense,
    );
    expect(transactions.single.cashOut, 10000);
  });

  test('online Day Close uses Cloud cash-book data', () {
    final totals = dayCloseCashBookTotalsFromTransactions(
      [
        _cashBook(
          description: 'POS cash sale ORD-POS-300',
          transactionType: CashBookTransactionType.cashSale,
          amount: 30000,
          cashIn: 30000,
        ),
        _cashBook(
          description: 'Cash expense',
          transactionType: CashBookTransactionType.cashExpense,
          amount: 10000,
          cashOut: 10000,
        ),
      ],
      includeCashSales: true,
      includeCashExpenses: true,
    );

    expect(totals.cashSales, 30000);
    expect(totals.cashExpenses, 10000);
  });

  test('finalizeCloudConfirmedDraft keeps local Cash Book parity for cash sales', () async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    final orderId = await db.insert('orders', {
      'order_no': 'DRAFT-123',
      'fulfilment_type': 'take_away',
      'status': 'draft',
      'grand_total_paise': 50000,
      'is_paid': 1,
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('order_payments', {
      'order_id': orderId,
      'method': 'cash',
      'amount_paise': 50000,
      'created_at': now,
    });

    final repo = OrderRepository();
    await repo.finalizeCloudConfirmedDraft(
      orderId: orderId,
      orderNo: 'ORD-CF-123',
      cloudOrderId: 'cloud-uuid-123',
    );

    final cashEntries = await db.query(
      'cash_book',
      where: 'description = ?',
      whereArgs: ['POS cash sale ORD-CF-123'],
    );
    expect(cashEntries, hasLength(1));
    expect(cashEntries.single['amount'], 50000);
    expect(cashEntries.single['cash_in'], 50000);
    expect(cashEntries.single['transaction_type'], 'cashSale');

    // Idempotency check: running again does not duplicate
    await repo.finalizeCloudConfirmedDraft(
      orderId: orderId,
      orderNo: 'ORD-CF-123',
      cloudOrderId: 'cloud-uuid-123',
    ).catchError((_) => const ConfirmedOrder(orderId: 0, lineProductLinks: []));

    final cashEntriesAfter = await db.query(
      'cash_book',
      where: 'description = ?',
      whereArgs: ['POS cash sale ORD-CF-123'],
    );
    expect(cashEntriesAfter, hasLength(1));
  });

  test('finalizeCloudConfirmedDraft does not create local Cash Book entry for non-cash', () async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    final orderId = await db.insert('orders', {
      'order_no': 'DRAFT-UPI',
      'fulfilment_type': 'take_away',
      'status': 'draft',
      'grand_total_paise': 40000,
      'is_paid': 1,
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('order_payments', {
      'order_id': orderId,
      'method': 'upi',
      'amount_paise': 40000,
      'created_at': now,
    });

    final repo = OrderRepository();
    await repo.finalizeCloudConfirmedDraft(
      orderId: orderId,
      orderNo: 'ORD-CF-UPI',
      cloudOrderId: 'cloud-uuid-upi',
    );

    final cashEntries = await db.query('cash_book');
    expect(cashEntries, isEmpty);
  });
}

class _FakeCashBookRepository extends CashBookRepository {
  _FakeCashBookRepository(this._rows);

  final List<CashBook> _rows;
  bool called = false;

  @override
  Future<List<CashBook>> getByDate(DateTime date) async {
    called = true;
    return _rows;
  }
}

CashBook _cashBook({
  required String description,
  required CashBookTransactionType transactionType,
  required int amount,
  int cashIn = 0,
  int cashOut = 0,
}) {
  return CashBook(
    id: 1,
    date: _selectedDate,
    transactionType: transactionType,
    description: description,
    amount: amount,
    cashIn: cashIn,
    cashOut: cashOut,
    runningBalance: cashIn - cashOut,
    createdAt: _selectedDate,
  );
}

Map<String, dynamic> _cloudCashSale({required String description}) {
  return {
    'id': 'cloud-cash-book-id',
    'date': '2026-09-06',
    'transactionType': 'CashSale',
    'description': description,
    'amount': 300,
    'cashIn': 300,
    'cashOut': 0,
    'runningBalance': 300,
    'createdAtUtc': '2026-09-06T10:00:00Z',
  };
}