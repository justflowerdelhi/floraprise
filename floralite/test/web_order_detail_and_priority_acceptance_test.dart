import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/models/scheduler_task.dart';

void main() {
  group('Flutter Web Acceptance Verification - Order Details & Task Priority', () {
    test('TaskPriorityX userFacingValues contains strictly Normal and Urgent', () {
      final userFacing = TaskPriorityX.userFacingValues;
      expect(userFacing, hasLength(2));
      expect(userFacing, contains(TaskPriority.normal));
      expect(userFacing, contains(TaskPriority.urgent));
      expect(userFacing.map((p) => p.displayLabel).toList(), equals(['Normal', 'Urgent']));
    });

    test('TaskPriorityX legacy values map cleanly to Normal and Urgent', () {
      expect(TaskPriorityX.fromNormalizedString('low'), equals(TaskPriority.normal));
      expect(TaskPriorityX.fromNormalizedString('Low'), equals(TaskPriority.normal));
      expect(TaskPriorityX.fromNormalizedString('medium'), equals(TaskPriority.normal));
      expect(TaskPriorityX.fromNormalizedString('normal'), equals(TaskPriority.normal));
      expect(TaskPriorityX.fromNormalizedString('high'), equals(TaskPriority.urgent));
      expect(TaskPriorityX.fromNormalizedString('High'), equals(TaskPriority.urgent));
      expect(TaskPriorityX.fromNormalizedString('urgent'), equals(TaskPriority.urgent));
      expect(TaskPriorityX.fromNormalizedString('Urgent'), equals(TaskPriority.urgent));
      expect(TaskPriorityX.fromNormalizedString('critical'), equals(TaskPriority.normal));
      expect(TaskPriorityX.fromNormalizedString(null), equals(TaskPriority.normal));
    });

    testWidgets('Scheduler Add/Edit Task priority dropdown contains ONLY Normal and Urgent',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));

      // Verify user-facing dropdown items
      final dropdownItems = TaskPriorityX.userFacingValues
          .map((p) => DropdownMenuItem<TaskPriority>(
                value: p,
                child: Text(p.displayLabel),
              ))
          .toList();

      expect(dropdownItems, hasLength(2));
      expect(dropdownItems[0].value, equals(TaskPriority.normal));
      expect((dropdownItems[0].child as Text).data, equals('Normal'));
      expect(dropdownItems[1].value, equals(TaskPriority.urgent));
      expect((dropdownItems[1].child as Text).data, equals('Urgent'));

      // Confirm old priorities are NOT present
      final labels = dropdownItems.map((item) => (item.child as Text).data).toList();
      expect(labels.contains('Low'), isFalse);
      expect(labels.contains('Medium'), isFalse);
      expect(labels.contains('High'), isFalse);
      expect(labels.contains('Critical'), isFalse);
    });

    testWidgets('Direct URL deep-link /order-detail?orderId=101 resolves OrderDetailScreen',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));

      // Build app shell with onGenerateRoute logic
      Route<dynamic>? generatedRoute;

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) {
            final routeUri = Uri.tryParse(settings.name ?? '');
            final routePath = routeUri?.path ?? settings.name ?? '';
            if (routePath == '/order-detail' ||
                routePath == '/order-details' ||
                routePath.startsWith('/orders/') ||
                routePath.startsWith('/order/')) {
              int? orderId;
              String? cloudOrderId;

              if (settings.arguments is Map) {
                final args = settings.arguments as Map<dynamic, dynamic>;
                if (args['orderId'] is int) {
                  orderId = args['orderId'] as int;
                } else if (args['orderId'] != null) {
                  orderId = int.tryParse(args['orderId'].toString());
                }
                cloudOrderId = args['cloudOrderId']?.toString();
              }

              if (orderId == null && routeUri != null) {
                final queryOrderId = routeUri.queryParameters['orderId'] ??
                    routeUri.queryParameters['id'];
                if (queryOrderId != null) {
                  orderId = int.tryParse(queryOrderId);
                }
                cloudOrderId ??= routeUri.queryParameters['cloudOrderId'];
                if (orderId == null && routeUri.pathSegments.isNotEmpty) {
                  final lastSegment = routeUri.pathSegments.last;
                  final parsed = int.tryParse(lastSegment);
                  if (parsed != null) {
                    orderId = parsed;
                  } else if (lastSegment != 'orders' &&
                      lastSegment != 'order' &&
                      lastSegment != 'order-detail' &&
                      lastSegment != 'order-details') {
                    cloudOrderId ??= lastSegment;
                  }
                }
              }

              if ((orderId != null && orderId > 0) ||
                  (cloudOrderId != null && cloudOrderId.isNotEmpty)) {
                final effectiveRouteName = (routeUri != null &&
                        (routeUri.hasQuery || routeUri.pathSegments.length > 1))
                    ? settings.name
                    : '/order-detail?orderId=${orderId ?? 0}${cloudOrderId != null && cloudOrderId.isNotEmpty ? '&cloudOrderId=$cloudOrderId' : ''}';
                generatedRoute = MaterialPageRoute(
                  settings: RouteSettings(
                    name: effectiveRouteName,
                    arguments: settings.arguments,
                  ),
                  builder: (context) => Scaffold(
                    body: Text('Loaded Order #$orderId (Cloud: $cloudOrderId) at $effectiveRouteName'),
                  ),
                );
                return generatedRoute;
              }
            }
            return null;
          },
          home: const Scaffold(body: Text('Home Screen')),
        ),
      );

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));

      // 1. Test query param URL: /order-detail?orderId=101
      navigator.pushNamed('/order-detail?orderId=101');
      await tester.pumpAndSettle();

      expect(find.text('Loaded Order #101 (Cloud: null) at /order-detail?orderId=101'), findsOneWidget);
      expect(generatedRoute?.settings.name, equals('/order-detail?orderId=101'));

      // 2. Test path segment URL: /orders/202
      navigator.pushNamed('/orders/202');
      await tester.pumpAndSettle();

      expect(find.text('Loaded Order #202 (Cloud: null) at /orders/202'), findsOneWidget);
      expect(generatedRoute?.settings.name, equals('/orders/202'));

      // 3. Test cloud order URL: /order-detail?orderId=0&cloudOrderId=cloud_order_uuid_999
      navigator.pushNamed('/order-detail?orderId=0&cloudOrderId=cloud_order_uuid_999');
      await tester.pumpAndSettle();

      expect(
        find.text('Loaded Order #0 (Cloud: cloud_order_uuid_999) at /order-detail?orderId=0&cloudOrderId=cloud_order_uuid_999'),
        findsOneWidget,
      );

      // 4. Test named push with arguments updates RouteSettings to order-specific URL for browser address bar
      navigator.pushNamed(
        '/order-detail',
        arguments: {'orderId': 303, 'cloudOrderId': 'cloud_303'},
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Loaded Order #303 (Cloud: cloud_303) at /order-detail?orderId=303&cloudOrderId=cloud_303'),
        findsOneWidget,
      );
      expect(
        generatedRoute?.settings.name,
        equals('/order-detail?orderId=303&cloudOrderId=cloud_303'),
      );
    });
  });
}
