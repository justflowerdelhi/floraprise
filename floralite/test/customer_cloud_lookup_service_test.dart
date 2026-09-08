import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/data/repositories/cloud_customer_repository.dart';
import 'package:floraprise/data/repositories/customer_repository.dart';
import 'package:floraprise/services/customer_cloud_lookup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const companyOne = '11111111-1111-4111-8111-111111111111';
const companyTwo = '22222222-2222-4222-8222-222222222222';

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
    AppDatabase.testDatabaseName = null;
    AppDatabase.useInMemoryForTests = false;
  });

  test('cache hit returns the tenant-scoped local customer without a Cloud call', () async {
    final repository = CustomerRepository();
    await repository.upsertFromCloud(
      cloudCustomerId: 'c-1',
      cloudCompanyId: companyOne,
      phone: '9876500001',
      name: 'Cached Alice',
    );

    var cloudCalls = 0;
    final service = CustomerCloudLookupService(
      customerRepository: repository,
      currentCompanyId: () async => companyOne,
      isOnline: () async => true,
      findCloudCustomerByPhone: (_) async {
        cloudCalls++;
        return null;
      },
    );

    final result = await service.lookupByPhone('9876500001');

    expect(result, isNotNull);
    expect(result!.name, 'Cached Alice');
    expect(cloudCalls, 0);
  });

  test('cache miss while online queries Cloud and caches the linked customer', () async {
    final repository = CustomerRepository();
    final service = CustomerCloudLookupService(
      customerRepository: repository,
      currentCompanyId: () async => companyOne,
      isOnline: () async => true,
      findCloudCustomerByPhone: (phone) async => CloudCustomer(
        id: 'cloud-99',
        name: 'Bob From Cloud',
        phone: phone,
      ),
    );

    final result = await service.lookupByPhone('9876500002');

    expect(result, isNotNull);
    expect(result!.name, 'Bob From Cloud');
    expect(result.cloudCustomerId, 'cloud-99');
    expect(result.cloudCompanyId, companyOne);

    // Second lookup must now be a cache hit.
    var cloudCalls = 0;
    final second = CustomerCloudLookupService(
      customerRepository: repository,
      currentCompanyId: () async => companyOne,
      isOnline: () async => true,
      findCloudCustomerByPhone: (_) async {
        cloudCalls++;
        return null;
      },
    );
    final cached = await second.lookupByPhone('9876500002');
    expect(cached!.id, result.id);
    expect(cloudCalls, 0);
  });

  test('cache miss with no matching Cloud customer returns null', () async {
    final repository = CustomerRepository();
    final service = CustomerCloudLookupService(
      customerRepository: repository,
      currentCompanyId: () async => companyOne,
      isOnline: () async => true,
      findCloudCustomerByPhone: (_) async => null,
    );

    final result = await service.lookupByPhone('9876500003');

    expect(result, isNull);
    expect(await repository.getAll(), isEmpty);
  });

  test('offline with cache miss returns null and does not call Cloud', () async {
    final repository = CustomerRepository();
    var cloudCalls = 0;
    final service = CustomerCloudLookupService(
      customerRepository: repository,
      currentCompanyId: () async => companyOne,
      isOnline: () async => false,
      findCloudCustomerByPhone: (_) async {
        cloudCalls++;
        return const CloudCustomer(id: 'cloud-1', name: 'Unreachable', phone: '9876500004');
      },
    );

    final result = await service.lookupByPhone('9876500004');

    expect(result, isNull);
    expect(cloudCalls, 0);
  });

  test('offline still returns a cached customer', () async {
    final repository = CustomerRepository();
    await repository.upsertFromCloud(
      cloudCustomerId: 'c-2',
      cloudCompanyId: companyOne,
      phone: '9876500005',
      name: 'Offline Cached Carol',
    );

    final service = CustomerCloudLookupService(
      customerRepository: repository,
      currentCompanyId: () async => companyOne,
      isOnline: () async => false,
      findCloudCustomerByPhone: (_) async =>
          throw StateError('Cloud must not be called offline'),
    );

    final result = await service.lookupByPhone('9876500005');

    expect(result, isNotNull);
    expect(result!.name, 'Offline Cached Carol');
  });

  test('tenant isolation: cache from another company is never returned, and a phone conflict is rejected safely', () async {
    final repository = CustomerRepository();
    await repository.upsertFromCloud(
      cloudCustomerId: 'c-3',
      cloudCompanyId: companyTwo,
      phone: '9876500006',
      name: 'Tenant Two Dave',
    );

    var cloudCalls = 0;
    final service = CustomerCloudLookupService(
      customerRepository: repository,
      currentCompanyId: () async => companyOne,
      isOnline: () async => true,
      findCloudCustomerByPhone: (phone) async {
        cloudCalls++;
        return CloudCustomer(id: 'c-4', name: 'Tenant One Dave', phone: phone);
      },
    );

    // The Company Two cache entry must never be returned to Company One,
    // so the service falls through to Cloud instead of a false cache hit —
    // which then safely rejects the cross-tenant phone conflict rather than
    // silently reassigning another company's customer.
    await expectLater(
      () => service.lookupByPhone('9876500006'),
      throwsArgumentError,
    );
    expect(cloudCalls, 1);

    // Original Company Two record must remain untouched and distinct.
    final companyTwoRecord = await repository.findByCloudId('c-3', companyId: companyTwo);
    expect(companyTwoRecord, isNotNull);
    expect(companyTwoRecord!.name, 'Tenant Two Dave');
  });

  test('no authenticated company falls back to plain Local lookup', () async {
    final repository = CustomerRepository();
    await repository.create(phone: '9876500007', name: 'Local Only Eve');

    var cloudCalls = 0;
    final service = CustomerCloudLookupService(
      customerRepository: repository,
      currentCompanyId: () async => null,
      isOnline: () async => true,
      findCloudCustomerByPhone: (_) async {
        cloudCalls++;
        return null;
      },
    );

    final result = await service.lookupByPhone('9876500007');

    expect(result, isNotNull);
    expect(result!.name, 'Local Only Eve');
    expect(cloudCalls, 0);
  });
}
