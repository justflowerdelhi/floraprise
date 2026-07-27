import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

Future<String?> showCameraBarcodeScanner(
  BuildContext context, {
  required String title,
}) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _CameraBarcodeScannerPage(title: title),
    ),
  );
}

class _CameraBarcodeScannerPage extends StatefulWidget {
  const _CameraBarcodeScannerPage({required this.title});

  final String title;

  @override
  State<_CameraBarcodeScannerPage> createState() =>
      _CameraBarcodeScannerPageState();
}

class _CameraBarcodeScannerPageState extends State<_CameraBarcodeScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) {
      return;
    }

    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue?.trim();
      if (code == null || code.isEmpty) {
        continue;
      }

      _handled = true;
      await _controller.stop();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(code);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Point camera at barcode to scan',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
