import 'package:flutter/material.dart';

import '../../data/database/app_database.dart';
import '../../widgets/common_widgets.dart';

class RewardsReportScreen extends StatefulWidget {
  const RewardsReportScreen({super.key});

  @override
  State<RewardsReportScreen> createState() => _RewardsReportScreenState();
}

class _RewardsReportScreenState extends State<RewardsReportScreen> {
  late Future<_RewardsReportData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_RewardsReportData> _load() async {
    final db = await AppDatabase.instance.database;
    final summaryRows = await db.rawQuery('''
      SELECT
        COALESCE(SUM(reward_points), 0) AS current_points,
        COALESCE(SUM(lifetime_reward_points), 0) AS lifetime_points,
        COALESCE(SUM(redeemed_reward_points), 0) AS redeemed_points
      FROM customers
      WHERE deleted_at IS NULL
    ''');
    final orderRows = await db.rawQuery('''
      SELECT
        COUNT(*) AS reward_orders,
        COALESCE(SUM(reward_discount_amount_paise), 0) AS discount_paise
      FROM orders
      WHERE reward_points_redeemed > 0 OR reward_points_earned > 0
    ''');
    final topCustomers = await db.rawQuery('''
      SELECT name, phone, reward_points, lifetime_reward_points,
             redeemed_reward_points, last_reward_activity
      FROM customers
      WHERE deleted_at IS NULL
        AND (reward_points > 0 OR lifetime_reward_points > 0 OR redeemed_reward_points > 0)
      ORDER BY reward_points DESC, lifetime_reward_points DESC
      LIMIT 25
    ''');

    return _RewardsReportData(
      currentPoints: (summaryRows.first['current_points'] as int?) ?? 0,
      lifetimePoints: (summaryRows.first['lifetime_points'] as int?) ?? 0,
      redeemedPoints: (summaryRows.first['redeemed_points'] as int?) ?? 0,
      rewardOrders: (orderRows.first['reward_orders'] as int?) ?? 0,
      discountPaise: (orderRows.first['discount_paise'] as int?) ?? 0,
      customers: topCustomers,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rewards Report')),
      body: FutureBuilder<_RewardsReportData>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _metricCard('Current Points',
                        '${data.currentPoints}', Icons.redeem, Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _metricCard('Redeemed', '${data.redeemedPoints}',
                        Icons.check_circle, Colors.blue),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _metricCard('Lifetime Earned',
                        '${data.lifetimePoints}', Icons.stars, Colors.orange),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _metricCard(
                        'Reward Discount',
                        _formatPaise(data.discountPaise),
                        Icons.savings,
                        Colors.purple),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${data.rewardOrders} rewarded orders',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ...data.customers.map(_customerTile),
            ],
          );
        },
      ),
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(value,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }

  Widget _customerTile(Map<String, Object?> row) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.person),
          title: Text((row['name'] as String?) ?? 'Customer'),
          subtitle: Text((row['phone'] as String?) ?? ''),
          trailing: Text('${(row['reward_points'] as int?) ?? 0} pts'),
        ),
      ),
    );
  }

  String _formatPaise(int paise) {
    return '₹${(paise / 100).toStringAsFixed(0)}';
  }
}

class _RewardsReportData {
  const _RewardsReportData({
    required this.currentPoints,
    required this.lifetimePoints,
    required this.redeemedPoints,
    required this.rewardOrders,
    required this.discountPaise,
    required this.customers,
  });

  final int currentPoints;
  final int lifetimePoints;
  final int redeemedPoints;
  final int rewardOrders;
  final int discountPaise;
  final List<Map<String, Object?>> customers;
}
