import 'package:flutter/material.dart';
import '../../services/delivery_tracking_service.dart';

/// Dedicated logistics panel for Floraprise Pro Web Dashboard.
/// Streams live active deliveries with customer/recipient info, scheduled slots,
/// delivery area, and driver dispatch status.
class DashboardDeliveriesPanel extends StatelessWidget {
  const DashboardDeliveriesPanel({
    super.key,
    required this.deliveries,
    required this.isLoading,
    required this.onViewWorkspace,
  });

  final List<DeliveryWorkspaceRecord> deliveries;
  final bool isLoading;
  final VoidCallback onViewWorkspace;

  Color _deliveryStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return const Color(0xFF2E7D32);
      case 'out_for_delivery':
      case 'in_transit':
        return const Color(0xFF2563EB);
      case 'assigned':
        return const Color(0xFF7C3AED);
      case 'pending':
      default:
        return const Color(0xFFD97706);
    }
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'out_for_delivery':
      case 'in_transit':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'assigned':
        return 'Driver Assigned';
      case 'pending':
      default:
        return 'Pending Dispatch';
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
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: Color(0xFF2563EB),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    "Today's Deliveries",
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
                  onTap: onViewWorkspace,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Workspace',
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: Color(0xFF2563EB),
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
              padding: EdgeInsets.all(28),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (deliveries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF93C5FD).withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        color: Color(0xFF2563EB),
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'All deliveries are on schedule.',
                      style: TextStyle(
                        color: Color(0xFF1E2922),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'No orders currently pending driver dispatch.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF6B7F72),
                        fontSize: 12,
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
              itemCount: deliveries.length.clamp(0, 5),
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF2F4F0)),
              itemBuilder: (context, index) {
                final item = deliveries[index];
                final color = _deliveryStatusColor(item.status);
                final statusLabel = _formatStatus(item.status);

                return InkWell(
                  onTap: onViewWorkspace,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.location_on_rounded, size: 16, color: color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.recipientName.trim().isNotEmpty
                                          ? item.recipientName
                                          : item.customerName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF1E2922),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      statusLabel,
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.deliveryArea.trim().isNotEmpty
                                    ? item.deliveryArea
                                    : (item.deliveryAddress.trim().isNotEmpty
                                        ? item.deliveryAddress
                                        : 'Area specified on ticket'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                ),
                              ),
                              if (item.deliveryTime.trim().isNotEmpty || item.driver != null) ...[
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    if (item.deliveryTime.trim().isNotEmpty) ...[
                                      const Icon(Icons.access_time_rounded, size: 11, color: Color(0xFF94A3B8)),
                                      const SizedBox(width: 4),
                                      Text(
                                        item.deliveryTime,
                                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                      ),
                                    ],
                                    if (item.driver != null) ...[
                                      const SizedBox(width: 10),
                                      const Icon(Icons.person_pin_rounded, size: 11, color: Color(0xFF94A3B8)),
                                      const SizedBox(width: 4),
                                      Text(
                                        item.driver!.name,
                                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
