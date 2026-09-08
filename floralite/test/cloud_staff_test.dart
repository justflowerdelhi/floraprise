import 'package:floraprise/data/repositories/cloud_staff_repository.dart';
import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/data/repositories/staff_repository.dart';
import 'package:floraprise/models/storage_mode.dart';
import 'package:floraprise/providers/cloud_staff_provider.dart';
import 'package:floraprise/providers/staff_provider.dart';
import 'package:floraprise/providers/storage_mode_provider.dart';
import 'package:floraprise/services/storage_mode_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _staffId = '44444444-4444-4444-8444-444444444444';

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

  test('App roles map to Cloud roles without silent fallbacks', () {
    expect(CloudStaffRoles.toCloud(StaffRole.designer), 'Designer');
    expect(CloudStaffRoles.toCloud(StaffRole.delivery), 'Driver');
    expect(CloudStaffRoles.toCloud(StaffRole.other), 'Staff');
    expect(CloudStaffRoles.displayName(StaffRole.other), 'Staff');

    for (final role in [
      StaffRole.chef,
      StaffRole.sales,
      StaffRole.cashier,
      StaffRole.manager,
      StaffRole.owner,
      StaffRole.helper,
    ]) {
      expect(CloudStaffRoles.isSupported(role), isFalse);
      expect(
        () => CloudStaffRoles.toCloud(role),
        throwsA(isA<CloudStaffRoleNotSupportedException>()),
      );
    }

    expect(CloudStaffRoles.toAppRole('Driver'), StaffRole.delivery);
    expect(CloudStaffRoles.toAppRole('designer'), StaffRole.designer);
    expect(CloudStaffRoles.toAppRole('Admin'), isNull);
    expect(CloudStaffRoles.toAppRole('Staff'), StaffRole.other);
  });

  test('Cloud mode lists staff from the Cloud staff endpoint', () async {
    final storage = await _storageMode(StorageMode.cloud);
    final calls = <Uri>[];
    final provider = CloudStaffProvider(
      storage,
      CloudStaffRepository(
        sender: (method, uri, {body}) async {
          calls.add(uri);
          expect(method, 'GET');
          expect(body, isNull);
          return _staffListResponse();
        },
      ),
    );

    await provider.loadStaff();

    expect(calls.single.path, '/api/staff');
    expect(provider.error, isNull);
    expect(provider.staff, hasLength(3));
    final designer = provider.staff.firstWhere((s) => s.name == 'Asha');
    expect(designer.id, _staffId);
    expect(designer.appRole, StaffRole.designer);
    expect(designer.roleLabel, 'Designer');
    final admin = provider.staff.firstWhere((s) => s.name == 'Zoya');
    expect(admin.appRole, isNull);
    expect(admin.roleLabel, 'Admin');
  });

  test('Search sends query, mapped role and active flag', () async {
    final storage = await _storageMode(StorageMode.cloud);
    final calls = <Uri>[];
    final provider = CloudStaffProvider(
      storage,
      CloudStaffRepository(
        sender: (method, uri, {body}) async {
          calls.add(uri);
          return _staffListResponse();
        },
      ),
    );

    await provider.searchStaff(
      query: 'asha',
      role: StaffRole.delivery,
      isActive: false,
    );

    expect(calls.single.path, '/api/staff/search');
    expect(calls.single.queryParameters['query'], 'asha');
    expect(calls.single.queryParameters['role'], 'Driver');
    expect(calls.single.queryParameters['isActive'], 'false');
  });

  test('Role and status filters run over Cloud results', () async {
    final storage = await _storageMode(StorageMode.cloud);
    final provider = CloudStaffProvider(
      storage,
      CloudStaffRepository(
        sender: (method, uri, {body}) async => _staffListResponse(),
      ),
    );
    await provider.loadStaff();

    provider.setRoleFilter(StaffRole.delivery);
    expect(provider.staff.map((s) => s.name), ['Bhanu']);

    provider.setRoleFilter(null);
    provider.setStatusFilter(StaffStatusFilter.inactive);
    expect(provider.staff.map((s) => s.name), ['Bhanu']);

    provider.setStatusFilter(StaffStatusFilter.active);
    expect(provider.staff.map((s) => s.name), ['Asha', 'Zoya']);

    provider.setStatusFilter(StaffStatusFilter.all);
    provider.setQuery('9876500002');
    expect(provider.staff.map((s) => s.name), ['Bhanu']);
  });

  test('Create posts the Cloud role and reloads from Cloud', () async {
    final storage = await _storageMode(StorageMode.cloud);
    final requests = <({String method, Uri uri, Map<String, dynamic>? body})>[];
    final provider = CloudStaffProvider(
      storage,
      CloudStaffRepository(
        sender: (method, uri, {body}) async {
          requests.add((method: method, uri: uri, body: body));
          if (method == 'POST') return {'id': _staffId};
          return _staffListResponse();
        },
      ),
    );

    await provider.createStaff(
      const CloudStaffInput(
        name: 'New Driver',
        role: StaffRole.delivery,
        phone: '9876500003',
        email: 'driver@example.com',
      ),
    );

    final post = requests.first;
    expect(post.method, 'POST');
    expect(post.uri.path, '/api/staff');
    expect(post.body, {
      'name': 'New Driver',
      'role': 'Driver',
      'phone': '9876500003',
      'email': 'driver@example.com',
      'isActive': true,
    });
    expect(requests.last.uri.path, '/api/staff');
    expect(requests.last.method, 'GET');
  });

  test('Update and activation toggles use the Cloud Guid', () async {
    final storage = await _storageMode(StorageMode.cloud);
    final requests = <({String method, Uri uri, Map<String, dynamic>? body})>[];
    final provider = CloudStaffProvider(
      storage,
      CloudStaffRepository(
        sender: (method, uri, {body}) async {
          requests.add((method: method, uri: uri, body: body));
          if (method == 'PUT') return <String, dynamic>{};
          return _staffListResponse();
        },
      ),
    );

    await provider.updateStaff(
      _staffId,
      const CloudStaffInput(
        name: 'Asha R',
        role: StaffRole.other,
        phone: '9876500001',
        isActive: false,
      ),
    );
    await provider.deactivateStaff(_staffId);
    await provider.reactivateStaff(_staffId);

    final puts = requests.where((r) => r.method == 'PUT').toList();
    expect(puts, hasLength(3));
    for (final put in puts) {
      expect(put.uri.path, '/api/staff/$_staffId');
    }
    expect(puts[0].body, {
      'name': 'Asha R',
      'role': 'Staff',
      'phone': '9876500001',
      'isActive': false,
    });
    expect(puts[1].body, {'isActive': false});
    expect(puts[2].body, {'isActive': true});
  });

  test('Unsupported roles never reach the Cloud API', () async {
    final storage = await _storageMode(StorageMode.cloud);
    var calls = 0;
    final provider = CloudStaffProvider(
      storage,
      CloudStaffRepository(
        sender: (method, uri, {body}) async {
          calls++;
          return <String, dynamic>{};
        },
      ),
    );

    await expectLater(
      provider.createStaff(
        const CloudStaffInput(name: 'Chef', role: StaffRole.chef),
      ),
      throwsA(isA<CloudStaffRoleNotSupportedException>()),
    );
    expect(calls, 0);
  });

  test('403 writes surface a clean permission error', () async {
    final storage = await _storageMode(StorageMode.cloud);
    final provider = CloudStaffProvider(
      storage,
      CloudStaffRepository(
        sender: (method, uri, {body}) async {
          if (method == 'PUT') throw const CloudStaffPermissionException();
          return _staffListResponse();
        },
      ),
    );

    await expectLater(
      provider.deactivateStaff(_staffId),
      throwsA(
        isA<CloudStaffPermissionException>().having(
          (error) => error.message,
          'message',
          contains('company admin'),
        ),
      ),
    );
  });

  test('Local mode blocks every Cloud staff operation', () async {
    final storage = await _storageMode(StorageMode.local);
    final provider = CloudStaffProvider(
      storage,
      CloudStaffRepository(
        sender: (method, uri, {body}) async {
          throw StateError('Cloud staff repository must not run in local mode.');
        },
      ),
    );

    expect(() => provider.loadStaff(), throwsStateError);
    expect(() => provider.searchStaff(), throwsStateError);
    expect(() => provider.getStaff(_staffId), throwsStateError);
    expect(
      () => provider.createStaff(
        const CloudStaffInput(name: 'X', role: StaffRole.designer),
      ),
      throwsStateError,
    );
    expect(
      () => provider.updateStaff(
        _staffId,
        const CloudStaffInput(name: 'X', role: StaffRole.designer),
      ),
      throwsStateError,
    );
    expect(() => provider.deactivateStaff(_staffId), throwsStateError);
    expect(() => provider.reactivateStaff(_staffId), throwsStateError);
  });
}

Future<StorageModeProvider> _storageMode(StorageMode mode) async {
  final provider = StorageModeProvider(StorageModeService());
  await provider.setMode(mode);
  return provider;
}

List<Map<String, dynamic>> _staffListResponse() => [
      {
        'id': _staffId,
        'name': 'Asha',
        'role': 'Designer',
        'email': 'asha@example.com',
        'phone': '9876500001',
        'isActive': true,
        'driverStatus': 'Available',
        'createdAtUtc': '2026-09-01T10:00:00Z',
      },
      {
        'id': '55555555-5555-4555-8555-555555555555',
        'name': 'Bhanu',
        'role': 'Driver',
        'phone': '9876500002',
        'isActive': false,
        'createdAtUtc': '2026-09-02T10:00:00Z',
      },
      {
        'id': '66666666-6666-4666-8666-666666666666',
        'name': 'Zoya',
        'role': 'Admin',
        'phone': '9876500009',
        'isActive': true,
        'createdAtUtc': '2026-09-03T10:00:00Z',
      },
      {
        'id': '',
        'name': 'Ignored',
        'role': 'Designer',
        'isActive': true,
      },
    ];
