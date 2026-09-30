import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/crm_models.dart';
import '../../providers/crm_provider.dart';
import '../../utils/whatsapp_phone_utils.dart';
import '../../widgets/app_header.dart';
import '../../widgets/floraprise_page_header.dart';
import '../walkin_sales_screen.dart';
import 'crm_enquiry_create_dialog.dart';

class CrmTodayScreen extends StatefulWidget {
  const CrmTodayScreen({super.key});

  @override
  State<CrmTodayScreen> createState() => _CrmTodayScreenState();
}

class _CrmTodayScreenState extends State<CrmTodayScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CrmProvider>().loadTodayData();
    });
  }

  Future<void> _makePhoneCall(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available for this contact.')),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final crmProvider = context.watch<CrmProvider>();
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;

    return Scaffold(
      appBar: const AppHeader(
        title: 'CRM Today',
        showBackButton: false,
      ),
      body: RefreshIndicator(
        onRefresh: () => crmProvider.refresh(),
        child: crmProvider.isLoading && crmProvider.data.evaluatedAt == DateTime.fromMillisecondsSinceEpoch(0)
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  if (isDesktop) ...[
                    const FloraprisePageHeader(
                      title: 'CRM Today',
                      subtitle: "Manage today's follow-ups, enquiries, and occasions.",
                      icon: Icons.dashboard_customize_rounded,
                    ),
                    const SizedBox(height: 16),
                  ],
                  // KPI Summary Bar
                  _buildKpiSummaryBar(crmProvider.data, colorScheme),
                  const SizedBox(height: 16),

                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildFollowUpsSection(context, crmProvider),
                              const SizedBox(height: 16),
                              _buildQuotesPendingSection(context, crmProvider),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildNewEnquiriesSection(context, crmProvider),
                              const SizedBox(height: 16),
                              _buildOccasionsThisWeekSection(context, crmProvider),
                            ],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    // 1. TODAY'S FOLLOW-UPS
                    _buildFollowUpsSection(context, crmProvider),
                    const SizedBox(height: 16),

                    // 2. NEW ENQUIRIES
                    _buildNewEnquiriesSection(context, crmProvider),
                    const SizedBox(height: 16),

                    // 3. QUOTES PENDING
                    _buildQuotesPendingSection(context, crmProvider),
                    const SizedBox(height: 16),

                    // 4. OCCASIONS THIS WEEK
                    _buildOccasionsThisWeekSection(context, crmProvider),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildKpiSummaryBar(CrmTodayData data, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildKpiBadge('Follow-ups', '${data.pendingFollowUpsCount}', const Color(0xFFD97706)),
          _buildKpiBadge('Enquiries', '${data.enquiries.length}', const Color(0xFF2563EB)),
          _buildKpiBadge('Quotes', '${data.pendingQuotes.length}', const Color(0xFF7C3AED)),
          _buildKpiBadge('Occasions', '${data.upcomingOccasions.length}', const Color(0xFF059669)),
        ],
      ),
    );
  }

  Widget _buildKpiBadge(String label, String count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // 1. TODAY'S FOLLOW-UPS
  // --------------------------------------------------------------------------
  Widget _buildFollowUpsSection(BuildContext context, CrmProvider provider) {
    final followUps = provider.followUps;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.phone_callback_rounded, size: 20, color: Color(0xFFD97706)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "TODAY'S FOLLOW-UPS",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                if (followUps.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${followUps.where((f) => !f.isCompleted).length} pending',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (followUps.isEmpty)
              _buildEmptyState('No follow-ups scheduled for today.', Icons.check_circle_outline_rounded)
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: followUps.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final item = followUps[index];
                  return _buildFollowUpCard(context, item, provider);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowUpCard(
    BuildContext context,
    CrmFollowUpItem item,
    CrmProvider provider,
  ) {
    final isDone = item.isCompleted;
    final timeStr = DateFormat('hh:mm a').format(item.scheduledTime);

    return Opacity(
      opacity: isDone ? 0.5 : 1.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.customerName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E2922),
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (item.amount != null && item.amount! > 0)
                Text(
                  '₹${item.amount!.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF059669),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.requirementSummary,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: isDone ? null : () => _makePhoneCall(item.customerPhone),
                icon: const Icon(Icons.call_rounded, size: 14),
                label: const Text('Call'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
              OutlinedButton.icon(
                onPressed: isDone
                    ? null
                    : () => _openWhatsApp(
                          item.customerPhone,
                          message: 'Hello ${item.customerName}, following up regarding: ${item.requirementSummary}',
                        ),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Color(0xFF25D366)),
                label: const Text('WhatsApp'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
              FilledButton.tonal(
                onPressed: isDone ? null : () => provider.markFollowUpDone(item),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  backgroundColor: isDone ? Colors.grey.shade300 : const Color(0xFFD1FAE5),
                  foregroundColor: isDone ? Colors.grey.shade600 : const Color(0xFF047857),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                child: Text(isDone ? 'Done ✓' : 'Done'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 2. NEW ENQUIRIES
  // --------------------------------------------------------------------------
  Widget _buildNewEnquiriesSection(BuildContext context, CrmProvider provider) {
    final enquiries = provider.enquiries;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.mark_email_unread_rounded, size: 20, color: Color(0xFF2563EB)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'NEW ENQUIRIES',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Add Enquiry',
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 20, color: Color(0xFF2563EB)),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => CrmEnquiryCreateDialog.show(context),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/crm/enquiries'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (enquiries.isEmpty)
              _buildEmptyState('No new enquiries today.', Icons.inbox_rounded)
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: enquiries.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final enq = enquiries[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              enq.customerName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E2922),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBEAFE),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              enq.status,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        enq.requirement,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                      ),
                      if (enq.eventDate != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Event Date: ${DateFormat('dd MMM yyyy').format(enq.eventDate!)}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (enq.customerPhone.isNotEmpty) ...[
                            OutlinedButton.icon(
                              onPressed: () => _makePhoneCall(enq.customerPhone),
                              icon: const Icon(Icons.call_rounded, size: 14),
                              label: const Text('Call'),
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                textStyle: const TextStyle(fontSize: 11),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () => _openWhatsApp(enq.customerPhone),
                              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Color(0xFF25D366)),
                              label: const Text('WhatsApp'),
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                textStyle: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 3. QUOTES PENDING
  // --------------------------------------------------------------------------
  Widget _buildQuotesPendingSection(BuildContext context, CrmProvider provider) {
    final quotes = provider.pendingQuotes;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.request_quote_rounded, size: 20, color: Color(0xFF7C3AED)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'QUOTES PENDING',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                if (quotes.isNotEmpty)
                  Text(
                    '${quotes.length} pending',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (quotes.isEmpty)
              _buildEmptyState('No pending quotes.', Icons.receipt_long_outlined)
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: quotes.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final quote = quotes[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      if (quote.orderId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WalkinSalesScreen(
                              prefillCustomerName: quote.customerName,
                              prefillCustomerPhone: quote.customerPhone,
                            ),
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  quote.customerName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E2922),
                                  ),
                                ),
                              ),
                              Text(
                                '₹${quote.amount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF7C3AED),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            quote.requirementSummary,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                DateFormat('dd MMM, hh:mm a').format(quote.date),
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                              ),
                              Text(
                                '${quote.nextAction} →',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF7C3AED),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 4. OCCASIONS THIS WEEK
  // --------------------------------------------------------------------------
  Widget _buildOccasionsThisWeekSection(BuildContext context, CrmProvider provider) {
    final occasions = provider.upcomingOccasions;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.cake_rounded, size: 20, color: Color(0xFF059669)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'OCCASIONS THIS WEEK',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (occasions.isEmpty)
              _buildEmptyState('No upcoming occasions this week.', Icons.celebration_outlined)
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: occasions.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final occ = occasions[index];
                  final icon = _getOccasionIcon(occ.occasion);

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: occ.dayLabel == 'Today'
                              ? const Color(0xFFFEE2E2)
                              : occ.dayLabel == 'Tomorrow'
                                  ? const Color(0xFFFEF3C7)
                                  : const Color(0xFFE0E7FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          occ.dayLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: occ.dayLabel == 'Today'
                                ? const Color(0xFFB91C1C)
                                : occ.dayLabel == 'Tomorrow'
                                    ? const Color(0xFFB45309)
                                    : const Color(0xFF3730A3),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$icon ${occ.recipientName.isNotEmpty ? occ.recipientName : occ.customerName} — ${occ.occasion}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            if (occ.relationship.isNotEmpty && occ.customerName.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${occ.relationship} of ${occ.customerName}',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (occ.customerPhone.isNotEmpty) ...[
                        IconButton(
                          icon: const Icon(Icons.call_rounded, size: 18, color: Color(0xFF2563EB)),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          onPressed: () => _makePhoneCall(occ.customerPhone),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF25D366)),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          onPressed: () => _openWhatsApp(
                            occ.customerPhone,
                            message: 'Wishing a very Happy ${occ.occasion} to ${occ.recipientName}! 🌸 — Floraprise',
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _getOccasionIcon(String occasion) {
    final lower = occasion.toLowerCase();
    if (lower.contains('birthday')) return '🎂';
    if (lower.contains('anniversary')) return '💍';
    if (lower.contains('valentine')) return '🌹';
    if (lower.contains('festival') || lower.contains('diwali')) return '🎉';
    if (lower.contains('corporate')) return '🏢';
    return '🔔';
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }
}
