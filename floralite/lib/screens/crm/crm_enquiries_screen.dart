import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/crm_models.dart';
import '../../providers/crm_provider.dart';
import '../../utils/whatsapp_phone_utils.dart';
import '../../widgets/app_header.dart';
import '../../widgets/floraprise_page_header.dart';
import '../order_view_screen.dart';
import 'crm_enquiry_create_dialog.dart';
import 'crm_mark_lost_dialog.dart';
import 'crm_quote_compose_dialog.dart';
import 'crm_quote_preview_dialog.dart';
import 'crm_reopen_dialog.dart';

class CrmEnquiriesScreen extends StatefulWidget {
  const CrmEnquiriesScreen({super.key});

  @override
  State<CrmEnquiriesScreen> createState() => _CrmEnquiriesScreenState();
}

class _CrmEnquiriesScreenState extends State<CrmEnquiriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'all';

  static const List<Map<String, String>> _statusFilters = [
    {'id': 'all', 'label': 'All'},
    {'id': 'new', 'label': 'New'},
    {'id': 'follow_up', 'label': 'Follow-up'},
    {'id': 'quote_sent', 'label': 'Quote Sent'},
    {'id': 'won', 'label': 'Won'},
    {'id': 'lost', 'label': 'Lost'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CrmProvider>().loadEnquiries(status: _selectedStatus);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onStatusSelected(String status) {
    setState(() {
      _selectedStatus = status;
    });
    context.read<CrmProvider>().loadEnquiries(
          status: status,
          query: _searchController.text.trim(),
        );
  }

  void _onSearch(String query) {
    context.read<CrmProvider>().loadEnquiries(
          status: _selectedStatus,
          query: query.trim(),
        );
  }

  Future<void> _makePhoneCall(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available.')),
      );
      return;
    }
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$digits');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not initiate call to $phone')),
      );
    }
  }

  Future<void> _openWhatsApp(String? phone, {String? message}) async {
    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available for WhatsApp.')),
      );
      return;
    }
    final uri = WhatsAppPhoneUtils.buildUri(phone, message: message) ??
        WhatsAppPhoneUtils.buildFallbackUri(phone, message: message);

    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open WhatsApp for $phone')),
      );
    }
  }

  Future<void> _openCreateDialog() async {
    final result = await CrmEnquiryCreateDialog.show(context);
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enquiry created for ${result.customerName}'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }
  }

  Future<void> _openQuoteDialog(CrmEnquiryItem item) async {
    final draftId = await CrmQuoteComposeDialog.show(context, enquiry: item);
    if (draftId != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quotation draft #$draftId saved for ${item.customerName}'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }
  }

  Future<void> _openQuotePreviewDialog(CrmEnquiryItem item) async {
    await CrmQuotePreviewDialog.show(context, enquiry: item);
  }

  Future<void> _openMarkLostDialog(CrmEnquiryItem item) async {
    final result = await CrmMarkLostDialog.show(context, enquiry: item);
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enquiry marked as Lost'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<void> _openReopenDialog(CrmEnquiryItem item) async {
    final result = await CrmReopenDialog.show(context, enquiry: item);
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enquiry reopened as Follow-up'),
          backgroundColor: Color(0xFFD97706),
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return const Color(0xFF2563EB); // Blue
      case 'follow_up':
        return const Color(0xFFD97706); // Amber
      case 'quote_sent':
        return const Color(0xFF7C3AED); // Purple
      case 'won':
        return const Color(0xFF059669); // Emerald
      case 'lost':
        return const Color(0xFFDC2626); // Red
      default:
        return Colors.blueGrey;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return const Color(0xFFDBEAFE);
      case 'follow_up':
        return const Color(0xFFFEF3C7);
      case 'quote_sent':
        return const Color(0xFFEDE9FE);
      case 'won':
        return const Color(0xFFD1FAE5);
      case 'lost':
        return const Color(0xFFFEE2E2);
      default:
        return Colors.blueGrey.shade50;
    }
  }

  String _formatStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return 'New';
      case 'follow_up':
        return 'Follow-up';
      case 'quote_sent':
        return 'Quote Sent';
      case 'won':
        return 'Won';
      case 'lost':
        return 'Lost';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final crmProvider = context.watch<CrmProvider>();
    final enquiries = crmProvider.enquiriesList;
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;

    return Scaffold(
      appBar: const AppHeader(
        title: 'Enquiries',
        showBackButton: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Enquiry'),
      ),
      body: RefreshIndicator(
        onRefresh: () => crmProvider.loadEnquiries(
          status: _selectedStatus,
          query: _searchController.text.trim(),
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            if (isDesktop) ...[
              FloraprisePageHeader(
                title: 'Enquiry Management',
                subtitle: 'Track customer requests, event orders, and follow-up pipeline.',
                icon: Icons.question_answer_outlined,
                actions: [
                  FilledButton.icon(
                    onPressed: _openCreateDialog,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('New Enquiry'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search by customer, phone, requirement, venue...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),

            // Status Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statusFilters.map((filter) {
                  final isSelected = _selectedStatus == filter['id'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(filter['label']!),
                      onSelected: (_) => _onStatusSelected(filter['id']!),
                      selectedColor: colorScheme.primaryContainer,
                      checkmarkColor: colorScheme.onPrimaryContainer,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? colorScheme.onPrimaryContainer : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Enquiries List / Loading / Empty
            if (crmProvider.isEnquiriesLoading && enquiries.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (enquiries.isEmpty)
              _buildEmptyState()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: enquiries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = enquiries[index];
                  return _buildEnquiryCard(context, item, crmProvider);
                },
              ),
            const SizedBox(height: 80), // Padding for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'No Enquiries Found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              _selectedStatus != 'all' || _searchController.text.isNotEmpty
                  ? 'Try clearing search filters or create a new enquiry.'
                  : 'Start capturing customer enquiries and wedding requests.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _openCreateDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create New Enquiry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnquiryCard(BuildContext context, CrmEnquiryItem item, CrmProvider provider) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(item.status);
    final statusBgColor = _getStatusBgColor(item.status);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Row: Customer info & Status Chip
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    item.customerName.isNotEmpty ? item.customerName[0].toUpperCase() : 'C',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.customerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E2922),
                        ),
                      ),
                      if (item.customerPhone.isNotEmpty)
                        Text(
                          item.customerPhone,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade800,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _formatStatusLabel(item.status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Category & Requirement
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.category,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      if (item.budgetPaise != null && item.budgetPaise! > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Budget: ₹${(item.budgetPaise! / 100).toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.requirement,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade900, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Metadata: Event Date, Location, Next Action
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                if (item.eventDate != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_rounded, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Event: ${DateFormat('dd MMM yyyy').format(item.eventDate!)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                if (item.location != null && item.location!.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        item.location!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                if (item.status == 'lost')
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cancel_outlined, size: 14, color: Colors.red.shade700),
                      const SizedBox(width: 4),
                      Text(
                        item.lostReason != null && item.lostReason!.isNotEmpty
                            ? 'Lost: ${item.lostReason}'
                            : 'Lost',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                else if (item.nextAction.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.blue.shade700),
                      const SizedBox(width: 4),
                      Text(
                        item.nextAction,
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade800, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                if (item.convertedOrderId != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_rounded, size: 14, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Order #ORD-${item.convertedOrderId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                else if (item.quoteOrderId != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.description_outlined, size: 14, color: Colors.purple.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Draft #${item.quoteOrderId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (item.notes != null && item.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Notes: ${item.notes}',
                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Action Buttons
            Row(
              children: [
                if (item.customerPhone.isNotEmpty) ...[
                  OutlinedButton.icon(
                    onPressed: () => _makePhoneCall(item.customerPhone),
                    icon: const Icon(Icons.call_rounded, size: 14),
                    label: const Text('Call'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _openWhatsApp(
                      item.customerPhone,
                      message: 'Hello ${item.customerName}, regarding your enquiry for ${item.category} (${item.requirement}):',
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Color(0xFF25D366)),
                    label: const Text('WhatsApp'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                // Order / Quote / Lost / Reopen Action Buttons
                if (item.status == 'won' && item.convertedOrderId != null)
                  FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OrderViewScreen(orderId: item.convertedOrderId!),
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_long_outlined, size: 14),
                    label: Text('View Order (#ORD-${item.convertedOrderId})'),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  )
                else if (item.status == 'lost') ...[
                  FilledButton.tonalIcon(
                    onPressed: () => _openReopenDialog(item),
                    icon: const Icon(Icons.replay_rounded, size: 14),
                    label: const Text('Reopen'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFEF3C7),
                      foregroundColor: const Color(0xFF92400E),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (item.quoteOrderId != null) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _openQuotePreviewDialog(item),
                      icon: const Icon(Icons.description_outlined, size: 14),
                      label: Text('Quote (#${item.quoteOrderId})'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ]
                else ...[
                  // Active Enquiry (new, follow_up, quote_sent)
                  if (item.quoteOrderId == null)
                    OutlinedButton.icon(
                      onPressed: () => _openQuoteDialog(item),
                      icon: const Icon(Icons.request_quote_outlined, size: 14),
                      label: const Text('Create Quote'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    )
                  else ...[
                    FilledButton.tonalIcon(
                      onPressed: () => _openQuotePreviewDialog(item),
                      icon: const Icon(Icons.description_outlined, size: 14),
                      label: Text('Quote (#${item.quoteOrderId})'),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () => _openQuoteDialog(item),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      tooltip: 'Edit Quote Draft',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _openMarkLostDialog(item),
                    icon: const Icon(Icons.close_rounded, size: 14, color: Color(0xFFDC2626)),
                    label: const Text('Mark Lost', style: TextStyle(color: Color(0xFFDC2626))),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red.shade300),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
                const Spacer(),
                // Status Changer / Won Protection
                if (item.status == 'won')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF059669)),
                        SizedBox(width: 4),
                        Text(
                          'Won',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  PopupMenuButton<String>(
                    tooltip: 'Change Status',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatStatusLabel(item.status),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          const Icon(Icons.arrow_drop_down_rounded, size: 18),
                        ],
                      ),
                    ),
                    onSelected: (newStatus) async {
                      if (newStatus == item.status) return;
                      if (newStatus == 'lost') {
                        await _openMarkLostDialog(item);
                      } else if (newStatus == 'won') {
                        if (item.quoteOrderId != null) {
                          await _openQuotePreviewDialog(item);
                        } else {
                          await _openQuoteDialog(item);
                        }
                      } else {
                        await provider.updateEnquiry(item.copyWith(status: newStatus));
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'new', child: Text('New')),
                      const PopupMenuItem(value: 'follow_up', child: Text('Follow-up')),
                      const PopupMenuItem(value: 'quote_sent', child: Text('Quote Sent')),
                      const PopupMenuItem(value: 'won', child: Text('Won (Convert Order)')),
                      const PopupMenuItem(value: 'lost', child: Text('Lost')),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
