import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'botanical_decorations.dart';

/// Top hero banner for the Floraprise Pro Web Dashboard.
/// Combines a personalized florist studio greeting, live date, subtle botanical
/// backdrop, and direct 1-tap Quick Action buttons.
class DashboardHeroHeader extends StatelessWidget {
  const DashboardHeroHeader({
    super.key,
    required this.shopName,
    this.ownerName,
    required this.onNewSale,
    required this.onNewOrder,
    required this.onAddProduct,
    required this.onDeliveryMap,
  });

  final String shopName;
  final String? ownerName;
  final VoidCallback onNewSale;
  final VoidCallback onNewOrder;
  final VoidCallback onAddProduct;
  final VoidCallback onDeliveryMap;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateString = DateFormat('EEEE, d MMMM yyyy').format(now);
    final displayName = shopName.trim().isNotEmpty
        ? shopName.trim()
        : (ownerName?.trim().isNotEmpty == true ? ownerName!.trim() : 'Florist Studio');

    final isDesktop = MediaQuery.sizeOf(context).width >= 800;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F3822),
            Color(0xFF1B5534),
            Color(0xFF23653E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F3822).withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Botanical leaf vector overlay
          const Positioned.fill(
            child: CustomPaint(
              painter: BotanicalHeroPainter(
                primaryColor: Color(0xFF2E7D32),
                accentColor: Color(0xFFD4A054),
                opacity: 0.22,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 28 : 20,
              vertical: isDesktop ? 26 : 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Date Pill & Studio Badge
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFD4A054).withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 13,
                              color: Color(0xFFE2C48D),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                dateString,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFF3E8D2),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4A054).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFD4A054).withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_florist_rounded,
                            size: 13,
                            color: Color(0xFFFFE082),
                          ),
                          SizedBox(width: 5),
                          Text(
                            'PRO CLOUD STUDIO',
                            style: TextStyle(
                              color: Color(0xFFFFE082),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Main Greeting
                Text(
                  '${_getGreeting()}, $displayName 🌸',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isDesktop ? 26 : 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Here's what's happening in your flower business today.",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: isDesktop ? 14.5 : 13.5,
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 22),

                // Quick Action Bar
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    _QuickActionButton(
                      icon: Icons.point_of_sale_rounded,
                      label: '+ New Sale',
                      isPrimary: true,
                      onTap: onNewSale,
                    ),
                    _QuickActionButton(
                      icon: Icons.receipt_long_rounded,
                      label: '+ New Order',
                      onTap: onNewOrder,
                    ),
                    _QuickActionButton(
                      icon: Icons.add_box_rounded,
                      label: '+ Add Product',
                      onTap: onAddProduct,
                    ),
                    _QuickActionButton(
                      icon: Icons.local_shipping_rounded,
                      label: 'Delivery Workspace',
                      onTap: onDeliveryMap,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatefulWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isPrimary
        ? const Color(0xFFD4A054)
        : (_isHovered
            ? Colors.white.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.12));

    final textColor = widget.isPrimary ? const Color(0xFF12341F) : Colors.white;
    final iconColor = widget.isPrimary ? const Color(0xFF12341F) : const Color(0xFFE2C48D);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -2 : 0, 0),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isPrimary
                ? const Color(0xFFFFD54F)
                : Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, size: 17, color: iconColor),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
