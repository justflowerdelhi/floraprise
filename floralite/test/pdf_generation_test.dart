import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/managers/business_settings_manager.dart';
import 'package:floraprise/models/order_workspace_models.dart';
import 'package:floraprise/services/pdf/pdf_bill_builder.dart';
import 'package:floraprise/services/pdf/pdf_delivery_slip_builder.dart';
import 'package:floraprise/services/pdf/pdf_document_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sampleBusiness = BusinessSettings(
    shopName: 'Floraprise Boutique & Gifts',
    ownerName: 'Priya Sharma',
    address: '123 Floral Garden Avenue, MG Road, Bengaluru, Karnataka 560001',
    phone: '+91 9876543210',
    gstRegistered: true,
    gstNumber: '29ABCDE1234F1Z5',
    defaultDeliveryChargePaise: 5000,
    minimumPreparationBufferMinutes: 30,
  );

  OrderDetailHeader createSampleHeader({
    int id = 101,
    String orderNo = 'FP-2026-101',
    String customerName = 'Rahul Sharma',
    String customerPhone = '9876543210',
    String recipientName = 'Rahul Sharma',
    String recipientPhone = '9876543210',
    String address = '45 Palm Grove, Indiranagar, Bengaluru 560038',
    int grandTotalPaise = 150000,
    int paidAmountPaise = 150000,
    int discountPaise = 10000,
    int deliveryFeePaise = 5000,
    int taxPaise = 7500,
    int roundOffPaise = 0,
    String status = 'confirmed',
    String? deliveryName,
    String? deliveryPhone,
    String specialInstructions = '',
    String cardMessage = '',
    DateTime? scheduledDeliveryAt,
  }) {
    return OrderDetailHeader(
      id: id,
      cloudOrderId: null,
      orderNo: orderNo,
      status: status,
      customerName: customerName,
      customerPhone: customerPhone,
      recipientName: recipientName,
      recipientPhone: recipientPhone,
      fulfilmentType: 'delivery',
      source: 'pos',
      grandTotalPaise: grandTotalPaise,
      subtotalPaise: grandTotalPaise - taxPaise - deliveryFeePaise + discountPaise,
      discountTotalPaise: discountPaise,
      gstTotalPaise: taxPaise,
      deliveryChargesPaise: deliveryFeePaise,
      roundOffPaise: roundOffPaise,
      address: address,
      specialInstructions: specialInstructions,
      createdAt: DateTime(2026, 9, 27, 10, 30),
      scheduledAt: scheduledDeliveryAt ?? DateTime(2026, 9, 27, 16, 0),
      occasion: 'Birthday',
      deliverySlot: '16:00 - 18:00',
      cardMessage: cardMessage,
      isPaid: paidAmountPaise >= grandTotalPaise ? 1 : 0,
      paidAmountPaise: paidAmountPaise,
      deliveryName: deliveryName,
    );
  }

  OrderDetailBundle createSampleBundle({
    OrderDetailHeader? header,
    List<Map<String, Object?>>? lines,
    List<Map<String, Object?>>? payments,
    String? receiptStatus = 'printed',
  }) {
    final h = header ?? createSampleHeader();
    return OrderDetailBundle(
      header: h,
      lines: lines ??
          [
            {
              'description': 'Red Rose Bouquet (12 Stems)',
              'qty': 1,
              'unit_price_paise': 80000,
              'line_total_paise': 80000,
              'discount_paise': 0,
            },
            {
              'description': 'Belgian Chocolate Box',
              'qty': 2,
              'unit_price_paise': 35000,
              'line_total_paise': 70000,
              'discount_paise': 0,
            },
          ],
      payments: payments ??
          [
            {
              'payment_method': 'upi',
              'amount_paise': 150000,
              'created_at': DateTime(2026, 9, 27, 10, 32).toIso8601String(),
            }
          ],
      timeline: const [],
      schedulerTasks: const [],
      inventoryTransactions: const [],
      receiptStatus: receiptStatus,
      whatsappStatus: null,
      relayInfo: const {},
      corporateInfo: const {},
      marketplaceInfo: const {},
    );
  }

  group('Feature #4 — Bill & Delivery Slip PDF Generation', () {
    final pdfService = PdfDocumentService();
    const billBuilder = PdfBillBuilder();
    const deliverySlipBuilder = PdfDeliverySlipBuilder();

    test('1. Generates valid Bill PDF for single line item', () async {
      final header = createSampleHeader(grandTotalPaise: 50000, paidAmountPaise: 50000);
      final bundle = createSampleBundle(
        lines: [
          {
            'description': 'Classic Orchid Bunch',
            'qty': 1,
            'unit_price_paise': 50000,
            'line_total_paise': 50000,
          }
        ],
        payments: [
          {'payment_method': 'cash', 'amount_paise': 50000}
        ],
      );

      final bytes = await pdfService.generateBillPdf(
        header: header,
        bundle: bundle,
        business: sampleBusiness,
      );

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
      // Standard PDF magic header check "%PDF-"
      expect(String.fromCharCodes(bytes.sublist(0, 5)), equals('%PDF-'));
    });

    test('2. Generates valid Bill PDF for multiple line items with item discounts', () async {
      final header = createSampleHeader(
        grandTotalPaise: 240000,
        paidAmountPaise: 240000,
        discountPaise: 20000,
      );
      final bundle = createSampleBundle(
        lines: [
          {
            'description': 'Dutch Tulips Bouquet',
            'qty': 2,
            'unit_price_paise': 100000,
            'line_total_paise': 180000,
            'discount_paise': 20000,
          },
          {
            'description': 'Glass Vase',
            'qty': 1,
            'unit_price_paise': 60000,
            'line_total_paise': 60000,
          },
        ],
      );

      final bytes = await pdfService.generateBillPdf(
        header: header,
        bundle: bundle,
        business: sampleBusiness,
      );

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.sublist(0, 5)), equals('%PDF-'));
    });

    test('3. Generates Bill PDF with delivery charge, GST/tax, and round-off', () async {
      final header = createSampleHeader(
        grandTotalPaise: 157500,
        paidAmountPaise: 157500,
        deliveryFeePaise: 10000,
        taxPaise: 7500,
        roundOffPaise: -50,
      );
      final bundle = createSampleBundle();

      final bytes = await billBuilder.build(
        business: sampleBusiness,
        header: header,
        bundle: bundle,
      );

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.sublist(0, 5)), equals('%PDF-'));
    });

    test('4. Generates Bill PDF with Fully Paid status badge', () async {
      final header = createSampleHeader(
        grandTotalPaise: 100000,
        paidAmountPaise: 100000,
      );
      final bundle = createSampleBundle(payments: [
        {'payment_method': 'upi', 'amount_paise': 100000}
      ]);

      final bytes = await pdfService.generateBillPdf(
        header: header,
        bundle: bundle,
        business: sampleBusiness,
      );

      expect(bytes, isNotEmpty);
    });

    test('5. Generates Bill PDF with Unpaid status badge', () async {
      final header = createSampleHeader(
        grandTotalPaise: 100000,
        paidAmountPaise: 0,
      );
      final bundle = createSampleBundle(payments: []);

      final bytes = await pdfService.generateBillPdf(
        header: header,
        bundle: bundle,
        business: sampleBusiness,
      );

      expect(bytes, isNotEmpty);
    });

    test('6. Generates Bill PDF with Partially Paid status badge and balance amount', () async {
      final header = createSampleHeader(
        grandTotalPaise: 200000,
        paidAmountPaise: 80000,
      );
      final bundle = createSampleBundle(payments: [
        {'payment_method': 'cash', 'amount_paise': 80000}
      ]);

      final bytes = await pdfService.generateBillPdf(
        header: header,
        bundle: bundle,
        business: sampleBusiness,
      );

      expect(bytes, isNotEmpty);
    });

    test('7. Generates Bill PDF with multiple split payments', () async {
      final header = createSampleHeader(
        grandTotalPaise: 300000,
        paidAmountPaise: 300000,
      );
      final bundle = createSampleBundle(payments: [
        {'payment_method': 'cash', 'amount_paise': 100000, 'created_at': '2026-09-27 10:30'},
        {'payment_method': 'upi', 'amount_paise': 100000, 'created_at': '2026-09-27 10:31'},
        {'payment_method': 'card', 'amount_paise': 100000, 'created_at': '2026-09-27 10:32'},
      ]);

      final bytes = await pdfService.generateBillPdf(
        header: header,
        bundle: bundle,
        business: sampleBusiness,
      );

      expect(bytes, isNotEmpty);
    });

    test('8. Handles extremely long customer name, address, and notes gracefully', () async {
      final header = createSampleHeader(
        customerName: 'Shri Dr. Vijayaraghavan Ramachandran Krishnamoorthy III, Senior Botanist',
        customerPhone: '+91 9999988888, ext 102',
        address: 'Penthouse Apartment #402, Block C, Grand Majestic Palms Luxury Enclave, Near Outer Ring Road Junction, Sarjapur Main Road, Bengaluru, Karnataka, India - 560103',
        specialInstructions: 'Please ensure careful temperature controlled delivery. Ring the service doorbell twice upon arrival and hand over exclusively to reception or resident.',
        cardMessage: 'Wishing you the grandest and most prosperous 50th Golden Jubilee Birthday! May your path always be lined with fresh blooms and continuous joy.',
      );
      final bundle = createSampleBundle();

      final bytes = await pdfService.generateBillPdf(
        header: header,
        bundle: bundle,
        business: sampleBusiness,
      );

      expect(bytes, isNotEmpty);
    });

    test('9. Generates Bill PDF from POS payload map (Take Away / Pickup Later / POS)', () async {
      final posPayload = {
        'invoiceNumber': 'POS-2026-0042',
        'dateTime': '2026-09-27 11:15:00',
        'customerName': 'Pooja Hegde',
        'customerPhone': '9812345678',
        'items': [
          {'name': 'Sunflower Posy', 'qty': 2, 'ratePaise': 30000, 'totalPaise': 60000},
          {'name': 'Greeting Card', 'qty': 1, 'ratePaise': 10000, 'totalPaise': 10000},
        ],
        'basicAmountPaise': 70000,
        'discountPaise': 5000,
        'deliveryChargePaise': 0,
        'gstPaise': 3250,
        'taxLabel': 'GST Amount',
        'roundOffPaise': -250,
        'grandTotalPaise': 68000,
        'paymentMode': 'Split',
        'paymentSummary': [
          {'method': 'Cash', 'amountPaise': 30000},
          {'method': 'UPI', 'amountPaise': 38000},
        ],
        'paidPaise': 68000,
        'outstandingPaise': 0,
      };

      final bytes = await pdfService.generateBillPdfFromPayload(
        posPayload,
        business: sampleBusiness,
      );

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.sublist(0, 5)), equals('%PDF-'));
    });

    test('10. Generates multi-page Bill PDF with 30+ items without layout breakdown', () async {
      final manyLines = List.generate(
        35,
        (i) => {
          'description': 'Product Item #${i + 1} - Premium Floral Arrangement Deluxe Special Edition',
          'qty': (i % 3) + 1,
          'unit_price_paise': 25000,
          'line_total_paise': ((i % 3) + 1) * 25000,
          'discount_paise': 0,
        },
      );
      final totalPaise = manyLines.fold<int>(0, (sum, item) => sum + (item['line_total_paise'] as int));
      final header = createSampleHeader(
        grandTotalPaise: totalPaise,
        paidAmountPaise: totalPaise,
      );
      final bundle = createSampleBundle(lines: manyLines);

      final bytes = await pdfService.generateBillPdf(
        header: header,
        bundle: bundle,
        business: sampleBusiness,
      );

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(3000));
    });

    test('11. Generates valid Delivery Slip PDF with recipient, address, driver, and checklist', () async {
      final header = createSampleHeader(
        orderNo: 'FP-DEL-900',
        customerName: 'Siddharth Roy',
        customerPhone: '9876500001',
        address: 'Villa 14, Palm Meadows, Whitefield, Bengaluru 560066',
        deliveryName: 'Ramesh Kumar (Van #3)',
        deliveryPhone: '9900112233',
        specialInstructions: 'Call before arriving. Gate security code is #4012.',
        cardMessage: 'Happy Anniversary Mom & Dad! With love from Sid & Priya.',
        scheduledDeliveryAt: DateTime(2026, 9, 27, 17, 30),
      );
      final bundle = createSampleBundle(
        lines: [
          {'description': '50 Red Roses in Heart Shape Box', 'qty': 1, 'notes': 'Fresh morning harvest'},
          {'description': '1kg Chocolate Truffle Cake', 'qty': 1, 'notes': 'Eggless'},
          {'description': 'Handwritten Greeting Card', 'qty': 1},
        ],
      );

      final bytes = await deliverySlipBuilder.build(
        business: sampleBusiness,
        header: header,
        bundle: bundle,
      );

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.sublist(0, 5)), equals('%PDF-'));
    });

    test('12. Generates Delivery Slip PDF from POS delivery payload map', () async {
      final deliveryPayload = {
        'orderNo': 'DEL-2026-888',
        'deliveryTime': '2026-09-27T15:00:00.000',
        'recipientName': 'Sunita Desai',
        'recipientPhone': '9845012345',
        'senderName': 'Anand Verma',
        'senderPhone': '9810392755',
        'address': 'Flat 304, Green Heights, 12th Main, Koramangala 4th Block',
        'landmark': 'Opposite Sony World Signal',
        'pinCode': '560034',
        'deliveryInstructions': 'Leave at door if no answer',
        'messageCardIncluded': true,
        'cardMessage': 'Best wishes on your promotion!',
        'deliveryAssociateName': 'Deepak (Rider)',
        'items': [
          {'name': 'Mixed Carnations Bunch', 'qty': 1},
          {'name': 'Celebration Helium Balloon', 'qty': 2},
        ],
      };

      final bytes = await pdfService.generateDeliverySlipPdfFromPayload(
        deliveryPayload,
        business: sampleBusiness,
      );

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.sublist(0, 5)), equals('%PDF-'));
    });

    test('13. Generates Delivery Slip PDF with multi-item checklist (20+ items)', () async {
      final manyDeliveryLines = List.generate(
        25,
        (i) => {
          'description': 'Decoration Asset / Flower Batch #${i + 1}',
          'qty': 5,
        },
      );
      final header = createSampleHeader();
      final bundle = createSampleBundle(lines: manyDeliveryLines);

      final bytes = await pdfService.generateDeliverySlipPdf(
        header: header,
        bundle: bundle,
        business: sampleBusiness,
      );

      expect(bytes, isNotEmpty);
    });

    test('14. Formatting currency accurately formats paise to rupees', () {
      expect(PdfBillBuilder.formatCurrency(100, 'Rs.'), equals('Rs. 1.00'));
      expect(PdfBillBuilder.formatCurrency(150050, 'Rs.'), equals('Rs. 1500.50'));
      expect(PdfBillBuilder.formatCurrency(0, 'Rs.'), equals('Rs. 0.00'));
      expect(PdfBillBuilder.formatCurrency(-250, 'Rs.'), equals('-Rs. 2.50'));
    });
  });
}
