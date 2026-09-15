import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../managers/business_settings_manager.dart';
import '../providers/storage_mode_provider.dart';
import '../services/storage_mode_service.dart';
import 'business_identity.dart';

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
  final StorageModeService _storageModeService = StorageModeService();
  String _shopName = '';
  String _businessSubtitle = '';
  String _logoPath = '';
  bool _isCloud = false;

  @override
  void initState() {
    super.initState();
    BusinessSettingsManager.changeNotifier.addListener(_onSettingsChanged);
    _loadStorageModeAndShopName();
  }

  @override
  void dispose() {
    BusinessSettingsManager.changeNotifier.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    _loadStorageModeAndShopName();
  }

  Future<void> _loadStorageModeAndShopName() async {
    final isCloud = await _storageModeService.isCloud();
    final settings = await _businessSettingsManager.load();
    if (!mounted) return;
    setState(() {
      _isCloud = isCloud;
      _shopName = settings.shopName.trim();
      _businessSubtitle = settings.subtitle.trim();
      _logoPath = settings.logoPath.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final storageProvider = Provider.of<StorageModeProvider?>(context);
    final isCloud = storageProvider?.isCloud ?? _isCloud;

    final isDefaultTitle = widget.title == null ||
        widget.title!.trim().isEmpty ||
        widget.title!.trim() == 'Floraprise' ||
        (l10n != null && widget.title!.trim() == l10n.appTitle);

    return AppBar(
      automaticallyImplyLeading: widget.showBackButton,
      titleSpacing: widget.showBackButton ? 0 : 16,
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isDefaultTitle)
                  BusinessIdentity(
                    name: _shopName,
                    subtitle: _businessSubtitle,
                    logoPath: _logoPath,
                    logoSize: 32,
                    nameFontSize: 14,
                  )
                else
                  Text(
                    widget.title!.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
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
              await _loadStorageModeAndShopName();
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
