import 'dart:convert';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:floraprise/data/repositories/cloud_share_branding_settings_repository.dart';
import 'package:floraprise/models/share_branding.dart';

void main() {
  group('CloudShareBrandingSettingsRepository', () {
    test('fetchSettings parses JSON correctly', () async {
      final repo = CloudShareBrandingSettingsRepository(
        sender: (method, uri, {headers, body}) async {
          expect(method, 'GET');
          expect(uri.path, '/api/v1/mobile/company/settings/share-branding');
          expect(headers?['Authorization'], 'Bearer test_token');
          return http.Response(
            jsonEncode({
              'showPrice': false,
              'showShopName': true,
              'showPhoneNumber': false,
              'showWebsite': true,
              'showLogo': true,
              'showWatermark': true,
              'showWatermarkBusinessName': false,
              'showWatermarkCity': true,
              'watermarkOpacity': 0.85,
              'watermarkSize': 'large',
              'watermarkPosition': 'topRight',
              'footerColorArgb': 0xFF123456,
            }),
            200,
          );
        },
      );

      final settings = await repo.fetchSettings(
        baseUrl: 'https://api.example.com',
        accessToken: 'test_token',
      );

      expect(settings.showPrice, false);
      expect(settings.showShopName, true);
      expect(settings.showPhoneNumber, false);
      expect(settings.showLogo, true);
      expect(settings.watermarkOpacity, 0.85);
      expect(settings.watermarkSize, WatermarkSize.large);
      expect(settings.watermarkPosition, WatermarkPosition.topRight);
      expect(settings.footerColor, const Color(0xFF123456));
    });

    test('saveSettings serializes and handles server response', () async {
      late Map<String, dynamic> capturedBody;
      final repo = CloudShareBrandingSettingsRepository(
        sender: (method, uri, {headers, body}) async {
          expect(method, 'PUT');
          expect(headers?['Authorization'], 'Bearer test_token');
          capturedBody = jsonDecode(body as String);
          return http.Response(
            jsonEncode({
              ...capturedBody,
              'id': '11111111-1111-1111-1111-111111111111',
            }),
            200,
          );
        },
      );

      const toSave = ShareBrandingSettings(
        showPrice: true,
        showShopName: false,
        showPhoneNumber: true,
        showLogo: false,
        showWatermark: true,
        showWatermarkBusinessName: true,
        showWatermarkCity: false,
        watermarkOpacity: 0.5,
        watermarkSize: WatermarkSize.small,
        watermarkPosition: WatermarkPosition.topLeft,
        showWebsite: false,
        footerColor: Color(0xCC004D40),
      );

      final saved = await repo.saveSettings(
        baseUrl: 'https://api.example.com',
        accessToken: 'test_token',
        settings: toSave,
      );

      expect(capturedBody['watermarkSize'], 'small');
      expect(capturedBody['watermarkPosition'], 'topLeft');
      expect(capturedBody['watermarkOpacity'], 0.5);
      expect(saved.watermarkSize, WatermarkSize.small);
      expect(saved.watermarkPosition, WatermarkPosition.topLeft);
    });

    test('saveSettings throws on server error with detail message', () async {
      final repo = CloudShareBrandingSettingsRepository(
        sender: (method, uri, {headers, body}) async {
          return http.Response(
            jsonEncode({'detail': 'watermarkOpacity must be between 0.2 and 1.0.'}),
            400,
          );
        },
      );

      expect(
        () => repo.saveSettings(
          baseUrl: 'https://api.example.com',
          accessToken: 'test_token',
          settings: const ShareBrandingSettings(
            showPrice: true,
            showShopName: true,
            showPhoneNumber: true,
            showLogo: false,
            showWatermark: true,
            showWatermarkBusinessName: true,
            showWatermarkCity: true,
            watermarkOpacity: 1.5,
            watermarkSize: WatermarkSize.medium,
            watermarkPosition: WatermarkPosition.bottomCenter,
            showWebsite: true,
            footerColor: Color(0xCC1B5E20),
          ),
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('watermarkOpacity must be between 0.2 and 1.0.'),
        )),
      );
    });
  });
}
