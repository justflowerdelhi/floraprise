import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/widgets/camera_barcode_scanner_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  PageRoute<String> createTestRoute() {
    return PageRouteBuilder<String>(
      pageBuilder: (_, __, ___) =>
          const CameraBarcodeScannerPage(title: 'Scan Barcode'),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }

  group('ScannerOverlay Widget Tests', () {
    testWidgets('Renders viewport overlay with guidance texts and manual entry button',
        (tester) async {
      bool manualEntryTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScannerOverlay(
              onManualEntry: () {
                manualEntryTapped = true;
              },
            ),
          ),
        ),
      );

      // Verify instruction texts are present
      expect(find.text('Align barcode inside the box'), findsOneWidget);
      expect(
          find.text(
              'Position the barcode until it looks sharp and fits inside the box.'),
          findsOneWidget);
      expect(find.text('Or enter barcode manually'), findsOneWidget);

      // Tap the manual entry button
      await tester.tap(find.text('Or enter barcode manually'));
      await tester.pump();

      expect(manualEntryTapped, isTrue);
    });

    testWidgets('Scanner overlay repaints smoothly during animation ticks',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScannerOverlay(
              onManualEntry: () {},
            ),
          ),
        ),
      );

      // Advance animation frames
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(CustomPaint), findsWidgets);

      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  group('Hardware Scanner Key Event Simulation Tests', () {
    testWidgets('Simulates rapid hardware barcode keystrokes + Enter and pops with code',
        (tester) async {
      String? returnedCode;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  returnedCode =
                      await Navigator.of(context).push<String>(createTestRoute());
                },
                child: const Text('Open Scanner'),
              ),
            ),
          ),
        ),
      );

      // Open scanner page
      await tester.tap(find.text('Open Scanner'));
      await tester.pump();

      expect(find.byType(CameraBarcodeScannerPage), findsOneWidget);

      final state = tester.state<CameraBarcodeScannerPageState>(
          find.byType(CameraBarcodeScannerPage));

      // Simulate fast USB/Bluetooth hardware barcode scanner characters (15ms apart)
      final startTime = DateTime(2026, 9, 16, 12, 0, 0);
      const barcode = 'VL0085425688009';
      for (int i = 0; i < barcode.length; i++) {
        state.handleKeyEvent(
          KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.keyA,
            logicalKey: LogicalKeyboardKey.keyA,
            character: barcode[i],
            timeStamp: Duration(milliseconds: i * 15),
          ),
          customNow: startTime.add(Duration(milliseconds: i * 15)),
        );
      }

      // Scanner sends Enter key
      state.handleKeyEvent(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.enter,
          logicalKey: LogicalKeyboardKey.enter,
          timeStamp: Duration(milliseconds: 15 * 15),
        ),
        customNow:
            startTime.add(const Duration(milliseconds: 15 * 15)),
      );

      // Pump to trigger postFrameCallback and instant route pop
      await tester.pump();
      await tester.pump();

      // Verify returned code and scanner closed
      expect(returnedCode, 'VL0085425688009');
      expect(find.byType(CameraBarcodeScannerPage), findsNothing);
    });

    testWidgets('Simulates rapid hardware barcode keystrokes + NumpadEnter',
        (tester) async {
      String? returnedCode;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  returnedCode =
                      await Navigator.of(context).push<String>(createTestRoute());
                },
                child: const Text('Open Scanner'),
              ),
            ),
          ),
        ),
      );

      // Open scanner page
      await tester.tap(find.text('Open Scanner'));
      await tester.pump();

      final state = tester.state<CameraBarcodeScannerPageState>(
          find.byType(CameraBarcodeScannerPage));

      final startTime = DateTime(2026, 9, 16, 12, 0, 0);
      const barcode = '8901030999999';
      for (int i = 0; i < barcode.length; i++) {
        state.handleKeyEvent(
          KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.digit0,
            logicalKey: LogicalKeyboardKey.digit0,
            character: barcode[i],
            timeStamp: Duration(milliseconds: i * 15),
          ),
          customNow: startTime.add(Duration(milliseconds: i * 15)),
        );
      }

      // Scanner sends NumpadEnter key
      state.handleKeyEvent(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.numpadEnter,
          logicalKey: LogicalKeyboardKey.numpadEnter,
          timeStamp: Duration(milliseconds: 13 * 15),
        ),
        customNow:
            startTime.add(const Duration(milliseconds: 13 * 15)),
      );

      await tester.pump();
      await tester.pump();

      expect(returnedCode, '8901030999999');
      expect(find.byType(CameraBarcodeScannerPage), findsNothing);
    });

    testWidgets('Escape key closes scanner without returning code',
        (tester) async {
      String? returnedCode;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  returnedCode = await Navigator.of(context).push<String>(
                    MaterialPageRoute(
                      builder: (_) => const CameraBarcodeScannerPage(
                        title: 'Scan Barcode',
                      ),
                    ),
                  );
                },
                child: const Text('Open Scanner'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Scanner'));
      await tester.pumpAndSettle();

      final state = tester
          .state<CameraBarcodeScannerPageState>(find.byType(CameraBarcodeScannerPage));

      // Press Escape
      state.handleKeyEvent(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.escape,
          logicalKey: LogicalKeyboardKey.escape,
          timeStamp: Duration.zero,
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(returnedCode, isNull);
      expect(find.byType(CameraBarcodeScannerPage), findsNothing);
    });

    testWidgets(
        'Slow typing does not trigger hardware scanner auto-submit on Enter',
        (tester) async {
      String? returnedCode;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  returnedCode = await Navigator.of(context).push<String>(
                    MaterialPageRoute(
                      builder: (_) => const CameraBarcodeScannerPage(
                        title: 'Scan Barcode',
                      ),
                    ),
                  );
                },
                child: const Text('Open Scanner'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Scanner'));
      await tester.pumpAndSettle();

      final state = tester
          .state<CameraBarcodeScannerPageState>(find.byType(CameraBarcodeScannerPage));

      const barcode = '123456';
      final startTime = DateTime(2026, 1, 1, 12, 0, 0);

      // Simulate human-speed typing (250ms interval between keystrokes)
      for (int i = 0; i < barcode.length; i++) {
        state.handleKeyEvent(
          KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.digit1,
            logicalKey: LogicalKeyboardKey.keyA,
            character: barcode[i],
            timeStamp: Duration(milliseconds: i * 250),
          ),
          customNow: startTime.add(Duration(milliseconds: i * 250)),
        );
      }

      // Enter pressed after slow typing
      state.handleKeyEvent(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.enter,
          logicalKey: LogicalKeyboardKey.enter,
          timeStamp: Duration(milliseconds: 6 * 250),
        ),
        customNow:
            startTime.add(const Duration(milliseconds: 6 * 250)),
      );

      await tester.pump();

      // Scanner should still be open
      expect(find.byType(CameraBarcodeScannerPage), findsOneWidget);
      expect(returnedCode, isNull);

      // Clean up by popping scanner route before test completes
      state.cancelAndPop();
      await tester.pump();
      await tester.pump();
      expect(find.byType(CameraBarcodeScannerPage), findsNothing);
    });

    testWidgets('Duplicate completion calls are safely ignored without multiple pops',
        (tester) async {
      String? returnedCode;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  returnedCode =
                      await Navigator.of(context).push<String>(createTestRoute());
                },
                child: const Text('Open Scanner'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Scanner'));
      await tester.pump();

      final state = tester.state<CameraBarcodeScannerPageState>(
          find.byType(CameraBarcodeScannerPage));

      // Call completeWithCode multiple times concurrently
      state.completeWithCode('FIRST_CODE');
      state.completeWithCode('SECOND_CODE');

      await tester.pump();
      await tester.pump();

      expect(returnedCode, 'FIRST_CODE');
      expect(find.byType(CameraBarcodeScannerPage), findsNothing);
    });
  });
}
