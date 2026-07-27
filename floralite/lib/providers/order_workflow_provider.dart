import 'package:flutter/foundation.dart';

import '../data/repositories/associate_repository.dart';
import '../managers/order_workflow_manager.dart';
import '../models/order_status.dart';

/// Provider for the Order Workflow screen.
///
/// It re-uses [OrderWorkflowManager] and exposes the current workflow state,
/// pending actions and loading state.
class OrderWorkflowProvider extends ChangeNotifier {
  OrderWorkflowProvider(this._manager);

  final OrderWorkflowManager _manager;

  OrderWorkflowView? _workflow;
  bool _isLoading = false;
  String? _error;
  String? _statusMessage;
  List<AssociateRecord> _associates = const [];
  bool _associatesLoading = false;

  OrderWorkflowView? get workflow => _workflow;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get statusMessage => _statusMessage;
  List<AssociateRecord> get associates => _associates;
  bool get associatesLoading => _associatesLoading;

  Future<void> loadAssignableAssociates() async {
    _associatesLoading = true;
    notifyListeners();
    try {
      _associates = await _manager.getAssignableAssociates();
    } catch (e) {
      _error = e.toString();
    } finally {
      _associatesLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadWorkflow(int orderId) async {
    _setLoading(true);
    try {
      _workflow = await _manager.loadWorkflowView(orderId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> advanceStatus({
    required int orderId,
    required String currentStatus,
    required String newStatus,
    String? notes,
  }) async {
    _setLoading(true);
    try {
      await _manager.advanceStatus(
        orderId: orderId,
        currentStatus: currentStatus,
        newStatus: newStatus,
        notes: notes,
      );
      _statusMessage = 'Order moved to ${OrderStatus.label(newStatus)}';
      await loadWorkflow(orderId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendToDesigner({
    required int orderId,
    required int designerId,
    String? notes,
  }) async {
    _setLoading(true);
    try {
      await _manager.sendToDesigner(
        orderId: orderId,
        designerId: designerId,
        notes: notes,
      );
      _statusMessage = 'Sent to designer';
      await loadWorkflow(orderId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> assignDeliveryPartner({
    required int orderId,
    required int deliveryPartnerId,
    String? notes,
  }) async {
    _setLoading(true);
    try {
      await _manager.assignDeliveryPartner(
        orderId: orderId,
        deliveryPartnerId: deliveryPartnerId,
        notes: notes,
      );
      _statusMessage = 'Delivery person assigned';
      await loadWorkflow(orderId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> startProduction({
    required int orderId,
    DateTime? scheduledAt,
    String? notes,
  }) async {
    _setLoading(true);
    try {
      await _manager.startProduction(
        orderId: orderId,
        scheduledAt: scheduledAt,
        notes: notes,
      );
      _statusMessage = 'Production started';
      await loadWorkflow(orderId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> markReady({
    required int orderId,
    int? deliveryPartnerId,
    String? notes,
  }) async {
    _setLoading(true);
    try {
      await _manager.markReady(
        orderId: orderId,
        deliveryPartnerId: deliveryPartnerId,
        notes: notes,
      );
      _statusMessage = 'Order is ready';
      await loadWorkflow(orderId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> outForDelivery({
    required int orderId,
    int? deliveryPartnerId,
    String? notes,
  }) async {
    _setLoading(true);
    try {
      await _manager.outForDelivery(
        orderId: orderId,
        deliveryPartnerId: deliveryPartnerId,
        notes: notes,
      );
      _statusMessage = 'Order out for delivery';
      await loadWorkflow(orderId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> markDelivered({
    required int orderId,
    String? notes,
  }) async {
    _setLoading(true);
    try {
      await _manager.markDelivered(orderId: orderId, notes: notes);
      _statusMessage = 'Order delivered';
      await loadWorkflow(orderId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> markDeliveryFailed({
    required int orderId,
    String? notes,
  }) async {
    _setLoading(true);
    try {
      await _manager.markDeliveryFailed(orderId: orderId, notes: notes);
      _statusMessage = 'Delivery failed recorded';
      await loadWorkflow(orderId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> assignRelayPartner({
    required int orderId,
    required int relayPartnerId,
    String? notes,
  }) async {
    _setLoading(true);
    try {
      await _manager.assignRelayPartner(
        orderId: orderId,
        relayPartnerId: relayPartnerId,
        notes: notes,
      );
      _statusMessage = 'Relay partner assigned';
      await loadWorkflow(orderId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> cancelOrder({
    required int orderId,
    required String currentStatus,
    String? reason,
  }) async {
    _setLoading(true);
    try {
      await _manager.cancelOrder(
        orderId: orderId,
        currentStatus: currentStatus,
        reason: reason,
      );
      _statusMessage = 'Order cancelled';
      await loadWorkflow(orderId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addNote({
    required int orderId,
    required String note,
  }) async {
    _setLoading(true);
    try {
      await _manager.addNote(orderId: orderId, note: note);
      _statusMessage = 'Note added';
      await loadWorkflow(orderId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> printReceipt(int orderId) async {
    _setLoading(true);
    try {
      await _manager.printReceipt(orderId);
      _statusMessage = 'Receipt print job queued';
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> printDeliverySlip(int orderId) async {
    _setLoading(true);
    try {
      await _manager.printDeliverySlip(orderId);
      _statusMessage = 'Delivery slip print job queued';
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> printMessageCard(int orderId) async {
    _setLoading(true);
    try {
      await _manager.printMessageCard(orderId);
      _statusMessage = 'Message card print job queued';
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> shareWhatsApp({
    required int orderId,
    required String template,
    required String phone,
    String? fallbackMessage,
  }) async {
    _setLoading(true);
    try {
      await _manager.sendWhatsAppUpdate(
        orderId: orderId,
        template: template,
        phone: phone,
        fallbackMessage: fallbackMessage,
      );
      _statusMessage = 'WhatsApp opened';
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void clearStatusMessage() {
    _statusMessage = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
