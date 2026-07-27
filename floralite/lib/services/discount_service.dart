class DiscountService {
  DiscountService._();

  static final DiscountService instance = DiscountService._();

  /// Calculate line item discount amount
  /// Returns the discount amount in paise
  static int calculateLineDiscount({
    required int lineSubtotalPaise,
    required String discountType,
    required int discountValue,
  }) {
    if (discountType == 'percentage') {
      return (lineSubtotalPaise * discountValue / 100).round();
    } else if (discountType == 'fixed') {
      return discountValue;
    }
    return 0;
  }

  /// Calculate bill discount amount
  /// Returns the discount amount in paise
  static int calculateBillDiscount({
    required int subtotalPaise,
    required String discountType,
    required int discountValue,
  }) {
    if (discountType == 'percentage') {
      return (subtotalPaise * discountValue / 100).round();
    } else if (discountType == 'fixed') {
      return discountValue;
    } else if (discountType == 'final_amount') {
      // Calculate discount needed to reach final amount
      final discount = subtotalPaise - discountValue;
      return discount > 0 ? discount : 0;
    }
    return 0;
  }

  /// Validate line item discount
  /// Returns error message if invalid, null if valid
  static String? validateLineDiscount({
    required int lineSubtotalPaise,
    required String discountType,
    required int discountValue,
  }) {
    if (discountValue < 0) {
      return 'Discount value cannot be negative';
    }

    if (discountType == 'percentage') {
      if (discountValue > 100) {
        return 'Percentage discount cannot exceed 100%';
      }
    } else if (discountType == 'fixed') {
      if (discountValue > lineSubtotalPaise) {
        return 'Discount cannot exceed line amount';
      }
    }

    return null;
  }

  /// Validate bill discount
  /// Returns error message if invalid, null if valid
  static String? validateBillDiscount({
    required int subtotalPaise,
    required String discountType,
    required int discountValue,
  }) {
    if (discountValue < 0) {
      return 'Discount value cannot be negative';
    }

    if (discountType == 'percentage') {
      if (discountValue > 100) {
        return 'Percentage discount cannot exceed 100%';
      }
    } else if (discountType == 'fixed') {
      if (discountValue > subtotalPaise) {
        return 'Discount cannot exceed subtotal';
      }
    } else if (discountType == 'final_amount') {
      if (discountValue < 0) {
        return 'Final amount cannot be negative';
      }
      // Final amount can be 0 (free order)
    }

    return null;
  }

  /// Calculate final bill amount after bill discount
  static int calculateFinalAmount({
    required int subtotalPaise,
    required String billDiscountType,
    required int billDiscountValue,
    required int deliveryChargePaise,
    required int gstTotalPaise,
  }) {
    final billDiscount = calculateBillDiscount(
      subtotalPaise: subtotalPaise,
      discountType: billDiscountType,
      discountValue: billDiscountValue,
    );

    final afterDiscount = subtotalPaise - billDiscount;
    final total = afterDiscount + deliveryChargePaise + gstTotalPaise;

    return total > 0 ? total : 0;
  }

  /// Calculate line total after discount and GST
  static int calculateLineTotal({
    required int qty,
    required int unitPricePaise,
    required int gstPercent,
    required String discountType,
    required int discountValue,
  }) {
    final lineSubtotal = qty * unitPricePaise;
    final discount = calculateLineDiscount(
      lineSubtotalPaise: lineSubtotal,
      discountType: discountType,
      discountValue: discountValue,
    );
    final afterDiscount = lineSubtotal - discount;
    final gst = (afterDiscount * gstPercent / 100).round();
    final total = afterDiscount + gst;

    return total > 0 ? total : 0;
  }

  /// Get discount display text
  static String getDiscountDisplayText({
    required String discountType,
    required int discountValue,
  }) {
    if (discountType == 'percentage') {
      return '$discountValue%';
    } else if (discountType == 'fixed') {
      return '₹${(discountValue / 100).toStringAsFixed(2)}';
    } else if (discountType == 'final_amount') {
      return 'Final: ₹${(discountValue / 100).toStringAsFixed(2)}';
    }
    return '';
  }
}
