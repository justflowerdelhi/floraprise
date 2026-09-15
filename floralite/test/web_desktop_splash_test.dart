import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/presentation/splash/web_desktop_splash.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WebDesktopSplash Responsive Rendering', () {
    testWidgets('renders desktop splash with branding, badge, and tagline on 1920x1080', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: WebDesktopSplash(),
        ),
      );

      // Verify core brand elements
      expect(find.text('Floraprise'), findsOneWidget);
      expect(find.text('PRO CLOUD'), findsOneWidget);
      expect(find.text('Your Florist Business, Simplified.'), findsOneWidget);
      expect(find.text('Loading workspace…'), findsOneWidget);

      // Verify cloud icon in edition badge
      expect(find.byIcon(Icons.cloud_outlined), findsOneWidget);

      // Verify no RenderFlex overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders desktop splash cleanly on standard business 1366x768 monitor', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: WebDesktopSplash(),
        ),
      );

      expect(find.text('Floraprise'), findsOneWidget);
      expect(find.text('PRO CLOUD'), findsOneWidget);
      expect(find.text('Your Florist Business, Simplified.'), findsOneWidget);
      expect(find.text('Loading workspace…'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('adapts gracefully on compact viewports without clipping or overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(500, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: WebDesktopSplash(),
        ),
      );

      expect(find.text('Floraprise'), findsOneWidget);
      expect(find.text('PRO CLOUD'), findsOneWidget);
      expect(find.text('Your Florist Business, Simplified.'), findsOneWidget);
      expect(find.text('Loading workspace…'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
