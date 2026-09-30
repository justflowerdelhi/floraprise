import 'package:flutter/foundation.dart';

import '../data/repositories/cloud_customer_repository.dart';
import '../data/repositories/customer_repository.dart';
import '../data/repositories/order_repository.dart';
import '../managers/walk_in_manager.dart';
import '../models/crm_models.dart';
import '../models/storage_mode.dart';
import '../models/walk_in_session.dart';
import '../services/crm_service.dart';
import '../services/storage_mode_service.dart';

class CrmProvider extends ChangeNotifier {
  CrmProvider({
    CrmService? crmService,
    CustomerRepository? customerRepository,
    CloudCustomerRepository? cloudCustomerRepository,
    StorageModeService? storageModeService,
  })  : _crmService = crmService ?? CrmService(),
        _customerRepository = customerRepository ?? CustomerRepository(),
        _cloudCustomerRepository =
            cloudCustomerRepository ?? CloudCustomerRepository(),
        _storageModeService = storageModeService ?? StorageModeService();

  final CrmService _crmService;
  final CustomerRepository _customerRepository;
  final CloudCustomerRepository _cloudCustomerRepository;
  final StorageModeService _storageModeService;

  CrmTodayData _data = CrmTodayData.empty;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();

  // Enquiries Screen State
  List<CrmEnquiryItem> _enquiriesList = [];
  bool _isEnquiriesLoading = false;
  String _enquiryStatusFilter = 'all';
  String _enquirySearchQuery = '';
  DateTime? _enquiryDateFilter;

  CrmTodayData get data => _data;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime get selectedDate => _selectedDate;

  List<CrmFollowUpItem> get followUps => _data.followUps;
  List<CrmEnquiryItem> get enquiries => _data.enquiries;
  List<CrmQuoteItem> get pendingQuotes => _data.pendingQuotes;
  List<CrmOccasionItem> get upcomingOccasions => _data.upcomingOccasions;

  List<CrmEnquiryItem> get enquiriesList => _enquiriesList;
  bool get isEnquiriesLoading => _isEnquiriesLoading;
  String get enquiryStatusFilter => _enquiryStatusFilter;
  String get enquirySearchQuery => _enquirySearchQuery;
  DateTime? get enquiryDateFilter => _enquiryDateFilter;

  // --------------------------------------------------------------------------
  // TODAY DATA
  // --------------------------------------------------------------------------
  Future<void> loadTodayData({DateTime? date}) async {
    final targetDate = date ?? _selectedDate;
    _selectedDate = targetDate;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final freshData = await _crmService.getTodayData(targetDate);
      _data = freshData;
      _errorMessage = null;
    } catch (e, st) {
      debugPrint('[CrmProvider] Error loading CRM today data: $e\n$st');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadTodayData(date: _selectedDate);
    if (_enquiriesList.isNotEmpty) {
      await loadEnquiries(
        status: _enquiryStatusFilter,
        query: _enquirySearchQuery,
        eventDate: _enquiryDateFilter,
      );
    }
  }

  // --------------------------------------------------------------------------
  // ENQUIRIES PIPELINE
  // --------------------------------------------------------------------------
  Future<void> loadEnquiries({
    String? status,
    String? query,
    DateTime? eventDate,
  }) async {
    _enquiryStatusFilter = status ?? _enquiryStatusFilter;
    _enquirySearchQuery = query ?? _enquirySearchQuery;
    _enquiryDateFilter = eventDate;
    _isEnquiriesLoading = true;
    notifyListeners();

    try {
      final list = await _crmService.listEnquiries(
        status: _enquiryStatusFilter,
        query: _enquirySearchQuery,
        eventDate: _enquiryDateFilter,
      );
      _enquiriesList = list;
    } catch (e, st) {
      debugPrint('[CrmProvider] Error loading enquiries: $e\n$st');
    } finally {
      _isEnquiriesLoading = false;
      notifyListeners();
    }
  }

  Future<CrmEnquiryItem> createEnquiry({
    required String customerPhone,
    required String customerName,
    required String requirement,
    String category = 'General',
    DateTime? eventDate,
    int? budgetPaise,
    String? location,
    String? notes,
    String? nextAction,
    DateTime? nextFollowUpAt,
  }) async {
    final mode = await _storageModeService.getCurrentMode();
    final isCloudOrWeb = kIsWeb || mode == StorageMode.cloud;

    int? localCustId;
    String? cloudCustId;
    final normalizedPhone = _normalizePhone(customerPhone);

    // 1. Resolve or create customer
    if (isCloudOrWeb) {
      try {
        final existing = await _cloudCustomerRepository.findByPhone(normalizedPhone);
        if (existing != null && existing.id.isNotEmpty) {
          cloudCustId = existing.id;
        } else {
          cloudCustId = await _cloudCustomerRepository.create(
            phone: normalizedPhone,
            name: customerName.trim().isNotEmpty ? customerName.trim() : 'Customer',
          );
        }
      } catch (e) {
        debugPrint('[CrmProvider] Cloud customer lookup/create fallback: $e');
      }
    } else {
      try {
        final existing = await _customerRepository.findByPhone(normalizedPhone);
        if (existing != null) {
          localCustId = existing.id;
          cloudCustId = existing.cloudCustomerId;
        } else {
          final created = await _customerRepository.create(
            phone: normalizedPhone,
            name: customerName.trim().isNotEmpty ? customerName.trim() : 'Customer',
          );
          localCustId = created.id;
        }
      } catch (e) {
        debugPrint('[CrmProvider] Local customer lookup/create error: $e');
        rethrow;
      }
    }

    final now = DateTime.now();
    final item = CrmEnquiryItem(
      clientSyncId: generateClientSyncId(),
      customerId: localCustId,
      cloudCustomerId: cloudCustId,
      customerName: customerName.trim().isNotEmpty ? customerName.trim() : 'Customer',
      customerPhone: normalizedPhone,
      category: category.trim().isNotEmpty ? category.trim() : 'General',
      requirement: requirement.trim(),
      eventDate: eventDate,
      budgetPaise: budgetPaise,
      location: location?.trim(),
      notes: notes?.trim(),
      status: 'new',
      nextAction: nextAction?.trim() ?? 'Follow-up with customer',
      nextFollowUpAt: nextFollowUpAt,
      createdAt: now,
      updatedAt: now,
    );

    final createdItem = await _crmService.createEnquiry(item);

    // Refresh enquiries and today data
    await loadTodayData();
    await loadEnquiries();

    return createdItem;
  }

  Future<CrmEnquiryItem> updateEnquiry(CrmEnquiryItem item) async {
    final updated = await _crmService.updateEnquiry(item);
    await loadTodayData();
    await loadEnquiries();
    return updated;
  }

  Future<void> deleteEnquiry(CrmEnquiryItem item) async {
    await _crmService.deleteEnquiry(item);
    await loadTodayData();
    await loadEnquiries();
  }

  // --------------------------------------------------------------------------
  // CRM QUOTE DRAFTS (Phase 2B-1)
  // --------------------------------------------------------------------------
  Future<int> saveQuoteDraftForEnquiry({
    required CrmEnquiryItem enquiry,
    required WalkInSession session,
    required OrderTotals totals,
  }) async {
    final draftId = await _crmService.saveQuoteDraft(
      session: session,
      totals: totals,
      customerId: enquiry.customerId,
      cloudCustomerId: enquiry.cloudCustomerId,
    );

    final updatedEnquiry = enquiry.copyWith(
      quoteOrderId: draftId,
      status: 'quote_sent',
      updatedAt: DateTime.now(),
    );

    await _crmService.updateEnquiry(updatedEnquiry);
    await loadTodayData();
    await loadEnquiries();

    return draftId;
  }

  Future<WalkInSession?> loadQuoteDraft(int draftOrderId) async {
    return _crmService.getQuoteDraft(draftOrderId);
  }

  Future<int> convertQuoteToWonOrder({
    required CrmEnquiryItem enquiry,
    WalkInManager? walkInManager,
  }) async {
    final confirmedOrderId = await _crmService.convertQuoteToWonOrder(
      enquiry: enquiry,
      walkInManager: walkInManager,
    );
    await loadTodayData();
    await loadEnquiries();
    return confirmedOrderId;
  }

  // --------------------------------------------------------------------------
  // LOST / REOPEN (Phase 2B-4)
  // --------------------------------------------------------------------------
  Future<CrmEnquiryItem> markEnquiryLost({
    required CrmEnquiryItem enquiry,
    required String reason,
    String? notes,
  }) async {
    final updated = await _crmService.markEnquiryLost(
      enquiry: enquiry,
      reason: reason,
      notes: notes,
    );
    await loadTodayData();
    await loadEnquiries();
    return updated;
  }

  Future<CrmEnquiryItem> reopenEnquiry({
    required CrmEnquiryItem enquiry,
    DateTime? nextFollowUpAt,
    String? nextAction,
    String? notes,
  }) async {
    final updated = await _crmService.reopenEnquiry(
      enquiry: enquiry,
      nextFollowUpAt: nextFollowUpAt,
      nextAction: nextAction,
      notes: notes,
    );
    await loadTodayData();
    await loadEnquiries();
    return updated;
  }

  // Customer Lookup helper for dialog
  Future<Map<String, String>?> findCustomerByPhone(String phone) async {
    final normalized = _normalizePhone(phone);
    if (normalized.length < 10) return null;

    final mode = await _storageModeService.getCurrentMode();
    final isCloudOrWeb = kIsWeb || mode == StorageMode.cloud;

    if (isCloudOrWeb) {
      final cloudCust = await _cloudCustomerRepository.findByPhone(normalized);
      if (cloudCust != null) {
        return {
          'id': cloudCust.id,
          'name': cloudCust.name,
          'phone': cloudCust.phone ?? normalized,
        };
      }
    } else {
      final localCust = await _customerRepository.findByPhone(normalized);
      if (localCust != null) {
        return {
          'id': localCust.id.toString(),
          'name': localCust.name,
          'phone': localCust.phone,
        };
      }
    }
    return null;
  }

  // --------------------------------------------------------------------------
  // FOLLOW-UPS ACTIONS
  // --------------------------------------------------------------------------
  Future<void> markFollowUpDone(CrmFollowUpItem item) async {
    final previousFollowUps = List<CrmFollowUpItem>.from(_data.followUps);
    final updatedFollowUps = _data.followUps.map((f) {
      if (f.id == item.id) {
        return f.copyWith(isCompleted: true, status: 'Completed');
      }
      return f;
    }).toList();

    _data = CrmTodayData(
      followUps: updatedFollowUps,
      enquiries: _data.enquiries,
      pendingQuotes: _data.pendingQuotes,
      upcomingOccasions: _data.upcomingOccasions,
      evaluatedAt: _data.evaluatedAt,
    );
    notifyListeners();

    try {
      await _crmService.markFollowUpDone(item);
    } catch (e) {
      debugPrint('[CrmProvider] Failed to mark follow-up done: $e');
      _data = CrmTodayData(
        followUps: previousFollowUps,
        enquiries: _data.enquiries,
        pendingQuotes: _data.pendingQuotes,
        upcomingOccasions: _data.upcomingOccasions,
        evaluatedAt: _data.evaluatedAt,
      );
      notifyListeners();
    }
  }

  Future<void> snoozeFollowUp(CrmFollowUpItem item) async {
    final previousFollowUps = List<CrmFollowUpItem>.from(_data.followUps);
    final updatedFollowUps = _data.followUps.where((f) => f.id != item.id).toList();

    _data = CrmTodayData(
      followUps: updatedFollowUps,
      enquiries: _data.enquiries,
      pendingQuotes: _data.pendingQuotes,
      upcomingOccasions: _data.upcomingOccasions,
      evaluatedAt: _data.evaluatedAt,
    );
    notifyListeners();

    try {
      await _crmService.snoozeFollowUp(item);
    } catch (e) {
      debugPrint('[CrmProvider] Failed to snooze follow-up: $e');
      _data = CrmTodayData(
        followUps: previousFollowUps,
        enquiries: _data.enquiries,
        pendingQuotes: _data.pendingQuotes,
        upcomingOccasions: _data.upcomingOccasions,
        evaluatedAt: _data.evaluatedAt,
      );
      notifyListeners();
    }
  }

  String _normalizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
  }
}
