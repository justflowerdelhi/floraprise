import 'package:flutter/material.dart';
import '../../data/repositories/cloud_inventory_repository.dart';
import '../../data/repositories/inventory_repository.dart';

/// Studio Inventory Health card for Floraprise Pro Web Dashboard.
/// Provides visual stock ratio breakdown and immediate visibility into
/// low-stock botanical items requiring florist reordering.
class DashboardInventoryHealth extends StatelessWidget {
  const DashboardInventoryHealth({
    super.key,
    required this.products,
    required this.lowStockProducts,
    required this.isLoading,
    required this.onViewInventory,
  });

  final List<InventoryProductRecord> products;
  final List<CloudLowStockProduct> lowStockProducts;
  final bool isLoading;
  final VoidCallback onViewInventory;

  @override
  Widget build(BuildContext context) {
    // Compute genuine stock statistics
    int inStockCount = 0;
    int lowStockCount = 0;
    int outOfStockCount = 0;
    int untrackedCount = 0;

    for (final p in products) {
      if (!p.trackInventory) {
        untrackedCount++;
      } else if (p.currentQty <= 0) {
        outOfStockCount++;
      } else if (p.currentQty <= p.minQty) {
        lowStockCount++;
      } else {
        inStockCount++;
      }
    }

    final totalTracked = inStockCount + lowStockCount + outOfStockCount;

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
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    color: Color(0xFF2E7D32),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Inventory Health',
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
                  onTap: onViewInventory,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Inventory',
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: Color(0xFF2E7D32),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEAECE6)),

          // Stock Distribution Bar
          if (products.isNotEmpty && totalTracked > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 8,
                      child: Row(
                        children: [
                          if (inStockCount > 0)
                            Expanded(
                              flex: inStockCount,
                              child: Container(color: const Color(0xFF2E7D32)),
                            ),
                          if (lowStockCount > 0)
                            Expanded(
                              flex: lowStockCount,
                              child: Container(color: const Color(0xFFF59E0B)),
                            ),
                          if (outOfStockCount > 0)
                            Expanded(
                              flex: outOfStockCount,
                              child: Container(color: const Color(0xFFEF4444)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StockBadge(
                        label: 'In Stock',
                        count: inStockCount,
                        color: const Color(0xFF2E7D32),
                      ),
                      _StockBadge(
                        label: 'Low Stock',
                        count: lowStockCount,
                        color: const Color(0xFFF59E0B),
                      ),
                      _StockBadge(
                        label: 'Out of Stock',
                        count: outOfStockCount,
                        color: const Color(0xFFEF4444),
                      ),
                      if (untrackedCount > 0)
                        _StockBadge(
                          label: 'Untracked',
                          count: untrackedCount,
                          color: const Color(0xFF94A3B8),
                        ),
                    ],
                  ),
                ],
              ),
            ),

          if (products.isNotEmpty && totalTracked > 0)
            const Divider(height: 1, color: Color(0xFFF2F4F0)),

          // Items needing attention
          if (lowStockProducts.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lowStockProducts.length.clamp(0, 4),
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF2F4F0)),
              itemBuilder: (context, index) {
                final item = lowStockProducts[index];
                final isOut = item.isOutOfStock;
                final badgeColor = isOut ? const Color(0xFFDC2626) : const Color(0xFFD97706);

                return InkWell(
                  onTap: onViewInventory,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF1E2922),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (item.sku.trim().isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'SKU: ${item.sku}',
                                  style: const TextStyle(
                                    color: Color(0xFF86948B),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isOut
                                ? '0 left'
                                : '${item.currentQuantity} / min ${item.minimumQuantity}',
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          else if (!isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        products.isEmpty
                            ? 'Catalogue inventory active.'
                            : 'All inventory items are above minimum stock levels.',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF4B6354),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          '$label ($count)',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
