import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/models/printer_models.dart';
import 'package:floraprise/providers/printer_provider.dart';
import 'package:floraprise/services/printer/printer_manager.dart';

void main() {
  testWidgets('permission UI context has required Material ancestors',
      (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    );

    final permissionContext = navigatorKey.currentState!.overlay!.context;

    expect(MaterialLocalizations.of(permissionContext), isNotNull);
    expect(Navigator.maybeOf(permissionContext), isNotNull);
    expect(ScaffoldMessenger.maybeOf(permissionContext), isNotNull);
  });

  group('PrinterProvider Bluetooth safeguards', () {
    test('reports a friendly message when no printers are discovered',
        () async {
      final provider = PrinterProvider(_FakePrinterManager());

      await provider.scanBluetoothPrinters();

      expect(provider.discoveredPrinters, isEmpty);
      expect(
        provider.error,
        'No Bluetooth printers found. Make sure the printer is switched on and nearby.',
      );
    });

    test('does not report Bluetooth unavailable while printer is connected',
        () async {
      final manager = _FakePrinterManager()
        ..connected = true
        ..scanError = StateError('Null check operator used on a null value');
      final provider = PrinterProvider(manager);

      await provider.scanBluetoothPrinters();

      expect(provider.isConnected, isTrue);
      expect(provider.error, isNull);
    });

    test('reports Bluetooth unavailable when adapter is off and disconnected',
        () async {
      final manager = _FakePrinterManager()
        ..scanError = Exception(
          'Bluetooth is turned off. Please enable Bluetooth and try again.',
        );
      final provider = PrinterProvider(manager);

      await provider.scanBluetoothPrinters();

      expect(provider.isConnected, isFalse);
      expect(
        provider.error,
        'Bluetooth is unavailable. Please turn on Bluetooth and try again.',
      );
    });

    test('reports not connected after disconnect', () async {
      final manager = _FakePrinterManager()..connected = true;
      final provider = PrinterProvider(manager);

      await provider.disconnect();

      expect(provider.isConnected, isFalse);
      expect(provider.error, isNull);
    });

    test('does not connect a device with no Bluetooth address', () async {
      final manager = _FakePrinterManager();
      final provider = PrinterProvider(manager);

      await provider.connect(
        const PrinterDeviceInfo(name: 'Unknown printer', address: ''),
      );

      expect(manager.connectCalled, isFalse);
      expect(provider.error, 'Please select a printer first.');
    });

    test('does not print a test page before a printer is selected', () async {
      final manager = _FakePrinterManager();
      final provider = PrinterProvider(manager);

      await provider.printTestPage();

      expect(manager.printTestPageCalled, isFalse);
      expect(provider.error, 'Please select a printer first.');
    });
  });
}

class _FakePrinterManager extends PrinterManager {
  bool connectCalled = false;
  bool printTestPageCalled = false;
  bool connected = false;
  Object? scanError;

  @override
  bool get isConnected => connected;

  @override
  Future<bool> refreshConnectionState() async => connected;

  @override
  Future<List<PrinterDeviceInfo>> scanBluetoothPrinters({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final error = scanError;
    if (error != null) throw error;
    return const [];
  }

  @override
  Future<void> connect(PrinterDeviceInfo device) async {
    connectCalled = true;
  }

  @override
  Future<void> disconnect() async {
    connected = false;
  }

  @override
  Future<void> printTestPage() async {
    printTestPageCalled = true;
  }

  @override
  Future<List<PrintQueueJob>> listQueue() async => const [];

  @override
  Future<bool> hasLastSuccessfulReceipt() async => false;
}
