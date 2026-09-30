import 'package:flutter/foundation.dart';

import '../data/database/app_database.dart';
import '../data/repositories/cloud_enquiry_repository.dart';
import '../data/repositories/cloud_occasion_repository.dart';
import '../data/repositories/cloud_order_repository.dart';
import '../data/repositories/cloud_scheduler_repository.dart';
import '../data/repositories/enquiry_repository.dart';
import '../data/repositories/occasion_repository.dart';
import '../data/repositories/order_repository.dart';
import '../data/repositories/scheduler_repository.dart';
import '../managers/pricing_manager.dart';
import '../managers/walk_in_manager.dart';
import '../models/crm_models.dart';
import '../models/order_workspace_models.dart';
import '../models/payment_split.dart';
import '../models/scheduler_task.dart';
import '../models/storage_mode.dart';
import '../models/walk_in_enums.dart';
import '../models/walk_in_session.dart';
import 'storage_mode_service.dart';
import 'web_draft_storage_service.dart';

class CrmService {
  CrmService({
    EnquiryRepository? enquiryRepository,
    CloudEnquiryRepository? cloudEnquiryRepository,
    OccasionRepository? occasionRepository,
    CloudOccasionRepository? cloudOccasionRepository,
    SchedulerRepository? schedulerRepository,
    CloudSchedulerRepository? cloudSchedulerRepository,
    OrderRepository? orderRepository,
    CloudOrderRepository? cloudOrderRepository,
    StorageModeService? storageModeService,
  })  : _enquiryRepository = enquiryRepository ?? EnquiryRepository(),
        _cloudEnquiryRepository =
            cloudEnquiryRepository ?? CloudEnquiryRepository(),
        _occasionRepository = occasionRepository ?? OccasionRepository(),
        _cloudOccasionRepository =
            cloudOccasionRepository ?? CloudOccasionRepository(),
        _schedulerRepository = schedulerRepository ?? SchedulerRepository(),
        _cloudSchedulerRepository =
            cloudSchedulerRepository ?? CloudSchedulerRepository(),
        _orderRepository = orderRepository ?? OrderRepository(),
        _cloudOrderRepository = cloudOrderRepository ?? CloudOrderRepository(),
        _storageModeService = storageModeService ?? StorageModeService();

  final EnquiryRepository _enquiryRepository;
  final CloudEnquiryRepository _cloudEnquiryRepository;
  final OccasionRepository _occasionRepository;
  final CloudOccasionRepository _cloudOccasionRepository;
  final SchedulerRepository _schedulerRepository;
  final CloudSchedulerRepository _cloudSchedulerRepository;
  final OrderRepository _orderRepository;
  final CloudOrderRepository _cloudOrderRepository;
  final StorageModeService _storageModeService;

  Future<CrmTodayData> getTodayData(DateTime now) async {
    final today = DateTime(now.year, now.month, now.day);
    final mode = await _storageModeService.getCurrentMode();

    if (kIsWeb) {
      return _getWebTodayData(today);
    } else if (mode == StorageMode.cloud) {
      return _getCloudTodayData(today);
    } else {
      return _getSoloTodayData(today);
    }
  }

  // --------------------------------------------------------------------------
  // SOLO (Offline SQLite)
  // --------------------------------------------------------------------------
  Future<CrmTodayData> _getSoloTodayData(DateTime today) async {
    // 1. Follow-ups
    final followUps = <CrmFollowUpItem>[];

    // 1a. Occasion follow-ups (strictly 'occasion' source, no payment)
    try {
      final occasionData =
          await _occasionRepository.buildScreenData(today: today);
      for (final item in occasionData.today) {
        if (item.isCompleted ||
            item.sourceType == 'delivery' ||
            item.sourceType == 'payment') {
          continue;
        }
        followUps.add(
          CrmFollowUpItem(
            id: 'occ_${item.sourceId}_${item.date.toIso8601String()}',
            sourceType: 'occasion',
            localSourceId: item.sourceId,
            scheduledTime: DateTime(today.year, today.month, today.day, 10, 0),
            customerName:
                item.title.trim().isNotEmpty ? item.title : 'Customer',
            customerPhone: item.customerPhone.isNotEmpty
                ? item.customerPhone
                : item.recipientPhone,
            requirementSummary: item.subtitle,
            status: item.isCompleted ? 'Completed' : 'Pending',
            isCompleted: item.isCompleted,
            customerId: item.customerId,
            orderId: item.orderId,
          ),
        );
      }
    } catch (_) {}

    // 1b. Scheduler task follow-ups
    try {
      final tasks =
          await _schedulerRepository.getOperationalQueue(selectedDate: today);
      for (final task in tasks) {
        if (!_isSameDay(task.scheduledAt, today)) continue;
        if (task.status == TaskStatus.completed ||
            task.status == TaskStatus.cancelled) {
          continue;
        }
        if (task.category == TaskCategory.reminder ||
            task.category == TaskCategory.sales ||
            task.type == TaskType.reminder ||
            task.type == TaskType.appointment) {
          followUps.add(
            CrmFollowUpItem(
              id: 'task_${task.id ?? task.cloudId ?? task.hashCode}',
              sourceType: 'scheduler',
              localSourceId: task.id,
              cloudSourceId: task.cloudId,
              scheduledTime: task.scheduledAt,
              customerName:
                  task.title.trim().isNotEmpty ? task.title : 'Task',
              customerPhone: '',
              requirementSummary: task.notes ?? task.title,
              status: task.isOverdue ? 'Overdue' : 'Pending',
              isCompleted: task.status == TaskStatus.completed,
              customerId: task.linkedCustomerId,
              orderId: task.linkedOrderId,
            ),
          );
        }
      }
    } catch (_) {}

    followUps.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    // 2. New Enquiries (Persistent SQLite EnquiryRepository)
    final enquiries = <CrmEnquiryItem>[];
    try {
      final list = await _enquiryRepository.getTodayNewEnquiries(today);
      enquiries.addAll(list);
    } catch (e) {
      debugPrint('[CrmService] Error loading solo enquiries: $e');
    }

    // 3. Quotes Pending (from draft orders)
    final pendingQuotes = <CrmQuoteItem>[];
    try {
      final drafts = await _orderRepository.listDraftOrders();
      for (final draft in drafts) {
        pendingQuotes.add(
          CrmQuoteItem(
            id: 'quote_${draft.id}',
            orderId: draft.id,
            orderNo: draft.orderNo,
            customerName: draft.customerName.isNotEmpty
                ? draft.customerName
                : 'Walk-in Customer',
            customerPhone: draft.customerPhone,
            requirementSummary:
                '${draft.itemCount} item${draft.itemCount == 1 ? '' : 's'} • ${draft.fulfilmentType.name.toUpperCase()}',
            amount: draft.grandTotalPaise / 100.0,
            date: draft.updatedAt,
            nextAction: 'Review & Confirm Quote',
          ),
        );
      }
    } catch (_) {}

    // 4. Occasions This Week
    final upcomingOccasions = <CrmOccasionItem>[];
    try {
      final contacts =
          await _occasionRepository.listContacts(filter: 'Next 7 Days');
      for (final contact in contacts) {
        if (!contact.reminderEnabled) continue;
        final dayLabel = _computeDayLabel(today, contact.occasionDate);
        upcomingOccasions.add(
          CrmOccasionItem(
            id: 'occ_contact_${contact.id}',
            customerName: contact.customerName.isNotEmpty
                ? contact.customerName
                : 'Customer',
            recipientName: contact.recipientName,
            customerPhone: contact.customerPhone.isNotEmpty
                ? contact.customerPhone
                : contact.recipientPhone,
            occasion: contact.occasion,
            relationship: contact.relationship,
            occasionDate: contact.occasionDate,
            dayLabel: dayLabel,
            notes: contact.notes,
            customerId: contact.customerId,
          ),
        );
      }
    } catch (_) {}

    upcomingOccasions.sort((a, b) => a.occasionDate.compareTo(b.occasionDate));

    return CrmTodayData(
      followUps: followUps,
      enquiries: enquiries,
      pendingQuotes: pendingQuotes,
      upcomingOccasions: upcomingOccasions,
      evaluatedAt: DateTime.now(),
    );
  }

  // --------------------------------------------------------------------------
  // CLOUD MOBILE
  // --------------------------------------------------------------------------
  Future<CrmTodayData> _getCloudTodayData(DateTime today) async {
    // 1. Follow-ups
    final followUps = <CrmFollowUpItem>[];
    try {
      final occasionData =
          await _cloudOccasionRepository.buildScreenData(today: today);
      for (final item in occasionData.today) {
        if (item.isCompleted ||
            item.sourceType == 'delivery' ||
            item.sourceType == 'payment') {
          continue;
        }
        followUps.add(
          CrmFollowUpItem(
            id: 'cloud_occ_${item.cloudSourceId ?? item.sourceId}_${item.date.toIso8601String()}',
            sourceType: 'occasion',
            localSourceId: item.sourceId,
            cloudSourceId: item.cloudSourceId,
            scheduledTime: DateTime(today.year, today.month, today.day, 10, 0),
            customerName:
                item.title.trim().isNotEmpty ? item.title : 'Customer',
            customerPhone: item.customerPhone.isNotEmpty
                ? item.customerPhone
                : item.recipientPhone,
            requirementSummary: item.subtitle,
            status: item.isCompleted ? 'Completed' : 'Pending',
            isCompleted: item.isCompleted,
            customerId: item.customerId,
            cloudCustomerId: item.cloudCustomerId,
            orderId: item.orderId,
          ),
        );
      }
    } catch (_) {}

    // Cloud tasks
    try {
      final from = DateTime(today.year, today.month, today.day);
      final to =
          from.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
      final tasks = await _cloudSchedulerRepository.listTasks(from: from, to: to);
      for (final task in tasks) {
        if (task.status == TaskStatus.completed ||
            task.status == TaskStatus.cancelled) {
          continue;
        }
        if (task.category == TaskCategory.reminder ||
            task.category == TaskCategory.sales ||
            task.type == TaskType.reminder ||
            task.type == TaskType.appointment) {
          followUps.add(
            CrmFollowUpItem(
              id: 'cloud_task_${task.cloudId ?? task.id}',
              sourceType: 'scheduler',
              localSourceId: task.id,
              cloudSourceId: task.cloudId,
              scheduledTime: task.scheduledAt,
              customerName:
                  task.title.trim().isNotEmpty ? task.title : 'Task',
              customerPhone: '',
              requirementSummary: task.notes ?? task.title,
              status: task.isOverdue ? 'Overdue' : 'Pending',
              isCompleted: task.status == TaskStatus.completed,
              customerId: task.linkedCustomerId,
              cloudCustomerId: task.cloudLinkedCustomerId,
              orderId: task.linkedOrderId,
            ),
          );
        }
      }
    } catch (_) {}

    followUps.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    // 2. Enquiries (Cloud Enquiry Repository)
    final enquiries = <CrmEnquiryItem>[];
    try {
      final list = await _cloudEnquiryRepository.getTodayNewEnquiries(today);
      enquiries.addAll(list);
    } catch (e) {
      debugPrint('[CrmService] Error loading cloud enquiries: $e');
    }

    // 3. Quotes Pending (Cloud workspace pending orders)
    final pendingQuotes = <CrmQuoteItem>[];
    try {
      final cloudOrders = await _cloudOrderRepository.getWorkspace(
        tab: 'pending',
        searchQuery: '',
        filters: const OrderWorkspaceFilters(),
      );
      for (final order in cloudOrders) {
        pendingQuotes.add(
          CrmQuoteItem(
            id: 'cloud_quote_${order.cloudOrderId ?? order.id}',
            cloudOrderId: order.cloudOrderId,
            orderNo: order.orderNo,
            customerName: order.customerName.isNotEmpty
                ? order.customerName
                : 'Customer',
            customerPhone: order.customerPhone,
            requirementSummary:
                '${order.fulfilmentType.toUpperCase()} • ${order.status.toUpperCase()}',
            amount: order.grandTotalPaise / 100.0,
            date: order.createdAt,
            nextAction: 'Review & Confirm Quote',
          ),
        );
      }
    } catch (_) {}

    // 4. Occasions This Week
    final upcomingOccasions = <CrmOccasionItem>[];
    try {
      final contacts = await _cloudOccasionRepository.listContacts();
      final todayDate = DateTime(today.year, today.month, today.day);
      final weekEnd = todayDate.add(const Duration(days: 7));

      for (final contact in contacts) {
        if (!contact.reminderEnabled) continue;

        var effDate = DateTime(
            today.year, contact.occasionDate.month, contact.occasionDate.day);
        if (effDate.isBefore(todayDate.subtract(const Duration(days: 1)))) {
          effDate = DateTime(today.year + 1, contact.occasionDate.month,
              contact.occasionDate.day);
        }

        if (effDate.isAfter(todayDate.subtract(const Duration(days: 1))) &&
            effDate.isBefore(weekEnd.add(const Duration(days: 1)))) {
          final dayLabel = _computeDayLabel(today, effDate);
          upcomingOccasions.add(
            CrmOccasionItem(
              id: 'cloud_occ_contact_${contact.cloudId ?? contact.id}',
              customerName: contact.customerName.isNotEmpty
                  ? contact.customerName
                  : 'Customer',
              recipientName: contact.recipientName,
              customerPhone: contact.customerPhone.isNotEmpty
                  ? contact.customerPhone
                  : contact.recipientPhone,
              occasion: contact.occasion,
              relationship: contact.relationship,
              occasionDate: effDate,
              dayLabel: dayLabel,
              notes: contact.notes,
              customerId: contact.customerId,
              cloudCustomerId: contact.cloudCustomerId,
            ),
          );
        }
      }
    } catch (_) {}

    upcomingOccasions.sort((a, b) => a.occasionDate.compareTo(b.occasionDate));

    return CrmTodayData(
      followUps: followUps,
      enquiries: enquiries,
      pendingQuotes: pendingQuotes,
      upcomingOccasions: upcomingOccasions,
      evaluatedAt: DateTime.now(),
    );
  }

  // --------------------------------------------------------------------------
  // FLUTTER WEB
  // --------------------------------------------------------------------------
  Future<CrmTodayData> _getWebTodayData(DateTime today) async {
    // 1. Follow-ups (Cloud Occasion + Cloud Scheduler)
    final followUps = <CrmFollowUpItem>[];
    try {
      final occasionData =
          await _cloudOccasionRepository.buildScreenData(today: today);
      for (final item in occasionData.today) {
        if (item.isCompleted ||
            item.sourceType == 'delivery' ||
            item.sourceType == 'payment') {
          continue;
        }
        followUps.add(
          CrmFollowUpItem(
            id: 'web_occ_${item.cloudSourceId ?? item.sourceId}_${item.date.toIso8601String()}',
            sourceType: 'occasion',
            localSourceId: item.sourceId,
            cloudSourceId: item.cloudSourceId,
            scheduledTime: DateTime(today.year, today.month, today.day, 10, 0),
            customerName:
                item.title.trim().isNotEmpty ? item.title : 'Customer',
            customerPhone: item.customerPhone.isNotEmpty
                ? item.customerPhone
                : item.recipientPhone,
            requirementSummary: item.subtitle,
            status: item.isCompleted ? 'Completed' : 'Pending',
            isCompleted: item.isCompleted,
            customerId: item.customerId,
            cloudCustomerId: item.cloudCustomerId,
            orderId: item.orderId,
          ),
        );
      }
    } catch (_) {}

    try {
      final from = DateTime(today.year, today.month, today.day);
      final to =
          from.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
      final tasks = await _cloudSchedulerRepository.listTasks(from: from, to: to);
      for (final task in tasks) {
        if (task.status == TaskStatus.completed ||
            task.status == TaskStatus.cancelled) {
          continue;
        }
        if (task.category == TaskCategory.reminder ||
            task.category == TaskCategory.sales ||
            task.type == TaskType.reminder ||
            task.type == TaskType.appointment) {
          followUps.add(
            CrmFollowUpItem(
              id: 'web_task_${task.cloudId ?? task.id}',
              sourceType: 'scheduler',
              localSourceId: task.id,
              cloudSourceId: task.cloudId,
              scheduledTime: task.scheduledAt,
              customerName:
                  task.title.trim().isNotEmpty ? task.title : 'Task',
              customerPhone: '',
              requirementSummary: task.notes ?? task.title,
              status: task.isOverdue ? 'Overdue' : 'Pending',
              isCompleted: task.status == TaskStatus.completed,
              customerId: task.linkedCustomerId,
              cloudCustomerId: task.cloudLinkedCustomerId,
              orderId: task.linkedOrderId,
            ),
          );
        }
      }
    } catch (_) {}

    followUps.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    // 2. Enquiries (Cloud Enquiry Repository)
    final enquiries = <CrmEnquiryItem>[];
    try {
      final list = await _cloudEnquiryRepository.getTodayNewEnquiries(today);
      enquiries.addAll(list);
    } catch (e) {
      debugPrint('[CrmService] Error loading web enquiries: $e');
    }

    // 3. Quotes Pending (Web Draft Storage + Cloud Pending Orders)
    final pendingQuotes = <CrmQuoteItem>[];
    try {
      final webDrafts = await WebDraftStorageService().listDraftOrders();
      for (final draft in webDrafts) {
        pendingQuotes.add(
          CrmQuoteItem(
            id: 'web_draft_${draft.id}',
            orderId: draft.id,
            orderNo: draft.orderNo,
            customerName: draft.customerName.isNotEmpty
                ? draft.customerName
                : 'Walk-in Customer',
            customerPhone: draft.customerPhone,
            requirementSummary:
                '${draft.itemCount} item${draft.itemCount == 1 ? '' : 's'} • ${draft.fulfilmentType.name.toUpperCase()}',
            amount: draft.grandTotalPaise / 100.0,
            date: draft.updatedAt,
            nextAction: 'Review & Confirm Quote',
          ),
        );
      }
    } catch (_) {}

    if (pendingQuotes.isEmpty) {
      try {
        final cloudOrders = await _cloudOrderRepository.getWorkspace(
          tab: 'pending',
          searchQuery: '',
          filters: const OrderWorkspaceFilters(),
        );
        for (final order in cloudOrders) {
          pendingQuotes.add(
            CrmQuoteItem(
              id: 'cloud_quote_${order.cloudOrderId ?? order.id}',
              cloudOrderId: order.cloudOrderId,
              orderNo: order.orderNo,
              customerName: order.customerName.isNotEmpty
                  ? order.customerName
                  : 'Customer',
              customerPhone: order.customerPhone,
              requirementSummary:
                  '${order.fulfilmentType.toUpperCase()} • ${order.status.toUpperCase()}',
              amount: order.grandTotalPaise / 100.0,
              date: order.createdAt,
              nextAction: 'Review & Confirm Quote',
            ),
          );
        }
      } catch (_) {}
    }

    // 4. Occasions This Week
    final upcomingOccasions = <CrmOccasionItem>[];
    try {
      final contacts = await _cloudOccasionRepository.listContacts();
      final todayDate = DateTime(today.year, today.month, today.day);
      final weekEnd = todayDate.add(const Duration(days: 7));

      for (final contact in contacts) {
        if (!contact.reminderEnabled) continue;

        var effDate = DateTime(
            today.year, contact.occasionDate.month, contact.occasionDate.day);
        if (effDate.isBefore(todayDate.subtract(const Duration(days: 1)))) {
          effDate = DateTime(today.year + 1, contact.occasionDate.month,
              contact.occasionDate.day);
        }

        if (effDate.isAfter(todayDate.subtract(const Duration(days: 1))) &&
            effDate.isBefore(weekEnd.add(const Duration(days: 1)))) {
          final dayLabel = _computeDayLabel(today, effDate);
          upcomingOccasions.add(
            CrmOccasionItem(
              id: 'web_occ_contact_${contact.cloudId ?? contact.id}',
              customerName: contact.customerName.isNotEmpty
                  ? contact.customerName
                  : 'Customer',
              recipientName: contact.recipientName,
              customerPhone: contact.customerPhone.isNotEmpty
                  ? contact.customerPhone
                  : contact.recipientPhone,
              occasion: contact.occasion,
              relationship: contact.relationship,
              occasionDate: effDate,
              dayLabel: dayLabel,
              notes: contact.notes,
              customerId: contact.customerId,
              cloudCustomerId: contact.cloudCustomerId,
            ),
          );
        }
      }
    } catch (_) {}

    upcomingOccasions.sort((a, b) => a.occasionDate.compareTo(b.occasionDate));

    return CrmTodayData(
      followUps: followUps,
      enquiries: enquiries,
      pendingQuotes: pendingQuotes,
      upcomingOccasions: upcomingOccasions,
      evaluatedAt: DateTime.now(),
    );
  }

  // --------------------------------------------------------------------------
  // ENQUIRIES CRUD
  // --------------------------------------------------------------------------
  Future<List<CrmEnquiryItem>> listEnquiries({
    String? status,
    String? query,
    DateTime? eventDate,
    int page = 1,
    int pageSize = 50,
  }) async {
    final mode = await _storageModeService.getCurrentMode();
    if (kIsWeb || mode == StorageMode.cloud) {
      return _cloudEnquiryRepository.listEnquiries(
        status: status,
        query: query,
        fromEventDate: eventDate,
        toEventDate: eventDate,
        page: page,
        pageSize: pageSize,
      );
    } else {
      return _enquiryRepository.listEnquiries(
        status: status,
        query: query,
        eventDate: eventDate,
        limit: pageSize,
        offset: (page - 1) * pageSize,
      );
    }
  }

  Future<CrmEnquiryItem> createEnquiry(CrmEnquiryItem item) async {
    final mode = await _storageModeService.getCurrentMode();
    if (kIsWeb || mode == StorageMode.cloud) {
      return _cloudEnquiryRepository.create(item);
    } else {
      return _enquiryRepository.create(item);
    }
  }

  Future<CrmEnquiryItem> updateEnquiry(CrmEnquiryItem item) async {
    final mode = await _storageModeService.getCurrentMode();
    if (kIsWeb || mode == StorageMode.cloud) {
      return _cloudEnquiryRepository.update(item);
    } else {
      return _enquiryRepository.update(item);
    }
  }

  Future<void> deleteEnquiry(CrmEnquiryItem item) async {
    final mode = await _storageModeService.getCurrentMode();
    if (kIsWeb || mode == StorageMode.cloud) {
      if (item.cloudId != null && item.cloudId!.isNotEmpty) {
        await _cloudEnquiryRepository.delete(item.cloudId!);
      }
    } else {
      if (item.localId != null) {
        await _enquiryRepository.delete(item.localId!);
      }
    }
  }

  // --------------------------------------------------------------------------
  // QUOTE DRAFTS LINKING (Phase 2B-1)
  // --------------------------------------------------------------------------
  Future<int> saveQuoteDraft({
    required WalkInSession session,
    required OrderTotals totals,
    int? customerId,
    String? cloudCustomerId,
  }) async {
    return _orderRepository.upsertDraft(
      session: session,
      totals: totals,
      customerId: customerId,
      cloudCustomerId: cloudCustomerId,
    );
  }

  Future<WalkInSession?> getQuoteDraft(int draftOrderId) async {
    return _orderRepository.getDraftById(draftOrderId);
  }

  // --------------------------------------------------------------------------
  // CRM WON CONVERSION (Phase 2B-3)
  // --------------------------------------------------------------------------
  Future<int> convertQuoteToWonOrder({
    required CrmEnquiryItem enquiry,
    WalkInManager? walkInManager,
  }) async {
    if (enquiry.quoteOrderId == null) {
      throw StateError('Cannot convert enquiry to Won without a linked quote draft.');
    }

    // 1. Reconciliation & Idempotency: If already converted, return existing convertedOrderId
    if (enquiry.convertedOrderId != null && enquiry.status == 'won') {
      return enquiry.convertedOrderId!;
    }

    final mode = await _storageModeService.getCurrentMode();
    const isWeb = kIsWeb;
    final isCloud = mode == StorageMode.cloud;
    int confirmedOrderId;

    if (isWeb) {
      final draftSession = await _orderRepository.getDraftById(enquiry.quoteOrderId!);
      if (draftSession == null) {
        throw StateError('Draft quotation #${enquiry.quoteOrderId} not found.');
      }
      if (walkInManager != null) {
        var sessionToConfirm = draftSession;
        if (sessionToConfirm.payments.isEmpty) {
          final totals = PricingManager().computeTotals(
            lines: sessionToConfirm.lines,
            billDiscountType: sessionToConfirm.billDiscountType,
            billDiscountValue: sessionToConfirm.billDiscountValue,
          );
          sessionToConfirm = sessionToConfirm.copyWith(
            payments: [
              PaymentSplit(
                method: PaymentMethod.other,
                amountPaise: totals.grandTotalPaise,
                reference: 'CRM Quote Conversion',
              ),
            ],
          );
        }
        final result = await walkInManager.confirmOnlineOrder(sessionToConfirm);
        confirmedOrderId = result.orderId;
      } else {
        final result = await _orderRepository.confirmDraft(orderId: enquiry.quoteOrderId!);
        confirmedOrderId = result.orderId;
      }
    } else if (isCloud) {
      if (walkInManager != null) {
        final draftSession = await _orderRepository.getDraftById(enquiry.quoteOrderId!);
        if (draftSession == null) {
          throw StateError('Draft quotation #${enquiry.quoteOrderId} not found.');
        }
        var sessionToConfirm = draftSession;
        if (sessionToConfirm.payments.isEmpty) {
          final totals = PricingManager().computeTotals(
            lines: sessionToConfirm.lines,
            billDiscountType: sessionToConfirm.billDiscountType,
            billDiscountValue: sessionToConfirm.billDiscountValue,
          );
          sessionToConfirm = sessionToConfirm.copyWith(
            payments: [
              PaymentSplit(
                method: PaymentMethod.other,
                amountPaise: totals.grandTotalPaise,
                reference: 'CRM Quote Conversion',
              ),
            ],
          );
        }
        final result = await walkInManager.confirmOnlineOrder(sessionToConfirm);
        confirmedOrderId = result.orderId;
      } else {
        // Reconciliation check for SQLite draft
        final db = await AppDatabase.instance.database;
        final rows = await db.query(
          'orders',
          columns: ['id', 'status'],
          where: 'id = ?',
          whereArgs: [enquiry.quoteOrderId],
          limit: 1,
        );
        if (rows.isNotEmpty && rows.first['status'] == 'confirmed') {
          confirmedOrderId = enquiry.quoteOrderId!;
        } else {
          final result = await _orderRepository.confirmDraft(orderId: enquiry.quoteOrderId!);
          confirmedOrderId = result.orderId;
        }
      }
    } else {
      // Solo SQLite
      final db = await AppDatabase.instance.database;
      final rows = await db.query(
        'orders',
        columns: ['id', 'status'],
        where: 'id = ?',
        whereArgs: [enquiry.quoteOrderId],
        limit: 1,
      );
      if (rows.isNotEmpty && rows.first['status'] == 'confirmed') {
        confirmedOrderId = enquiry.quoteOrderId!;
      } else {
        final result = await _orderRepository.confirmDraft(orderId: enquiry.quoteOrderId!);
        confirmedOrderId = result.orderId;
      }
    }

    // 2. Update enquiry with status='won' and convertedOrderId
    final updatedEnquiry = enquiry.copyWith(
      status: 'won',
      convertedOrderId: confirmedOrderId,
      nextAction: 'Order #ORD-$confirmedOrderId confirmed',
      updatedAt: DateTime.now(),
    );
    await updateEnquiry(updatedEnquiry);

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
    // 1. Won protection
    if (enquiry.status == 'won' || enquiry.convertedOrderId != null) {
      throw StateError('Cannot mark a won enquiry as lost.');
    }

    final cleanReason = reason.trim().isNotEmpty ? reason.trim() : 'Customer cancelled';
    final cleanNotes = notes?.trim();
    final combinedLostReason = cleanNotes != null && cleanNotes.isNotEmpty
        ? '$cleanReason - $cleanNotes'
        : cleanReason;

    // 2. Idempotency: if already lost with same reason, return existing
    if (enquiry.status == 'lost' && enquiry.lostReason == combinedLostReason) {
      return enquiry;
    }

    final updatedNotes = cleanNotes != null && cleanNotes.isNotEmpty
        ? (enquiry.notes != null && enquiry.notes!.trim().isNotEmpty
            ? '${enquiry.notes!.trim()}\n[Lost]: $cleanNotes'
            : '[Lost]: $cleanNotes')
        : enquiry.notes;

    final lostEnquiry = enquiry.copyWith(
      status: 'lost',
      lostReason: combinedLostReason,
      nextAction: 'Lost: $cleanReason',
      notes: updatedNotes,
      updatedAt: DateTime.now(),
    );

    return await updateEnquiry(lostEnquiry);
  }

  Future<CrmEnquiryItem> reopenEnquiry({
    required CrmEnquiryItem enquiry,
    DateTime? nextFollowUpAt,
    String? nextAction,
    String? notes,
  }) async {
    // 1. Won protection
    if (enquiry.status == 'won' || enquiry.convertedOrderId != null) {
      throw StateError('Cannot reopen a won enquiry.');
    }

    final followUpDate = nextFollowUpAt ?? DateTime.now().add(const Duration(days: 1));
    final action = nextAction != null && nextAction.trim().isNotEmpty
        ? nextAction.trim()
        : 'Call customer';
    final cleanNotes = notes?.trim();

    // 2. Idempotency: if already follow_up with same action and follow-up date
    if (enquiry.status == 'follow_up' &&
        enquiry.nextAction == action &&
        enquiry.nextFollowUpAt == followUpDate) {
      return enquiry;
    }

    final updatedNotes = cleanNotes != null && cleanNotes.isNotEmpty
        ? (enquiry.notes != null && enquiry.notes!.trim().isNotEmpty
            ? '${enquiry.notes!.trim()}\n[Reopened]: $cleanNotes'
            : '[Reopened]: $cleanNotes')
        : enquiry.notes;

    final reopenedEnquiry = CrmEnquiryItem(
      localId: enquiry.localId,
      cloudId: enquiry.cloudId,
      clientSyncId: enquiry.clientSyncId,
      customerId: enquiry.customerId,
      cloudCustomerId: enquiry.cloudCustomerId,
      customerName: enquiry.customerName,
      customerPhone: enquiry.customerPhone,
      category: enquiry.category,
      requirement: enquiry.requirement,
      eventDate: enquiry.eventDate,
      budgetPaise: enquiry.budgetPaise,
      location: enquiry.location,
      notes: updatedNotes,
      status: 'follow_up',
      nextAction: action,
      nextFollowUpAt: followUpDate,
      quoteOrderId: enquiry.quoteOrderId,
      convertedOrderId: enquiry.convertedOrderId,
      lostReason: null,
      createdAt: enquiry.createdAt,
      updatedAt: DateTime.now(),
      deletedAt: enquiry.deletedAt,
    );

    return await updateEnquiry(reopenedEnquiry);
  }

  // --------------------------------------------------------------------------
  // ACTIONS
  // --------------------------------------------------------------------------
  Future<void> markFollowUpDone(CrmFollowUpItem item) async {
    final mode = await _storageModeService.getCurrentMode();
    final isCloudOrWeb = kIsWeb || mode == StorageMode.cloud;

    if (item.sourceType == 'occasion') {
      if (isCloudOrWeb && item.cloudSourceId != null) {
        await _cloudOccasionRepository.markDone(
          sourceType: 'occasion',
          sourceId: item.cloudSourceId!,
          occurrenceDate: item.scheduledTime,
        );
      } else if (item.localSourceId != null) {
        await _occasionRepository.markDone(
          sourceType: 'occasion',
          sourceId: item.localSourceId!,
          occurrenceDate: item.scheduledTime,
        );
      }
    } else if (item.sourceType == 'scheduler') {
      if (isCloudOrWeb && item.cloudSourceId != null) {
        await _cloudSchedulerRepository.setStatus(
          item.cloudSourceId!,
          TaskStatus.completed,
        );
      } else if (item.localSourceId != null) {
        await _schedulerRepository.updateTaskStatus(
          item.localSourceId!,
          TaskStatus.completed,
        );
      }
    }
  }

  Future<void> snoozeFollowUp(CrmFollowUpItem item) async {
    final mode = await _storageModeService.getCurrentMode();
    final isCloudOrWeb = kIsWeb || mode == StorageMode.cloud;

    if (item.sourceType == 'occasion') {
      if (isCloudOrWeb && item.cloudSourceId != null) {
        await _cloudOccasionRepository.snoozeTomorrow(
          sourceType: 'occasion',
          sourceId: item.cloudSourceId!,
          occurrenceDate: item.scheduledTime,
        );
      } else if (item.localSourceId != null) {
        await _occasionRepository.snoozeTomorrow(
          sourceType: 'occasion',
          sourceId: item.localSourceId!,
          occurrenceDate: item.scheduledTime,
        );
      }
    }
  }

  // --------------------------------------------------------------------------
  // HELPER UTILITIES
  // --------------------------------------------------------------------------
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _computeDayLabel(DateTime today, DateTime target) {
    final tDate = DateTime(today.year, today.month, today.day);
    final targetDate = DateTime(target.year, target.month, target.day);
    final diffDays = targetDate.difference(tDate).inDays;

    if (diffDays == 0) return 'Today';
    if (diffDays == 1) return 'Tomorrow';
    if (diffDays == -1) return 'Yesterday';

    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return weekdays[target.weekday - 1];
  }
}
