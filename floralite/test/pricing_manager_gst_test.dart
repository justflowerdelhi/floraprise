import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/managers/pricing_manager.dart';
import 'package:floraprise/models/gst_calculation_type.dart';
import 'package:floraprise/models/walk_in_line_item.dart';

void main() {
  test('inclusive GST splits selling price without increasing total', () {
    final totals = PricingManager().computeTotals(
      lines: const [
        WalkInLineItem(
          description: 'Rose bouquet',
          quantity: 1,
          unitPricePaise: 11200,
          gstPercent: 12,
          gstCalculationType: GstCalculationType.inclusive,
          source: 'product',
        ),
      ],
    );

    expect(totals.subtotalPaise, 10000);
    expect(totals.gstTotalPaise, 1200);
    expect(totals.grandTotalPaise, 11200);
  });

  test('exclusive GST adds tax above selling price', () {
    final totals = PricingManager().computeTotals(
      lines: const [
        WalkInLineItem(
          description: 'Corporate bouquet',
          quantity: 1,
          unitPricePaise: 10000,
          gstPercent: 12,
          gstCalculationType: GstCalculationType.exclusive,
          source: 'product',
        ),
      ],
    );

    expect(totals.subtotalPaise, 10000);
    expect(totals.gstTotalPaise, 1200);
    expect(totals.grandTotalPaise, 11200);
  });
}
