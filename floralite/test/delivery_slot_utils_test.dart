import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/utils/delivery_slot_utils.dart';

void main() {
  group('DeliverySlotUtils.availableSlotKeys', () {
    test('shows all slots for future delivery dates', () {
      final now = DateTime(2026, 7, 18, 13);

      expect(
        DeliverySlotUtils.availableSlotKeys(
          deliveryDate: DateTime(2026, 7, 19),
          now: now,
          bufferMinutes: 60,
        ),
        DeliverySlotUtils.allSlotKeys,
      );
    });

    test('at 1:00 PM with 60 minute buffer shows evening and night', () {
      final now = DateTime(2026, 7, 18, 13);

      expect(
        DeliverySlotUtils.availableSlotKeys(
          deliveryDate: DateTime(2026, 7, 18),
          now: now,
          bufferMinutes: 60,
        ),
        ['evening', 'night'],
      );
    });

    test('at 5:30 PM with 60 minute buffer shows only night', () {
      final now = DateTime(2026, 7, 18, 17, 30);

      expect(
        DeliverySlotUtils.availableSlotKeys(
          deliveryDate: DateTime(2026, 7, 18),
          now: now,
          bufferMinutes: 60,
        ),
        ['night'],
      );
    });

    test('at 8:15 PM with 60 minute buffer has no same-day slots', () {
      final now = DateTime(2026, 7, 18, 20, 15);

      expect(
        DeliverySlotUtils.availableSlotKeys(
          deliveryDate: DateTime(2026, 7, 18),
          now: now,
          bufferMinutes: 60,
        ),
        isEmpty,
      );
    });
  });
}
