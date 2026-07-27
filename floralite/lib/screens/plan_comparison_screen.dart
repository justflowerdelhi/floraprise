import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/subscription.dart';
import '../providers/subscription_provider.dart';
import '../widgets/common_widgets.dart';

class PlanComparisonScreen extends StatelessWidget {
  const PlanComparisonScreen({super.key});

  static const _features = [
    'Full Access',
    'Unlimited Orders',
    'Unlimited Products',
    'Unlimited Customers',
    'Unlimited Staff',
    'Unlimited Deliveries',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Comparison'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PlanCard(
            plan: SubscriptionPlans.trial,
            isHighlighted: false,
            onSelect: () => Navigator.pop(context),
          ),
          const SizedBox(height: 16),
          _PlanCard(
            plan: SubscriptionPlans.quarterly,
            isHighlighted: false,
            onSelect: () => _selectPlan(context, SubscriptionPlan.quarterly),
          ),
          const SizedBox(height: 16),
          _PlanCard(
            plan: SubscriptionPlans.halfYearly,
            isHighlighted: false,
            onSelect: () => _selectPlan(context, SubscriptionPlan.halfYearly),
          ),
          const SizedBox(height: 16),
          _PlanCard(
            plan: SubscriptionPlans.annual,
            isHighlighted: true,
            onSelect: () => _selectPlan(context, SubscriptionPlan.annual),
          ),
          const SizedBox(height: 24),
          const _FeaturesSection(),
        ],
      ),
    );
  }

  Future<void> _selectPlan(BuildContext context, SubscriptionPlan plan) async {
    if (!context.mounted) return;
    await context.read<SubscriptionProvider>().startPurchase(plan);
    if (context.mounted) {
      Navigator.pop(context);
    }
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isHighlighted,
    required this.onSelect,
  });

  final SubscriptionPlanConfig plan;
  final bool isHighlighted;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: isHighlighted
            ? colorScheme.primary.withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted
              ? colorScheme.primary.withValues(alpha: 0.5)
              : Colors.grey.shade300,
          width: isHighlighted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isHighlighted)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: const Text(
                '⭐ MOST POPULAR',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  plan.description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  plan.priceLabel,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (plan.plan == SubscriptionPlan.halfYearly)
                  Text(
                    'Save ₹1,000 compared to renewing Quarterly twice.',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (plan.plan == SubscriptionPlan.annual) ...[
                  Text(
                    'FREE Bluetooth Thermal Printer',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'For First 100 Subscribers on Annual Plan',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: plan.isTrial ? null : onSelect,
                  style: FilledButton.styleFrom(
                    backgroundColor: isHighlighted
                        ? colorScheme.primary
                        : colorScheme.primary.withValues(alpha: 0.8),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Text(
                    plan.isTrial ? 'Current Plan' : 'Choose Plan',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Every paid plan includes:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...PlanComparisonScreen._features.map((feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
