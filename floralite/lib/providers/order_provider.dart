import 'package:flutter/foundation.dart';

import '../managers/order_manager.dart';
import '../models/order_workspace_models.dart';

class OrderProvider extends ChangeNotifier {
  OrderProvider(this._orderManager);

  final OrderManager _orderManager;

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
      _orders = await _orderManager.getOrdersForWorkspace(
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
    _history = await _orderManager.getHistory(limit: limit, offset: offset);
    notifyListeners();
  }

  Future<void> loadOrderDetailProgressive(int orderId) async {
    _isDetailLoading = true;
    _detailBundle = null;
    _error = null;
    notifyListeners();

    try {
      _detailHeader = await _orderManager.getOrderDetailHeader(orderId);
      notifyListeners();
      _detailBundle = await _orderManager.getOrderDetailBundle(orderId);
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

  Future<void> collectOrderPayment({
    required int orderId,
    required String method,
    required int amountPaise,
    String? reference,
  }) async {
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
