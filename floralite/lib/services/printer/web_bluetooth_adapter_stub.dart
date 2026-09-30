import 'web_bluetooth_adapter.dart';

WebBluetoothAdapter createWebBluetoothAdapter() => _StubWebBluetoothAdapter();

class _StubWebBluetoothAdapter implements WebBluetoothAdapter {
  @override
  bool get isSupported => false;

  @override
  Future<WebBluetoothDevice?> requestDevice({List<String>? optionalServices}) async {
    return null;
  }

  @override
  Future<List<WebBluetoothDevice>> getDevices() async {
    return const [];
  }
}
