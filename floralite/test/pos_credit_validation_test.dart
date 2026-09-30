import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/data/repositories/customer_repository.dart';
import 'package:floraprise/data/repositories/inventory_repository.dart';
import 'package:floraprise/data/repositories/job_repository.dart';
import 'package:floraprise/data/repositories/order_repository.dart';
import 'package:floraprise/data/repositories/pos_sync_outbox_repository.dart';
import 'package:floraprise/data/repositories/scheduler_repository.dart';
import 'package:floraprise/managers/customer_manager.dart';
import 'package:floraprise/managers/inventory_manager.dart';
import 'package:floraprise/managers/order_manager.dart';
import 'package:floraprise/managers/pricing_manager.dart';
import 'package:floraprise/managers/scheduler_manager.dart';
import 'package:floraprise/managers/walk_in_manager.dart';
import 'package:floraprise/models/payment_split.dart';
import 'package:floraprise/models/walk_in_enums.dart';
import 'package:floraprise/models/walk_in_line_item.dart';
import 'package:floraprise/models/walk_in_session.dart';
import 'package:floraprise/providers/walk_in_session_provider.dart';
import 'package:floraprise/services/pos_sale_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CustomerManager Phone Validation Helpers', () {
    test('validates 10 digit Indian phones correctly', () {
      expect(CustomerManager.isValidPhone('9876543210'), isTrue);
      expect(CustomerManager.isValidPhone('+91 9876543210'), isTrue);
      expect(CustomerManager.isValidPhone('+91-98765-43210'), isTrue);
      expect(CustomerManager.isValidPhone('09876543210'), isTrue);
      expect(CustomerManager.isValidPhone(''), isFalse);
      expect(CustomerManager.isValidPhone('12345'), isFalse);
      expect(CustomerManager.isValidPhone('abcdefghij'), isFalse);
    });

    test('normalizes digits correctly', () {
      expect(CustomerManager.normalizeDigits('+91 98765-43210'), '9876543210');
      expect(CustomerManager.normalizeDigits('9876543210'), '9876543210');
      expect(CustomerManager.normalizeDigits('12345'), '12345');
    });
  });

  group('PricingManager validatePayments — 10 Required Scenarios', () {
    final pricingManager = PricingManager();
    const grandTotalPaise = 100000; // ₹1,000

    test('Scenario 1: ₹1,000 sale, Full cash (₹1,000), no customer -> allowed', () {
      final result = pricingManager.validatePayments(
        grandTotalPaise: grandTotalPaise,
        payments: const [
          PaymentSplit(method: PaymentMethod.cash, amountPaise: 100000),
        ],
        customerName: '',
        customerPhone: '',
      );

      expect(result.isValid, isTrue);
      expect(result.message, isNull);
    });

    test('Scenario 2: ₹1,000 sale, Full UPI (₹1,000), no customer -> allowed', () {
      final result = pricingManager.validatePayments(
        grandTotalPaise: grandTotalPaise,
        payments: const [
          PaymentSplit(method: PaymentMethod.upi, amountPaise: 100000),
        ],
        customerName: '',
        customerPhone: '',
      );

      expect(result.isValid, isTrue);
      expect(result.message, isNull);
    });

    test('Scenario 3: ₹1,000 sale, Full card (₹1,000), no customer -> allowed', () {
      final result = pricingManager.validatePayments(
        grandTotalPaise: grandTotalPaise,
        payments: const [
          PaymentSplit(method: PaymentMethod.card, amountPaise: 100000),
        ],
        customerName: '',
        customerPhone: '',
      );

      expect(result.isValid, isTrue);
      expect(result.message, isNull);
    });

    test('Scenario 4: ₹1,000 sale, Cash ₹500 + Credit ₹500, no customer -> rejected', () {
      final result = pricingManager.validatePayments(
        grandTotalPaise: grandTotalPaise,
        payments: const [
          PaymentSplit(method: PaymentMethod.cash, amountPaise: 50000),
          PaymentSplit(
            method: PaymentMethod.other,
            methodCode: 'credit',
            amountPaise: 50000,
          ),
        ],
        customerName: '',
        customerPhone: '',
      );

      expect(result.isValid, isFalse);
      expect(
        result.message,
        'Customer Name and Phone Number are required for credit or partial payment transactions.',
      );
    });

    test('Scenario 5: ₹1,000 sale, Cash ₹500 + Credit ₹500, customer name but no phone -> rejected', () {
      final result = pricingManager.validatePayments(
        grandTotalPaise: grandTotalPaise,
        payments: const [
          PaymentSplit(method: PaymentMethod.cash, amountPaise: 50000),
          PaymentSplit(
            method: PaymentMethod.other,
            methodCode: 'credit',
            amountPaise: 50000,
          ),
        ],
        customerName: 'Rahul Sharma',
        customerPhone: '',
      );

      expect(result.isValid, isFalse);
      expect(
        result.message,
        'Customer Name and Phone Number are required for credit or partial payment transactions.',
      );
    });

    test('Scenario 6: ₹1,000 sale, Cash ₹500 + Credit ₹500, phone but no name -> rejected', () {
      final result = pricingManager.validatePayments(
        grandTotalPaise: grandTotalPaise,
        payments: const [
          PaymentSplit(method: PaymentMethod.cash, amountPaise: 50000),
          PaymentSplit(
            method: PaymentMethod.other,
            methodCode: 'credit',
            amountPaise: 50000,
          ),
        ],
        customerName: '   ',
        customerPhone: '9876543210',
      );

      expect(result.isValid, isFalse);
      expect(
        result.message,
        'Customer Name and Phone Number are required for credit or partial payment transactions.',
      );
    });

    test('Scenario 7: ₹1,000 sale, Cash ₹500 + Credit ₹500, valid name + phone -> allowed', () {
      final result = pricingManager.validatePayments(
        grandTotalPaise: grandTotalPaise,
        payments: const [
          PaymentSplit(method: PaymentMethod.cash, amountPaise: 50000),
          PaymentSplit(
            method: PaymentMethod.other,
            methodCode: 'credit',
            amountPaise: 50000,
          ),
        ],
        customerName: 'Rahul Sharma',
        customerPhone: '+91 98765 43210',
      );

      expect(result.isValid, isTrue);
      expect(result.message, isNull);
    });

    test('Scenario 8: ₹1,000 sale, 100% Credit ₹1,000, no customer -> rejected', () {
      final result = pricingManager.validatePayments(
        grandTotalPaise: grandTotalPaise,
        payments: const [
          PaymentSplit(
            method: PaymentMethod.other,
            methodCode: 'credit',
            amountPaise: 100000,
          ),
        ],
        customerName: '',
        customerPhone: '',
      );

      expect(result.isValid, isFalse);
      expect(
        result.message,
        'Customer Name and Phone Number are required for credit or partial payment transactions.',
      );
    });

    test('Scenario 9: ₹1,000 sale, Cash ₹600 + UPI ₹400, no customer -> allowed', () {
      final result = pricingManager.validatePayments(
        grandTotalPaise: grandTotalPaise,
        payments: const [
          PaymentSplit(method: PaymentMethod.cash, amountPaise: 60000),
          PaymentSplit(method: PaymentMethod.upi, amountPaise: 40000),
        ],
        customerName: '',
        customerPhone: '',
      );

      expect(result.isValid, isTrue);
      expect(result.message, isNull);
    });

    test('Scenario 10: ₹1,000 sale, Cash ₹500 + UPI ₹200 + Credit ₹300, valid customer -> allowed', () {
      final result = pricingManager.validatePayments(
        grandTotalPaise: grandTotalPaise,
        payments: const [
          PaymentSplit(method: PaymentMethod.cash, amountPaise: 50000),
          PaymentSplit(method: PaymentMethod.upi, amountPaise: 20000),
          PaymentSplit(
            method: PaymentMethod.other,
            methodCode: 'credit',
            amountPaise: 30000,
          ),
        ],
        customerName: 'Anita Gupta',
        customerPhone: '9811122233',
      );

      expect(result.isValid, isTrue);
      expect(result.message, isNull);
    });

    test('Other non-credit tenders (Bank Transfer, Cheque, Gift Voucher) do not trigger credit validation when fully covering total', () {
      final result = pricingManager.validatePayments(
        grandTotalPaise: grandTotalPaise,
        payments: const [
          PaymentSplit(
            method: PaymentMethod.bank,
            methodCode: 'bank_transfer',
            amountPaise: 50000,
          ),
          PaymentSplit(
            method: PaymentMethod.other,
            methodCode: 'gift_voucher',
            amountPaise: 50000,
          ),
        ],
        customerName: '',
        customerPhone: '',
      );

      expect(result.isValid, isTrue);
    });

    test('Partial payment without explicit credit item still calculates outstanding and requires customer', () {
      final result = pricingManager.validatePayments(
        grandTotalPaise: 100000,
        payments: const [
          PaymentSplit(method: PaymentMethod.cash, amountPaise: 60000),
        ],
        customerName: '',
        customerPhone: '',
      );

      expect(result.isValid, isFalse);
      expect(
        result.message,
        'Customer Name and Phone Number are required for credit or partial payment transactions.',
      );
    });
  });

  group('WalkInManager Checkout Enforcement', () {
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

    WalkInManager createManager({PosSaleSyncService? posSaleSyncService}) {
      final orderRepository = OrderRepository();
      return WalkInManager(
        customerManager: CustomerManager(CustomerRepository()),
        pricingManager: PricingManager(),
        orderManager: OrderManager(orderRepository, JobRepository()),
        inventoryManager: InventoryManager(InventoryRepository()),
        schedulerManager: SchedulerManager(SchedulerRepository()),
        posSaleSyncService: posSaleSyncService,
      );
    }

    test('confirmOrder throws StateError with exact message when credit sale lacks customer', () async {
      final manager = createManager();
      const session = WalkInSession(
        fulfilmentType: FulfilmentType.takeAway,
        customerName: '',
        customerPhone: '',
        lines: [
          WalkInLineItem(
            description: 'Red Roses',
            quantity: 1,
            unitPricePaise: 100000,
            gstPercent: 0,
            source: 'manual',
          ),
        ],
        payments: [
          PaymentSplit(method: PaymentMethod.cash, amountPaise: 50000),
          PaymentSplit(
            method: PaymentMethod.other,
            methodCode: 'credit',
            amountPaise: 50000,
          ),
        ],
      );

      expect(
        () => manager.confirmOrder(session),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'Customer Name and Phone Number are required for credit or partial payment transactions.',
          ),
        ),
      );
    });

    test('confirmOrder succeeds with customer details for credit sale', () async {
      final manager = createManager();
      const session = WalkInSession(
        fulfilmentType: FulfilmentType.takeAway,
        customerName: 'Priya Verma',
        customerPhone: '9876543210',
        lines: [
          WalkInLineItem(
            description: 'Red Roses',
            quantity: 1,
            unitPricePaise: 100000,
            gstPercent: 0,
            source: 'manual',
          ),
        ],
        payments: [
          PaymentSplit(method: PaymentMethod.cash, amountPaise: 50000),
          PaymentSplit(
            method: PaymentMethod.other,
            methodCode: 'credit',
            amountPaise: 50000,
          ),
        ],
      );

      final result = await manager.confirmOrder(session);
      expect(result.orderId, isPositive);
      expect(result.grandTotalPaise, 100000);
    });

    test('confirmOrder succeeds for fully paid walk-in without customer', () async {
      final manager = createManager();
      const session = WalkInSession(
        fulfilmentType: FulfilmentType.takeAway,
        customerName: '',
        customerPhone: '',
        lines: [
          WalkInLineItem(
            description: 'Red Roses',
            quantity: 1,
            unitPricePaise: 100000,
            gstPercent: 0,
            source: 'manual',
          ),
        ],
        payments: [
          PaymentSplit(method: PaymentMethod.cash, amountPaise: 100000),
        ],
      );

      final result = await manager.confirmOrder(session);
      expect(result.orderId, isPositive);
      expect(result.grandTotalPaise, 100000);
    });

    test('confirmOnlineOrder throws StateError with exact message when credit sale lacks customer', () async {
      final syncService = PosSaleSyncService(
        outboxRepository: PosSyncOutboxRepository(),
      );
      final manager = createManager(posSaleSyncService: syncService);

      const session = WalkInSession(
        fulfilmentType: FulfilmentType.takeAway,
        customerName: '',
        customerPhone: '',
        lines: [
          WalkInLineItem(
            description: 'Red Roses',
            quantity: 1,
            unitPricePaise: 100000,
            gstPercent: 0,
            source: 'manual',
          ),
        ],
        payments: [
          PaymentSplit(method: PaymentMethod.cash, amountPaise: 50000),
          PaymentSplit(
            method: PaymentMethod.other,
            methodCode: 'credit',
            amountPaise: 50000,
          ),
        ],
      );

      expect(
        () => manager.confirmOnlineOrder(session),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'Customer Name and Phone Number are required for credit or partial payment transactions.',
          ),
        ),
      );
    });

    test('updateExistingOrder throws StateError when updated payment includes credit without customer', () async {
      final manager = createManager();
      const session = WalkInSession(
        fulfilmentType: FulfilmentType.takeAway,
        customerName: '',
        customerPhone: '',
        lines: [
          WalkInLineItem(
            description: 'Red Roses',
            quantity: 1,
            unitPricePaise: 100000,
            gstPercent: 0,
            source: 'manual',
          ),
        ],
        payments: [
          PaymentSplit(
            method: PaymentMethod.other,
            methodCode: 'credit',
            amountPaise: 100000,
          ),
        ],
      );

      expect(
        () => manager.updateExistingOrder(orderId: 1, session: session),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'Customer Name and Phone Number are required for credit or partial payment transactions.',
          ),
        ),
      );
    });
  });

  group('WalkInSessionProvider Credit Handling', () {
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

    test('confirmOrder surfaces clean validation message and preserves session state', () async {
      final orderRepository = OrderRepository();
      final walkInManager = WalkInManager(
        customerManager: CustomerManager(CustomerRepository()),
        pricingManager: PricingManager(),
        orderManager: OrderManager(orderRepository, JobRepository()),
        inventoryManager: InventoryManager(InventoryRepository()),
        schedulerManager: SchedulerManager(SchedulerRepository()),
      );
      final provider = WalkInSessionProvider(walkInManager);

      provider.patchSession(
        const WalkInSession(
          fulfilmentType: FulfilmentType.takeAway,
          customerName: '',
          customerPhone: '',
          lines: [
            WalkInLineItem(
              description: 'Pink Lilies',
              quantity: 1,
              unitPricePaise: 150000,
              gstPercent: 0,
              source: 'manual',
            ),
          ],
          payments: [
            PaymentSplit(method: PaymentMethod.cash, amountPaise: 50000),
            PaymentSplit(
              method: PaymentMethod.other,
              methodCode: 'credit',
              amountPaise: 100000,
            ),
          ],
        ),
      );

      final orderId = await provider.confirmOrder();

      // Should fail cleanly
      expect(orderId, isNull);
      expect(
        provider.error,
        'Customer Name and Phone Number are required for credit or partial payment transactions.',
      );
      // Session and payment allocations must NOT be cleared or converted
      expect(provider.session.lines, hasLength(1));
      expect(provider.session.lines.first.description, 'Pink Lilies');
      expect(provider.session.payments, hasLength(2));
      expect(provider.session.payments[0].method, PaymentMethod.cash);
      expect(provider.session.payments[0].amountPaise, 50000);
      expect(provider.session.payments[1].persistenceMethod, 'credit');
      expect(provider.session.payments[1].amountPaise, 100000);

      // Now add customer details and retry
      provider.patchSession(
        provider.session.copyWith(
          customerName: 'Sunita Rao',
          customerPhone: '9820011223',
        ),
      );

      final successOrderId = await provider.confirmOrder();
      expect(successOrderId, isNotNull);
      expect(successOrderId! > 0, isTrue);
      expect(provider.error, isNull);
    });
  });
}
