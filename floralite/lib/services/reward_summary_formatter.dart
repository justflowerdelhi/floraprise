import '../models/order_workspace_models.dart';

String buildRewardSummaryText(OrderRewardSummary? summary) {
  if (summary == null || !summary.hasActivity) return '';
  return '''
REWARD SUMMARY
Opening Balance: ${summary.openingBalance}
Earned: +${summary.earnedPoints}
Redeemed: -${summary.redeemedPoints}
Closing Balance: ${summary.closingBalance}
Reward Value: ₹${(summary.rewardValuePaise / 100).toStringAsFixed(0)}
'''
      .trim();
}

String buildRewardWhatsAppText(OrderRewardSummary? summary) {
  if (summary == null || !summary.hasActivity) return '';
  return '''

You earned *${summary.earnedPoints} Reward Points*.

Current Reward Balance:
${summary.closingBalance} Points

Redeem your reward points on your next purchase.''';
}
