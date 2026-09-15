import 'dart:convert';

import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/l10n/app_localizations.dart';
import 'package:floraprise/models/storage_mode.dart';
import 'package:floraprise/providers/storage_mode_provider.dart';
import 'package:floraprise/services/storage_mode_service.dart';
import 'package:floraprise/widgets/app_header.dart';
import 'package:floraprise/widgets/business_identity.dart';
import 'package:floraprise/widgets/floraprise_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await AppDatabase.instance.close();
    final path = await getDatabasesPath();
    await deleteDatabase('$path/floraprise.db');
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('AppHeader - Cloud Globe Indicator & Shop Name', () {
    testWidgets('does not expose onboarding metadata as business identity subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BusinessIdentity(
              name: 'Sunflower Studios',
              subtitle: 'Registered from mobile onboarding',
            ),
          ),
        ),
      );

      expect(find.text('Sunflower Studios'), findsOneWidget);
      expect(find.text('Registered from mobile onboarding'), findsNothing);
    });

    testWidgets('In Cloud mode: renders globe visual indicator and displays authenticated company name', (tester) async {
      await tester.runAsync(() async {
        final storageService = StorageModeService();
        await storageService.setMode(StorageMode.cloud);

        const secureStorage = FlutterSecureStorage();
        await secureStorage.write(
          key: 'cloud_company_profile',
          value: jsonEncode({
            'id': 'company-header-1',
            'name': 'Sunflower Studios',
            'timeZone': 'UTC',
            'currencyCode': 'INR',
            'region': 'IN',
            'isActive': true,
            'createdAtUtc': DateTime.now().toIso8601String(),
          }),
        );

        final storageProvider = StorageModeProvider(storageService);
        await storageProvider.load();

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ChangeNotifierProvider<StorageModeProvider>.value(
              value: storageProvider,
              child: const Scaffold(
                appBar: AppHeader(),
                body: SizedBox(),
              ),
            ),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 300));
        await tester.pump();
      });

      // Globe visual indicator is present with Cloud Mode tooltip
      expect(find.byIcon(Icons.language), findsOneWidget);
      expect(find.byTooltip('Cloud Mode'), findsOneWidget);

      // Verify it is only a visual indicator, NOT a clickable button or link
      expect(find.widgetWithIcon(IconButton, Icons.language), findsNothing);

      // Authenticated company name is displayed
      expect(find.text('Sunflower Studios'), findsOneWidget);
      expect(find.text('My Flower Shop'), findsNothing);
      expect(find.byType(BusinessIdentity), findsOneWidget);
      expect(find.byType(FlorapriseBrand), findsNothing);
    });

    testWidgets('In Local Storage mode: does NOT render globe indicator', (tester) async {
      await tester.runAsync(() async {
        final storageService = StorageModeService();
        await storageService.setMode(StorageMode.local);

        final storageProvider = StorageModeProvider(storageService);
        await storageProvider.load();

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ChangeNotifierProvider<StorageModeProvider>.value(
              value: storageProvider,
              child: const Scaffold(
                appBar: AppHeader(),
                body: SizedBox(),
              ),
            ),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 300));
        await tester.pump();
      });

      // Globe indicator MUST NOT be present in Local mode
      expect(find.byIcon(Icons.language), findsNothing);
      expect(find.byTooltip('Cloud Mode'), findsNothing);
    });
  });
}
