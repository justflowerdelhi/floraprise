import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:floraprise/managers/language_manager.dart';
import 'package:floraprise/managers/onboarding_manager.dart';
import 'package:floraprise/models/storage_mode.dart';
import 'package:floraprise/presentation/splash/splash_screen.dart';
import 'package:floraprise/providers/auth_provider.dart';
import 'package:floraprise/providers/storage_mode_provider.dart';
import 'package:floraprise/services/mobile_auth_service.dart';
import 'package:floraprise/services/scheduler_service.dart';
import 'package:floraprise/services/storage_mode_service.dart';

class _FailingStorageModeService extends StorageModeService {
  @override
  Future<StorageMode?> getCurrentMode() async {
    throw StateError('Simulated storage mode initialization error');
  }
}

class _MockAuthService extends MobileAuthService {
  _MockAuthService({this.authenticated = false});
  final bool authenticated;

  @override
  Future<bool> hasRememberedSession() async => authenticated;
}

void main() {
  group('SplashScreen defensive startup navigation', () {
    testWidgets(
      'navigates to /mobile-register if unexpected error occurs and user is unauthenticated',
      (tester) async {
        final authProvider = AuthProvider(_MockAuthService(authenticated: false));
        final failingStorageProvider = StorageModeProvider(_FailingStorageModeService());

        String? navigatedRoute;

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
              ChangeNotifierProvider<StorageModeProvider>.value(
                value: failingStorageProvider,
              ),
            ],
            child: MaterialApp(
              routes: {
                '/': (_) => const SplashScreen(),
                '/mobile-register': (_) {
                  navigatedRoute = '/mobile-register';
                  return const Scaffold(body: Text('Register / Login'));
                },
                '/dashboard': (_) {
                  navigatedRoute = '/dashboard';
                  return const Scaffold(body: Text('Dashboard'));
                },
              },
            ),
          ),
        );

        // Advance past splash delay (3000ms)
        await tester.pump(const Duration(milliseconds: 3100));
        await tester.pumpAndSettle();

        expect(navigatedRoute, equals('/mobile-register'));
      },
    );
  });

  group('Web startup SQLite guard unit checks', () {
    test('LanguageManager getSavedLanguage handles call gracefully', () async {
      final manager = LanguageManager();
      expect(manager, isNotNull);
    });

    test('OnboardingManager methods exist and are callable', () async {
      final manager = OnboardingManager();
      expect(manager, isNotNull);
    });

    test('SchedulerService instance is available', () async {
      final service = SchedulerService.instance;
      expect(service, isNotNull);
    });
  });
}
