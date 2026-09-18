import '../models/fiscal_profile.dart';

/// Result of a tax calculation containing monetary values in integer minor units
/// (paise / cents / fils).
class TaxCalculationResult {
  /// Net / Subtotal base amount before tax in minor units.
  final int netAmountPaise;

  /// Computed tax amount in minor units.
  final int taxAmountPaise;

  /// Total gross amount payable in minor units.
  final int totalAmountPaise;

  /// Effective tax rate percentage applied (e.g. 18.0, 5.0).
  final double taxRatePercent;

  /// Whether the input amount was treated as tax-inclusive.
  final bool taxInclusive;

  const TaxCalculationResult({
    required this.netAmountPaise,
    required this.taxAmountPaise,
    required this.totalAmountPaise,
    required this.taxRatePercent,
    required this.taxInclusive,
  });

  /// Compatibility aliases matching existing naming conventions.
  int get subtotalPaise => netAmountPaise;
  int get taxPaise => taxAmountPaise;
  int get grandTotalPaise => totalAmountPaise;

  int get netAmount => netAmountPaise;
  int get taxAmount => taxAmountPaise;
  int get totalAmount => totalAmountPaise;
  double get taxRate => taxRatePercent;

  @override
  String toString() {
    return 'TaxCalculationResult(net: $netAmountPaise, tax: $taxAmountPaise, total: $totalAmountPaise, rate: $taxRatePercent%, inclusive: $taxInclusive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaxCalculationResult &&
        other.netAmountPaise == netAmountPaise &&
        other.taxAmountPaise == taxAmountPaise &&
        other.totalAmountPaise == totalAmountPaise &&
        other.taxRatePercent == taxRatePercent &&
        other.taxInclusive == taxInclusive;
  }

  @override
  int get hashCode => Object.hash(
        netAmountPaise,
        taxAmountPaise,
        totalAmountPaise,
        taxRatePercent,
        taxInclusive,
      );
}

/// Shared Tax Calculation Engine for Floraprise across Solo, Pro Android, and Pro Web.
/// Performs precise integer minor-unit monetary arithmetic without floating-point drift.
class TaxCalculationEngine {
  TaxCalculationEngine._();

  /// Calculates tax for an amount given explicit tax rate and inclusive/exclusive mode.
  ///
  /// 1. TAX EXCLUSIVE:
  ///    tax = round(N * R / 100)
  ///    total = N + tax
  ///    net = N
  ///
  /// 2. TAX INCLUSIVE:
  ///    tax = round(G * R / (100 + R))
  ///    net = G - tax
  ///    total = G
  ///
  /// 3. TAX DISABLED / ZERO:
  ///    tax = 0
  ///    total = amount
  ///    net = amount
  static TaxCalculationResult calculate({
    required int amountPaise,
    required double taxRatePercent,
    required bool isTaxInclusive,
    bool taxEnabled = true,
  }) {
    final safeAmount = amountPaise < 0 ? 0 : amountPaise;
    final safeRate = taxRatePercent < 0 ? 0.0 : taxRatePercent;

    if (!taxEnabled || safeAmount == 0 || safeRate == 0.0) {
      return TaxCalculationResult(
        netAmountPaise: safeAmount,
        taxAmountPaise: 0,
        totalAmountPaise: safeAmount,
        taxRatePercent: safeRate,
        taxInclusive: isTaxInclusive,
      );
    }

    if (isTaxInclusive) {
      // Inclusive Tax Calculation:
      // tax = round(G * R / (100 + R))
      // net = G - tax
      // total = G
      final tax = ((safeAmount * safeRate) / (100.0 + safeRate)).round();
      final net = safeAmount - tax;
      return TaxCalculationResult(
        netAmountPaise: net,
        taxAmountPaise: tax,
        totalAmountPaise: safeAmount,
        taxRatePercent: safeRate,
        taxInclusive: true,
      );
    } else {
      // Exclusive Tax Calculation:
      // tax = round(N * R / 100)
      // total = N + tax
      // net = N
      final tax = ((safeAmount * safeRate) / 100.0).round();
      final total = safeAmount + tax;
      return TaxCalculationResult(
        netAmountPaise: safeAmount,
        taxAmountPaise: tax,
        totalAmountPaise: total,
        taxRatePercent: safeRate,
        taxInclusive: false,
      );
    }
  }

  /// Calculates tax using the store's configured FiscalProfile.
  static TaxCalculationResult calculateWithProfile({
    required int amountPaise,
    required FiscalProfile profile,
    double? taxRateOverride,
    bool? isTaxInclusiveOverride,
  }) {
    return calculate(
      amountPaise: amountPaise,
      taxRatePercent: taxRateOverride ?? profile.taxRatePercent,
      isTaxInclusive: isTaxInclusiveOverride ?? profile.taxInclusive,
      taxEnabled: profile.taxEnabled,
    );
  }
}
