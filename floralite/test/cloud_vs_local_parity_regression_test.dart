import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:floraprise/data/repositories/cloud_customer_repository.dart';
import 'package:floraprise/data/repositories/cloud_product_repository.dart';
import 'package:floraprise/data/repositories/customer_repository.dart';
import 'package:floraprise/data/repositories/product_repository.dart';
import 'package:floraprise/providers/cloud_product_provider.dart';
import 'package:floraprise/screens/day_closing_screen.dart';
import 'package:floraprise/services/customer_cloud_lookup_service.dart';
import 'package:floraprise/widgets/non_cloud_report_banner.dart';

void main() {
  group('Cloud vs Local Parity Regression Tests', () {
    test('CloudProductProvider filters, sorts, and toggles favorites correctly', () async {
      final mockRepo = _MockCloudProductRepository();
      final provider = CloudProductProvider(mockRepo);

      await provider.load();
      expect(provider.products.length, 3);

      // Category filter
      provider.setCategory('Flowers');
      expect(provider.products.length, 2);
      expect(provider.products.first.name, 'Lily');

      // Reset category and sort price high to low
      provider.setCategory('all');
      provider.setSort(ProductSort.priceHighToLow);
      expect(provider.products.first.name, 'Bouquet Deluxe');
      expect(provider.products.first.retailPrice, 500.0);

      // Toggle favorite
      provider.toggleFavorite('prod-1');
      expect(provider.isFavorite('prod-1'), isTrue);

      provider.setFavoriteOnly(true);
      expect(provider.products.length, 1);
      expect(provider.products.first.id, 'prod-1');
    });

    test('CustomerCloudLookupService checks cache first then falls back to cloud', () async {
      final mockCustomerRepo = _MockCustomerRepository();
      bool searchedCloud = false;

      final service = CustomerCloudLookupService(
        customerRepository: mockCustomerRepo,
        findCloudCustomerByPhone: (phone) async {
          searchedCloud = true;
          return const CloudCustomer(
            id: 'cloud-cust-1',
            name: 'Cloud Alice',
            phone: '9876543210',
          );
        },
        isOnline: () async => true,
        currentCompanyId: () async => '12345678-1234-4234-a234-123456789012',
      );

      final result = await service.lookupByPhone('9876543210');
      expect(searchedCloud, isTrue);
      expect(result, isNotNull);
      expect(result!.name, 'Cloud Alice');
    });

    test('DayCloseCashBookTotals calculates cash totals correctly', () {
      final totals = dayCloseCashBookTotalsFromTransactions(
        const [],
        includeCashSales: true,
        includeCashExpenses: true,
      );

      expect(totals.cashSales, 0);
      expect(totals.cashExpenses, 0);
    });

    testWidgets('NonCloudReportBanner displays primary device notice in Cloud mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NonCloudReportBanner(reportTitle: 'Top Customers Report'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(NonCloudReportBanner), findsOneWidget);
      expect(find.text('Top Customers Report is Primary Device Only'), findsOneWidget);
    });
  });
}

class _MockCloudProductRepository extends CloudProductRepository {
  @override
  Future<List<CloudProduct>> listProducts({
    String query = '',
    String? category,
    bool? trackInventory,
    bool showActive = true,
    bool showInactive = false,
  }) async {
    return [
      _sampleProduct('prod-1', 'Rose', 'Flowers', 50.0),
      _sampleProduct('prod-2', 'Lily', 'Flowers', 100.0),
      _sampleProduct('prod-3', 'Bouquet Deluxe', 'Finished Products', 500.0),
    ];
  }

  @override
  Future<List<CloudCategory>> listCategories() async => const [];

  CloudProduct _sampleProduct(String id, String name, String cat, double price) {
    final now = DateTime.now();
    return CloudProduct(
      id: id,
      companyId: 'company-1',
      name: name,
      sku: 'SKU-$id',
      barcode: id,
      manufacturerBarcode: null,
      internalBarcode: null,
      brand: null,
      description: null,
      category: cat,
      categoryId: null,
      unitOfMeasure: 'Stem',
      retailPrice: price,
      costPrice: price * 0.5,
      wholesalePrice: null,
      weddingEventPrice: null,
      taxCategory: 'Standard',
      trackInventory: true,
      trackBatch: false,
      stockQuantity: 10,
      minimumStockLevel: 2,
      reorderLevel: 5,
      isActive: true,
      shelfLifeDays: null,
      expiryAlertDays: null,
      temperatureNotes: null,
      createdAtUtc: now,
      updatedAtUtc: now,
    );
  }
}

class _MockCustomerRepository extends CustomerRepository {
  CustomerRecord? _cached;

  @override
  Future<CustomerRecord?> findByPhone(
    String phone, {
    String? companyId,
    bool includeDeleted = false,
    bool includeUnassigned = true,
  }) async {
    return _cached;
  }

  @override
  Future<CustomerRecord> upsertFromCloud({
    required String cloudCustomerId,
    required String cloudCompanyId,
    required String phone,
    required String name,
    String notes = '',
    String birthdayMd = '',
    String anniversaryMd = '',
    String company = '',
    String department = '',
  }) async {
    _cached = CustomerRecord(
      id: 1,
      phone: phone,
      name: name,
      createdAt: DateTime.now().toIso8601String(),
      cloudCustomerId: cloudCustomerId,
      cloudCompanyId: cloudCompanyId,
    );
    return _cached!;
  }
}
