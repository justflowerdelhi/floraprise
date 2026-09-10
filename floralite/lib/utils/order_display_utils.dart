/// Utility for formatting user-facing order numbers and identifiers.
class OrderDisplayUtils {
  static final RegExp _uuidRegex = RegExp(
    r'([0-9a-fA-F]{8})-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
  );

  static final RegExp _hex32Regex = RegExp(
    r'\b([0-9a-fA-F]{8})[0-9a-fA-F]{24}\b',
  );

  /// Formats an internal order number or sync identifier into a short, human-readable
  /// display representation for user-facing UI.
  ///
  /// - If [orderNo] is already a short human-readable string (e.g. `ORD-101`, `ORD-POS-11`,
  ///   `101`, `ORD-1725983721000`), it is preserved as-is.
  /// - If [orderNo] contains a long UUID (e.g. `ORD-POS-70b35907-e3e2-4dfb-9ed8-ae3c8833918a`),
  ///   it extracts the leading 8 hex digits to yield a compact identifier (e.g. `ORD-POS-70B35907`).
  /// - If [orderNo] is empty or null and a valid local [orderId] is provided, it falls back
  ///   to `Order #$orderId`.
  static String format(String? orderNo, {int? orderId}) {
    final trimmed = (orderNo ?? '').trim();
    if (trimmed.isEmpty || trimmed == '-') {
      if (orderId != null && orderId > 0 && orderId < 10000000) {
        return 'Order #$orderId';
      }
      return '-';
    }

    final upper = trimmed.toUpperCase();

    // Check for standard UUID pattern (8-4-4-4-12)
    final uuidMatch = _uuidRegex.firstMatch(trimmed);
    if (uuidMatch != null) {
      final shortHex = uuidMatch.group(1)!.toUpperCase();
      if (upper.startsWith('ORD-POS-')) {
        return 'ORD-POS-$shortHex';
      } else if (upper.startsWith('ORD-')) {
        return 'ORD-$shortHex';
      } else if (upper.startsWith('POS-')) {
        return 'POS-$shortHex';
      } else {
        return 'Order #$shortHex';
      }
    }

    // Check for 32-character continuous hex UUID pattern
    final hex32Match = _hex32Regex.firstMatch(trimmed);
    if (hex32Match != null) {
      final shortHex = hex32Match.group(1)!.toUpperCase();
      if (upper.startsWith('ORD-POS-')) {
        return 'ORD-POS-$shortHex';
      } else if (upper.startsWith('ORD-')) {
        return 'ORD-$shortHex';
      } else {
        return 'Order #$shortHex';
      }
    }

    // Existing short human-readable order numbers (e.g. ORD-101, ORD-POS-11, 101, ORD-1725983721000)
    return trimmed;
  }
}

/// Convenience top-level function for formatting display order numbers.
String formatDisplayOrderNo(String? orderNo, {int? orderId}) =>
    OrderDisplayUtils.format(orderNo, orderId: orderId);
