import 'package:flutter/material.dart';

import 'business_logo.dart';

class BusinessIdentity extends StatelessWidget {
  const BusinessIdentity({
    super.key,
    required this.name,
    this.subtitle = '',
    this.logoPath = '',
    this.logoSize = 36,
    this.nameFontSize = 14,
  });

  final String name;
  final String subtitle;
  final String logoPath;
  final double logoSize;
  final double nameFontSize;

  @override
  Widget build(BuildContext context) {
    final displayName = name.trim().isEmpty ? 'Business' : name.trim();
    final displaySubtitle = _visibleSubtitle(subtitle);

    return Row(
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: buildBusinessLogo(logoPath, size: logoSize - 10),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: nameFontSize,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (displaySubtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  displaySubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _visibleSubtitle(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty ||
        normalized.contains('registered from mobile onboarding') ||
        normalized.contains('mobile onboarding') ||
        normalized.contains('registration method') ||
        normalized.contains('onboarding method')) {
      return '';
    }
    return value.trim();
  }
}