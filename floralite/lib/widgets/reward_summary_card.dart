import 'package:flutter/material.dart';

import '../models/order_workspace_models.dart';
import '../utils/locale_formatter.dart';

class RewardSummaryCard extends StatelessWidget {
  const RewardSummaryCard({
    super.key,
    required this.summary,
    this.compact = false,
  });

  final OrderRewardSummary summary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.redeem_rounded, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Reward Earned',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _row('Earned', '+${summary.earnedPoints} Points'),
          _row('Current Balance', '${summary.closingBalance} Points'),
          if (!compact) ...[
            _row('Redeemed', '-${summary.redeemedPoints} Points'),
            _row(
              'Reward Value',
              LocaleFormatter.formatCurrency(context, summary.rewardValuePaise),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
