import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data/database/app_database.dart';
import '../data/repositories/pos_sync_outbox_repository.dart';
import '../managers/onboarding_manager.dart';
import '../l10n/app_localizations.dart';
import '../models/storage_mode.dart';
import '../presentation/splash/splash_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../providers/storage_mode_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/pos_sale_sync_service.dart';
import '../services/storage_migration_service.dart';
import '../widgets/app_header.dart';
import '../widgets/common_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final OnboardingManager _onboardingManager = OnboardingManager();
  bool _isSyncingPendingPosSales = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<LanguageProvider>().loadSavedLanguage();
      }
    });
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.selectLanguage,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildLanguageOption(sheetContext, 'en', '🇬🇧 English'),
            _buildLanguageOption(sheetContext, 'hi', '🇮🇳 हिन्दी'),
            _buildLanguageOption(sheetContext, 'gu', '🇮🇳 ગુજરાતી'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext sheetContext,
    String localeCode,
    String label,
  ) {
    final languageProvider = context.watch<LanguageProvider>();
    final isSelected =
        languageProvider.currentLocale.languageCode == localeCode;
    return ListTile(
      title: Text(label),
      trailing:
          isSelected ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: () async {
        Navigator.of(sheetContext).pop();
        await context.read<LanguageProvider>().setLanguage(localeCode);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final l10n = AppLocalizations.of(context)!;
    final subscription = context.watch<SubscriptionProvider>();
    final storageMode = context.watch<StorageModeProvider>().effectiveMode;
    final subscriptionSummary = _subscriptionSummary(subscription);

    return Scaffold(
      appBar: AppHeader(title: l10n.settingsTitle),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
          children: [
            AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Icon(
                          Icons.store,
                          color: colorScheme.primary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.appTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Version 1.0.0',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Business',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                children: [
                  _buildSettingTile(
                    context,
                    'Shop Details',
                    'Business information and settings',
                    Icons.store,
                    () => Navigator.pushNamed(context, '/shop-details'),
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    context,
                    'Printer Settings',
                    'Bluetooth printer, receipts and queue',
                    Icons.print_rounded,
                    () => Navigator.pushNamed(context, '/printer-settings'),
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    context,
                    'Share Branding',
                    'Design share watermark, price and footer style',
                    Icons.share_outlined,
                    () => Navigator.pushNamed(context, '/share-branding'),
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    context,
                    'Rewards Settings',
                    'Customer points and redemption rules',
                    Icons.redeem,
                    () => Navigator.pushNamed(context, '/rewards-settings'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Subscription',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                children: [
                  _buildSettingTile(
                    context,
                    'Subscription & License',
                    subscriptionSummary,
                    Icons.workspace_premium,
                    () => Navigator.pushNamed(context, '/subscription'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                children: [
                  _buildSettingTile(
                    context,
                    'Storage & Data',
                    'Current storage: ${storageMode.label}',
                    Icons.storage_rounded,
                    _showStorageDataDialog,
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    context,
                    'Backup & Restore',
                    'Manual backup and restore',
                    Icons.backup,
                    () => Navigator.pushNamed(context, '/backup-restore'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'App',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                children: [
                  _buildSettingTile(
                    context,
                    l10n.language,
                    _getLanguageLabel(),
                    Icons.language,
                    _showLanguageSelector,
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    context,
                    'Logout',
                    'Sign out from this device',
                    Icons.logout,
                    _logout,
                    isDanger: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildDeveloperSection(context, l10n),
            const SizedBox(height: 24),
            Center(
              child: Text(
                l10n.madeWithLove,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getLanguageLabel() {
    final languageProvider = context.watch<LanguageProvider>();
    final localeCode = languageProvider.currentLocale.languageCode;
    if (localeCode == 'hi') return 'हिन्दी';
    if (localeCode == 'gu') return 'ગુજરાતી';
    return 'English';
  }

  String _subscriptionSummary(SubscriptionProvider provider) {
    final access = provider.access;
    if (provider.isLoading && access == null) return 'Loading subscription';
    if (access == null) return 'Plan, renewal and restore purchase';
    final record = access.record;
    final expiry = DateFormat('dd MMM yyyy').format(record.expiryDate);
    final remaining = access.daysRemaining(DateTime.now());
    return '${record.plan.label} • Expires $expiry • $remaining days left';
  }

  Future<void> _showStorageDataDialog() async {
    final mode = context.read<StorageModeProvider>().effectiveMode;
    const migrationService = StorageMigrationService();
    final target = mode == StorageMode.local ? StorageMode.cloud : StorageMode.local;
    final migration = await migrationService.previewModeChange(
      from: mode,
      to: target,
    );
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage & Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current storage: ${mode.label}'),
            const SizedBox(height: 12),
            Text(migration.message),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback? onTap, {
    bool isDanger = false,
  }) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDanger
                  ? Colors.red
                  : (enabled ? null : Colors.grey.shade500),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isDanger
                          ? Colors.red
                          : (enabled ? null : Colors.grey.shade600),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (enabled)
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              )
            else
              Icon(
                Icons.lock_outline,
                size: 18,
                color: Colors.grey.shade400,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _resetOnboarding() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resetOnboarding),
        content: Text(l10n.resetOnboardingDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _onboardingManager.resetOnboarding();
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Do you want to logout from this device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    await context.read<AuthProvider>().logout();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }

  Future<void> _syncPendingPosSalesForDebug() async {
    if (_isSyncingPendingPosSales) return;
    setState(() => _isSyncingPendingPosSales = true);

    final outboxRepository = PosSyncOutboxRepository();
    PosSaleSyncResult? result;
    List<PosSyncOutboxRecord> beforeRows = const [];
    List<PosSyncOutboxRecord> remainingRows = const [];
    List<Map<String, Object?>> syncedRows = const [];
    Object? failure;

    try {
      final db = await AppDatabase.instance.database;
      beforeRows = await outboxRepository.listRetryable(db);
      result = await PosSaleSyncService(
        outboxRepository: outboxRepository,
      ).syncPending();
      remainingRows = await outboxRepository.listRetryable(db);
      syncedRows = await _loadPosSyncOutboxRowsByIds(
        beforeRows.map((row) => row.id).toList(),
      );
    } catch (error) {
      failure = error;
      try {
        final db = await AppDatabase.instance.database;
        remainingRows = await outboxRepository.listRetryable(db);
        syncedRows = await _loadPosSyncOutboxRowsByIds(
          beforeRows.map((row) => row.id).toList(),
        );
      } catch (_) {}
    } finally {
      if (mounted) {
        setState(() => _isSyncingPendingPosSales = false);
      }
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync Pending POS Sales'),
        content: SingleChildScrollView(
          child: SelectableText(
            _buildPosSaleSyncDebugReport(
              pendingBefore: beforeRows.length,
              result: result,
              remainingRetryable: remainingRows.length,
              syncedRows: syncedRows,
              failure: failure,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, Object?>>> _loadPosSyncOutboxRowsByIds(
    List<int> ids,
  ) async {
    if (ids.isEmpty) return const [];
    final db = await AppDatabase.instance.database;
    final placeholders = List.filled(ids.length, '?').join(', ');
    return db.query(
      'pos_sync_outbox',
      columns: [
        'id',
        'local_order_id',
        'state',
        'attempt_count',
        'cloud_order_id',
        'last_error',
        'next_attempt_at',
        'last_attempt_at',
      ],
      where: 'id IN ($placeholders)',
      whereArgs: ids,
      orderBy: 'created_at ASC, id ASC',
    );
  }

  String _buildPosSaleSyncDebugReport({
    required int pendingBefore,
    required PosSaleSyncResult? result,
    required int remainingRetryable,
    required List<Map<String, Object?>> syncedRows,
    required Object? failure,
  }) {
    final buffer = StringBuffer()
      ..writeln('Retryable pending before: $pendingBefore')
      ..writeln('Attempted: ${result?.processedCount ?? 0}')
      ..writeln('Completed: ${result?.completedCount ?? 0}')
      ..writeln('Failed: ${result?.failedCount ?? 0}')
      ..writeln('Remaining retryable pending: $remainingRetryable');

    final cloudOrderIds = syncedRows
        .map((row) => row['cloud_order_id']?.toString())
        .where((value) => value != null && value.trim().isNotEmpty)
        .cast<String>()
        .toList();
    buffer.writeln(
      'Cloud order IDs: ${cloudOrderIds.isEmpty ? 'none' : cloudOrderIds.join(', ')}',
    );

    final rowErrors = syncedRows
        .map((row) => row['last_error']?.toString())
        .where((value) => value != null && value.trim().isNotEmpty)
        .cast<String>()
        .toList();
    if (failure != null) {
      buffer.writeln('Sync exception: $failure');
    }
    buffer.writeln(
      'Outbox errors: ${rowErrors.isEmpty ? 'none' : rowErrors.join('\n')}',
    );

    if (syncedRows.isNotEmpty) {
      buffer.writeln('Outbox rows:');
      for (final row in syncedRows) {
        buffer.writeln(
          '#${row['id']} order=${row['local_order_id']} state=${row['state']} attempts=${row['attempt_count']} next=${row['next_attempt_at'] ?? 'none'}',
        );
      }
    }

    return buffer.toString().trimRight();
  }

  Widget _buildDeveloperSection(BuildContext context, AppLocalizations l10n) {
    // Only show in debug builds
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Developer',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.orange.shade700,
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            children: [
              _buildSettingTile(
                context,
                l10n.resetOnboarding,
                l10n.resetOnboardingSubtitle,
                Icons.restart_alt,
                _resetOnboarding,
              ),
              const Divider(height: 1),
              _buildSettingTile(
                context,
                'Sync Pending POS Sales',
                _isSyncingPendingPosSales
                    ? 'Sync in progress'
                    : 'Temporary debug action for stored POS sale outbox rows',
                Icons.cloud_upload_outlined,
                _isSyncingPendingPosSales ? null : _syncPendingPosSalesForDebug,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
