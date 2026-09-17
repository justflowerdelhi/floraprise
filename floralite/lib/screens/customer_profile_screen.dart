import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../widgets/common_widgets.dart';
import '../providers/customer_provider.dart';

class CustomerProfileScreen extends StatefulWidget {
  final String customerId;
  final String name;
  final String phone;
  final String lastOrder;
  final String birthday;
  final String pendingPayment;
  final int totalOrders;
  final int rewardPoints;
  final int lifetimeRewardPoints;
  final int redeemedRewardPoints;
  final String lastRewardActivity;

  const CustomerProfileScreen({
    super.key,
    required this.customerId,
    required this.name,
    required this.phone,
    required this.lastOrder,
    required this.birthday,
    required this.pendingPayment,
    required this.totalOrders,
    required this.rewardPoints,
    required this.lifetimeRewardPoints,
    required this.redeemedRewardPoints,
    required this.lastRewardActivity,
  });

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  List<Map<String, dynamic>>? _purchaseInsights;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    try {
      final provider = context.read<CustomerProvider>();
      final insights = await provider.getPurchaseInsights(widget.customerId);
      if (mounted) {
        setState(() {
          _purchaseInsights = insights;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.customerProfile),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        widget.name[0],
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.name,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.phone,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      label: l10n.totalOrders,
                      value: '${widget.totalOrders}',
                      icon: Icons.shopping_bag,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      label: l10n.pendingPayment,
                      value: widget.pendingPayment,
                      icon: Icons.account_balance_wallet,
                      color: widget.pendingPayment != '₹0' ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      label: 'Reward Balance',
                      value: '${widget.rewardPoints}',
                      icon: Icons.redeem,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      label: 'Lifetime Earned',
                      value: '${widget.lifetimeRewardPoints}',
                      icon: Icons.stars,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.customerDetails,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.phone, l10n.phoneNumber, widget.phone),
                    const SizedBox(height: 12),
                    _buildDetailRow(Icons.cake, l10n.birthdayMonth, widget.birthday),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                        Icons.shopping_bag, l10n.lastOrder, widget.lastOrder),
                    const SizedBox(height: 12),
                    _buildDetailRow(Icons.redeem, 'Lifetime Redeemed',
                        '${widget.redeemedRewardPoints} Points'),
                    const SizedBox(height: 12),
                    _buildDetailRow(Icons.history, 'Last Reward Activity',
                        widget.lastRewardActivity),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_purchaseInsights != null)
                _buildPurchaseInsightsCard(_purchaseInsights!),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/walkin-sales',
                      arguments: {
                        'prefillCustomerId': widget.customerId,
                        'prefillCustomerName': widget.name,
                        'prefillCustomerPhone': widget.phone,
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.newOrder,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseInsightsCard(List<Map<String, dynamic>> insights) {
    if (insights.isEmpty) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Purchase Insights',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text('No purchase history found.'),
          ],
        ),
      );
    }

    final categories = insights.map((e) => (e['categoryName'] ?? e['CategoryName']).toString()).join(', ');

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Purchase Insights',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.category, 'Categories Purchased', categories),
          const SizedBox(height: 16),
          const Divider(),
          ...insights.map((item) {
            final name = (item['categoryName'] ?? item['CategoryName']).toString();
            final count = item['orderCount'] ?? item['OrderCount'];
            final spentPaise = item['totalAmountSpentPaise'] ?? item['TotalAmountSpentPaise'] ?? (item['totalAmountSpent'] != null ? ((item['totalAmountSpent'] as num) * 100).toInt() : (item['TotalAmountSpent'] != null ? ((item['TotalAmountSpent'] as num) * 100).toInt() : 0));
            final dateRaw = (item['lastPurchaseDate'] ?? item['LastPurchaseDate'])?.toString();

            String dateFormatted = '-';
            if (dateRaw != null) {
              final d = DateTime.tryParse(dateRaw);
              if (d != null) {
                dateFormatted = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
              }
            }

            return Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Orders: $count', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      Text('Spent: ₹${(spentPaise / 100).toStringAsFixed(0)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      Text('Last: $dateFormatted', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
