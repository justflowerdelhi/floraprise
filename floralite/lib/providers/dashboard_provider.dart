import 'dart:async';

import 'package:flutter/foundation.dart';
import '../managers/dashboard_manager.dart';
import '../models/dashboard_summary.dart';
import '../services/business_data_event_bus.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this._dashboardManager, this._businessDataEvents) {
    _businessDataEvents.addListener(_handleBusinessDataChanged);
  }

  final DashboardManager _dashboardManager;
  final BusinessDataEventBus _businessDataEvents;

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
      final summary = await _dashboardManager.getTodaySummary();
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

  void _handleBusinessDataChanged() {
    unawaited(refresh());
  }

  @override
  void dispose() {
    _businessDataEvents.removeListener(_handleBusinessDataChanged);
    super.dispose();
  }
}
