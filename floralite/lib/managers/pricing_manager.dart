import '../data/repositories/order_repository.dart';
import '../models/payment_split.dart';
import '../models/gst_calculation_type.dart';
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
    int rewardDiscountPaise = 0,
  }) {
    var grossSubtotal = 0;
    var lineDiscountTotal = 0;
    var taxableSubtotal = 0;
    var gstTotal = 0;

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

      final discountedAmount = lineSubtotal - lineDiscount;
      final breakup = calculateGstLineBreakup(
        amountPaise: discountedAmount,
        gstPercent: line.gstPercent,
        calculationType: line.gstCalculationType,
      );

      grossSubtotal += lineSubtotal;
      lineDiscountTotal += lineDiscount;
      taxableSubtotal += breakup.basicAmountPaise;
      gstTotal += breakup.gstAmountPaise;
    }

    // Calculate bill discount using DiscountService
    final billDiscount = billDiscountType != null && billDiscountValue != null
        ? DiscountService.calculateBillDiscount(
            subtotalPaise: grossSubtotal - lineDiscountTotal,
            discountType: billDiscountType,
            discountValue: billDiscountValue,
          )
        : 0;

    final afterLineDiscount = grossSubtotal - lineDiscountTotal;
    final taxableAfterBillDiscount = afterLineDiscount == 0
        ? taxableSubtotal
        : (taxableSubtotal *
                (afterLineDiscount - billDiscount) /
                afterLineDiscount)
            .round();
    final gstAfterBillDiscount = afterLineDiscount == 0
        ? gstTotal
        : (gstTotal * (afterLineDiscount - billDiscount) / afterLineDiscount)
            .round();
    final afterDelivery =
        taxableAfterBillDiscount + gstAfterBillDiscount + deliveryChargePaise;

    final totalDiscount = lineDiscountTotal + billDiscount;
    final unrounded = afterDelivery;
    final paise = unrounded % 100;
    final roundOff = paise >= 50 ? (100 - paise) : -paise;
    final rewardDiscount = rewardDiscountPaise.clamp(0, unrounded + roundOff);
    final grandTotal = unrounded + roundOff - rewardDiscount;

    return OrderTotals(
      subtotalPaise: taxableAfterBillDiscount,
      gstTotalPaise: gstAfterBillDiscount,
      discountTotalPaise: totalDiscount,
      rewardDiscountPaise: rewardDiscount,
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
