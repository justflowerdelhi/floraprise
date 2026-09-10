import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/data/repositories/cloud_order_repository.dart';
import 'package:floraprise/data/repositories/job_repository.dart';
import 'package:floraprise/data/repositories/order_repository.dart';
import 'package:floraprise/managers/order_manager.dart';
import 'package:floraprise/models/order_workspace_models.dart';
import 'package:floraprise/models/storage_mode.dart';
import 'package:floraprise/models/walk_in_session.dart';
import 'package:floraprise/providers/order_provider.dart';
import 'package:floraprise/providers/storage_mode_provider.dart';
import 'package:floraprise/services/storage_mode_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _cloudOrderId = '11111111-1111-4111-8111-111111111111';
const _staffId = '22222222-2222-4222-8222-222222222222';
const _productId = '33333333-3333-4333-8333-333333333333';

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

  test('Cloud mode loads Orders from API', () async {
    final storage = await _storageMode(StorageMode.cloud);
    final localManager = _FakeOrderManager();
    final calls = <Uri>[];
    final provider = OrderProvider(
      localManager,
      storage,
      CloudOrderRepository(
        sender: (method, uri, {body}) async {
          calls.add(uri);
          expect(method, 'GET');
          expect(body, isNull);
          return _workspaceResponse();
        },
      ),
    );

    await provider.loadOrdersForTab('all');

    expect(localManager.workspaceCalls, 0);
    expect(calls, hasLength(1));
    expect(calls.single.path, '/api/v1/mobile/orders/workspace');
    expect(provider.orders, hasLength(1));
    expect(provider.orders.single.cloudOrderId, _cloudOrderId);
    expect(provider.orders.single.orderNo, 'ORD-POS-11');
    expect(provider.orders.single.grandTotalPaise, 30000);
  });

  test('Cloud mode opens detail using Cloud Guid', () async {
    final storage = await _storageMode(StorageMode.cloud);
    final localManager = _FakeOrderManager();
    final calls = <Uri>[];
    final provider = OrderProvider(
      localManager,
      storage,
      CloudOrderRepository(
        sender: (method, uri, {body}) async {
          calls.add(uri);
          expect(body, isNull);
          return _detailResponse();
        },
      ),
    );

    await provider.loadOrderDetailProgressive(-1, cloudOrderId: _cloudOrderId);

    expect(localManager.detailCalls, 0);
    expect(calls, hasLength(1));
    expect(calls.single.path, '/api/v1/mobile/orders/$_cloudOrderId');
    expect(provider.detailHeader?.cloudOrderId, _cloudOrderId);
    expect(provider.detailHeader?.orderNo, 'ORD-POS-11');
    expect(provider.detailBundle?.lines.single['line_total_paise'], 30000);
    expect(provider.detailBundle?.payments.single['amount_paise'], 30000);
  });

  test('Local mode still uses SQLite path through OrderManager', () async {
    final storage = await _storageMode(StorageMode.local);
    final localManager = _FakeOrderManager();
    final provider = OrderProvider(
      localManager,
      storage,
      CloudOrderRepository(
        sender: (method, uri, {body}) async {
          throw StateError('Cloud repository should not be called in local mode.');
        },
      ),
    );

    await provider.loadOrdersForTab('all');
    await provider.loadOrderDetailProgressive(7);

    expect(localManager.workspaceCalls, 1);
    expect(localManager.detailCalls, 3);
    expect(provider.orders.single.id, 7);
    expect(provider.orders.single.cloudOrderId, isNull);
    expect(provider.detailHeader?.id, 7);
    expect(provider.detailHeader?.cloudOrderId, isNull);
  });

  test('Cloud mode does not call local Orders manager', () async {
    final storage = await _storageMode(StorageMode.cloud);
    final localManager = _FakeOrderManager();
    final provider = OrderProvider(
      localManager,
      storage,
      CloudOrderRepository(
        sender: (method, uri, {body}) async {
          if (uri.path.endsWith('/workspace')) return _workspaceResponse();
          return _detailResponse();
        },
      ),
    );

    await provider.loadOrdersForTab('all');
    await provider.loadHistory();
    await provider.loadOrderDetailProgressive(-1, cloudOrderId: _cloudOrderId);

    expect(localManager.workspaceCalls, 0);
    expect(localManager.historyCalls, 0);
    expect(localManager.detailCalls, 0);
  });

  test('Cloud status action uses Cloud Guid and PATCH endpoint', () async {
    final storage = await _storageMode(StorageMode.cloud);
    final localManager = _FakeOrderManager();
    final requests = <({String method, Uri uri, Map<String, dynamic>? body})>[];
    final provider = OrderProvider(
      localManager,
      storage,
      CloudOrderRepository(
        sender: (method, uri, {body}) async {
          requests.add((method: method, uri: uri, body: body));
          if (method == 'PATCH') return <String, dynamic>{};
          if (uri.path.endsWith('/workspace')) return _workspaceResponse();
          return _detailResponse();
        },
      ),
    );

    await provider.updateCloudOrderStatus(
      cloudOrderId: _cloudOrderId,
      newStatus: 'ready',
    );

    expect(localManager.workspaceCalls, 0);
    expect(localManager.detailCalls, 0);
    final patch = requests.singleWhere((request) => request.method == 'PATCH');
    expect(patch.uri.path, '/api/orders/$_cloudOrderId/status');
    expect(patch.body, {'status': 'ReadyForDelivery'});
  });

  test('Cloud cancel action uses Cloud Guid and cancel endpoint', () async {
    final storage = await _storageMode(StorageMode.cloud);
    final localManager = _FakeOrderManager();
    final requests = <({String method, Uri uri, Map<String, dynamic>? body})>[];
    final provider = OrderProvider(
      localManager,
      storage,
      CloudOrderRepository(
        sender: (method, uri, {body}) async {
          requests.add((method: method, uri: uri, body: body));
          if (method == 'POST') return <String, dynamic>{};
          if (uri.path.endsWith('/workspace')) return _workspaceResponse();
          return _detailResponse();
        },
      ),
    );

    await provider.cancelCloudOrder(
      cloudOrderId: _cloudOrderId,
      reason: 'No longer needed',
    );

    expect(localManager.workspaceCalls, 0);
    expect(localManager.detailCalls, 0);
    final post = requests.singleWhere((request) => request.method == 'POST');
    expect(post.uri.path, '/api/orders/$_cloudOrderId/cancel');
    expect(post.body, {'reason': 'No longer needed'});
  });

  test('Cloud designer assignment posts Staff Guid and refreshes detail',
      () async {
    final storage = await _storageMode(StorageMode.cloud);
    final localManager = _FakeOrderManager();
    final requests = <({String method, Uri uri, Map<String, dynamic>? body})>[];
    final provider = OrderProvider(
      localManager,
      storage,
      CloudOrderRepository(
        sender: (method, uri, {body}) async {
          requests.add((method: method, uri: uri, body: body));
          if (method == 'POST') return <String, dynamic>{};
          return _detailResponse();
        },
      ),
    );

    await provider.assignCloudDesigner(
      cloudOrderId: _cloudOrderId,
      staffId: _staffId,
    );

    expect(localManager.detailCalls, 0);
    final post = requests.singleWhere((request) => request.method == 'POST');
    expect(post.uri.path, '/api/orders/$_cloudOrderId/assign-designer');
    expect(post.body, {'staffId': _staffId});
    expect(
      requests.last.uri.path,
      '/api/v1/mobile/orders/$_cloudOrderId',
    );
    expect(provider.detailHeader?.cloudOrderId, _cloudOrderId);
  });

  test('Cloud driver assignment posts Cloud Guid and refreshes detail',
      () async {
    final storage = await _storageMode(StorageMode.cloud);
    final localManager = _FakeOrderManager();
    final requests = <({String method, Uri uri, Map<String, dynamic>? body})>[];
    final provider = OrderProvider(
      localManager,
      storage,
      CloudOrderRepository(
        sender: (method, uri, {body}) async {
          requests.add((method: method, uri: uri, body: body));
          if (method == 'POST') return <String, dynamic>{};
          return _detailResponse();
        },
      ),
    );

    await provider.assignCloudDriver(
      cloudOrderId: _cloudOrderId,
      staffId: _staffId,
    );

    expect(localManager.detailCalls, 0);
    final post = requests.singleWhere((request) => request.method == 'POST');
    expect(post.uri.path, '/api/orders/$_cloudOrderId/assign-driver');
    expect(post.body, {'staffId': _staffId});
    expect(
      requests.last.uri.path,
      '/api/v1/mobile/orders/$_cloudOrderId',
    );
  });

  test('Cloud assignee lists come from Cloud staff APIs', () async {
    final storage = await _storageMode(StorageMode.cloud);
    final calls = <Uri>[];
    final provider = OrderProvider(
      _FakeOrderManager(),
      storage,
      CloudOrderRepository(
        sender: (method, uri, {body}) async {
          calls.add(uri);
          expect(method, 'GET');
          return [
            {
              'id': _staffId,
              'name': 'Asha',
              'role': 'Designer',
              'phone': '9876500001',
              'isActive': true,
            },
            {'id': '', 'name': 'Ignored', 'role': 'Designer'},
          ];
        },
      ),
    );

    final designers = await provider.loadCloudDesigners();
    final drivers = await provider.loadCloudDrivers();

    expect(calls.map((uri) => uri.path).toList(), [
      '/api/staff/by-role/Designer',
      '/api/staff/available-drivers',
    ]);
    expect(designers, hasLength(1));
    expect(designers.single.staffId, _staffId);
    expect(designers.single.name, 'Asha');
    expect(designers.single.phone, '9876500001');
    expect(drivers, hasLength(1));
  });

  test('Cloud payment collection posts to Cloud payments endpoint', () async {
    final storage = await _storageMode(StorageMode.cloud);
    final localManager = _FakeOrderManager();
    final requests = <({String method, Uri uri, Map<String, dynamic>? body})>[];
    final provider = OrderProvider(
      localManager,
      storage,
      CloudOrderRepository(
        sender: (method, uri, {body}) async {
          requests.add((method: method, uri: uri, body: body));
          if (method == 'POST') return <String, dynamic>{};
          return _detailResponse();
        },
      ),
    );

    await provider.collectCloudOrderPayment(
      cloudOrderId: _cloudOrderId,
      method: 'bank_transfer',
      amountPaise: 30050,
    );

    expect(localManager.detailCalls, 0);
    final post = requests.singleWhere((request) => request.method == 'POST');
    expect(post.uri.path, '/api/payments');
    expect(post.body, {
      'orderId': _cloudOrderId,
      'method': 'BankTransfer',
      'amount': 300.5,
      'paymentDate':
          DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day).toIso8601String(),
    });
    expect(requests.last.uri.path, '/api/v1/mobile/orders/$_cloudOrderId');
    expect(provider.detailHeader?.cloudOrderId, _cloudOrderId);
  });

  test('Cloud payment rejects non-positive amounts before any HTTP call',
      () async {
    final storage = await _storageMode(StorageMode.cloud);
    var calls = 0;
    final provider = OrderProvider(
      _FakeOrderManager(),
      storage,
      CloudOrderRepository(
        sender: (method, uri, {body}) async {
          calls++;
          return <String, dynamic>{};
        },
      ),
    );

    await expectLater(
      provider.collectCloudOrderPayment(
        cloudOrderId: _cloudOrderId,
        method: 'cash',
        amountPaise: 0,
      ),
      throwsStateError,
    );
    expect(calls, 0);
  });

  test('Local mode blocks Cloud payment collection', () async {
    final storage = await _storageMode(StorageMode.local);
    final localManager = _FakeOrderManager();
    final provider = OrderProvider(
      localManager,
      storage,
      CloudOrderRepository(
        sender: (method, uri, {body}) async {
          throw StateError('Cloud repository should not be called in local mode.');
        },
      ),
    );

    await expectLater(
      provider.collectCloudOrderPayment(
        cloudOrderId: _cloudOrderId,
        method: 'cash',
        amountPaise: 10000,
      ),
      throwsStateError,
    );
    expect(localManager.paymentCalls, 0);
  });

  test('Cloud edit hits details, items and financials endpoints by Guid',
      () async {
    final storage = await _storageMode(StorageMode.cloud);
    final localManager = _FakeOrderManager();
    final requests = <({String method, Uri uri, Map<String, dynamic>? body})>[];
    final provider = OrderProvider(
      localManager,
      storage,
      CloudOrderRepository(
        sender: (method, uri, {body}) async {
          requests.add((method: method, uri: uri, body: body));
          if (method == 'GET' && uri.path.endsWith('/workspace')) {
            return _workspaceResponse();
          }
          if (method == 'GET') return _detailResponse();
          return <String, dynamic>{};
        },
      ),
    );

    await provider.saveCloudOrderEdit(
      cloudOrderId: _cloudOrderId,
      deliveryDate: DateTime.utc(2026, 10, 1, 9, 30),
      timeSlot: '10:00 - 12:00',
      deliveryAddress: '12 New Street',
      deliveryPincode: '560001',
      recipientName: 'Riya',
      recipientPhone: '9876500002',
      cardMessage: 'Happy Birthday',
      items: const [
        CloudOrderItemInput(
          productId: _productId,
          productName: 'Lily Bunch',
          quantity: 3,
          unitPricePaise: 15000,
          discountAmountPaise: 4500,
          taxRatePercent: 5,
        ),
      ],
      discountAmountPaise: 4000,
      deliveryFeePaise: 6000,
      rewardPointsRedeemed: 25,
      rewardDiscountAmountPaise: 1250,
    );

    expect(localManager.workspaceCalls, 0);
    expect(localManager.detailCalls, 0);

    final patchDetails = requests.singleWhere(
      (request) => request.uri.path.endsWith('/details'),
    );
    expect(patchDetails.method, 'PATCH');
    expect(patchDetails.uri.path, '/api/orders/$_cloudOrderId/details');
    expect(patchDetails.body, {
      'deliveryDate': '2026-10-01T09:30:00.000Z',
      'timeSlot': '10:00 - 12:00',
      'deliveryAddress': '12 New Street',
      'deliveryPincode': '560001',
      'recipientName': 'Riya',
      'recipientPhone': '9876500002',
      'cardMessage': 'Happy Birthday',
    });

    final putItems = requests.singleWhere(
      (request) => request.uri.path.endsWith('/items'),
    );
    expect(putItems.method, 'PUT');
    expect(putItems.uri.path, '/api/orders/$_cloudOrderId/items');
    expect(putItems.body?['taxAmount'], 20.25);
    final line = (putItems.body?['items'] as List).single as Map;
    expect(line['productId'], _productId);
    expect(line['quantity'], 3);
    expect(line['unitPrice'], 150.0);
    expect(line['discountAmount'], 45.0);
    expect(line['lineSubtotal'], 405.0);
    expect(line['lineTaxAmount'], 20.25);

    final patchFinancials = requests.singleWhere(
      (request) => request.uri.path.endsWith('/financials'),
    );
    expect(patchFinancials.method, 'PATCH');
    expect(patchFinancials.body, {
      'discountAmount': 40.0,
      'deliveryFee': 60.0,
      'rewardPointsRedeemed': 25,
      'rewardDiscountAmount': 12.5,
    });

    expect(
      requests.map((request) => request.uri.path).toList(),
      containsAllInOrder([
        '/api/orders/$_cloudOrderId/details',
        '/api/orders/$_cloudOrderId/items',
        '/api/orders/$_cloudOrderId/financials',
        '/api/v1/mobile/orders/$_cloudOrderId',
      ]),
    );
    expect(provider.detailHeader?.cloudOrderId, _cloudOrderId);
  });

  test('Cloud edit omits sections that were not changed', () async {
    final storage = await _storageMode(StorageMode.cloud);
    final requests = <({String method, Uri uri, Map<String, dynamic>? body})>[];
    final provider = OrderProvider(
      _FakeOrderManager(),
      storage,
      CloudOrderRepository(
        sender: (method, uri, {body}) async {
          requests.add((method: method, uri: uri, body: body));
          if (method == 'GET' && uri.path.endsWith('/workspace')) {
            return _workspaceResponse();
          }
          if (method == 'GET') return _detailResponse();
          return <String, dynamic>{};
        },
      ),
    );

    await provider.saveCloudOrderEdit(
      cloudOrderId: _cloudOrderId,
      cardMessage: 'Only this',
    );

    expect(
      requests.where((request) => request.uri.path.endsWith('/items')),
      isEmpty,
    );
    expect(
      requests.where((request) => request.uri.path.endsWith('/financials')),
      isEmpty,
    );
    final patch = requests.singleWhere(
      (request) => request.uri.path.endsWith('/details'),
    );
    expect(patch.body, {'cardMessage': 'Only this'});
  });

  test('Cloud edit rejects an empty item list before any HTTP call', () async {
    final storage = await _storageMode(StorageMode.cloud);
    var calls = 0;
    final provider = OrderProvider(
      _FakeOrderManager(),
      storage,
      CloudOrderRepository(
        sender: (method, uri, {body}) async {
          calls++;
          return <String, dynamic>{};
        },
      ),
    );

    await expectLater(
      provider.saveCloudOrderEdit(
        cloudOrderId: _cloudOrderId,
        items: const [],
      ),
      throwsStateError,
    );
    expect(calls, 0);
  });

  test('Cloud edit failures report the failing endpoint, status and body',
      () async {
    final storage = await _storageMode(StorageMode.cloud);
    final provider = OrderProvider(
      _FakeOrderManager(),
      storage,
      CloudOrderRepository(
        sender: (method, uri, {body}) async {
          if (uri.path.endsWith('/items')) {
            throw const CloudOrderRequestException(
              method: 'PUT',
              path: '/api/orders/$_cloudOrderId/items',
              statusCode: 500,
              serverMessage: 'An unexpected error occurred.',
              responseBody: '{"title":"Server Error","traceId":"abc123"}',
              traceId: 'abc123',
            );
          }
          return <String, dynamic>{};
        },
      ),
    );

    await expectLater(
      provider.saveCloudOrderEdit(
        cloudOrderId: _cloudOrderId,
        cardMessage: 'x',
        items: const [
          CloudOrderItemInput(
            productId: _productId,
            productName: 'Lily',
            quantity: 1,
            unitPricePaise: 10000,
          ),
        ],
      ),
      throwsA(
        isA<CloudOrderRequestException>()
            .having((e) => e.statusCode, 'statusCode', 500)
            .having((e) => e.path, 'path', endsWith('/items'))
            .having((e) => e.method, 'method', 'PUT')
            .having((e) => e.traceId, 'traceId', 'abc123')
            .having(
              (e) => e.toString(),
              'toString',
              allOf(
                contains('PUT'),
                contains('/items'),
                contains('HTTP 500'),
                contains('An unexpected error occurred.'),
                contains('abc123'),
              ),
            ),
      ),
    );
  });

  test('Local mode blocks the Cloud edit path', () async {
    final storage = await _storageMode(StorageMode.local);
    final localManager = _FakeOrderManager();
    final provider = OrderProvider(
      localManager,
      storage,
      CloudOrderRepository(
        sender: (method, uri, {body}) async {
          throw StateError('Cloud repository should not be called in local mode.');
        },
      ),
    );

    await expectLater(
      provider.saveCloudOrderEdit(
        cloudOrderId: _cloudOrderId,
        cardMessage: 'nope',
      ),
      throwsStateError,
    );
    expect(localManager.updateCalls, 0);
  });

  test('Local mode blocks Cloud assignment paths', () async {
    final storage = await _storageMode(StorageMode.local);
    final provider = OrderProvider(
      _FakeOrderManager(),
      storage,
      CloudOrderRepository(
        sender: (method, uri, {body}) async {
          throw StateError('Cloud repository should not be called in local mode.');
        },
      ),
    );

    expect(
      () => provider.assignCloudDesigner(
        cloudOrderId: _cloudOrderId,
        staffId: _staffId,
      ),
      throwsStateError,
    );
    expect(
      () => provider.assignCloudDriver(
        cloudOrderId: _cloudOrderId,
        staffId: _staffId,
      ),
      throwsStateError,
    );
    expect(() => provider.loadCloudDesigners(), throwsStateError);
    expect(() => provider.loadCloudDrivers(), throwsStateError);
  });
}

Future<StorageModeProvider> _storageMode(StorageMode mode) async {
  final provider = StorageModeProvider(StorageModeService());
  await provider.setMode(mode);
  return provider;
}

class _FakeOrderManager extends OrderManager {
  _FakeOrderManager() : super(OrderRepository(), JobRepository());

  int workspaceCalls = 0;
  int historyCalls = 0;
  int detailCalls = 0;
  int paymentCalls = 0;
  int updateCalls = 0;

  @override
  Future<void> updateExistingOrder({
    required int orderId,
    required WalkInSession session,
    required OrderTotals totals,
    required int? customerId,
    String? cloudCustomerId,
  }) async {
    updateCalls++;
  }

  @override
  Future<void> collectOrderPayment({
    required int orderId,
    required String method,
    required int amountPaise,
    String? reference,
  }) async {
    paymentCalls++;
  }

  @override
  Future<List<OrderListItem>> getOrdersForWorkspace({
    required String tab,
    required String searchQuery,
    required OrderWorkspaceFilters filters,
  }) async {
    workspaceCalls++;
    return [
      OrderListItem(
        id: 7,
        orderNo: 'LOCAL-7',
        customerName: 'Local Customer',
        customerPhone: '999',
        recipientName: 'Local Recipient',
        source: 'walkIn',
        fulfilmentType: 'take_away',
        status: 'confirmed',
        grandTotalPaise: 7000,
        createdAt: DateTime(2026, 9, 6),
        scheduledAt: null,
        isPaid: 1,
      ),
    ];
  }

  @override
  Future<List<OrderListItem>> getHistory({int limit = 100, int offset = 0}) async {
    historyCalls++;
    return getOrdersForWorkspace(
      tab: 'all',
      searchQuery: '',
      filters: OrderWorkspaceFilters.empty,
    );
  }

  @override
  Future<OrderDetailHeader?> getOrderDetailHeader(int orderId) async {
    detailCalls++;
    return OrderDetailHeader(
      id: orderId,
      orderNo: 'LOCAL-$orderId',
      status: 'confirmed',
      customerName: 'Local Customer',
      customerPhone: '999',
      recipientName: 'Local Recipient',
      recipientPhone: '888',
      fulfilmentType: 'take_away',
      source: 'walkIn',
      grandTotalPaise: 7000,
      address: '-',
      scheduledAt: null,
      occasion: '-',
      deliverySlot: '-',
      cardMessage: '',
      isPaid: 1,
      paidAmountPaise: 7000,
    );
  }

  @override
  Future<OrderDetailBundle?> getOrderDetailBundle(int orderId) async {
    detailCalls++;
    final header = await getOrderDetailHeader(orderId);
    return header == null
        ? null
        : OrderDetailBundle(
            header: header,
            lines: const [],
            payments: const [],
            timeline: const [],
            schedulerTasks: const [],
            inventoryTransactions: const [],
            receiptStatus: null,
            whatsappStatus: null,
            relayInfo: const {},
            corporateInfo: const {},
            marketplaceInfo: const {},
          );
  }
}

Map<String, dynamic> _workspaceResponse() => {
      'items': [
        {
          'id': _cloudOrderId,
          'orderNumber': 'ORD-POS-11',
          'customerName': 'Cloud Customer',
          'customerPhone': '9876543210',
          'recipientName': 'Cloud Recipient',
          'recipientPhone': '9988776655',
          'fulfilmentType': 'take_away',
          'status': 'confirmed',
          'paymentStatus': 'Paid',
          'totalAmount': 300,
          'paidAmount': 300,
          'balanceDue': 0,
          'orderDate': '2026-09-06T10:00:00Z',
          'deliveryDate': '2026-09-06T10:00:00Z',
          'designerName': null,
          'deliveryPersonName': null,
        },
      ],
      'totalCount': 1,
      'page': 1,
      'pageSize': 50,
    };

Map<String, dynamic> _detailResponse() => {
      'id': _cloudOrderId,
      'orderNumber': 'ORD-POS-11',
      'customerId': '22222222-2222-4222-8222-222222222222',
      'customerName': 'Cloud Customer',
      'customerPhone': '9876543210',
      'recipientName': 'Cloud Recipient',
      'recipientPhone': '9988776655',
      'fulfilmentType': 'take_away',
      'status': 'confirmed',
      'paymentStatus': 'Paid',
      'fulfillmentStatus': 'Completed',
      'orderSource': 'WalkIn',
      'subTotal': 300,
      'deliveryFee': 0,
      'taxAmount': 0,
      'discountAmount': 0,
      'totalAmount': 300,
      'paidAmount': 300,
      'balanceDue': 0,
      'rewardPointsEarned': 0,
      'rewardPointsRedeemed': 0,
      'orderDate': '2026-09-06T10:00:00Z',
      'deliveryDate': '2026-09-06T10:00:00Z',
      'deliveryAddress': '',
      'deliveryPincode': '',
      'timeSlot': '',
      'items': [
        {
          'id': '33333333-3333-4333-8333-333333333333',
          'productId': '44444444-4444-4444-8444-444444444444',
          'productName': 'Cloud Rose',
          'quantity': 1,
          'unitPrice': 300,
          'totalPrice': 300,
          'discountAmount': 0,
          'lineSubtotal': 300,
          'lineTaxAmount': 0,
          'lineTotal': 300,
        },
      ],
      'payments': [
        {
          'id': '55555555-5555-4555-8555-555555555555',
          'orderId': _cloudOrderId,
          'method': 'Cash',
          'amount': 300,
          'status': 'Approved',
          'createdAtUtc': '2026-09-06T10:01:00Z',
        },
      ],
      'deliverySummary': null,
      'timeline': [
        {
          'source': 'order',
          'status': 'confirmed',
          'notes': null,
          'createdAtUtc': '2026-09-06T10:00:00Z',
        },
      ],
      'createdAtUtc': '2026-09-06T10:00:00Z',
    };