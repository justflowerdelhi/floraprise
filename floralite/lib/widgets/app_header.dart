import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/storage_mode_provider.dart';
import '../services/storage_mode_service.dart';

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
  final StorageModeService _storageModeService = StorageModeService();
  bool _isCloud = false;

  @override
  void initState() {
    super.initState();
    _loadStorageMode();
  }

  Future<void> _loadStorageMode() async {
    final isCloud = await _storageModeService.isCloud();
    if (!mounted) return;
    setState(() {
      _isCloud = isCloud;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final storageProvider = Provider.of<StorageModeProvider?>(context);
    final isCloud = storageProvider?.isCloud ?? _isCloud;

    final hasCustomTitle = widget.title != null &&
        widget.title!.trim().isNotEmpty &&
        widget.title!.trim() != 'Floraprise' &&
        (l10n == null || widget.title!.trim() != l10n.appTitle);

    return AppBar(
      automaticallyImplyLeading: widget.showBackButton,
      titleSpacing: widget.showBackButton ? 0 : 16,
      title: hasCustomTitle
          ? Text(
              widget.title!.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            )
          : null,
      bottom: widget.bottom,
      actions: [
        ...?widget.actions,
        if (isCloud)
          const Tooltip(
            message: 'Cloud Mode',
            triggerMode: TooltipTriggerMode.tap,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.language, size: 22),
            ),
          ),
        PopupMenuButton<String>(
          tooltip: 'Profile',
          onSelected: (value) async {
            await Navigator.pushNamed(context, value);
            if (mounted) {
              await _loadStorageMode();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
                value: '/shop-details',
                child: Text(l10n?.shopDetails ?? 'Shop Details')),
            PopupMenuItem(
                value: '/backup-restore',
                child: Text(l10n?.backup ?? 'Backup & Restore')),
            PopupMenuItem(
                value: '/settings',
                child: Text(l10n?.settingsTitle ?? 'Settings')),
            PopupMenuItem(
                value: '/about',
                child: Text(l10n?.about ?? 'About')),
          ],
          icon: const Icon(Icons.account_circle_rounded),
        ),
      ],
    );
  }
}
