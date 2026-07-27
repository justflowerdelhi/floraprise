import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/models/subscription.dart';
import 'package:floraprise/services/subscription_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await AppDatabase.instance.close();
  });

  test('subscription plans use finalized pricing and durations', () {
    expect(SubscriptionPlans.trial.durationDays, 14);
    expect(SubscriptionPlans.trial.pricePaise, 0);

    expect(SubscriptionPlans.halfYearly.name, 'Half-Yearly');
    expect(SubscriptionPlans.halfYearly.durationDays, 180);
    expect(SubscriptionPlans.halfYearly.pricePaise, 599900);

    expect(SubscriptionPlans.yearly.name, 'Yearly');
    expect(SubscriptionPlans.yearly.durationDays, 365);
    expect(SubscriptionPlans.yearly.pricePaise, 999900);
    expect(SubscriptionPlans.yearly.recommended, isTrue);
  });

  test('new install starts a 14-day active trial', () async {
    final now = DateTime(2026, 7, 19, 10);
    final service = SubscriptionService(
      secureStore: MemorySubscriptionSecureStore(),
      now: () => now,
    );

    final access = await service.load();

    expect(access.state, SubscriptionState.active);
    expect(access.record.plan, SubscriptionPlan.trial);
    expect(access.record.expiryDate, now.add(const Duration(days: 14)));
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
    final path = await getDatabasesPath();
    await deleteDatabase('$path/floraprise.db');

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

  test('offline access requires internet after 3 days', () async {
    final start = DateTime(2026, 7, 19, 10);
    var now = start;
    final service = SubscriptionService(
      secureStore: MemorySubscriptionSecureStore(),
      now: () => now,
    );
    await service.load();

    now = start.add(const Duration(days: 4));
    final access = await service.load();

    expect(access.requiresInternet, isTrue);
    expect(access.blocksBusinessAccess, isTrue);
  });

  test('manual clock rollback requires online verification', () async {
    final start = DateTime(2026, 7, 19, 10);
    var now = start;
    final service = SubscriptionService(
      secureStore: MemorySubscriptionSecureStore(),
      now: () => now,
    );
    await service.load();

    now = start.subtract(const Duration(days: 1));
    final access = await service.load();

    expect(access.clockTamperingDetected, isTrue);
    expect(access.blocksBusinessAccess, isTrue);
  });
}
