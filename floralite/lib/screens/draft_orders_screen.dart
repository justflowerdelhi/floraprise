import 'package:flutter/material.dart';

import '../data/repositories/order_repository.dart';
import '../models/walk_in_enums.dart';
import '../models/walk_in_session.dart';
import '../utils/locale_formatter.dart';
import 'delivery_screen.dart';
import 'pickup_later_screen.dart';
import 'take_away_screen.dart';

class DraftOrdersScreen extends StatefulWidget {
  const DraftOrdersScreen({super.key});

  @override
  State<DraftOrdersScreen> createState() => _DraftOrdersScreenState();
}

class _DraftOrdersScreenState extends State<DraftOrdersScreen> {
  final OrderRepository _orderRepository = OrderRepository();
  final TextEditingController _searchController = TextEditingController();
  late Future<List<DraftOrderSummary>> _draftsFuture;
  int? _openingDraftId;

  @override
  void initState() {
    super.initState();
    _draftsFuture = _loadDrafts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<DraftOrderSummary>> _loadDrafts() {
    return _orderRepository.listDraftOrders(query: _searchController.text);
  }

  void _refreshDrafts() {
    setState(() => _draftsFuture = _loadDrafts());
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      appBar: AppBar(title: const Text('Draft Orders')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startNewSale,
        icon: const Icon(Icons.add),
        label: const Text('New Sale'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search customer, mobile, or draft ID',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _refreshDrafts();
                          },
                          icon: const Icon(Icons.clear),
                        ),
                ),
                onChanged: (_) => _refreshDrafts(),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<DraftOrderSummary>>(
                future: _draftsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Unable to load draft orders.'),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _refreshDrafts,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final drafts = snapshot.data ?? const <DraftOrderSummary>[];
                  if (drafts.isEmpty) {
                    return _EmptyDrafts(onStartNewSale: _startNewSale);
                  }

                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 96 + bottomInset),
                    itemCount: drafts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _DraftOrderCard(
                      draft: drafts[index],
                      isOpening: _openingDraftId == drafts[index].id,
                      onContinue: () => _continueDraft(drafts[index]),
                      onDelete: () => _deleteDraft(drafts[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startNewSale() {
    Navigator.of(context, rootNavigator: true)
        .push(
          MaterialPageRoute(builder: (_) => const TakeAwayScreen()),
        )
        .then((_) => _refreshDrafts());
  }

  Future<void> _continueDraft(DraftOrderSummary draft) async {
    if (_openingDraftId != null) return;
    setState(() => _openingDraftId = draft.id);

    try {
      final session = await _orderRepository.getDraftById(draft.id);
      if (!mounted) return;
      if (session == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft order not found.')),
        );
        _refreshDrafts();
        return;
      }

      await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => _screenForSession(session)),
      );
      if (mounted) _refreshDrafts();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open draft: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _openingDraftId = null);
      }
    }
  }

  Widget _screenForSession(WalkInSession session) {
    return switch (session.fulfilmentType) {
      FulfilmentType.pickupLater => PickupLaterScreen(initialSession: session),
      FulfilmentType.delivery => DeliveryScreen(initialSession: session),
      FulfilmentType.takeAway => TakeAwayScreen(initialSession: session),
    };
  }

  Future<void> _deleteDraft(DraftOrderSummary draft) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Draft?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _orderRepository.deleteDraft(draft.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draft deleted.')),
    );
    _refreshDrafts();
  }
}

class _EmptyDrafts extends StatelessWidget {
  const _EmptyDrafts({required this.onStartNewSale});

  final VoidCallback onStartNewSale;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.note_alt_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No Draft Orders',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Draft orders will appear here.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onStartNewSale,
              icon: const Icon(Icons.add),
              label: const Text('Start New Sale'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftOrderCard extends StatelessWidget {
  const _DraftOrderCard({
    required this.draft,
    required this.isOpening,
    required this.onContinue,
    required this.onDelete,
  });

  final DraftOrderSummary draft;
  final bool isOpening;
  final VoidCallback onContinue;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note_alt_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    draft.orderNo,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(draft.customerName),
            if (draft.customerPhone.isNotEmpty)
              Text(
                draft.customerPhone,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                Text('${draft.itemCount} Items'),
                Text(LocaleFormatter.formatCurrency(
                    context, draft.grandTotalPaise)),
                Text(_fulfilmentLabel(draft.fulfilmentType)),
                Text(_relativeDate(context, draft.updatedAt)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: isOpening ? null : onContinue,
                    child: isOpening
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Continue'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: isOpening ? null : onDelete,
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fulfilmentLabel(FulfilmentType type) {
    return switch (type) {
      FulfilmentType.takeAway => 'Take Away',
      FulfilmentType.pickupLater => 'Pickup Later',
      FulfilmentType.delivery => 'Delivery',
    };
  }

  String _relativeDate(BuildContext context, DateTime value) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(value.year, value.month, value.day);
    final time = TimeOfDay.fromDateTime(value).format(context);
    if (date == today) return 'Today • $time';
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return LocaleFormatter.formatDate(context, value);
  }
}
