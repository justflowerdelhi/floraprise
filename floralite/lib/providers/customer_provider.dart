import 'package:flutter/foundation.dart';
import '../data/repositories/customer_repository.dart';
import '../managers/customer_manager.dart';
import '../managers/customer_import_manager.dart';
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
  List<String> _filterPurchasedCategories = [];

  List<Map<String, dynamic>> get customers => _filteredCustomers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get pendingPaymentFilter => _filterPendingPayment;
  String get totalOrdersFilter => _filterTotalOrders;
  List<String> get purchasedCategoriesFilter => _filterPurchasedCategories;

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

  Map<String, dynamic> _cloudMap(
    CloudCustomer c, {
    CloudCustomerStatistics? stats,
  }) =>
      {
        'id': c.id,
        'name': c.name,
        'phone': c.phone ?? '',
        'email': c.email ?? '',
        'createdAt': '',
        'lastOrder': _formatLastOrder(stats?.lastOrderAt),
        'birthday': '-',
        'birthdayMd': '',
        'anniversaryMd': '',
        'company': '',
        'department': '',
        'notes': c.notes ?? '',
        'pendingPaymentPaise': stats?.pendingPaymentPaise ?? 0,
        'pendingPayment': _formatPaise(stats?.pendingPaymentPaise ?? 0),
        'totalOrders': stats?.totalOrders ?? 0,
        'rewardPoints': 0, // Intentionally local/Primary Device
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
          purchasedCategories: _filterPurchasedCategories.isNotEmpty ? _filterPurchasedCategories : null,
        );
        final statsList = await Future.wait(
          rows.map((c) => _cloudRepository.getStatistics(c.id)),
        );
        _customers = List.generate(
          rows.length,
          (i) => _cloudMap(rows[i], stats: statsList[i]),
        );
      } else {
        final rows = await _customerManager.customerRepository.search(
          _searchQuery,
          purchasedCategories: _filterPurchasedCategories.isNotEmpty ? _filterPurchasedCategories : null,
        );

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

  void setPurchasedCategoriesFilter(List<String> v) {
    _filterPurchasedCategories = List.from(v);

    // We must reload since sqlite/API filtering is needed for categories
    loadCustomers();
  }

  void clearFilters() {
    _filterPendingPayment = 'all';
    _filterTotalOrders = 'all';

    if (_filterPurchasedCategories.isNotEmpty) {
       _filterPurchasedCategories.clear();
       loadCustomers();
    } else {
       notifyListeners();
    }
  }

  Future<CustomerRecord?> lookupByPhone(String phone) {
    return _customerManager.lookupByPhone(phone);
  }

  Future<List<CustomerRecord>> searchCustomers(String query) {
    return _customerManager.searchCustomers(query, isCloud: _cloud);
  }

  Future<Map<String, dynamic>?> lookupCustomerStatistics(
    CustomerRecord customer,
  ) async {
    if (!_cloud) {
      final stats = await _customerManager.lookupCustomerStatistics(customer);
      if (stats == null) return null;
      return stats;
    }

    final cloudCustomerId = customer.cloudCustomerId?.trim() ?? '';
    if (cloudCustomerId.isEmpty) {
      return {
        'previousOrders': 0,
        'lifetimePurchasePaise': 0,
        'lastOrderDate': null,
        'pendingPaymentPaise': 0,
      };
    }

    final stats = await _cloudRepository.getStatistics(
      cloudCustomerId,
      companyId: customer.cloudCompanyId,
    );
    if (stats == null) {
      return {
        'previousOrders': 0,
        'lifetimePurchasePaise': 0,
        'lastOrderDate': null,
        'pendingPaymentPaise': 0,
      };
    }

    return {
      'previousOrders': stats.totalOrders,
      'lifetimePurchasePaise': stats.lifetimePurchasePaise,
      'lastOrderDate': stats.lastOrderAt,
      'pendingPaymentPaise': stats.pendingPaymentPaise,
    };
  }

  Future<List<Map<String, dynamic>>> getPurchaseInsights(String customerId) async {
    try {
      if (_cloud) {
        return await _cloudRepository.getPurchaseInsights(customerId);
      } else {
        return await _customerManager.customerRepository.getPurchaseInsights(int.parse(customerId));
      }
    } catch (_) {
      return [];
    }
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

  Future<dynamic> lookupCustomerForImport(String phone) async {
    if (_cloud) {
      final cloudCustomer = await _cloudRepository.findByPhone(phone);
      if (cloudCustomer != null) return cloudCustomer;
      if (!kIsWeb) {
        return await _customerManager.lookupByPhone(phone);
      }
      return null;
    } else {
      return await _customerManager.lookupByPhone(phone);
    }
  }

  Future<CustomerImportPreview> prepareImportBytes(
    Uint8List bytes,
    String fileName,
  ) async {
    final importManager = CustomerImportManager(_customerManager.customerRepository);
    return importManager.prepareImportBytes(
      bytes: bytes,
      fileName: fileName,
      findExistingCustomer: lookupCustomerForImport,
    );
  }

  Future<CustomerImportPreview> prepareImportFromContacts(
    List<dynamic> contacts,
  ) async {
    final importManager = CustomerImportManager(_customerManager.customerRepository);
    return importManager.prepareImportFromContacts(
      contacts: contacts,
      findExistingCustomer: lookupCustomerForImport,
    );
  }

  Future<CustomerImportResult> importCustomers({
    required List<CustomerImportRow> rows,
    required DuplicateHandlingOption duplicateHandling,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final importManager = CustomerImportManager(_customerManager.customerRepository);
      final result = await importManager.runImport(
        rows: rows,
        duplicateHandling: duplicateHandling,
        createCustomer: ({
          required String phone,
          required String name,
          String birthdayMd = '',
          String anniversaryMd = '',
          String company = '',
          String department = '',
          String notes = '',
        }) async {
          if (_cloud) {
            await _cloudRepository.create(phone: phone, name: name);
            if (!kIsWeb) {
              await _customerManager.ensureCustomer(
                phone: phone,
                name: name,
                birthdayMd: birthdayMd,
                anniversaryMd: anniversaryMd,
                company: company,
                department: department,
                notes: notes,
              );
            }
          } else {
            await _customerManager.ensureCustomer(
              phone: phone,
              name: name,
              birthdayMd: birthdayMd,
              anniversaryMd: anniversaryMd,
              company: company,
              department: department,
              notes: notes,
            );
          }
        },
        updateCustomer: ({
          required dynamic existing,
          required String phone,
          required String name,
          String birthdayMd = '',
          String anniversaryMd = '',
          String company = '',
          String department = '',
          String notes = '',
        }) async {
          if (_cloud) {
            String customerId = '';
            if (existing is CloudCustomer) {
              customerId = existing.id;
            } else if (existing is CustomerRecord &&
                existing.cloudCustomerId != null &&
                existing.cloudCustomerId!.isNotEmpty) {
              customerId = existing.cloudCustomerId!;
            } else if (existing is Map) {
              customerId = existing['id']?.toString() ?? '';
            }
            if (customerId.isNotEmpty) {
              await _cloudRepository.update(id: customerId, phone: phone, name: name);
            }
            if (!kIsWeb && existing is CustomerRecord) {
              await _customerManager.updateCustomer(
                id: existing.id,
                phone: phone,
                name: name,
                birthdayMd: birthdayMd.isNotEmpty ? birthdayMd : existing.birthdayMd,
                anniversaryMd:
                    anniversaryMd.isNotEmpty ? anniversaryMd : existing.anniversaryMd,
                company: company.isNotEmpty ? company : existing.company,
                department:
                    department.isNotEmpty ? department : existing.department,
                notes: notes.isNotEmpty ? notes : existing.notes,
              );
            }
          } else {
            if (existing is CustomerRecord) {
              await _customerManager.updateCustomer(
                id: existing.id,
                phone: phone,
                name: name,
                birthdayMd: birthdayMd.isNotEmpty ? birthdayMd : existing.birthdayMd,
                anniversaryMd:
                    anniversaryMd.isNotEmpty ? anniversaryMd : existing.anniversaryMd,
                company: company.isNotEmpty ? company : existing.company,
                department:
                    department.isNotEmpty ? department : existing.department,
                notes: notes.isNotEmpty ? notes : existing.notes,
              );
            }
          }
        },
      );

      await loadCustomers();

      _businessDataEvents?.publish(
        source: BusinessDataChangeSource.customer,
      );

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}