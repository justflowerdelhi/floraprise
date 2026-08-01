import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/services/api_base_url.dart';

void main() {
  group('resolveFlorapriseApiBaseUrl', () {
    test('uses localhost fallback in debug on desktop platforms', () {
      final result = resolveFlorapriseApiBaseUrl(
        explicitValue: '',
        isDebug: true,
        platform: TargetPlatform.windows,
      );

      expect(result, 'http://localhost:5148');
    });

    test('uses Android emulator fallback in debug on Android', () {
      final result = resolveFlorapriseApiBaseUrl(
        explicitValue: '',
        isDebug: true,
        platform: TargetPlatform.android,
      );

      expect(result, 'http://10.0.2.2:5148');
    });

    test('prefers explicit configuration over fallback values', () {
      final result = resolveFlorapriseApiBaseUrl(
        explicitValue: 'https://example.test',
        isDebug: true,
        platform: TargetPlatform.android,
      );

      expect(result, 'https://example.test');
    });

    test('uses production host outside debug mode', () {
      final result = resolveFlorapriseApiBaseUrl(
        explicitValue: '',
        isDebug: false,
        platform: TargetPlatform.android,
      );

      expect(result, 'https://api.floraprise.com');
    });
  });
}
