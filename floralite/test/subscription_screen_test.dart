import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/models/subscription.dart';
import 'package:floraprise/providers/subscription_provider.dart';
import 'package:floraprise/screens/backup_restore_screen.dart';
import 'package:floraprise/screens/subscription_screen.dart';
import 'package:floraprise/services/subscription_service.dart';
import 'package:provider/provider.dart';

class _LockedSubscriptionProvider extends SubscriptionProvider {
  _LockedSubscriptionProvider() : super(SubscriptionService());

  @override
  bool get isLoading => false;

  @override
  SubscriptionState get state => SubscriptionState.locked;

  @override
  bool get blocksBusinessAccess => true;

  @override
  SubscriptionAccess get access => SubscriptionAccess(
        record: SubscriptionRecord(
          status: SubscriptionState.locked,
          plan: SubscriptionPlan.halfYearly,
          purchaseToken: 'token',
          expiryDate: DateTime(2026, 7, 1),
          graceEndDate: DateTime(2026, 7, 31),
          lastVerification: DateTime(2026, 7, 1),
          offlineExpiry: DateTime(2026, 7, 4),
          lastAppVersion: '1.0.0',
        ),
        state: SubscriptionState.locked,
        requiresInternet: false,
        clockTamperingDetected: false,
      );
}

void main() {
  testWidgets('locked screen shows expired trial actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<SubscriptionProvider>(
        create: (_) => _LockedSubscriptionProvider(),
        child: MaterialApp(
          routes: {
            '/backup-restore': (_) => const BackupRestoreScreen(),
          },
          home: const SubscriptionScreen(),
        ),
      ),
    );

    expect(find.text('Your Free Trial Has Expired'), findsOneWidget);
    expect(find.textContaining('Your business data is safe'), findsOneWidget);
    expect(find.text('Subscribe Now'), findsOneWidget);
    expect(find.text('Restore License'), findsOneWidget);
    expect(find.text('Exit'), findsOneWidget);
    expect(find.text('Contact Support'), findsOneWidget);
  });
}
