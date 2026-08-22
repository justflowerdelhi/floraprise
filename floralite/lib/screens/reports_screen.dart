import 'package:flutter/material.dart';

import '../widgets/app_header.dart';
import '../widgets/common_widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'Reports'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ReportCard(
            icon: Icons.trending_up_rounded,
            title: 'Sales Report',
            description: 'How much did I sell?',
            color: Colors.green,
            onTap: () => Navigator.pushNamed(context, '/reports/sales'),
          ),
          const SizedBox(height: 12),
          _ReportCard(
            icon: Icons.inventory_2_rounded,
            title: 'Order Status',
            description: 'What is the status of my orders?',
            color: Colors.blue,
            onTap: () => Navigator.pushNamed(context, '/reports/order-status'),
          ),
          const SizedBox(height: 12),
          _ReportCard(
            icon: Icons.people_rounded,
            title: 'Top Customers',
            description: 'Who are my best customers?',
            color: Colors.purple,
            onTap: () => Navigator.pushNamed(context, '/reports/top-customers'),
          ),
          const SizedBox(height: 12),
          _ReportCard(
            icon: Icons.redeem_rounded,
            title: 'Rewards Report',
            description: 'Track points earned, redeemed and outstanding.',
            color: Colors.green,
            onTap: () => Navigator.pushNamed(context, '/reports/rewards'),
          ),
          const SizedBox(height: 12),
          _ReportCard(
            icon: Icons.local_florist_rounded,
            title: 'Top Products',
            description: 'Which products are selling the most?',
            color: Colors.pink,
            onTap: () => Navigator.pushNamed(context, '/reports/top-products'),
          ),
          const SizedBox(height: 12),
          _ReportCard(
            icon: Icons.warning_rounded,
            title: 'Low Stock',
            description: 'Which products need restocking?',
            color: Colors.orange,
            onTap: () => Navigator.pushNamed(context, '/reports/low-stock'),
          ),
          const SizedBox(height: 12),
          _ReportCard(
            icon: Icons.receipt_long_rounded,
            title: 'Expense Report',
            description: 'How much have I spent?',
            color: Colors.red,
            onTap: () => Navigator.pushNamed(context, '/reports/expenses'),
          ),
          const SizedBox(height: 12),
          _ReportCard(
            icon: Icons.nights_stay_rounded,
            title: 'Day Closing',
            description: 'How did my day close?',
            color: Colors.indigo,
            onTap: () => Navigator.pushNamed(context, '/reports/day-closing'),
          ),
          const SizedBox(height: 12),
          _ReportCard(
            icon: Icons.delete_outline_rounded,
            title: 'Wastage Report',
            description: 'Track inventory losses and wastage analysis.',
            color: Colors.deepOrange,
            onTap: () => Navigator.pushNamed(context, '/reports/wastage'),
          ),
          const SizedBox(height: 12),
          _ReportCard(
            icon: Icons.precision_manufacturing_outlined,
            title: 'Production Report',
            description: 'Review bouquets produced and production costs.',
            color: Colors.teal,
            onTap: () => Navigator.pushNamed(context, '/reports/production'),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _ReportCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
