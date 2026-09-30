import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/crm_models.dart';
import '../../providers/crm_provider.dart';

class CrmMarkLostDialog extends StatefulWidget {
  const CrmMarkLostDialog({
    super.key,
    required this.enquiry,
  });

  final CrmEnquiryItem enquiry;

  static Future<bool?> show(
    BuildContext context, {
    required CrmEnquiryItem enquiry,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CrmMarkLostDialog(enquiry: enquiry),
    );
  }

  @override
  State<CrmMarkLostDialog> createState() => _CrmMarkLostDialogState();
}

class _CrmMarkLostDialogState extends State<CrmMarkLostDialog> {
  static const List<String> lostReasons = [
    'Customer cancelled',
    'Price too high',
    'Went with another florist',
    'Event cancelled',
    'No response',
    'Duplicate enquiry',
    'Other',
  ];

  late String _selectedReason;
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedReason = lostReasons.first;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final messenger = ScaffoldMessenger.of(context);
      final nav = Navigator.of(context);
      final provider = context.read<CrmProvider>();

      await provider.markEnquiryLost(
        enquiry: widget.enquiry,
        reason: _selectedReason,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (!mounted) return;
      if (nav.canPop()) {
        nav.pop(true);
      }

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Enquiry marked as Lost'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark enquiry as lost: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.cancel_outlined,
              color: Color(0xFFDC2626),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Mark Enquiry Lost',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer: ${widget.enquiry.customerName} • ${widget.enquiry.category}',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Lost Reason *',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedReason,
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: lostReasons
                    .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 14))))
                    .toList(),
                onChanged: _isSubmitting
                    ? null
                    : (val) {
                        if (val != null) {
                          setState(() {
                            _selectedReason = val;
                          });
                        }
                      },
              ),
              const SizedBox(height: 14),
              const Text(
                'Optional Note',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _notesController,
                enabled: !_isSubmitting,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add details (e.g. customer budget ₹1,000 max, event cancelled due to rain...)',
                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isSubmitting ? null : _submit,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.close_rounded, size: 16),
          label: Text(_isSubmitting ? 'Saving...' : 'Mark Lost'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
