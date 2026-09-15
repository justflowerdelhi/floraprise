import 'package:flutter/foundation.dart';

import '../data/repositories/cloud_occasion_repository.dart';
import '../data/repositories/customer_repository.dart';
import '../data/repositories/occasion_repository.dart';
import '../managers/occasion_manager.dart';
import 'customer_provider.dart';
import 'storage_mode_provider.dart';

class OccasionProvider extends ChangeNotifier {
  OccasionProvider(
    this._occasionManager,
    this._customerRepository, [
    this._storageModeProvider,
    this._cloudOccasionRepository,
    this._customerProvider,
  ]);

  final OccasionManager _occasionManager;
  final CustomerRepository _customerRepository;
  final StorageModeProvider? _storageModeProvider;
  final CloudOccasionRepository? _cloudOccasionRepository;
  final CustomerProvider? _customerProvider;

  bool _isLoading = false;
  bool _isBusy = false;
  String? _error;

  String _searchQuery = '';
  String _selectedFilter = 'All';
  DateTime? _selectedCalendarDate;

  List<String> _relationships = const [];
  List<String> _occasions = const [];

  OccasionScreenData _screenData = const OccasionScreenData(
    today: [],
    upcoming: [],
    completed: [],
    festival: [],
  );

  bool get isCloud => _storageModeProvider?.isCloud ?? false;
  bool get isLoading => _isLoading;
  bool get isBusy => _isBusy;
  String? get error => _error;

  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;

  List<String> get relationships => _relationships;
  List<String> get occasions => _occasions;

  List<OccasionFollowUpRecord> get today => _screenData.today;
  List<OccasionFollowUpRecord> get upcoming => _screenData.upcoming;
  List<OccasionFollowUpRecord> get completed => _screenData.completed;
  List<OccasionFollowUpRecord> get festival => _screenData.festival;

  Future<void> loadInitial() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (isCloud && _cloudOccasionRepository != null) {
        _relationships = _cloudOccasionRepository!.listRelationshipMaster();
        _occasions = _cloudOccasionRepository!.listOccasionMaster();
      } else {
        _relationships = await _occasionManager.relationshipMaster();
        _occasions = await _occasionManager.occasionMaster();
      }
      await _loadFollowUps();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await _loadFollowUps();
    notifyListeners();
  }

  Future<void> setSearchQuery(String query) async {
    _searchQuery = query;
    await _loadFollowUps();
    notifyListeners();
  }

  Future<void> setFilter(String filter) async {
    _selectedFilter = filter;
    _selectedCalendarDate = null; // Clear calendar date when filter is selected
    await _loadFollowUps();
    notifyListeners();
  }

  Future<void> setCalendarDate(DateTime? date) async {
    _selectedCalendarDate = date;
    // Don't change _selectedFilter - keep it as 'All' or whatever was selected
    // The specificDate parameter will handle the filtering
    await _loadFollowUps();
    notifyListeners();
  }

  Future<void> addContact({
    required int customerId,
    required String recipientName,
    required String relationship,
    required String occasion,
    required DateTime occasionDate,
    String recipientPhone = '',
    String company = '',
    String notes = '',
    bool reminderEnabled = true,
    String source = 'Manual',
  }) async {
    _isBusy = true;
    notifyListeners();

    try {
      if (isCloud && _cloudOccasionRepository != null) {
        String? cloudCustId;
        if (_customerProvider != null) {
          for (final cust in _customerProvider!.customers) {
            final rawId = cust['id'];
            if (rawId == customerId || (rawId is String && rawId.hashCode == customerId)) {
              cloudCustId = rawId.toString();
              break;
            }
          }
        }
        await _cloudOccasionRepository!.createContact(
          customerId: cloudCustId ?? customerId.toString(),
          recipientName: recipientName,
          relationship: relationship,
          occasion: occasion,
          occasionDate: occasionDate,
          recipientPhone: recipientPhone,
          company: company,
          notes: notes,
          reminderEnabled: reminderEnabled,
          source: source,
        );
      } else {
        await _occasionManager.addOccasionContact(
          customerId: customerId,
          recipientName: recipientName,
          relationship: relationship,
          occasion: occasion,
          occasionDate: occasionDate,
          recipientPhone: recipientPhone,
          company: company,
          notes: notes,
          reminderEnabled: reminderEnabled,
          source: source,
        );
      }
      await _loadFollowUps();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> markDone(OccasionFollowUpRecord record) async {
    _isBusy = true;
    notifyListeners();

    try {
      if (isCloud && _cloudOccasionRepository != null) {
        await _cloudOccasionRepository!.markDone(
          sourceType: record.sourceType,
          sourceId: record.cloudSourceId ?? record.sourceId.toString(),
          occurrenceDate: record.date,
        );
      } else {
        await _occasionManager.markDone(
          sourceType: record.sourceType,
          sourceId: record.sourceId,
          occurrenceDate: record.date,
        );
      }
      await _loadFollowUps();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> snoozeTomorrow(OccasionFollowUpRecord record) async {
    _isBusy = true;
    notifyListeners();

    try {
      if (isCloud && _cloudOccasionRepository != null) {
        await _cloudOccasionRepository!.snoozeTomorrow(
          sourceType: record.sourceType,
          sourceId: record.cloudSourceId ?? record.sourceId.toString(),
          occurrenceDate: record.date,
        );
      } else {
        await _occasionManager.snoozeTomorrow(
          sourceType: record.sourceType,
          sourceId: record.sourceId,
          occurrenceDate: record.date,
        );
      }
      await _loadFollowUps();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> deleteManualReminder(OccasionFollowUpRecord record) async {
    if (!record.isManual) {
      return;
    }

    _isBusy = true;
    notifyListeners();

    try {
      if (isCloud && _cloudOccasionRepository != null) {
        await _cloudOccasionRepository!.deleteContact(
          record.cloudSourceId ?? record.sourceId.toString(),
        );
      } else {
        await _occasionManager.deleteManualReminder(
          contactId: record.sourceId,
          occurrenceDate: record.date,
        );
      }
      await _loadFollowUps();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<int?> findCustomerIdByNameOrPhone({
    required String customerName,
    required String mobile,
  }) async {
    if (isCloud && _customerProvider != null) {
      final normalized = mobile.replaceAll(RegExp(r'\D'), '');
      for (final cust in _customerProvider!.customers) {
        final custPhoneNorm =
            (cust['phone'] as String? ?? '').replaceAll(RegExp(r'\D'), '');
        final custName = (cust['name'] as String? ?? '').toLowerCase();
        if ((normalized.isNotEmpty && custPhoneNorm.endsWith(normalized)) ||
            (custName == customerName.trim().toLowerCase())) {
          final rawId = cust['id'];
          if (rawId is int) return rawId;
          return rawId.toString().hashCode;
        }
      }
      return null;
    }
    return _occasionManager.findCustomerIdByNameOrPhone(
      customerName: customerName,
      mobile: mobile,
    );
  }

  Future<int> createCustomer({
    required String name,
    required String phone,
  }) async {
    if (isCloud && _customerProvider != null) {
      await _customerProvider!.addCustomer(
        phone: phone,
        name: name,
      );
      final id = await findCustomerIdByNameOrPhone(
        customerName: name,
        mobile: phone,
      );
      return id ?? name.hashCode;
    }
    final customer = await _customerRepository.create(
      name: name,
      phone: phone,
    );
    return customer.id;
  }

  Future<OccasionContactRecord?> findDuplicate({
    required int customerId,
    required String recipientName,
    required String occasion,
  }) {
    if (isCloud) {
      return Future.value(null);
    }
    return _occasionManager.findDuplicate(
      customerId: customerId,
      recipientName: recipientName,
      occasion: occasion,
    );
  }

  Future<OccasionDashboardSummary> dashboardSummary(DateTime today) {
    if (isCloud && _cloudOccasionRepository != null) {
      return _cloudOccasionRepository!.getDashboardSummary(today);
    }
    return _occasionManager.dashboardSummary(today);
  }

  Future<void> _loadFollowUps() async {
    if (isCloud && _cloudOccasionRepository != null) {
      _screenData = await _cloudOccasionRepository!.buildScreenData(
        today: DateTime.now(),
        search: _searchQuery,
        filter: _selectedFilter,
        specificDate: _selectedCalendarDate,
      );
    } else {
      _screenData = await _occasionManager.screenData(
        today: DateTime.now(),
        search: _searchQuery,
        filter: _selectedFilter,
        specificDate: _selectedCalendarDate,
      );
    }
    _error = null;
  }
}
