import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/repositories/cloud_inventory_repository.dart';
import '../data/repositories/cloud_order_repository.dart';
import '../data/repositories/order_repository.dart';
import '../data/repositories/staff_repository.dart';
import '../models/order_status.dart';
import '../models/order_workspace_models.dart';
import '../models/payment_split.dart';
import '../models/walk_in_enums.dart' hide OrderStatus;
import '../models/walk_in_line_item.dart';
import '../models/walk_in_session.dart';
import '../providers/order_provider.dart';
import '../providers/order_workflow_provider.dart';
import '../services/delivery_tracking_service.dart';
import '../services/order_whatsapp_service.dart';
import '../utils/delivery_message_utils.dart';
import '../utils/order_display_utils.dart';
import '../utils/whatsapp_phone_utils.dart';
import '../screens/bouquet_production_entry_screen.dart';
import '../screens/cloud_order_edit_screen.dart';
import '../screens/delivery_screen.dart';
import '../screens/event_sale_screen.dart';
import '../screens/live_delivery_tracking_screen.dart';
import '../screens/pickup_later_screen.dart';
import '../screens/take_away_screen.dart';
import '../services/pdf/pdf_document_service.dart';
import 'common_widgets.dart';

/// Central Action Hub for Orders.
///
/// Displays a modal bottom sheet containing the clean retail-friendly action options:
/// - View Order
/// - Edit Order
/// - Change Status
/// - Collect / Adjust Payment
/// - Print
/// - WhatsApp / Share
/// - Assign Designer
/// - Assign Driver
/// - Track Delivery
/// - Cancel Order
void showOrderActionMenu(
  BuildContext context, {
  required int orderId,
  String? cloudOrderId,
  OrderListItem? orderListItem,
  OrderDetailHeader? header,
  OrderDetailBundle? detailBundle,
  VoidCallback? onOrderUpdated,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => _OrderActionMenuContent(
      parentContext: context,
      orderId: orderId,
      cloudOrderId: cloudOrderId ?? orderListItem?.cloudOrderId ?? header?.cloudOrderId,
      orderListItem: orderListItem,
      header: header,
      detailBundle: detailBundle,
      onOrderUpdated: onOrderUpdated,
    ),
  );
}

class _OrderActionMenuContent extends StatelessWidget {
  const _OrderActionMenuContent({
    required this.parentContext,
    required this.orderId,
    this.cloudOrderId,
    this.orderListItem,
    this.header,
    this.detailBundle,
    this.onOrderUpdated,
  });

  final BuildContext parentContext;
  final int orderId;
  final String? cloudOrderId;
  final OrderListItem? orderListItem;
  final OrderDetailHeader? header;
  final OrderDetailBundle? detailBundle;
  final VoidCallback? onOrderUpdated;

  bool get _isCloud =>
      (cloudOrderId != null && cloudOrderId!.trim().isNotEmpty);

  String get _displayOrderNo {
    if (header != null) return header!.displayOrderNo;
    if (orderListItem != null) return orderListItem!.displayOrderNo;
    return OrderDisplayUtils.format(null, orderId: orderId);
  }

  String get _status {
    if (header != null) return header!.status;
    if (orderListItem != null) return orderListItem!.status;
    return 'pending';
  }

  String get _customerName {
    if (header != null) return header!.customerName;
    if (orderListItem != null) return orderListItem!.customerName;
    return 'Customer';
  }

  String get _customerPhone {
    if (header != null) return header!.customerPhone;
    return '';
  }

  String get _recipientName {
    if (header != null) return header!.recipientName;
    if (orderListItem != null) return orderListItem!.recipientName;
    return '';
  }

  String get _recipientPhone {
    if (header != null) return header!.recipientPhone;
    return '';
  }

  int get _grandTotalPaise {
    if (header != null) return header!.grandTotalPaise;
    if (orderListItem != null) return orderListItem!.grandTotalPaise;
    return 0;
  }

  int get _outstandingPaise {
    if (header != null) return header!.outstandingAmountPaise;
    if (orderListItem != null) {
      return orderListItem!.isPaid == 1 ? 0 : orderListItem!.grandTotalPaise;
    }
    return 0;
  }

  bool get _isPaid {
    if (header != null) return header!.isPaid == 1 || header!.outstandingAmountPaise <= 0;
    if (orderListItem != null) return orderListItem!.isPaid == 1;
    return false;
  }

  String get _fulfilmentType {
    if (header != null) return header!.fulfilmentType.toLowerCase();
    if (orderListItem != null) return orderListItem!.fulfilmentType.toLowerCase();
    return 'delivery';
  }

  bool get _isDelivery => _fulfilmentType.contains('delivery');

  bool get _canCancel => OrderStatus.canCancel(_status);

  bool get _canEdit =>
      _status != OrderStatus.delivered && _status != OrderStatus.cancelled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = _getStatusColor(_status);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header Card
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayOrderNo,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _recipientName.isNotEmpty &&
                                _recipientName != _customerName &&
                                _recipientName.toLowerCase() != 'walk-in'
                            ? '$_recipientName (by $_customerName)'
                            : (_customerName.isNotEmpty
                                ? _customerName
                                : 'Walk-in Customer'),
                        style: const TextStyle(
                          color: Color(0xFF1E2922),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatPaise(_grandTotalPaise),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StatusChip(
                          label: _pretty(_status),
                          color: statusColor,
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _isPaid
                                ? Colors.green.shade50
                                : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isPaid
                                  ? Colors.green.shade300
                                  : Colors.orange.shade300,
                            ),
                          ),
                          child: Text(
                            _isPaid ? 'Paid' : 'Pending',
                            style: TextStyle(
                              color: _isPaid
                                  ? Colors.green.shade800
                                  : Colors.orange.shade900,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Action Items
            _ActionTile(
              icon: Icons.visibility_outlined,
              iconColor: colorScheme.primary,
              title: 'View Order',
              subtitle: 'Submitted order details & items summary',
              onTap: () => _viewOrder(context),
            ),
            if (_canEdit)
              _ActionTile(
                icon: Icons.edit_outlined,
                iconColor: Colors.blue.shade700,
                title: 'Edit Order',
                subtitle: 'Modify items, recipient, delivery, or message',
                onTap: () => _editOrder(context),
              ),
            if (!OrderStatus.isTerminal(_status))
              _ActionTile(
                icon: Icons.swap_horiz_rounded,
                iconColor: Colors.amber.shade800,
                title: 'Change Status',
                subtitle: 'Update workflow state (Preparing, Ready, Out for Delivery)',
                onTap: () => _changeStatus(context),
              ),
            _ActionTile(
              icon: Icons.payments_outlined,
              iconColor: _isPaid ? Colors.teal.shade700 : Colors.green.shade700,
              title: _outstandingPaise > 0 ? 'Collect Payment' : 'Adjust Payment',
              subtitle: _outstandingPaise > 0
                  ? 'Collect outstanding ${_formatPaise(_outstandingPaise)}'
                  : 'Record adjustment or refund',
              onTap: () => _collectOrAdjustPayment(context),
            ),
            _ActionTile(
              icon: Icons.print_outlined,
              iconColor: Colors.indigo.shade700,
              title: 'Print',
              subtitle: 'Thermal receipt, delivery slip, or message card',
              onTap: () => _showPrintOptions(context),
            ),
            _ActionTile(
              icon: Icons.picture_as_pdf_outlined,
              iconColor: Colors.red.shade700,
              title: 'Download / Share PDF',
              subtitle: 'A4 Bill Invoice or Delivery Slip PDF',
              onTap: () => _showPdfOptions(context),
            ),
            _ActionTile(
              icon: Icons.share_outlined,
              iconColor: Colors.green.shade800,
              title: 'WhatsApp / Share',
              subtitle: 'Send order details or tracking update to customer',
              onTap: () => _shareWhatsApp(context),
            ),
            _ActionTile(
              icon: Icons.palette_outlined,
              iconColor: Colors.purple.shade700,
              title: 'Assign Designer',
              subtitle: 'Assign florist for preparation',
              onTap: () => _assignDesigner(context),
            ),
            if (_isDelivery) ...[
              _ActionTile(
                icon: Icons.local_shipping_outlined,
                iconColor: Colors.deepOrange.shade700,
                title: 'Assign Driver',
                subtitle: 'Assign delivery person',
                onTap: () => _assignDriver(context),
              ),
              _ActionTile(
                icon: Icons.location_on_outlined,
                iconColor: Colors.teal.shade700,
                title: 'Track Delivery',
                subtitle: 'Live GPS delivery tracking',
                onTap: () => _trackDelivery(context),
              ),
            ],
            if (_canCancel)
              _ActionTile(
                icon: Icons.cancel_outlined,
                iconColor: colorScheme.error,
                title: 'Cancel Order',
                subtitle: 'Cancel order and retain audit history',
                isDestructive: true,
                onTap: () => _cancelOrder(context),
              ),
          ],
        ),
      ),
    );
  }

  void _viewOrder(BuildContext context) {
    Navigator.pop(context);
    final cloudSuffix = (_isCloud && cloudOrderId != null && cloudOrderId!.isNotEmpty)
        ? '&cloudOrderId=$cloudOrderId'
        : '';
    Navigator.pushNamed(
      parentContext,
      '/order-view?orderId=$orderId$cloudSuffix',
      arguments: {
        'orderId': orderId,
        'cloudOrderId': cloudOrderId,
      },
    );
  }

  Future<void> _editOrder(BuildContext context) async {
    Navigator.pop(context);
    if (!parentContext.mounted) return;
    final orderProvider = parentContext.read<OrderProvider>();

    if (_isCloud && cloudOrderId != null && cloudOrderId!.isNotEmpty) {
      await orderProvider.loadOrderDetailProgressive(
        orderId,
        cloudOrderId: cloudOrderId,
      );
      final currentHeader = orderProvider.detailHeader;
      final currentDetail = orderProvider.detailBundle;
      if (currentHeader == null || currentDetail == null || !parentContext.mounted) return;

      await Navigator.push<bool>(
        parentContext,
        MaterialPageRoute(
          builder: (_) => CloudOrderEditScreen(
            cloudOrderId: cloudOrderId!,
            header: currentHeader,
            detail: currentDetail,
          ),
        ),
      );
    } else {
      await orderProvider.loadOrderDetailProgressive(orderId);
      final currentHeader = orderProvider.detailHeader;
      final currentDetail = orderProvider.detailBundle;
      if (currentHeader == null || currentDetail == null || !parentContext.mounted) return;

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
        case FulfilmentType.eventSale:
          editor = EventSaleScreen(
            initialSession: session,
            editingOrderId: currentHeader.id,
          );
          break;
      }

      await Navigator.push(
        parentContext,
        MaterialPageRoute(builder: (_) => editor),
      );
    }

    if (parentContext.mounted) {
      onOrderUpdated?.call();
      await parentContext.read<OrderProvider>().loadOrdersForTab(
            parentContext.read<OrderProvider>().activeTab,
          );
    }
  }

  Future<void> _changeStatus(BuildContext context) async {
    Navigator.pop(context);
    final nextStatuses = OrderStatus.nextStatuses(_status, fulfilmentType: _fulfilmentType)
        .where((s) => s != OrderStatus.cancelled)
        .toList(growable: false);

    if (nextStatuses.isEmpty) {
      if (parentContext.mounted) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          const SnackBar(content: Text('No further status changes available.')),
        );
      }
      return;
    }

    if (!parentContext.mounted) return;
    final selected = await showDialog<String>(
      context: parentContext,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Change Order Status'),
        children: [
          for (final s in nextStatuses)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, s),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getStatusColor(s),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      OrderStatus.actionLabel(s, fulfilmentType: _fulfilmentType),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );

    if (selected == null || !parentContext.mounted) return;

    if (_fulfilmentType == 'event_sale' && selected == OrderStatus.delivered) {
      final canFulfill = await _preCheckEventFulfillmentStock();
      if (!canFulfill || !parentContext.mounted) return;
    }

    try {
      if (_isCloud && cloudOrderId != null && cloudOrderId!.isNotEmpty) {
        await parentContext.read<OrderProvider>().updateCloudOrderStatus(
              cloudOrderId: cloudOrderId!,
              newStatus: selected,
            );
      } else {
        await parentContext.read<OrderProvider>().updateOrderStatus(
              orderId: orderId,
              currentStatus: _status,
              newStatus: selected,
            );
      }

      if (parentContext.mounted) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          SnackBar(
            content: Text('Order status updated to ${OrderStatus.label(selected)}.'),
          ),
        );
        onOrderUpdated?.call();
      }
    } catch (e) {
      if (parentContext.mounted) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  Future<bool> _preCheckEventFulfillmentStock() async {
    if (_isCloud) {
      try {
        final cloudInventoryRepo = CloudInventoryRepository();
        final inventoryItems = await cloudInventoryRepo.listInventoryProducts();
        final stockByCloudId = <String, int>{};
        for (final item in inventoryItems) {
          if (item.cloudProductId != null && item.cloudProductId!.isNotEmpty) {
            stockByCloudId[item.cloudProductId!] = item.currentQty;
          }
        }

        final lines = detailBundle?.lines ?? const <Map<String, Object?>>[];
        final shortages = <Map<String, dynamic>>[];

        for (final line in lines) {
          final cloudProdId = line['cloud_product_id'] as String?;
          final qty = (line['qty'] as int?) ?? 0;
          final name = (line['product_name'] as String?) ?? (line['description'] as String?) ?? 'Product';
          if (cloudProdId == null || cloudProdId.isEmpty || qty <= 0) continue;

          final avail = stockByCloudId[cloudProdId] ?? 0;
          if (avail < qty) {
            shortages.add({
              'productName': name,
              'requiredQty': qty,
              'availableQty': avail,
              'shortageQty': qty - avail,
            });
          }
        }

        if (shortages.isNotEmpty) {
          if (!parentContext.mounted) return false;
          await _showFulfillmentShortageDialog(shortages);
          return false;
        }
      } catch (e) {
        debugPrint('[ActionMenu] Cloud stock pre-check warning: $e');
      }
      return true;
    }

    final shortages = await OrderRepository().checkEventFulfillmentStock(orderId);
    if (shortages.isNotEmpty) {
      if (!parentContext.mounted) return false;
      await _showFulfillmentShortageDialog(
        shortages.map((s) => {
          'productName': s.productName,
          'requiredQty': s.requiredQty,
          'availableQty': s.availableQty,
          'shortageQty': s.shortageQty,
        }).toList(),
      );
      return false;
    }
    return true;
  }

  Future<void> _showFulfillmentShortageDialog(List<Map<String, dynamic>> shortages) async {
    await showDialog<void>(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
            const SizedBox(width: 8),
            const Expanded(child: Text('Insufficient Physical Stock')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cannot fulfill event. Current physical stock is less than required for the following item(s):',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              ...shortages.map((s) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s['productName'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Required: ${s['requiredQty']}', style: const TextStyle(fontSize: 12)),
                        Text('In Stock: ${s['availableQty']}', style: const TextStyle(fontSize: 12)),
                        Text(
                          'Shortage: ${s['shortageQty']}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade800),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 8),
              const Text(
                'Please produce or procure the missing bouquets before marking the event as fulfilled.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.push(
                parentContext,
                MaterialPageRoute(builder: (_) => const BouquetProductionEntryScreen()),
              );
            },
            icon: const Icon(Icons.precision_manufacturing_outlined, size: 16),
            label: const Text('Open Bouquet Production'),
          ),
        ],
      ),
    );
  }

  Future<void> _collectOrAdjustPayment(BuildContext context) async {
    Navigator.pop(context);
    if (!parentContext.mounted) return;
    final provider = parentContext.read<OrderProvider>();

    if (_outstandingPaise > 0) {
      final amountController = TextEditingController(
        text: (_outstandingPaise / 100).toStringAsFixed(0),
      );
      String method = 'cash';
      final referenceController = TextEditingController();
      var isSaving = false;

      await showDialog<void>(
        context: parentContext,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setStateDialog) => AlertDialog(
              title: const Text('Collect Payment'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Outstanding: ${_formatPaise(_outstandingPaise)}'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: '₹ ',
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: method,
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'upi', child: Text('UPI')),
                      DropdownMenuItem(value: 'card', child: Text('Card')),
                      DropdownMenuItem(
                          value: 'bank_transfer', child: Text('Bank Transfer')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setStateDialog(() => method = value);
                    },
                    decoration: const InputDecoration(labelText: 'Method'),
                  ),
                  if (!_isCloud) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: referenceController,
                      decoration: const InputDecoration(
                        labelText: 'Reference (optional)',
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final amount =
                              _parseCurrencyToPaise(amountController.text);
                          if (amount <= 0) {
                            ScaffoldMessenger.of(parentContext).showSnackBar(
                              const SnackBar(
                                  content: Text('Enter a valid amount.')),
                            );
                            return;
                          }
                          if (amount > _outstandingPaise) {
                            ScaffoldMessenger.of(parentContext).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Amount cannot exceed outstanding.')),
                            );
                            return;
                          }

                          setStateDialog(() => isSaving = true);
                          try {
                            if (_isCloud &&
                                cloudOrderId != null &&
                                cloudOrderId!.isNotEmpty) {
                              await provider.collectCloudOrderPayment(
                                cloudOrderId: cloudOrderId!,
                                method: method,
                                amountPaise: amount,
                              );
                            } else {
                              await provider.collectOrderPayment(
                                orderId: orderId,
                                method: method,
                                amountPaise: amount,
                                reference: referenceController.text.trim().isEmpty
                                    ? null
                                    : referenceController.text.trim(),
                              );
                            }
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            if (parentContext.mounted) {
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Payment collected successfully.')),
                              );
                              onOrderUpdated?.call();
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              setStateDialog(() => isSaving = false);
                            }
                            if (parentContext.mounted) {
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Failed to collect payment: $e')),
                              );
                            }
                          }
                        },
                  child: const Text('Save'),
                ),
              ],
            ),
          );
        },
      );
    } else {
      await _showAdjustmentDialog(parentContext);
    }
  }

  Future<void> _showAdjustmentDialog(BuildContext context) async {
    final provider = parentContext.read<OrderProvider>();
    await provider.loadOrderDetailProgressive(orderId, cloudOrderId: cloudOrderId);
    final currentHeader = provider.detailHeader;
    final currentDetail = provider.detailBundle;
    if (currentHeader == null || !parentContext.mounted) return;

    final payments = currentDetail?.payments ?? const <Map<String, Object?>>[];
    final receivedPaise = payments.where((row) {
      final method = ((row['method'] as String?) ?? '').toLowerCase();
      return method != 'credit';
    }).fold<int>(0, (sum, row) => sum + ((row['amount_paise'] as int?) ?? 0));

    final refundedPaise = payments.where((row) {
      final amount = (row['amount_paise'] as int?) ?? 0;
      return amount < 0;
    }).fold<int>(0, (sum, row) => sum + (((row['amount_paise'] as int?) ?? 0).abs()));

    final suggestedPaise = (receivedPaise - refundedPaise).clamp(0, receivedPaise);
    String whatHappened = 'customer_cancelled';
    String action = 'refund_customer';
    String refundMethod = 'cash';
    final amountController = TextEditingController(
      text: (suggestedPaise / 100).toStringAsFixed(0),
    );
    final remarksController = TextEditingController();
    var isSaving = false;

    await showDialog<void>(
      context: parentContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setStateDialog) => AlertDialog(
          title: const Text('Adjust Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order Total: ${_formatPaise(currentHeader.grandTotalPaise)}'),
                Text('Received: ${_formatPaise(receivedPaise)}'),
                if (refundedPaise > 0)
                  Text('Already Refunded: ${_formatPaise(refundedPaise)}'),
                const SizedBox(height: 12),
                const Text('Adjustment Amount:'),
                TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    prefixText: '₹ ',
                    labelText: 'Amount',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: whatHappened,
                  items: const [
                    DropdownMenuItem(
                        value: 'customer_cancelled',
                        child: Text('Customer Cancelled')),
                    DropdownMenuItem(
                        value: 'order_modified', child: Text('Order Modified')),
                    DropdownMenuItem(
                        value: 'money_returned', child: Text('Money Returned')),
                    DropdownMenuItem(
                        value: 'wrong_entry', child: Text('Wrong Entry')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (v) => setStateDialog(() => whatHappened = v ?? whatHappened),
                  decoration: const InputDecoration(labelText: 'Reason'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: action,
                  items: const [
                    DropdownMenuItem(
                        value: 'refund_customer', child: Text('Refund Customer')),
                    DropdownMenuItem(
                        value: 'keep_as_advance', child: Text('Keep as Advance')),
                    DropdownMenuItem(
                        value: 'no_refund', child: Text('No Refund')),
                  ],
                  onChanged: (v) => setStateDialog(() => action = v ?? action),
                  decoration: const InputDecoration(labelText: 'Action'),
                ),
                if (action == 'refund_customer') ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: refundMethod,
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'upi', child: Text('UPI')),
                      DropdownMenuItem(
                          value: 'bank_transfer', child: Text('Bank Transfer')),
                      DropdownMenuItem(
                          value: 'credit_note', child: Text('Credit Note')),
                    ],
                    onChanged: (v) =>
                        setStateDialog(() => refundMethod = v ?? refundMethod),
                    decoration: const InputDecoration(labelText: 'Refund Mode'),
                  ),
                ],
                const SizedBox(height: 8),
                TextField(
                  controller: remarksController,
                  decoration: const InputDecoration(labelText: 'Remarks (optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final amount = _parseCurrencyToPaise(amountController.text);
                      if (amount <= 0) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(content: Text('Enter a valid amount.')),
                        );
                        return;
                      }

                      setStateDialog(() => isSaving = true);
                      try {
                        await provider.adjustOrderPayment(
                          orderId: orderId,
                          event: whatHappened,
                          resolution: action,
                          amountPaise: amount,
                          refundMethod: action == 'refund_customer'
                              ? refundMethod
                              : null,
                          remarks: remarksController.text.trim().isEmpty
                              ? null
                              : remarksController.text.trim(),
                        );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        if (parentContext.mounted) {
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            const SnackBar(
                                content: Text('Payment adjustment recorded.')),
                          );
                          onOrderUpdated?.call();
                        }
                      } catch (e) {
                        if (dialogContext.mounted) {
                          setStateDialog(() => isSaving = false);
                        }
                        if (parentContext.mounted) {
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            SnackBar(content: Text('Failed: $e')),
                          );
                        }
                      }
                    },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrintOptions(BuildContext context) {
    Navigator.pop(context);
    if (!parentContext.mounted) return;
    final workflowProvider = parentContext.read<OrderWorkflowProvider>();

    showModalBottomSheet<void>(
      context: parentContext,
      showDragHandle: true,
      builder: (printSheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Print $_displayOrderNo',
                style: Theme.of(printSheetContext).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text('Print Receipt / Bill'),
                onTap: () async {
                  Navigator.pop(printSheetContext);
                  await workflowProvider.printReceipt(orderId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined, color: Colors.indigo),
                title: const Text('Download Bill (PDF)'),
                onTap: () async {
                  Navigator.pop(printSheetContext);
                  await _generateAndDeliverBillPdf();
                },
              ),
              ListTile(
                leading: const Icon(Icons.local_shipping),
                title: const Text('Print Delivery Slip'),
                onTap: () async {
                  Navigator.pop(printSheetContext);
                  await workflowProvider.printDeliverySlip(orderId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined, color: Colors.teal),
                title: const Text('Download Delivery Slip (PDF)'),
                onTap: () async {
                  Navigator.pop(printSheetContext);
                  await _generateAndDeliverDeliverySlipPdf();
                },
              ),
              ListTile(
                leading: const Icon(Icons.card_giftcard),
                title: const Text('Print Message Card'),
                onTap: () async {
                  Navigator.pop(printSheetContext);
                  await workflowProvider.printMessageCard(orderId);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPdfOptions(BuildContext context) {
    Navigator.pop(context);
    if (!parentContext.mounted) return;

    showModalBottomSheet<void>(
      context: parentContext,
      showDragHandle: true,
      builder: (pdfSheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PDF Documents • $_displayOrderNo',
                style: Theme.of(pdfSheetContext).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.receipt_long, color: Colors.indigo),
                title: const Text('Download Bill (PDF)'),
                subtitle: const Text('A4 Tax Invoice with complete line items & payments'),
                onTap: () async {
                  Navigator.pop(pdfSheetContext);
                  await _generateAndDeliverBillPdf();
                },
              ),
              ListTile(
                leading: const Icon(Icons.local_shipping, color: Colors.teal),
                title: const Text('Download Delivery Slip (PDF)'),
                subtitle: const Text('A4 Delivery Challan with item checklist & address'),
                onTap: () async {
                  Navigator.pop(pdfSheetContext);
                  await _generateAndDeliverDeliverySlipPdf();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateAndDeliverBillPdf() async {
    final provider = parentContext.read<OrderProvider>();
    if (header == null || detailBundle == null) {
      await provider.loadOrderDetailProgressive(orderId, cloudOrderId: cloudOrderId);
    }
    final resolvedHeader = header ?? provider.detailHeader;
    final resolvedBundle = detailBundle ?? provider.detailBundle;
    if (resolvedHeader == null || !parentContext.mounted) return;

    await PdfDocumentService().downloadOrShareBillPdf(
      context: parentContext,
      header: resolvedHeader,
      bundle: resolvedBundle,
    );
  }

  Future<void> _generateAndDeliverDeliverySlipPdf() async {
    final provider = parentContext.read<OrderProvider>();
    if (header == null || detailBundle == null) {
      await provider.loadOrderDetailProgressive(orderId, cloudOrderId: cloudOrderId);
    }
    final resolvedHeader = header ?? provider.detailHeader;
    final resolvedBundle = detailBundle ?? provider.detailBundle;
    if (resolvedHeader == null || !parentContext.mounted) return;

    await PdfDocumentService().downloadOrShareDeliverySlipPdf(
      context: parentContext,
      header: resolvedHeader,
      bundle: resolvedBundle,
    );
  }

  Future<void> _shareWhatsApp(BuildContext context) async {
    Navigator.pop(context);
    final phone = _recipientPhone.isNotEmpty ? _recipientPhone : _customerPhone;

    if (phone.isEmpty) {
      if (!parentContext.mounted) return;
      final phoneController = TextEditingController();
      final enteredPhone = await showDialog<String>(
        context: parentContext,
        builder: (dContext) => AlertDialog(
          title: const Text('Enter WhatsApp Number'),
          content: TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: 'e.g. 9876543210',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dContext, phoneController.text.trim()),
              child: const Text('Open WhatsApp'),
            ),
          ],
        ),
      );
      if (enteredPhone == null || enteredPhone.isEmpty || !parentContext.mounted) return;
      await _openWhatsAppWithPhone(parentContext, enteredPhone);
      return;
    }

    if (!parentContext.mounted) return;
    await _openWhatsAppWithPhone(parentContext, phone);
  }

  Future<void> _openWhatsAppWithPhone(BuildContext context, String phone) async {
    final message = await OrderWhatsappService.buildMessage(
      OrderWhatsappService.orderStatusTemplate,
      orderId,
      _customerName,
      _status,
      _grandTotalPaise / 100.0,
      '',
      '',
    );
    if (!context.mounted) return;
    await _dispatchWhatsApp(
      context,
      phone: phone,
      message: message,
      failurePrefix: 'Could not open WhatsApp',
    );
  }

  Future<void> _dispatchWhatsApp(
    BuildContext context, {
    required String phone,
    required String message,
    String failurePrefix = 'Could not open WhatsApp',
  }) async {
    final normalized = WhatsAppPhoneUtils.normalize(phone);
    if (normalized == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(phone.trim().isEmpty
                ? '$failurePrefix: Driver phone number is missing.'
                : '$failurePrefix: Invalid phone number for WhatsApp ($phone).'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    final uri = WhatsAppPhoneUtils.buildUri(normalized, message: message);
    final fallback =
        WhatsAppPhoneUtils.buildFallbackUri(normalized, message: message);

    try {
      if (uri != null &&
          await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return;
      }
      if (fallback != null &&
          await launchUrl(fallback, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (e) {
      debugPrint('[OrderActionMenu] WhatsApp launch exception: $e');
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('$failurePrefix: Could not open WhatsApp on this device.'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _assignDesigner(BuildContext context) async {
    Navigator.pop(context);

    if (!parentContext.mounted) return;

    if (_isCloud && cloudOrderId != null && cloudOrderId!.isNotEmpty) {
      final provider = parentContext.read<OrderProvider>();
      List<CloudAssignee> designers;
      try {
        designers = await provider.loadCloudDesigners();
      } catch (e) {
        if (parentContext.mounted) {
          ScaffoldMessenger.of(parentContext).showSnackBar(
            SnackBar(content: Text('Failed to load designers: $e')),
          );
        }
        return;
      }

      if (designers.isEmpty) {
        if (parentContext.mounted) {
          ScaffoldMessenger.of(parentContext).showSnackBar(
            const SnackBar(content: Text('No designers available in Cloud.')),
          );
        }
        return;
      }

      if (!parentContext.mounted) return;
      final selected = await showDialog<CloudAssignee>(
        context: parentContext,
        builder: (dContext) => SimpleDialog(
          title: const Text('Select Designer / Florist'),
          children: [
            for (final d in designers)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dContext, d),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(d.name),
                  subtitle: d.phone != null ? Text(d.phone!) : null,
                ),
              ),
          ],
        ),
      );

      if (selected != null && parentContext.mounted) {
        try {
          await provider.assignCloudDesigner(
            cloudOrderId: cloudOrderId!,
            staffId: selected.staffId,
          );
          if (parentContext.mounted) {
            ScaffoldMessenger.of(parentContext).showSnackBar(
              SnackBar(content: Text('Designer assigned to ${selected.name}.')),
            );
            onOrderUpdated?.call();
          }
        } catch (e) {
          if (parentContext.mounted) {
            ScaffoldMessenger.of(parentContext).showSnackBar(
              SnackBar(content: Text('Failed to assign designer: $e')),
            );
          }
        }
      }
    } else {
      final staffRepo = StaffRepository();
      var designers = await staffRepo.searchStaff(
        roles: [StaffRole.designer],
        activeOnly: true,
      );
      if (designers.isEmpty) {
        designers = await staffRepo.searchStaff(activeOnly: true);
      }

      if (designers.isEmpty) {
        if (parentContext.mounted) {
          ScaffoldMessenger.of(parentContext).showSnackBar(
            const SnackBar(content: Text('No active staff found. Please add staff in Settings > Staff.')),
          );
        }
        return;
      }

      if (!parentContext.mounted) return;
      final selected = await showDialog<Staff>(
        context: parentContext,
        builder: (dContext) => SimpleDialog(
          title: const Text('Select Designer / Florist'),
          children: [
            for (final d in designers)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dContext, d),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(d.name),
                  subtitle: d.phone.isNotEmpty ? Text(d.phone) : null,
                ),
              ),
          ],
        ),
      );

      if (selected != null && parentContext.mounted) {
        try {
          final workflowProvider = parentContext.read<OrderWorkflowProvider>();
          await workflowProvider.sendToDesigner(
            orderId: orderId,
            designerId: selected.id,
            notes: 'Assigned to ${selected.name}',
          );
          if (parentContext.mounted) {
            ScaffoldMessenger.of(parentContext).showSnackBar(
              SnackBar(
                content: Text('Designer assigned to ${selected.name}.'),
              ),
            );
            onOrderUpdated?.call();
          }
        } catch (e) {
          if (parentContext.mounted) {
            ScaffoldMessenger.of(parentContext).showSnackBar(
              SnackBar(content: Text('Failed: $e')),
            );
          }
        }
      }
    }
  }

  Future<void> _assignDriver(BuildContext context) async {
    Navigator.pop(context);

    if (!parentContext.mounted) return;

    if (_isCloud && cloudOrderId != null && cloudOrderId!.isNotEmpty) {
      final provider = parentContext.read<OrderProvider>();
      List<CloudAssignee> drivers;
      try {
        drivers = await provider.loadCloudDrivers();
      } catch (e) {
        if (parentContext.mounted) {
          ScaffoldMessenger.of(parentContext).showSnackBar(
            SnackBar(content: Text('Failed to load drivers: $e')),
          );
        }
        return;
      }

      if (drivers.isEmpty) {
        if (parentContext.mounted) {
          ScaffoldMessenger.of(parentContext).showSnackBar(
            const SnackBar(content: Text('No drivers available in Cloud.')),
          );
        }
        return;
      }

      if (!parentContext.mounted) return;
      final selected = await showDialog<CloudAssignee>(
        context: parentContext,
        builder: (dContext) => SimpleDialog(
          title: const Text('Select Delivery Driver'),
          children: [
            for (final d in drivers)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dContext, d),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(d.name),
                  subtitle: d.phone != null ? Text(d.phone!) : null,
                ),
              ),
          ],
        ),
      );

      if (selected != null && parentContext.mounted) {
        try {
          await provider.assignCloudDriver(
            cloudOrderId: cloudOrderId!,
            staffId: selected.staffId,
          );
          if (parentContext.mounted) {
            ScaffoldMessenger.of(parentContext).showSnackBar(
              SnackBar(content: Text('Driver assigned to ${selected.name}.')),
            );
            onOrderUpdated?.call();
          }
        } catch (e) {
          if (parentContext.mounted) {
            ScaffoldMessenger.of(parentContext).showSnackBar(
              SnackBar(content: Text('Failed to assign driver: $e')),
            );
          }
          return;
        }

        if (!parentContext.mounted) return;

        final refreshedHeader = provider.detailHeader ?? header;
        final refreshedDetail = provider.detailBundle ?? detailBundle;
        final effectiveOrderNo =
            refreshedHeader?.orderNo ?? orderListItem?.orderNo ?? _displayOrderNo;

        String? startDeliveryLink;
        try {
          final deliveryService = DeliveryTrackingService();
          final deliveryId = await deliveryService.getCloudDeliveryId(
            cloudOrderId: cloudOrderId,
            orderNo: effectiveOrderNo,
          );
          if (deliveryId != null && deliveryId.trim().isNotEmpty) {
            final links =
                await deliveryService.generateTrackingLinks(deliveryId);
            final driverLink = links.driverLink.trim();
            if (driverLink.isNotEmpty) {
              startDeliveryLink = driverLink;
            }
          }
        } catch (error) {
          debugPrint(
            '[OrderActionMenu] Cloud tracking link generation failed after assignment: $error',
          );
          if (parentContext.mounted) {
            ScaffoldMessenger.of(parentContext).showSnackBar(
              SnackBar(
                content: Text(
                  'Driver assigned, but the WhatsApp delivery message could not be generated/sent: $error',
                ),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }

        if (!parentContext.mounted) return;

        final headerToUse = refreshedHeader ??
            OrderDetailHeader(
              id: orderId,
              cloudOrderId: cloudOrderId,
              orderNo: effectiveOrderNo,
              status: _status,
              customerName: _customerName,
              customerPhone: _customerPhone,
              recipientName: _recipientName,
              recipientPhone: _recipientPhone,
              fulfilmentType: _fulfilmentType,
              source: orderListItem?.source ?? 'manual',
              grandTotalPaise: _grandTotalPaise,
              address: header?.address ?? '',
              scheduledAt: header?.scheduledAt ?? orderListItem?.scheduledAt,
              occasion: header?.occasion ?? '',
              deliverySlot: header?.deliverySlot ?? '',
              cardMessage: header?.cardMessage ?? '',
              isPaid: _isPaid ? 1 : 0,
              paidAmountPaise: _isPaid ? _grandTotalPaise : 0,
            );

        final message = deliveryAssignmentMessage(
          headerToUse,
          refreshedDetail,
          selected.name,
          startDeliveryLink: startDeliveryLink,
        );

        await _dispatchWhatsApp(
          parentContext,
          phone: selected.phone ?? '',
          message: message,
          failurePrefix:
              'Driver assigned, but the WhatsApp delivery message could not be generated/sent',
        );
      }
    } else {
      final staffRepo = StaffRepository();
      var drivers = await staffRepo.searchStaff(
        roles: [StaffRole.delivery],
        activeOnly: true,
      );
      if (drivers.isEmpty) {
        drivers = await staffRepo.searchStaff(activeOnly: true);
      }

      if (drivers.isEmpty) {
        if (parentContext.mounted) {
          ScaffoldMessenger.of(parentContext).showSnackBar(
            const SnackBar(content: Text('No active delivery staff found. Please add staff in Settings > Staff.')),
          );
        }
        return;
      }

      if (!parentContext.mounted) return;
      final selected = await showDialog<Staff>(
        context: parentContext,
        builder: (dContext) => SimpleDialog(
          title: const Text('Select Delivery Person'),
          children: [
            for (final d in drivers)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dContext, d),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(d.name),
                  subtitle: d.phone.isNotEmpty ? Text(d.phone) : null,
                ),
              ),
          ],
        ),
      );

      if (selected != null && parentContext.mounted) {
        try {
          final workflowProvider = parentContext.read<OrderWorkflowProvider>();
          await workflowProvider.assignDeliveryPartner(
            orderId: orderId,
            deliveryPartnerId: selected.id,
            notes: 'Assigned to ${selected.name}',
            syncDeliveryInBackground: true,
          );
          if (parentContext.mounted) {
            ScaffoldMessenger.of(parentContext).showSnackBar(
              SnackBar(
                content: Text('Delivery assigned to ${selected.name}.'),
              ),
            );
            onOrderUpdated?.call();
          }
        } catch (e) {
          if (parentContext.mounted) {
            ScaffoldMessenger.of(parentContext).showSnackBar(
              SnackBar(content: Text('Failed to assign delivery: $e')),
            );
          }
          return;
        }

        if (!parentContext.mounted) return;

        final orderProvider = parentContext.read<OrderProvider>();
        try {
          await orderProvider.loadOrderDetailProgressive(orderId);
        } catch (_) {}

        final refreshedHeader = orderProvider.detailHeader ?? header;
        final refreshedDetail = orderProvider.detailBundle ?? detailBundle;
        final effectiveOrderNo =
            refreshedHeader?.orderNo ?? orderListItem?.orderNo ?? _displayOrderNo;

        String? startDeliveryLink;
        try {
          final deliveryService = DeliveryTrackingService();
          final deliveryId = await deliveryService.getCloudDeliveryId(
                cloudOrderId: refreshedHeader?.cloudOrderId ?? cloudOrderId,
                orderNo: effectiveOrderNo,
              ) ??
              (kIsWeb
                  ? null
                  : await deliveryService
                      .resolveOrCreateCloudDeliveryId(orderId));
          if (deliveryId != null && deliveryId.trim().isNotEmpty) {
            final links =
                await deliveryService.generateTrackingLinks(deliveryId);
            final driverLink = links.driverLink.trim();
            if (driverLink.isNotEmpty) {
              startDeliveryLink = driverLink;
            }
          }
        } catch (error) {
          debugPrint(
            '[OrderActionMenu] Solo tracking link generation failed after assignment: $error',
          );
          if (parentContext.mounted) {
            ScaffoldMessenger.of(parentContext).showSnackBar(
              SnackBar(
                content: Text(
                  'Driver assigned, but the WhatsApp delivery message could not be generated/sent: $error',
                ),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }

        if (!parentContext.mounted) return;

        final headerToUse = refreshedHeader ??
            OrderDetailHeader(
              id: orderId,
              cloudOrderId: cloudOrderId,
              orderNo: effectiveOrderNo,
              status: _status,
              customerName: _customerName,
              customerPhone: _customerPhone,
              recipientName: _recipientName,
              recipientPhone: _recipientPhone,
              fulfilmentType: _fulfilmentType,
              source: orderListItem?.source ?? 'manual',
              grandTotalPaise: _grandTotalPaise,
              address: header?.address ?? '',
              scheduledAt: header?.scheduledAt ?? orderListItem?.scheduledAt,
              occasion: header?.occasion ?? '',
              deliverySlot: header?.deliverySlot ?? '',
              cardMessage: header?.cardMessage ?? '',
              isPaid: _isPaid ? 1 : 0,
              paidAmountPaise: _isPaid ? _grandTotalPaise : 0,
            );

        final driverPhone = (selected.whatsapp?.trim().isNotEmpty == true)
            ? selected.whatsapp!.trim()
            : selected.phone.trim();

        final message = deliveryAssignmentMessage(
          headerToUse,
          refreshedDetail,
          selected.name,
          startDeliveryLink: startDeliveryLink,
        );

        await _dispatchWhatsApp(
          parentContext,
          phone: driverPhone,
          message: message,
          failurePrefix:
              'Driver assigned, but the WhatsApp delivery message could not be generated/sent',
        );
      }
    }
  }

  void _trackDelivery(BuildContext context) {
    Navigator.pop(context);
    if (!parentContext.mounted) return;
    Navigator.push(
      parentContext,
      MaterialPageRoute(
        builder: (_) => LiveDeliveryTrackingScreen(
          cloudOrderId: _isCloud ? cloudOrderId : null,
          orderId: _isCloud ? null : orderId,
        ),
      ),
    );
  }

  Future<void> _cancelOrder(BuildContext context) async {
    Navigator.pop(context);

    if (!parentContext.mounted) return;
    final confirmed = await showDialog<bool>(
      context: parentContext,
      builder: (dContext) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Text(
          'Are you sure you want to cancel $_displayOrderNo? The order will be cancelled and retained for audit history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dContext, false),
            child: const Text('Keep Order'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dContext, true),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );

    if (confirmed != true || !parentContext.mounted) return;

    try {
      if (_isCloud && cloudOrderId != null && cloudOrderId!.isNotEmpty) {
        await parentContext.read<OrderProvider>().cancelCloudOrder(
              cloudOrderId: cloudOrderId!,
              reason: 'Cancelled from Order Action Menu',
            );
      } else {
        await parentContext.read<OrderWorkflowProvider>().cancelOrder(
              orderId: orderId,
              currentStatus: _status,
              reason: 'Cancelled from Order Action Menu',
            );
      }

      if (parentContext.mounted) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          const SnackBar(content: Text('Order cancelled successfully.')),
        );
        onOrderUpdated?.call();
      }
    } catch (e) {
      if (parentContext.mounted) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          SnackBar(content: Text('Failed to cancel order: $e')),
        );
      }
    }
  }

  FulfilmentType _parseFulfilmentType(String value) {
    return switch (value.toLowerCase()) {
      'take_away' || 'takeaway' => FulfilmentType.takeAway,
      'pickup_later' || 'pickup' => FulfilmentType.pickupLater,
      'event_sale' || 'event' => FulfilmentType.eventSale,
      _ => FulfilmentType.delivery,
    };
  }

  WalkInSession _buildEditSession(
    OrderDetailHeader header,
    OrderDetailBundle detail,
  ) {
    final lines = detail.lines
        .map(
          (line) {
            final imageRef = (line['design_ref'] ??
                    line['designRef'] ??
                    line['order_reference_image_path'] ??
                    line['reference_image_path'] ??
                    line['attachment_path'] ??
                    line['attachmentPath'] ??
                    line['product_image_path'] ??
                    line['image_url'] ??
                    line['imageUrl'])
                ?.toString();
            final rawDescription = (line['description'] as String?)?.trim();
            final rawProductName = (line['product_name'] as String?)?.trim();
            final desc = (rawDescription != null && rawDescription.isNotEmpty)
                ? rawDescription
                : (rawProductName != null && rawProductName.isNotEmpty
                    ? rawProductName
                    : 'Item');
            return WalkInLineItem(
              productId: line['product_id'] as int?,
              cloudProductId: line['cloud_product_id']?.toString(),
              designRef: imageRef?.isNotEmpty == true ? imageRef : null,
              description: desc,
              quantity: (line['qty'] as int?) ?? 1,
              unitPricePaise: (line['unit_price_paise'] as int?) ?? 0,
              discountPaise: (line['discount_paise'] as int?) ?? 0,
              discountType: line['discount_type'] as String?,
              discountValue: line['discount_value'] as int?,
              gstPercent: (line['gst_percent'] as int?) ?? 0,
              source: (line['source'] as String?) ?? 'manual',
            );
          },
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
      specialInstructions: header.specialInstructions,
      payments: payments,
      billDiscountType: null,
      billDiscountValue: null,
    );
  }

  int _parseCurrencyToPaise(String? value) {
    if (value == null || value.trim().isEmpty) return 0;
    final normalized = value.replaceAll('₹', '').replaceAll(',', '').trim();
    final parsed = double.tryParse(normalized) ?? 0;
    return (parsed * 100).round();
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

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: isDestructive ? Theme.of(context).colorScheme.error : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDestructive
              ? Theme.of(context).colorScheme.error.withValues(alpha: 0.8)
              : Colors.grey.shade600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }
}
