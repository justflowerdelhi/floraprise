import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/voice_dictation_controller.dart';
import '../data/repositories/order_workflow_repository.dart';
import '../managers/order_workflow_manager.dart';
import '../models/order_status.dart';
import '../models/order_workspace_models.dart';
import '../providers/order_workflow_provider.dart';
import '../services/speech_recognition_service.dart';
import '../services/order_whatsapp_service.dart';
import '../widgets/voice_dictation_field_header.dart';

class OrderWorkflowScreen extends StatefulWidget {
  const OrderWorkflowScreen({super.key, required this.orderId});

  final int orderId;

  @override
  State<OrderWorkflowScreen> createState() => _OrderWorkflowScreenState();
}

class _OrderWorkflowScreenState extends State<OrderWorkflowScreen> {
  final _noteController = TextEditingController();
  final _noteDictationController = VoiceDictationController(
    speechRecognition: SpeechRecognitionService(),
  );

  @override
  void initState() {
    super.initState();
    _noteDictationController.bindController(_noteController);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<OrderWorkflowProvider>();
      provider.loadWorkflow(widget.orderId);
      provider.loadAssignableAssociates();
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    _noteDictationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderWorkflowProvider>();
    final workflow = provider.workflow;
    final header = workflow?.header;

    return Scaffold(
      appBar: AppBar(
        title: header == null
            ? const Text('Order Workflow')
            : Text('Workflow #${header.orderNo}'),
      ),
      body: provider.isLoading || workflow == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.loadWorkflow(widget.orderId),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatusCard(header!),
                  const SizedBox(height: 16),
                  _buildStatusActions(provider, workflow),
                  const SizedBox(height: 16),
                  _buildAssignmentSection(provider, workflow),
                  const SizedBox(height: 16),
                  _buildPrintAndShareSection(provider, workflow),
                  const SizedBox(height: 16),
                  _buildTimelineSection(workflow),
                  const SizedBox(height: 16),
                  _buildNoteSection(provider, widget.orderId),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard(OrderDetailHeader header) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order #${header.orderNo}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(OrderStatus.label(header.status)),
                  backgroundColor:
                      OrderStatus.color(header.status).withValues(alpha: 0.15),
                  labelStyle:
                      TextStyle(color: OrderStatus.color(header.status)),
                ),
                const Spacer(),
                Text(
                  '₹${(header.grandTotalPaise / 100.0).toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Customer: ${header.customerName}'),
            Text('Phone: ${header.customerPhone}'),
            Text('Fulfilment: ${header.fulfilmentType}'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusActions(
    OrderWorkflowProvider provider,
    OrderWorkflowView workflow,
  ) {
    final header = workflow.header;
    final next = workflow.nextStatuses;

    if (next.isEmpty || OrderStatus.isTerminal(header.status)) {
      return const Card(
        child: ListTile(
          title: Text('No further status actions'),
          subtitle: Text('Order is in a terminal state.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Next Status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: next.map((status) {
                return ActionChip(
                  label: Text(OrderStatus.actionLabel(status)),
                  backgroundColor:
                      OrderStatus.color(status).withValues(alpha: 0.15),
                  labelStyle: TextStyle(color: OrderStatus.color(status)),
                  onPressed: provider.isLoading
                      ? null
                      : () => _onStatusChange(provider, header.status, status),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentSection(
    OrderWorkflowProvider provider,
    OrderWorkflowView workflow,
  ) {
    final header = workflow.header;
    final assignments = workflow.assignments;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assignments',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (header.status == OrderStatus.confirmed ||
                header.status == OrderStatus.sentToDesigner)
              _buildAssignButton(
                label: 'Designer',
                assigned: assignments['designer'],
                onAssign: (id) => provider.sendToDesigner(
                  orderId: widget.orderId,
                  designerId: id,
                ),
                provider: provider,
              ),
            if (header.status == OrderStatus.ready ||
                header.status == OrderStatus.outForDelivery ||
                header.status == OrderStatus.deliveryFailed)
              _buildAssignButton(
                label: 'Delivery Partner',
                assigned: assignments['delivery'],
                onAssign: (id) => provider.assignDeliveryPartner(
                  orderId: widget.orderId,
                  deliveryPartnerId: id,
                ),
                provider: provider,
              ),
            if (header.fulfilmentType.toLowerCase() == 'relay')
              _buildAssignButton(
                label: 'Relay Partner',
                assigned: assignments['relay'],
                onAssign: (id) => provider.assignRelayPartner(
                  orderId: widget.orderId,
                  relayPartnerId: id,
                ),
                provider: provider,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignButton({
    required String label,
    required AssignmentRow? assigned,
    required Future<void> Function(int) onAssign,
    required OrderWorkflowProvider provider,
  }) {
    final assignedText = assigned != null ? 'Assigned' : 'Not assigned';
    return ListTile(
      title: Text('$label ($assignedText)'),
      trailing: const Icon(Icons.person_add),
      onTap: provider.isLoading
          ? null
          : () => _showAssociatePicker(context, label, onAssign, provider),
    );
  }

  Widget _buildPrintAndShareSection(
    OrderWorkflowProvider provider,
    OrderWorkflowView workflow,
  ) {
    final header = workflow.header;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Print & Share',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: provider.isLoading
                      ? null
                      : () => provider.printReceipt(widget.orderId),
                  icon: const Icon(Icons.receipt),
                  label: const Text('Print Bill'),
                ),
                ElevatedButton.icon(
                  onPressed: provider.isLoading
                      ? null
                      : () => provider.printDeliverySlip(widget.orderId),
                  icon: const Icon(Icons.delivery_dining),
                  label: const Text('Delivery Slip'),
                ),
                ElevatedButton.icon(
                  onPressed: provider.isLoading
                      ? null
                      : () => provider.printMessageCard(widget.orderId),
                  icon: const Icon(Icons.card_giftcard),
                  label: const Text('Message Card'),
                ),
                ElevatedButton.icon(
                  onPressed: provider.isLoading || header.customerPhone.isEmpty
                      ? null
                      : () => _shareWhatsApp(provider, header.customerPhone),
                  icon: const Icon(Icons.message),
                  label: const Text('WhatsApp'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineSection(OrderWorkflowView workflow) {
    final timeline = workflow.timeline;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Timeline',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (timeline.isEmpty)
              const Text('No timeline events yet.')
            else
              ...timeline.map((event) {
                final status = event['status'] as String? ?? '';
                final notes = event['notes'] as String? ?? '';
                final createdAt = event['created_at'] as String? ?? '';
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor:
                        OrderStatus.color(status).withValues(alpha: 0.15),
                    child: Icon(
                      Icons.circle,
                      size: 10,
                      color: OrderStatus.color(status),
                    ),
                  ),
                  title: Text(
                    status == 'workflow_note'
                        ? 'Note'
                        : OrderStatus.label(status),
                    style: const TextStyle(fontSize: 13),
                  ),
                  subtitle: Text(
                    '$createdAt\n$notes'.trim(),
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteSection(OrderWorkflowProvider provider, int orderId) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Workflow Note',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            VoiceDictationFieldHeader(
              label: 'Add Workflow Note',
              controller: _noteDictationController,
              compact: true,
            ),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter a note...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: provider.isLoading
                  ? null
                  : () async {
                      final note = _noteController.text.trim();
                      if (note.isEmpty) return;
                      await provider.addNote(orderId: orderId, note: note);
                      _noteController.clear();
                    },
              child: const Text('Add Note'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onStatusChange(
    OrderWorkflowProvider provider,
    String currentStatus,
    String newStatus,
  ) async {
    final note = await _promptNote(context, newStatus);
    if (note == null) return;

    await provider.advanceStatus(
      orderId: widget.orderId,
      currentStatus: currentStatus,
      newStatus: newStatus,
      notes: note,
    );
  }

  Future<void> _shareWhatsApp(
    OrderWorkflowProvider provider,
    String phone,
  ) async {
    final template = await _promptTemplateSelection(context);
    if (template == null) return;

    await provider.shareWhatsApp(
      orderId: widget.orderId,
      template: template,
      phone: phone,
    );
  }

  Future<String?> _promptNote(BuildContext context, String newStatus) async {
    final controller = TextEditingController(
      text: OrderStatus.actionNote('', newStatus),
    );
    final noteDictationController = VoiceDictationController(
      speechRecognition: SpeechRecognitionService(),
    );
    noteDictationController.bindController(controller);
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Move to ${OrderStatus.label(newStatus)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VoiceDictationFieldHeader(
              label: 'Note (optional)',
              controller: noteDictationController,
              compact: true,
            ),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    noteDictationController.dispose();
    return result;
  }

  Future<String?> _promptTemplateSelection(BuildContext context) async {
    final templates = {
      'Status Update': OrderWhatsappService.orderStatusTemplate,
      'Ready': OrderWhatsappService.readyTemplate,
      'Out for Delivery': OrderWhatsappService.deliveryTemplate,
      'Delivered': OrderWhatsappService.deliveredTemplate,
    };

    return showDialog<String?>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select WhatsApp Template'),
        children: templates.entries.map((entry) {
          return SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(entry.value),
            child: Text(entry.key),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _showAssociatePicker(
    BuildContext context,
    String label,
    Future<void> Function(int) onAssign,
    OrderWorkflowProvider provider,
  ) async {
    final selected = await showDialog<int?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Select $label'),
        content: provider.associatesLoading
            ? const Center(child: CircularProgressIndicator())
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: provider.associates.length,
                  itemBuilder: (itemContext, index) {
                    final associate = provider.associates[index];
                    return ListTile(
                      title: Text(associate.businessName),
                      subtitle: Text(associate.typesDisplay),
                      onTap: () =>
                          Navigator.of(dialogContext).pop(associate.id),
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selected != null) {
      await onAssign(selected);
    }
  }
}
