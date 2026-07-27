enum PrinterConnectionKind { bluetooth }

class PrinterDevice {
  const PrinterDevice({
    required this.name,
    required this.address,
    this.connectionKind = PrinterConnectionKind.bluetooth,
  });

  final String name;
  final String address;
  final PrinterConnectionKind connectionKind;

  factory PrinterDevice.fromMap(Map<Object?, Object?> map) {
    return PrinterDevice(
      name: map['name']?.toString() ?? 'Bluetooth Printer',
      address: map['address']?.toString() ?? '',
    );
  }
}

typedef PrinterDeviceInfo = PrinterDevice;
