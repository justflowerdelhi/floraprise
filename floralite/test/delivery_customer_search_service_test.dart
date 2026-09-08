import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/data/repositories/cloud_customer_repository.dart';
import 'package:floraprise/data/repositories/customer_repository.dart';
import 'package:floraprise/screens/delivery_screen.dart';
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

  group('DeliveryCustomerSearchService', () {
    test('cloud mode searches cached tenant customers and refreshes Cloud results', () async {
      final repo = CustomerRepository();
      await repo.upsertFromCloud(
        cloudCustomerId: 'cloud-101',
        cloudCompanyId: companyOne,
        phone: '9876500001',
        name: 'Alice Cached',
      );

      var cloudCalls = 0;
      final service = DeliveryCustomerSearchService(
        repository: repo,
        currentCompanyId: () async => companyOne,
        isOnline: () async => true,
        cloudSearcher: ({String? query}) async {
          cloudCalls++;
          expect(query, 'ali');
          return const [
            CloudCustomer(
              id: 'cloud-101',
              name: 'Alice Cloud',
              phone: '9876500001',
              notes: 'updated from cloud',
            ),
          ];
        },
      );

      final results = await service.search('ali', isCloud: true);

      expect(cloudCalls, 1);
      expect(results.length, 1);
      expect(results.first.name, 'Alice Cloud');
      expect(results.first.cloudCustomerId, 'cloud-101');
      expect(results.first.cloudCompanyId, companyOne);

      final cached = await repo.findByCloudId('cloud-101', companyId: companyOne);
      expect(cached, isNotNull);
      expect(cached!.notes, 'updated from cloud');
    });

    test('cloud mode offline searches cached customers only', () async {
      final repo = CustomerRepository();
      await repo.upsertFromCloud(
        cloudCustomerId: 'cloud-202',
        cloudCompanyId: companyOne,
        phone: '9876500002',
        name: 'Offline Carol',
      );

      var cloudCalls = 0;
      final service = DeliveryCustomerSearchService(
        repository: repo,
        currentCompanyId: () async => companyOne,
        isOnline: () async => false,
        cloudSearcher: ({String? query}) async {
          cloudCalls++;
          return const [
            CloudCustomer(
              id: 'cloud-203',
              name: 'Unexpected Cloud',
              phone: '9876500002',
            ),
          ];
        },
      );

      final results = await service.search('car', isCloud: true);

      expect(cloudCalls, 0);
      expect(results, isNotEmpty);
      expect(results.first.name, 'Offline Carol');
      expect(results.first.cloudCustomerId, 'cloud-202');
    });

    test('cloud mode excludes tenant-isolated cache entries', () async {
      final repo = CustomerRepository();
      await repo.upsertFromCloud(
        cloudCustomerId: 'cloud-303',
        cloudCompanyId: companyTwo,
        phone: '9876500003',
        name: 'Tenant Two Eve',
      );

      final service = DeliveryCustomerSearchService(
        repository: repo,
        currentCompanyId: () async => companyOne,
        isOnline: () async => true,
        cloudSearcher: ({String? query}) async {
          return const [
            CloudCustomer(
              id: 'cloud-304',
              name: 'Tenant One Eve',
              phone: '9876500009',
            ),
          ];
        },
      );

      final results = await service.search('eve', isCloud: true);

      expect(results, isNotEmpty);
      expect(results.first.cloudCompanyId, companyOne);
      expect(results.first.name, 'Tenant One Eve');

      final otherTenant = await repo.findByCloudId('cloud-303', companyId: companyTwo);
      expect(otherTenant, isNotNull);
      expect(otherTenant!.name, 'Tenant Two Eve');
      expect(await repo.findByPhone('9876500003', companyId: companyOne), isNull);
    });

    test('local mode preserves raw repository search behavior', () async {
      final repo = CustomerRepository();
      await repo.create(phone: '9876500004', name: 'Local Only');

      final service = DeliveryCustomerSearchService(
        repository: repo,
        currentCompanyId: () async => companyOne,
        isOnline: () async => true,
      );

      final results = await service.search('local', isCloud: false);
      expect(results, isNotEmpty);
      expect(results.first.name, 'Local Only');
    });
  });
}
