// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'dart:typed_data';

import 'web_bluetooth_adapter.dart';

WebBluetoothAdapter createWebBluetoothAdapter() => BrowserWebBluetoothAdapter();

class BrowserWebBluetoothAdapter implements WebBluetoothAdapter {
  dynamic get _bluetooth {
    try {
      if (js_util.hasProperty(html.window.navigator, 'bluetooth')) {
        return js_util.getProperty(html.window.navigator, 'bluetooth');
      }
    } catch (_) {}
    return null;
  }

  @override
  bool get isSupported => _bluetooth != null;

  @override
  Future<WebBluetoothDevice?> requestDevice({List<String>? optionalServices}) async {
    final bt = _bluetooth;
    if (bt == null) return null;

    final servicesList = optionalServices ?? knownThermalServiceUuids;
    final options = js_util.newObject();
    js_util.setProperty(options, 'acceptAllDevices', true);
    js_util.setProperty(options, 'optionalServices', servicesList);

    try {
      final rawDevice = await js_util.promiseToFuture<dynamic>(
        js_util.callMethod(bt, 'requestDevice', [options]),
      );
      if (rawDevice == null) return null;
      return BrowserWebBluetoothDevice(rawDevice);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('user cancelled') || msg.contains('user canceled')) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<List<WebBluetoothDevice>> getDevices() async {
    final bt = _bluetooth;
    if (bt == null) return const [];

    try {
      if (js_util.hasProperty(bt, 'getDevices')) {
        final rawDevices = await js_util.promiseToFuture<dynamic>(
          js_util.callMethod(bt, 'getDevices', []),
        );
        if (rawDevices is List) {
          return rawDevices.map((d) => BrowserWebBluetoothDevice(d)).toList();
        }
        final length = js_util.getProperty(rawDevices, 'length') as int? ?? 0;
        final list = <WebBluetoothDevice>[];
        for (var i = 0; i < length; i++) {
          final d = js_util.callMethod(rawDevices, 'item', [i]) ??
              js_util.getProperty(rawDevices, i);
          if (d != null) {
            list.add(BrowserWebBluetoothDevice(d));
          }
        }
        return list;
      }
    } catch (_) {}
    return const [];
  }
}

class BrowserWebBluetoothDevice implements WebBluetoothDevice {
  BrowserWebBluetoothDevice(this.rawDevice);

  final dynamic rawDevice;
  BrowserWebBluetoothCharacteristic? _cachedCharacteristic;

  @override
  String get id {
    try {
      return js_util.getProperty(rawDevice, 'id')?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  @override
  String get name {
    try {
      final val = js_util.getProperty(rawDevice, 'name')?.toString();
      if (val != null && val.trim().isNotEmpty) return val.trim();
    } catch (_) {}
    return 'Bluetooth Thermal Printer';
  }

  @override
  bool get isConnected {
    try {
      final gatt = js_util.getProperty(rawDevice, 'gatt');
      if (gatt == null) return false;
      return js_util.getProperty(gatt, 'connected') == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> connect() async {
    final gatt = js_util.getProperty(rawDevice, 'gatt');
    if (gatt == null) {
      throw Exception('GATT server unavailable on this device');
    }
    if (isConnected) return;
    await js_util.promiseToFuture<dynamic>(
      js_util.callMethod(gatt, 'connect', []),
    );
    _cachedCharacteristic = null;
  }

  @override
  Future<void> disconnect() async {
    try {
      final gatt = js_util.getProperty(rawDevice, 'gatt');
      if (gatt != null) {
        js_util.callMethod(gatt, 'disconnect', []);
      }
    } catch (_) {}
    _cachedCharacteristic = null;
  }

  @override
  void onDisconnected(void Function() callback) {
    try {
      js_util.callMethod(rawDevice, 'addEventListener', [
        'gattserverdisconnected',
        js.allowInterop((_) {
          _cachedCharacteristic = null;
          callback();
        }),
      ]);
    } catch (_) {}
  }

  @override
  Future<WebBluetoothCharacteristic?> findWritableCharacteristic() async {
    if (_cachedCharacteristic != null) return _cachedCharacteristic;

    final gatt = js_util.getProperty(rawDevice, 'gatt');
    if (gatt == null) return null;

    if (!isConnected) {
      await connect();
    }

    // Step 1: Probe known thermal primary services
    for (final serviceUuid in knownThermalServiceUuids) {
      try {
        final service = await js_util.promiseToFuture<dynamic>(
          js_util.callMethod(gatt, 'getPrimaryService', [serviceUuid]),
        );
        if (service != null) {
          final char = await _findWritableInService(service);
          if (char != null) {
            _cachedCharacteristic = char;
            return char;
          }
        }
      } catch (_) {}
    }

    // Step 2: Fallback - Discover all primary services on device
    try {
      final services = await js_util.promiseToFuture<dynamic>(
        js_util.callMethod(gatt, 'getPrimaryServices', []),
      );
      final servicesList = _toList(services);
      for (final service in servicesList) {
        final char = await _findWritableInService(service);
        if (char != null) {
          _cachedCharacteristic = char;
          return char;
        }
      }
    } catch (_) {}

    return null;
  }

  Future<BrowserWebBluetoothCharacteristic?> _findWritableInService(
      dynamic service) async {
    try {
      final chars = await js_util.promiseToFuture<dynamic>(
        js_util.callMethod(service, 'getCharacteristics', []),
      );
      final charList = _toList(chars);
      for (final c in charList) {
        final charObj = BrowserWebBluetoothCharacteristic(c);
        if (charObj.canWrite) {
          return charObj;
        }
      }
    } catch (_) {}
    return null;
  }

  List<dynamic> _toList(dynamic jsArrayOrList) {
    if (jsArrayOrList == null) return const [];
    if (jsArrayOrList is List) return jsArrayOrList;
    try {
      final length = js_util.getProperty(jsArrayOrList, 'length') as int? ?? 0;
      final list = <dynamic>[];
      for (var i = 0; i < length; i++) {
        final item = js_util.getProperty(jsArrayOrList, i);
        if (item != null) list.add(item);
      }
      return list;
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> writeBytes(
    Uint8List bytes, {
    int chunkSize = 100,
    Duration delay = const Duration(milliseconds: 15),
  }) async {
    final characteristic = await findWritableCharacteristic();
    if (characteristic == null) {
      throw Exception('No compatible writable BLE printing service found.');
    }

    for (var offset = 0; offset < bytes.length; offset += chunkSize) {
      final end = (offset + chunkSize < bytes.length)
          ? offset + chunkSize
          : bytes.length;
      final chunk = bytes.sublist(offset, end);
      await characteristic.writeValue(chunk);
      if (offset + chunkSize < bytes.length) {
        await Future.delayed(delay);
      }
    }
  }
}

class BrowserWebBluetoothCharacteristic implements WebBluetoothCharacteristic {
  BrowserWebBluetoothCharacteristic(this.rawCharacteristic);

  final dynamic rawCharacteristic;

  @override
  String get uuid {
    try {
      return js_util.getProperty(rawCharacteristic, 'uuid')?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  @override
  bool get canWrite {
    try {
      final props = js_util.getProperty(rawCharacteristic, 'properties');
      if (props == null) return false;
      final write = js_util.getProperty(props, 'write') == true;
      final writeNoResp =
          js_util.getProperty(props, 'writeWithoutResponse') == true;
      return write || writeNoResp;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> writeValue(Uint8List bytes) async {
    try {
      final props = js_util.getProperty(rawCharacteristic, 'properties');
      final writeNoResp =
          props != null && js_util.getProperty(props, 'writeWithoutResponse') == true;

      if (writeNoResp &&
          js_util.hasProperty(rawCharacteristic, 'writeValueWithoutResponse')) {
        await js_util.promiseToFuture<dynamic>(
          js_util.callMethod(
              rawCharacteristic, 'writeValueWithoutResponse', [bytes]),
        );
      } else if (js_util.hasProperty(
          rawCharacteristic, 'writeValueWithResponse')) {
        await js_util.promiseToFuture<dynamic>(
          js_util.callMethod(
              rawCharacteristic, 'writeValueWithResponse', [bytes]),
        );
      } else {
        await js_util.promiseToFuture<dynamic>(
          js_util.callMethod(rawCharacteristic, 'writeValue', [bytes]),
        );
      }
    } catch (e) {
      throw Exception('Failed writing bytes to BLE characteristic: $e');
    }
  }
}
