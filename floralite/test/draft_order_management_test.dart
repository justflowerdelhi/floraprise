import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/data/repositories/order_repository.dart';
import 'package:floraprise/managers/customer_manager.dart';
import 'package:floraprise/managers/inventory_manager.dart';
import 'package:floraprise/managers/order_manager.dart';
import 'package:floraprise/managers/pricing_manager.dart';
import 'package:floraprise/managers/scheduler_manager.dart';
import 'package:floraprise/managers/walk_in_manager.dart';
import 'package:floraprise/data/repositories/customer_repository.dart';
import 'package:floraprise/data/repositories/inventory_repository.dart';
import 'package:floraprise/data/repositories/job_repository.dart';
import 'package:floraprise/data/repositories/scheduler_repository.dart';
import 'package:floraprise/models/walk_in_enums.dart';
import 'package:floraprise/models/walk_in_line_item.dart';
import 'package:floraprise/models/walk_in_session.dart';
import 'package:floraprise/models/payment_split.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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

  test('opening POS starts blank even when a draft exists', () async {
    final orderRepository = OrderRepository();
    final orderManager = OrderManager(orderRepository, JobRepository());
    final walkInManager = WalkInManager(
      customerManager: CustomerManager(CustomerRepository()),
      pricingManager: PricingManager(),
      orderManager: orderManager,
      inventoryManager: InventoryManager(InventoryRepository()),
      schedulerManager: SchedulerManager(SchedulerRepository()),
    );

    await walkInManager.saveDraft(
      const WalkInSession(
        fulfilmentType: FulfilmentType.takeAway,
        customerName: 'Rahul Sharma',
        customerPhone: '9876543210',
        lines: [
          WalkInLineItem(
            description: 'Rose Bouquet',
            quantity: 2,
            unitPricePaise: 50000,
            source: 'manual',
          ),
        ],
      ),
    );

    final freshSession =
        await walkInManager.startOrResume(FulfilmentType.takeAway);
    final drafts = await orderRepository.listDraftOrders();
    final restoredDraft = await orderRepository.getDraftById(drafts.single.id);

    expect(freshSession.draftOrderId, isNull);
    expect(freshSession.lines, isEmpty);
    expect(freshSession.customerName, isEmpty);
    expect(drafts, hasLength(1));
    expect(drafts.single.customerName, 'Rahul Sharma');
    expect(restoredDraft, isNotNull);
    expect(restoredDraft!.lines, isA<List<WalkInLineItem>>());
    expect(restoredDraft.lines.single.description, 'Rose Bouquet');
  });

  test('deleteDraft removes only draft orders', () async {
    final orderRepository = OrderRepository();
    final orderManager = OrderManager(orderRepository, JobRepository());
    final walkInManager = WalkInManager(
      customerManager: CustomerManager(CustomerRepository()),
      pricingManager: PricingManager(),
      orderManager: orderManager,
      inventoryManager: InventoryManager(InventoryRepository()),
      schedulerManager: SchedulerManager(SchedulerRepository()),
    );

    final draftResult = await walkInManager.saveDraft(
      const WalkInSession(
        fulfilmentType: FulfilmentType.takeAway,
        customerName: 'Draft Customer',
        lines: [
          WalkInLineItem(
            description: 'Draft Line',
            quantity: 1,
            unitPricePaise: 10000,
            source: 'manual',
          ),
        ],
      ),
    );
    final completed = await walkInManager.confirmOrder(
      const WalkInSession(
        fulfilmentType: FulfilmentType.takeAway,
        customerName: 'Completed Customer',
        payments: [
          PaymentSplit(
            method: PaymentMethod.cash,
            amountPaise: 10000,
            methodCode: 'cash',
          ),
        ],
        lines: [
          WalkInLineItem(
            description: 'Completed Line',
            quantity: 1,
            unitPricePaise: 10000,
            gstPercent: 0,
            source: 'manual',
          ),
        ],
      ),
    );

    await orderRepository.deleteDraft(completed.orderId);
    await orderRepository.deleteDraft(draftResult.session.draftOrderId!);

    final drafts = await orderRepository.listDraftOrders();
    final completedSummary =
        await orderRepository.getOrderSummary(completed.orderId);

    expect(drafts, isEmpty);
    expect(completedSummary['status'], 'confirmed');
  });
}
