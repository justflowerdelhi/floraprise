import 'package:flutter/foundation.dart';

import '../data/repositories/cloud_order_repository.dart';
import '../managers/order_manager.dart';
import '../models/order_workspace_models.dart';
import 'storage_mode_provider.dart';

class OrderProvider extends ChangeNotifier {
  OrderProvider(
    this._orderManager, [
    this._storageModeProvider,
    CloudOrderRepository? cloudOrderRepository,
  ]) : _cloudOrderRepository = cloudOrderRepository ?? CloudOrderRepository();

  final OrderManager _orderManager;
  final StorageModeProvider? _storageModeProvider;
  final CloudOrderRepository _cloudOrderRepository;

  String _activeTab = 'pending';
  String _searchQuery = '';
  OrderWorkspaceFilters _filters = OrderWorkspaceFilters.empty;
  List<OrderListItem> _orders = const [];
  List<OrderListItem> _history = const [];
  bool _isLoading = false;
  String? _error;

  OrderDetailHeader? _detailHeader;
  OrderDetailBundle? _detailBundle;
  bool _isDetailLoading = false;

  String get activeTab => _activeTab;
  String get searchQuery => _searchQuery;
  OrderWorkspaceFilters get filters => _filters;
  List<OrderListItem> get orders => _orders;
  List<OrderListItem> get history => _history;
  bool get isLoading => _isLoading;
  String? get error => _error;
  OrderDetailHeader? get detailHeader => _detailHeader;
  OrderDetailBundle? get detailBundle => _detailBundle;
  bool get isDetailLoading => _isDetailLoading;
  bool get _isCloud => _storageModeProvider?.isCloud == true;

  Future<void> loadTodayOrders() async {
    _filters = const OrderWorkspaceFilters(today: true);
    await loadOrdersForTab(_activeTab);
  }

  Future<void> setSelectedDate(DateTime? date) async {
    _filters = _filters.copyWith(
      selectedDate: date,
      today: false,
      clearSelectedDate: date == null,
    );
    await loadOrdersForTab(_activeTab);
  }

  Future<void> loadOrdersForTab(String tab) async {
    _activeTab = tab;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _orders = _isCloud
          ? await _cloudOrderRepository.getWorkspace(
              tab: tab,
              searchQuery: _searchQuery,
              filters: _filters,
            )
          : await _orderManager.getOrdersForWorkspace(
              tab: tab,
              searchQuery: _searchQuery,
              filters: _filters,
            );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setSearchQuery(String query) async {
    _searchQuery = query.trim();
    await loadOrdersForTab(_activeTab);
  }

  Future<void> applyFilters(OrderWorkspaceFilters filters) async {
    _filters = filters;
    await loadOrdersForTab(_activeTab);
  }

  Future<void> clearDateFilter() async {
    _filters = _filters.copyWith(clearSelectedDate: true, today: false);
    await loadOrdersForTab(_activeTab);
  }

  Future<void> loadHistory({int limit = 100, int offset = 0}) async {
    _history = _isCloud
        ? await _cloudOrderRepository.getWorkspace(
            tab: 'all',
            searchQuery: '',
            filters: OrderWorkspaceFilters.empty,
            limit: limit,
            offset: offset,
          )
        : await _orderManager.getHistory(limit: limit, offset: offset);
    notifyListeners();
  }

  Future<void> loadOrderDetailProgressive(
    int orderId, {
    String? cloudOrderId,
  }) async {
    _isDetailLoading = true;
    _detailBundle = null;
    _error = null;
    notifyListeners();

    try {
      if (_isCloud) {
        final detail = cloudOrderId?.trim().isNotEmpty == true
            ? await _cloudOrderRepository.getDetail(cloudOrderId!.trim())
            : null;
        _detailBundle = detail;
        _detailHeader = detail?.header;
      } else {
        _detailHeader = await _orderManager.getOrderDetailHeader(orderId);
        notifyListeners();
        _detailBundle = await _orderManager.getOrderDetailBundle(orderId);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isDetailLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateOrderStatus({
    required int orderId,
    required String currentStatus,
    required String newStatus,
    String? notes,
  }) async {
    if (_isCloud) {
      throw StateError('Cloud order status updates are not implemented yet.');
    }
    await _orderManager.updateOrderStatus(
      orderId: orderId,
      currentStatus: currentStatus,
      newStatus: newStatus,
      notes: notes,
    );

    await loadOrdersForTab(_activeTab);
    if (_detailHeader?.id == orderId) {
      await loadOrderDetailProgressive(orderId);
    }
  }

  Future<void> updateCloudOrderStatus({
    required String cloudOrderId,
    required String newStatus,
  }) async {
    if (!_isCloud) {
      throw StateError('Cloud order status updates require Cloud mode.');
    }
    await _cloudOrderRepository.updateStatus(
      cloudOrderId: cloudOrderId,
      status: newStatus,
    );
    await loadOrderDetailProgressive(-1, cloudOrderId: cloudOrderId);
    await loadOrdersForTab(_activeTab);
  }

  Future<List<CloudAssignee>> loadCloudDesigners() {
    if (!_isCloud) {
      throw StateError('Cloud designer lookup requires Cloud mode.');
    }
    return _cloudOrderRepository.getDesigners();
  }

  Future<List<CloudAssignee>> loadCloudDrivers() {
    if (!_isCloud) {
      throw StateError('Cloud driver lookup requires Cloud mode.');
    }
    return _cloudOrderRepository.getDrivers();
  }

  Future<void> assignCloudDesigner({
    required String cloudOrderId,
    required String staffId,
  }) async {
    if (!_isCloud) {
      throw StateError('Cloud designer assignment requires Cloud mode.');
    }
    await _cloudOrderRepository.assignDesigner(
      cloudOrderId: cloudOrderId,
      staffId: staffId,
    );
    await loadOrderDetailProgressive(-1, cloudOrderId: cloudOrderId);
  }

  Future<void> assignCloudDriver({
    required String cloudOrderId,
    required String staffId,
  }) async {
    if (!_isCloud) {
      throw StateError('Cloud delivery assignment requires Cloud mode.');
    }
    await _cloudOrderRepository.assignDriver(
      cloudOrderId: cloudOrderId,
      staffId: staffId,
    );
    await loadOrderDetailProgressive(-1, cloudOrderId: cloudOrderId);
  }

  /// Saves a Cloud order edit. Only the supplied sections are sent; the local
  /// SQLite update path is never used.
  Future<void> saveCloudOrderEdit({
    required String cloudOrderId,
    DateTime? deliveryDate,
    String? timeSlot,
    String? deliveryAddress,
    String? deliveryPincode,
    String? recipientName,
    String? recipientPhone,
    String? cardMessage,
    List<CloudOrderItemInput>? items,
    int? discountAmountPaise,
    int? deliveryFeePaise,
    int? rewardPointsRedeemed,
    int? rewardDiscountAmountPaise,
  }) async {
    if (!_isCloud) {
      throw StateError('Cloud order editing requires Cloud mode.');
    }

    await _cloudOrderRepository.updateDetails(
      cloudOrderId: cloudOrderId,
      deliveryDate: deliveryDate,
      timeSlot: timeSlot,
      deliveryAddress: deliveryAddress,
      deliveryPincode: deliveryPincode,
      recipientName: recipientName,
      recipientPhone: recipientPhone,
      cardMessage: cardMessage,
    );

    if (items != null) {
      await _cloudOrderRepository.replaceItems(
        cloudOrderId: cloudOrderId,
        items: items,
      );
    }

    await _cloudOrderRepository.updateFinancials(
      cloudOrderId: cloudOrderId,
      discountAmountPaise: discountAmountPaise,
      deliveryFeePaise: deliveryFeePaise,
      rewardPointsRedeemed: rewardPointsRedeemed,
      rewardDiscountAmountPaise: rewardDiscountAmountPaise,
    );

    await loadOrderDetailProgressive(-1, cloudOrderId: cloudOrderId);
    await loadOrdersForTab(_activeTab);
  }

  Future<void> collectCloudOrderPayment({
    required String cloudOrderId,
    required String method,
    required int amountPaise,
  }) async {
    if (!_isCloud) {
      throw StateError('Cloud payment collection requires Cloud mode.');
    }
    await _cloudOrderRepository.collectPayment(
      cloudOrderId: cloudOrderId,
      method: method,
      amountPaise: amountPaise,
    );
    await loadOrderDetailProgressive(-1, cloudOrderId: cloudOrderId);
  }

  Future<void> cancelCloudOrder({
    required String cloudOrderId,
    String? reason,
  }) async {
    if (!_isCloud) {
      throw StateError('Cloud order cancellation requires Cloud mode.');
    }
    await _cloudOrderRepository.cancel(
      cloudOrderId: cloudOrderId,
      reason: reason,
    );
    await loadOrderDetailProgressive(-1, cloudOrderId: cloudOrderId);
    await loadOrdersForTab(_activeTab);
  }

  Future<void> collectOrderPayment({
    required int orderId,
    required String method,
    required int amountPaise,
    String? reference,
  }) async {
    if (_isCloud) {
      throw StateError('Cloud order payment collection is not implemented yet.');
    }
    await _orderManager.collectOrderPayment(
      orderId: orderId,
      method: method,
      amountPaise: amountPaise,
      reference: reference,
    );

    await loadOrdersForTab(_activeTab);
    if (_detailHeader?.id == orderId) {
      await loadOrderDetailProgressive(orderId);
    }
  }

  Future<void> adjustOrderPayment({
    required int orderId,
    required String event,
    required String resolution,
    required int amountPaise,
    String? refundMethod,
    String? remarks,
  }) async {
    if (_isCloud) {
      throw StateError('Cloud order payment adjustments are not implemented yet.');
    }
    await _orderManager.adjustOrderPayment(
      orderId: orderId,
      event: event,
      resolution: resolution,
      amountPaise: amountPaise,
      refundMethod: refundMethod,
      remarks: remarks,
    );

    await loadOrdersForTab(_activeTab);
    if (_detailHeader?.id == orderId) {
      await loadOrderDetailProgressive(orderId);
    }
  }
}
