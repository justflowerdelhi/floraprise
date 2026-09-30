import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/data/repositories/printer_repository.dart';
import 'package:floraprise/managers/business_settings_manager.dart';
import 'package:floraprise/models/printer_models.dart';
import 'package:floraprise/providers/printer_provider.dart';
import 'package:floraprise/services/printer/escpos_builder.dart';
import 'package:floraprise/services/printer/printer_manager.dart';
import 'package:floraprise/services/printer/printer_service.dart';
import 'package:floraprise/services/printer/printer_transport_factory.dart';
import 'package:floraprise/services/printer/receipt_builder.dart';
import 'package:floraprise/services/printer/web_bluetooth_adapter.dart';
import 'package:floraprise/services/printer/web_bluetooth_printer_service.dart';
import 'package:floraprise/services/printer/web_receipt_print_service.dart';

class MockWebBluetoothCharacteristic implements WebBluetoothCharacteristic {
  MockWebBluetoothCharacteristic({
    required this.uuid,
    this.canWrite = true,
  });

  @override
  final String uuid;
  @override
  final bool canWrite;

  final List<Uint8List> writtenChunks = [];

  @override
  Future<void> writeValue(Uint8List bytes) async {
    if (!canWrite) throw Exception('Characteristic is not writable');
    writtenChunks.add(Uint8List.fromList(bytes));
  }
}

class MockWebBluetoothDevice implements WebBluetoothDevice {
  MockWebBluetoothDevice({
    required this.id,
    required this.name,
    this.writableCharacteristic,
  });

  @override
  final String id;
  @override
  final String name;

  MockWebBluetoothCharacteristic? writableCharacteristic;
  bool connected = false;
  void Function()? disconnectCallback;
  final List<Uint8List> writtenBytesLog = [];

  @override
  bool get isConnected => connected;

  @override
  Future<void> connect() async {
    connected = true;
  }

  @override
  Future<void> disconnect() async {
    connected = false;
    disconnectCallback?.call();
  }

  @override
  void onDisconnected(void Function() callback) {
    disconnectCallback = callback;
  }

  @override
  Future<WebBluetoothCharacteristic?> findWritableCharacteristic() async {
    return writableCharacteristic;
  }

  @override
  Future<void> writeBytes(
    Uint8List bytes, {
    int chunkSize = 100,
    Duration delay = const Duration(milliseconds: 15),
  }) async {
    final char = await findWritableCharacteristic();
    if (char == null) {
      throw Exception('No compatible writable BLE printing service found.');
    }
    for (var offset = 0; offset < bytes.length; offset += chunkSize) {
      final end = (offset + chunkSize < bytes.length)
          ? offset + chunkSize
          : bytes.length;
      final chunk = bytes.sublist(offset, end);
      await char.writeValue(chunk);
      writtenBytesLog.add(chunk);
    }
  }
}

class MockWebBluetoothAdapter implements WebBluetoothAdapter {
  bool supported = true;
  MockWebBluetoothDevice? deviceToReturn;
  final List<MockWebBluetoothDevice> existingDevices = [];
  bool requestDeviceCalled = false;

  @override
  bool get isSupported => supported;

  @override
  Future<WebBluetoothDevice?> requestDevice({List<String>? optionalServices}) async {
    requestDeviceCalled = true;
    return deviceToReturn;
  }

  @override
  Future<List<WebBluetoothDevice>> getDevices() async {
    return existingDevices;
  }
}

class MockWebReceiptPrintService extends WebReceiptPrintService {
  int posBillPrintedCount = 0;
  int deliverySlipPrintedCount = 0;
  Map<String, dynamic>? lastPosBillPayload;

  @override
  Future<void> printPosBill(
    Map<String, dynamic> payload, {
    PrinterPaperWidth paperWidth = PrinterPaperWidth.mm80,
  }) async {
    posBillPrintedCount++;
    lastPosBillPayload = payload;
  }

  @override
  Future<void> printDeliverySlip(
    Map<String, dynamic> payload, {
    PrinterPaperWidth paperWidth = PrinterPaperWidth.mm80,
  }) async {
    deliverySlipPrintedCount++;
  }
}

class _MockBusinessSettingsManager extends BusinessSettingsManager {
  @override
  Future<BusinessSettings> load() async {
    return const BusinessSettings(
      shopName: 'Bloom Boutique',
      ownerName: 'Alice Florist',
      phone: '+919876543210',
      address: '123 Flower Market, New Delhi',
      gstRegistered: true,
      gstNumber: '07AAAAA0000A1Z5',
      defaultDeliveryChargePaise: 5000,
      minimumPreparationBufferMinutes: 30,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppDatabase.instance.close();
    final path = await getDatabasesPath();
    await deleteDatabase('$path/floraprise.db');
  });

  group('Web Bluetooth Adapter & Service Unit Tests', () {
    test('1. WebBluetoothPrinterService reports browser unavailable when adapter is unsupported', () async {
      final adapter = MockWebBluetoothAdapter()..supported = false;
      final service = WebBluetoothPrinterService(adapter: adapter);

      expect(
        () => service.scan(),
        throwsA(isA<PrinterServiceException>().having(
          (e) => e.message,
          'message',
          contains('Bluetooth is not available in this browser'),
        )),
      );
    });

    test('2. WebBluetoothPrinterService scan returns discovered printer device on user selection', () async {
      final mockDevice = MockWebBluetoothDevice(
        id: 'web-ble-device-123',
        name: 'POS-80 Thermal',
      );
      final adapter = MockWebBluetoothAdapter()
        ..supported = true
        ..deviceToReturn = mockDevice;
      final service = WebBluetoothPrinterService(adapter: adapter);

      final devices = await service.scan();

      expect(adapter.requestDeviceCalled, isTrue);
      expect(devices.length, 1);
      expect(devices.first.name, 'POS-80 Thermal');
      expect(devices.first.address, 'web-ble-device-123');
    });

    test('3. WebBluetoothPrinterService scan returns empty list when user cancels picker', () async {
      final adapter = MockWebBluetoothAdapter()
        ..supported = true
        ..deviceToReturn = null;
      final service = WebBluetoothPrinterService(adapter: adapter);

      final devices = await service.scan();

      expect(devices, isEmpty);
    });

    test('4. WebBluetoothPrinterService connects to GATT and finds writable characteristic', () async {
      final mockChar = MockWebBluetoothCharacteristic(
        uuid: '0000bef7-0000-1000-8000-00805f9b34fb',
        canWrite: true,
      );
      final mockDevice = MockWebBluetoothDevice(
        id: 'dev-1',
        name: 'POS-80',
        writableCharacteristic: mockChar,
      );
      final adapter = MockWebBluetoothAdapter()
        ..supported = true
        ..deviceToReturn = mockDevice;
      final service = WebBluetoothPrinterService(adapter: adapter);

      await service.scan();
      final connected = await service.connect(
        const PrinterDevice(name: 'POS-80', address: 'dev-1'),
      );

      expect(connected, isTrue);
      expect(await service.isConnected(), isTrue);
    });

    test('5. WebBluetoothPrinterService throws user-friendly error when printer lacks compatible BLE GATT service', () async {
      final mockDevice = MockWebBluetoothDevice(
        id: 'dev-2',
        name: 'Incompatible BLE Device',
        writableCharacteristic: null,
      );
      final adapter = MockWebBluetoothAdapter()
        ..supported = true
        ..deviceToReturn = mockDevice;
      final service = WebBluetoothPrinterService(adapter: adapter);

      await service.scan();

      expect(
        () => service.connect(
          const PrinterDevice(name: 'Incompatible BLE Device', address: 'dev-2'),
        ),
        throwsA(isA<PrinterServiceException>().having(
          (e) => e.message,
          'message',
          'This printer does not expose a compatible BLE printing service.',
        )),
      );
    });

    test('6. WebBluetoothPrinterService writes ESC/POS bytes in safe 100-byte chunks with delays', () async {
      final mockChar = MockWebBluetoothCharacteristic(
        uuid: '0000bef7-0000-1000-8000-00805f9b34fb',
        canWrite: true,
      );
      final mockDevice = MockWebBluetoothDevice(
        id: 'dev-chunk',
        name: 'POS-80',
        writableCharacteristic: mockChar,
      );
      final adapter = MockWebBluetoothAdapter()
        ..supported = true
        ..deviceToReturn = mockDevice;
      final service = WebBluetoothPrinterService(
        adapter: adapter,
        chunkSize: 100,
        chunkDelay: const Duration(milliseconds: 1),
      );

      await service.scan();
      await service.connect(
        const PrinterDevice(name: 'POS-80', address: 'dev-chunk'),
      );

      final testBytes = Uint8List.fromList(List.generate(250, (i) => i % 256));
      await service.printBytes(testBytes);

      expect(mockChar.writtenChunks.length, 3);
      expect(mockChar.writtenChunks[0].length, 100);
      expect(mockChar.writtenChunks[1].length, 100);
      expect(mockChar.writtenChunks[2].length, 50);
    });

    test('7. WebBluetoothPrinterService disconnect callback resets connection state', () async {
      final mockChar = MockWebBluetoothCharacteristic(
        uuid: '0000bef7-0000-1000-8000-00805f9b34fb',
      );
      final mockDevice = MockWebBluetoothDevice(
        id: 'dev-disc',
        name: 'POS-80',
        writableCharacteristic: mockChar,
      );
      final adapter = MockWebBluetoothAdapter()
        ..supported = true
        ..deviceToReturn = mockDevice;
      final service = WebBluetoothPrinterService(adapter: adapter);

      await service.scan();
      await service.connect(
        const PrinterDevice(name: 'POS-80', address: 'dev-disc'),
      );
      expect(await service.isConnected(), isTrue);

      await service.disconnect();
      expect(await service.isConnected(), isFalse);
    });
  });

  group('PrinterRepository SharedPreferences Persistence Tests', () {
    test('8. PrinterRepository saves and retrieves PrinterConfig via SharedPreferences on Web', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = PrinterRepository(prefs: prefs, isWeb: true);

      final initialConfig = await repo.getConfig();
      expect(initialConfig.paperWidth, PrinterPaperWidth.mm80);

      const newConfig = PrinterConfig(
        connectionKind: PrinterConnectionKind.bluetooth,
        paperWidth: PrinterPaperWidth.mm58,
        printerName: 'POS-58 BLE',
        printerAddress: 'ble-address-xyz',
        autoConnect: true,
        autoPrintAfterBilling: true,
        copies: 2,
        cutPaper: false,
        printLogo: true,
        printQrCode: true,
        printBarcode: false,
        printDuplicateCopy: true,
        thankYouMessage: 'Visit Again!',
      );

      await repo.saveConfig(newConfig);

      final freshRepo = PrinterRepository(prefs: prefs, isWeb: true);
      final loadedConfig = await freshRepo.getConfig();

      expect(loadedConfig.paperWidth, PrinterPaperWidth.mm58);
      expect(loadedConfig.printerName, 'POS-58 BLE');
      expect(loadedConfig.printerAddress, 'ble-address-xyz');
      expect(loadedConfig.autoConnect, isTrue);
      expect(loadedConfig.autoPrintAfterBilling, isTrue);
      expect(loadedConfig.copies, 2);
      expect(loadedConfig.cutPaper, isFalse);
      expect(loadedConfig.printLogo, isTrue);
      expect(loadedConfig.thankYouMessage, 'Visit Again!');
    });

    test('9. PrinterRepository enqueues, marks printed, and provides last successful receipt for reprint on Web', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = PrinterRepository(prefs: prefs, isWeb: true);

      final jobId = await repo.enqueue(
        type: PrintJobType.posBill,
        payload: {
          'invoiceNumber': 'INV-999',
          'grandTotalPaise': 150000,
        },
      );

      expect(jobId, greaterThan(0));
      final queue = await repo.listQueue();
      expect(queue.length, 1);
      expect(queue.first.status, PrintJobStatus.pending);

      await repo.markPrinted(jobId);

      final lastReceipt = await repo.getLastSuccessfulReceipt();
      expect(lastReceipt, isNotNull);
      expect(lastReceipt!.payload['invoiceNumber'], 'INV-999');
    });
  });

  group('PrinterTransportFactory Tests', () {
    test('10. PrinterTransportFactory creates default PrinterService instance', () {
      final transport = PrinterTransportFactory.createDefault();
      expect(transport, isNotNull);
      expect(transport, isA<PrinterService>());
    });
  });

  group('POS Print Routing & Fallback Tests', () {
    test('11. Disconnected Web Bluetooth printer routes POS bill to WebReceiptPrintService HTML fallback', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = PrinterRepository(prefs: prefs, isWeb: true);

      final mockChar = MockWebBluetoothCharacteristic(
        uuid: '0000bef7-0000-1000-8000-00805f9b34fb',
      );
      final mockDevice = MockWebBluetoothDevice(
        id: 'dev-pos',
        name: 'POS-80',
        writableCharacteristic: mockChar,
      );
      final adapter = MockWebBluetoothAdapter()..deviceToReturn = mockDevice;
      final webTransport = WebBluetoothPrinterService(adapter: adapter);

      final manager = PrinterManager(
        repository: repo,
        receiptBuilder: ReceiptBuilder(
          businessSettingsManager: _MockBusinessSettingsManager(),
        ),
        transport: webTransport,
      );

      final webPrintService = MockWebReceiptPrintService();
      final provider = PrinterProvider(
        manager,
        webReceiptPrintService: webPrintService,
        isWeb: true,
      );

      await provider.load();

      expect(provider.isConnected, isFalse);

      await provider.enqueuePosBill({
        'invoiceNumber': 'INV-WEB-01',
        'items': [],
        'grandTotalPaise': 50000,
      });

      expect(webPrintService.posBillPrintedCount, 1);
      expect(webPrintService.lastPosBillPayload?['invoiceNumber'], 'INV-WEB-01');
      expect(provider.hasLastReceipt, isTrue);
    });

    test('12. Connected Web Bluetooth printer prints ESC/POS binary directly without HTML fallback', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = PrinterRepository(prefs: prefs, isWeb: true);

      final mockChar = MockWebBluetoothCharacteristic(
        uuid: '0000bef7-0000-1000-8000-00805f9b34fb',
      );
      final mockDevice = MockWebBluetoothDevice(
        id: 'dev-connected',
        name: 'POS-80 Bluetooth',
        writableCharacteristic: mockChar,
      );
      final adapter = MockWebBluetoothAdapter()..deviceToReturn = mockDevice;
      final webTransport = WebBluetoothPrinterService(
        adapter: adapter,
        chunkSize: 100,
        chunkDelay: const Duration(milliseconds: 1),
      );

      final manager = PrinterManager(
        repository: repo,
        receiptBuilder: ReceiptBuilder(
          businessSettingsManager: _MockBusinessSettingsManager(),
        ),
        transport: webTransport,
      );

      final webPrintService = MockWebReceiptPrintService();
      final provider = PrinterProvider(
        manager,
        webReceiptPrintService: webPrintService,
        isWeb: true,
      );

      await provider.load();
      await provider.scanBluetoothPrinters();
      await provider.connect(
        const PrinterDeviceInfo(name: 'POS-80 Bluetooth', address: 'dev-connected'),
      );

      expect(provider.isConnected, isTrue);

      await provider.enqueuePosBill({
        'invoiceNumber': 'INV-BT-01',
        'items': [
          {
            'name': 'Lily Bouquet',
            'qty': 1,
            'ratePaise': 80000,
            'totalPaise': 80000,
          },
        ],
        'basicAmountPaise': 80000,
        'grandTotalPaise': 80000,
      });

      expect(webPrintService.posBillPrintedCount, 0);
      expect(mockChar.writtenChunks, isNotEmpty);
      expect(provider.hasLastReceipt, isTrue);
    });

    test('13. Print Test Page routes through Web Bluetooth transport when connected', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = PrinterRepository(prefs: prefs, isWeb: true);

      final mockChar = MockWebBluetoothCharacteristic(
        uuid: '0000bef7-0000-1000-8000-00805f9b34fb',
      );
      final mockDevice = MockWebBluetoothDevice(
        id: 'dev-test',
        name: 'POS-80 Test',
        writableCharacteristic: mockChar,
      );
      final adapter = MockWebBluetoothAdapter()..deviceToReturn = mockDevice;
      final webTransport = WebBluetoothPrinterService(
        adapter: adapter,
        chunkSize: 100,
        chunkDelay: const Duration(milliseconds: 1),
      );

      final manager = PrinterManager(
        repository: repo,
        receiptBuilder: ReceiptBuilder(
          businessSettingsManager: _MockBusinessSettingsManager(),
        ),
        transport: webTransport,
      );

      final provider = PrinterProvider(
        manager,
        isWeb: true,
      );
      await provider.load();
      await provider.scanBluetoothPrinters();
      await provider.connect(
        const PrinterDeviceInfo(name: 'POS-80 Test', address: 'dev-test'),
      );

      await provider.printTestPage();

      expect(mockChar.writtenChunks, isNotEmpty);
      expect(provider.error, isNull);
    });
  });

  group('ESC/POS Formatting & Paper Width Tests', () {
    test('14. EscPosBuilder generates correct line widths for 58mm (32 chars) and 80mm (48 chars)', () {
      final builder58 = EscPosBuilder(paperWidth: PrinterPaperWidth.mm58);
      expect(builder58.charsPerLine, 32);

      final builder80 = EscPosBuilder(paperWidth: PrinterPaperWidth.mm80);
      expect(builder80.charsPerLine, 48);
    });

    test('15. ReceiptBuilder builds valid ESC/POS byte sequence for test page and POS bill', () async {
      final builder = ReceiptBuilder(
        businessSettingsManager: _MockBusinessSettingsManager(),
      );
      const settings80 = PrinterConfig(
        connectionKind: PrinterConnectionKind.bluetooth,
        paperWidth: PrinterPaperWidth.mm80,
        autoConnect: false,
        autoPrintAfterBilling: false,
        copies: 1,
        cutPaper: true,
        printLogo: false,
        printQrCode: false,
        printBarcode: true,
        printDuplicateCopy: false,
        thankYouMessage: 'Thank you for shopping with us',
      );

      final testPageBytes = await builder.build(
        type: PrintJobType.testPage,
        payload: const {},
        settings: settings80,
      );

      expect(testPageBytes, isNotEmpty);
      expect(testPageBytes[0], 0x1B);
      expect(testPageBytes[1], 0x40);

      final posBillBytes = await builder.build(
        type: PrintJobType.posBill,
        payload: {
          'invoiceNumber': 'INV-100',
          'items': [
            {'name': 'Orchids', 'qty': 2, 'ratePaise': 50000, 'totalPaise': 100000}
          ],
          'grandTotalPaise': 100000,
        },
        settings: settings80,
      );

      expect(posBillBytes, isNotEmpty);
    });
  });
}
