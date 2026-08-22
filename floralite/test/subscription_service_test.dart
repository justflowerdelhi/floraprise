import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/models/subscription.dart';
import 'package:floraprise/services/subscription_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  var databaseCounter = 0;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await AppDatabase.instance.close();
    AppDatabase.testDatabaseName = 'subscription_test_${databaseCounter++}.db';
  });

  tearDown(() async {
    await AppDatabase.instance.close();
    AppDatabase.testDatabaseName = null;
  });

  test('subscription plans use finalized pricing and durations', () {
    expect(SubscriptionPlans.trial.durationDays, 7);
    expect(SubscriptionPlans.trial.pricePaise, 0);

    expect(SubscriptionPlans.quarterly.name, 'Quarterly Plan');
    expect(SubscriptionPlans.quarterly.durationDays, 90);
    expect(SubscriptionPlans.quarterly.pricePaise, 499900);

    expect(SubscriptionPlans.halfYearly.name, 'Half Yearly Plan');
    expect(SubscriptionPlans.halfYearly.durationDays, 180);
    expect(SubscriptionPlans.halfYearly.pricePaise, 899900);

    expect(SubscriptionPlans.annual.name, 'Annual Plan');
    expect(SubscriptionPlans.annual.durationDays, 365);
    expect(SubscriptionPlans.annual.pricePaise, 1499900);
    expect(SubscriptionPlans.annual.recommended, isTrue);
  });

  test('new install starts a 7-day active trial', () async {
    final now = DateTime(2026, 7, 19, 10);
    final service = SubscriptionService(
      secureStore: MemorySubscriptionSecureStore(),
      now: () => now,
    );

    final access = await service.load();

    expect(access.state, SubscriptionState.active);
    expect(access.record.plan, SubscriptionPlan.trial);
    expect(access.record.expiryDate, now.add(const Duration(days: 7)));
    expect(access.record.offlineExpiry, now.add(const Duration(days: 3)));
  });

  test('trial expiry locks without grace period', () async {
    final installedAt = DateTime(2026, 7, 19, 10);
    var now = installedAt;
    final service = SubscriptionService(
      secureStore: MemorySubscriptionSecureStore(),
      now: () => now,
    );
    await service.load();

    now = installedAt.add(const Duration(days: 15));
    final access = await service.load();

    expect(access.state, SubscriptionState.locked);
  });

  test('secure trial flag prevents a second trial after database reset',
      () async {
    final secureStore = MemorySubscriptionSecureStore();
    final now = DateTime(2026, 7, 19, 10);
    await SubscriptionService(
      secureStore: secureStore,
      now: () => now,
    ).load();

    await AppDatabase.instance.close();
    AppDatabase.testDatabaseName = 'subscription_test_${databaseCounter++}.db';

    final access = await SubscriptionService(
      secureStore: secureStore,
      now: () => now.add(const Duration(minutes: 1)),
    ).load();

    expect(access.state, SubscriptionState.locked);
  });

  test('paid subscription enters grace period then locks after 30 days',
      () async {
    final start = DateTime(2026, 7, 19, 10);
    var now = start;
    final service = SubscriptionService(
      secureStore: MemorySubscriptionSecureStore(),
      now: () => now,
    );
    final expiry = start.add(const Duration(days: 10));

    await service.activateLocalSubscription(
      plan: SubscriptionPlan.halfYearly,
      expiryDate: expiry,
      purchaseToken: 'token',
    );

    now = expiry.add(const Duration(days: 1));
    expect((await service.load()).state, SubscriptionState.gracePeriod);

    now = expiry.add(const Duration(days: 31));
    expect((await service.load()).state, SubscriptionState.locked);
  });
}
