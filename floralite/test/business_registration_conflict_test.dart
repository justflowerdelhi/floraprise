import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:floraprise/models/storage_mode.dart';
import 'package:floraprise/providers/auth_provider.dart';
import 'package:floraprise/providers/storage_mode_provider.dart';
import 'package:floraprise/screens/business_registration_screen.dart';
import 'package:floraprise/services/mobile_auth_service.dart';
import 'package:floraprise/services/storage_mode_service.dart';

class _FakeStorageModeService extends StorageModeService {
  @override
  Future<StorageMode?> getCurrentMode() async => StorageMode.cloud;
}

class _FailingRegisterAuthService extends MobileAuthService {
  _FailingRegisterAuthService({required this.errorCode, required this.errorMessage});

  final String errorCode;
  final String errorMessage;

  @override
  Future<MobileAuthPayload> register({
    required String companyName,
    required String ownerName,
    required String mobile,
    required String address,
    required String city,
    required String email,
    required String password,
  }) async {
    throw MobileAuthServiceException(errorCode, errorMessage);
  }
}

void main() {
  group('AuthProvider registration error mapping', () {
    test('maps PHONE_ALREADY_IN_USE to clear user-friendly message', () async {
      final authService = _FailingRegisterAuthService(
        errorCode: 'PHONE_ALREADY_IN_USE',
        errorMessage: 'Phone number already in use. Please use a different phone number.',
      );
      final provider = AuthProvider(authService);

      final result = await provider.register(
        companyName: 'New Blossom',
        ownerName: 'Jane',
        mobile: '9876543210',
        address: 'MG Road',
        city: 'Delhi',
        email: 'jane@example.com',
        password: 'Password123!',
      );

      expect(result, isFalse);
      expect(provider.errorCode, equals('PHONE_ALREADY_IN_USE'));
      expect(
        provider.friendlyMessage,
        equals('Phone number already in use. Please use a different phone number.'),
      );
    });

    test('maps EMAIL_ALREADY_IN_USE to clear user-friendly message', () async {
      final authService = _FailingRegisterAuthService(
        errorCode: 'EMAIL_ALREADY_IN_USE',
        errorMessage: 'This email is already registered. Please use a different email or log in.',
      );
      final provider = AuthProvider(authService);

      final result = await provider.register(
        companyName: 'New Blossom',
        ownerName: 'Jane',
        mobile: '9876543210',
        address: 'MG Road',
        city: 'Delhi',
        email: 'jane@example.com',
        password: 'Password123!',
      );

      expect(result, isFalse);
      expect(provider.errorCode, equals('EMAIL_ALREADY_IN_USE'));
      expect(
        provider.friendlyMessage,
        equals('This email is already registered.'),
      );
    });
  });

  group('BusinessRegistrationScreen duplicate phone handling', () {
    testWidgets(
      'displays duplicate phone dialog and switches to login on action',
      (tester) async {
        final authService = _FailingRegisterAuthService(
          errorCode: 'PHONE_ALREADY_IN_USE',
          errorMessage: 'Phone number already in use. Please use a different phone number.',
        );
        final authProvider = AuthProvider(authService);
        final storageProvider = StorageModeProvider(_FakeStorageModeService());

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
              ChangeNotifierProvider<StorageModeProvider>.value(value: storageProvider),
            ],
            child: const MaterialApp(
              home: BusinessRegistrationScreen(),
            ),
          ),
        );

        // Switch to "Create Account" tab
        await tester.tap(find.text('Create Account'));
        await tester.pumpAndSettle();

        // Fill registration form
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Business Name'),
          'New Blossom',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Owner Name'),
          'Jane Doe',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Mobile'),
          '9876543210',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Address'),
          'MG Road',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'City'),
          'Delhi',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'jane@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'Password123!',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm Password'),
          'Password123!',
        );

        // Tap Register button
        final registerButton = find.widgetWithText(FilledButton, 'Register');
        await tester.ensureVisible(registerButton);
        await tester.pumpAndSettle();
        await tester.tap(registerButton);
        await tester.pumpAndSettle();

        // Dialog should be shown with clear message
        expect(find.text('Phone Number Already Registered'), findsOneWidget);
        expect(
          find.text('Phone number already in use. Please use a different phone number.'),
          findsOneWidget,
        );

        // Tap "Log In Instead"
        await tester.tap(find.text('Log In Instead'));
        await tester.pumpAndSettle();

        // Should switch to "Sign In" mode and prefill mobile
        expect(find.text('Sign in to your Floraprise account'), findsOneWidget);
        expect(find.text('9876543210'), findsOneWidget);
      },
    );
  });
}
