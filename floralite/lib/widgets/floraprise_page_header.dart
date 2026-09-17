import 'package:flutter/material.dart';

import 'dashboard/botanical_decorations.dart';

enum FloraprisePageHeaderVariant { compact, standard }

class FloraprisePageHeader extends StatelessWidget {
  const FloraprisePageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
    this.actions = const [],
    this.badge,
    this.variant = FloraprisePageHeaderVariant.standard,
    this.decorationAlignment = Alignment.centerRight,
  });

  final String title;
  final String subtitle;
  final IconData? icon;
  final List<Widget> actions;
  final Widget? badge;
  final FloraprisePageHeaderVariant variant;
  final Alignment decorationAlignment;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 800;

  @override
  Widget build(BuildContext context) {
    if (!isDesktop(context)) return const SizedBox.shrink();

    final isCompact = variant == FloraprisePageHeaderVariant.compact;
    final verticalPadding = isCompact ? 16.0 : 20.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: isCompact ? 90 : 104),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
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
              color: const Color(0xFF0F3822).withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: decorationAlignment,
                child: const FractionallySizedBox(
                  widthFactor: 0.62,
                  heightFactor: 1,
                  child: CustomPaint(
                    painter: BotanicalHeroPainter(
                      primaryColor: Color(0xFF2E7D32),
                      accentColor: Color(0xFFD4A054),
                      opacity: 0.11,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 24,
                vertical: verticalPadding,
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFD4A054)
                              .withValues(alpha: 0.28),
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 22,
                        color: const Color(0xFFFFE082),
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                ),
                              ),
                            ),
                            if (badge != null) ...[
                              const SizedBox(width: 10),
                              badge!,
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (actions.isNotEmpty) ...[
                    const SizedBox(width: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: actions,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FloraprisePageHeaderAction extends StatelessWidget {
  const FloraprisePageHeaderAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
    this.tooltip,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = primary
        ? const Color(0xFF173522)
        : Colors.white.withValues(alpha: 0.94);

    return Tooltip(
      message: tooltip ?? label,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(label),
        style: FilledButton.styleFrom(
          foregroundColor: foregroundColor,
          backgroundColor: primary
              ? const Color(0xFFE2C48D)
              : Colors.white.withValues(alpha: 0.11),
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.06),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: primary
                  ? const Color(0xFFE2C48D)
                  : Colors.white.withValues(alpha: 0.20),
            ),
          ),
        ),
      ),
    );
  }
}