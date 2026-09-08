import 'dart:async';

import 'package:flutter/foundation.dart';
import '../data/repositories/cloud_dashboard_repository.dart';
import '../managers/dashboard_manager.dart';
import '../models/dashboard_summary.dart';
import '../providers/storage_mode_provider.dart';
import '../services/business_data_event_bus.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider(
    this._dashboardManager,
    this._businessDataEvents,
    this._storageModeProvider, [
    CloudDashboardRepository? cloudDashboardRepository,
  ])  : _cloudDashboardRepository =
            cloudDashboardRepository ?? CloudDashboardRepository() {
    _businessDataEvents.addListener(_handleBusinessDataChanged);
  }

  final DashboardManager _dashboardManager;
  final BusinessDataEventBus _businessDataEvents;
  final StorageModeProvider _storageModeProvider;
  final CloudDashboardRepository _cloudDashboardRepository;

  DashboardSummary _summary = DashboardSummary.empty();
  bool _isLoading = false;
  String? _error;
  int _refreshVersion = 0;

  DashboardSummary get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSummary({bool showLoading = true}) async {
    final refreshVersion = ++_refreshVersion;
    Timer? loadingTimer;
    _error = null;

    if (showLoading) {
      loadingTimer = Timer(const Duration(milliseconds: 300), () {
        if (refreshVersion != _refreshVersion || _isLoading) return;
        _isLoading = true;
        notifyListeners();
      });
    }

    try {
      final summary = _storageModeProvider.isCloud
          ? await _loadCloudSummary()
          : await _dashboardManager.getTodaySummary();
      if (refreshVersion != _refreshVersion) return;
      _summary = summary;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (refreshVersion != _refreshVersion) return;
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    } finally {
      loadingTimer?.cancel();
    }
  }

  Future<void> refresh({bool showLoading = false}) async {
    await loadSummary(showLoading: showLoading);
  }

  Future<DashboardSummary> _loadCloudSummary() async {
    final today = DateTime.now();
    final summary = await _cloudDashboardRepository.getSummary(
      fromDate: today,
      toDate: today,
    );
    if (summary != null) {
      return DashboardSummary(
        todaySalesAmount: summary.totalSalesPaise,
        todayOrderCount: summary.orderCount,
        pendingOrders: summary.pendingOrderCount,
        preparingOrders: summary.preparingOrderCount,
        readyOrders: summary.readyOrderCount,
        outForDeliveryOrders: summary.outForDeliveryCount,
        todayDeliveryCount: summary.deliveryCount,
        todayPickupCount: summary.pickupCount,
        todayTaskCount: 0,
        lowStockItems: 0,
        outOfStockItems: 0,
        todayBirthdays: 0,
        todayFollowUps: 0,
        todayFestivalCount: 0,
        todayPendingPayments: summary.pendingOrderCount,
        todayPurchaseListCount: 0,
        activeAssociates: 0,
        activeStaff: 0,
        unmarkedAttendanceCount: 0,
        todayExpenses: summary.expensePaise,
        lowStockList: const [],
        todaySchedule: const [],
      );
    }

    return _dashboardManager.getTodaySummary();
  }

  void _handleBusinessDataChanged() {
    unawaited(refresh());
  }

  @override
  void dispose() {
    _businessDataEvents.removeListener(_handleBusinessDataChanged);
    super.dispose();
  }
}
