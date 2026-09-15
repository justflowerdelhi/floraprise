import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:floraprise/data/repositories/order_repository.dart';
import 'package:floraprise/models/gst_calculation_type.dart';
import 'package:floraprise/models/walk_in_enums.dart';
import 'package:floraprise/models/walk_in_line_item.dart';
import 'package:floraprise/models/walk_in_session.dart';
import 'package:floraprise/services/web_draft_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('WebDraftStorageService saves, retrieves, searches, and deletes drafts', () async {
    final storage = WebDraftStorageService();

    const session = WalkInSession(
      fulfilmentType: FulfilmentType.takeAway,
      customerName: 'Aarav Patel',
      customerPhone: '9876543210',
      occasion: 'Birthday',
      lines: [
        WalkInLineItem(
          productId: 10,
          cloudProductId: 'cp-10',
          description: 'Orchid Bouquet',
          quantity: 2,
          unitPricePaise: 40000,
          gstPercent: 12,
          gstCalculationType: GstCalculationType.inclusive,
          source: 'manual',
        ),
      ],
    );

    const totals = OrderTotals(
      subtotalPaise: 80000,
      gstTotalPaise: 8571,
      discountTotalPaise: 0,
      roundOffPaise: 0,
      grandTotalPaise: 80000,
    );

    // 1. Upsert draft
    final draftId = await storage.upsertDraft(
      session: session,
      totals: totals,
      customerId: 1,
      cloudCustomerId: 'cloud-cust-1',
    );
    expect(draftId, isPositive);

    // 2. Count drafts
    final count = await storage.countDraftOrders();
    expect(count, 1);

    // 3. List drafts
    final list = await storage.listDraftOrders();
    expect(list.length, 1);
    expect(list.first.customerName, 'Aarav Patel');
    expect(list.first.customerPhone, '9876543210');
    expect(list.first.itemCount, 2);
    expect(list.first.grandTotalPaise, 80000);

    // 4. Search drafts
    final searched = await storage.listDraftOrders(query: 'Aarav');
    expect(searched.length, 1);
    final missed = await storage.listDraftOrders(query: 'NonExistent');
    expect(missed, isEmpty);

    // 5. Retrieve draft by ID
    final retrieved = await storage.getDraftById(draftId);
    expect(retrieved, isNotNull);
    expect(retrieved!.customerName, 'Aarav Patel');
    expect(retrieved.lines.length, 1);
    expect(retrieved.lines.first.description, 'Orchid Bouquet');
    expect(retrieved.lines.first.quantity, 2);

    // 6. Get latest draft
    final latest = await storage.getLatestDraft(FulfilmentType.takeAway);
    expect(latest, isNotNull);
    expect(latest!.customerPhone, '9876543210');

    // 7. Delete draft
    await storage.deleteDraft(draftId);
    final afterDelete = await storage.listDraftOrders();
    expect(afterDelete, isEmpty);
    final afterCount = await storage.countDraftOrders();
    expect(afterCount, 0);
  });
}
