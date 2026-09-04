import 'package:flutter/foundation.dart';
import '../managers/customer_manager.dart';
import '../services/business_data_event_bus.dart';
import 'storage_mode_provider.dart';
import '../data/repositories/cloud_customer_repository.dart';

class CustomerProvider extends ChangeNotifier {
  CustomerProvider(
    this._customerManager,
    this._storageModeProvider, [
    this._businessDataEvents,
  ]);

  final CustomerManager _customerManager;
  final StorageModeProvider _storageModeProvider;
  final BusinessDataEventBus? _businessDataEvents;
  final CloudCustomerRepository _cloudRepository =
      CloudCustomerRepository();

  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _filterPendingPayment = 'all';
  String _filterTotalOrders = 'all';

  List<Map<String, dynamic>> get customers => _filteredCustomers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get pendingPaymentFilter => _filterPendingPayment;
  String get totalOrdersFilter => _filterTotalOrders;

  bool get _cloud => _storageModeProvider.isCloud;

  List<Map<String, dynamic>> get _filteredCustomers {
    var filtered = _customers;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (c) =>
                (c['name'] as String? ?? '')
                    .toLowerCase()
                    .contains(q) ||
                (c['phone'] as String? ?? '').contains(_searchQuery),
          )
          .toList();
    }

    if (_filterPendingPayment == 'yes') {
      filtered = filtered
          .where(
            (c) => (c['pendingPaymentPaise'] as int? ?? 0) > 0,
          )
          .toList();
    }

    if (_filterPendingPayment == 'no') {
      filtered = filtered
          .where(
            (c) => (c['pendingPaymentPaise'] as int? ?? 0) == 0,
          )
          .toList();
    }

    if (_filterTotalOrders == '1-5') {
      filtered = filtered.where((c) {
        final n = c['totalOrders'] as int? ?? 0;
        return n >= 1 && n <= 5;
      }).toList();
    }

    if (_filterTotalOrders == '5-10') {
      filtered = filtered.where((c) {
        final n = c['totalOrders'] as int? ?? 0;
        return n > 5 && n <= 10;
      }).toList();
    }

    if (_filterTotalOrders == '10+') {
      filtered = filtered
          .where(
            (c) => (c['totalOrders'] as int? ?? 0) > 10,
          )
          .toList();
    }

    return filtered;
  }

  String _formatPaise(int p) =>
      '₹${(p / 100).toStringAsFixed(0)}';

  String _formatLastOrder(String? v) {
    if (v == null || v.isEmpty) return '-';

    final d = DateTime.tryParse(v);
    if (d == null) return '-';

    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  String _formatMonthDay(String v) {
    final p = v.split('-');
    if (p.length != 2) return '-';

    final m = int.tryParse(p[0]);
    final d = int.tryParse(p[1]);

    if (m == null || d == null) return '-';

    return '${d.toString().padLeft(2, '0')}/'
        '${m.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> _cloudMap(CloudCustomer c) => {
        'id': c.id,
        'name': c.name,
        'phone': c.phone ?? '',
        'email': c.email ?? '',
        'createdAt': '',
        'lastOrder': '-',
        'birthday': '-',
        'birthdayMd': '',
        'anniversaryMd': '',
        'company': '',
        'department': '',
        'notes': c.notes ?? '',
        'pendingPaymentPaise': 0,
        'pendingPayment': '₹0',
        'totalOrders': 0,
        'rewardPoints': 0,
        'lifetimeRewardPoints': 0,
        'redeemedRewardPoints': 0,
        'lastRewardActivity': '-',
        'isActive': true,
      };

  Future<void> loadCustomers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_cloud) {
        final rows = await _cloudRepository.getAll(
          query: _searchQuery,
        );
        _customers = rows.map(_cloudMap).toList();
      } else {
        final rows = await _customerManager.getAllCustomers();

        _customers = rows
            .map(
              (r) => {
                'id': r.id,
                'name': r.name,
                'phone': r.phone,
                'createdAt': r.createdAt,
                'lastOrder': _formatLastOrder(r.lastOrderAt),
                'birthday': _formatMonthDay(r.birthdayMd),
                'birthdayMd': r.birthdayMd,
                'anniversaryMd': r.anniversaryMd,
                'company': r.company,
                'department': r.department,
                'notes': r.notes,
                'pendingPaymentPaise': r.pendingPaymentPaise,
                'pendingPayment':
                    _formatPaise(r.pendingPaymentPaise),
                'totalOrders': r.totalOrders,
                'rewardPoints': r.rewardPoints,
                'lifetimeRewardPoints':
                    r.lifetimeRewardPoints,
                'redeemedRewardPoints':
                    r.redeemedRewardPoints,
                'lastRewardActivity':
                    _formatLastOrder(r.lastRewardActivity),
                'isActive': true,
              },
            )
            .toList();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String q) {
    _searchQuery = q;

    if (_cloud) {
      loadCustomers();
    } else {
      notifyListeners();
    }
  }

  void setPendingPaymentFilter(String v) {
    _filterPendingPayment = v;
    notifyListeners();
  }

  void setTotalOrdersFilter(String v) {
    _filterTotalOrders = v;
    notifyListeners();
  }

  void clearFilters() {
    _filterPendingPayment = 'all';
    _filterTotalOrders = 'all';
    notifyListeners();
  }

  Future<void> refresh() => loadCustomers();

  Future<bool> addCustomer({
    required String phone,
    required String name,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_cloud) {
        if (await _cloudRepository.findByPhone(phone) != null) {
          _error =
              'Phone number already exists for another customer';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        await _cloudRepository.create(
          phone: phone,
          name: name,
        );
      } else {
        if (await _customerManager.lookupByPhone(phone) != null) {
          _isLoading = false;
          notifyListeners();
          return false;
        }

        if (await _customerManager.ensureCustomer(
              phone: phone,
              name: name,
            ) ==
            null) {
          _error = 'Failed to create customer';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      await loadCustomers();

      _businessDataEvents?.publish(
        source: BusinessDataChangeSource.customer,
      );

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

  Future<bool> updateCustomer({
    required Object id,
    required String phone,
    required String name,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_cloud) {
        await _cloudRepository.update(
          id: id.toString(),
          phone: phone,
          name: name,
        );
      } else {
        final localId =
            id is int ? id : int.parse(id.toString());

        final existing = _customers.firstWhere(
          (r) => r['id'] == localId,
          orElse: () => const <String, dynamic>{},
        );

        await _customerManager.updateCustomer(
          id: localId,
          phone: phone,
          name: name,
          birthdayMd:
              existing['birthdayMd'] as String? ?? '',
          anniversaryMd:
              existing['anniversaryMd'] as String? ?? '',
          company: existing['company'] as String? ?? '',
          department:
              existing['department'] as String? ?? '',
          notes: existing['notes'] as String? ?? '',
        );
      }

      await loadCustomers();

      _businessDataEvents?.publish(
        source: BusinessDataChangeSource.customer,
      );

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

  Future<bool> deleteCustomer(Object id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_cloud) {
        await _cloudRepository.deactivate(id.toString());
      } else {
        await _customerManager.deleteCustomer(
          id is int ? id : int.parse(id.toString()),
        );
      }

      await loadCustomers();

      _businessDataEvents?.publish(
        source: BusinessDataChangeSource.customer,
      );

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