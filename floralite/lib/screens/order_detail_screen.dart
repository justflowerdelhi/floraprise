import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/voice_dictation_controller.dart';
import '../data/repositories/associate_repository.dart';
import '../data/repositories/staff_repository.dart';
import '../data/repositories/third_party_delivery_repository.dart';
import '../l10n/app_localizations.dart';
import '../models/payment_split.dart';
import '../models/order_status.dart';
import '../models/order_workspace_models.dart';
import '../models/walk_in_enums.dart' hide OrderStatus;
import '../models/walk_in_line_item.dart';
import '../models/walk_in_session.dart';
import '../providers/order_provider.dart';
import '../providers/order_workflow_provider.dart';
import '../services/delivery_tracking_service.dart';
import '../services/speech_recognition_service.dart';
import 'delivery_screen.dart';
import 'live_delivery_tracking_screen.dart';
import 'pickup_later_screen.dart';
import 'take_away_screen.dart';
import '../utils/whatsapp_phone_utils.dart';
import '../widgets/common_widgets.dart';
import '../widgets/voice_dictation_field_header.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final DeliveryTrackingService _deliveryTrackingService =
      DeliveryTrackingService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrderDetailProgressive(widget.orderId);
      final workflowProvider = context.read<OrderWorkflowProvider>();
      workflowProvider.loadWorkflow(widget.orderId);
      workflowProvider.loadAssignableAssociates();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.orderDetails),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editOrder(),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Consumer<OrderProvider>(
          builder: (context, provider, _) {
            final header = provider.detailHeader;
            final detail = provider.detailBundle;

            if (provider.isDetailLoading && header == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (header == null) {
              return Center(child: Text(l10n.orderNotFound));
            }

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderHeader(header, colorScheme),
                  const SizedBox(height: 12),
                  _buildWorkflowQuickActions(header, detail),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Timeline',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...(detail?.timeline ?? const <OrderTimelineItem>[])
                            .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${_pretty(item.status)} • ${_formatDateTime(item.createdAt)}',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Items',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...(detail?.lines ?? const <Map<String, Object?>>[])
                            .map(
                          (line) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildOrderItem(
                              (line['description'] as String?) ?? '-',
                              _formatPaise(
                                  (line['line_total_paise'] as int?) ?? 0),
                              (line['qty'] as int?) ?? 0,
                            ),
                          ),
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formatPaise(header.grandTotalPaise),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Linkages',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildLinkageRow(
                          'Scheduler Tasks',
                          '${detail?.schedulerTasks.length ?? 0}',
                        ),
                        _buildLinkageRow(
                          'Inventory Impact Rows',
                          '${detail?.inventoryTransactions.length ?? 0}',
                        ),
                        _buildLinkageRow(
                          'Receipt Status',
                          (detail?.receiptStatus ?? 'pending').toString(),
                        ),
                        _buildLinkageRow(
                          'WhatsApp Status',
                          (detail?.whatsappStatus ?? 'pending').toString(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (detail != null) ...[
                    _buildInfoCard('Relay Information', detail.relayInfo),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                        'Corporate Information', detail.corporateInfo),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                        'Marketplace Information', detail.marketplaceInfo),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderHeader(
    OrderDetailHeader header,
    ColorScheme colorScheme,
  ) {
    final outstanding = header.outstandingAmountPaise;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Number row
          Row(
            children: [
              Text(
                header.orderNo,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              StatusChip(
                label: _pretty(header.status),
                color: _getStatusColor(header.status),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Recipient Name - LARGE (primary focus)
          Text(
            header.recipientName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Ordered by customer
          Text(
            'Ordered by ${header.customerName}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 14),
          // Metadata grid
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _headerValue('Occasion', header.occasion),
              _headerValue('Source', _pretty(header.source)),
              _headerValue('Fulfillment', _pretty(header.fulfilmentType)),
              _headerValue('Delivery Date', _formatDate(header.scheduledAt)),
              _headerValue('Delivery Slot', _pretty(header.deliverySlot)),
              _headerValue('Payment', header.paymentStatus),
              _headerValue('Total', _formatPaise(header.grandTotalPaise)),
              if (outstanding > 0)
                _headerValue('Outstanding', _formatPaise(outstanding),
                    isAlert: true),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Assigned To row
          Row(
            children: [
              Expanded(
                child: _assignedToChip(
                  Icons.brush_rounded,
                  'Designer',
                  header.designerName,
                  colorScheme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _assignedToChip(
                  Icons.delivery_dining_rounded,
                  'Delivery',
                  header.deliveryName,
                  colorScheme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerValue(String label, String value, {bool isAlert = false}) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),
          Text(
            value.trim().isEmpty ? '-' : value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isAlert ? Colors.red.shade700 : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _assignedToChip(
    IconData icon,
    String role,
    String? name,
    ColorScheme colorScheme,
  ) {
    final assigned = name != null && name.trim().isNotEmpty;
    final color = assigned ? colorScheme.primary : Colors.grey.shade400;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: assigned
            ? colorScheme.primary.withValues(alpha: 0.08)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
                Text(
                  assigned ? name : 'Not Assigned',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: assigned ? null : Colors.grey.shade500,
                    fontStyle: assigned ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowQuickActions(
    OrderDetailHeader header,
    OrderDetailBundle? detail,
  ) {
    return Consumer<OrderWorkflowProvider>(
      builder: (context, workflowProvider, _) {
        final disabled = workflowProvider.isLoading;
        final deliveryAssigned =
            (header.deliveryName ?? '').trim().isNotEmpty ||
                header.status == 'out_for_delivery' ||
                header.status == 'delivered';
        final actions = [
          _OrderQuickAction(
            'Assign Designer',
            Icons.design_services,
            disabled ? null : () => _assignDesigner(header, detail),
          ),
          _OrderQuickAction(
            'Assign Delivery',
            Icons.delivery_dining,
            disabled ? null : () => _assignDelivery(header, detail),
          ),
          _OrderQuickAction(
            'Track Delivery',
            Icons.location_searching_rounded,
            disabled || !deliveryAssigned
                ? null
                : () => _openLiveTracking(header.id),
          ),
          _OrderQuickAction(
            'Copy Tracking Link',
            Icons.link_rounded,
            disabled || !deliveryAssigned
                ? null
                : () => _copyTrackingLink(header.id),
          ),
          _OrderQuickAction(
            'Share Tracking Link',
            Icons.share_rounded,
            disabled || !deliveryAssigned
                ? null
                : () => _shareTrackingLinkViaWhatsApp(header.id),
          ),
          _OrderQuickAction(
            'Preview Customer View',
            Icons.public_rounded,
            disabled || !deliveryAssigned
                ? null
                : () => _openPublicTrackingView(header.id),
          ),
          _OrderQuickAction(
            'Forward Associate',
            Icons.forward_to_inbox,
            disabled ? null : () => _forwardAssociate(header, detail),
          ),
          _OrderQuickAction(
            'Update Status',
            Icons.sync_alt,
            disabled ? null : () => _showStatusPicker(header),
          ),
          _OrderQuickAction(
            'Print',
            Icons.print,
            disabled ? null : () => _showPrintMenu(header, detail),
          ),
          _OrderQuickAction(
            'More',
            Icons.more_horiz,
            () => _showMoreMenu(header, detail),
          ),
        ];

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: actions.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 3.2,
                ),
                itemBuilder: (context, index) {
                  final action = actions[index];
                  final color = Theme.of(context).colorScheme.primary;
                  return InkWell(
                    onTap: action.onTap,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(10),
                        color: color.withValues(alpha: 0.07),
                      ),
                      child: Row(
                        children: [
                          Icon(action.icon, color: color, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              action.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              if (workflowProvider.error != null) ...[
                const SizedBox(height: 8),
                Text(
                  workflowProvider.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _openLiveTracking(int orderId) async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveDeliveryTrackingScreen(orderId: orderId),
      ),
    );
  }

  Future<void> _copyTrackingLink(int orderId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final snapshot =
          await _deliveryTrackingService.getTrackingByOrderId(orderId);
      final link = snapshot.trackingLink.trim();
      if (link.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Tracking link is not available yet.')),
        );
        return;
      }
      await Clipboard.setData(ClipboardData(text: link));
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Tracking link copied.')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Unable to copy tracking link: $e')),
      );
    }
  }

  Future<void> _shareTrackingLinkViaWhatsApp(int orderId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final snapshot =
          await _deliveryTrackingService.getTrackingByOrderId(orderId);
      final link = snapshot.trackingLink.trim();
      if (link.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Tracking link is not available yet.')),
        );
        return;
      }

      final message = 'Track your delivery live:\n$link';
      final waUri = Uri.parse(
        'https://wa.me/?text=${Uri.encodeComponent(message)}',
      );

      if (await launchUrl(waUri, mode: LaunchMode.externalApplication)) {
        return;
      }

      final fallback = Uri.parse(
        'https://api.whatsapp.com/send?text=${Uri.encodeComponent(message)}',
      );
      if (await launchUrl(fallback, mode: LaunchMode.externalApplication)) {
        return;
      }

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Unable to open WhatsApp on this device')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Unable to share tracking link: $e')),
      );
    }
  }

  Future<void> _openPublicTrackingView(int orderId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final snapshot =
          await _deliveryTrackingService.getTrackingByOrderId(orderId);
      final link = snapshot.trackingLink.trim();
      if (link.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Tracking link is not available yet.')),
        );
        return;
      }
      if (!mounted) return;
      await Navigator.pushNamed(
        context,
        '/public-delivery-tracking',
        arguments: {
          'trackingLink': link,
          'orderId': orderId,
          'assignmentId': snapshot.assignmentId,
        },
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Unable to open customer tracking view: $e')),
      );
    }
  }

  Future<Staff?> _selectStaff(String title, StaffRole role) async {
    final repository = StaffRepository();
    final staff = await repository.searchStaff(
      roles: [role],
      activeOnly: true,
    );

    if (!mounted) return null;

    return showDialog<Staff>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: staff.isEmpty
              ? const Text('No active staff available for this role.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: staff.length,
                  itemBuilder: (context, index) {
                    final person = staff[index];
                    return ListTile(
                      title: Text(person.name),
                      subtitle: Text(person.phone),
                      onTap: () => Navigator.pop(dialogContext, person),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<AssociateRecord?> _selectAssociate(
      String title, List<AssociateRecord> associates) async {
    if (!mounted) return null;

    return showDialog<AssociateRecord>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: associates.isEmpty
              ? const Text(
                  'No active associates available. Add one in Associates.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: associates.length,
                  itemBuilder: (context, index) {
                    final associate = associates[index];
                    return ListTile(
                      title: Text(associate.businessName),
                      subtitle: Text(associate.typesDisplay),
                      onTap: () => Navigator.pop(dialogContext, associate),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _assignDesigner(
    OrderDetailHeader header,
    OrderDetailBundle? detail,
  ) async {
    final workflowProvider = context.read<OrderWorkflowProvider>();
    final orderProvider = context.read<OrderProvider>();
    final designer = await _selectStaff('Select Designer', StaffRole.designer);
    if (designer == null || !mounted) return;

    await workflowProvider.sendToDesigner(
      orderId: header.id,
      designerId: designer.id,
      notes: 'Assigned to ${designer.name}',
    );
    if (!mounted) return;
    await orderProvider.loadOrderDetailProgressive(header.id);

    final sendWhatsApp = await _showAssignmentChoiceDialog(
      'Designer Assigned Successfully',
    );
    if (sendWhatsApp != true || !mounted) return;

    await _launchWhatsAppMessage(
      phone: designer.whatsapp?.trim().isNotEmpty == true
          ? designer.whatsapp!
          : designer.phone,
      message: _designerChecklist(header, detail, designer.name),
    );
  }

  Future<void> _assignDelivery(
    OrderDetailHeader header,
    OrderDetailBundle? detail,
  ) async {
    final deliveryType = await _showDeliveryTypeDialog();
    if (deliveryType == null || !mounted) return;

    await _waitForRouteTeardown();
    if (!mounted) return;

    if (deliveryType == 'internal') {
      await _assignInternalDelivery(header, detail);
    } else {
      await _assignThirdPartyDelivery(header, detail);
    }
  }

  Future<String?> _showDeliveryTypeDialog() async {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Assign Delivery'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Internal Delivery'),
              subtitle: const Text('Assign to staff member'),
              leading: const Icon(Icons.person),
              onTap: () => Navigator.pop(dialogContext, 'internal'),
            ),
            ListTile(
              title: const Text('Third-Party Delivery'),
              subtitle: const Text('Porter, Dunzo, Borzo, etc.'),
              leading: const Icon(Icons.local_shipping),
              onTap: () => Navigator.pop(dialogContext, 'third-party'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignInternalDelivery(
    OrderDetailHeader header,
    OrderDetailBundle? detail,
  ) async {
    final workflowProvider = context.read<OrderWorkflowProvider>();
    final orderProvider = context.read<OrderProvider>();
    final delivery =
        await _selectStaff('Select Delivery Person', StaffRole.delivery);
    if (delivery == null || !mounted) return;

    await workflowProvider.assignDeliveryPartner(
      orderId: header.id,
      deliveryPartnerId: delivery.id,
      notes: 'Assigned to ${delivery.name}',
    );
    if (!mounted) return;

    await orderProvider.loadOrderDetailProgressive(header.id);
    if (!mounted) return;

    await _launchWhatsAppMessage(
      phone: delivery.whatsapp?.trim().isNotEmpty == true
          ? delivery.whatsapp!
          : delivery.phone,
      message: _deliveryChecklist(header, detail, delivery.name),
    );
  }

  Future<void> _assignThirdPartyDelivery(
    OrderDetailHeader header,
    OrderDetailBundle? detail,
  ) async {
    final result = await _showThirdPartyDeliveryDialog();
    if (result == null || !mounted) return;

    final repository = ThirdPartyDeliveryRepository();
    final input = ThirdPartyDeliveryInput(
      orderId: header.id,
      deliveryPartner: result['deliveryPartner'] as String,
      bookingReference: result['bookingReference'] as String?,
      driverName: result['driverName'] as String?,
      driverMobile: result['driverMobile'] as String?,
      deliveryChargesPaise: result['deliveryChargesPaise'] as int,
      notes: result['notes'] as String?,
    );
    final existing = await repository.getByOrderId(header.id);
    if (existing == null) {
      await repository.create(input);
    } else {
      await repository.update(existing.id, input);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Third-party delivery assigned')),
    );

    final driverMobile = input.driverMobile?.trim();
    if (driverMobile != null && driverMobile.isNotEmpty) {
      await _launchWhatsAppMessage(
        phone: driverMobile,
        message: _deliveryChecklist(
          header,
          detail,
          input.driverName?.trim().isNotEmpty == true
              ? input.driverName!.trim()
              : input.deliveryPartner.trim(),
        ),
      );
    }
  }

  Future<Map<String, dynamic>?> _showThirdPartyDeliveryDialog() async {
    if (!mounted) return null;

    final partnerController = TextEditingController();
    final bookingRefController = TextEditingController();
    final driverNameController = TextEditingController();
    final driverMobileController = TextEditingController();
    final chargesController = TextEditingController(text: '0');
    final notesController = TextEditingController();
    final notesDictationController = VoiceDictationController(
      speechRecognition: SpeechRecognitionService(),
    );
    notesDictationController.bindController(notesController);

    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Third-Party Delivery'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: partnerController,
                  decoration: const InputDecoration(
                    labelText: 'Delivery Partner',
                    hintText: 'e.g., Porter, Dunzo, Borzo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bookingRefController,
                  decoration: const InputDecoration(
                    labelText: 'Booking Reference',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: driverNameController,
                  decoration: const InputDecoration(
                    labelText: 'Driver Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: driverMobileController,
                  decoration: const InputDecoration(
                    labelText: 'Driver Mobile',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: chargesController,
                  decoration: const InputDecoration(
                    labelText: 'Delivery Charges (₹)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                VoiceDictationFieldHeader(
                  label: 'Notes',
                  controller: notesDictationController,
                  compact: true,
                ),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, {
                  'deliveryPartner': partnerController.text,
                  'bookingReference': bookingRefController.text,
                  'driverName': driverNameController.text,
                  'driverMobile': driverMobileController.text,
                  'deliveryChargesPaise':
                      ((double.tryParse(chargesController.text) ?? 0) * 100)
                          .round(),
                  'notes': notesController.text,
                });
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      );
      await _waitForRouteTeardown();
      return result;
    } finally {
      partnerController.dispose();
      bookingRefController.dispose();
      driverNameController.dispose();
      driverMobileController.dispose();
      chargesController.dispose();
      notesController.dispose();
      notesDictationController.dispose();
    }
  }

  Future<bool?> _showAssignmentChoiceDialog(String title) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: const Text('Do you want to send WhatsApp now?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Done'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Send WhatsApp'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchWhatsAppMessage({
    required String phone,
    required String message,
  }) async {
    final normalizedPhone = WhatsAppPhoneUtils.normalize(phone);
    if (normalizedPhone == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid phone number for WhatsApp')),
      );
      return;
    }

    final uri = WhatsAppPhoneUtils.buildUri(normalizedPhone, message: message);
    final fallback = WhatsAppPhoneUtils.buildFallbackUri(
      normalizedPhone,
      message: message,
    );

    if (uri != null && await _launchExternalUri(uri)) {
      return;
    }

    if (fallback != null && await _launchExternalUri(fallback)) {
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not launch WhatsApp')),
    );
  }

  Future<void> _forwardAssociate(
    OrderDetailHeader header,
    OrderDetailBundle? detail,
  ) async {
    final workflowProvider = context.read<OrderWorkflowProvider>();
    final orderProvider = context.read<OrderProvider>();
    final associates = List<AssociateRecord>.from(workflowProvider.associates);

    if (!mounted) return;

    final associate = await _selectAssociate('Select Associate', associates);
    if (associate == null || !mounted) return;

    await _waitForRouteTeardown();
    if (!mounted) return;

    final referenceController = TextEditingController();
    final amountController = TextEditingController();
    final values = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Forward to ${associate.businessName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: referenceController,
              decoration: const InputDecoration(labelText: 'Reference Number'),
            ),
            TextField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Fulfillment Amount',
                prefixText: '₹ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, [
              referenceController.text.trim(),
              amountController.text.trim(),
            ]),
            child: const Text('Forward'),
          ),
        ],
      ),
    );
    await _waitForRouteTeardown();
    referenceController.dispose();
    amountController.dispose();
    if (values == null || !mounted) return;

    final note = 'Reference: ${values[0]} • Fulfillment: ₹${values[1]}';
    await workflowProvider.assignRelayPartner(
      orderId: header.id,
      relayPartnerId: associate.id,
      notes: note,
    );
    if (!mounted) return;

    await orderProvider.loadOrderDetailProgressive(header.id);
    if (!mounted) return;

    await _waitForRouteTeardown();
    if (!mounted) return;

    final phone = associate.whatsapp?.trim().isNotEmpty == true
        ? associate.whatsapp!
        : associate.phone;
    final normalizedPhone = WhatsAppPhoneUtils.normalize(phone);
    if (normalizedPhone != null && mounted) {
      final message = _forwardAssociateMessage(header, detail, note);
      final uri =
          WhatsAppPhoneUtils.buildUri(normalizedPhone, message: message);
      final fallback = WhatsAppPhoneUtils.buildFallbackUri(
        normalizedPhone,
        message: message,
      );
      if (uri != null && await _launchExternalUri(uri)) {
        return;
      }
      if (fallback != null && await _launchExternalUri(fallback)) {
        return;
      }
    }
  }

  Future<bool> _launchExternalUri(Uri uri) async {
    try {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  Future<void> _waitForRouteTeardown() async {
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> _showStatusPicker(OrderDetailHeader header) async {
    const statuses = [
      OrderStatus.preparing,
      OrderStatus.ready,
      OrderStatus.outForDelivery,
      OrderStatus.delivered,
      OrderStatus.cancelled,
    ];
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Update Status')),
            ...statuses.map(
              (status) => ListTile(
                leading: Icon(Icons.circle, color: OrderStatus.color(status)),
                title: Text(OrderStatus.label(status)),
                enabled: OrderStatus.canTransition(header.status, status),
                onTap: OrderStatus.canTransition(header.status, status)
                    ? () => Navigator.pop(sheetContext, status)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    await context.read<OrderProvider>().updateOrderStatus(
          orderId: header.id,
          currentStatus: header.status,
          newStatus: selected,
        );
    if (!mounted) return;
    await context.read<OrderWorkflowProvider>().loadWorkflow(header.id);
  }

  Future<void> _showPrintMenu(
    OrderDetailHeader header,
    OrderDetailBundle? detail,
  ) async {
    final workflowProvider = context.read<OrderWorkflowProvider>();
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Print',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Print Bill'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await workflowProvider.printReceipt(header.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping),
              title: const Text('Print Delivery Slip'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await workflowProvider.printDeliverySlip(header.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.card_giftcard),
              title: const Text('Print Message Card'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await workflowProvider.printMessageCard(header.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreMenu(
    OrderDetailHeader header,
    OrderDetailBundle? detail,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'More Actions',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('View Bill'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showBill(header, detail);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Order'),
              onTap: () {
                Navigator.pop(sheetContext);
                _editOrder(header: header, detail: detail);
              },
            ),
            if (OrderStatus.canCancel(header.status))
              ListTile(
                leading: Icon(Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error),
                title: Text(
                  'Cancel Order',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmDeleteOrder(header);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBill(
    OrderDetailHeader header,
    OrderDetailBundle? detail,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Bill ${header.orderNo}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...?detail?.lines.map(
                (line) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text((line['description'] as String?) ?? 'Item'),
                  subtitle: Text('Qty ${(line['qty'] as int?) ?? 1}'),
                  trailing: Text(
                    _formatPaise((line['line_total_paise'] as int?) ?? 0),
                  ),
                ),
              ),
              const Divider(),
              _billRow('Total', _formatPaise(header.grandTotalPaise)),
              _billRow('Received', _formatPaise(header.paidAmountPaise)),
              _billRow('Balance', _formatPaise(header.outstandingAmountPaise)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              context.read<OrderWorkflowProvider>().printReceipt(header.id);
              Navigator.pop(dialogContext);
            },
            icon: const Icon(Icons.print),
            label: const Text('Print Bill'),
          ),
        ],
      ),
    );
  }

  Widget _billRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value)],
      ),
    );
  }

  void _showEditOrderMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Delivered and cancelled orders are read-only.')),
    );
  }

  bool _canEditOrder(String status) {
    return status != OrderStatus.delivered && status != OrderStatus.cancelled;
  }

  Future<void> _editOrder({
    OrderDetailHeader? header,
    OrderDetailBundle? detail,
  }) async {
    final currentHeader = header ?? context.read<OrderProvider>().detailHeader;
    final currentDetail = detail ?? context.read<OrderProvider>().detailBundle;
    if (currentHeader == null || currentDetail == null) return;

    if (!_canEditOrder(currentHeader.status)) {
      _showEditOrderMessage();
      return;
    }

    final session = _buildEditSession(currentHeader, currentDetail);
    final fulfilment = _parseFulfilmentType(currentHeader.fulfilmentType);

    Widget editor;
    switch (fulfilment) {
      case FulfilmentType.takeAway:
        editor = TakeAwayScreen(
          initialSession: session,
          editingOrderId: currentHeader.id,
        );
        break;
      case FulfilmentType.pickupLater:
        editor = PickupLaterScreen(
          initialSession: session,
          editingOrderId: currentHeader.id,
        );
        break;
      case FulfilmentType.delivery:
        editor = DeliveryScreen(
          initialSession: session,
          editingOrderId: currentHeader.id,
        );
        break;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => editor),
    );

    if (!mounted) return;
    await context
        .read<OrderProvider>()
        .loadOrderDetailProgressive(currentHeader.id);
  }

  FulfilmentType _parseFulfilmentType(String value) {
    return switch (value.toLowerCase()) {
      'take_away' => FulfilmentType.takeAway,
      'pickup_later' => FulfilmentType.pickupLater,
      _ => FulfilmentType.delivery,
    };
  }

  WalkInSession _buildEditSession(
    OrderDetailHeader header,
    OrderDetailBundle detail,
  ) {
    final lines = detail.lines
        .map(
          (line) => WalkInLineItem(
            productId: line['product_id'] as int?,
            description: (line['description'] as String?) ?? 'Item',
            quantity: (line['qty'] as int?) ?? 1,
            unitPricePaise: (line['unit_price_paise'] as int?) ?? 0,
            discountPaise: (line['discount_paise'] as int?) ?? 0,
            discountType: line['discount_type'] as String?,
            discountValue: line['discount_value'] as int?,
            gstPercent: (line['gst_percent'] as int?) ?? 0,
            source: (line['source'] as String?) ?? 'manual',
          ),
        )
        .toList(growable: false);

    final payments = detail.payments
        .map(
          (row) => PaymentSplit(
            method: switch (((row['method'] as String?) ?? '').toLowerCase()) {
              'cash' => PaymentMethod.cash,
              'upi' => PaymentMethod.upi,
              'card' => PaymentMethod.card,
              'bank' || 'bank_transfer' => PaymentMethod.bank,
              _ => PaymentMethod.other,
            },
            amountPaise: (row['amount_paise'] as int?) ?? 0,
            reference: row['reference'] as String?,
            methodCode: row['method'] as String?,
          ),
        )
        .toList(growable: false);

    return WalkInSession(
      draftOrderId: header.id,
      fulfilmentType: _parseFulfilmentType(header.fulfilmentType),
      lines: lines,
      customerPhone: header.customerPhone,
      customerName: header.customerName,
      occasion: header.occasion,
      scheduledAt: header.scheduledAt,
      deliverySlot: header.deliverySlot,
      recipientName: header.recipientName,
      recipientPhone: header.recipientPhone,
      deliveryAddress: header.address,
      cardMessage: header.cardMessage,
      specialInstructions: '',
      payments: payments,
      billDiscountType: null,
      billDiscountValue: null,
    );
  }

  Future<void> _confirmDeleteOrder(OrderDetailHeader header) async {
    if (!OrderStatus.canCancel(header.status)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Order'),
        content: const Text(
          'The order will be cancelled and retained for audit history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Order'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<OrderWorkflowProvider>().cancelOrder(
          orderId: header.id,
          currentStatus: header.status,
          reason: 'Cancelled from Order Details',
        );
    if (!mounted) return;
    await context.read<OrderProvider>().loadOrderDetailProgressive(header.id);
  }

  String _designerChecklist(
    OrderDetailHeader header,
    OrderDetailBundle? detail,
    String designerName,
  ) {
    return [
      '🌸 NEW DESIGN ORDER',
      '',
      'Order : ${header.orderNo}',
      '',
      'Recipient',
      header.recipientName,
      '',
      'Customer',
      header.customerName,
      '',
      'Delivery',
      _formatDate(header.scheduledAt),
      header.deliverySlot.isEmpty ? '-' : header.deliverySlot,
      '',
      'Designer',
      designerName,
      '',
      'Products',
      _productChecklist(detail, checked: true),
      '',
      'Message Card',
      header.cardMessage.isEmpty ? '-' : header.cardMessage,
      '',
      'Please acknowledge after preparation.',
    ].join('\n');
  }

  String _deliveryChecklist(
    OrderDetailHeader header,
    OrderDetailBundle? detail,
    String deliveryName,
  ) {
    final address = header.address.trim();
    final mapsLink = address.isNotEmpty
        ? 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}'
        : '-';
    final outstanding = header.outstandingAmountPaise;
    return [
      '🚚 DELIVERY ASSIGNMENT',
      '',
      'Order : ${header.orderNo}',
      '',
      'Recipient',
      header.recipientName,
      '',
      'Customer',
      header.customerName,
      '',
      'Phone',
      header.recipientPhone.isEmpty ? '-' : header.recipientPhone,
      '',
      'Delivery Address',
      address.isEmpty ? '-' : address,
      '',
      'Google Maps URL',
      mapsLink,
      '',
      'Delivery Slot',
      header.deliverySlot.isEmpty ? '-' : header.deliverySlot,
      '',
      'Occasion',
      header.occasion.isEmpty ? '-' : header.occasion,
      '',
      'Message Card Included',
      header.cardMessage.isEmpty ? 'NO' : 'YES',
      '',
      'Outstanding Amount',
      _formatPaise(outstanding),
      '',
      'Products',
      _productChecklist(detail, checked: false),
      '',
      'Delivery Person',
      deliveryName,
    ].join('\n');
  }

  String _forwardAssociateMessage(
    OrderDetailHeader header,
    OrderDetailBundle? detail,
    String note,
  ) {
    final outstanding = header.outstandingAmountPaise;
    return [
      '📦 FORWARD ASSOCIATE',
      '',
      'Order : ${header.orderNo}',
      '',
      'Recipient',
      header.recipientName,
      '',
      'Customer',
      header.customerName,
      '',
      'Products',
      _productChecklist(detail, checked: true),
      '',
      'Delivery Date',
      _formatDate(header.scheduledAt),
      '',
      'Delivery Slot',
      header.deliverySlot.isEmpty ? '-' : header.deliverySlot,
      '',
      'Card Message',
      header.cardMessage.isEmpty ? '-' : header.cardMessage,
      if (outstanding > 0) '',
      if (outstanding > 0) 'Outstanding Amount',
      if (outstanding > 0) _formatPaise(outstanding),
      '',
      note,
    ].join('\n');
  }

  String _productChecklist(
    OrderDetailBundle? detail, {
    required bool checked,
  }) {
    final lines = detail?.lines ?? const <Map<String, Object?>>[];
    if (lines.isEmpty) return checked ? '✅ No products' : '☐ No products';
    final mark = checked ? '✅' : '☐';
    return lines
        .map(
          (line) =>
              '$mark ${(line['qty'] as int?) ?? 1} × ${(line['product_name'] as String?) ?? (line['description'] as String?) ?? 'Item'}',
        )
        .join('\n');
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    return '${value.day}/${value.month}/${value.year}';
  }

  Widget _buildInfoCard(String title, Map<String, Object?> data) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (data.isEmpty)
            Text(l10n.noData)
          else
            ...data.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        _pretty(entry.key),
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: Text((entry.value ?? '-').toString()),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLinkageRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) {
      return '-';
    }
    final hour =
        value.hour == 0 ? 12 : (value.hour > 12 ? value.hour - 12 : value.hour);
    final minute = value.minute.toString().padLeft(2, '0');
    final meridiem = value.hour >= 12 ? 'PM' : 'AM';
    return '${value.day}/${value.month}/${value.year} $hour:$minute $meridiem';
  }

  String _formatPaise(int paise) {
    return '₹${(paise / 100).toStringAsFixed(0)}';
  }

  String _pretty(String value) {
    return value.replaceAll('_', ' ').replaceAllMapped(
          RegExp(r'(^|\s)([a-z])'),
          (m) => '${m.group(1)}${m.group(2)!.toUpperCase()}',
        );
  }

  Widget _buildOrderItem(String name, String price, int quantity) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Text(
          'x$quantity',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(width: 16),
        Text(
          price,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
      case 'confirmed':
        return Colors.orange;
      case 'preparing':
        return Colors.blue;
      case 'ready':
        return Colors.green;
      case 'out_for_delivery':
        return Colors.purple;
      case 'delivered':
        return Colors.teal;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

class _OrderQuickAction {
  const _OrderQuickAction(
    this.label,
    this.icon,
    this.onTap,
  );

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
}
