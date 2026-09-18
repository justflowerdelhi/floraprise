import '../services/tax_calculation_engine.dart';

enum GstCalculationType {
  inclusive,
  exclusive;

  static GstCalculationType fromStorage(String? value) {
    return value == exclusive.storageValue ? exclusive : inclusive;
  }

  String get storageValue {
    switch (this) {
      case GstCalculationType.inclusive:
        return 'inclusive';
      case GstCalculationType.exclusive:
        return 'exclusive';
    }
  }

  String get label {
    switch (this) {
      case GstCalculationType.inclusive:
        return 'Inclusive';
      case GstCalculationType.exclusive:
        return 'Exclusive';
    }
  }
}

class GstLineBreakup {
  const GstLineBreakup({
    required this.basicAmountPaise,
    required this.gstAmountPaise,
    required this.totalAmountPaise,
  });

  final int basicAmountPaise;
  final int gstAmountPaise;
  final int totalAmountPaise;
}

GstLineBreakup calculateGstLineBreakup({
  required int amountPaise,
  required int gstPercent,
  required GstCalculationType calculationType,
}) {
  final result = TaxCalculationEngine.calculate(
    amountPaise: amountPaise,
    taxRatePercent: gstPercent.toDouble(),
    isTaxInclusive: calculationType == GstCalculationType.inclusive,
  );

  return GstLineBreakup(
    basicAmountPaise: result.netAmountPaise,
    gstAmountPaise: result.taxAmountPaise,
    totalAmountPaise: result.totalAmountPaise,
  );
}

