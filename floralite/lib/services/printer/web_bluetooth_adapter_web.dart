// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:js' as js;
import 'dart:typed_data';

import 'web_bluetooth_adapter.dart';

WebBluetoothAdapter createWebBluetoothAdapter() => BrowserWebBluetoothAdapter();

Future<dynamic> _promiseToFuture(dynamic promise) {
  final completer = Completer<dynamic>();
  try {
    final jsPromise = promise is js.JsObject
        ? promise
        : js.JsObject.fromBrowserObject(promise);
    final onResolve = js.JsFunction.withThis((_, [result]) {
      if (!completer.isCompleted) {
        completer.complete(result);
      }
    });
    final onReject = js.JsFunction.withThis((_, [error]) {
      if (!completer.isCompleted) {
        completer.completeError(error ?? 'Promise rejected');
      }
    });
    jsPromise.callMethod('then', [onResolve, onReject]);
  } catch (e) {
    if (!completer.isCompleted) {
      completer.completeError(e);
    }
  }
  return completer.future;
}

class BrowserWebBluetoothAdapter implements WebBluetoothAdapter {
  js.JsObject? get _bluetooth {
    try {
      final nav = js.context['navigator'] as js.JsObject?;
      if (nav != null && nav.hasProperty('bluetooth')) {
        final bt = nav['bluetooth'];
        if (bt != null) {
          return bt is js.JsObject ? bt : js.JsObject.fromBrowserObject(bt);
        }
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
    final options = js.JsObject.jsify({
      'acceptAllDevices': true,
      'optionalServices': servicesList,
    });

    try {
      final rawDevice = await _promiseToFuture(
        bt.callMethod('requestDevice', [options]),
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
      if (bt.hasProperty('getDevices')) {
        final rawDevices = await _promiseToFuture(
          bt.callMethod('getDevices', []),
        );
        if (rawDevices != null) {
          final jsDevices = rawDevices is js.JsObject
              ? rawDevices
              : js.JsObject.fromBrowserObject(rawDevices);
          final length = jsDevices['length'] as int? ?? 0;
          final list = <WebBluetoothDevice>[];
          for (var i = 0; i < length; i++) {
            final item = jsDevices[i];
            if (item != null) {
              list.add(BrowserWebBluetoothDevice(item));
            }
          }
          return list;
        }
      }
    } catch (_) {}
    return const [];
  }
}

class BrowserWebBluetoothDevice implements WebBluetoothDevice {
  BrowserWebBluetoothDevice(dynamic rawDevice)
      : _jsDevice = rawDevice is js.JsObject
            ? rawDevice
            : js.JsObject.fromBrowserObject(rawDevice);

  final js.JsObject _jsDevice;
  BrowserWebBluetoothCharacteristic? _cachedCharacteristic;

  js.JsObject? get _gatt {
    try {
      final gatt = _jsDevice['gatt'];
      if (gatt == null) return null;
      return gatt is js.JsObject ? gatt : js.JsObject.fromBrowserObject(gatt);
    } catch (_) {
      return null;
    }
  }

  @override
  String get id {
    try {
      return _jsDevice['id']?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  @override
  String get name {
    try {
      final val = _jsDevice['name']?.toString();
      if (val != null && val.trim().isNotEmpty) return val.trim();
    } catch (_) {}
    return 'Bluetooth Thermal Printer';
  }

  @override
  bool get isConnected {
    try {
      return _gatt?['connected'] == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> connect() async {
    final gatt = _gatt;
    if (gatt == null) {
      throw Exception('GATT server unavailable on this device');
    }
    if (isConnected) return;
    await _promiseToFuture(gatt.callMethod('connect', []));
    _cachedCharacteristic = null;
  }

  @override
  Future<void> disconnect() async {
    try {
      _gatt?.callMethod('disconnect', []);
    } catch (_) {}
    _cachedCharacteristic = null;
  }

  @override
  void onDisconnected(void Function() callback) {
    try {
      final listener = js.JsFunction.withThis((_, [__]) {
        _cachedCharacteristic = null;
        callback();
      });
      _jsDevice.callMethod('addEventListener', [
        'gattserverdisconnected',
        listener,
      ]);
    } catch (_) {}
  }

  @override
  Future<WebBluetoothCharacteristic?> findWritableCharacteristic() async {
    if (_cachedCharacteristic != null) return _cachedCharacteristic;

    final gatt = _gatt;
    if (gatt == null) return null;

    if (!isConnected) {
      await connect();
    }

    // Step 1: Probe known thermal primary services
    for (final serviceUuid in knownThermalServiceUuids) {
      try {
        final rawService = await _promiseToFuture(
          gatt.callMethod('getPrimaryService', [serviceUuid]),
        );
        if (rawService != null) {
          final service = rawService is js.JsObject
              ? rawService
              : js.JsObject.fromBrowserObject(rawService);
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
      final rawServices = await _promiseToFuture(
        gatt.callMethod('getPrimaryServices', []),
      );
      if (rawServices != null) {
        final jsServices = rawServices is js.JsObject
            ? rawServices
            : js.JsObject.fromBrowserObject(rawServices);
        final length = jsServices['length'] as int? ?? 0;
        for (var i = 0; i < length; i++) {
          final item = jsServices[i];
          if (item != null) {
            final service = item is js.JsObject
                ? item
                : js.JsObject.fromBrowserObject(item);
            final char = await _findWritableInService(service);
            if (char != null) {
              _cachedCharacteristic = char;
              return char;
            }
          }
        }
      }
    } catch (_) {}

    return null;
  }

  Future<BrowserWebBluetoothCharacteristic?> _findWritableInService(
      js.JsObject service) async {
    try {
      final rawChars = await _promiseToFuture(
        service.callMethod('getCharacteristics', []),
      );
      if (rawChars != null) {
        final jsChars = rawChars is js.JsObject
            ? rawChars
            : js.JsObject.fromBrowserObject(rawChars);
        final length = jsChars['length'] as int? ?? 0;
        for (var i = 0; i < length; i++) {
          final item = jsChars[i];
          if (item != null) {
            final charObj = BrowserWebBluetoothCharacteristic(item);
            if (charObj.canWrite) {
              return charObj;
            }
          }
        }
      }
    } catch (_) {}
    return null;
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
  BrowserWebBluetoothCharacteristic(dynamic rawCharacteristic)
      : _jsChar = rawCharacteristic is js.JsObject
            ? rawCharacteristic
            : js.JsObject.fromBrowserObject(rawCharacteristic);

  final js.JsObject _jsChar;

  @override
  String get uuid {
    try {
      return _jsChar['uuid']?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  @override
  bool get canWrite {
    try {
      final props = _jsChar['properties'] as js.JsObject?;
      if (props == null) return false;
      final write = props['write'] == true;
      final writeNoResp = props['writeWithoutResponse'] == true;
      return write || writeNoResp;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> writeValue(Uint8List bytes) async {
    try {
      final props = _jsChar['properties'] as js.JsObject?;
      final writeNoResp = props != null && props['writeWithoutResponse'] == true;
      final jsArray = js.JsObject(js.context['Uint8Array'], [bytes]);

      if (writeNoResp && _jsChar.hasProperty('writeValueWithoutResponse')) {
        await _promiseToFuture(
          _jsChar.callMethod('writeValueWithoutResponse', [jsArray]),
        );
      } else if (_jsChar.hasProperty('writeValueWithResponse')) {
        await _promiseToFuture(
          _jsChar.callMethod('writeValueWithResponse', [jsArray]),
        );
      } else {
        await _promiseToFuture(
          _jsChar.callMethod('writeValue', [jsArray]),
        );
      }
    } catch (e) {
      throw Exception('Failed writing bytes to BLE characteristic: $e');
    }
  }
}
