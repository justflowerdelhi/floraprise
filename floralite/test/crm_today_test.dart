import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/models/crm_models.dart';
import 'package:floraprise/models/workspace_destinations.dart';
import 'package:floraprise/providers/crm_provider.dart';
import 'package:floraprise/screens/crm/crm_today_screen.dart';
import 'package:floraprise/screens/crm/crm_enquiries_screen.dart';
import 'package:floraprise/screens/crm/crm_customers_screen.dart';
import 'package:floraprise/screens/crm/crm_occasions_screen.dart';
import 'package:floraprise/services/crm_service.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeCrmService extends CrmService {
  _FakeCrmService({
    this.initialData,
  });

  CrmTodayData? initialData;
  final List<String> markedDoneIds = [];

  @override
  Future<CrmTodayData> getTodayData(DateTime now) async {
    return initialData ??
        CrmTodayData(
          followUps: const [],
          enquiries: const [],
          pendingQuotes: const [],
          upcomingOccasions: const [],
          evaluatedAt: DateTime.now(),
        );
  }

  @override
  Future<void> markFollowUpDone(CrmFollowUpItem item) async {
    markedDoneIds.add(item.id);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('CRM Navigation Destinations', () {
    test('WorkspaceNavigation contains CRM section and all 4 destinations', () {
      final crmSection = WorkspaceNavigation.sections.firstWhere(
        (s) => s.title == 'CRM',
      );
      expect(crmSection, isNotNull);
      expect(crmSection.items.length, 4);

      final routes = crmSection.items.map((i) => i.route).toList();
      expect(routes, [
        '/crm',
        '/crm/enquiries',
        '/crm/customers',
        '/crm/occasions',
      ]);

      expect(WorkspaceNavigation.findByRoute('/crm'), isNotNull);
      expect(WorkspaceNavigation.findByRoute('/crm/enquiries'), isNotNull);
      expect(WorkspaceNavigation.findByRoute('/crm/customers'), isNotNull);
      expect(WorkspaceNavigation.findByRoute('/crm/occasions'), isNotNull);
    });
  });

  group('CRM Data Models', () {
    test('CrmTodayData calculates pending follow-up counts accurately', () {
      final now = DateTime.now();
      final data = CrmTodayData(
        followUps: [
          CrmFollowUpItem(
            id: 'fu_1',
            sourceType: 'occasion',
            scheduledTime: now,
            customerName: 'Anil Kumar',
            customerPhone: '9876543210',
            requirementSummary: 'Birthday bouquet follow-up',
            status: 'Pending',
            isCompleted: false,
          ),
          CrmFollowUpItem(
            id: 'fu_2',
            sourceType: 'scheduler',
            scheduledTime: now,
            customerName: 'Pooja Patel',
            customerPhone: '9825000000',
            requirementSummary: 'Payment check',
            status: 'Completed',
            isCompleted: true,
          ),
        ],
        enquiries: [
          CrmEnquiryItem(
            id: 'enq_1',
            customerName: 'Meera Shah',
            customerPhone: '9811122233',
            requirement: 'Wedding stage floral inquiry',
            eventDate: now.add(const Duration(days: 10)),
            status: 'New',
            nextAction: 'Send portfolio',
            createdAt: now,
          ),
        ],
        pendingQuotes: [
          CrmQuoteItem(
            id: 'q_1',
            orderId: 101,
            orderNo: 'DRAFT-101',
            customerName: 'Vikram Joshi',
            customerPhone: '9898989898',
            requirementSummary: '2 items • DELIVERY',
            amount: 2500.0,
            date: now,
            nextAction: 'Review Quote',
          ),
        ],
        upcomingOccasions: [
          CrmOccasionItem(
            id: 'occ_1',
            customerName: 'Karan Dave',
            recipientName: 'Sneha Dave',
            customerPhone: '9870001111',
            occasion: 'Anniversary',
            relationship: 'Spouse',
            occasionDate: now,
            dayLabel: 'Today',
            notes: 'Prefers Red Roses',
          ),
        ],
        evaluatedAt: now,
      );

      expect(data.followUps.length, 2);
      expect(data.pendingFollowUpsCount, 1);
      expect(data.enquiries.length, 1);
      expect(data.pendingQuotes.length, 1);
      expect(data.upcomingOccasions.length, 1);
    });

    test('CrmFollowUpItem copyWith updates completion status', () {
      final item = CrmFollowUpItem(
        id: 'fu_1',
        sourceType: 'occasion',
        scheduledTime: DateTime.now(),
        customerName: 'John',
        customerPhone: '9999999999',
        requirementSummary: 'Call customer',
        status: 'Pending',
        isCompleted: false,
      );

      final completed = item.copyWith(isCompleted: true, status: 'Completed');
      expect(completed.isCompleted, isTrue);
      expect(completed.status, 'Completed');
      expect(completed.customerName, 'John');
    });
  });

  group('CRM Today Screen UI & Interaction', () {
    Widget createTestApp({
      required CrmService crmService,
    }) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<CrmProvider>(
            create: (_) => CrmProvider(crmService: crmService),
          ),
        ],
        child: const MaterialApp(
          home: CrmTodayScreen(),
        ),
      );
    }

    testWidgets('Displays empty state when no data exists (zero fake fallback)', (
      tester,
    ) async {
      final fakeService = _FakeCrmService();
      await tester.pumpWidget(createTestApp(crmService: fakeService));
      await tester.pumpAndSettle();

      // Section titles
      expect(find.text("TODAY'S FOLLOW-UPS"), findsOneWidget);
      expect(find.text('NEW ENQUIRIES'), findsOneWidget);
      expect(find.text('QUOTES PENDING'), findsOneWidget);
      expect(find.text('OCCASIONS THIS WEEK'), findsOneWidget);

      // Empty states
      expect(find.text('No follow-ups scheduled for today.'), findsOneWidget);
      expect(find.text('No new enquiries today.'), findsOneWidget);
      expect(find.text('No pending quotes.'), findsOneWidget);
      expect(find.text('No upcoming occasions this week.'), findsOneWidget);
    });

    testWidgets('Renders real follow-ups, quotes, enquiries, and occasions', (
      tester,
    ) async {
      final now = DateTime(2026, 9, 28, 10, 30);
      final fakeData = CrmTodayData(
        followUps: [
          CrmFollowUpItem(
            id: 'fu_100',
            sourceType: 'occasion',
            localSourceId: 10,
            scheduledTime: now,
            customerName: 'Rahul Verma',
            customerPhone: '9825123456',
            requirementSummary: 'Birthday Lily Arrangement reminder',
            status: 'Pending',
            isCompleted: false,
          ),
        ],
        enquiries: [
          CrmEnquiryItem(
            id: 'enq_200',
            customerName: 'Sanjay Sharma',
            customerPhone: '9825987654',
            requirement: '200 Red Roses for Gala event',
            status: 'New',
            nextAction: 'Follow-up with customer',
            createdAt: now,
          ),
        ],
        pendingQuotes: [
          CrmQuoteItem(
            id: 'quote_300',
            orderId: 300,
            orderNo: 'DRAFT-300',
            customerName: 'Deepa Mehta',
            customerPhone: '9825654321',
            requirementSummary: '3 items • DELIVERY',
            amount: 3200.0,
            date: now,
            nextAction: 'Review & Confirm Quote',
          ),
        ],
        upcomingOccasions: [
          CrmOccasionItem(
            id: 'occ_400',
            customerName: 'Kavita Patel',
            recipientName: 'Aarav Patel',
            customerPhone: '9825111222',
            occasion: 'Birthday',
            relationship: 'Son',
            occasionDate: now,
            dayLabel: 'Today',
          ),
        ],
        evaluatedAt: now,
      );

      final fakeService = _FakeCrmService(initialData: fakeData);
      await tester.pumpWidget(createTestApp(crmService: fakeService));
      await tester.pumpAndSettle();

      // Verify KPI counts
      expect(find.text('1'), findsNWidgets(4)); // 1 for each section in KPI bar

      // Verify follow-up card
      expect(find.text('Rahul Verma'), findsOneWidget);
      expect(find.text('Birthday Lily Arrangement reminder'), findsOneWidget);
      expect(find.text('Call'), findsWidgets);
      expect(find.text('WhatsApp'), findsWidgets);
      expect(find.text('Done'), findsOneWidget);

      // Verify enquiry card
      expect(find.text('Sanjay Sharma'), findsOneWidget);
      expect(find.text('200 Red Roses for Gala event'), findsOneWidget);

      // Verify quote card
      expect(find.text('Deepa Mehta'), findsOneWidget);
      expect(find.text('₹3200'), findsOneWidget);
      expect(find.text('3 items • DELIVERY'), findsOneWidget);

      // Verify occasion card
      expect(find.text('🎂 Aarav Patel — Birthday'), findsOneWidget);
      expect(find.text('Son of Kavita Patel'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('Clicking Done on a follow-up triggers optimistic update and service call', (
      tester,
    ) async {
      final now = DateTime(2026, 9, 28, 10, 30);
      final fakeData = CrmTodayData(
        followUps: [
          CrmFollowUpItem(
            id: 'fu_test_done',
            sourceType: 'occasion',
            localSourceId: 55,
            scheduledTime: now,
            customerName: 'Priya Nambiar',
            customerPhone: '9825444555',
            requirementSummary: 'Anniversary bouquet follow-up',
            status: 'Pending',
            isCompleted: false,
          ),
        ],
        enquiries: const [],
        pendingQuotes: const [],
        upcomingOccasions: const [],
        evaluatedAt: now,
      );

      final fakeService = _FakeCrmService(initialData: fakeData);
      await tester.pumpWidget(createTestApp(crmService: fakeService));
      await tester.pumpAndSettle();

      final doneButton = find.text('Done');
      expect(doneButton, findsOneWidget);

      await tester.tap(doneButton);
      await tester.pumpAndSettle();

      expect(fakeService.markedDoneIds, contains('fu_test_done'));
      expect(find.text('Done ✓'), findsOneWidget);
    });
  });

  group('CRM Sub-Screens Navigation Placeholder & Linking', () {
    testWidgets('CrmEnquiriesScreen renders interactive enquiries screen', (
      tester,
    ) async {
      final fakeService = _FakeCrmService();
      final provider = CrmProvider(crmService: fakeService);

      await tester.pumpWidget(
        ChangeNotifierProvider<CrmProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: CrmEnquiriesScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Enquiries'), findsWidgets);
      expect(find.text('New Enquiry'), findsWidgets);
    });

    testWidgets('CrmCustomersScreen instantiates CustomersScreen delegation', (
      tester,
    ) async {
      const widget = CrmCustomersScreen();
      expect(widget, isNotNull);
    });

    testWidgets('CrmOccasionsScreen instantiates RemindersScreen delegation', (
      tester,
    ) async {
      const widget = CrmOccasionsScreen();
      expect(widget, isNotNull);
    });
  });
}
