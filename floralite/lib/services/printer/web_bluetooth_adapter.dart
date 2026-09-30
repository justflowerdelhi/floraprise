import 'dart:typed_data';

/// Known BLE GATT service UUIDs commonly used by thermal POS receipt printers.
const List<String> knownThermalServiceUuids = [
  '0000e781-0000-1000-8000-00805f9b34fb', // Thermal POS standard
  '0000fff0-0000-1000-8000-00805f9b34fb', // Transparent / ISSC UART
  '6e400001-b5a3-f393-e0a9-e50e24dcca9e', // Nordic UART Service (NUS)
  '0000ffe0-0000-1000-8000-00805f9b34fb', // HM-10 / CC2540 Serial
  '0000fee7-0000-1000-8000-00805f9b34fb', // Vendor thermal service
  '49535343-fe7d-4ae5-8fa9-9fafd205e455', // Microchip ISSC
  '000018f0-0000-1000-8000-00805f9b34fb', // POS Service standard
  '0000ff00-0000-1000-8000-00805f9b34fb', // General Serial
  '000018f1-0000-1000-8000-00805f9b34fb', // POS Service variant
  '0000af30-0000-1000-8000-00805f9b34fb', // Vendor BLE
];

/// Known BLE characteristic UUIDs commonly used to write ESC/POS bytes.
const List<String> knownThermalWriteCharacteristicUuids = [
  '0000bef7-0000-1000-8000-00805f9b34fb',
  '0000fff2-0000-1000-8000-00805f9b34fb',
  '0000fff1-0000-1000-8000-00805f9b34fb',
  '6e400002-b5a3-f393-e0a9-e50e24dcca9e',
  '0000ffe1-0000-1000-8000-00805f9b34fb',
  '0000fec7-0000-1000-8000-00805f9b34fb',
  '0000fec8-0000-1000-8000-00805f9b34fb',
  '49535343-8841-43f4-a8d4-ecbe34729bb3',
  '00002af1-0000-1000-8000-00805f9b34fb',
  '0000ff02-0000-1000-8000-00805f9b34fb',
];

/// Abstract characteristic contract for writing GATT data.
abstract class WebBluetoothCharacteristic {
  String get uuid;
  bool get canWrite;
  Future<void> writeValue(Uint8List bytes);
}

/// Abstract device contract representing a connected or paired BLE device.
abstract class WebBluetoothDevice {
  String get id;
  String get name;
  bool get isConnected;

  Future<void> connect();
  Future<void> disconnect();
  void onDisconnected(void Function() callback);
  Future<WebBluetoothCharacteristic?> findWritableCharacteristic();
  Future<void> writeBytes(
    Uint8List bytes, {
    int chunkSize = 100,
    Duration delay = const Duration(milliseconds: 15),
  });
}

/// Abstract adapter interface isolating browser Web Bluetooth APIs
/// for clean testability and headless execution.
abstract class WebBluetoothAdapter {
  bool get isSupported;
  Future<WebBluetoothDevice?> requestDevice({List<String>? optionalServices});
  Future<List<WebBluetoothDevice>> getDevices();
}
