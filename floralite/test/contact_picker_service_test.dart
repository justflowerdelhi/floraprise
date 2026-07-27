import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/services/contact_picker_service.dart';

void main() {
  group('ContactPickerService.normalizeMobile', () {
    test('removes spaces hyphens brackets and leading India code', () {
      expect(ContactPickerService.normalizeMobile('+91 98765 43210'),
          '9876543210');
      expect(ContactPickerService.normalizeMobile('+91-98765-43210'),
          '9876543210');
      expect(
          ContactPickerService.normalizeMobile('(98765) 43210'), '9876543210');
    });

    test('removes leading zero before ten digit mobile number', () {
      expect(ContactPickerService.normalizeMobile('09876543210'), '9876543210');
    });
  });
}
