import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: backgroundColor,
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

class AppChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? selectedColor;

  const AppChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => onTap?.call(),
      selectedColor:
          selectedColor?.withValues(alpha: 0.2) ?? colorScheme.primaryContainer,
      checkmarkColor: selectedColor ?? colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected
            ? (selectedColor ?? colorScheme.primary)
            : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class TimelineCard extends StatelessWidget {
  final String time;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const TimelineCard({
    super.key,
    required this.time,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return AppCard(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 360 || textScale > 1.15;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 56,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isCompact)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            time,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              time,
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                      maxLines: isCompact ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 148),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 24,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class TileButton extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const TileButton({
    super.key,
    required this.emoji,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tileColor = color ?? colorScheme.primary;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 148),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final iconSize = constraints.maxWidth < 160 ? 40.0 : 48.0;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  emoji,
                  style: TextStyle(fontSize: iconSize),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: tileColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class AppSearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;

  const AppSearchBar({
    super.key,
    required this.hintText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.grey.shade600),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WhatsAppButton extends StatelessWidget {
  final VoidCallback onTap;

  const WhatsAppButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green.shade600,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'WhatsApp',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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
