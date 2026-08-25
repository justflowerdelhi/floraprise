import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/managers/pricing_manager.dart';
import 'package:floraprise/managers/reward_manager.dart';
import 'package:floraprise/models/gst_calculation_type.dart';
import 'package:floraprise/models/walk_in_line_item.dart';

void main() {
  test('maximum redemption respects balance, bill cap, and minimum bill', () {
    final manager = RewardManager();
    const settings = RewardSettings.defaults;

    expect(
      manager.calculateMaximumRedeemablePoints(
        billPaise: 100000,
        availablePoints: 500,
        settings: settings,
      ),
      200,
    );
    expect(
      manager.calculateMaximumRedeemablePoints(
        billPaise: 25000,
        availablePoints: 500,
        settings: settings,
      ),
      0,
    );
  });

  test('reward discount applies after GST pricing', () {
    final totals = PricingManager().computeTotals(
      lines: const [
        WalkInLineItem(
          description: 'Inclusive bouquet',
          quantity: 1,
          unitPricePaise: 112000,
          gstPercent: 12,
          gstCalculationType: GstCalculationType.inclusive,
          source: 'product',
        ),
      ],
      rewardDiscountPaise: 20000,
    );

    expect(totals.subtotalPaise, 100000);
    expect(totals.gstTotalPaise, 12000);
    expect(totals.rewardDiscountPaise, 20000);
    expect(totals.grandTotalPaise, 92000);
  });

  test('earned points require enabled rewards and minimum bill', () {
    final manager = RewardManager();
    const settings = RewardSettings.defaults;

    expect(
      manager.calculateEarnedPoints(
        paidBillPaise: 112000,
        settings: settings,
      ),
      11,
    );
    expect(
      manager.calculateEarnedPoints(
        paidBillPaise: 25000,
        settings: settings,
      ),
      0,
    );
  });
}
