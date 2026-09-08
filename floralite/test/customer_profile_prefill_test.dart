import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/l10n/app_localizations.dart';
import 'package:floraprise/screens/customer_profile_screen.dart';

void main() {
  Future<RouteSettings?> pumpAndTapNewOrder(
    WidgetTester tester, {
    required String customerId,
  }) async {
    RouteSettings? pushedSettings;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        onGenerateRoute: (settings) {
          if (settings.name == '/walkin-sales') {
            pushedSettings = settings;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const SizedBox.shrink(),
            );
          }
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const Scaffold(),
          );
        },
        home: CustomerProfileScreen(
          customerId: customerId,
          name: 'Asha Rao',
          phone: '9876501234',
          lastOrder: '01/09/2026',
          birthday: '05-12',
          pendingPayment: '₹0',
          totalOrders: 7,
          rewardPoints: 20,
          lifetimeRewardPoints: 120,
          redeemedRewardPoints: 15,
          lastRewardActivity: '01/09/2026',
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('New Order'));
    await tester.tap(find.text('New Order'));
    await tester.pumpAndSettle();

    return pushedSettings;
  }

  testWidgets('New Order preserves local customer ID, name, and phone', (tester) async {
    final settings = await pumpAndTapNewOrder(tester, customerId: '42');

    expect(settings, isNotNull);
    expect(settings!.name, '/walkin-sales');
    final args = settings.arguments as Map<String, dynamic>;
    expect(args['prefillCustomerId'], '42');
    expect(args['prefillCustomerName'], 'Asha Rao');
    expect(args['prefillCustomerPhone'], '9876501234');
  });

  testWidgets('New Order preserves cloud customer GUID, name, and phone', (tester) async {
    final settings = await pumpAndTapNewOrder(
      tester,
      customerId: '7f9c8f32-8b12-4e2f-95d8-4d3f0c6d9f1a',
    );

    expect(settings, isNotNull);
    expect(settings!.name, '/walkin-sales');
    final args = settings.arguments as Map<String, dynamic>;
    expect(
      args['prefillCustomerId'],
      '7f9c8f32-8b12-4e2f-95d8-4d3f0c6d9f1a',
    );
    expect(args['prefillCustomerName'], 'Asha Rao');
    expect(args['prefillCustomerPhone'], '9876501234');
  });
}
