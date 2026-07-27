import '../data/repositories/order_repository.dart';
import '../models/payment_split.dart';
import '../models/walk_in_line_item.dart';
import '../services/discount_service.dart';

class PricingValidation {
  final bool isValid;
  final String? message;

  const PricingValidation({required this.isValid, this.message});
}

class PricingManager {
  OrderTotals computeTotals({
    required List<WalkInLineItem> lines,
    String? billDiscountType,
    int? billDiscountValue,
    int deliveryChargePaise = 0,
  }) {
    var subtotal = 0;
    var lineDiscountTotal = 0;

    for (final line in lines) {
      final lineSubtotal = line.unitPricePaise * line.quantity;

      // Calculate line discount using DiscountService
      final lineDiscount =
          line.discountType != null && line.discountValue != null
              ? DiscountService.calculateLineDiscount(
                  lineSubtotalPaise: lineSubtotal,
                  discountType: line.discountType!,
                  discountValue: line.discountValue!,
                )
              : line.discountPaise;

      subtotal += lineSubtotal;
      lineDiscountTotal += lineDiscount;
    }

    // Calculate bill discount using DiscountService
    final billDiscount = billDiscountType != null && billDiscountValue != null
        ? DiscountService.calculateBillDiscount(
            subtotalPaise: subtotal - lineDiscountTotal,
            discountType: billDiscountType,
            discountValue: billDiscountValue,
          )
        : 0;

    final afterLineDiscount = subtotal - lineDiscountTotal;
    final afterBillDiscount = afterLineDiscount - billDiscount;
    final afterDelivery = afterBillDiscount + deliveryChargePaise;

    // Calculate GST on post-line-discount amount (before bill discount and delivery)
    var gstTotal = 0;
    for (final line in lines) {
      final lineSubtotal = line.unitPricePaise * line.quantity;
      final lineDiscount =
          line.discountType != null && line.discountValue != null
              ? DiscountService.calculateLineDiscount(
                  lineSubtotalPaise: lineSubtotal,
                  discountType: line.discountType!,
                  discountValue: line.discountValue!,
                )
              : line.discountPaise;
      final taxable = lineSubtotal - lineDiscount;

      // Proportionally allocate GST based on line's share of taxable amount
      final proportion = taxable > 0 ? taxable / afterLineDiscount : 0.0;
      final lineGst =
          ((afterLineDiscount * proportion) * line.gstPercent / 100).round();
      gstTotal += lineGst;
    }

    final totalDiscount = lineDiscountTotal + billDiscount;
    final unrounded = afterDelivery + gstTotal;
    final paise = unrounded % 100;
    final roundOff = paise >= 50 ? (100 - paise) : -paise;
    final grandTotal = unrounded + roundOff;

    return OrderTotals(
      subtotalPaise: subtotal,
      gstTotalPaise: gstTotal,
      discountTotalPaise: totalDiscount,
      roundOffPaise: roundOff,
      grandTotalPaise: grandTotal,
    );
  }

  PricingValidation validatePayments({
    required int grandTotalPaise,
    required List<PaymentSplit> payments,
  }) {
    if (payments.isEmpty) {
      return const PricingValidation(
        isValid: false,
        message: 'Please select a payment method',
      );
    }

    final allocated = payments.fold<int>(0, (sum, p) => sum + p.amountPaise);
    if (allocated > grandTotalPaise) {
      return const PricingValidation(
        isValid: false,
        message: 'Payment total cannot exceed grand total',
      );
    }

    if (allocated <= 0) {
      return const PricingValidation(
        isValid: false,
        message: 'Please enter at least one payment amount',
      );
    }

    return const PricingValidation(isValid: true);
  }
}
