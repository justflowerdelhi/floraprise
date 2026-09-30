import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/crm_models.dart';
import '../../providers/crm_provider.dart';

class CrmEnquiryCreateDialog extends StatefulWidget {
  const CrmEnquiryCreateDialog({super.key, this.initialCustomerPhone, this.initialCustomerName});

  final String? initialCustomerPhone;
  final String? initialCustomerName;

  static Future<CrmEnquiryItem?> show(
    BuildContext context, {
    String? initialCustomerPhone,
    String? initialCustomerName,
  }) {
    return showDialog<CrmEnquiryItem>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CrmEnquiryCreateDialog(
        initialCustomerPhone: initialCustomerPhone,
        initialCustomerName: initialCustomerName,
      ),
    );
  }

  @override
  State<CrmEnquiryCreateDialog> createState() => _CrmEnquiryCreateDialogState();
}

class _CrmEnquiryCreateDialogState extends State<CrmEnquiryCreateDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _phoneController;
  late final TextEditingController _nameController;
  late final TextEditingController _requirementController;
  late final TextEditingController _budgetController;
  late final TextEditingController _locationController;
  late final TextEditingController _notesController;
  late final TextEditingController _nextActionController;

  String _selectedCategory = 'Flowers';
  DateTime? _selectedEventDate;
  DateTime? _selectedFollowUpDate;

  bool _isSaving = false;
  bool _isLookingUpCustomer = false;
  String? _existingCustomerFoundMessage;
  Timer? _phoneDebounce;

  static const List<String> _categories = [
    'Flowers',
    'Wedding',
    'Birthday',
    'Anniversary',
    'Corporate',
    'Sympathy',
    'Custom Decor',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialCustomerPhone ?? '');
    _nameController = TextEditingController(text: widget.initialCustomerName ?? '');
    _requirementController = TextEditingController();
    _budgetController = TextEditingController();
    _locationController = TextEditingController();
    _notesController = TextEditingController();
    _nextActionController = TextEditingController(text: 'Follow-up with customer');

    _phoneController.addListener(_onPhoneChanged);

    if (widget.initialCustomerPhone != null && widget.initialCustomerPhone!.trim().isNotEmpty) {
      _lookupCustomer(widget.initialCustomerPhone!);
    }
  }

  @override
  void dispose() {
    _phoneDebounce?.cancel();
    _phoneController.dispose();
    _nameController.dispose();
    _requirementController.dispose();
    _budgetController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _nextActionController.dispose();
    super.dispose();
  }

  void _onPhoneChanged() {
    _phoneDebounce?.cancel();
    _phoneDebounce = Timer(const Duration(milliseconds: 400), () {
      final phone = _phoneController.text.trim();
      if (phone.length >= 10) {
        _lookupCustomer(phone);
      } else {
        if (_existingCustomerFoundMessage != null) {
          setState(() {
            _existingCustomerFoundMessage = null;
          });
        }
      }
    });
  }

  Future<void> _lookupCustomer(String phone) async {
    if (!mounted) return;
    setState(() {
      _isLookingUpCustomer = true;
    });

    try {
      final provider = context.read<CrmProvider>();
      final cust = await provider.findCustomerByPhone(phone);
      if (!mounted) return;

      if (cust != null) {
        setState(() {
          if (_nameController.text.trim().isEmpty || _nameController.text == 'Customer') {
            _nameController.text = cust['name'] ?? '';
          }
          _existingCustomerFoundMessage = 'Existing customer: ${cust['name']}';
          _isLookingUpCustomer = false;
        });
      } else {
        setState(() {
          _existingCustomerFoundMessage = null;
          _isLookingUpCustomer = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLookingUpCustomer = false;
        });
      }
    }
  }

  Future<void> _selectEventDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedEventDate ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() {
        _selectedEventDate = picked;
      });
    }
  }

  Future<void> _selectFollowUpDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedFollowUpDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedFollowUpDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final provider = context.read<CrmProvider>();
      int? budgetPaise;
      final rawBudget = _budgetController.text.trim();
      if (rawBudget.isNotEmpty) {
        final amountRupees = double.tryParse(rawBudget);
        if (amountRupees != null && amountRupees > 0) {
          budgetPaise = (amountRupees * 100).round();
        }
      }

      final created = await provider.createEnquiry(
        customerPhone: _phoneController.text.trim(),
        customerName: _nameController.text.trim(),
        requirement: _requirementController.text.trim(),
        category: _selectedCategory,
        eventDate: _selectedEventDate,
        budgetPaise: budgetPaise,
        location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        nextAction: _nextActionController.text.trim().isNotEmpty ? _nextActionController.text.trim() : null,
        nextFollowUpAt: _selectedFollowUpDate,
      );

      if (!mounted) return;
      Navigator.of(context).pop(created);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save enquiry: $e'), backgroundColor: Colors.red.shade700),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dialog Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(Icons.add_task_rounded, color: colorScheme.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'New Enquiry',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Capture requirement & link to customer master',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Customer Phone & Lookup
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Customer Phone *',
                          hintText: 'e.g. 9876543210',
                          prefixIcon: const Icon(Icons.phone_rounded, size: 20),
                          suffixIcon: _isLookingUpCustomer
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : null,
                          helperText: _existingCustomerFoundMessage,
                          helperStyle: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Customer phone is required';
                          }
                          final digits = val.replaceAll(RegExp(r'[^0-9]'), '');
                          if (digits.length < 10) {
                            return 'Enter a valid 10-digit phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Customer Name
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Customer Name *',
                          hintText: 'e.g. Priya Sharma',
                          prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Customer name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Category Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Enquiry Category',
                          prefixIcon: Icon(Icons.category_outlined, size: 20),
                          border: OutlineInputBorder(),
                        ),
                        items: _categories
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedCategory = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 14),

                      // Requirement description
                      TextFormField(
                        controller: _requirementController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Requirement / Items Description *',
                          hintText: 'e.g. 50 Fresh Red Roses Bouquet for Wedding Anniversary',
                          alignLabelWithHint: true,
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(bottom: 40),
                            child: Icon(Icons.description_outlined, size: 20),
                          ),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Requirement description is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Date & Budget Row
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _selectEventDate,
                              borderRadius: BorderRadius.circular(4),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Event Date',
                                  prefixIcon: Icon(Icons.event_rounded, size: 20),
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  _selectedEventDate != null
                                      ? DateFormat('dd MMM yyyy').format(_selectedEventDate!)
                                      : 'Not set',
                                  style: TextStyle(
                                    color: _selectedEventDate != null ? null : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _budgetController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Budget (₹)',
                                hintText: 'e.g. 3500',
                                prefixIcon: Icon(Icons.currency_rupee_rounded, size: 20),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Location
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Venue / Delivery Location',
                          hintText: 'e.g. Hyatt Regency, MG Road',
                          prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Follow-up Date & Next Action
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _selectFollowUpDate,
                              borderRadius: BorderRadius.circular(4),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Next Follow-up',
                                  prefixIcon: Icon(Icons.alarm_rounded, size: 20),
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  _selectedFollowUpDate != null
                                      ? DateFormat('dd MMM yyyy').format(_selectedFollowUpDate!)
                                      : 'Not set',
                                  style: TextStyle(
                                    color: _selectedFollowUpDate != null ? null : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _nextActionController,
                              decoration: const InputDecoration(
                                labelText: 'Next Action',
                                hintText: 'e.g. Call on Friday',
                                prefixIcon: Icon(Icons.arrow_forward_rounded, size: 20),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Notes
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Internal Notes',
                          hintText: 'e.g. Prefers pastel shades, budget negotiable',
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(bottom: 24),
                            child: Icon(Icons.note_alt_outlined, size: 20),
                          ),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),

            // Actions Footer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _submit,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(_isSaving ? 'Saving...' : 'Create Enquiry'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
