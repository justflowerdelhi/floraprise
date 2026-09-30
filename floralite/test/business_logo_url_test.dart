import 'package:floraprise/services/api_base_url.dart';
import 'package:floraprise/widgets/business_identity.dart';
import 'package:floraprise/widgets/business_logo.dart';
import 'package:floraprise/widgets/safe_platform_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveBusinessLogoUrl Unit Tests', () {
    test('returns empty string for null, empty, and whitespace strings', () {
      expect(resolveBusinessLogoUrl(null), '');
      expect(resolveBusinessLogoUrl(''), '');
      expect(resolveBusinessLogoUrl('   '), '');
    });

    test('preserves absolute URLs (http:// and https://)', () {
      const httpsUrl = 'https://api.floraprise.com/uploads/logos/logo_1_123.png';
      expect(resolveBusinessLogoUrl(httpsUrl), httpsUrl);

      const httpUrl = 'http://localhost:5148/uploads/logos/logo.png';
      expect(resolveBusinessLogoUrl(httpUrl), httpUrl);
    });

    test('preserves blob URLs, data URIs, and asset paths', () {
      const blobUrl = 'blob:http://localhost:3000/12345';
      expect(resolveBusinessLogoUrl(blobUrl), blobUrl);

      const dataUri = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
      expect(resolveBusinessLogoUrl(dataUri), dataUri);

      const assetPath = 'assets/icon.png';
      expect(resolveBusinessLogoUrl(assetPath), assetPath);
    });

    test('resolves relative path with leading slash using default Web base URL', () {
      final resolved = resolveBusinessLogoUrl(
        '/uploads/logos/logo_1_123.png',
        isWeb: true,
      );
      expect(resolved, 'https://api.floraprise.com/uploads/logos/logo_1_123.png');
    });

    test('resolves relative path without leading slash without missing slash', () {
      final resolved = resolveBusinessLogoUrl(
        'uploads/logos/logo_1_123.png',
        isWeb: true,
      );
      expect(resolved, 'https://api.floraprise.com/uploads/logos/logo_1_123.png');
    });

    test('resolves relative path with explicit baseUrl with and without trailing slashes', () {
      final resolvedWithTrailingSlash = resolveBusinessLogoUrl(
        '/uploads/logos/company_1.png',
        explicitBaseUrl: 'https://api.floraprise.com/',
      );
      expect(
        resolvedWithTrailingSlash,
        'https://api.floraprise.com/uploads/logos/company_1.png',
      );

      final resolvedWithoutTrailingSlash = resolveBusinessLogoUrl(
        'uploads/logos/company_1.png',
        explicitBaseUrl: 'https://custom-api.floraprise.com',
      );
      expect(
        resolvedWithoutTrailingSlash,
        'https://custom-api.floraprise.com/uploads/logos/company_1.png',
      );
    });

    test('handles non-web relative path starting with uploads/ in debug mode', () {
      final resolved = resolveBusinessLogoUrl(
        '/uploads/logos/company_1.png',
        isDebug: true,
        platform: TargetPlatform.windows,
        isWeb: false,
      );
      expect(resolved, 'http://localhost:5148/uploads/logos/company_1.png');
    });
  });

  group('Logo & SafePlatformImageView Widget Tests', () {
    testWidgets('SafePlatformImageView renders fallback when imagePath is null or empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SafePlatformImageView(
              imagePath: '',
              fallbackIcon: Icons.store,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.store), findsOneWidget);
    });

    testWidgets('SafePlatformImageView resolves relative path and constructs Image.network', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SafePlatformImageView(
              imagePath: '/uploads/logos/shop_logo.png',
            ),
          ),
        ),
      );

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final imageWidget = tester.widget<Image>(imageFinder);
      expect(imageWidget.image, isA<NetworkImage>());
      final networkImage = imageWidget.image as NetworkImage;
      expect(networkImage.url, contains('/uploads/logos/shop_logo.png'));
    });

    testWidgets('buildBusinessLogo with empty path renders fallback asset icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildBusinessLogo(''),
          ),
        ),
      );

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final imageWidget = tester.widget<Image>(imageFinder);
      expect(imageWidget.image, isA<AssetImage>());
      final assetImage = imageWidget.image as AssetImage;
      expect(assetImage.assetName, 'assets/icon.png');
    });

    testWidgets('buildBusinessLogo with remote logo path renders NetworkImage', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildBusinessLogo('https://api.floraprise.com/uploads/logos/test.png'),
          ),
        ),
      );

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final imageWidget = tester.widget<Image>(imageFinder);
      expect(imageWidget.image, isA<NetworkImage>());
      final networkImage = imageWidget.image as NetworkImage;
      expect(networkImage.url, 'https://api.floraprise.com/uploads/logos/test.png');
    });

    testWidgets('BusinessIdentity displays resolved logo and shop name', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BusinessIdentity(
              name: 'Rose & Blossom Floral Studio',
              subtitle: 'Premium Florist',
              logoPath: 'https://api.floraprise.com/uploads/logos/rose.png',
            ),
          ),
        ),
      );

      expect(find.text('Rose & Blossom Floral Studio'), findsOneWidget);
      expect(find.text('Premium Florist'), findsOneWidget);

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final imageWidget = tester.widget<Image>(imageFinder);
      expect(imageWidget.image, isA<NetworkImage>());
    });
  });
}
