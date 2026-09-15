import 'package:flutter/material.dart';

import '../data/repositories/order_repository.dart';
import '../l10n/app_localizations.dart';
import '../widgets/app_header.dart';
import 'delivery_screen.dart';
import 'pickup_later_screen.dart';
import 'take_away_screen.dart';

class WalkinSalesScreen extends StatelessWidget {
  WalkinSalesScreen({
    super.key,
    this.prefillCustomerId,
    this.prefillCustomerName,
    this.prefillCustomerPhone,
    this.prefillRecipientName,
    this.prefillOccasion,
  });

  final String? prefillCustomerId;
  final String? prefillCustomerName;
  final String? prefillCustomerPhone;
  final String? prefillRecipientName;
  final String? prefillOccasion;
  final OrderRepository _orderRepository = OrderRepository();

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final l10n = AppLocalizations.of(context)!;

    if (prefillCustomerId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TakeAwayScreen(
              prefillCustomerId: prefillCustomerId,
              prefillCustomerName: prefillCustomerName,
              prefillCustomerPhone: prefillCustomerPhone,
              prefillRecipientName: prefillRecipientName,
              prefillOccasion: prefillOccasion,
            ),
          ),
        );
      });
    }

    return Scaffold(
      appBar: AppHeader(title: l10n.walkinSales),
      backgroundColor: const Color(0xFFF8F4EE),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 800;
            final width = constraints.maxWidth;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 1180 : 620),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(18, 16, 18, 12 + bottomInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.walkinSales,
                        style: TextStyle(
                          fontSize: isDesktop ? 22 : 19,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E2922),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.howCustomerReceiveOrder,
                        style: TextStyle(
                          fontSize: isDesktop ? 15 : 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E2922),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose an option to continue',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: isDesktop ? 2 : 1,
                          crossAxisSpacing: isDesktop ? 18 : 14,
                          mainAxisSpacing: isDesktop ? 18 : 14,
                          childAspectRatio: isDesktop
                              ? (width >= 1200 ? 2.15 : 1.95)
                              : 1.7,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _SelectionTile(
                              title: l10n.takeAway,
                              subtitle: l10n.takeAwayDesc,
                              accentColor: const Color(0xFF1E5E3A),
                              backgroundColor: const Color(0xFFEEF7F0),
                              surfaceColor: const Color(0xFFE6F4EB),
                              illustration: _TileIllustrationType.takeAway,
                              features: const ['Quick Sale', 'Scan Products', 'Payments'],
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TakeAwayScreen(
                                      prefillCustomerId: prefillCustomerId,
                                      prefillCustomerName: prefillCustomerName,
                                      prefillCustomerPhone: prefillCustomerPhone,
                                      prefillRecipientName: prefillRecipientName,
                                      prefillOccasion: prefillOccasion,
                                    ),
                                  ),
                                );
                              },
                            ),
                            _SelectionTile(
                              title: l10n.pickupLater,
                              subtitle: l10n.pickupLaterDesc,
                              accentColor: const Color(0xFFB67A2E),
                              backgroundColor: const Color(0xFFFCF7EE),
                              surfaceColor: const Color(0xFFF5EAD4),
                              illustration: _TileIllustrationType.pickupLater,
                              features: const ['Schedule Time', 'Customer Details', 'Notes'],
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PickupLaterScreen(
                                      prefillCustomerId: prefillCustomerId,
                                      prefillCustomerName: prefillCustomerName,
                                      prefillCustomerPhone: prefillCustomerPhone,
                                      prefillRecipientName: prefillRecipientName,
                                      prefillOccasion: prefillOccasion,
                                    ),
                                  ),
                                );
                              },
                            ),
                            _SelectionTile(
                              title: l10n.delivery,
                              subtitle: l10n.deliveryDesc,
                              accentColor: const Color(0xFF2D6BB6),
                              backgroundColor: const Color(0xFFF0F7FE),
                              surfaceColor: const Color(0xFFE3EFFA),
                              illustration: _TileIllustrationType.delivery,
                              features: const ['Address', 'Schedule', 'Track'],
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DeliveryScreen(
                                      prefillCustomerId: prefillCustomerId,
                                      prefillCustomerName: prefillCustomerName,
                                      prefillCustomerPhone: prefillCustomerPhone,
                                      prefillRecipientName: prefillRecipientName,
                                      prefillOccasion: prefillOccasion,
                                    ),
                                  ),
                                );
                              },
                            ),
                            FutureBuilder<int>(
                              future: _orderRepository.countDraftOrders(),
                              builder: (context, snapshot) {
                                final count = snapshot.data ?? 0;
                                final title = count > 0 ? 'Draft Orders ($count)' : 'Draft Orders';
                                return _SelectionTile(
                                  title: title,
                                  subtitle: 'Continue or manage saved draft orders.',
                                  accentColor: const Color(0xFF7153A6),
                                  backgroundColor: const Color(0xFFF8F4FF),
                                  surfaceColor: const Color(0xFFEDE5FF),
                                  illustration: _TileIllustrationType.draft,
                                  features: const ['Saved Drafts', 'Edit', 'Delete'],
                                  onTap: () => Navigator.pushNamed(context, '/draft-orders'),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

enum _TileIllustrationType {
  takeAway,
  pickupLater,
  delivery,
  draft,
}

class _SelectionTile extends StatefulWidget {
  const _SelectionTile({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.illustration,
    required this.features,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Color accentColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final _TileIllustrationType illustration;
  final List<String> features;
  final VoidCallback onTap;

  @override
  State<_SelectionTile> createState() => _SelectionTileState();
}

class _SelectionTileState extends State<_SelectionTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.accentColor.withOpacity(0.18);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hovering ? widget.accentColor.withOpacity(0.32) : borderColor,
            width: _hovering ? 1.4 : 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E2922).withOpacity(_hovering ? 0.08 : 0.05),
              blurRadius: _hovering ? 18 : 12,
              offset: Offset(0, _hovering ? 8 : 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(20),
            splashColor: widget.accentColor.withOpacity(0.08),
            highlightColor: widget.accentColor.withOpacity(0.04),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: widget.backgroundColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: _TileIllustration(
                      type: widget.illustration,
                      accentColor: widget.accentColor,
                      backgroundColor: widget.surfaceColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E2922),
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: widget.features.map((feature) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: widget.backgroundColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                feature,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: widget.accentColor,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 170),
                    curve: Curves.easeOut,
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.accentColor.withOpacity(_hovering ? 0.18 : 0.12),
                    ),
                    child: Transform.translate(
                      offset: Offset(_hovering ? 2 : 0, 0),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: widget.accentColor,
                      ),
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

class _TileIllustration extends StatelessWidget {
  const _TileIllustration({
    required this.type,
    required this.accentColor,
    required this.backgroundColor,
  });

  final _TileIllustrationType type;
  final Color accentColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TilePainter(type: type, accentColor: accentColor, backgroundColor: backgroundColor),
      child: const SizedBox(width: 96, height: 96),
    );
  }
}

class _TilePainter extends CustomPainter {
  const _TilePainter({
    required this.type,
    required this.accentColor,
    required this.backgroundColor,
  });

  final _TileIllustrationType type;
  final Color accentColor;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = accentColor.withOpacity(0.7);

    switch (type) {
      case _TileIllustrationType.takeAway:
        paint.color = const Color(0xFFFFFFFF);
        final bag = RRect.fromRectAndRadius(
          Rect.fromLTWH(22, 36, 56, 42),
          const Radius.circular(14),
        );
        canvas.drawRRect(bag, paint);
        final handle = Path()
          ..moveTo(34, 42)
          ..quadraticBezierTo(30, 18, 48, 20)
          ..quadraticBezierTo(66, 20, 62, 42);
        canvas.drawPath(handle, stroke);

        final flowerCenter = const Color(0xFFB9A164);
        final petals = [
          Offset(24, 18),
          Offset(40, 12),
          Offset(54, 18),
          Offset(60, 30),
          Offset(46, 32),
          Offset(32, 30),
        ];
        for (final petal in petals) {
          canvas.drawCircle(petal, 7, Paint()..color = const Color(0xFFB9E3B6));
        }
        canvas.drawCircle(const Offset(42, 24), 8, Paint()..color = flowerCenter);
        canvas.drawCircle(const Offset(48, 25), 6, Paint()..color = const Color(0xFFD9A661));
        break;
      case _TileIllustrationType.pickupLater:
        paint.color = const Color(0xFFFAF0D6);
        final box = RRect.fromRectAndRadius(
          Rect.fromLTWH(25, 48, 48, 28),
          const Radius.circular(10),
        );
        canvas.drawRRect(box, paint);
        canvas.drawLine(const Offset(29, 48), const Offset(29, 80), stroke);
        canvas.drawLine(const Offset(69, 48), const Offset(69, 80), stroke);
        canvas.drawLine(const Offset(25, 52), const Offset(73, 52), stroke);
        paint.color = const Color(0xFFD9A661);
        final stem = pathForStem();
        canvas.drawPath(stem, paint);
        canvas.drawCircle(const Offset(46, 34), 7, Paint()..color = const Color(0xFFD98C5A));
        canvas.drawCircle(const Offset(54, 28), 7, Paint()..color = const Color(0xFF8CB28E));
        canvas.drawCircle(const Offset(38, 26), 7, Paint()..color = const Color(0xFFB7C47E));
        paint.color = accentColor.withOpacity(0.18);
        canvas.drawCircle(const Offset(68, 24), 12, paint);
        stroke.color = accentColor.withOpacity(0.8);
        canvas.drawCircle(const Offset(68, 24), 10, stroke);
        canvas.drawLine(const Offset(68, 36), const Offset(68, 42), stroke);
        canvas.drawLine(const Offset(60, 24), const Offset(68, 24), stroke);
        break;
      case _TileIllustrationType.delivery:
        paint.color = const Color(0xFFFFFFFF);
        final box = RRect.fromRectAndRadius(
          Rect.fromLTWH(32, 40, 34, 25),
          const Radius.circular(8),
        );
        canvas.drawRRect(box, paint);
        canvas.drawLine(const Offset(32, 52), const Offset(66, 52), stroke);
        paint.color = const Color(0xFFB8D9FF);
        canvas.drawCircle(const Offset(37, 68), 12, paint);
        canvas.drawCircle(const Offset(63, 68), 12, paint);
        paint.color = const Color(0xFF8FB7F9);
        canvas.drawRect(Rect.fromLTWH(20, 52, 56, 8), paint);
        paint.color = const Color(0xFFB9E5C4);
        canvas.drawCircle(const Offset(48, 30), 8, paint);
        canvas.drawCircle(const Offset(54, 24), 7, paint);
        canvas.drawCircle(const Offset(42, 24), 7, paint);
        canvas.drawLine(const Offset(48, 38), const Offset(48, 52), stroke);
        break;
      case _TileIllustrationType.draft:
        final page = RRect.fromRectAndRadius(
          Rect.fromLTWH(24, 22, 50, 56),
          const Radius.circular(10),
        );
        paint.color = const Color(0xFFFFFFFF);
        canvas.drawRRect(page, paint);
        stroke.color = accentColor.withOpacity(0.5);
        canvas.drawLine(const Offset(30, 36), const Offset(64, 36), stroke);
        canvas.drawLine(const Offset(30, 44), const Offset(64, 44), stroke);
        canvas.drawLine(const Offset(30, 52), const Offset(58, 52), stroke);
        canvas.drawLine(const Offset(30, 60), const Offset(62, 60), stroke);
        paint.color = const Color(0xFFD6C5ED);
        canvas.drawCircle(const Offset(48, 16), 9, paint);
        paint.color = const Color(0xFFB8D8A6);
        canvas.drawCircle(const Offset(40, 14), 7, paint);
        canvas.drawCircle(const Offset(56, 14), 7, paint);
        break;
    }
  }

  Path pathForStem() {
    final path = Path();
    path.moveTo(52, 48);
    path.quadraticBezierTo(54, 36, 46, 24);
    path.quadraticBezierTo(40, 30, 40, 42);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
