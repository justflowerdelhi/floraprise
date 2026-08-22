import 'package:flutter/foundation.dart';

import '../models/order_workspace_models.dart';
import '../models/walk_in_enums.dart';
import '../models/walk_in_line_item.dart';
import '../models/walk_in_session.dart';
import '../managers/walk_in_manager.dart';
import '../services/business_data_event_bus.dart';

class WalkInSessionProvider extends ChangeNotifier {
  WalkInSessionProvider(this._walkInManager, [this._businessDataEvents]);

  final WalkInManager _walkInManager;
  final BusinessDataEventBus? _businessDataEvents;

  WalkInSession _session = WalkInSession.empty(FulfilmentType.takeAway);
  bool _isBusy = false;
  String? _error;

  WalkInSession get session => _session;
  bool get isBusy => _isBusy;
  String? get error => _error;

  int get grandTotalPaise => _walkInManager.currentGrandTotal(_session);

  Future<void> initialize(FulfilmentType type) async {
    _isBusy = true;
    _error = null;
    notifyListeners();
    try {
      _session = await _walkInManager.startOrResume(type);
    } catch (e) {
      _error = e.toString();
      _session = WalkInSession.empty(type);
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> initializeDraft(int draftOrderId) async {
    _isBusy = true;
    _error = null;
    notifyListeners();
    try {
      final draft = await _walkInManager.loadDraft(draftOrderId);
      if (draft == null) {
        throw StateError('Draft order not found.');
      }
      _session = draft;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> initializeWithCustomer(
    FulfilmentType type, {
    required int customerId,
    required String customerName,
    required String customerPhone,
    String recipientName = '',
    String occasion = '',
  }) async {
    _isBusy = true;
    _error = null;
    notifyListeners();
    try {
      _session = WalkInSession.empty(type);
      _session = _session.copyWith(
        customerPhone: customerPhone,
        customerName: customerName,
        recipientName: recipientName,
        occasion: occasion,
      );
    } catch (e) {
      _error = e.toString();
      _session = WalkInSession.empty(type);
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  void patchSession(WalkInSession next) {
    _session = next;
    notifyListeners();
  }

  void setLines(List<WalkInLineItem> lines) {
    _session = _walkInManager.withLines(_session, lines);
    notifyListeners();
  }

  Future<String?> lookupCustomerName(String phone) async {
    try {
      return await _walkInManager.lookupCustomerName(phone);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> lookupCustomerStatistics(String phone) async {
    try {
      return await _walkInManager.lookupCustomerStatistics(phone);
    } catch (_) {
      return null;
    }
  }

  Future<WalkInSession> applyMaximumRewards() async {
    _session = await _walkInManager.applyMaximumRewards(_session);
    notifyListeners();
    return _session;
  }

  Future<OrderRewardSummary?> getOrderRewardSummary(int orderId) {
    return _walkInManager.getOrderRewardSummary(orderId);
  }

  void setSinglePayment(PaymentMethod method) {
    final total = _walkInManager.currentGrandTotal(_session);
    _session = _walkInManager.withSinglePayment(_session, method, total);
    notifyListeners();
  }

  Future<void> saveDraft() async {
    _isBusy = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _walkInManager.saveDraft(_session);
      _session = result.session;
      _businessDataEvents?.publish(source: BusinessDataChangeSource.sale);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<bool> updateExistingOrder(int orderId) async {
    _isBusy = true;
    _error = null;
    notifyListeners();
    try {
      await _walkInManager.updateExistingOrder(
        orderId: orderId,
        session: _session,
      );
      _businessDataEvents?.publish(source: BusinessDataChangeSource.sale);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<int?> confirmOrder() async {
    _isBusy = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _walkInManager.confirmOrder(_session);
      _session = WalkInSession.empty(_session.fulfilmentType);
      _businessDataEvents?.publish(source: BusinessDataChangeSource.sale);
      return result.orderId;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }
}
