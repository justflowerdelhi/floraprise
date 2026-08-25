import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../managers/business_settings_manager.dart';

class AppHeader extends StatefulWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    this.title,
    this.showBackButton = false,
    this.actions,
    this.bottom,
  });

  final String? title;
  final bool showBackButton;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  final BusinessSettingsManager _businessSettingsManager =
      BusinessSettingsManager();
  String _shopName = 'My Flower Shop';

  @override
  void initState() {
    super.initState();
    _loadShopName();
  }

  Future<void> _loadShopName() async {
    final settings = await _businessSettingsManager.load();
    if (!mounted) return;
    setState(() {
      _shopName = settings.shopName.trim().isEmpty
          ? 'My Flower Shop'
          : settings.shopName.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return AppBar(
      automaticallyImplyLeading: widget.showBackButton,
      titleSpacing: widget.showBackButton ? 0 : 16,
      title: Row(
        children: [
          Image.asset('assets/icon.png', width: 28, height: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title?.trim().isNotEmpty == true
                      ? widget.title!.trim()
                      : 'Floraprise',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  _shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottom: widget.bottom,
      actions: [
        ...?widget.actions,
        PopupMenuButton<String>(
          tooltip: 'Profile',
          onSelected: (value) => Navigator.pushNamed(context, value),
          itemBuilder: (context) => [
            PopupMenuItem(
                value: '/shop-details', child: Text(l10n.shopDetails)),
            PopupMenuItem(value: '/backup-restore', child: Text(l10n.backup)),
            PopupMenuItem(value: '/settings', child: Text(l10n.settingsTitle)),
            PopupMenuItem(value: '/about', child: Text(l10n.about)),
          ],
          icon: const Icon(Icons.account_circle_rounded),
        ),
      ],
    );
  }
}
