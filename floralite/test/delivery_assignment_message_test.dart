import 'package:floraprise/utils/delivery_message_utils.dart';
import 'package:floraprise/utils/whatsapp_phone_utils.dart';
import 'package:flutter_test/flutter_test.dart';

const _driverLink =
    'https://mobile.floraprise.com/track/driver/abc123XYZ';

void main() {
  group('startDeliverySection', () {
    test('appends the tracking-start link block when a link is available', () {
      expect(
        startDeliverySection(_driverLink),
        ['', '▶ START DELIVERY', _driverLink],
      );
    });

    test('trims the link so the message never carries stray whitespace', () {
      expect(
        startDeliverySection('  $_driverLink  '),
        ['', '▶ START DELIVERY', _driverLink],
      );
    });

    test('omits the block when no link could be generated', () {
      expect(startDeliverySection(null), isEmpty);
      expect(startDeliverySection(''), isEmpty);
      expect(startDeliverySection('   '), isEmpty);
    });
  });

  test('delivery assignment message carries the link into the WhatsApp URI', () {
    final message = [
      '🚚 DELIVERY ASSIGNMENT',
      '',
      'Order : ORD-POS-11',
      '',
      'Delivery Person',
      'Bhanu',
      ...startDeliverySection(_driverLink),
    ].join('\n');

    expect(message, contains('▶ START DELIVERY'));
    expect(message, endsWith(_driverLink));

    final uri = WhatsAppPhoneUtils.buildUri('9876500002', message: message);
    expect(uri, isNotNull);
    expect(uri!.host, 'wa.me');
    expect(uri.path, '/919876500002');
    expect(uri.queryParameters['text'], contains(_driverLink));
    expect(uri.queryParameters['text'], contains('▶ START DELIVERY'));
  });
}
