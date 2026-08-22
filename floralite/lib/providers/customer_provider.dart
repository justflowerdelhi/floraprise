import 'package:flutter/foundation.dart';
import '../managers/customer_manager.dart';
import '../services/business_data_event_bus.dart';

class CustomerProvider extends ChangeNotifier {
  CustomerProvider(this._customerManager, [this._businessDataEvents]);

  final CustomerManager _customerManager;
  final BusinessDataEventBus? _businessDataEvents;

  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _filterPendingPayment = 'all'; // 'all', 'yes', 'no'
  String _filterTotalOrders = 'all'; // 'all', '1-5', '5-10', '10+'

  List<Map<String, dynamic>> get customers => _filteredCustomers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get pendingPaymentFilter => _filterPendingPayment;
  String get totalOrdersFilter => _filterTotalOrders;

  List<Map<String, dynamic>> get _filteredCustomers {
    var filtered = _customers;

    // Apply search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((customer) {
        final name = customer['name'] as String;
        final phone = customer['phone'] as String;
        return name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            phone.contains(_searchQuery);
      }).toList();
    }

    // Apply pending payment filter
    if (_filterPendingPayment == 'yes') {
      filtered = filtered
          .where((c) => (c['pendingPaymentPaise'] as int? ?? 0) > 0)
          .toList();
    } else if (_filterPendingPayment == 'no') {
      filtered = filtered
          .where((c) => (c['pendingPaymentPaise'] as int? ?? 0) == 0)
          .toList();
    }

    // Apply total orders filter
    if (_filterTotalOrders == '1-5') {
      filtered = filtered.where((c) {
        final orders = c['totalOrders'] as int;
        return orders >= 1 && orders <= 5;
      }).toList();
    } else if (_filterTotalOrders == '5-10') {
      filtered = filtered.where((c) {
        final orders = c['totalOrders'] as int;
        return orders > 5 && orders <= 10;
      }).toList();
    } else if (_filterTotalOrders == '10+') {
      filtered = filtered.where((c) {
        final orders = c['totalOrders'] as int;
        return orders > 10;
      }).toList();
    }

    return filtered;
  }

  String _formatPaise(int paise) {
    return '₹${(paise / 100).toStringAsFixed(0)}';
  }

  String _formatLastOrder(String? isoString) {
    if (isoString == null || isoString.isEmpty) {
      return '-';
    }

    final dt = DateTime.tryParse(isoString);
    if (dt == null) {
      return '-';
    }
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return '$day/$month/${dt.year}';
  }

  String _formatMonthDay(String value) {
    final parts = value.split('-');
    if (parts.length != 2) return '-';
    final month = int.tryParse(parts[0]);
    final day = int.tryParse(parts[1]);
    if (month == null || day == null) return '-';
    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}';
  }

  Future<void> loadCustomers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final customerRecords = await _customerManager.getAllCustomers();
      _customers = customerRecords
          .map(
            (record) => {
              'id': record.id,
              'name': record.name,
              'phone': record.phone,
              'createdAt': record.createdAt,
              'lastOrder': _formatLastOrder(record.lastOrderAt),
              'birthday': _formatMonthDay(record.birthdayMd),
              'birthdayMd': record.birthdayMd,
              'anniversaryMd': record.anniversaryMd,
              'company': record.company,
              'department': record.department,
              'notes': record.notes,
              'pendingPaymentPaise': record.pendingPaymentPaise,
              'pendingPayment': _formatPaise(record.pendingPaymentPaise),
              'totalOrders': record.totalOrders,
              'rewardPoints': record.rewardPoints,
              'lifetimeRewardPoints': record.lifetimeRewardPoints,
              'redeemedRewardPoints': record.redeemedRewardPoints,
              'lastRewardActivity': _formatLastOrder(record.lastRewardActivity),
            },
          )
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setPendingPaymentFilter(String value) {
    _filterPendingPayment = value;
    notifyListeners();
  }

  void setTotalOrdersFilter(String value) {
    _filterTotalOrders = value;
    notifyListeners();
  }

  void clearFilters() {
    _filterPendingPayment = 'all';
    _filterTotalOrders = 'all';
    notifyListeners();
  }

  Future<void> refresh() async {
    await loadCustomers();
  }

  Future<bool> addCustomer({
    required String phone,
    required String name,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final existing = await _customerManager.lookupByPhone(phone);
      if (existing != null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final customer = await _customerManager.ensureCustomer(
        phone: phone,
        name: name,
      );

      if (customer != null) {
        await loadCustomers();
        _businessDataEvents?.publish(source: BusinessDataChangeSource.customer);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = 'Failed to create customer';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCustomer({
    required int id,
    required String phone,
    required String name,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final existing = _customers.cast<Map<String, dynamic>>().firstWhere(
            (row) => row['id'] == id,
            orElse: () => const <String, dynamic>{},
          );

      await _customerManager.updateCustomer(
        id: id,
        phone: phone,
        name: name,
        birthdayMd: (existing['birthdayMd'] as String?) ?? '',
        anniversaryMd: (existing['anniversaryMd'] as String?) ?? '',
        company: (existing['company'] as String?) ?? '',
        department: (existing['department'] as String?) ?? '',
        notes: (existing['notes'] as String?) ?? '',
      );

      await loadCustomers();
      _businessDataEvents?.publish(source: BusinessDataChangeSource.customer);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCustomer(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _customerManager.deleteCustomer(id);

      await loadCustomers();
      _businessDataEvents?.publish(source: BusinessDataChangeSource.customer);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
