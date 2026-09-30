import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/data/repositories/enquiry_repository.dart';
import 'package:floraprise/models/crm_models.dart';
import 'package:floraprise/models/walk_in_enums.dart';
import 'package:floraprise/models/walk_in_line_item.dart';
import 'package:floraprise/models/walk_in_session.dart';
import 'package:floraprise/providers/crm_provider.dart';
import 'package:floraprise/screens/crm/crm_enquiries_screen.dart';
import 'package:floraprise/screens/crm/crm_mark_lost_dialog.dart';
import 'package:floraprise/screens/crm/crm_quote_preview_dialog.dart';
import 'package:floraprise/screens/crm/crm_reopen_dialog.dart';
import 'package:floraprise/services/crm_service.dart';

class _FakeLostReopenCrmService extends CrmService {
  _FakeLostReopenCrmService({
    this.enquiries = const [],
    this.draftSessions = const {},
  });

  List<CrmEnquiryItem> enquiries;
  final Map<int, WalkInSession> draftSessions;

  @override
  Future<CrmTodayData> getTodayData(DateTime now) async {
    return CrmTodayData.empty;
  }

  @override
  Future<WalkInSession?> getQuoteDraft(int draftOrderId) async {
    return draftSessions[draftOrderId];
  }

  @override
  Future<List<CrmEnquiryItem>> listEnquiries({
    String? status,
    String? query,
    DateTime? eventDate,
    int page = 1,
    int pageSize = 50,
  }) async {
    var result = List<CrmEnquiryItem>.from(enquiries);
    if (status != null && status != 'all') {
      result = result.where((e) => e.status.toLowerCase() == status.toLowerCase()).toList();
    }
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      result = result.where((e) =>
          e.customerName.toLowerCase().contains(q) ||
          e.customerPhone.toLowerCase().contains(q) ||
          e.requirement.toLowerCase().contains(q)).toList();
    }
    return result;
  }

  @override
  Future<CrmEnquiryItem> markEnquiryLost({
    required CrmEnquiryItem enquiry,
    required String reason,
    String? notes,
  }) async {
    if (enquiry.status == 'won' || enquiry.convertedOrderId != null) {
      throw StateError('Cannot mark a won enquiry as lost.');
    }
    final cleanReason = reason.trim().isNotEmpty ? reason.trim() : 'Customer cancelled';
    final cleanNotes = notes?.trim();
    final combinedLostReason = cleanNotes != null && cleanNotes.isNotEmpty
        ? '$cleanReason - $cleanNotes'
        : cleanReason;

    final updated = enquiry.copyWith(
      status: 'lost',
      lostReason: combinedLostReason,
      nextAction: 'Lost: $cleanReason',
      notes: cleanNotes != null && cleanNotes.isNotEmpty
          ? (enquiry.notes != null && enquiry.notes!.isNotEmpty
              ? '${enquiry.notes}\n[Lost]: $cleanNotes'
              : '[Lost]: $cleanNotes')
          : enquiry.notes,
      updatedAt: DateTime.now(),
    );

    enquiries = enquiries.map((e) => (e.clientSyncId == updated.clientSyncId || (e.localId != null && e.localId == updated.localId)) ? updated : e).toList();
    return updated;
  }

  @override
  Future<CrmEnquiryItem> reopenEnquiry({
    required CrmEnquiryItem enquiry,
    DateTime? nextFollowUpAt,
    String? nextAction,
    String? notes,
  }) async {
    if (enquiry.status == 'won' || enquiry.convertedOrderId != null) {
      throw StateError('Cannot reopen a won enquiry.');
    }
    final followUpDate = nextFollowUpAt ?? DateTime.now().add(const Duration(days: 1));
    final action = nextAction != null && nextAction.trim().isNotEmpty
        ? nextAction.trim()
        : 'Call customer';
    final cleanNotes = notes?.trim();

    final updated = CrmEnquiryItem(
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
      notes: cleanNotes != null && cleanNotes.isNotEmpty
          ? (enquiry.notes != null && enquiry.notes!.isNotEmpty
              ? '${enquiry.notes}\n[Reopened]: $cleanNotes'
              : '[Reopened]: $cleanNotes')
          : enquiry.notes,
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

    enquiries = enquiries.map((e) => (e.clientSyncId == updated.clientSyncId || (e.localId != null && e.localId == updated.localId)) ? updated : e).toList();
    return updated;
  }

  @override
  Future<CrmEnquiryItem> updateEnquiry(CrmEnquiryItem item) async {
    enquiries = enquiries.map((e) => (e.clientSyncId == item.clientSyncId || (e.localId != null && e.localId == item.localId)) ? item : e).toList();
    return item;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('CRM Phase 2B-4: Status Model & Lost Workflow', () {
    test('Valid statuses are exactly 5', () {
      expect(CrmEnquiryItem.validStatuses, [
        'new',
        'follow_up',
        'quote_sent',
        'won',
        'lost',
      ]);
      expect(CrmEnquiryItem.validStatuses.length, 5);
    });

    test('Marking New, Follow-up, or Quote Sent enquiry as Lost updates status, reason, next action and notes', () async {
      final service = CrmService();
      final now = DateTime.now();

      final activeEnquiry = CrmEnquiryItem(
        localId: 101,
        clientSyncId: 'sync-active-1',
        customerName: 'Ananya Roy',
        customerPhone: '9876543210',
        category: 'Wedding',
        requirement: 'Stage floral arch',
        status: 'quote_sent',
        quoteOrderId: 55,
        budgetPaise: 450000,
        createdAt: now,
      );

      final lostItem = await service.markEnquiryLost(
        enquiry: activeEnquiry,
        reason: 'Price too high',
        notes: 'Customer budget was maximum ₹3,000',
      );

      expect(lostItem.status, 'lost');
      expect(lostItem.lostReason, 'Price too high - Customer budget was maximum ₹3,000');
      expect(lostItem.nextAction, 'Lost: Price too high');
      expect(lostItem.notes, contains('[Lost]: Customer budget was maximum ₹3,000'));
      expect(lostItem.quoteOrderId, 55); // Draft link preserved
      expect(lostItem.customerName, 'Ananya Roy');
      expect(lostItem.requirement, 'Stage floral arch');
    });

    test('Reopening Lost enquiry returns status to follow_up, sets nextFollowUpAt & action, clears lostReason', () async {
      final service = CrmService();
      final now = DateTime.now();

      final lostEnquiry = CrmEnquiryItem(
        localId: 101,
        clientSyncId: 'sync-active-1',
        customerName: 'Ananya Roy',
        customerPhone: '9876543210',
        category: 'Wedding',
        requirement: 'Stage floral arch',
        status: 'lost',
        lostReason: 'Price too high',
        quoteOrderId: 55,
        budgetPaise: 450000,
        notes: '[Lost]: Customer budget was max ₹3,000',
        createdAt: now,
      );

      final scheduledFollowUp = DateTime(2026, 10, 5, 11, 30);
      final reopenedItem = await service.reopenEnquiry(
        enquiry: lostEnquiry,
        nextFollowUpAt: scheduledFollowUp,
        nextAction: 'Offer 10% festive discount',
        notes: 'Customer called back interested in budget options',
      );

      expect(reopenedItem.status, 'follow_up');
      expect(reopenedItem.lostReason, isNull);
      expect(reopenedItem.nextFollowUpAt, scheduledFollowUp);
      expect(reopenedItem.nextAction, 'Offer 10% festive discount');
      expect(reopenedItem.notes, contains('[Reopened]: Customer called back interested in budget options'));
      expect(reopenedItem.notes, contains('[Lost]: Customer budget was max ₹3,000'));
      expect(reopenedItem.quoteOrderId, 55); // Same draft quote retained
      expect(reopenedItem.localId, 101); // Same enquiry ID retained
    });

    test('Won protection: StateError thrown when marking Won enquiry as Lost or Reopening', () async {
      final service = CrmService();
      final now = DateTime.now();

      final wonEnquiry = CrmEnquiryItem(
        localId: 202,
        clientSyncId: 'sync-won-1',
        customerName: 'Karan Mehra',
        customerPhone: '9876500002',
        category: 'Birthday',
        requirement: 'Carnations and balloons',
        status: 'won',
        convertedOrderId: 777,
        createdAt: now,
      );

      expect(
        () => service.markEnquiryLost(enquiry: wonEnquiry, reason: 'Customer cancelled'),
        throwsA(isA<StateError>()),
      );

      expect(
        () => service.reopenEnquiry(enquiry: wonEnquiry),
        throwsA(isA<StateError>()),
      );
    });

    test('Idempotency: Repeated markEnquiryLost and reopenEnquiry calls return existing item safely', () async {
      final service = CrmService();
      final now = DateTime.now();

      final lostItem = CrmEnquiryItem(
        localId: 303,
        clientSyncId: 'sync-idem-1',
        customerName: 'Deepa Gupta',
        customerPhone: '9876500003',
        requirement: 'Lilies bunch',
        status: 'lost',
        lostReason: 'Event cancelled',
        createdAt: now,
      );

      // Calling markEnquiryLost with exact same reason on already lost item
      final idempotentLost = await service.markEnquiryLost(
        enquiry: lostItem,
        reason: 'Event cancelled',
      );
      expect(idempotentLost.status, 'lost');
      expect(idempotentLost.lostReason, 'Event cancelled');

      // Calling reopenEnquiry with exact same action and date
      final followUpDate = DateTime(2026, 10, 1, 10, 0);
      final reopenedItem = CrmEnquiryItem(
        localId: 303,
        clientSyncId: 'sync-idem-1',
        customerName: 'Deepa Gupta',
        customerPhone: '9876500003',
        requirement: 'Lilies bunch',
        status: 'follow_up',
        nextFollowUpAt: followUpDate,
        nextAction: 'Call customer',
        createdAt: now,
      );

      final idempotentReopen = await service.reopenEnquiry(
        enquiry: reopenedItem,
        nextFollowUpAt: followUpDate,
        nextAction: 'Call customer',
      );
      expect(idempotentReopen.status, 'follow_up');
      expect(idempotentReopen.nextAction, 'Call customer');
    });
  });

  group('CRM Phase 2B-4: SQLite Repository Lost & Reopen Persistence', () {
    late AppDatabase appDb;

    setUp(() async {
      AppDatabase.useInMemoryForTests = true;
      AppDatabase.testDatabaseName = 'test_crm_lost_reopen_${DateTime.now().microsecondsSinceEpoch}.db';
      appDb = AppDatabase.instance;
      await appDb.close();
    });

    tearDown(() async {
      await appDb.close();
      AppDatabase.useInMemoryForTests = false;
    });

    test('SQLite enquiry repository persists lost status, lostReason and Reopen transition with zero order impact', () async {
      final db = await appDb.database;
      final enqRepo = EnquiryRepository();

      final nowStr = DateTime.now().toIso8601String();
      final custId = await db.insert('customers', {
        'phone': '9988776655',
        'name': 'Suresh Raina',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      final created = await enqRepo.create(CrmEnquiryItem(
        customerId: custId,
        customerName: 'Suresh Raina',
        customerPhone: '9988776655',
        category: 'Corporate',
        requirement: 'Annual banquet flowers',
        budgetPaise: 800000,
        status: 'quote_sent',
        quoteOrderId: 12,
        createdAt: DateTime.now(),
      ));

      expect(created.localId, isNotNull);
      expect(created.status, 'quote_sent');

      // Verify no orders exist
      final orderCountBefore = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM orders')) ?? 0;
      expect(orderCountBefore, 0);

      // 1. Mark as Lost
      final updatedLost = await enqRepo.update(created.copyWith(
        status: 'lost',
        lostReason: 'Went with another florist - Competitor gave 20% discount',
        nextAction: 'Lost: Went with another florist',
      ));
      expect(updatedLost.status, 'lost');
      expect(updatedLost.lostReason, contains('Went with another florist'));

      // Check DB row
      final queriedLost = await enqRepo.getById(created.localId!);
      expect(queriedLost, isNotNull);
      expect(queriedLost!.status, 'lost');
      expect(queriedLost.lostReason, 'Went with another florist - Competitor gave 20% discount');
      expect(queriedLost.quoteOrderId, 12); // Draft remains intact

      // Check order table count remains 0 (Zero order created)
      final orderCountAfterLost = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM orders')) ?? 0;
      expect(orderCountAfterLost, 0);

      // 2. Reopen enquiry
      final reopenedFollowUp = DateTime(2026, 11, 1, 10, 0);
      final updatedReopened = CrmEnquiryItem(
        localId: queriedLost.localId,
        clientSyncId: queriedLost.clientSyncId,
        customerId: queriedLost.customerId,
        customerName: queriedLost.customerName,
        customerPhone: queriedLost.customerPhone,
        category: queriedLost.category,
        requirement: queriedLost.requirement,
        eventDate: queriedLost.eventDate,
        budgetPaise: queriedLost.budgetPaise,
        status: 'follow_up',
        nextAction: 'Follow up for next quarter gala',
        nextFollowUpAt: reopenedFollowUp,
        quoteOrderId: queriedLost.quoteOrderId,
        lostReason: null,
        createdAt: queriedLost.createdAt,
        updatedAt: DateTime.now(),
      );

      final savedReopened = await enqRepo.update(updatedReopened);
      expect(savedReopened.status, 'follow_up');
      expect(savedReopened.lostReason, isNull);

      // Verify DB row
      final queriedReopened = await enqRepo.getById(created.localId!);
      expect(queriedReopened!.status, 'follow_up');
      expect(queriedReopened.lostReason, isNull);
      expect(queriedReopened.nextAction, 'Follow up for next quarter gala');
      expect(queriedReopened.quoteOrderId, 12);

      // Verify enquiry count in DB is still exactly 1 (No duplicate rows)
      final enquiryCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM crm_enquiries')) ?? 0;
      expect(enquiryCount, 1);
    });
  });

  group('CRM Phase 2B-4: UI Dialogs & Screen Widgets', () {
    testWidgets('CrmMarkLostDialog renders reasons, note field, and submits successfully', (tester) async {
      final now = DateTime.now();
      final enquiry = CrmEnquiryItem(
        localId: 501,
        clientSyncId: 'sync-dialog-1',
        customerName: 'Kavita Rao',
        customerPhone: '9876543210',
        category: 'Wedding',
        requirement: 'Rose garland setup',
        status: 'quote_sent',
        createdAt: now,
      );

      final fakeService = _FakeLostReopenCrmService(enquiries: [enquiry]);
      final provider = CrmProvider(crmService: fakeService);

      await tester.pumpWidget(
        ChangeNotifierProvider<CrmProvider>.value(
          value: provider,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => CrmMarkLostDialog.show(context, enquiry: enquiry),
                    child: const Text('Open Mark Lost'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Mark Lost'));
      await tester.pumpAndSettle();

      expect(find.text('Mark Enquiry Lost'), findsOneWidget);
      expect(find.text('Customer: Kavita Rao • Wedding'), findsOneWidget);
      expect(find.text('Lost Reason *'), findsOneWidget);
      expect(find.text('Mark Lost'), findsOneWidget);

      // Enter a note
      await tester.enterText(find.byType(TextField), 'Price was 30% over budget');
      await tester.pumpAndSettle();

      // Tap Mark Lost button
      await tester.tap(find.widgetWithText(FilledButton, 'Mark Lost'));
      await tester.pumpAndSettle();

      // Dialog dismissed and enquiry updated to lost
      expect(find.text('Mark Enquiry Lost'), findsNothing);
      expect(fakeService.enquiries.first.status, 'lost');
      expect(fakeService.enquiries.first.lostReason, contains('Customer cancelled - Price was 30% over budget'));
    });

    testWidgets('CrmReopenDialog renders follow-up fields and reopens enquiry as follow_up', (tester) async {
      final now = DateTime.now();
      final enquiry = CrmEnquiryItem(
        localId: 502,
        clientSyncId: 'sync-dialog-2',
        customerName: 'Kavita Rao',
        customerPhone: '9876543210',
        category: 'Wedding',
        requirement: 'Rose garland setup',
        status: 'lost',
        lostReason: 'Price too high',
        createdAt: now,
      );

      final fakeService = _FakeLostReopenCrmService(enquiries: [enquiry]);
      final provider = CrmProvider(crmService: fakeService);

      await tester.pumpWidget(
        ChangeNotifierProvider<CrmProvider>.value(
          value: provider,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => CrmReopenDialog.show(context, enquiry: enquiry),
                    child: const Text('Open Reopen'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Reopen'));
      await tester.pumpAndSettle();

      expect(find.text('Reopen Enquiry'), findsOneWidget);
      expect(find.text('Customer: Kavita Rao • Wedding'), findsOneWidget);
      expect(find.text('Next Action *'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Reopen'), findsOneWidget);

      // Tap Reopen Enquiry button
      await tester.tap(find.widgetWithText(FilledButton, 'Reopen'));
      await tester.pumpAndSettle();

      // Dialog dismissed and enquiry updated to follow_up
      expect(find.text('Reopen Enquiry'), findsNothing);
      expect(fakeService.enquiries.first.status, 'follow_up');
      expect(fakeService.enquiries.first.lostReason, isNull);
    });

    testWidgets('CrmEnquiriesScreen displays Lost badge and Reopen button for lost enquiries', (tester) async {
      final now = DateTime.now();
      final lostEnquiry = CrmEnquiryItem(
        localId: 601,
        clientSyncId: 'sync-lost-card',
        customerName: 'Pooja Hegde',
        customerPhone: '9876500004',
        category: 'Anniversary',
        requirement: 'Red rose heart box',
        status: 'lost',
        lostReason: 'Event cancelled due to weather',
        createdAt: now,
      );

      final fakeService = _FakeLostReopenCrmService(enquiries: [lostEnquiry]);
      final provider = CrmProvider(crmService: fakeService);

      await tester.pumpWidget(
        ChangeNotifierProvider<CrmProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: CrmEnquiriesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify customer card rendered
      expect(find.text('Pooja Hegde'), findsOneWidget);
      expect(find.text('Lost: Event cancelled due to weather'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Reopen'), findsOneWidget);
      expect(find.text('Mark Lost'), findsNothing);
    });

    testWidgets('CrmQuotePreviewDialog displays Lost banner and Reopen Enquiry button when enquiry is lost', (tester) async {
      final now = DateTime.now();
      final lostEnquiry = CrmEnquiryItem(
        localId: 701,
        clientSyncId: 'sync-lost-quote',
        customerName: 'Sameer Sen',
        customerPhone: '9876500005',
        category: 'Reception',
        requirement: 'Floral entryway',
        status: 'lost',
        lostReason: 'Budget mismatch',
        quoteOrderId: 88,
        createdAt: now,
      );

      const session = WalkInSession(
        draftOrderId: 88,
        customerName: 'Sameer Sen',
        customerPhone: '9876500005',
        fulfilmentType: FulfilmentType.takeAway,
        lines: [
          WalkInLineItem(
            description: 'Floral Entryway Setup',
            unitPricePaise: 250000,
            quantity: 1,
            discountPaise: 0,
            gstPercent: 18,
          ),
        ],
      );

      final fakeService = _FakeLostReopenCrmService(
        enquiries: [lostEnquiry],
        draftSessions: {88: session},
      );
      final provider = CrmProvider(crmService: fakeService);

      await tester.pumpWidget(
        ChangeNotifierProvider<CrmProvider>.value(
          value: provider,
          child: MaterialApp(
            home: CrmQuotePreviewDialog(enquiry: lostEnquiry),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Lost banner and Reopen button are present
      expect(find.text('Enquiry Marked as Lost'), findsOneWidget);
      expect(find.text('Reason: Budget mismatch'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Reopen Enquiry'), findsOneWidget);
      expect(find.text('Mark Won & Convert'), findsNothing);
      expect(find.text('Edit Quote'), findsNothing);
    });
  });
}
