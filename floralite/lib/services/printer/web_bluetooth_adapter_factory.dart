import 'web_bluetooth_adapter.dart';
import 'web_bluetooth_adapter_stub.dart'
    if (dart.library.html) 'web_bluetooth_adapter_web.dart' as impl;

WebBluetoothAdapter createDefaultWebBluetoothAdapter() =>
    impl.createWebBluetoothAdapter();
