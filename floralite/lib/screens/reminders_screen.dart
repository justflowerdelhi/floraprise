import 'dart:io';
import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/repositories/occasion_repository.dart';
import '../l10n/app_localizations.dart';
import '../managers/occasion_import_manager.dart';
import '../providers/occasion_provider.dart';
import '../providers/customer_provider.dart';
import '../services/contact_picker_service.dart';
import '../utils/whatsapp_phone_utils.dart';
import '../widgets/common_widgets.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final OccasionRepository _occasionRepository = OccasionRepository();
  late final OccasionImportManager _importManager;
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<List<String>> _customRelationships = ValueNotifier(
    const [],
  );

  bool _isImporting = false;
  DateTime? _selectedCalendarDate;

  static const List<String> _filters = [
    'All',
    'Today',
    'Tomorrow',
    'Next 3 Days',
    'Birthday',
    'Anniversary',
    'Festival',
    'Payment',
    'Delivery',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    _importManager = OccasionImportManager(_occasionRepository);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadCustomRelationships();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customRelationships.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reminders),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _showCalendarPicker,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<OccasionProvider>().refresh(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'import') {
                _importCustomers();
                return;
              }
              if (value == 'template') {
                _downloadSampleTemplate();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'import',
                enabled: !_isImporting,
                child: const Text('Import Occasion Contacts'),
              ),
              const PopupMenuItem(
                value: 'template',
                child: Text('Download Sample Template'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _buildBody(context, colorScheme, bottomInset, l10n),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ColorScheme colorScheme,
    double bottomInset,
    AppLocalizations l10n,
  ) {
    return Consumer<OccasionProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(provider.error!),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => provider.refresh(),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
          children: [
            _buildSearchAndFilter(provider),
            const SizedBox(height: 20),
            _buildFollowupSection(
              title: 'Today\'s Follow-ups',
              records: provider.today,
              emptyText: 'No follow-ups for today.',
              emptyHint: 'Tap Add Reminder to create your first reminder.',
            ),
            const SizedBox(height: 16),
            _buildFollowupSection(
              title: 'Upcoming',
              records: provider.upcoming,
              emptyText: 'No upcoming reminders.',
              emptyHint: 'Tap Add Reminder to schedule one.',
            ),
            const SizedBox(height: 16),
            _buildFollowupSection(
              title: 'Completed',
              records: provider.completed,
              emptyText: 'No completed follow-ups.',
              emptyHint: 'Completed reminders will appear here.',
            ),
            const SizedBox(height: 16),
            _buildFollowupSection(
              title: 'Festival',
              records: provider.festival,
              emptyText: 'No festival reminders.',
              emptyHint: 'Festival follow-ups will appear here.',
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchAndFilter(OccasionProvider provider) {
    return AppCard(
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search customer, recipient, phone, occasion',
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              provider.setSearchQuery(value);
            },
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final value = _filters[index];
                final selected = provider.selectedFilter == value;
                return ChoiceChip(
                  label: Text(value),
                  selected: selected,
                  onSelected: (_) => provider.setFilter(value),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _showAddReminderDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Reminder'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowupSection({
    required String title,
    required List<OccasionFollowUpRecord> records,
    required String emptyText,
    required String emptyHint,
  }) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final validRecords = records.where((record) {
      final parts = record.subtitle.split(' • ');
      final customerName = parts.length > 2 ? parts[2] : '';
      final recipientName = record.title;
      return customerName.isNotEmpty && recipientName.isNotEmpty;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        if (validRecords.isEmpty)
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emptyText,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        emptyHint,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ...validRecords.map((record) {
          final parts = record.subtitle.split(' • ');
          final occasion = parts.isNotEmpty ? parts[0] : '';
          final relationship = parts.length > 1 ? parts[1] : '';
          final customerName = parts.length > 2 ? parts[2] : '';
          final isToday =
              DateTime(record.date.year, record.date.month, record.date.day)
                  .isAtSameMomentAs(todayDate);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isToday)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '🔥 TODAY',
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (isToday) const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person,
                                    size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  'Customer',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              customerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) => _onReminderAction(value, record),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'view',
                            child: Text('View'),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          if (record.sourceType == 'occasion')
                            const PopupMenuItem(
                              value: 'new_order',
                              child: Text('Create New Order'),
                            ),
                          if (record.isManual)
                            const PopupMenuItem(
                              value: 'delete_manual',
                              child: Text('Delete'),
                            ),
                        ],
                        icon: const Icon(Icons.more_vert),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.card_giftcard,
                          size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Recipient',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${record.title} ($relationship)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.event, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        occasion,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(record.date),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _onReminderAction('call', record),
                          icon: const Icon(Icons.phone, size: 16),
                          label: const Text('Call'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () =>
                              _onReminderAction('whatsapp', record),
                          icon: const Icon(Icons.chat, size: 16),
                          label: const Text('WhatsApp'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _showCalendarPicker() async {
    final provider = context.read<OccasionProvider>();
    final now = DateTime.now();
    final initialDate = _selectedCalendarDate ?? now;

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      selectableDayPredicate: (day) {
        // All days are selectable
        return true;
      },
      // Note: Standard showDatePicker doesn't support custom day indicators
      // For full calendar with indicators, we would need a custom calendar widget
      // This is a simplified implementation
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedCalendarDate = selected;
      });
      // Filter reminders for the selected date
      await provider.setSearchQuery('');
      await provider.setCalendarDate(selected);
    }
  }

  Future<void> _downloadSampleTemplate() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = p.join(dir.path, 'floraprise_occasions_template.csv');
      await File(path)
          .writeAsString(OccasionImportManager.buildSampleTemplateCsv());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Template saved: $path')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Unable to download template. Please try again.')),
      );
    }
  }

  Future<void> _importCustomers() async {
    setState(() => _isImporting = true);
    try {
      final picked = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(label: 'Import Files', extensions: ['csv', 'xlsx']),
        ],
      );

      if (picked == null) {
        if (!mounted) return;
        setState(() => _isImporting = false);
        return;
      }

      final filePath = picked.path;
      final preview = await _importManager.prepareImport(filePath);
      if (!mounted) return;

      if (preview.totalRows == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No rows found in selected file.')),
        );
        setState(() => _isImporting = false);
        return;
      }

      var duplicateMode = OccasionDuplicateHandlingOption.skipExisting;
      if (preview.duplicateRows > 0) {
        final selected = await _askDuplicateHandling();
        if (selected == null) {
          setState(() => _isImporting = false);
          return;
        }
        duplicateMode = selected;
      }

      final shouldImport = await _showPreviewSummary(preview);
      if (shouldImport != true) {
        setState(() => _isImporting = false);
        return;
      }

      final result = await _importManager.runImport(
        rows: preview.ready,
        duplicateHandling: duplicateMode,
      );

      if (!mounted) return;
      await _showImportResult(preview, result);
      if (!mounted) return;
      await context.read<OccasionProvider>().refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Unable to import file. Please use sample template.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  Future<OccasionDuplicateHandlingOption?> _askDuplicateHandling() {
    return showDialog<OccasionDuplicateHandlingOption>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplicate Occasion Found'),
        content:
            const Text('Choose one option for all existing occasion rows.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(
                context, OccasionDuplicateHandlingOption.skipExisting),
            child: const Text('Skip Existing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
                context, OccasionDuplicateHandlingOption.updateExisting),
            child: const Text('Update Existing'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showPreviewSummary(OccasionImportPreview preview) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Preview Summary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rows: ${preview.totalRows}'),
            Text('Ready: ${preview.readyRows}'),
            Text('Skipped: ${preview.skippedRows}'),
            if (preview.errorCounts.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Errors:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              ...preview.errorCounts.entries.map(
                (e) => Text('${e.key}: ${e.value}'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: preview.readyRows == 0
                ? null
                : () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  Future<void> _showImportResult(
    OccasionImportPreview preview,
    OccasionImportResult result,
  ) async {
    final mergedErrors = <String, int>{};
    for (final entry in preview.errorCounts.entries) {
      mergedErrors[entry.key] = (mergedErrors[entry.key] ?? 0) + entry.value;
    }
    for (final entry in result.errorCounts.entries) {
      mergedErrors[entry.key] = (mergedErrors[entry.key] ?? 0) + entry.value;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Result'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Imported: ${result.imported}'),
            Text('Updated: ${result.updated}'),
            Text('Skipped: ${preview.skippedRows + result.skipped}'),
            Text(
                'Errors: ${mergedErrors.values.fold<int>(0, (a, b) => a + b)}'),
            if (mergedErrors.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...mergedErrors.entries.map((e) => Text('${e.key}: ${e.value}')),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _onReminderAction(
    String action,
    OccasionFollowUpRecord record,
  ) async {
    final provider = context.read<OccasionProvider>();
    if (action == 'call') {
      await _call(record.customerPhone);
      return;
    }
    if (action == 'whatsapp') {
      await _shareWhatsApp(record);
      return;
    }
    if (action == 'new_order') {
      await _navigateToNewOrder(record);
      return;
    }
    if (action == 'view') {
      await _showReminderDetails(record);
      return;
    }
    if (action == 'edit') {
      await _showEditReminderDialog(record);
      return;
    }
    if (action == 'open_customer') {
      if (!mounted) return;
      Navigator.pushNamed(context, '/customers');
      return;
    }
    if (action == 'open_order') {
      if (!mounted) return;
      Navigator.pushNamed(context, '/orders');
      return;
    }
    if (action == 'done') {
      await provider.markDone(record);
      return;
    }
    if (action == 'snooze') {
      await provider.snoozeTomorrow(record);
      return;
    }
    if (action == 'delete_manual') {
      await provider.deleteManualReminder(record);
    }
  }

  Future<void> _call(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length < 10) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available')),
      );
      return;
    }

    final uri = Uri.parse('tel:$clean');
    if (await launchUrl(uri)) {
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to start call on this device')),
    );
  }

  Future<void> _shareWhatsApp(OccasionFollowUpRecord record) async {
    final message = _buildReminderMessage(record);
    final waUri = WhatsAppPhoneUtils.buildUri(
      record.customerPhone,
      message: message,
    );
    if (waUri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available')),
      );
      return;
    }

    if (await launchUrl(waUri, mode: LaunchMode.externalApplication)) {
      return;
    }

    final fallback = WhatsAppPhoneUtils.buildFallbackUri(
      record.customerPhone,
      message: message,
    );
    if (fallback != null &&
        await launchUrl(fallback, mode: LaunchMode.externalApplication)) {
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to open WhatsApp on this device')),
    );
  }

  String _buildReminderMessage(OccasionFollowUpRecord record) {
    final parts = record.subtitle.split(' • ');
    final occasion = parts.isNotEmpty ? parts[0] : '';
    final customerName = parts.length > 2 ? parts[2] : '';

    final dateStr = _formatDate(record.date);
    final recipientName = record.title;

    return 'Good Morning ${customerName.isNotEmpty ? customerName : ''},\n\n'
        '$dateStr is $recipientName\'s $occasion.\n\n'
        'Would you like us to prepare a beautiful bouquet, cake or gift for the occasion?\n\n'
        'Please let us know and we will be happy to assist.\n\n'
        'Regards\n'
        'Floraprise';
  }

  Future<void> _navigateToNewOrder(OccasionFollowUpRecord record) async {
    if (!mounted) return;

    // Extract customer info from the record
    final parts = record.subtitle.split(' • ');
    final occasion = parts.isNotEmpty ? parts[0] : '';
    final customerName = parts.length > 2 ? parts[2] : '';

    // Navigate to walkin_sales_screen with customer preselected
    Navigator.pushNamed(
      context,
      '/walkin-sales',
      arguments: {
        'prefillCustomerId': record.customerId,
        'prefillCustomerName': customerName,
        'prefillCustomerPhone': record.customerPhone,
        'prefillRecipientName': record.title,
        'prefillOccasion': occasion,
      },
    );
  }

  Future<void> _showReminderDetails(OccasionFollowUpRecord record) async {
    if (!mounted) return;

    final parts = record.subtitle.split(' • ');
    final occasion = parts.isNotEmpty ? parts[0] : '';
    final relationship = parts.length > 1 ? parts[1] : '';
    final customerName = parts.length > 2 ? parts[2] : '';

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reminder Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Customer', customerName),
            _buildDetailRow('Customer Phone', record.customerPhone),
            _buildDetailRow('Recipient', record.title),
            _buildDetailRow('Relationship', relationship),
            _buildDetailRow('Occasion', occasion),
            _buildDetailRow('Date', _formatDate(record.date)),
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

  Future<void> _showEditReminderDialog(OccasionFollowUpRecord record) async {
    if (!mounted) return;
    if (record.sourceType != 'occasion') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only occasion reminders can be edited')),
      );
      return;
    }

    // Fetch the full contact record
    final contact = await _occasionRepository.getContactById(record.sourceId);
    if (contact == null || !mounted) return;

    final provider = context.read<OccasionProvider>();
    final customerProvider = context.read<CustomerProvider>();

    // Ensure customers are loaded for autocomplete
    if (customerProvider.customers.isEmpty) {
      await customerProvider.loadCustomers();
      if (!mounted) return;
    }

    final recipientController =
        TextEditingController(text: contact.recipientName);
    final relationshipController =
        TextEditingController(text: contact.relationship);
    final occasionController = TextEditingController(text: contact.occasion);
    final phoneController = TextEditingController(text: contact.recipientPhone);
    final companyController = TextEditingController(text: contact.company);
    final notesController = TextEditingController(text: contact.notes);
    final dateController =
        TextEditingController(text: _formatDate(contact.occasionDate));

    DateTime selectedDate = contact.occasionDate;
    String selectedSource = contact.source;

    final customerController =
        TextEditingController(text: contact.customerName);
    final mobileController = TextEditingController(text: contact.customerPhone);

    if (relationshipController.text.trim().isEmpty) {
      relationshipController.text = provider.relationships.isNotEmpty
          ? provider.relationships.first
          : 'Other';
    }

    Future<void> pickDate(
      BuildContext dialogContext,
      StateSetter setLocalState,
    ) async {
      final picked = await showDatePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        initialDate: selectedDate,
      );
      if (picked == null) return;
      if (!dialogContext.mounted) return;
      setLocalState(() {
        selectedDate = picked;
        dateController.text = _formatDate(picked);
      });
    }

    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) {
          return AlertDialog(
            title: const Text('Edit Occasion Reminder'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Customer Search Field (read-only since customer is already linked)
                  TextField(
                    controller: customerController,
                    decoration: const InputDecoration(
                      labelText: 'Customer',
                      hintText: 'Customer linked to reminder',
                    ),
                    readOnly: true,
                  ),
                  const SizedBox(height: 8),
                  // Customer Phone (read-only)
                  TextField(
                    controller: mobileController,
                    decoration: const InputDecoration(
                      labelText: 'Customer Phone',
                    ),
                    readOnly: true,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: recipientController,
                    decoration: const InputDecoration(labelText: 'Recipient'),
                  ),
                  const SizedBox(height: 8),
                  _relationshipField(
                    provider: provider,
                    controller: relationshipController,
                    setLocalState: setLocalState,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: occasionController.text,
                    items: provider.occasions
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) {
                      occasionController.text = value ?? 'General Reminder';
                    },
                    decoration: const InputDecoration(labelText: 'Occasion'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedSource,
                    items: const [
                      DropdownMenuItem(value: 'Manual', child: Text('Manual')),
                      DropdownMenuItem(
                          value: 'Customer Profile',
                          child: Text('Customer Profile')),
                      DropdownMenuItem(
                          value: 'Excel Import', child: Text('Excel Import')),
                      DropdownMenuItem(
                          value: 'Order History', child: Text('Order History')),
                    ],
                    onChanged: (value) {
                      setLocalState(() {
                        selectedSource = value ?? 'Manual';
                      });
                    },
                    decoration:
                        const InputDecoration(labelText: 'Reminder Source'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: dateController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    onTap: () => pickDate(context, setLocalState),
                  ),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                        labelText: 'Recipient Phone (Optional)'),
                  ),
                  TextField(
                    controller: companyController,
                    decoration: const InputDecoration(labelText: 'Company'),
                  ),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(labelText: 'Notes'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (submit != true) {
      customerController.dispose();
      mobileController.dispose();
      recipientController.dispose();
      relationshipController.dispose();
      occasionController.dispose();
      phoneController.dispose();
      companyController.dispose();
      notesController.dispose();
      dateController.dispose();
      return;
    }

    // Update the contact
    try {
      await _occasionRepository.updateContact(
        id: contact.id,
        customerId: contact.customerId,
        recipientName: recipientController.text.trim(),
        relationship: relationshipController.text.trim(),
        occasion: occasionController.text.trim(),
        occasionDate: selectedDate,
        recipientPhone: phoneController.text.trim(),
        company: companyController.text.trim(),
        notes: notesController.text.trim(),
        reminderEnabled: contact.reminderEnabled,
        source: selectedSource,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder updated.')),
      );
      await provider.refresh();
    } catch (e) {
      if (!mounted) return;
      String errorMessage = 'Failed to update reminder';
      if (e.toString().contains('already exists')) {
        errorMessage =
            'A reminder for this customer, recipient, and occasion already exists.';
      } else {
        errorMessage = 'Failed to update reminder: ${e.toString()}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      customerController.dispose();
      mobileController.dispose();
      recipientController.dispose();
      relationshipController.dispose();
      occasionController.dispose();
      phoneController.dispose();
      companyController.dispose();
      notesController.dispose();
      dateController.dispose();
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value.isEmpty ? '-' : value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  List<String> _relationshipOptions(
    OccasionProvider provider,
    String currentValue,
  ) {
    final options = <String>[];
    final seen = <String>{};

    void addOption(String value) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return;
      final key = trimmed.toLowerCase();
      if (seen.add(key)) {
        options.add(trimmed);
      }
    }

    for (final relationship in provider.relationships) {
      addOption(relationship);
    }
    for (final relationship in _customRelationships.value) {
      addOption(relationship);
    }
    addOption(currentValue);
    if (options.isEmpty) {
      addOption('Other');
    }

    return options;
  }

  Future<String?> _showRelationshipPicker(
    BuildContext pickerContext,
    String currentValue,
  ) async {
    final provider = pickerContext.read<OccasionProvider>();
    final options = _relationshipOptions(provider, currentValue);

    return showDialog<String>(
      context: pickerContext,
      barrierDismissible: false,
      builder: (dialogContext) => _RelationshipPickerDialog(
        options: options,
        onSave: _persistCustomRelationship,
      ),
    );
  }

  Future<String?> _persistCustomRelationship(String relationship) async {
    final trimmed = relationship.trim();
    if (trimmed.isEmpty) return null;

    final provider = context.read<OccasionProvider>();
    final existingOptions = _relationshipOptions(provider, '');
    final existing = existingOptions.where(
      (value) => value.toLowerCase() == trimmed.toLowerCase(),
    );
    if (existing.isNotEmpty) {
      return existing.first;
    }

    final updatedRelationships = [..._customRelationships.value, trimmed];
    await _saveCustomRelationships(updatedRelationships);
    if (mounted) {
      _customRelationships.value = updatedRelationships;
    }

    return trimmed;
  }

  Widget _relationshipField({
    required OccasionProvider provider,
    required TextEditingController controller,
    required StateSetter setLocalState,
    FocusNode? focusNode,
    String? errorText,
    VoidCallback? onSelected,
  }) {
    return Builder(
      builder: (fieldContext) => TextField(
        controller: controller,
        focusNode: focusNode,
        readOnly: true,
        decoration: InputDecoration(
          labelText: 'Relationship',
          errorText: errorText,
          suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
        ),
        onTap: () async {
          final relationship = await _showRelationshipPicker(
            fieldContext,
            controller.text,
          );
          if (relationship == null || !fieldContext.mounted) return;
          setLocalState(() {
            controller.text = relationship;
            onSelected?.call();
          });
        },
      ),
    );
  }

  Future<File> _customRelationshipsFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'floraprise_custom_relationships.json'));
  }

  Future<void> _loadCustomRelationships() async {
    try {
      final file = await _customRelationshipsFile();
      if (!await file.exists()) return;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return;
      final values = decoded
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList();
      if (!mounted) return;
      _customRelationships.value = values;
    } catch (_) {
      // Ignore local preference read errors; default relationships still work.
    }
  }

  Future<void> _saveCustomRelationships(List<String> relationships) async {
    final file = await _customRelationshipsFile();
    await file.writeAsString(jsonEncode(relationships));
  }

  Future<void> _showAddReminderDialog() async {
    final provider = context.read<OccasionProvider>();
    final customerProvider = context.read<CustomerProvider>();

    // Ensure customers are loaded for autocomplete
    if (customerProvider.customers.isEmpty) {
      await customerProvider.loadCustomers();
      if (!mounted) return;
    }

    final customerController = TextEditingController();
    final mobileController = TextEditingController();
    final recipientController = TextEditingController();
    final relationshipController = TextEditingController();
    final occasionController = TextEditingController();
    final phoneController = TextEditingController();
    final companyController = TextEditingController();
    final notesController = TextEditingController();
    final dateController = TextEditingController();
    final mobileFocusNode = FocusNode();
    final recipientFocusNode = FocusNode();
    final relationshipFocusNode = FocusNode();
    final occasionFocusNode = FocusNode();
    final dateFocusNode = FocusNode();

    DateTime selectedDate = DateTime.now();
    relationshipController.text = provider.relationships.isNotEmpty
        ? provider.relationships.first
        : 'Other';
    occasionController.text = provider.occasions.isNotEmpty
        ? provider.occasions.first
        : 'General Reminder';
    dateController.text = _formatDate(selectedDate);

    String selectedSource = 'Manual';

    int? selectedCustomerId;
    bool customerSelected = false;
    FocusNode? customerSearchFocusNode;
    TextEditingController? customerSearchTextController;
    String? customerErrorText;
    String? mobileErrorText;
    String? recipientErrorText;
    String? relationshipErrorText;
    String? occasionErrorText;
    String? dateErrorText;

    void disposeDialogResources() {
      customerController.dispose();
      mobileController.dispose();
      recipientController.dispose();
      relationshipController.dispose();
      occasionController.dispose();
      phoneController.dispose();
      companyController.dispose();
      notesController.dispose();
      dateController.dispose();
      mobileFocusNode.dispose();
      recipientFocusNode.dispose();
      relationshipFocusNode.dispose();
      occasionFocusNode.dispose();
      dateFocusNode.dispose();
    }

    bool validateRequiredFields(StateSetter setLocalState) {
      final customerName = customerController.text.trim();
      final mobile = mobileController.text.trim();
      final recipient = recipientController.text.trim();
      final relationship = relationshipController.text.trim();
      final occasion = occasionController.text.trim();
      final date = dateController.text.trim();

      FocusNode? firstInvalidFocus;

      setLocalState(() {
        customerErrorText =
            customerName.isEmpty ? 'Customer name is required' : null;
        mobileErrorText = mobile.isEmpty ? 'Phone is required' : null;
        recipientErrorText = recipient.isEmpty ? 'Recipient is required' : null;
        relationshipErrorText =
            relationship.isEmpty ? 'Relationship is required' : null;
        occasionErrorText = occasion.isEmpty ? 'Occasion is required' : null;
        dateErrorText = date.isEmpty ? 'Date is required' : null;

        firstInvalidFocus = customerName.isEmpty
            ? customerSearchFocusNode
            : mobile.isEmpty
                ? mobileFocusNode
                : recipient.isEmpty
                    ? recipientFocusNode
                    : relationship.isEmpty
                        ? relationshipFocusNode
                        : occasion.isEmpty
                            ? occasionFocusNode
                            : date.isEmpty
                                ? dateFocusNode
                                : null;
      });

      firstInvalidFocus?.requestFocus();
      return firstInvalidFocus == null;
    }

    Future<void> pickDate(
      BuildContext dialogContext,
      StateSetter setLocalState,
    ) async {
      final picked = await showDatePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        initialDate: selectedDate,
      );
      if (picked == null) {
        return;
      }
      if (!dialogContext.mounted) return;
      setLocalState(() {
        selectedDate = picked;
        dateController.text = _formatDate(picked);
        dateErrorText = null;
      });
    }

    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) {
          return AlertDialog(
            title: const Text('Add Occasion Reminder'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Customer Search Field
                  Autocomplete<Map<String, dynamic>>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<Map<String, dynamic>>.empty();
                      }
                      return customerProvider.customers.where((customer) {
                        final name = customer['name'] as String;
                        final phone = customer['phone'] as String;
                        return name.toLowerCase().contains(
                                textEditingValue.text.toLowerCase()) ||
                            phone.contains(textEditingValue.text);
                      });
                    },
                    displayStringForOption: (option) =>
                        '${option['name']} (${option['phone']})',
                    fieldViewBuilder: (context, textEditingController,
                        focusNode, onFieldSubmitted) {
                      customerSearchFocusNode = focusNode;
                      customerSearchTextController = textEditingController;
                      customerController.text = textEditingController.text;
                      return TextField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'Search Customer',
                          hintText: 'Type name or phone...',
                          errorText: customerErrorText,
                          suffixIcon: customerSelected
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setLocalState(() {
                                      customerSelected = false;
                                      selectedCustomerId = null;
                                      customerController.clear();
                                      mobileController.clear();
                                      customerErrorText = null;
                                      mobileErrorText = null;
                                    });
                                    textEditingController.clear();
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          setLocalState(() {
                            customerController.text = value;
                            customerErrorText =
                                value.trim().isEmpty ? customerErrorText : null;
                            if (value.isEmpty && customerSelected) {
                              customerSelected = false;
                              selectedCustomerId = null;
                              mobileController.clear();
                            }
                          });
                        },
                      );
                    },
                    onSelected: (option) {
                      setLocalState(() {
                        selectedCustomerId = option['id'] as int;
                        customerController.text = option['name'] as String;
                        mobileController.text = option['phone'] as String;
                        customerSelected = true;
                        customerErrorText = null;
                        mobileErrorText = null;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked =
                            await ContactPickerService.pickContact(context);
                        if (picked == null || !context.mounted) return;
                        setLocalState(() {
                          customerSearchTextController?.text = picked.name;
                          customerController.text = picked.name;
                          mobileController.text = picked.mobile;
                          customerSelected = false;
                          selectedCustomerId = null;
                          customerErrorText = null;
                          mobileErrorText = null;
                        });
                      },
                      icon: const Icon(Icons.contacts_outlined, size: 18),
                      label: const Text('Select Customer From Contacts'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Customer Phone (read-only when customer selected)
                  TextField(
                    controller: mobileController,
                    focusNode: mobileFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Customer Phone',
                      hintText:
                          customerSelected ? 'Auto-filled' : 'Enter phone',
                      errorText: mobileErrorText,
                    ),
                    readOnly: customerSelected,
                    onChanged: (value) {
                      if (value.trim().isNotEmpty && mobileErrorText != null) {
                        setLocalState(() {
                          mobileErrorText = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: recipientController,
                    focusNode: recipientFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Recipient',
                      errorText: recipientErrorText,
                    ),
                    onChanged: (value) {
                      if (value.trim().isNotEmpty &&
                          recipientErrorText != null) {
                        setLocalState(() {
                          recipientErrorText = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  _relationshipField(
                    provider: provider,
                    controller: relationshipController,
                    setLocalState: setLocalState,
                    focusNode: relationshipFocusNode,
                    errorText: relationshipErrorText,
                    onSelected: () {
                      relationshipErrorText = null;
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    focusNode: occasionFocusNode,
                    initialValue: occasionController.text,
                    items: provider.occasions
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) {
                      setLocalState(() {
                        occasionController.text = value ?? 'General Reminder';
                        occasionErrorText = null;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Occasion',
                      errorText: occasionErrorText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedSource,
                    items: const [
                      DropdownMenuItem(value: 'Manual', child: Text('Manual')),
                      DropdownMenuItem(
                          value: 'Customer Profile',
                          child: Text('Customer Profile')),
                      DropdownMenuItem(
                          value: 'Excel Import', child: Text('Excel Import')),
                      DropdownMenuItem(
                          value: 'Order History', child: Text('Order History')),
                    ],
                    onChanged: (value) {
                      setLocalState(() {
                        selectedSource = value ?? 'Manual';
                      });
                    },
                    decoration:
                        const InputDecoration(labelText: 'Reminder Source'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: dateController,
                    focusNode: dateFocusNode,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Date',
                      errorText: dateErrorText,
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    onTap: () => pickDate(context, setLocalState),
                  ),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                        labelText: 'Recipient Phone (Optional)'),
                  ),
                  TextField(
                    controller: companyController,
                    decoration: const InputDecoration(labelText: 'Company'),
                  ),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(labelText: 'Notes'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (validateRequiredFields(setLocalState)) {
                    Navigator.pop(context, true);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (submit != true) {
      return;
    }

    final customerName = customerController.text.trim();
    final mobile = mobileController.text.trim();

    if (customerName.isEmpty || mobile.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Customer name and mobile are required.')),
        );
      }
      disposeDialogResources();
      return;
    }

    // Use selectedCustomerId if customer was selected from autocomplete
    // Otherwise, find or create customer
    int customerId;
    if (customerSelected && selectedCustomerId != null) {
      customerId = selectedCustomerId!;
    } else {
      var foundCustomerId = await provider.findCustomerIdByNameOrPhone(
        customerName: customerName,
        mobile: mobile,
      );

      customerId = foundCustomerId ??
          await provider.createCustomer(
            name: customerName,
            phone: mobile,
          );
    }

    await provider.addContact(
      customerId: customerId,
      recipientName: recipientController.text.trim(),
      relationship: relationshipController.text.trim(),
      occasion: occasionController.text.trim(),
      occasionDate: selectedDate,
      recipientPhone: phoneController.text.trim(),
      company: companyController.text.trim(),
      notes: notesController.text.trim(),
      source: selectedSource,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder added.')),
      );
    }

    disposeDialogResources();
  }
}

class _RelationshipPickerDialog extends StatefulWidget {
  const _RelationshipPickerDialog({
    required this.options,
    required this.onSave,
  });

  final List<String> options;
  final Future<String?> Function(String relationship) onSave;

  @override
  State<_RelationshipPickerDialog> createState() =>
      _RelationshipPickerDialogState();
}

class _RelationshipPickerDialogState extends State<_RelationshipPickerDialog> {
  final TextEditingController _controller = TextEditingController();

  bool _isAdding = false;
  bool _isSaving = false;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) return;

    _isSaving = true;
    _errorText = null;

    try {
      final savedRelationship = await widget.onSave(trimmed);
      if (!mounted) return;
      Navigator.pop(context, savedRelationship);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorText = 'Could not save relationship. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(_isAdding ? 'Add Relationship' : 'Relationship'),
        content: _isAdding ? _buildAddField() : _buildRelationshipList(),
        actions: _isAdding ? _buildAddActions() : _buildListActions(),
      ),
    );
  }

  Widget _buildAddField() {
    return TextField(
      controller: _controller,
      autofocus: true,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: 'Relationship Name',
        errorText: _errorText,
      ),
      onSubmitted: (_) => _save(),
    );
  }

  Widget _buildRelationshipList() {
    return SizedBox(
      width: double.maxFinite,
      child: ListView(
        shrinkWrap: true,
        children: [
          ...widget.options.map(
            (relationship) => ListTile(
              title: Text(relationship),
              onTap: () => Navigator.pop(context, relationship),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.add_rounded),
            title: const Text('Add Relationship'),
            onTap: () {
              setState(() {
                _isAdding = true;
                _errorText = null;
              });
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAddActions() {
    return [
      TextButton(
        onPressed: () {
          if (_isSaving) return;
          setState(() {
            _isAdding = false;
            _errorText = null;
            _controller.clear();
          });
        },
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _save,
        child: const Text('Save'),
      ),
    ];
  }

  List<Widget> _buildListActions() {
    return [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
    ];
  }
}
