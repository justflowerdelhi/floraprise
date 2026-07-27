import 'package:flutter/foundation.dart';

import '../data/repositories/occasion_repository.dart';
import '../data/repositories/customer_repository.dart';
import '../managers/occasion_manager.dart';

class OccasionProvider extends ChangeNotifier {
  OccasionProvider(this._occasionManager, this._customerRepository);

  final OccasionManager _occasionManager;
  final CustomerRepository _customerRepository;

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
      _relationships = await _occasionManager.relationshipMaster();
      _occasions = await _occasionManager.occasionMaster();
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
      await _occasionManager.markDone(
        sourceType: record.sourceType,
        sourceId: record.sourceId,
        occurrenceDate: record.date,
      );
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
      await _occasionManager.snoozeTomorrow(
        sourceType: record.sourceType,
        sourceId: record.sourceId,
        occurrenceDate: record.date,
      );
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
      await _occasionManager.deleteManualReminder(
        contactId: record.sourceId,
        occurrenceDate: record.date,
      );
      await _loadFollowUps();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<int?> findCustomerIdByNameOrPhone({
    required String customerName,
    required String mobile,
  }) {
    return _occasionManager.findCustomerIdByNameOrPhone(
      customerName: customerName,
      mobile: mobile,
    );
  }

  Future<int> createCustomer({
    required String name,
    required String phone,
  }) async {
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
    return _occasionManager.findDuplicate(
      customerId: customerId,
      recipientName: recipientName,
      occasion: occasion,
    );
  }

  Future<OccasionDashboardSummary> dashboardSummary(DateTime today) {
    return _occasionManager.dashboardSummary(today);
  }

  Future<void> _loadFollowUps() async {
    _screenData = await _occasionManager.screenData(
      today: DateTime.now(),
      search: _searchQuery,
      filter: _selectedFilter,
      specificDate: _selectedCalendarDate,
    );
    _error = null;
  }
}
