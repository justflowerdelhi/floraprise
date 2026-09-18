import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/models/fiscal_profile.dart';
import 'package:floraprise/models/gst_calculation_type.dart';
import 'package:floraprise/models/printer_models.dart';
import 'package:floraprise/models/walk_in_enums.dart';
import 'package:floraprise/models/walk_in_line_item.dart';
import 'package:floraprise/models/walk_in_session.dart';
import 'package:floraprise/managers/business_settings_manager.dart';
import 'package:floraprise/managers/pricing_manager.dart';
import 'package:floraprise/managers/walk_in_manager.dart';
import 'package:floraprise/services/printer/receipt_builder.dart';
import 'package:floraprise/services/tax_calculation_engine.dart';
import 'package:floraprise/utils/locale_formatter.dart';

class _FakeBusinessSettingsManager extends BusinessSettingsManager {
  _FakeBusinessSettingsManager(this._settings);
  final BusinessSettings _settings;

  @override
  Future<BusinessSettings> load() async => _settings;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('POS Fiscal Integration Tests', () {
    final pricingManager = PricingManager();

    test('1. India standard: INR 1000 inclusive @ 18% GST', () {
      final fiscal = CountryPresets.india();
      final List<WalkInLineItem> lines = [
        const WalkInLineItem(
          description: 'Rose Bouquet',
          quantity: 1,
          unitPricePaise: 100000, // INR 1000.00
          gstPercent: 18,
          gstCalculationType: GstCalculationType.inclusive,
        ),
      ];

      final totals = pricingManager.computeTotals(
        lines: lines,
        fiscalProfile: fiscal,
      );

      // Subtotal is net taxable base: 84746 paise
      expect(totals.subtotalPaise, 84746);
      // GST: 15254 paise
      expect(totals.gstTotalPaise, 15254);
      // Grand total: 84746 + 15254 = 100000 paise (INR 1000.00)
      expect(totals.grandTotalPaise, 100000);

      // TaxCalculationEngine breakdown
      final breakdown = TaxCalculationEngine.calculate(
        amountPaise: 100000,
        taxRatePercent: fiscal.taxRatePercent,
        isTaxInclusive: fiscal.taxInclusive,
        taxEnabled: fiscal.taxEnabled,
      );
      expect(breakdown.netAmountPaise, 84746);
      expect(breakdown.taxAmountPaise, 15254);
      expect(breakdown.totalAmountPaise, 100000);

      // Web POS payload verification
      final session = WalkInSession(
        fulfilmentType: FulfilmentType.takeAway,
        lines: lines,
      );
      final payload = WalkInManager.buildWebPosPayload(
        session: session,
        totals: totals,
        ensuredCustomer: null,
        clientSyncId: 'test-sync-101',
        now: DateTime(2026, 9, 18, 10, 0),
        fiscalProfile: fiscal,
      );
      final payloadLines = payload['lines'] as List<Map<String, dynamic>>;
      expect(payloadLines.first['line_gst_paise'], 15254);
      expect(payloadLines.first['gst_percent'], 18);
      expect(payloadLines.first['line_subtotal_paise'], 84746);
      expect(payloadLines.first['line_total_paise'], 100000);
      expect(payload['order']['grand_total_paise'], 100000);
    });

    test('2. USA standard: USD 1000 exclusive @ 8.25% Sales Tax', () {
      final fiscal = CountryPresets.usa().copyWith(
        taxEnabled: true,
        taxRatePercent: 8.25,
      );
      final List<WalkInLineItem> lines = [
        const WalkInLineItem(
          description: 'Flower Vase',
          quantity: 1,
          unitPricePaise: 100000, // USD 1000.00
          gstCalculationType: GstCalculationType.exclusive,
        ),
      ];

      final totals = pricingManager.computeTotals(
        lines: lines,
        fiscalProfile: fiscal,
      );

      // Base subtotal: 100000 paise ($1000.00)
      expect(totals.subtotalPaise, 100000);
      // Tax: 100000 * 0.0825 = 8250 paise ($82.50)
      expect(totals.gstTotalPaise, 8250);
      // Grand total with 50 paise round-off: 108250 + 50 = 108300 paise ($1083.00)
      expect(totals.roundOffPaise, 50);
      expect(totals.grandTotalPaise, 108300);

      final breakdown = TaxCalculationEngine.calculate(
        amountPaise: totals.subtotalPaise,
        taxRatePercent: fiscal.taxRatePercent,
        isTaxInclusive: fiscal.taxInclusive,
        taxEnabled: fiscal.taxEnabled,
      );
      expect(breakdown.netAmountPaise, 100000);
      expect(breakdown.taxAmountPaise, 8250);
      expect(breakdown.totalAmountPaise, 108250);

      final session = WalkInSession(
        fulfilmentType: FulfilmentType.takeAway,
        lines: lines,
      );
      final payload = WalkInManager.buildWebPosPayload(
        session: session,
        totals: totals,
        ensuredCustomer: null,
        clientSyncId: 'test-sync-102',
        now: DateTime(2026, 9, 18, 10, 0),
        fiscalProfile: fiscal,
      );
      final payloadLines = payload['lines'] as List<Map<String, dynamic>>;
      expect(payloadLines.first['line_gst_paise'], 8250);
      expect(payloadLines.first['gst_percent'], 8);
      expect(payloadLines.first['line_subtotal_paise'], 100000);
      expect(payloadLines.first['line_total_paise'], 108250);
      expect(payload['order']['grand_total_paise'], 108300);
    });

    test('3. USA fractional rate: USD 1000 exclusive @ 8.875% NYC Sales Tax', () {
      final fiscal = CountryPresets.usa().copyWith(
        taxEnabled: true,
        taxRatePercent: 8.875,
      );
      final List<WalkInLineItem> lines = [
        const WalkInLineItem(
          description: 'NYC Event Centerpiece',
          quantity: 1,
          unitPricePaise: 100000, // USD 1000.00
        ),
      ];

      final totals = pricingManager.computeTotals(
        lines: lines,
        fiscalProfile: fiscal,
      );

      expect(totals.subtotalPaise, 100000);
      // 100000 * 0.08875 = 8875 paise ($88.75)
      expect(totals.gstTotalPaise, 8875);
      // 108875 + 25 paise round off = 108900
      expect(totals.roundOffPaise, 25);
      expect(totals.grandTotalPaise, 108900);
    });

    test('4. UAE standard: AED 1050 inclusive @ 5% VAT', () {
      final fiscal = CountryPresets.uae();
      final List<WalkInLineItem> lines = [
        const WalkInLineItem(
          description: 'Luxury Orchid Pot',
          quantity: 1,
          unitPricePaise: 105000, // AED 1050.00
        ),
      ];

      final totals = pricingManager.computeTotals(
        lines: lines,
        fiscalProfile: fiscal,
      );

      // Net base: 105000 / 1.05 = 100000 paise (AED 1000.00)
      expect(totals.subtotalPaise, 100000);
      // VAT: 5000 paise (AED 50.00)
      expect(totals.gstTotalPaise, 5000);
      expect(totals.grandTotalPaise, 105000);

      final breakdown = TaxCalculationEngine.calculate(
        amountPaise: 105000,
        taxRatePercent: fiscal.taxRatePercent,
        isTaxInclusive: fiscal.taxInclusive,
        taxEnabled: fiscal.taxEnabled,
      );
      expect(breakdown.netAmountPaise, 100000);
      expect(breakdown.taxAmountPaise, 5000);
      expect(breakdown.totalAmountPaise, 105000);

      final session = WalkInSession(
        fulfilmentType: FulfilmentType.takeAway,
        lines: lines,
      );
      final payload = WalkInManager.buildWebPosPayload(
        session: session,
        totals: totals,
        ensuredCustomer: null,
        clientSyncId: 'test-sync-103',
        now: DateTime(2026, 9, 18, 10, 0),
        fiscalProfile: fiscal,
      );
      final payloadLines = payload['lines'] as List<Map<String, dynamic>>;
      expect(payloadLines.first['line_gst_paise'], 5000);
      expect(payloadLines.first['gst_percent'], 5);
      expect(payloadLines.first['line_subtotal_paise'], 100000);
      expect(payloadLines.first['line_total_paise'], 105000);
      expect(payload['order']['grand_total_paise'], 105000);
    });

    test('5. Tax disabled (taxEnabled = false) & 0% rate', () {
      final fiscal = CountryPresets.usa().copyWith(
        taxEnabled: false,
        taxRatePercent: 0,
      );
      final List<WalkInLineItem> lines = [
        const WalkInLineItem(
          description: 'Tax Free Item',
          quantity: 2,
          unitPricePaise: 50000, // $500.00 each = $1000.00
        ),
      ];

      final totals = pricingManager.computeTotals(
        lines: lines,
        fiscalProfile: fiscal,
      );

      expect(totals.subtotalPaise, 100000);
      expect(totals.gstTotalPaise, 0);
      expect(totals.grandTotalPaise, 100000);
    });

    test('6. Line item discount + Bill discount + Tax calculation', () {
      final fiscal = CountryPresets.india(); // 18% inclusive
      final List<WalkInLineItem> lines = [
        const WalkInLineItem(
          description: 'Bouquet with Line Discount',
          quantity: 2,
          unitPricePaise: 60000, // 2 * 60000 = 120000
          discountType: 'fixed',
          discountValue: 20000, // 20000 line discount => 100000 gross line subtotal
          gstPercent: 18,
          gstCalculationType: GstCalculationType.inclusive,
        ),
      ];

      // Bill discount of 10%
      final totals = pricingManager.computeTotals(
        lines: lines,
        billDiscountType: 'percentage',
        billDiscountValue: 10,
        fiscalProfile: fiscal,
      );

      // Total discount: 20000 (line) + 10000 (bill 10% of 100000) = 30000 paise
      expect(totals.discountTotalPaise, 30000);
      // Effective discounted gross: 90000 paise ($900 / ₹900)
      // Net base after bill discount: 76271 paise
      expect(totals.subtotalPaise, 76271);
      // Tax after bill discount: 13729 paise
      expect(totals.gstTotalPaise, 13729);
      // Grand total: 76271 + 13729 = 90000 paise
      expect(totals.grandTotalPaise, 90000);
    });

    test('7. Dynamic Currency formatting across regions', () {
      final india = CountryPresets.india();
      final usa = CountryPresets.usa();
      final uae = CountryPresets.uae();

      expect(LocaleFormatter.formatCurrencyWithProfile(123450, profile: india), '₹1,234.50');
      expect(LocaleFormatter.formatCurrencyWithProfile(123450, profile: usa), '\$1,234.50');
      expect(LocaleFormatter.formatCurrencyWithProfile(123450, profile: uae), 'د.إ1,234.50');

      // Active cached fallback
      BusinessSettingsManager.activeFiscalProfile = usa;
      expect(LocaleFormatter.formatCurrencyWithProfile(50000), '\$500.00');

      BusinessSettingsManager.activeFiscalProfile = india;
      expect(LocaleFormatter.formatCurrencyWithProfile(50000), '₹500.00');
    });

    test('8. Receipt Builder formats dynamic tax labels and identifiers', () async {
      final uaeProfile = CountryPresets.uae().copyWith(taxIdentifier: '100200300');
      final fakeManager = _FakeBusinessSettingsManager(
        BusinessSettings(
          shopName: 'Dubai Flowers',
          ownerName: 'Owner',
          phone: '+971501234567',
          address: 'Downtown Dubai',
          defaultDeliveryChargePaise: 0,
          minimumPreparationBufferMinutes: 60,
          gstRegistered: true,
          gstNumber: '100200300',
          fiscalProfile: uaeProfile,
        ),
      );
      final receiptBuilder = ReceiptBuilder(businessSettingsManager: fakeManager);
      final printerConfig = PrinterSettings.fromMap({});

      // Test UAE Receipt
      BusinessSettingsManager.activeFiscalProfile = uaeProfile;
      final uaePayload = {
        'invoiceNumber': 'UAE-1001',
        'dateTime': '2026-09-18 10:00:00',
        'cashier': 'Admin',
        'customerName': 'Ahmed',
        'taxLabel': 'VAT Amount',
        'items': [
          {
            'name': 'Orchid',
            'qty': 1,
            'ratePaise': 105000,
            'totalPaise': 105000,
          }
        ],
        'basicAmountPaise': 100000,
        'discountPaise': 0,
        'gstPaise': 5000,
        'grandTotalPaise': 105000,
        'paymentMode': 'Card',
      };

      final bytes = await receiptBuilder.build(
        type: PrintJobType.posBill,
        payload: uaePayload,
        settings: printerConfig,
      );
      final receiptText = latin1.decode(bytes);

      expect(receiptText.contains('POS BILL'), isTrue);
      expect(receiptText.contains('UAE-1001'), isTrue);
      expect(receiptText.contains('TRN: 100200300'), isTrue);
      expect(receiptText.contains('VAT Amount'), isTrue);
      expect(receiptText.contains('1050.00'), isTrue);

      // Reset to India default
      BusinessSettingsManager.activeFiscalProfile = CountryPresets.india();
    });
  });
}
