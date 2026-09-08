import 'package:floraprise/models/order_workspace_models.dart';
import 'package:floraprise/utils/delivery_message_utils.dart';
import 'package:floraprise/utils/whatsapp_phone_utils.dart';
import 'package:flutter_test/flutter_test.dart';

const _cloudOrderId = '11111111-1111-4111-8111-111111111111';
const _driverLink = 'https://mobile.floraprise.com/track/driver/abc123XYZ';

void main() {
  group('Cloud designer WhatsApp message', () {
    test('matches the existing designer format using Cloud data only', () {
      final message = designerAssignmentMessage(
        _cloudHeader(),
        _cloudDetail(),
        'Asha',
      );

      expect(message, '''
🌸 NEW DESIGN ORDER

Order : ORD-POS-11

Recipient
Cloud Recipient

Customer
Cloud Customer

Delivery
20/9/2026
10:00 - 12:00

Designer
Asha

Products
✅ 2 × Rose Bunch
✅ 1 × Lily Stem

Message Card
Happy Birthday

Please acknowledge after preparation.''');
    });

    test('falls back to placeholders when Cloud fields are empty', () {
      final message = designerAssignmentMessage(
        _cloudHeader(deliverySlot: '', cardMessage: '', withSchedule: false),
        null,
        'Asha',
      );

      expect(message, contains('Delivery\n-\n-'));
      expect(message, contains('Products\n✅ No products'));
      expect(message, contains('Message Card\n-'));
    });
  });

  group('Cloud delivery WhatsApp message', () {
    test('matches the existing delivery format and carries the tracking link',
        () {
      final message = deliveryAssignmentMessage(
        _cloudHeader(),
        _cloudDetail(),
        'Bhanu',
        startDeliveryLink: _driverLink,
      );

      expect(message, '''
🚚 DELIVERY ASSIGNMENT

Order : ORD-POS-11

Recipient
Cloud Recipient

Customer
Cloud Customer

Phone
9988776655

Delivery Address
12 New Street

Google Maps URL
https://www.google.com/maps/search/?api=1&query=12%20New%20Street

Delivery Slot
10:00 - 12:00

Occasion
Birthday

Message Card Included
YES

Outstanding Amount
₹100

Products
☐ 2 × Rose Bunch
☐ 1 × Lily Stem

Delivery Person
Bhanu

▶ START DELIVERY
$_driverLink''');
    });

    test('omits the START DELIVERY block when the link could not be generated',
        () {
      final message = deliveryAssignmentMessage(
        _cloudHeader(),
        _cloudDetail(),
        'Bhanu',
      );

      expect(message, isNot(contains('▶ START DELIVERY')));
      expect(message, endsWith('Delivery Person\nBhanu'));
    });

    test('reaches WhatsApp with the tracking link intact', () {
      final message = deliveryAssignmentMessage(
        _cloudHeader(),
        _cloudDetail(),
        'Bhanu',
        startDeliveryLink: _driverLink,
      );

      final uri = WhatsAppPhoneUtils.buildUri('9876500002', message: message);
      expect(uri, isNotNull);
      expect(uri!.host, 'wa.me');
      expect(uri.path, '/919876500002');
      expect(uri.queryParameters['text'], contains('▶ START DELIVERY'));
      expect(uri.queryParameters['text'], contains(_driverLink));
      expect(uri.queryParameters['text'], contains('🚚 DELIVERY ASSIGNMENT'));
    });
  });
}

OrderDetailHeader _cloudHeader({
  String deliverySlot = '10:00 - 12:00',
  String cardMessage = 'Happy Birthday',
  bool withSchedule = true,
}) {
  return OrderDetailHeader(
    id: -1,
    cloudOrderId: _cloudOrderId,
    orderNo: 'ORD-POS-11',
    status: 'confirmed',
    customerName: 'Cloud Customer',
    customerPhone: '9876543210',
    recipientName: 'Cloud Recipient',
    recipientPhone: '9988776655',
    fulfilmentType: 'delivery',
    source: 'cloud',
    grandTotalPaise: 30000,
    address: '12 New Street',
    deliveryPincode: '560001',
    scheduledAt: withSchedule ? DateTime.utc(2026, 9, 20) : null,
    occasion: 'Birthday',
    deliverySlot: deliverySlot,
    cardMessage: cardMessage,
    isPaid: 0,
    paidAmountPaise: 20000,
  );
}

OrderDetailBundle _cloudDetail() {
  final header = _cloudHeader();
  return OrderDetailBundle(
    header: header,
    lines: const [
      {'product_name': 'Rose Bunch', 'qty': 2},
      {'product_name': 'Lily Stem', 'qty': 1},
    ],
    payments: const [],
    timeline: const [],
    schedulerTasks: const [],
    inventoryTransactions: const [],
    receiptStatus: 'cloud',
    whatsappStatus: 'cloud',
    relayInfo: const {},
    corporateInfo: const {},
    marketplaceInfo: const {'cloud_order_id': _cloudOrderId},
  );
}
