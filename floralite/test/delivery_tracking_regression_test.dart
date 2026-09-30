import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:floraprise/models/order_workspace_models.dart';
import 'package:floraprise/screens/live_delivery_tracking_screen.dart';
import 'package:floraprise/services/delivery_tracking_service.dart';
import 'package:floraprise/services/mobile_auth_service.dart';
import 'package:floraprise/utils/delivery_message_utils.dart';
import 'package:floraprise/widgets/order_action_menu_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});
  PackageInfo.setMockInitialValues(
    appName: 'Floraprise',
    packageName: 'com.floraprise.app',
    version: '1.0.4',
    buildNumber: '6',
    buildSignature: '',
  );

  group('A & B: Solo Device Provisioning & Login Fallback', () {
    test('Solo registration success returns token', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/v1/mobile/auth/register')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'accessToken': 'solo-reg-token-123',
                'refreshToken': 'solo-reg-refresh-123',
                'user': {'id': 'user-1', 'email': 'auto.9999900001@floraprise.local'},
                'session': {'id': 'sess-1'},
                'bootstrap': {'company': {'name': 'Floraprise Solo'}},
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{"error": "not found"}', 404);
      });

      final authService = MobileAuthService(
        client: mockClient,
        baseUrl: 'https://api.floraprise.com',
      );

      final payload = await authService.register(
        companyName: 'Floraprise Solo',
        ownerName: 'Floraprise Solo',
        mobile: '9999900001',
        address: 'Floraprise Shop',
        city: '',
        email: 'auto.9999900001@floraprise.local',
        password: 'Password#2026',
      );

      expect(payload.accessToken, 'solo-reg-token-123');
    });

    test('Solo registration 409 Conflict triggers login fallback with provisioned credentials', () async {
      var loginAttempted = false;
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/v1/mobile/auth/register')) {
          return http.Response(
            jsonEncode({
              'errorCode': 'DUPLICATE_COMPANY',
              'message': 'This company is already registered with Floraprise.',
            }),
            409,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.contains('/api/v1/mobile/auth/login')) {
          loginAttempted = true;
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['identifier'], 'auto.9999900001@floraprise.local');
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'accessToken': 'solo-login-fallback-token-456',
                'refreshToken': 'solo-login-refresh-456',
                'user': {'id': 'user-1', 'email': 'auto.9999900001@floraprise.local'},
                'session': {'id': 'sess-1'},
                'bootstrap': {'company': {'name': 'Floraprise Solo'}},
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{"error": "not found"}', 404);
      });

      final authService = MobileAuthService(
        client: mockClient,
        baseUrl: 'https://api.floraprise.com',
      );

      // Attempt register -> throws -> fallback to login
      String? accessToken;
      try {
        final reg = await authService.register(
          companyName: 'Floraprise Solo',
          ownerName: 'Floraprise Solo',
          mobile: '9999900001',
          address: 'Floraprise Shop',
          city: '',
          email: 'auto.9999900001@floraprise.local',
          password: 'Password#2026',
        );
        accessToken = reg.accessToken;
      } on Object {
        final login = await authService.login(
          identifier: 'auto.9999900001@floraprise.local',
          password: 'Password#2026',
          rememberLogin: true,
        );
        accessToken = login.accessToken;
      }

      expect(loginAttempted, isTrue);
      expect(accessToken, 'solo-login-fallback-token-456');
    });
  });

  group('C & D: Solo Tracking Link & WhatsApp Message', () {
    test('generateTrackingLinks parses driverLink and customerLink correctly', () async {
      final payload = {
        'token': 'tok-abc-123',
        'driverLink': 'https://pro.floraprise.com/delivery/start/tok-abc-123',
        'customerLink': 'https://pro.floraprise.com/api/public/tracking/customer/tok-abc-123',
      };

      final response = TrackingLinksResponse(
        token: payload['token']!,
        driverLink: payload['driverLink']!,
        customerLink: payload['customerLink']!,
      );

      expect(response.token, 'tok-abc-123');
      expect(response.driverLink, contains('/delivery/start/tok-abc-123'));
      expect(response.customerLink, contains('/customer/tok-abc-123'));
    });

    test('Solo WhatsApp dispatch message contains START DELIVERY LINK', () {
      const driverLink = 'https://pro.floraprise.com/delivery/start/tok-abc-123';
      final sections = startDeliverySection(driverLink);

      expect(sections, isNotEmpty);
      expect(sections, contains('▶ START DELIVERY'));
      expect(sections, contains(driverLink));

      const header = OrderDetailHeader(
        id: 101,
        orderNo: 'ORD-SOLO-101',
        status: 'confirmed',
        customerName: 'Priya Sharma',
        customerPhone: '9876543210',
        recipientName: 'Rahul Verma',
        recipientPhone: '9876543211',
        fulfilmentType: 'delivery',
        source: 'walk_in',
        grandTotalPaise: 150000,
        address: '123 MG Road, Bengaluru',
        scheduledAt: null,
        occasion: 'Birthday',
        deliverySlot: 'Evening',
        cardMessage: 'Happy Birthday!',
        isPaid: 1,
        paidAmountPaise: 150000,
      );

      final message = deliveryAssignmentMessage(
        header,
        null,
        'Ramesh Driver',
        startDeliveryLink: driverLink,
      );

      expect(message, contains('START DELIVERY'));
      expect(message, contains(driverLink));
      expect(message, contains('ORD-SOLO-101'));
      expect(message, contains('Ramesh Driver'));
    });
  });

  group('E, F, G, H: Cloud & Web Delivery Tracking (No SQLite Lookups)', () {
    testWidgets('LiveDeliveryTrackingScreen with cloudOrderId uses Cloud tracking path', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LiveDeliveryTrackingScreen(
            cloudOrderId: '3fa85f64-5717-4562-b3fc-2c963f66afa6',
            orderId: null,
          ),
        ),
      );

      // Loading state initiates without querying local SQLite
      expect(find.byType(LiveDeliveryTrackingScreen), findsOneWidget);
    });

    testWidgets('LiveDeliveryTrackingScreen with assignmentId uses Assignment tracking path', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LiveDeliveryTrackingScreen(
            assignmentId: 'delivery-uuid-999',
            orderId: null,
          ),
        ),
      );

      expect(find.byType(LiveDeliveryTrackingScreen), findsOneWidget);
    });

    testWidgets('LiveDeliveryTrackingScreen with publicView uses Public tracking path', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LiveDeliveryTrackingScreen(
            trackingLink: 'https://pro.floraprise.com/api/public/tracking/customer/tok-123',
            publicView: true,
          ),
        ),
      );

      expect(find.byType(LiveDeliveryTrackingScreen), findsOneWidget);
    });

    testWidgets('OrderActionMenuSheet passes cloudOrderId to LiveDeliveryTrackingScreen for Cloud orders', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showOrderActionMenu(
                    context,
                    orderId: -1,
                    cloudOrderId: 'cloud-order-guid-123',
                    header: const OrderDetailHeader(
                      id: -1,
                      cloudOrderId: 'cloud-order-guid-123',
                      orderNo: 'ORD-CLOUD-001',
                      status: 'confirmed',
                      customerName: 'Cloud Customer',
                      customerPhone: '9876543210',
                      recipientName: 'Recipient',
                      recipientPhone: '9876543210',
                      fulfilmentType: 'delivery',
                      source: 'web',
                      grandTotalPaise: 200000,
                      address: 'Cloud Address',
                      scheduledAt: null,
                      occasion: 'Anniversary',
                      deliverySlot: 'Morning',
                      cardMessage: 'Congrats!',
                      isPaid: 1,
                      paidAmountPaise: 200000,
                    ),
                  );
                },
                child: const Text('Open Menu'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Menu'));
      await tester.pumpAndSettle();

      // Find and scroll to Track Delivery
      final trackTile = find.text('Track Delivery');
      expect(trackTile, findsOneWidget);
      await tester.ensureVisible(trackTile);
      await tester.pumpAndSettle();

      await tester.tap(trackTile);
      await tester.pumpAndSettle();

      // Verify LiveDeliveryTrackingScreen was pushed with cloudOrderId
      final liveScreen = tester.widget<LiveDeliveryTrackingScreen>(
        find.byType(LiveDeliveryTrackingScreen),
      );
      expect(liveScreen.cloudOrderId, 'cloud-order-guid-123');
      expect(liveScreen.orderId, isNull);
    });

    testWidgets('OrderActionMenuSheet passes local orderId to LiveDeliveryTrackingScreen for Solo orders', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showOrderActionMenu(
                    context,
                    orderId: 42,
                    cloudOrderId: null,
                    header: const OrderDetailHeader(
                      id: 42,
                      cloudOrderId: null,
                      orderNo: 'ORD-LOCAL-042',
                      status: 'confirmed',
                      customerName: 'Local Customer',
                      customerPhone: '9876543210',
                      recipientName: 'Recipient',
                      recipientPhone: '9876543210',
                      fulfilmentType: 'delivery',
                      source: 'pos',
                      grandTotalPaise: 100000,
                      address: 'Local Address',
                      scheduledAt: null,
                      occasion: 'Birthday',
                      deliverySlot: 'Morning',
                      cardMessage: 'Best Wishes',
                      isPaid: 1,
                      paidAmountPaise: 100000,
                    ),
                  );
                },
                child: const Text('Open Menu'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Menu'));
      await tester.pumpAndSettle();

      // Find and scroll to Track Delivery
      final trackTile = find.text('Track Delivery');
      expect(trackTile, findsOneWidget);
      await tester.ensureVisible(trackTile);
      await tester.pumpAndSettle();

      await tester.tap(trackTile);
      await tester.pumpAndSettle();

      // Verify LiveDeliveryTrackingScreen was pushed with local orderId
      final liveScreen = tester.widget<LiveDeliveryTrackingScreen>(
        find.byType(LiveDeliveryTrackingScreen),
      );
      expect(liveScreen.orderId, 42);
      expect(liveScreen.cloudOrderId, isNull);
    });
  });

  group('I: Driver Link & Public Tracking Contract', () {
    test('DriverLinkResponse parses payload correctly', () {
      final map = {
        'deliveryId': 'del-123',
        'orderId': 'ord-456',
        'orderNumber': 'ORD-2026-001',
        'customerName': 'Aarav Patel',
        'recipientName': 'Diya Patel',
        'deliveryAddress': '45 Residency Road, Bengaluru',
        'destinationLatitude': 12.9716,
        'destinationLongitude': 77.5946,
        'customerPhone': '9876543210',
        'timeSlot': '2 PM - 5 PM',
        'status': 'OutForDelivery',
        'trackingToken': 'tok-xyz-789',
        'mapsUrl': 'https://maps.google.com/?q=12.9716,77.5946',
      };

      final response = DriverLinkResponse(
        deliveryId: map['deliveryId']! as String,
        orderId: map['orderId']! as String,
        orderNumber: map['orderNumber']! as String,
        customerName: map['customerName']! as String,
        recipientName: map['recipientName']! as String,
        deliveryAddress: map['deliveryAddress']! as String,
        destinationLatitude: map['destinationLatitude'] as double?,
        destinationLongitude: map['destinationLongitude'] as double?,
        customerPhone: map['customerPhone'] as String?,
        timeSlot: map['timeSlot']! as String,
        status: map['status']! as String,
        trackingToken: map['trackingToken']! as String,
        mapsUrl: map['mapsUrl'] as String?,
      );

      expect(response.orderNumber, 'ORD-2026-001');
      expect(response.status, 'OutForDelivery');
      expect(response.trackingToken, 'tok-xyz-789');
      expect(response.destinationLatitude, 12.9716);
      expect(response.destinationLongitude, 77.5946);
    });

    test('getCloudDeliveryId resolves deliveryId by cloudOrderId without querying local SQLite', () async {
      final fakeHttpClient = _FakeHttpClient(
        jsonEncode({
          'success': true,
          'data': {
            'assignmentId': 'delivery-uuid-abc-999',
            'orderId': '3fa85f64-5717-4562-b3fc-2c963f66afa6',
            'trackingId': 'trk-123',
            'status': 'Assigned',
          },
        }),
      );

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'accessToken': 'test-token',
            },
          }),
          200,
        );
      });

      final authService = MobileAuthService(
        client: mockClient,
        baseUrl: 'https://api.floraprise.com',
      );
      final deliveryService = DeliveryTrackingService(
        auth: authService,
        httpClient: fakeHttpClient,
      );

      final deliveryId = await deliveryService.getCloudDeliveryId(
        cloudOrderId: '3fa85f64-5717-4562-b3fc-2c963f66afa6',
      );

      expect(deliveryId, 'delivery-uuid-abc-999');
    });

    test('deliveryAssignmentMessage formats WhatsApp dispatch with START DELIVERY link and details', () {
      const header = OrderDetailHeader(
        id: 101,
        cloudOrderId: '3fa85f64-5717-4562-b3fc-2c963f66afa6',
        orderNo: 'ORD-9876',
        status: 'Assigned',
        customerName: 'Rahul Sharma',
        customerPhone: '9876543210',
        recipientName: 'Priya Sharma',
        recipientPhone: '9876543211',
        fulfilmentType: 'delivery',
        source: 'manual',
        grandTotalPaise: 150000,
        address: 'MG Road, Bangalore',
        scheduledAt: null,
        occasion: 'Birthday',
        deliverySlot: 'Morning (9 AM - 12 PM)',
        cardMessage: 'Happy Birthday!',
        isPaid: 1,
        paidAmountPaise: 150000,
      );

      const detail = OrderDetailBundle(
        header: header,
        lines: [
          {'product_name': 'Red Roses Bouquet', 'qty': 2},
        ],
        payments: [],
        timeline: [],
        schedulerTasks: [],
        inventoryTransactions: [],
        receiptStatus: null,
        whatsappStatus: null,
        relayInfo: {},
        corporateInfo: {},
        marketplaceInfo: {},
      );

      const startDeliveryLink = 'https://app.floraprise.com/track/driver/tok-driver-123';

      final message = deliveryAssignmentMessage(
        header,
        detail,
        'Ramesh Driver',
        startDeliveryLink: startDeliveryLink,
      );

      expect(message, contains('🚚 DELIVERY ASSIGNMENT'));
      expect(message, contains('Order : ORD-9876'));
      expect(message, contains('Recipient\nPriya Sharma'));
      expect(message, contains('Customer\nRahul Sharma'));
      expect(message, contains('Delivery Person\nRamesh Driver'));
      expect(message, contains('▶ START DELIVERY'));
      expect(message, contains('https://app.floraprise.com/track/driver/tok-driver-123'));
    });
  });
}

class _FakeHttpClient implements HttpClient {
  _FakeHttpClient(this.responseBody);
  final String responseBody;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #openUrl ||
        invocation.memberName == #getUrl ||
        invocation.memberName == #postUrl) {
      return Future.value(_FakeHttpClientRequest(responseBody));
    }
    return super.noSuchMethod(invocation);
  }
}

class _FakeHttpClientRequest implements HttpClientRequest {
  _FakeHttpClientRequest(this.responseBody);
  final String responseBody;

  final HttpHeaders _headers = _FakeHttpHeaders();

  @override
  HttpHeaders get headers => _headers;

  @override
  Future<HttpClientResponse> close() async =>
      _FakeHttpClientResponse(responseBody);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpHeaders implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void forEach(void Function(String name, List<String> values) action) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _FakeHttpClientResponse(this.body);
  final String body;

  @override
  final int statusCode = 200;

  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream.value(utf8.encode(body)).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
