import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/utils/whatsapp_phone_utils.dart';

void main() {
  group('WhatsAppPhoneUtils.normalize', () {
    test('adds India country code to a 10-digit number', () {
      expect(WhatsAppPhoneUtils.normalize('9810392755'), '+919810392755');
    });

    test('adds plus to a 12-digit Indian number', () {
      expect(WhatsAppPhoneUtils.normalize('919810392755'), '+919810392755');
    });

    test('keeps an E.164 Indian number unchanged', () {
      expect(WhatsAppPhoneUtils.normalize('+919810392755'), '+919810392755');
    });

    test('removes spaces, dashes, and brackets', () {
      expect(
        WhatsAppPhoneUtils.normalize('+91 (9810) 392-755'),
        '+919810392755',
      );
    });

    test('preserves an international country code', () {
      expect(WhatsAppPhoneUtils.normalize('+1 (415) 555-2671'), '+14155552671');
    });
  });
}
