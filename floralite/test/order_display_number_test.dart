import 'package:floraprise/models/order_workspace_models.dart';
import 'package:floraprise/utils/order_display_utils.dart';
import 'package:floraprise/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderDisplayUtils & displayOrderNo formatting', () {
    test('existing short order numbers display normally without modification', () {
      expect(formatDisplayOrderNo('ORD-101'), 'ORD-101');
      expect(formatDisplayOrderNo('ORD-POS-11'), 'ORD-POS-11');
      expect(formatDisplayOrderNo('ORD-POS-300'), 'ORD-POS-300');
      expect(formatDisplayOrderNo('123'), '123');
      expect(formatDisplayOrderNo('#42'), '#42');
      expect(formatDisplayOrderNo('ORD-2024-001'), 'ORD-2024-001');
      // Local mode timestamp format
      expect(formatDisplayOrderNo('ORD-1725983721000'), 'ORD-1725983721000');
    });

    test('long UUID-style order IDs are formatted into compact human-readable display values', () {
      const longUuidOrderNo =
          'ORD-POS-70b35907-e3e2-4dfb-9ed8-ae3c8833918a';
      expect(formatDisplayOrderNo(longUuidOrderNo), 'ORD-POS-70B35907');

      const ordUuid = 'ORD-70b35907-e3e2-4dfb-9ed8-ae3c8833918a';
      expect(formatDisplayOrderNo(ordUuid), 'ORD-70B35907');

      const rawUuid = '70b35907-e3e2-4dfb-9ed8-ae3c8833918a';
      expect(formatDisplayOrderNo(rawUuid), 'Order #70B35907');

      const hex32OrderNo = 'ORD-POS-70b35907e3e24dfb9ed8ae3c8833918a';
      expect(formatDisplayOrderNo(hex32OrderNo), 'ORD-POS-70B35907');
    });

    test('fallback when orderNo is empty, null, or "-"', () {
      expect(formatDisplayOrderNo(null, orderId: 123), 'Order #123');
      expect(formatDisplayOrderNo('', orderId: 123), 'Order #123');
      expect(formatDisplayOrderNo('   ', orderId: 456), 'Order #456');
      expect(formatDisplayOrderNo('-', orderId: 789), 'Order #789');
      expect(formatDisplayOrderNo(null), '-');
      expect(formatDisplayOrderNo(''), '-');
      expect(formatDisplayOrderNo('-'), '-');
    });

    test('OrderListItem and OrderDetailHeader preserve internal orderNo while exposing displayOrderNo', () {
      const longClientSyncOrderNo =
          'ORD-POS-70b35907-e3e2-4dfb-9ed8-ae3c8833918a';

      final item = OrderListItem(
        id: 99999999,
        cloudOrderId: 'cloud-guid-1',
        orderNo: longClientSyncOrderNo,
        customerName: 'Alice',
        customerPhone: '9876543210',
        recipientName: 'Bob',
        source: 'cloud',
        fulfilmentType: 'delivery',
        status: 'confirmed',
        grandTotalPaise: 250000,
        createdAt: DateTime(2026, 9, 10),
        scheduledAt: DateTime(2026, 9, 11),
        isPaid: 1,
      );

      // Internal orderNo / ClientSyncId string MUST remain unchanged
      expect(item.orderNo, longClientSyncOrderNo);
      expect(item.orderNo, contains('70b35907-e3e2-4dfb-9ed8-ae3c8833918a'));

      // User-facing displayOrderNo is short and human-readable
      expect(item.displayOrderNo, 'ORD-POS-70B35907');

      final header = OrderDetailHeader(
        id: 99999999,
        cloudOrderId: 'cloud-guid-1',
        orderNo: longClientSyncOrderNo,
        status: 'confirmed',
        customerName: 'Alice',
        customerPhone: '9876543210',
        recipientName: 'Bob',
        recipientPhone: '9876543210',
        fulfilmentType: 'delivery',
        source: 'cloud',
        grandTotalPaise: 250000,
        address: 'MG Road, Bengaluru',
        scheduledAt: DateTime(2026, 9, 11),
        occasion: 'Birthday',
        deliverySlot: 'Evening',
        cardMessage: 'Happy Birthday!',
        isPaid: 1,
        paidAmountPaise: 250000,
      );

      // Internal header orderNo remains unchanged
      expect(header.orderNo, longClientSyncOrderNo);
      // User-facing displayOrderNo is short and human-readable
      expect(header.displayOrderNo, 'ORD-POS-70B35907');
    });
  });

  group('Order card layout responsiveness & overflow prevention', () {
    testWidgets('Long UUID order ID does not cause layout overflow on narrow mobile screens (320px & 360px)', (tester) async {
      // Set a narrow mobile screen size (360x640)
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const longClientSyncOrderNo =
          'ORD-POS-70b35907-e3e2-4dfb-9ed8-ae3c8833918a';

      final item = OrderListItem(
        id: 12345,
        cloudOrderId: 'cloud-order-guid',
        orderNo: longClientSyncOrderNo,
        customerName: 'John Doe',
        customerPhone: '9876543210',
        recipientName: 'Jane Smith',
        source: 'cloud',
        fulfilmentType: 'delivery',
        status: 'confirmed',
        grandTotalPaise: 150000,
        createdAt: DateTime.now(),
        scheduledAt: DateTime.now().add(const Duration(days: 1)),
        isPaid: 1,
      );

      // Build the Order card header row as implemented in OrdersScreen
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.displayOrderNo,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const StatusChip(
                        label: 'Confirmed',
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Verify no overflow exception was thrown
      expect(tester.takeException(), isNull);

      // Verify the formatted compact identifier is displayed
      expect(find.text('ORD-POS-70B35907'), findsOneWidget);
      expect(find.text(longClientSyncOrderNo), findsNothing);

      // Test on even narrower 300px width
      tester.view.physicalSize = const Size(300, 640);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
