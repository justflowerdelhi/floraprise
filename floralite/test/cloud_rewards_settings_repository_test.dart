import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:floraprise/data/repositories/cloud_rewards_settings_repository.dart';
import 'package:floraprise/managers/reward_manager.dart';

void main() {
  group('CloudRewardsSettingsRepository', () {
    test('fetchSettings parses JSON correctly', () async {
      final repo = CloudRewardsSettingsRepository(
        sender: (method, uri, {headers, body}) async {
          expect(method, 'GET');
          expect(uri.path, '/api/v1/mobile/company/settings/rewards');
          expect(headers?['Authorization'], 'Bearer test_token');
          return http.Response(
            jsonEncode({
              'enabled': false,
              'earnSpendPaisePerPoint': 5000,
              'minimumBillPaise': 20000,
              'pointValuePaise': 50,
              'maximumRedemptionPercent': 30,
              'expiryDays': 180,
            }),
            200,
          );
        },
      );

      final settings = await repo.fetchSettings(
        baseUrl: 'https://api.example.com',
        accessToken: 'test_token',
      );

      expect(settings.enabled, false);
      expect(settings.earnSpendPaisePerPoint, 5000);
      expect(settings.minimumBillPaise, 20000);
      expect(settings.pointValuePaise, 50);
      expect(settings.maximumRedemptionPercent, 30);
      expect(settings.expiryDays, 180);
    });

    test('saveSettings serializes and handles server response', () async {
      late Map<String, dynamic> capturedBody;
      final repo = CloudRewardsSettingsRepository(
        sender: (method, uri, {headers, body}) async {
          expect(method, 'PUT');
          expect(headers?['Authorization'], 'Bearer test_token');
          capturedBody = jsonDecode(body as String);
          return http.Response(
            jsonEncode({
              ...capturedBody,
              'id': '22222222-2222-2222-2222-222222222222',
            }),
            200,
          );
        },
      );

      const toSave = RewardSettings(
        enabled: true,
        earnSpendPaisePerPoint: 8000,
        minimumBillPaise: 25000,
        pointValuePaise: 200,
        maximumRedemptionPercent: 15,
        expiryDays: 90,
      );

      final saved = await repo.saveSettings(
        baseUrl: 'https://api.example.com',
        accessToken: 'test_token',
        settings: toSave,
      );

      expect(capturedBody['earnSpendPaisePerPoint'], 8000);
      expect(capturedBody['minimumBillPaise'], 25000);
      expect(capturedBody['pointValuePaise'], 200);
      expect(capturedBody['maximumRedemptionPercent'], 15);
      expect(saved.maximumRedemptionPercent, 15);
    });

    test('saveSettings throws on server error with detail message', () async {
      final repo = CloudRewardsSettingsRepository(
        sender: (method, uri, {headers, body}) async {
          return http.Response(
            jsonEncode({'detail': 'maximumRedemptionPercent must be between 0 and 100.'}),
            400,
          );
        },
      );

      expect(
        () => repo.saveSettings(
          baseUrl: 'https://api.example.com',
          accessToken: 'test_token',
          settings: const RewardSettings(
            enabled: true,
            earnSpendPaisePerPoint: 10000,
            minimumBillPaise: 30000,
            pointValuePaise: 100,
            maximumRedemptionPercent: 150,
            expiryDays: 365,
          ),
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('maximumRedemptionPercent must be between 0 and 100.'),
        )),
      );
    });
  });
}
