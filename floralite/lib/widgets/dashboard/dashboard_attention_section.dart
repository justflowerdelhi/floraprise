import 'package:flutter/material.dart';
import '../../models/dashboard_summary.dart';

/// "Needs Your Attention" section for Floraprise Pro Web Dashboard.
/// Identifies genuine operational priorities requiring florist action (low stock,
/// pending preparations, delivery dispatches, pending payments) with 1-tap resolution.
class DashboardAttentionSection extends StatelessWidget {
  const DashboardAttentionSection({
    super.key,
    required this.summary,
    required this.onInventoryTap,
    required this.onOrdersTap,
    required this.onDeliveriesTap,
    required this.onPaymentsTap,
  });

  final DashboardSummary summary;
  final VoidCallback onInventoryTap;
  final VoidCallback onOrdersTap;
  final VoidCallback onDeliveriesTap;
  final VoidCallback onPaymentsTap;

  @override
  Widget build(BuildContext context) {
    final items = <_AttentionItem>[];

    // 1. Inventory Alerts
    final totalInventoryAlerts = summary.lowStockItems + summary.outOfStockItems;
    if (totalInventoryAlerts > 0) {
      final text = summary.outOfStockItems > 0
          ? '${summary.outOfStockItems} out of stock, ${summary.lowStockItems} low stock'
          : '${summary.lowStockItems} products below reorder threshold';
      items.add(
        _AttentionItem(
          icon: Icons.inventory_2_rounded,
          iconColor: const Color(0xFFDC2626),
          bgColor: const Color(0xFFFEF2F2),
          title: 'Inventory Alert',
          subtitle: text,
          actionLabel: 'Restock',
          onTap: onInventoryTap,
        ),
      );
    }

    // 2. Orders awaiting preparation
    if (summary.preparingOrders > 0) {
      items.add(
        _AttentionItem(
          icon: Icons.local_florist_rounded,
          iconColor: const Color(0xFFD97706),
          bgColor: const Color(0xFFFFFBEB),
          title: 'Preparation Queue',
          subtitle: '${summary.preparingOrders} arrangement${summary.preparingOrders == 1 ? '' : 's'} awaiting assembly',
          actionLabel: 'Open Orders',
          onTap: onOrdersTap,
        ),
      );
    }

    // 3. Deliveries in transit / pending
    if (summary.outForDeliveryOrders > 0) {
      items.add(
        _AttentionItem(
          icon: Icons.local_shipping_rounded,
          iconColor: const Color(0xFF2563EB),
          bgColor: const Color(0xFFEFF6FF),
          title: 'Delivery Tracking',
          subtitle: '${summary.outForDeliveryOrders} orders out for driver delivery',
          actionLabel: 'Track Delivery',
          onTap: onDeliveriesTap,
        ),
      );
    }

    // 4. Pending payments
    if (summary.todayPendingPayments > 0) {
      items.add(
        _AttentionItem(
          icon: Icons.pending_actions_rounded,
          iconColor: const Color(0xFFB45309),
          bgColor: const Color(0xFFFEF3C7),
          title: 'Payment Follow-up',
          subtitle: '${summary.todayPendingPayments} customers with balance pending',
          actionLabel: 'View Accounts',
          onTap: onPaymentsTap,
        ),
      );
    }

    // 5. Store Pickups
    if (summary.todayPickupCount > 0) {
      items.add(
        _AttentionItem(
          icon: Icons.shopping_bag_rounded,
          iconColor: const Color(0xFF7C3AED),
          bgColor: const Color(0xFFF5F3FF),
          title: 'Store Pickups Due',
          subtitle: '${summary.todayPickupCount} customer pickups scheduled today',
          actionLabel: 'View Orders',
          onTap: onOrdersTap,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7DF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: items.isEmpty
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    items.isEmpty ? Icons.check_circle_rounded : Icons.notification_important_rounded,
                    color: items.isEmpty ? const Color(0xFF2E7D32) : const Color(0xFFEA580C),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Needs Your Attention',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF1E2922),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (items.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5), width: 1),
                    ),
                    child: Text(
                      '${items.length} ACTION${items.length == 1 ? '' : 'S'}',
                      style: const TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEAECE6)),

          // Body
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF81C784).withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.spa_rounded,
                        color: Color(0xFF2E7D32),
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "You're all caught up.",
                      style: TextStyle(
                        color: Color(0xFF1B432C),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Studio operations, deliveries, and inventory levels are completely healthy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF6B7F72),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0F2ED)),
              itemBuilder: (context, index) {
                final item = items[index];
                return _AttentionRow(item: item);
              },
            ),
        ],
      ),
    );
  }
}

class _AttentionItem {
  const _AttentionItem({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;
}

class _AttentionRow extends StatefulWidget {
  const _AttentionRow({required this.item});

  final _AttentionItem item;

  @override
  State<_AttentionRow> createState() => _AttentionRowState();
}

class _AttentionRowState extends State<_AttentionRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: _isHovered ? const Color(0xFFFAFAF8) : Colors.white,
        child: InkWell(
          onTap: widget.item.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: widget.item.bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.item.icon,
                    size: 19,
                    color: widget.item.iconColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.title,
                        style: const TextStyle(
                          color: Color(0xFF1E2922),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.item.subtitle,
                        style: const TextStyle(
                          color: Color(0xFF6B7F72),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F4EE),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFDFE3DA), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.item.actionLabel,
                        style: const TextStyle(
                          color: Color(0xFF1E5E3A),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 12,
                        color: Color(0xFF1E5E3A),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
