import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/data/repositories/day_closing_repository.dart';
import 'package:floraprise/data/repositories/order_repository.dart';
import 'package:floraprise/models/day_closing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await AppDatabase.instance.close();
    final path = await getDatabasesPath();
    await deleteDatabase('$path/floraprise.db');
  });

  group('Stage 3 - Day Close & Sales Reporting Tests', () {
    test('Unclosed day calculates real-time sales breakdown and excludes cancelled orders', () async {
      final db = await AppDatabase.instance.database;
      final today = DateTime.now();
      final nowStr = today.toIso8601String();

      // Order 1: Split payment ₹1,000 total (₹600 cash, ₹400 credit)
      final o1 = await db.insert('orders', {
        'order_no': 'ORD-SPLIT-1',
        'fulfilment_type': 'take_away',
        'status': 'confirmed',
        'grand_total_paise': 100000,
        'created_at': nowStr,
        'updated_at': nowStr,
      });
      await db.insert('order_payments', {
        'order_id': o1,
        'method': 'cash',
        'amount_paise': 60000,
        'created_at': nowStr,
      });

      // Order 2: Full UPI payment ₹500
      final o2 = await db.insert('orders', {
        'order_no': 'ORD-UPI-2',
        'fulfilment_type': 'take_away',
        'status': 'delivered',
        'grand_total_paise': 50000,
        'created_at': nowStr,
        'updated_at': nowStr,
      });
      await db.insert('order_payments', {
        'order_id': o2,
        'method': 'upi',
        'amount_paise': 50000,
        'created_at': nowStr,
      });

      // Order 3: Cancelled order ₹800 (must be excluded)
      final o3 = await db.insert('orders', {
        'order_no': 'ORD-CANCELLED-3',
        'fulfilment_type': 'take_away',
        'status': 'cancelled',
        'grand_total_paise': 80000,
        'created_at': nowStr,
        'updated_at': nowStr,
      });
      await db.insert('order_payments', {
        'order_id': o3,
        'method': 'cash',
        'amount_paise': 80000,
        'created_at': nowStr,
      });

      final breakdown = await OrderRepository().getSalesBreakdown(
        startDate: today,
        endDate: today,
      );

      expect(breakdown.totalOrders, 2);
      expect(breakdown.grossSalesPaise, 150000);
      expect(breakdown.cashSalesPaise, 60000);
      expect(breakdown.upiSalesPaise, 50000);
      expect(breakdown.cardSalesPaise, 0);
      expect(breakdown.creditCreatedPaise, 40000);
      expect(breakdown.netSalesPaise, 150000);

      // Verify identity: Gross Sales == Cash + UPI + Card + Credit Created
      expect(
        breakdown.grossSalesPaise,
        breakdown.cashSalesPaise +
            breakdown.upiSalesPaise +
            breakdown.cardSalesPaise +
            breakdown.bankTransferSalesPaise +
            breakdown.otherSalesPaise +
            breakdown.creditCreatedPaise,
      );
    });

    test('Closed day retains frozen historical closing values', () async {
      final today = DateTime.now();
      final dayClosingRepo = DayClosingRepository();

      final historicalClosing = DayClosing(
        id: 0,
        date: today,
        cashSales: 60000,
        upiSales: 30000,
        cardSales: 10000,
        creditSales: 40000,
        cashExpenses: 5000,
        upiExpenses: 0,
        cardExpenses: 0,
        openingCash: 10000,
        expectedCash: 65000,
        countedCash: 65000,
        difference: 0,
        notes: 'End of day clean close',
        closedAt: today,
        createdAt: today,
      );

      await dayClosingRepo.create(historicalClosing);

      final retrieved = await dayClosingRepo.getByDate(today);

      expect(retrieved, isNotNull);
      expect(retrieved!.cashSales, 60000);
      expect(retrieved.upiSales, 30000);
      expect(retrieved.cardSales, 10000);
      expect(retrieved.creditSales, 40000);
      expect(retrieved.openingCash, 10000);
      expect(retrieved.expectedCash, 65000);
      expect(retrieved.countedCash, 65000);
      expect(retrieved.difference, 0);
      expect(retrieved.notes, 'End of day clean close');
    });

    test('Date range filtering in sales breakdown correctly segments orders across days', () async {
      final db = await AppDatabase.instance.database;
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayStr = yesterday.toIso8601String();
      final todayStr = now.toIso8601String();

      // Day 1 (Yesterday): ₹1,000 cash sale
      final o1 = await db.insert('orders', {
        'order_no': 'ORD-YEST-1',
        'fulfilment_type': 'take_away',
        'status': 'confirmed',
        'grand_total_paise': 100000,
        'created_at': yesterdayStr,
        'updated_at': yesterdayStr,
      });
      await db.insert('order_payments', {
        'order_id': o1,
        'method': 'cash',
        'amount_paise': 100000,
        'created_at': yesterdayStr,
      });

      // Day 2 (Today): ₹2,000 split sale (₹1,500 UPI, ₹500 credit)
      final o2 = await db.insert('orders', {
        'order_no': 'ORD-TODAY-2',
        'fulfilment_type': 'take_away',
        'status': 'confirmed',
        'grand_total_paise': 200000,
        'created_at': todayStr,
        'updated_at': todayStr,
      });
      await db.insert('order_payments', {
        'order_id': o2,
        'method': 'upi',
        'amount_paise': 150000,
        'created_at': todayStr,
      });

      final repo = OrderRepository();

      // Query only today
      final todayBreakdown = await repo.getSalesBreakdown(
        startDate: now,
        endDate: now,
      );
      expect(todayBreakdown.totalOrders, 1);
      expect(todayBreakdown.grossSalesPaise, 200000);
      expect(todayBreakdown.cashSalesPaise, 0);
      expect(todayBreakdown.upiSalesPaise, 150000);
      expect(todayBreakdown.creditCreatedPaise, 50000);

      // Query yesterday to today
      final combinedBreakdown = await repo.getSalesBreakdown(
        startDate: yesterday,
        endDate: now,
      );
      expect(combinedBreakdown.totalOrders, 2);
      expect(combinedBreakdown.grossSalesPaise, 300000);
      expect(combinedBreakdown.cashSalesPaise, 100000);
      expect(combinedBreakdown.upiSalesPaise, 150000);
      expect(combinedBreakdown.creditCreatedPaise, 50000);
    });

    test('Multi-tender split payment distributes accurately to cash, upi, card and credit created', () async {
      final db = await AppDatabase.instance.database;
      final now = DateTime.now();
      final nowStr = now.toIso8601String();

      // Grand Total: ₹1,000. Cash: ₹300, UPI: ₹200, Card: ₹200, Credit Created: ₹300
      final o = await db.insert('orders', {
        'order_no': 'ORD-MULTI-TENDER',
        'fulfilment_type': 'take_away',
        'status': 'confirmed',
        'grand_total_paise': 100000,
        'created_at': nowStr,
        'updated_at': nowStr,
      });
      await db.insert('order_payments', {
        'order_id': o,
        'method': 'cash',
        'amount_paise': 30000,
        'created_at': nowStr,
      });
      await db.insert('order_payments', {
        'order_id': o,
        'method': 'upi',
        'amount_paise': 20000,
        'created_at': nowStr,
      });
      await db.insert('order_payments', {
        'order_id': o,
        'method': 'card',
        'amount_paise': 20000,
        'created_at': nowStr,
      });

      final breakdown = await OrderRepository().getSalesBreakdown(
        startDate: now,
        endDate: now,
      );

      expect(breakdown.totalOrders, 1);
      expect(breakdown.grossSalesPaise, 100000);
      expect(breakdown.cashSalesPaise, 30000);
      expect(breakdown.upiSalesPaise, 20000);
      expect(breakdown.cardSalesPaise, 20000);
      expect(breakdown.creditCreatedPaise, 30000);
      expect(breakdown.netSalesPaise, 100000);
    });

    test('Pure credit sale records gross sales and 100% credit created with 0 cash/upi/card', () async {
      final db = await AppDatabase.instance.database;
      final today = DateTime.now();
      final nowStr = today.toIso8601String();

      // Order: ₹1,200 on pure credit (no payment rows)
      await db.insert('orders', {
        'order_no': 'ORD-PURE-CREDIT',
        'fulfilment_type': 'take_away',
        'status': 'confirmed',
        'grand_total_paise': 120000,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      final breakdown = await OrderRepository().getSalesBreakdown(
        startDate: today,
        endDate: today,
      );

      expect(breakdown.totalOrders, 1);
      expect(breakdown.grossSalesPaise, 120000);
      expect(breakdown.cashSalesPaise, 0);
      expect(breakdown.upiSalesPaise, 0);
      expect(breakdown.cardSalesPaise, 0);
      expect(breakdown.creditCreatedPaise, 120000);
      expect(breakdown.totalCollectionsPaise, 0);
    });

    test('Mandatory Same-Day Collection (Test 4): credit collection does not mutate gross sales or credit created', () async {
      final db = await AppDatabase.instance.database;
      final today = DateTime.now();
      final morningStr = DateTime(today.year, today.month, today.day, 10, 0).toIso8601String();
      final afternoonStr = DateTime(today.year, today.month, today.day, 16, 0).toIso8601String();

      // Morning 10:00 AM: Order ₹1,000 (₹600 cash tender, ₹400 credit)
      final o = await db.insert('orders', {
        'order_no': 'ORD-SAMEDAY-1',
        'fulfilment_type': 'take_away',
        'status': 'confirmed',
        'grand_total_paise': 100000,
        'created_at': morningStr,
        'updated_at': morningStr,
      });
      await db.insert('order_payments', {
        'order_id': o,
        'method': 'cash',
        'amount_paise': 60000,
        'payment_type': 'SaleTender',
        'created_at': morningStr,
      });

      // Afternoon 4:00 PM: Customer pays ₹200 towards credit
      await db.insert('order_payments', {
        'order_id': o,
        'method': 'cash',
        'amount_paise': 20000,
        'payment_type': 'CreditCollection',
        'created_at': afternoonStr,
      });

      final breakdown = await OrderRepository().getSalesBreakdown(
        startDate: today,
        endDate: today,
      );

      expect(breakdown.totalOrders, 1);
      expect(breakdown.grossSalesPaise, 100000, reason: 'Gross Sales must remain ₹1,000');
      expect(breakdown.cashSalesPaise, 60000, reason: 'Cash Sales tender must remain ₹600');
      expect(breakdown.creditCreatedPaise, 40000, reason: 'Credit Created must remain ₹400');
      expect(breakdown.cashCollectionsPaise, 20000, reason: 'Cash Collections must be ₹200');
      expect(breakdown.totalCollectionsPaise, 20000);

      // Identity: Gross Sales == Cash Sales + UPI Sales + Card Sales + Bank + Other + Credit Created
      expect(
        breakdown.grossSalesPaise,
        breakdown.cashSalesPaise +
            breakdown.upiSalesPaise +
            breakdown.cardSalesPaise +
            breakdown.bankTransferSalesPaise +
            breakdown.otherSalesPaise +
            breakdown.creditCreatedPaise,
      );

      // Total Cash Inflow for the drawer: Cash Sales + Cash Collections = ₹800
      final totalCashInflow = breakdown.cashSalesPaise + breakdown.cashCollectionsPaise;
      expect(totalCashInflow, 80000);
    });

    test('Subsequent day credit collection does not alter Day 1 sales or report Day 2 as sales', () async {
      final db = await AppDatabase.instance.database;
      final now = DateTime.now();
      final day1 = now.subtract(const Duration(days: 1));
      final day2 = now;
      final day1Str = day1.toIso8601String();
      final day2Str = day2.toIso8601String();

      // Day 1: Order ₹1,000 (₹600 cash tender, ₹400 credit created)
      final o = await db.insert('orders', {
        'order_no': 'ORD-DAY1-1',
        'fulfilment_type': 'take_away',
        'status': 'confirmed',
        'grand_total_paise': 100000,
        'created_at': day1Str,
        'updated_at': day1Str,
      });
      await db.insert('order_payments', {
        'order_id': o,
        'method': 'cash',
        'amount_paise': 60000,
        'payment_type': 'SaleTender',
        'created_at': day1Str,
      });

      // Day 2: Customer pays ₹200 towards credit
      await db.insert('order_payments', {
        'order_id': o,
        'method': 'cash',
        'amount_paise': 20000,
        'payment_type': 'CreditCollection',
        'created_at': day2Str,
      });

      final repo = OrderRepository();

      // Day 1 Report
      final day1Breakdown = await repo.getSalesBreakdown(
        startDate: day1,
        endDate: day1,
      );
      expect(day1Breakdown.totalOrders, 1);
      expect(day1Breakdown.grossSalesPaise, 100000);
      expect(day1Breakdown.cashSalesPaise, 60000);
      expect(day1Breakdown.creditCreatedPaise, 40000);
      expect(day1Breakdown.cashCollectionsPaise, 0);

      // Day 2 Report
      final day2Breakdown = await repo.getSalesBreakdown(
        startDate: day2,
        endDate: day2,
      );
      expect(day2Breakdown.totalOrders, 0);
      expect(day2Breakdown.grossSalesPaise, 0);
      expect(day2Breakdown.cashSalesPaise, 0);
      expect(day2Breakdown.creditCreatedPaise, 0);
      expect(day2Breakdown.cashCollectionsPaise, 20000);
      expect(day2Breakdown.totalCollectionsPaise, 20000);
    });
  });
}
