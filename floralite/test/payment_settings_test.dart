import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/managers/business_settings_manager.dart';
import 'package:floraprise/managers/payment_settings_manager.dart';
import 'package:floraprise/screens/payment_settings_screen.dart';
import 'package:floraprise/widgets/upi_qr_widget.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class FakePaymentSettingsManager extends PaymentSettingsManager {
  FakePaymentSettingsManager({this.initialSettings = const PaymentSettings()});

  final PaymentSettings initialSettings;
  PaymentSettings? savedSettings;

  @override
  Future<PaymentSettings> load() async {
    return initialSettings;
  }

  @override
  Future<void> saveLocalPaymentSettings({
    required bool cashEnabled,
    required bool upiEnabled,
    required String upiId,
    required String upiMerchantName,
    required bool cardEnabled,
    required bool hasCardMachine,
    required String cardTerminalId,
    bool onlineEnabled = false,
  }) async {
    savedSettings = initialSettings.copyWith(
      cashEnabled: cashEnabled,
      upiEnabled: upiEnabled,
      upiId: upiId,
      upiMerchantName: upiMerchantName,
      cardEnabled: cardEnabled,
      hasCardMachine: hasCardMachine,
      cardTerminalId: cardTerminalId,
      onlineEnabled: onlineEnabled,
    );
  }
}

class FakeBusinessSettingsManager extends BusinessSettingsManager {
  @override
  Future<BusinessSettings> load() async {
    return const BusinessSettings(
      shopName: 'Rose Boutique',
      ownerName: 'Florist',
      phone: '9999999999',
      address: 'Test Street',
      defaultDeliveryChargePaise: 0,
      minimumPreparationBufferMinutes: 60,
      gstRegistered: false,
      gstNumber: '',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    AppDatabase.useInMemoryForTests = true;
  });

  tearDownAll(() async {
    await AppDatabase.instance.close();
    AppDatabase.useInMemoryForTests = false;
  });

  group('PaymentSettings Model Tests', () {
    test('default payment settings values', () {
      const settings = PaymentSettings();
      expect(settings.cashEnabled, isTrue);
      expect(settings.upiEnabled, isTrue);
      expect(settings.upiId, isEmpty);
      expect(settings.cardEnabled, isTrue);
      expect(settings.hasCardMachine, isFalse);
      expect(settings.cardTerminalId, isEmpty);
      expect(settings.onlineEnabled, isFalse);
      expect(settings.onlineGatewayType, 'Razorpay');
      expect(settings.upiQrString, isEmpty);
    });

    test('upiQrString formats correctly with UPI ID and payee name', () {
      const settings = PaymentSettings(
        upiId: 'flowerboutique@icici',
        upiMerchantName: 'Floral & Blooms',
      );
      expect(
        settings.upiQrString,
        'upi://pay?pa=flowerboutique@icici&pn=Floral%20%26%20Blooms&cu=INR',
      );
    });

    test('copyWith updates fields immutably', () {
      const settings = PaymentSettings();
      final updated = settings.copyWith(
        cashEnabled: false,
        upiId: 'shop@upi',
        hasCardMachine: true,
        cardTerminalId: 'TERM-99',
      );

      expect(updated.cashEnabled, isFalse);
      expect(updated.upiId, 'shop@upi');
      expect(updated.hasCardMachine, isTrue);
      expect(updated.cardTerminalId, 'TERM-99');
      expect(settings.cashEnabled, isTrue);
    });
  });

  group('UpiQrWidget Widget Tests', () {
    testWidgets('renders placeholder when UPI ID is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UpiQrWidget(
              upiId: '',
              merchantName: '',
            ),
          ),
        ),
      );

      expect(find.text('Enter UPI ID to generate QR'), findsOneWidget);
    });
  });

  group('PaymentSettingsScreen Widget Tests', () {
    testWidgets('renders all florist payment method cards and toggles', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeManager = FakePaymentSettingsManager(
        initialSettings: const PaymentSettings(
          cashEnabled: true,
          upiEnabled: true,
          upiId: 'florist@upi',
          upiMerchantName: 'Rose Boutique',
          cardEnabled: true,
          hasCardMachine: true,
          cardTerminalId: 'TERM-01',
          onlineEnabled: false,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PaymentSettingsScreen(
            paymentSettingsManager: fakeManager,
            businessSettingsManager: FakeBusinessSettingsManager(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify Header and Cards
      expect(find.text('Payment Settings'), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget);
      expect(find.text('UPI / QR Code'), findsOneWidget);
      expect(find.text('Card Payments'), findsOneWidget);
      expect(find.text('Online Payments'), findsOneWidget);
      expect(find.text('Save Payment Settings'), findsOneWidget);

      // Verify populated fields
      expect(find.text('florist@upi'), findsOneWidget);
      expect(find.text('TERM-01'), findsOneWidget);

      // Tap Save
      await tester.tap(find.text('Save Payment Settings'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(fakeManager.savedSettings, isNotNull);
      expect(fakeManager.savedSettings!.upiId, 'florist@upi');
      expect(fakeManager.savedSettings!.cardTerminalId, 'TERM-01');
    });
  });
}
