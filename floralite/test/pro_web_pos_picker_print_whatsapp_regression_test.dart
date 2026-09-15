import 'package:floraprise/data/repositories/cloud_product_repository.dart';
import 'package:floraprise/data/repositories/inventory_repository.dart';
import 'package:floraprise/data/repositories/product_repository.dart';
import 'package:floraprise/managers/business_settings_manager.dart';
import 'package:floraprise/models/gst_calculation_type.dart';
import 'package:floraprise/services/printer/web_receipt_print_service.dart';
import 'package:floraprise/utils/whatsapp_phone_utils.dart';
import 'package:floraprise/widgets/product_picker_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

CloudProduct _testCloudProduct({
  required String id,
  required String name,
  required String sku,
  double retailPrice = 50.0,
  double costPrice = 30.0,
  int stockQuantity = 25,
  int minimumStockLevel = 5,
  bool trackInventory = true,
  bool isActive = true,
  String? barcode = '8901234567890',
  String? manufacturerBarcode,
  String? internalBarcode,
  String category = 'Flowers',
  String unitOfMeasure = 'Stem',
}) {
  return CloudProduct(
    id: id,
    companyId: 'company-guid-1',
    name: name,
    sku: sku,
    barcode: barcode,
    manufacturerBarcode: manufacturerBarcode,
    internalBarcode: internalBarcode,
    brand: null,
    description: null,
    category: category,
    categoryId: null,
    unitOfMeasure: unitOfMeasure,
    retailPrice: retailPrice,
    costPrice: costPrice,
    wholesalePrice: null,
    weddingEventPrice: null,
    taxCategory: 'Standard',
    trackInventory: trackInventory,
    trackBatch: false,
    stockQuantity: stockQuantity,
    minimumStockLevel: minimumStockLevel,
    reorderLevel: 0,
    isActive: isActive,
    shelfLifeDays: null,
    expiryAlertDays: null,
    temperatureNotes: null,
    createdAtUtc: DateTime.utc(2026, 9, 1),
    updatedAtUtc: null,
  );
}

class _MockBusinessSettingsManager extends BusinessSettingsManager {
  @override
  Future<BusinessSettings> load() async {
    return const BusinessSettings(
      shopName: 'Bloom Boutique',
      ownerName: 'Alice Florist',
      phone: '+919876543210',
      address: '123 Flower Market, New Delhi',
      gstRegistered: true,
      gstNumber: '07AAAAA0000A1Z5',
      defaultDeliveryChargePaise: 5000,
      minimumPreparationBufferMinutes: 30,
    );
  }
}

void main() {
  group('Floraprise Pro Web POS Product Picker Regression Tests', () {
    test('1. Product picker builds rows from cloud catalogue products when inventory is empty', () {
      final cloudProducts = [
        _testCloudProduct(
          id: '11111111-2222-3333-4444-555555555555',
          name: 'Red Dutch Rose',
          sku: 'ROSE-RED',
          retailPrice: 50.0,
          costPrice: 25.0,
          stockQuantity: 25,
          unitOfMeasure: 'Stem',
        ),
      ];

      final rows = productPickerRowsFromCloudInventory(
        const <InventoryProductRecord>[],
        cloudProducts,
      );

      expect(rows.length, 1);
      final product = rows.first;
      expect(product.name, 'Red Dutch Rose');
      expect(product.sku, 'ROSE-RED');
      expect(product.cloudProductId, '11111111-2222-3333-4444-555555555555');
      expect(product.sellingPricePaise, 5000);
      expect(product.purchasePricePaise, 2500);
      expect(product.currentQty, 25);
      expect(product.defaultUnit, 'Stem');
      expect(productPickerAvailabilityText(product), 'Stock: 25 Stems');
    });

    test('2. Product picker enriches cloud catalogue products with inventory stock and details when present', () {
      const cloudId = '22222222-3333-4444-5555-666666666666';
      final inventoryProducts = [
        const InventoryProductRecord(
          productId: 101,
          cloudProductId: cloudId,
          name: 'White Lily (Custom)',
          category: 'Premium Flowers',
          unit: 'Bunch',
          sku: 'LILY-WHT-01',
          barcode: '8909999999999',
          manufacturerBarcode: '8909999999999',
          internalBarcode: 'FP-8888',
          trackInventory: true,
          gstPercent: 5,
          gstCalculationType: GstCalculationType.inclusive,
          currentQty: 42,
          minQty: 8,
        ),
      ];
      final cloudProducts = [
        _testCloudProduct(
          id: cloudId,
          name: 'White Lily',
          sku: 'LILY-WHT-01',
          retailPrice: 150.0,
          costPrice: 90.0,
          stockQuantity: 10,
        ),
      ];

      final rows = productPickerRowsFromCloudInventory(
        inventoryProducts,
        cloudProducts,
      );

      expect(rows.length, 1);
      final product = rows.first;
      expect(product.id, 101);
      expect(product.currentQty, 42);
      expect(product.minQty, 8);
      expect(product.sellingPricePaise, 15000);
      expect(product.purchasePricePaise, 9000);
      expect(product.cloudProductId, cloudId);
      expect(product.gstPercent, 5);
    });

    test('3. Product picker falls back to cloudProduct.stockQuantity when inventory stock record is absent', () {
      final cloudProducts = [
        _testCloudProduct(
          id: '33333333-4444-5555-6666-777777777777',
          name: 'Blue Orchid',
          sku: 'ORCHID-BLU',
          retailPrice: 85.0,
          stockQuantity: 14,
          minimumStockLevel: 4,
          unitOfMeasure: 'Stem',
        ),
      ];

      final rows = productPickerRowsFromCloudInventory(
        const <InventoryProductRecord>[],
        cloudProducts,
      );

      final product = rows.first;
      expect(product.currentQty, 14);
      expect(product.minQty, 4);
      expect(productPickerAvailabilityText(product), 'Stock: 14 Stems');
    });

    test('4. Product picker marks out-of-stock cloud products non-selectable when trackInventory is true', () {
      final cloudProducts = [
        _testCloudProduct(
          id: '44444444-5555-6666-7777-888888888888',
          name: 'Sold Out Sunflower',
          sku: 'SUNFLOWER-0',
          stockQuantity: 0,
          trackInventory: true,
        ),
      ];

      final rows = productPickerRowsFromCloudInventory(
        const <InventoryProductRecord>[],
        cloudProducts,
      );

      final product = rows.first;
      expect(productPickerIsOutOfStock(product), isTrue);
      expect(productPickerCanSelect(product), isFalse);
      expect(productPickerAvailabilityText(product), 'Out of Stock');
    });

    test('5. Product picker allows untracked inventory products to be selected even if stock quantity is zero', () {
      final cloudProducts = [
        _testCloudProduct(
          id: '55555555-6666-7777-8888-999999999999',
          name: 'Gift Wrapping Service',
          sku: 'SVC-WRAP',
          stockQuantity: 0,
          trackInventory: false,
        ),
      ];

      final rows = productPickerRowsFromCloudInventory(
        const <InventoryProductRecord>[],
        cloudProducts,
      );

      final product = rows.first;
      expect(productPickerIsOutOfStock(product), isFalse);
      expect(productPickerCanSelect(product), isTrue);
      expect(productPickerAvailabilityText(product), '');
    });

    test('6. ProductRepository lookupProductBySearchPriority executes safely on Web without invoking SQLite database', () async {
      final repo = ProductRepository();
      // On non-empty or empty search string, verify it does not throw SQLite UnsupportedError
      final result = await repo.lookupProductBySearchPriority('');
      expect(result, isNull);
    });
  });

  group('Floraprise Pro Web Receipt Printing Regression Tests', () {
    final printService = WebReceiptPrintService(
      businessSettingsManager: _MockBusinessSettingsManager(),
    );

    test('7. WebReceiptPrintService formats POS Bill HTML containing store header, address, phone, and GSTIN', () async {
      final payload = <String, dynamic>{
        'invoiceNumber': 'INV-1001',
        'dateTime': '2026-09-14 11:30',
        'cashier': 'John Doe',
        'customerName': 'Pooja Sharma',
        'customerPhone': '9876543210',
        'items': <Map<String, dynamic>>[],
        'grandTotalPaise': 50000,
      };

      final html = await printService.buildPosBillHtml(payload);

      expect(html, contains('Bloom Boutique'));
      expect(html, contains('123 Flower Market, New Delhi'));
      expect(html, contains('Phone: +919876543210'));
      expect(html, contains('GSTIN: 07AAAAA0000A1Z5'));
      expect(html, contains('POS BILL'));
      expect(html, contains('#INV-1001'));
      expect(html, contains('Cashier:'));
      expect(html, contains('John Doe'));
      expect(html, contains('Pooja Sharma (9876543210)'));
    });

    test('8. WebReceiptPrintService formats POS Bill HTML containing line items with names, quantities, rates, and amounts', () async {
      final payload = <String, dynamic>{
        'invoiceNumber': 'INV-1002',
        'items': [
          {
            'name': 'Red Rose Bouquet',
            'qty': 2,
            'ratePaise': 150000,
            'totalPaise': 300000,
          },
          {
            'name': 'Chocolate Box',
            'qty': 1,
            'ratePaise': 50000,
            'totalPaise': 50000,
          },
        ],
        'grandTotalPaise': 350000,
      };

      final html = await printService.buildPosBillHtml(payload);

      expect(html, contains('Red Rose Bouquet'));
      expect(html, contains('₹1500.00'));
      expect(html, contains('₹3000.00'));
      expect(html, contains('Chocolate Box'));
      expect(html, contains('₹500.00'));
    });

    test('9. WebReceiptPrintService formats POS Bill HTML containing basic amount, discount, GST, grand total, and payment breakdown', () async {
      final payload = <String, dynamic>{
        'invoiceNumber': 'INV-1003',
        'basicAmountPaise': 300000,
        'discountPaise': 30000,
        'gstPaise': 13500,
        'grandTotalPaise': 283500,
        'paymentSummary': [
          {'method': 'Cash', 'amountPaise': 200000},
          {'method': 'UPI', 'amountPaise': 83500},
        ],
        'paidPaise': 283500,
        'outstandingPaise': 0,
        'rewardPointsEarned': 50,
        'rewardClosingBalance': 120,
      };

      final html = await printService.buildPosBillHtml(payload);

      expect(html, contains('Basic Amount:'));
      expect(html, contains('₹3000.00'));
      expect(html, contains('Discount:'));
      expect(html, contains('-₹300.00'));
      expect(html, contains('GST Amount:'));
      expect(html, contains('₹135.00'));
      expect(html, contains('Grand Total:'));
      expect(html, contains('₹2835.00'));
      expect(html, contains('Payment Summary:'));
      expect(html, contains('Cash:'));
      expect(html, contains('₹2000.00'));
      expect(html, contains('UPI:'));
      expect(html, contains('₹835.00'));
      expect(html, contains('Paid:'));
      expect(html, contains('Points Earned:'));
      expect(html, contains('+50'));
      expect(html, contains('Closing Balance:'));
      expect(html, contains('120 pts'));
    });

    test('10. WebReceiptPrintService formats Delivery Challan HTML with recipient, sender, instructions, and checklist', () async {
      final payload = <String, dynamic>{
        'orderNo': 'DEL-999',
        'deliveryTime': '2026-09-14 16:00',
        'recipientName': 'Rohit Kumar',
        'recipientPhone': '9811122233',
        'address': 'Flat 402, Sunshine Heights',
        'landmark': 'Near City Hospital',
        'pinCode': '110001',
        'senderName': 'Ananya Sen',
        'senderPhone': '9899988877',
        'deliveryInstructions': 'Please do not ring bell, leave at door.',
        'items': [
          {'name': 'Birthday Grand Basket', 'qty': 1},
        ],
      };

      final html = await printService.buildDeliverySlipHtml(payload);

      expect(html, contains('DELIVERY CHALLAN'));
      expect(html, contains('#DEL-999'));
      expect(html, contains('Rohit Kumar'));
      expect(html, contains('9811122233'));
      expect(html, contains('Flat 402, Sunshine Heights'));
      expect(html, contains('Near City Hospital'));
      expect(html, contains('PIN: 110001'));
      expect(html, contains('Ananya Sen'));
      expect(html, contains('Please do not ring bell, leave at door.'));
      expect(html, contains('PRODUCT CHECKLIST:'));
      expect(html, contains('[ ] Birthday Grand Basket'));
    });

    test('12. WebReceiptPrintService formats POS Bill HTML with Round Off and Change due', () async {
      final payload = <String, dynamic>{
        'invoiceNumber': 'INV-1004',
        'basicAmountPaise': 19950,
        'roundOffPaise': 50,
        'grandTotalPaise': 20000,
        'paymentSummary': [
          {'method': 'Cash', 'amountPaise': 50000},
        ],
        'paidPaise': 50000,
        'changePaise': 30000,
      };

      final html = await printService.buildPosBillHtml(payload);

      expect(html, contains('Round Off:'));
      expect(html, contains('+₹0.50'));
      expect(html, contains('Grand Total:'));
      expect(html, contains('₹200.00'));
      expect(html, contains('Change:'));
      expect(html, contains('₹300.00'));
    });
  });

  group('Floraprise Pro Web WhatsApp URI Regression Tests', () {
    test('11. WhatsAppPhoneUtils builds valid wa.me and fallback URLs with message encoding and handles invalid phone numbers', () {
      const phone = '9876543210';
      const message = 'Floraprise POS Receipt\nOrder #1234\nGrand Total: ₹500.00';

      final uri = WhatsAppPhoneUtils.buildUri(phone, message: message);
      expect(uri, isNotNull);
      expect(uri!.scheme, 'https');
      expect(uri.host, 'wa.me');
      expect(uri.path, '/919876543210');
      expect(uri.queryParameters['text'], message);

      final fallback = WhatsAppPhoneUtils.buildFallbackUri(phone, message: message);
      expect(fallback, isNotNull);
      expect(fallback!.scheme, 'https');
      expect(fallback.host, 'api.whatsapp.com');
      expect(fallback.path, '/send');
      expect(fallback.queryParameters['phone'], '919876543210');
      expect(fallback.queryParameters['text'], message);

      // Validation check for empty / invalid numbers
      expect(WhatsAppPhoneUtils.normalize(''), isNull);
      expect(WhatsAppPhoneUtils.normalize('abc'), isNull);
      expect(WhatsAppPhoneUtils.buildUri(''), isNull);
      expect(WhatsAppPhoneUtils.buildFallbackUri(''), isNull);
    });

    test('13. WhatsAppPhoneUtils normalizes various Indian phone formats including +91, 0 prefix, spaces, and hyphens', () {
      expect(WhatsAppPhoneUtils.normalize('+91 98765 43210'), '+919876543210');
      expect(WhatsAppPhoneUtils.normalize('09876543210'), '+919876543210');
      expect(WhatsAppPhoneUtils.normalize('98765-43210'), '+919876543210');
      expect(WhatsAppPhoneUtils.normalize('+919876543210'), '+919876543210');
      expect(WhatsAppPhoneUtils.normalize(''), isNull);
      expect(WhatsAppPhoneUtils.buildUri('09876543210')?.path, '/919876543210');
      expect(WhatsAppPhoneUtils.buildUri('+91 98765 43210')?.path, '/919876543210');
    });
  });
}
