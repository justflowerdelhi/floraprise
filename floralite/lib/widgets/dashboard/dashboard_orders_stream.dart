import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order_status.dart';
import '../../models/order_workspace_models.dart';

/// Live operational feed of today's customer orders on Floraprise Pro Web.
/// Displays order numbers, customer names, fulfilment modes, status badges, and amounts.
class DashboardOrdersStream extends StatelessWidget {
  const DashboardOrdersStream({
    super.key,
    required this.orders,
    required this.isLoading,
    required this.onViewAllOrders,
    required this.onOrderTap,
    required this.onNewSale,
  });

  final List<OrderListItem> orders;
  final bool isLoading;
  final VoidCallback onViewAllOrders;
  final void Function(OrderListItem order) onOrderTap;
  final VoidCallback onNewSale;

  Color _fulfilmentColor(String type) {
    switch (type.toLowerCase()) {
      case 'delivery':
        return const Color(0xFF2563EB);
      case 'pickup_later':
      case 'pickup':
        return const Color(0xFF7C3AED);
      case 'take_away':
      case 'takeaway':
      default:
        return const Color(0xFF059669);
    }
  }

  String _fulfilmentLabel(String type) {
    switch (type.toLowerCase()) {
      case 'delivery':
        return 'Delivery';
      case 'pickup_later':
      case 'pickup':
        return 'Pickup';
      case 'take_away':
      case 'takeaway':
      default:
        return 'Walk-in Sale';
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return const Color(0xFF2E7D32);
      case 'out_for_delivery':
      case 'outfordelivery':
        return const Color(0xFF2563EB);
      case 'ready':
      case 'readyfordelivery':
        return const Color(0xFF0D9488);
      case 'processing':
      case 'preparing':
        return const Color(0xFFD97706);
      case 'confirmed':
        return const Color(0xFF4F46E5);
      case 'pending':
      default:
        return const Color(0xFFEA580C);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    color: const Color(0xFFEBF3EE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Color(0xFF1E5E3A),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    "Today's Orders",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF1E2922),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onViewAllOrders,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All',
                          style: TextStyle(
                            color: Color(0xFF1E5E3A),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: Color(0xFF1E5E3A),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEAECE6)),

          // Body
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
              ),
            )
          else if (orders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F4EB),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFD4A054).withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.local_florist_outlined,
                        color: Color(0xFFB4833E),
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Your first arrangement of the day is waiting.',
                      style: TextStyle(
                        color: Color(0xFF1E2922),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Walk-in sales and customer orders created today will stream here live.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF6B7F72),
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: onNewSale,
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Start Walk-in Sale'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1E5E3A),
                        side: const BorderSide(color: Color(0xFF2E7D32)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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
              itemCount: orders.length.clamp(0, 7),
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF2F4F0)),
              itemBuilder: (context, index) {
                final order = orders[index];
                return _OrderRow(
                  order: order,
                  fulfilmentColor: _fulfilmentColor(order.fulfilmentType),
                  fulfilmentLabel: _fulfilmentLabel(order.fulfilmentType),
                  statusColor: _statusColor(order.status),
                  onTap: () => onOrderTap(order),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _OrderRow extends StatefulWidget {
  const _OrderRow({
    required this.order,
    required this.fulfilmentColor,
    required this.fulfilmentLabel,
    required this.statusColor,
    required this.onTap,
  });

  final OrderListItem order;
  final Color fulfilmentColor;
  final String fulfilmentLabel;
  final Color statusColor;
  final VoidCallback onTap;

  @override
  State<_OrderRow> createState() => _OrderRowState();
}

class _OrderRowState extends State<_OrderRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final timeString = DateFormat('h:mm a').format(order.createdAt);
    final amountRupees = (order.grandTotalPaise / 100).toStringAsFixed(0);
    final displayOrderNo = order.displayOrderNo;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: _isHovered ? const Color(0xFFFBFBF9) : Colors.white,
        child: InkWell(
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            child: Row(
              children: [
                // Order No & Time
                SizedBox(
                  width: 100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayOrderNo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1E2922),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeString,
                        style: const TextStyle(
                          color: Color(0xFF86948B),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Customer Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customerName.trim().isEmpty ? 'Walk-in Customer' : order.customerName.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF26332A),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (order.recipientName.trim().isNotEmpty && order.recipientName != order.customerName) ...[
                        const SizedBox(height: 2),
                        Text(
                          'For: ${order.recipientName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF86948B),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Fulfilment Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: widget.fulfilmentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.fulfilmentLabel,
                    style: TextStyle(
                      color: widget.fulfilmentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Status Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: widget.statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    OrderStatus.label(order.status),
                    style: TextStyle(
                      color: widget.statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Amount
                Text(
                  '₹$amountRupees',
                  style: const TextStyle(
                    color: Color(0xFF143823),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
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
