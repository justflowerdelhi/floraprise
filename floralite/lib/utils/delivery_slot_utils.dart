class DeliverySlotUtils {
  static const List<String> allSlotKeys = [
    'morning',
    'late_morning',
    'afternoon',
    'evening',
    'night',
    'midnight',
    'custom',
  ];

  static const List<String> sameDaySlotKeys = [
    'morning',
    'late_morning',
    'afternoon',
    'evening',
    'night',
  ];

  static List<String> availableSlotKeys({
    required DateTime deliveryDate,
    required DateTime now,
    required int bufferMinutes,
  }) {
    if (!isSameDate(deliveryDate, now)) return allSlotKeys;

    final effectiveTime = now.add(Duration(minutes: bufferMinutes));
    return sameDaySlotKeys.where((slot) {
      final startsAt = slotStartDateTime(slot, deliveryDate);
      return startsAt != null && !startsAt.isBefore(effectiveTime);
    }).toList(growable: false);
  }

  static bool isSlotAvailable({
    required String slot,
    required DateTime deliveryDate,
    required DateTime now,
    required int bufferMinutes,
  }) {
    if (!isSameDate(deliveryDate, now)) return true;

    final effectiveTime = now.add(Duration(minutes: bufferMinutes));
    final startsAt = slotStartDateTime(slot, deliveryDate);
    return startsAt != null && !startsAt.isBefore(effectiveTime);
  }

  static DateTime? slotStartDateTime(String slot, DateTime date) {
    final startMinutes = _slotStartMinutes(slot);
    if (startMinutes == null) return null;
    return DateTime(
      date.year,
      date.month,
      date.day,
      startMinutes ~/ 60,
      startMinutes % 60,
    );
  }

  static bool isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  static int? _slotStartMinutes(String slot) {
    switch (slot) {
      case 'morning':
        return 8 * 60;
      case 'late_morning':
        return 10 * 60;
      case 'afternoon':
        return 13 * 60;
      case 'evening':
        return 16 * 60;
      case 'night':
        return 19 * 60;
      default:
        return null;
    }
  }
}
