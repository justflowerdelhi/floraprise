import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/subscription.dart';
import '../providers/subscription_provider.dart';
import '../widgets/common_widgets.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Floraprise',
    packageName: 'com.floraprise.app',
    version: '1.0.0',
    buildNumber: '1',
  );

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _packageInfo = info);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final subscriptionProvider = context.watch<SubscriptionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.local_florist,
                      size: 60,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Floraprise',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version ${_packageInfo.version}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Flower Shop Management System',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Subscription',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'Plan',
                    subscriptionProvider.access?.record.plan.label ?? 'Trial',
                    Icons.workspace_premium,
                  ),
                  const Divider(),
                  _buildInfoRow(
                    'Status',
                    _formatSubscriptionState(subscriptionProvider.access?.state),
                    Icons.verified,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'App Build',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'Version',
                    _packageInfo.version,
                    Icons.info_outline,
                  ),
                  const Divider(),
                  _buildInfoRow(
                    'Build Number',
                    _packageInfo.buildNumber,
                    Icons.build,
                  ),
                  const Divider(),
                  _buildInfoRow(
                    'Package Name',
                    _packageInfo.packageName,
                    Icons.apps,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Legal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildContactTile(
                    Icons.description,
                    'Privacy Policy',
                    'View Privacy Policy',
                    () => _launchUrl('https://www.floraprise.com/privacy'),
                  ),
                  const Divider(),
                  _buildContactTile(
                    Icons.gavel,
                    'Terms & Conditions',
                    'View Terms & Conditions',
                    () => _launchUrl('https://www.floraprise.com/terms'),
                  ),
                  const Divider(),
                  _buildContactTile(
                    Icons.balance,
                    'Licenses',
                    'View Open Source Licenses',
                    () => showLicensePage(
                      context: context,
                      applicationName: 'Floraprise',
                      applicationVersion: _packageInfo.version,
                      applicationLegalese: '© 2024 Floraprise. All rights reserved.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildContactTile(
                    Icons.language,
                    'Website',
                    'www.floraprise.com',
                    () => _launchUrl('https://www.floraprise.com'),
                  ),
                  const Divider(),
                  _buildContactTile(
                    Icons.email,
                    'Email',
                    'support@floraprise.com',
                    () => _launchEmail('support@floraprise.com'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Made with ❤️ for Florists',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '© 2024 Floraprise. All rights reserved.',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSubscriptionState(SubscriptionState? state) {
    if (state == null) return 'Unknown';
    switch (state) {
      case SubscriptionState.active:
        return 'Active';
      case SubscriptionState.gracePeriod:
        return 'Grace Period';
      case SubscriptionState.locked:
        return 'Locked';
    }
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Colors.grey.shade600),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
