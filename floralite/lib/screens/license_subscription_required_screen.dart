import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/license.dart';
import '../providers/license_provider.dart';
import '../widgets/common_widgets.dart';

class LicenseSubscriptionRequiredScreen extends StatelessWidget {
  const LicenseSubscriptionRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LicenseProvider>(
      builder: (context, provider, child) {
        final license = provider.license;
        final isInternetRequired =
            provider.state == LicenseProviderState.internetRequired;
        final title = isInternetRequired
            ? 'Internet required to verify license'
            : 'Subscription Required';
        final message = provider.message ??
            (license?.status == CloudLicenseStatus.suspended
                ? 'This Floraprise license is suspended. Please contact support.'
                : 'Your trial or subscription has expired. Please contact Floraprise support to continue using POS and business features.');

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: AppCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          isInternetRequired
                              ? Icons.wifi_off_rounded
                              : Icons.workspace_premium_rounded,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            height: 1.4,
                          ),
                        ),
                        if (license != null) ...[
                          const SizedBox(height: 20),
                          _InfoRow(label: 'Plan', value: license.plan.label),
                          _InfoRow(
                            label: 'Status',
                            value: license.status.label,
                          ),
                          _InfoRow(
                            label: 'Remaining Days',
                            value: '${license.remainingDays}',
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: provider.isLoading
                              ? null
                              : () => context.read<LicenseProvider>().refresh(),
                          icon: provider.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded),
                          label: const Text('Verify Again'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: SystemNavigator.pop,
                          icon: const Icon(Icons.exit_to_app_outlined),
                          label: const Text('Exit'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
