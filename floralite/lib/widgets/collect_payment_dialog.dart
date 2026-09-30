import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/database/app_database.dart';
import '../data/repositories/cloud_order_repository.dart';
import '../data/repositories/cloud_scheduler_repository.dart';
import '../data/repositories/scheduler_repository.dart';
import '../models/scheduler_task.dart';
import '../providers/order_provider.dart';
import '../providers/storage_mode_provider.dart';

/// Shows the standardized, reusable Collect Payment dialog.
Future<bool?> showCollectPaymentDialog({
  required BuildContext context,
  required int orderId,
  String? cloudOrderId,
  required String orderNo,
  required String customerName,
  required int grandTotalPaise,
  required int paidAmountPaise,
  required int outstandingAmountPaise,
  VoidCallback? onPaymentSuccess,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => CollectPaymentDialog(
      orderId: orderId,
      cloudOrderId: cloudOrderId,
      orderNo: orderNo,
      customerName: customerName,
      grandTotalPaise: grandTotalPaise,
      paidAmountPaise: paidAmountPaise,
      outstandingAmountPaise: outstandingAmountPaise,
      onPaymentSuccess: onPaymentSuccess,
    ),
  );
}

class CollectPaymentDialog extends StatefulWidget {
  const CollectPaymentDialog({
    super.key,
    required this.orderId,
    this.cloudOrderId,
    required this.orderNo,
    required this.customerName,
    required this.grandTotalPaise,
    required this.paidAmountPaise,
    required this.outstandingAmountPaise,
    this.onPaymentSuccess,
  });

  final int orderId;
  final String? cloudOrderId;
  final String orderNo;
  final String customerName;
  final int grandTotalPaise;
  final int paidAmountPaise;
  final int outstandingAmountPaise;
  final VoidCallback? onPaymentSuccess;

  @override
  State<CollectPaymentDialog> createState() => _CollectPaymentDialogState();
}

class _CollectPaymentDialogState extends State<CollectPaymentDialog> {
  late final TextEditingController _amountController;
  final TextEditingController _referenceController = TextEditingController();
  String _method = 'cash';
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final defaultAmount = (widget.outstandingAmountPaise / 100);
    _amountController = TextEditingController(
      text: defaultAmount % 1 == 0
          ? defaultAmount.toInt().toString()
          : defaultAmount.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  String _formatPaise(int paise) {
    final rs = paise / 100;
    if (rs % 1 == 0) {
      return '₹${rs.toInt()}';
    }
    return '₹${rs.toStringAsFixed(2)}';
  }

  int _parseCurrencyToPaise(String input) {
    final clean = input.replaceAll('₹', '').replaceAll(',', '').trim();
    final parsed = double.tryParse(clean);
    if (parsed == null || parsed.isNaN || parsed.isInfinite) return 0;
    return (parsed * 100).round();
  }

  Future<void> _submit() async {
    if (_isSaving) return;

    final amountPaise = _parseCurrencyToPaise(_amountController.text);
    if (amountPaise <= 0) {
      setState(() => _errorMessage = 'Enter a valid payment amount greater than ₹0.');
      return;
    }
    if (amountPaise > widget.outstandingAmountPaise) {
      setState(() => _errorMessage = 'Amount cannot exceed outstanding balance of ${_formatPaise(widget.outstandingAmountPaise)}.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final storageMode = context.read<StorageModeProvider>();
      final isCloud = storageMode.isCloud;
      final isCloudOrder = isCloud && widget.cloudOrderId != null && widget.cloudOrderId!.isNotEmpty;

      if (isCloudOrder) {
        final cloudRepo = CloudOrderRepository();
        await cloudRepo.collectPayment(
          cloudOrderId: widget.cloudOrderId!.trim(),
          method: _method,
          amountPaise: amountPaise,
        );
      } else {
        final orderProvider = context.read<OrderProvider>();
        await orderProvider.collectOrderPayment(
          orderId: widget.orderId,
          method: _method,
          amountPaise: amountPaise,
          reference: _referenceController.text.trim().isEmpty
              ? null
              : _referenceController.text.trim(),
        );
      }

      final newOutstandingPaise = widget.outstandingAmountPaise - amountPaise;

      // Handle linked payment follow-up tasks
      await _handlePaymentFollowUpTasks(
        isCloud: isCloudOrder,
        orderId: widget.orderId,
        cloudOrderId: widget.cloudOrderId,
        newOutstandingPaise: newOutstandingPaise,
        customerName: widget.customerName,
      );

      if (!mounted) return;

      widget.onPaymentSuccess?.call();

      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Collected ${_formatPaise(amountPaise)} for order ${widget.orderNo} (${_method.toUpperCase()}).',
          ),
          backgroundColor: const Color(0xFF1E5E3A),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = 'Unable to collect payment: $e';
      });
    }
  }

  Future<void> _handlePaymentFollowUpTasks({
    required bool isCloud,
    required int orderId,
    String? cloudOrderId,
    required int newOutstandingPaise,
    required String customerName,
  }) async {
    try {
      final sourceRef = isCloud && cloudOrderId != null && cloudOrderId.isNotEmpty
          ? 'payment_followup:order_$cloudOrderId'
          : 'payment_followup:order_$orderId';

      if (newOutstandingPaise <= 0) {
        // Full payment collected: close the follow-up task
        if (isCloud) {
          final cloudScheduler = CloudSchedulerRepository();
          final tasks = await cloudScheduler.listTasks(query: sourceRef);
          for (final t in tasks) {
            if (t.sourceRef == sourceRef &&
                t.status != TaskStatus.completed &&
                t.status != TaskStatus.cancelled &&
                t.cloudId != null) {
              await cloudScheduler.setStatus(t.cloudId!, TaskStatus.completed);
            }
          }
        } else {
          final schedulerRepo = SchedulerRepository();
          final db = await AppDatabase.instance.database;
          final rows = await db.query(
            'scheduler_tasks',
            columns: ['id'],
            where: 'source_ref = ? AND status IN (?, ?, ?) AND deleted_at IS NULL',
            whereArgs: [sourceRef, 'pending', 'inProgress', 'deferred'],
          );
          for (final r in rows) {
            final id = r['id'] as int;
            await schedulerRepo.updateTaskStatus(id, TaskStatus.completed);
          }
        }
      } else {
        // Partial payment collected: update remaining balance in task notes
        final updatedNote = 'Collect ${_formatPaise(newOutstandingPaise)} from $customerName';
        if (isCloud) {
          final cloudScheduler = CloudSchedulerRepository();
          final tasks = await cloudScheduler.listTasks(query: sourceRef);
          for (final t in tasks) {
            if (t.sourceRef == sourceRef &&
                t.status != TaskStatus.completed &&
                t.status != TaskStatus.cancelled &&
                t.cloudId != null) {
              final updated = t.copyWith(notes: updatedNote);
              await cloudScheduler.updateTask(t.cloudId!, updated);
            }
          }
        } else {
          final db = await AppDatabase.instance.database;
          await db.update(
            'scheduler_tasks',
            {
              'notes': updatedNote,
              'updated_at': DateTime.now().toIso8601String(),
            },
            where: 'source_ref = ? AND status IN (?, ?, ?) AND deleted_at IS NULL',
            whereArgs: [sourceRef, 'pending', 'inProgress', 'deferred'],
          );
        }
      }
    } catch (e) {
      debugPrint('Follow-up task auto-update error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.payments_outlined, color: Color(0xFF1E5E3A)),
          SizedBox(width: 8),
          Text('Collect Payment'),
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
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:', style: TextStyle(fontSize: 13)),
                      Text(_formatPaise(widget.grandTotalPaise), style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Already Paid:', style: TextStyle(fontSize: 13)),
                      Text(_formatPaise(widget.paidAmountPaise), style: const TextStyle(fontSize: 13, color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Outstanding Balance:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      Text(
                        _formatPaise(widget.outstandingAmountPaise),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enabled: !_isSaving,
              decoration: const InputDecoration(
                labelText: 'Collection Amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
                filled: true,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _method,
              decoration: const InputDecoration(
                labelText: 'Payment Mode / Tender',
                border: OutlineInputBorder(),
                filled: true,
              ),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'upi', child: Text('UPI / QR')),
                DropdownMenuItem(value: 'card', child: Text('Card')),
                DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
              ],
              onChanged: _isSaving
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _method = value);
                      }
                    },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _referenceController,
              enabled: !_isSaving,
              decoration: const InputDecoration(
                labelText: 'Reference / Note (optional)',
                border: OutlineInputBorder(),
                filled: true,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
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
          label: Text(_isSaving ? 'Processing...' : 'Confirm Collection'),
        ),
      ],
    );
  }
}
