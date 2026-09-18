import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/models/fiscal_profile.dart';
import 'package:floraprise/models/subscription.dart';
import 'package:floraprise/providers/subscription_provider.dart';
import 'package:floraprise/screens/backup_restore_screen.dart';
import 'package:floraprise/screens/subscription_screen.dart';
import 'package:floraprise/services/subscription_service.dart';
import 'package:provider/provider.dart';

class _MockActiveSubscriptionProvider extends SubscriptionProvider {
  _MockActiveSubscriptionProvider() : super(SubscriptionService());

  @override
  bool get isLoading => false;

  @override
  SubscriptionState get state => SubscriptionState.active;

  @override
  bool get blocksBusinessAccess => false;

  @override
  SubscriptionAccess get access => SubscriptionAccess(
        record: SubscriptionRecord(
          status: SubscriptionState.active,
          plan: SubscriptionPlan.annual,
          purchaseToken: 'test_token',
          expiryDate: DateTime(2027, 7, 1),
          graceEndDate: DateTime(2027, 7, 31),
          lastVerification: DateTime(2026, 7, 1),
          offlineExpiry: DateTime(2026, 7, 4),
          lastAppVersion: '1.0.0',
        ),
        state: SubscriptionState.active,
        requiresInternet: false,
        clockTamperingDetected: false,
      );
}

void main() {
  group('Country-Based Subscription Pricing Models', () {
    test('India (IN) plans have correct prices, symbols, and durations', () {
      final plans = SubscriptionPlans.forCountry('IN');
      expect(plans.length, 4);

      final trial = plans.firstWhere((p) => p.plan == SubscriptionPlan.trial);
      expect(trial.durationDays, 7);
      expect(trial.pricePaise, 0);
      expect(trial.priceLabel, '₹0');
      expect(trial.currencyCode, 'INR');
      expect(trial.currencySymbol, '₹');

      final quarterly =
          plans.firstWhere((p) => p.plan == SubscriptionPlan.quarterly);
      expect(quarterly.durationDays, 90);
      expect(quarterly.pricePaise, 499900);
      expect(quarterly.priceLabel, '₹4,999');
      expect(quarterly.currencyCode, 'INR');
      expect(quarterly.currencySymbol, '₹');

      final halfYearly =
          plans.firstWhere((p) => p.plan == SubscriptionPlan.halfYearly);
      expect(halfYearly.durationDays, 180);
      expect(halfYearly.pricePaise, 899900);
      expect(halfYearly.priceLabel, '₹8,999');
      expect(halfYearly.currencyCode, 'INR');
      expect(halfYearly.currencySymbol, '₹');

      final annual = plans.firstWhere((p) => p.plan == SubscriptionPlan.annual);
      expect(annual.durationDays, 365);
      expect(annual.pricePaise, 1499900);
      expect(annual.priceLabel, '₹14,999');
      expect(annual.currencyCode, 'INR');
      expect(annual.currencySymbol, '₹');
      expect(annual.recommended, isTrue);
    });

    test('USA (US) plans have correct prices, symbols, and durations', () {
      final plans = SubscriptionPlans.forCountry('US');
      expect(plans.length, 4);

      final trial = plans.firstWhere((p) => p.plan == SubscriptionPlan.trial);
      expect(trial.durationDays, 7);
      expect(trial.pricePaise, 0);
      expect(trial.priceLabel, r'$0');
      expect(trial.currencyCode, 'USD');
      expect(trial.currencySymbol, r'$');

      final quarterly =
          plans.firstWhere((p) => p.plan == SubscriptionPlan.quarterly);
      expect(quarterly.durationDays, 90);
      expect(quarterly.pricePaise, 17900);
      expect(quarterly.priceLabel, r'$179');
      expect(quarterly.currencyCode, 'USD');
      expect(quarterly.currencySymbol, r'$');

      final halfYearly =
          plans.firstWhere((p) => p.plan == SubscriptionPlan.halfYearly);
      expect(halfYearly.durationDays, 180);
      expect(halfYearly.pricePaise, 32900);
      expect(halfYearly.priceLabel, r'$329');
      expect(halfYearly.currencyCode, 'USD');
      expect(halfYearly.currencySymbol, r'$');

      final annual = plans.firstWhere((p) => p.plan == SubscriptionPlan.annual);
      expect(annual.durationDays, 365);
      expect(annual.pricePaise, 59900);
      expect(annual.priceLabel, r'$599');
      expect(annual.currencyCode, 'USD');
      expect(annual.currencySymbol, r'$');
      expect(annual.recommended, isTrue);
    });

    test('UAE (AE) plans have correct prices, symbols, and durations', () {
      final plans = SubscriptionPlans.forCountry('AE');
      expect(plans.length, 4);

      final trial = plans.firstWhere((p) => p.plan == SubscriptionPlan.trial);
      expect(trial.durationDays, 7);
      expect(trial.pricePaise, 0);
      expect(trial.priceLabel, 'AED 0');
      expect(trial.currencyCode, 'AED');
      expect(trial.currencySymbol, 'AED');

      final quarterly =
          plans.firstWhere((p) => p.plan == SubscriptionPlan.quarterly);
      expect(quarterly.durationDays, 90);
      expect(quarterly.pricePaise, 64900);
      expect(quarterly.priceLabel, 'AED 649');
      expect(quarterly.currencyCode, 'AED');
      expect(quarterly.currencySymbol, 'AED');

      final halfYearly =
          plans.firstWhere((p) => p.plan == SubscriptionPlan.halfYearly);
      expect(halfYearly.durationDays, 180);
      expect(halfYearly.pricePaise, 119900);
      expect(halfYearly.priceLabel, 'AED 1,199');
      expect(halfYearly.currencyCode, 'AED');
      expect(halfYearly.currencySymbol, 'AED');

      final annual = plans.firstWhere((p) => p.plan == SubscriptionPlan.annual);
      expect(annual.durationDays, 365);
      expect(annual.pricePaise, 219900);
      expect(annual.priceLabel, 'AED 2,199');
      expect(annual.currencyCode, 'AED');
      expect(annual.currencySymbol, 'AED');
      expect(annual.recommended, isTrue);
    });

    test('Missing / unconfigured country code falls back to India defaults', () {
      for (final input in [null, '', '   ', 'XYZ', 'GB', 'DE']) {
        final plans = SubscriptionPlans.forCountry(input);
        expect(plans, equals(SubscriptionPlans.all));

        final quarterly =
            plans.firstWhere((p) => p.plan == SubscriptionPlan.quarterly);
        expect(quarterly.pricePaise, 499900);
        expect(quarterly.priceLabel, '₹4,999');
      }
    });

    test('SubscriptionPlans.forProfile resolves correctly with CountryPresets', () {
      expect(
        SubscriptionPlans.forProfile(CountryPresets.india())[1].priceLabel,
        '₹4,999',
      );
      expect(
        SubscriptionPlans.forProfile(CountryPresets.usa())[1].priceLabel,
        r'$179',
      );
      expect(
        SubscriptionPlans.forProfile(CountryPresets.uae())[1].priceLabel,
        'AED 649',
      );
      expect(
        SubscriptionPlans.forProfile(null)[1].priceLabel,
        '₹4,999',
      );
    });

    test('paidForCountry returns only quarterly, halfYearly, and annual', () {
      final paidUS = SubscriptionPlans.paidForCountry('US');
      expect(paidUS.length, 3);
      expect(paidUS.map((p) => p.plan), [
        SubscriptionPlan.quarterly,
        SubscriptionPlan.halfYearly,
        SubscriptionPlan.annual,
      ]);
    });
  });

  group('SubscriptionScreen Country-Aware Rendering', () {
    testWidgets('renders India pricing and savings correctly', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SubscriptionProvider>(
          create: (_) => _MockActiveSubscriptionProvider(),
          child: MaterialApp(
            routes: {'/backup-restore': (_) => const BackupRestoreScreen()},
            home: SubscriptionScreen(fiscalProfile: CountryPresets.india()),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('₹4,999'), findsOneWidget);
      expect(find.text('₹8,999'), findsOneWidget);
      expect(find.text('₹14,999'), findsOneWidget);
      expect(
        find.text('Save ₹999 compared to renewing Quarterly twice.'),
        findsOneWidget,
      );
    });

    testWidgets('renders USA pricing and savings correctly', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SubscriptionProvider>(
          create: (_) => _MockActiveSubscriptionProvider(),
          child: MaterialApp(
            routes: {'/backup-restore': (_) => const BackupRestoreScreen()},
            home: SubscriptionScreen(fiscalProfile: CountryPresets.usa()),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(r'$179'), findsOneWidget);
      expect(find.text(r'$329'), findsOneWidget);
      expect(find.text(r'$599'), findsOneWidget);
      expect(
        find.text('Save \$29 compared to renewing Quarterly twice.'),
        findsOneWidget,
      );
    });

    testWidgets('renders UAE pricing and savings correctly', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SubscriptionProvider>(
          create: (_) => _MockActiveSubscriptionProvider(),
          child: MaterialApp(
            routes: {'/backup-restore': (_) => const BackupRestoreScreen()},
            home: SubscriptionScreen(fiscalProfile: CountryPresets.uae()),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('AED 649'), findsOneWidget);
      expect(find.text('AED 1,199'), findsOneWidget);
      expect(find.text('AED 2,199'), findsOneWidget);
      expect(
        find.text('Save AED 99 compared to renewing Quarterly twice.'),
        findsOneWidget,
      );
    });
  });
}
