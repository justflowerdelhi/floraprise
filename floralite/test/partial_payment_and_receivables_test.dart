import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/data/repositories/cash_book_repository.dart';
import 'package:floraprise/data/repositories/customer_repository.dart';
import 'package:floraprise/data/repositories/order_repository.dart';
import 'package:floraprise/data/repositories/scheduler_repository.dart';
import 'package:floraprise/models/cash_book.dart';
import 'package:floraprise/models/scheduler_task.dart';
import 'package:floraprise/screens/day_closing_screen.dart';
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

  group('Phase 1: Partial Payment, Customer Outstanding, Cash Book & Receivables Tests', () {
    test('A. Solo unpaid customer outstanding: ₹10,000 order with ₹0 paid reports ₹10,000 pending', () async {
      final db = await AppDatabase.instance.database;
      final nowStr = DateTime.now().toIso8601String();

      final customerId = await db.insert('customers', {
        'name': 'Rahul Sharma',
        'phone': '9876543210',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await db.insert('orders', {
        'order_no': 'ORD-UNPAID-1',
        'fulfilment_type': 'take_away',
        'status': 'confirmed',
        'customer_id': customerId,
        'grand_total_paise': 1000000, // ₹10,000
        'is_paid': 0,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      final customer = await CustomerRepository().getById(customerId);
      expect(customer, isNotNull);
      expect(customer!.pendingPaymentPaise, 1000000); // Exactly ₹10,000
    });

    test('B. Solo partial customer outstanding: ₹10,000 order with ₹3,000 paid reports ₹7,000 pending (NOT ₹10,000)', () async {
      final db = await AppDatabase.instance.database;
      final nowStr = DateTime.now().toIso8601String();

      final customerId = await db.insert('customers', {
        'name': 'Ananya Verma',
        'phone': '9876543211',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      final orderId = await db.insert('orders', {
        'order_no': 'ORD-PARTIAL-1',
        'fulfilment_type': 'take_away',
        'status': 'confirmed',
        'customer_id': customerId,
        'grand_total_paise': 1000000, // ₹10,000
        'is_paid': 0,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      // Partial payment ₹3,000 (300,000 paise)
      await db.insert('order_payments', {
        'order_id': orderId,
        'method': 'upi',
        'amount_paise': 300000,
        'payment_type': 'SaleTender',
        'created_at': nowStr,
      });

      final customer = await CustomerRepository().getById(customerId);
      expect(customer, isNotNull);
      // Outstanding must be ₹7,000 (700,000 paise), proving Bug 1 is fixed
      expect(customer!.pendingPaymentPaise, 700000);
    });

    test('C. Solo full payment: ₹10,000 order with ₹10,000 paid reports ₹0 pending', () async {
      final db = await AppDatabase.instance.database;
      final nowStr = DateTime.now().toIso8601String();

      final customerId = await db.insert('customers', {
        'name': 'Kavita Patel',
        'phone': '9876543212',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      final orderId = await db.insert('orders', {
        'order_no': 'ORD-FULL-1',
        'fulfilment_type': 'take_away',
        'status': 'confirmed',
        'customer_id': customerId,
        'grand_total_paise': 1000000,
        'is_paid': 1,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await db.insert('order_payments', {
        'order_id': orderId,
        'method': 'upi',
        'amount_paise': 1000000,
        'payment_type': 'SaleTender',
        'created_at': nowStr,
      });

      final customer = await CustomerRepository().getById(customerId);
      expect(customer, isNotNull);
      expect(customer!.pendingPaymentPaise, 0);
    });

    test('D. Solo cash CreditCollection writes exactly one cashReceived entry to cash_book', () async {
      final db = await AppDatabase.instance.database;
      final nowStr = DateTime.now().toIso8601String();

      final orderId = await db.insert('orders', {
        'order_no': 'ORD-COLLECT-CASH',
        'fulfilment_type': 'take_away',
        'status': 'confirmed',
        'grand_total_paise': 1000000, // ₹10,000
        'is_paid': 0,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      final orderRepo = OrderRepository();
      await orderRepo.addOrderPaymentTransaction(
        orderId: orderId,
        method: 'cash',
        amountPaise: 700000, // ₹7,000 cash collection
        actor: 'testActor',
        note: 'Customer paid remaining balance in cash',
      );

      final payments = await db.query(
        'order_payments',
        where: 'order_id = ?',
        whereArgs: [orderId],
      );
      expect(payments.length, 1);
      expect(payments.first['payment_type'], 'CreditCollection');
      expect(payments.first['amount_paise'], 700000);

      // Verify cash_book has exactly 1 cashReceived entry on today's date
      final cashEntries = await CashBookRepository().getByDate(DateTime.now());
      expect(cashEntries.length, 1);
      expect(cashEntries.first.transactionType, CashBookTransactionType.cashReceived);
      expect(cashEntries.first.amount, 700000);
      expect(cashEntries.first.cashIn, 700000);
      expect(cashEntries.first.description, contains('ORD-COLLECT-CASH'));
    });

    test('E. Solo UPI CreditCollection does NOT create a cash_book CASH entry', () async {
      final db = await AppDatabase.instance.database;
      final nowStr = DateTime.now().toIso8601String();

      final orderId = await db.insert('orders', {
        'order_no': 'ORD-COLLECT-UPI',
        'fulfilment_type': 'take_away',
        'status': 'confirmed',
        'grand_total_paise': 1000000,
        'is_paid': 0,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      final orderRepo = OrderRepository();
      await orderRepo.addOrderPaymentTransaction(
        orderId: orderId,
        method: 'upi',
        amountPaise: 700000,
        actor: 'testActor',
      );

      final cashEntries = await CashBookRepository().getByDate(DateTime.now());
      expect(cashEntries.isEmpty, isTrue);
    });

    test('F. Collection Date: Old order from 10 days ago collected today records in today cash_book & Day Close', () async {
      final db = await AppDatabase.instance.database;
      final tenDaysAgo = DateTime.now().subtract(const Duration(days: 10));
      final tenDaysAgoStr = tenDaysAgo.toIso8601String();

      final orderId = await db.insert('orders', {
        'order_no': 'ORD-OLD-10D',
        'fulfilment_type': 'take_away',
        'status': 'confirmed',
        'grand_total_paise': 8000000, // ₹80,000
        'is_paid': 0,
        'created_at': tenDaysAgoStr,
        'updated_at': tenDaysAgoStr,
      });

      // Initial advance on order date: ₹30,000
      await db.insert('order_payments', {
        'order_id': orderId,
        'method': 'cash',
        'amount_paise': 3000000,
        'payment_type': 'SaleTender',
        'created_at': tenDaysAgoStr,
      });

      // Collection today: ₹50,000 cash
      final orderRepo = OrderRepository();
      await orderRepo.addOrderPaymentTransaction(
        orderId: orderId,
        method: 'cash',
        amountPaise: 5000000,
        actor: 'testActor',
      );

      // Verify today's cash book has ₹50,000 collection
      final todayCashEntries = await CashBookRepository().getByDate(DateTime.now());
      expect(todayCashEntries.length, 1);
      expect(todayCashEntries.first.amount, 5000000);

      // Verify 10 days ago cash book does NOT have today's collection
      final oldCashEntries = await CashBookRepository().getByDate(tenDaysAgo);
      expect(oldCashEntries.isEmpty, isTrue);

      // Verify today's SalesBreakdown shows cashCollectionsPaise = ₹50,000
      final today = DateTime.now();
      final breakdown = await orderRepo.getSalesBreakdown(
        startDate: today,
        endDate: today,
      );
      expect(breakdown.cashCollectionsPaise, 5000000);
      expect(breakdown.cashSalesPaise, 0); // Not a new sale today
    });

    test('G. Multiple partial payments: ₹10,000 order paid in 3 instalments becomes fully paid', () async {
      final db = await AppDatabase.instance.database;
      final nowStr = DateTime.now().toIso8601String();

      final orderId = await db.insert('orders', {
        'order_no': 'ORD-MULTI-3',
        'fulfilment_type': 'take_away',
        'status': 'confirmed',
        'grand_total_paise': 1000000, // ₹10,000
        'is_paid': 0,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      final orderRepo = OrderRepository();

      // Payment 1: ₹3,000
      await orderRepo.addOrderPaymentTransaction(
        orderId: orderId,
        method: 'upi',
        amountPaise: 300000,
        actor: 'test',
      );
      var orderRow = (await db.query('orders', where: 'id = ?', whereArgs: [orderId])).first;
      expect(orderRow['is_paid'], 0);

      // Payment 2: ₹2,000
      await orderRepo.addOrderPaymentTransaction(
        orderId: orderId,
        method: 'cash',
        amountPaise: 200000,
        actor: 'test',
      );
      orderRow = (await db.query('orders', where: 'id = ?', whereArgs: [orderId])).first;
      expect(orderRow['is_paid'], 0);

      // Payment 3: ₹5,000 (final balance)
      await orderRepo.addOrderPaymentTransaction(
        orderId: orderId,
        method: 'upi',
        amountPaise: 500000,
        actor: 'test',
      );
      orderRow = (await db.query('orders', where: 'id = ?', whereArgs: [orderId])).first;
      expect(orderRow['is_paid'], 1); // Now fully paid!
    });

    test('H. Overpayment prevention: Attempting to collect amount <= 0 throws ArgumentError', () async {
      final db = await AppDatabase.instance.database;
      final nowStr = DateTime.now().toIso8601String();

      final orderId = await db.insert('orders', {
        'order_no': 'ORD-VALIDATE-1',
        'fulfilment_type': 'take_away',
        'status': 'confirmed',
        'grand_total_paise': 1000000,
        'is_paid': 0,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      final orderRepo = OrderRepository();
      expect(
        () => orderRepo.addOrderPaymentTransaction(
          orderId: orderId,
          method: 'cash',
          amountPaise: 0,
          actor: 'test',
        ),
        throwsArgumentError,
      );
      expect(
        () => orderRepo.addOrderPaymentTransaction(
          orderId: orderId,
          method: 'cash',
          amountPaise: -5000,
          actor: 'test',
        ),
        throwsArgumentError,
      );
    });

    test('I. Full payment automatically completes linked payment follow-up task', () async {
      final db = await AppDatabase.instance.database;
      final now = DateTime.now();
      final nowStr = now.toIso8601String();

      final orderId = await db.insert('orders', {
        'order_no': 'ORD-TASK-AUTOCOMPLETE',
        'fulfilment_type': 'take_away',
        'status': 'confirmed',
        'grand_total_paise': 500000, // ₹5,000
        'is_paid': 0,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      final schedulerRepo = SchedulerRepository();

      // Create linked payment follow-up task
      final followUpTaskId = await schedulerRepo.publishTask(
        SchedulerTask(
          title: 'Collect Pending Payment - ORD-TASK-AUTOCOMPLETE',
          type: TaskType.reminder,
          category: TaskCategory.sales,
          priority: TaskPriority.normal,
          status: TaskStatus.pending,
          scheduledAt: now.add(const Duration(days: 1)),
          linkedOrderId: orderId,
          producer: TaskProducer.orders,
          sourceRef: 'payment_followup:order_$orderId',
          notes: 'Collect ₹5,000',
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Create an unrelated task (must NOT be touched)
      final unrelatedTaskId = await schedulerRepo.publishTask(
        SchedulerTask(
          title: 'Water plants in shop',
          type: TaskType.personalTask,
          category: TaskCategory.operational,
          priority: TaskPriority.normal,
          status: TaskStatus.pending,
          scheduledAt: now.add(const Duration(days: 1)),
          producer: TaskProducer.manual,
          sourceRef: 'manual_task_99',
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Verify both tasks are pending initially
      var followUpTask = await schedulerRepo.getTask(followUpTaskId);
      var unrelatedTask = await schedulerRepo.getTask(unrelatedTaskId);
      expect(followUpTask?.status, TaskStatus.pending);
      expect(unrelatedTask?.status, TaskStatus.pending);

      // Collect the full ₹5,000 payment
      final orderRepo = OrderRepository();
      await orderRepo.addOrderPaymentTransaction(
        orderId: orderId,
        method: 'cash',
        amountPaise: 500000,
        actor: 'test',
      );

      // Trigger automatic completion of linked payment follow-up task
      final sourceRef = 'payment_followup:order_$orderId';
      final taskRows = await db.query(
        'scheduler_tasks',
        columns: ['id'],
        where: 'source_ref = ? AND status IN (?, ?, ?) AND deleted_at IS NULL',
        whereArgs: [sourceRef, 'pending', 'inProgress', 'deferred'],
      );
      for (final r in taskRows) {
        final id = r['id'] as int;
        await schedulerRepo.updateTaskStatus(id, TaskStatus.completed);
      }

      // Verify follow-up task is marked completed and remains in history
      followUpTask = await schedulerRepo.getTask(followUpTaskId);
      expect(followUpTask?.status, TaskStatus.completed);

      // Verify unrelated task remains untouched
      unrelatedTask = await schedulerRepo.getTask(unrelatedTaskId);
      expect(unrelatedTask?.status, TaskStatus.pending);
    });

    test('J. Day Close totals function correctly excludes order collections from ad-hoc cashReceived', () {
      final transactions = [
        CashBook(
          id: 1,
          date: DateTime.now(),
          transactionType: CashBookTransactionType.cashSale,
          description: 'POS cash sale ORD-100',
          amount: 30000,
          cashIn: 30000,
          cashOut: 0,
          runningBalance: 30000,
          createdAt: DateTime.now(),
        ),
        CashBook(
          id: 2,
          date: DateTime.now(),
          transactionType: CashBookTransactionType.cashReceived,
          description: 'Payment collection for order ORD-101',
          amount: 20000,
          cashIn: 20000,
          cashOut: 0,
          runningBalance: 50000,
          createdAt: DateTime.now(),
        ),
        CashBook(
          id: 3,
          date: DateTime.now(),
          transactionType: CashBookTransactionType.cashReceived,
          description: 'Owner cash infusion',
          amount: 10000,
          cashIn: 10000,
          cashOut: 0,
          runningBalance: 60000,
          createdAt: DateTime.now(),
        ),
      ];

      final totals = dayCloseCashBookTotalsFromTransactions(
        transactions,
        includeCashSales: false,
        includeCashExpenses: false,
        includeCashCollections: false,
      );

      // Order collection (₹20,000) is excluded because sales breakdown counts it,
      // while owner infusion (₹10,000) is included as ad-hoc cashReceived.
      expect(totals.cashReceived, 10000);
      expect(totals.cashSales, 0);
    });

    test('K. Delivery order with partial payment (₹1,000 total, ₹170 paid, ₹830 pending) appears in Customer Outstanding and Receivables Report', () async {
      final custRepo = CustomerRepository();
      final db = await AppDatabase.instance.database;
      final nowStr = DateTime.now().toUtc().toIso8601String();

      // 1. Create customer 'ubaid' (Phone: 9574184092)
      final custId = await db.insert('customers', {
        'name': 'ubaid',
        'phone': '9574184092',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      // 2. Create Delivery order: Total ₹1,000 (100000 paise), Paid ₹170 (17000 paise), Pending ₹830 (83000 paise)
      final orderId = await db.insert('orders', {
        'order_no': 'ORD-DEL-UBAID',
        'customer_id': custId,
        'customer_name': 'ubaid',
        'customer_phone': '9574184092',
        'grand_total_paise': 100000,
        'fulfilment_type': 'delivery',
        'is_paid': 0,
        'status': 'confirmed',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      // Record advance payment of ₹170
      await db.insert('order_payments', {
        'order_id': orderId,
        'method': 'cash',
        'payment_type': 'SaleTender',
        'amount_paise': 17000,
        'created_at': nowStr,
      });

      // 3. Verify Customer Profile query: Pending Payment = ₹830 (83000 paise)
      final cust = await custRepo.getById(custId);
      expect(cust?.pendingPaymentPaise, 83000);

      // 4. Query Pending Payments SQLite dataset
      final pendingRows = await db.rawQuery('''
        SELECT
          o.id,
          o.order_no,
          o.customer_id,
          o.customer_name,
          o.customer_phone,
          o.fulfilment_type,
          o.created_at,
          o.scheduled_at,
          o.grand_total_paise,
          COALESCE((
            SELECT SUM(op.amount_paise)
            FROM order_payments op
            WHERE op.order_id = o.id
              AND LOWER(COALESCE(op.method, op.payment_type, '')) != 'credit'
          ), 0) AS paid_amount_paise
        FROM orders o
        WHERE o.status NOT IN ('draft', 'cancelled')
      ''');

      final pendingOrders = pendingRows.where((r) {
        final total = (r['grand_total_paise'] as int?) ?? 0;
        final paid = (r['paid_amount_paise'] as int?) ?? 0;
        return (total - paid) > 0;
      }).toList();

      expect(pendingOrders.length, 1);
      final item = pendingOrders.first;
      expect(item['order_no'], 'ORD-DEL-UBAID');
      expect(item['customer_name'], 'ubaid');
      expect(item['customer_phone'], '9574184092');
      expect(item['fulfilment_type'], 'delivery');
      expect(item['grand_total_paise'], 100000);
      expect(item['paid_amount_paise'], 17000);
      final outstanding = (item['grand_total_paise'] as int) - (item['paid_amount_paise'] as int);
      expect(outstanding, 83000);
    });

    test('L. Fulfilment types: Walk-in, Pickup, and Delivery with partial/unpaid balances all appear in Receivables Report', () async {
      final db = await AppDatabase.instance.database;
      final nowStr = DateTime.now().toUtc().toIso8601String();

      final cust1 = await db.insert('customers', {'name': 'Walkin Cust', 'phone': '9876543211', 'created_at': nowStr, 'updated_at': nowStr});
      final cust2 = await db.insert('customers', {'name': 'Pickup Cust', 'phone': '9876543212', 'created_at': nowStr, 'updated_at': nowStr});
      final cust3 = await db.insert('customers', {'name': 'Delivery Cust', 'phone': '9876543213', 'created_at': nowStr, 'updated_at': nowStr});
      final custPaid = await db.insert('customers', {'name': 'Paid Cust', 'phone': '9876543214', 'created_at': nowStr, 'updated_at': nowStr});

      // 1. Walk-in order: ₹10,000, Paid ₹5,000, Outstanding ₹5,000
      final ord1 = await db.insert('orders', {
        'order_no': 'ORD-WALK',
        'customer_id': cust1,
        'customer_name': 'Walkin Cust',
        'customer_phone': '9876543211',
        'grand_total_paise': 1000000,
        'fulfilment_type': 'take_away',
        'is_paid': 0,
        'status': 'confirmed',
        'created_at': nowStr,
        'updated_at': nowStr,
      });
      await db.insert('order_payments', {
        'order_id': ord1,
        'method': 'upi',
        'payment_type': 'SaleTender',
        'amount_paise': 500000,
        'created_at': nowStr,
      });

      // 2. Pickup order: ₹8,000, Paid ₹3,000, Outstanding ₹5,000
      final ord2 = await db.insert('orders', {
        'order_no': 'ORD-PICK',
        'customer_id': cust2,
        'customer_name': 'Pickup Cust',
        'customer_phone': '9876543212',
        'grand_total_paise': 800000,
        'fulfilment_type': 'pickup_later',
        'is_paid': 0,
        'status': 'confirmed',
        'created_at': nowStr,
        'updated_at': nowStr,
      });
      await db.insert('order_payments', {
        'order_id': ord2,
        'method': 'cash',
        'payment_type': 'SaleTender',
        'amount_paise': 300000,
        'created_at': nowStr,
      });

      // 3. Delivery order: ₹6,000, Paid ₹2,000, Outstanding ₹4,000
      final ord3 = await db.insert('orders', {
        'order_no': 'ORD-DELV',
        'customer_id': cust3,
        'customer_name': 'Delivery Cust',
        'customer_phone': '9876543213',
        'grand_total_paise': 600000,
        'fulfilment_type': 'delivery',
        'is_paid': 0,
        'status': 'delivered', // Delivery status completed, but financial status is partially paid
        'created_at': nowStr,
        'updated_at': nowStr,
      });
      await db.insert('order_payments', {
        'order_id': ord3,
        'method': 'card',
        'payment_type': 'SaleTender',
        'amount_paise': 200000,
        'created_at': nowStr,
      });

      // 4. Fully paid order: ₹1,000, Paid ₹1,000
      final ordPaid = await db.insert('orders', {
        'order_no': 'ORD-FULL',
        'customer_id': custPaid,
        'customer_name': 'Paid Cust',
        'customer_phone': '9876543214',
        'grand_total_paise': 100000,
        'fulfilment_type': 'take_away',
        'is_paid': 1,
        'status': 'delivered',
        'created_at': nowStr,
        'updated_at': nowStr,
      });
      await db.insert('order_payments', {
        'order_id': ordPaid,
        'method': 'cash',
        'payment_type': 'SaleTender',
        'amount_paise': 100000,
        'created_at': nowStr,
      });

      // Query Receivables dataset
      final pendingRows = await db.rawQuery('''
        SELECT
          o.id,
          o.order_no,
          o.fulfilment_type,
          o.grand_total_paise,
          COALESCE((
            SELECT SUM(op.amount_paise)
            FROM order_payments op
            WHERE op.order_id = o.id
              AND LOWER(COALESCE(op.method, op.payment_type, '')) != 'credit'
          ), 0) AS paid_amount_paise
        FROM orders o
        WHERE o.status NOT IN ('draft', 'cancelled')
      ''');

      final pendingOrders = pendingRows.where((r) {
        final total = (r['grand_total_paise'] as int?) ?? 0;
        final paid = (r['paid_amount_paise'] as int?) ?? 0;
        return (total - paid) > 0;
      }).toList();

      // Exactly 3 orders (Walk-in, Pickup, Delivery)
      expect(pendingOrders.length, 3);
      final totalOutstanding = pendingOrders.fold<int>(
        0,
        (sum, r) => sum + ((r['grand_total_paise'] as int) - (r['paid_amount_paise'] as int)),
      );
      // ₹5,000 + ₹5,000 + ₹4,000 = ₹14,000 (1400000 paise)
      expect(totalOutstanding, 1400000);
    });

    test('M. Collecting remaining ₹830 on delivery order clears Customer Outstanding and removes order from Receivables Report', () async {
      final custRepo = CustomerRepository();
      final orderRepo = OrderRepository();
      final db = await AppDatabase.instance.database;
      final nowStr = DateTime.now().toUtc().toIso8601String();

      final custId = await db.insert('customers', {
        'name': 'ubaid',
        'phone': '9574184092',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      final orderId = await db.insert('orders', {
        'order_no': 'ORD-DEL-UBAID-2',
        'customer_id': custId,
        'customer_name': 'ubaid',
        'customer_phone': '9574184092',
        'grand_total_paise': 100000,
        'fulfilment_type': 'delivery',
        'is_paid': 0,
        'status': 'delivered',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      // Partial advance ₹170
      await db.insert('order_payments', {
        'order_id': orderId,
        'method': 'cash',
        'payment_type': 'SaleTender',
        'amount_paise': 17000,
        'created_at': nowStr,
      });

      var cust = await custRepo.getById(custId);
      expect(cust?.pendingPaymentPaise, 83000);

      // Collect remaining ₹830 (83000 paise)
      await orderRepo.addOrderPaymentTransaction(
        orderId: orderId,
        amountPaise: 83000,
        method: 'cash',
        actor: 'Cashier',
        note: 'Final settlement for delivery order',
      );

      // Customer outstanding is now ₹0
      cust = await custRepo.getById(custId);
      expect(cust?.pendingPaymentPaise, 0);

      // Order is marked paid
      final orderRow = await db.query('orders', where: 'id = ?', whereArgs: [orderId]);
      expect(orderRow.first['is_paid'], 1);

      // Receivables report no longer returns this order
      final pendingRows = await db.rawQuery('''
        SELECT
          o.id,
          o.grand_total_paise,
          COALESCE((
            SELECT SUM(op.amount_paise)
            FROM order_payments op
            WHERE op.order_id = o.id
              AND LOWER(COALESCE(op.method, op.payment_type, '')) != 'credit'
          ), 0) AS paid_amount_paise
        FROM orders o
        WHERE o.id = ? AND o.status NOT IN ('draft', 'cancelled')
      ''', [orderId]);

      final pendingOrders = pendingRows.where((r) {
        final total = (r['grand_total_paise'] as int?) ?? 0;
        final paid = (r['paid_amount_paise'] as int?) ?? 0;
        return (total - paid) > 0;
      }).toList();

      expect(pendingOrders.isEmpty, true);
    });
  });
}
