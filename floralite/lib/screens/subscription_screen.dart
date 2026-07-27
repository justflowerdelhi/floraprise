import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/subscription.dart';
import '../providers/subscription_provider.dart';
import '../widgets/common_widgets.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  Future<void> _manageSubscription(BuildContext context) async {
    // Razorpay subscriptions are managed through the app
    // No external subscription management needed
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subscription is managed through the app.')),
    );
  }

  Future<void> _showRenewOptions(BuildContext context) async {
    final plan = await showModalBottomSheet<SubscriptionPlan>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose Your Plan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '7-Day Free Trial',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            for (final config in SubscriptionPlans.paid) ...[
              _PlanOptionTile(
                config: config,
                onTap: () => Navigator.pop(sheetContext, config.plan),
              ),
              if (config != SubscriptionPlans.paid.last) const Divider(),
            ],
          ],
        ),
      ),
    );
    if (plan == null || !context.mounted) return;
    await context.read<SubscriptionProvider>().startPurchase(plan);
  }

  void _showSupport(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Text(
          'Please contact Floraprise support with your registered phone number and shop name.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, provider, child) {
        final access = provider.access;
        final state = provider.state;
        final lockedLayout = provider.blocksBusinessAccess;

        if (provider.isLoading && access == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar:
              lockedLayout ? null : AppBar(title: const Text('Subscription')),
          body: SafeArea(
            child: lockedLayout
                ? _LockedSubscriptionBody(
                    provider: provider,
                    onRenew: () => _showRenewOptions(context),
                    onSupport: () => _showSupport(context),
                  )
                : _StatusSubscriptionBody(
                    provider: provider,
                    state: state,
                    onRenew: () => _showRenewOptions(context),
                    onManage: () => _manageSubscription(context),
                    onSupport: () => _showSupport(context),
                  ),
          ),
        );
      },
    );
  }
}

class _LockedSubscriptionBody extends StatelessWidget {
  const _LockedSubscriptionBody({
    required this.provider,
    required this.onRenew,
    required this.onSupport,
  });

  final SubscriptionProvider provider;
  final VoidCallback onRenew;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    final message = provider.message;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Floraprise',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 28),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      provider.access?.requiresInternet == true
                          ? 'Internet connection required.'
                          : 'Your Free Trial Has Expired',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message ??
                          'Please subscribe to continue using Floraprise.\n\nYour business data is safe.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: Colors.grey.shade700, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: onRenew,
                      icon: const Icon(Icons.workspace_premium_outlined),
                      label: const Text('Subscribe Now'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => context
                          .read<SubscriptionProvider>()
                          .restorePurchase(),
                      icon: const Icon(Icons.restore_outlined),
                      label: const Text('Restore License'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: SystemNavigator.pop,
                      icon: const Icon(Icons.exit_to_app_outlined),
                      label: const Text('Exit'),
                    ),
                    TextButton.icon(
                      onPressed: onSupport,
                      icon: const Icon(Icons.support_agent),
                      label: const Text('Contact Support'),
                    ),
                    if (provider.isLoading) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusSubscriptionBody extends StatelessWidget {
  const _StatusSubscriptionBody({
    required this.provider,
    required this.state,
    required this.onRenew,
    required this.onManage,
    required this.onSupport,
  });

  final SubscriptionProvider provider;
  final SubscriptionState state;
  final VoidCallback onRenew;
  final VoidCallback onManage;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    final access = provider.access;
    final record = access?.record;
    final now = DateTime.now();
    final formatter = DateFormat('dd MMM yyyy');
    final daysRemaining = access?.daysRemaining(now) ?? 0;
    final statusLabel = state.storageValue;
    final reminder = access?.expiryReminder(now);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Subscription Status',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _InfoRow(label: 'Plan', value: record?.plan.label ?? '-'),
              _InfoRow(label: 'Status', value: statusLabel),
              _InfoRow(
                label: 'Expiry Date',
                value:
                    record == null ? '-' : formatter.format(record.expiryDate),
              ),
              _InfoRow(label: 'Days Remaining', value: '$daysRemaining'),
              if (reminder != null) ...[
                const SizedBox(height: 12),
                _ReminderBox(
                  message: record?.plan == SubscriptionPlan.trial
                      ? 'Free Trial\n$reminder'
                      : reminder,
                  critical: daysRemaining <= 3,
                ),
              ],
              if (provider.message != null) ...[
                const SizedBox(height: 12),
                Text(provider.message!,
                    style: TextStyle(color: Colors.grey.shade700)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _PlanSummarySection(),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onRenew,
          icon: const Icon(Icons.workspace_premium_outlined),
          label: const Text('Renew'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: provider.isLoading
              ? null
              : () => context.read<SubscriptionProvider>().restorePurchase(),
          icon: const Icon(Icons.restore_outlined),
          label: const Text('Restore Purchase'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: provider.isLoading ? null : provider.verifyNow,
          icon: const Icon(Icons.verified_outlined),
          label: const Text('Verify Now'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onManage,
          icon: const Icon(Icons.settings_outlined),
          label: const Text('Manage Subscription'),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/backup-restore'),
          icon: const Icon(Icons.backup_outlined),
          label: const Text('Backup & Restore'),
        ),
        TextButton.icon(
          onPressed: onSupport,
          icon: const Icon(Icons.support_agent),
          label: const Text('Contact Support'),
        ),
        if (provider.isLoading) const LinearProgressIndicator(),
      ],
    );
  }
}

class _PlanSummarySection extends StatelessWidget {
  const _PlanSummarySection();

  static const _features = [
    'POS',
    'Order Management',
    'Customer Management',
    'Inventory',
    'Production',
    'Purchase',
    'Delivery Tracking',
    'Scheduler',
    'Voice Stock Entry',
    'Voice Purchase List',
    'Voice Dictation',
    'Accounting',
    'Reports',
    'CRM',
    'Multi-language',
    'Cloud Sync',
  ];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Your Plan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '7-Day Free Trial',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          for (final config in SubscriptionPlans.paid) ...[
            _PlanDetails(config: config),
            if (config != SubscriptionPlans.paid.last)
              const SizedBox(height: 12),
          ],
          const SizedBox(height: 16),
          const Text(
            'Every paid plan includes:',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _features
                .map(
                  (feature) => Chip(
                    avatar: const Icon(Icons.check, size: 16),
                    label: Text(feature),
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _PlanDetails extends StatelessWidget {
  const _PlanDetails({required this.config});

  final SubscriptionPlanConfig config;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: config.recommended
            ? colorScheme.primary.withValues(alpha: 0.08)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: config.recommended
              ? colorScheme.primary.withValues(alpha: 0.35)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  config.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (config.badge != null)
                Chip(
                  label: Text(config.badge!),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            config.priceLabel,
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(config.description),
          if (config.plan == SubscriptionPlan.halfYearly) ...[
            const SizedBox(height: 4),
            const Text('Save ₹1,000 compared to renewing Quarterly twice.'),
          ],
          if (config.plan == SubscriptionPlan.annual) ...[
            const SizedBox(height: 4),
            const Text('FREE Bluetooth Thermal Printer',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 2),
            Text(
              'Free Bluetooth Thermal Printer available on NEW Annual subscriptions only. Subject to verification, stock availability, shipping policy, and applicable terms.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
          const SizedBox(height: 4),
          const Text('Full Floraprise Access'),
        ],
      ),
    );
  }
}

class _PlanOptionTile extends StatelessWidget {
  const _PlanOptionTile({required this.config, required this.onTap});

  final SubscriptionPlanConfig config;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        config.recommended
            ? Icons.workspace_premium_outlined
            : Icons.event_available_outlined,
      ),
      title: Row(
        children: [
          Expanded(child: Text('${config.name} ${config.priceLabel}')),
          if (config.recommended)
            const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
        ],
      ),
      subtitle: Text('${config.description} • Full Access'),
      trailing: config.badge == null ? null : Text(config.badge!),
      onTap: onTap,
    );
  }
}

class _ReminderBox extends StatelessWidget {
  const _ReminderBox({required this.message, required this.critical});

  final String message;
  final bool critical;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: critical ? const Color(0xFFFFEBEE) : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: critical ? const Color(0xFFC62828) : const Color(0xFF8A5B00),
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
              child:
                  Text(label, style: TextStyle(color: Colors.grey.shade700))),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
