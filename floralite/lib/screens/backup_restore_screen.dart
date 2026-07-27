import 'package:flutter/material.dart';

import '../services/backup_service.dart';
import '../widgets/common_widgets.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  final BackupService _backupService = BackupService();
  bool _isBusy = false;

  Future<void> _createBackup() async {
    setState(() => _isBusy = true);
    try {
      final path = await _backupService.createManualBackup();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup created: $path')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _restoreBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup'),
        content: const Text(
          'Restoring replaces the local Floraprise database on this device. Your current data should be backed up first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isBusy = true);
    try {
      final restored = await _backupService.restoreManualBackup();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(restored ? 'Backup restored.' : 'Restore cancelled.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _showSupport() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Text(
          'Please contact Floraprise support with your registered phone number and shop name.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your business data is safe.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a manual backup before changing devices or restoring old data.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.cloud_upload_outlined),
                    title: const Text('Create Manual Backup'),
                    subtitle: const Text('Save a local database backup file.'),
                    trailing:
                        _isBusy ? const CircularProgressIndicator() : null,
                    onTap: _isBusy ? null : _createBackup,
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.restore_outlined),
                    title: const Text('Restore Backup'),
                    subtitle:
                        const Text('Restore from a Floraprise .db backup.'),
                    onTap: _isBusy ? null : _restoreBackup,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.cloud_queue_outlined),
                    title: const Text('Google Drive'),
                    subtitle:
                        const Text('Manual cloud backup connection for v1.'),
                    onTap: _isBusy ? null : _createBackup,
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.business_outlined),
                    title: const Text('Floraprise Cloud'),
                    subtitle:
                        const Text('Manual cloud backup connection for v1.'),
                    onTap: _isBusy ? null : _createBackup,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _showSupport,
              icon: const Icon(Icons.support_agent),
              label: const Text('Contact Support'),
            ),
          ],
        ),
      ),
    );
  }
}
