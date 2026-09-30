import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/repositories/cloud_scheduler_repository.dart';
import '../data/repositories/scheduler_repository.dart';
import '../managers/scheduler_manager.dart';
import '../models/scheduler_task.dart';
import '../providers/storage_mode_provider.dart';

/// Shows the standardized Schedule Payment Follow-up dialog.
Future<bool?> showSchedulePaymentFollowUpDialog({
  required BuildContext context,
  required int orderId,
  String? cloudOrderId,
  required String orderNo,
  int? customerId,
  String? cloudCustomerId,
  required String customerName,
  required int outstandingAmountPaise,
  VoidCallback? onScheduled,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => SchedulePaymentFollowUpDialog(
      orderId: orderId,
      cloudOrderId: cloudOrderId,
      orderNo: orderNo,
      customerId: customerId,
      cloudCustomerId: cloudCustomerId,
      customerName: customerName,
      outstandingAmountPaise: outstandingAmountPaise,
      onScheduled: onScheduled,
    ),
  );
}

class SchedulePaymentFollowUpDialog extends StatefulWidget {
  const SchedulePaymentFollowUpDialog({
    super.key,
    required this.orderId,
    this.cloudOrderId,
    required this.orderNo,
    this.customerId,
    this.cloudCustomerId,
    required this.customerName,
    required this.outstandingAmountPaise,
    this.onScheduled,
  });

  final int orderId;
  final String? cloudOrderId;
  final String orderNo;
  final int? customerId;
  final String? cloudCustomerId;
  final String customerName;
  final int outstandingAmountPaise;
  final VoidCallback? onScheduled;

  @override
  State<SchedulePaymentFollowUpDialog> createState() =>
      _SchedulePaymentFollowUpDialogState();
}

class _SchedulePaymentFollowUpDialogState
    extends State<SchedulePaymentFollowUpDialog> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late final TextEditingController _notesController;
  TaskPriority _priority = TaskPriority.normal;
  bool _requiresAlarm = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Default to tomorrow at 10:00 AM
    _selectedDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    _selectedTime = const TimeOfDay(hour: 10, minute: 0);

    final formattedOutstanding = _formatPaise(widget.outstandingAmountPaise);
    _notesController = TextEditingController(
      text: 'Collect $formattedOutstanding from ${widget.customerName.isEmpty ? 'Customer' : widget.customerName}',
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _formatPaise(int paise) {
    final rs = paise / 100;
    if (rs % 1 == 0) {
      return '₹${rs.toInt()}';
    }
    return '₹${rs.toStringAsFixed(2)}';
  }

  DateTime get _scheduledDateTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submit() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final storageMode = context.read<StorageModeProvider>();
      final isCloud = storageMode.isCloud;
      final isCloudOrder = isCloud &&
          widget.cloudOrderId != null &&
          widget.cloudOrderId!.isNotEmpty;

      final sourceRef = isCloudOrder
          ? 'payment_followup:order_${widget.cloudOrderId}'
          : 'payment_followup:order_${widget.orderId}';

      final taskTitle = 'Collect Pending Payment - ${widget.orderNo}';
      final now = DateTime.now();

      final task = SchedulerTask(
        title: taskTitle,
        type: TaskType.reminder,
        category: TaskCategory.sales,
        priority: _priority,
        status: TaskStatus.pending,
        scheduledAt: _scheduledDateTime,
        deadlineAt: _scheduledDateTime.add(const Duration(hours: 4)),
        notes: _notesController.text.trim(),
        linkedCustomerId: widget.customerId,
        cloudLinkedCustomerId: widget.cloudCustomerId,
        linkedOrderId: widget.orderId,
        cloudLinkedOrderId: widget.cloudOrderId,
        producer: TaskProducer.orders,
        sourceRef: sourceRef,
        requiresAlarm: _requiresAlarm,
        createdAt: now,
        updatedAt: now,
      );

      if (isCloud) {
        final cloudScheduler = CloudSchedulerRepository();
        await cloudScheduler.publishTask(task);
      } else {
        final schedulerRepo = SchedulerRepository();
        final schedulerManager = SchedulerManager(schedulerRepo);
        await schedulerManager.publishTask(
          PublishTaskCommand(
            title: taskTitle,
            type: TaskType.reminder,
            category: TaskCategory.sales,
            priority: _priority,
            scheduledAt: _scheduledDateTime,
            deadlineAt: _scheduledDateTime.add(const Duration(hours: 4)),
            notes: _notesController.text.trim(),
            linkedCustomerId: widget.customerId,
            linkedOrderId: widget.orderId,
            producer: TaskProducer.orders,
            sourceRef: sourceRef,
            requiresAlarm: _requiresAlarm,
          ),
        );
      }

      if (!mounted) return;

      widget.onScheduled?.call();
      Navigator.of(context).pop(true);

      final dateFormatted = DateFormat.yMMMd().add_jm().format(_scheduledDateTime);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment follow-up scheduled for $dateFormatted'),
          backgroundColor: const Color(0xFF1E5E3A),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = 'Unable to schedule follow-up: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();
    final timeFormat = DateFormat.jm();
    final formattedTime = timeFormat.format(_scheduledDateTime);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.alarm_add_outlined, color: Color(0xFF1E5E3A)),
          SizedBox(width: 8),
          Text('Schedule Payment Follow-up'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F4EE),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2D9CC)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order: ${widget.orderNo}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.customerName.isEmpty ? 'Walk-in Customer' : widget.customerName,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Outstanding:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        _formatPaise(widget.outstandingAmountPaise),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Reminder Date & Time',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : _pickDate,
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(dateFormat.format(_selectedDate)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : _pickTime,
                    icon: const Icon(Icons.access_time, size: 16),
                    label: Text(formattedTime),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              enabled: !_isSaving,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes / Instructions',
                border: OutlineInputBorder(),
                filled: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Priority:', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 12),
                SegmentedButton<TaskPriority>(
                  segments: const [
                    ButtonSegment(value: TaskPriority.normal, label: Text('Normal')),
                    ButtonSegment(value: TaskPriority.urgent, label: Text('Urgent')),
                  ],
                  selected: {_priority},
                  onSelectionChanged: _isSaving
                      ? null
                      : (newSelection) {
                          setState(() => _priority = newSelection.first);
                        },
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Audible Alarm / Notification', style: TextStyle(fontSize: 14)),
              subtitle: const Text('Sound reminder when due', style: TextStyle(fontSize: 12, color: Colors.grey)),
              value: _requiresAlarm,
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => _requiresAlarm = value),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1E5E3A),
          ),
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.check, size: 18),
          label: Text(_isSaving ? 'Scheduling...' : 'Set Reminder'),
        ),
      ],
    );
  }
}
