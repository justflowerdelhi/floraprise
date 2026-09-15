import 'package:flutter/material.dart';
import '../../models/dashboard_summary.dart';

/// Performance & KPI section for Floraprise Pro Web Dashboard.
/// Features Today's Sales as the primary visual hero KPI, paired with
/// contextual operational pods (Orders, AOV, Deliveries, Expenses).
class DashboardKpiSection extends StatelessWidget {
  const DashboardKpiSection({
    super.key,
    required this.summary,
    required this.onSalesTap,
    required this.onOrdersTap,
    required this.onDeliveriesTap,
    required this.onExpensesTap,
  });

  final DashboardSummary summary;
  final VoidCallback onSalesTap;
  final VoidCallback onOrdersTap;
  final VoidCallback onDeliveriesTap;
  final VoidCallback onExpensesTap;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;
    final isTablet = MediaQuery.sizeOf(context).width >= 700;

    final salesRupees = (summary.todaySalesAmount / 100).toStringAsFixed(0);
    final expenseRupees = (summary.todayExpenses / 100).toStringAsFixed(0);
    final aovRupees = summary.todayOrderCount > 0
        ? (summary.todaySalesAmount / summary.todayOrderCount / 100).toStringAsFixed(0)
        : '0';

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero KPI: Today's Sales (Takes ~38% width on wide desktop)
          Expanded(
            flex: 38,
            child: _HeroSalesCard(
              salesRupees: salesRupees,
              orderCount: summary.todayOrderCount,
              onTap: onSalesTap,
            ),
          ),
          const SizedBox(width: 16),

          // Secondary KPIs (2x2 Grid taking remaining width)
          Expanded(
            flex: 62,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.receipt_long_rounded,
                        accentColor: const Color(0xFFD97706),
                        title: "Today's Orders",
                        value: '${summary.todayOrderCount}',
                        subtitle: summary.preparingOrders > 0
                            ? '${summary.preparingOrders} in preparation'
                            : 'All current orders active',
                        onTap: onOrdersTap,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.auto_graph_rounded,
                        accentColor: const Color(0xFF0D9488),
                        title: 'Average Order Value',
                        value: '₹$aovRupees',
                        subtitle: 'Per order today',
                        onTap: onSalesTap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.local_shipping_rounded,
                        accentColor: const Color(0xFF2563EB),
                        title: 'Pending Deliveries',
                        value: '${summary.outForDeliveryOrders}',
                        subtitle: summary.todayDeliveryCount > 0
                            ? '${summary.todayDeliveryCount} scheduled today'
                            : 'On-schedule dispatch',
                        onTap: onDeliveriesTap,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.account_balance_wallet_rounded,
                        accentColor: const Color(0xFF7C3AED),
                        title: "Today's Expenses",
                        value: '₹$expenseRupees',
                        subtitle: 'Recorded shop expenses',
                        onTap: onExpensesTap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (isTablet) {
      return Column(
        children: [
          _HeroSalesCard(
            salesRupees: salesRupees,
            orderCount: summary.todayOrderCount,
            onTap: onSalesTap,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.receipt_long_rounded,
                  accentColor: const Color(0xFFD97706),
                  title: "Today's Orders",
                  value: '${summary.todayOrderCount}',
                  subtitle: '${summary.preparingOrders} preparing',
                  onTap: onOrdersTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.auto_graph_rounded,
                  accentColor: const Color(0xFF0D9488),
                  title: 'AOV',
                  value: '₹$aovRupees',
                  subtitle: 'Avg order value',
                  onTap: onSalesTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.local_shipping_rounded,
                  accentColor: const Color(0xFF2563EB),
                  title: 'Deliveries',
                  value: '${summary.outForDeliveryOrders}',
                  subtitle: 'Pending dispatch',
                  onTap: onDeliveriesTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.account_balance_wallet_rounded,
                  accentColor: const Color(0xFF7C3AED),
                  title: 'Expenses',
                  value: '₹$expenseRupees',
                  subtitle: 'Outgoings',
                  onTap: onExpensesTap,
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Mobile single column layout
    return Column(
      children: [
        _HeroSalesCard(
          salesRupees: salesRupees,
          orderCount: summary.todayOrderCount,
          onTap: onSalesTap,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.receipt_long_rounded,
                accentColor: const Color(0xFFD97706),
                title: 'Orders',
                value: '${summary.todayOrderCount}',
                subtitle: '${summary.preparingOrders} preparing',
                onTap: onOrdersTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.auto_graph_rounded,
                accentColor: const Color(0xFF0D9488),
                title: 'AOV',
                value: '₹$aovRupees',
                subtitle: 'Avg value',
                onTap: onSalesTap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.local_shipping_rounded,
                accentColor: const Color(0xFF2563EB),
                title: 'Deliveries',
                value: '${summary.outForDeliveryOrders}',
                subtitle: 'Active now',
                onTap: onDeliveriesTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.account_balance_wallet_rounded,
                accentColor: const Color(0xFF7C3AED),
                title: 'Expenses',
                value: '₹$expenseRupees',
                subtitle: 'Today',
                onTap: onExpensesTap,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroSalesCard extends StatefulWidget {
  const _HeroSalesCard({
    required this.salesRupees,
    required this.orderCount,
    required this.onTap,
  });

  final String salesRupees;
  final int orderCount;
  final VoidCallback onTap;

  @override
  State<_HeroSalesCard> createState() => _HeroSalesCardState();
}

class _HeroSalesCardState extends State<_HeroSalesCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isHovered
                ? const Color(0xFF2E7D32).withValues(alpha: 0.5)
                : const Color(0xFFE2E6DF),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E5E3A).withValues(alpha: _isHovered ? 0.12 : 0.05),
              blurRadius: _isHovered ? 16 : 8,
              offset: Offset(0, _isHovered ? 6 : 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.payments_rounded,
                          color: Color(0xFF2E7D32),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "TODAY'S SALES",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFF4B6354),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              "Primary Studio Revenue",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFF829489),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F8F4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Reports',
                              style: TextStyle(
                                color: Color(0xFF2E7D32),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10,
                              color: Color(0xFF2E7D32),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      Text(
                        '₹${widget.salesRupees}',
                        style: const TextStyle(
                          color: Color(0xFF143823),
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          height: 1,
                        ),
                      ),
                      Text(
                        'from ${widget.orderCount} order${widget.orderCount == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: Color(0xFF6B7F72),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          size: 13,
                          color: Color(0xFF2E7D32),
                        ),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Live Cloud POS Synchronized',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF3B5646),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
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

class _MetricCard extends StatefulWidget {
  const _MetricCard({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String value;
  final String subtitle;
  final VoidCallback onTap;

  @override
  State<_MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<_MetricCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -2 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? widget.accentColor.withValues(alpha: 0.45)
                : const Color(0xFFE5E7DF),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isHovered ? 0.06 : 0.02),
              blurRadius: _isHovered ? 12 : 4,
              offset: Offset(0, _isHovered ? 4 : 1),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: widget.accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          widget.icon,
                          size: 18,
                          color: widget.accentColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF5F6E65),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.value,
                    style: const TextStyle(
                      color: Color(0xFF1E2922),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF86948B),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
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
