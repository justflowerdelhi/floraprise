import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/first_use_permission_service.dart';
import 'web_camera_barcode_scanner_stub.dart'
    if (dart.library.html) 'web_camera_barcode_scanner.dart';

Future<String?> showCameraBarcodeScanner(
  BuildContext context, {
  required String title,
}) {
  return _showCameraScannerWithPermission(
    context: context,
    title: title,
  );
}

Future<String?> _showCameraScannerWithPermission({
  required BuildContext context,
  required String title,
}) async {
  final granted = await FirstUsePermissionService.ensurePermission(
    context: context,
    flowKey: 'camera.capture_or_scan',
    permission: Permission.camera,
    title: 'Use camera to capture product photos and delivery proof.',
    body:
        'Floraprise requests camera access only when you use camera features.',
    permanentlyDeniedMessage:
        'Camera permission is disabled. You can enable it anytime from Settings > Apps > Floraprise > Permissions to use camera features.',
  );

  if (!granted || !context.mounted) {
    return null;
  }

  return Navigator.of(context).push<String>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => CameraBarcodeScannerPage(title: title),
    ),
  );
}

class CameraBarcodeScannerPage extends StatefulWidget {
  const CameraBarcodeScannerPage({super.key, required this.title});

  final String title;

  @override
  State<CameraBarcodeScannerPage> createState() =>
      CameraBarcodeScannerPageState();
}

class CameraBarcodeScannerPageState extends State<CameraBarcodeScannerPage> {
  late MobileScannerController _controller;
  late final FocusNode _focusNode;

  int _scannerKey = 0;
  bool _handled = false;
  bool _isRestarting = false;
  bool _isManualDialogOpen = false;

  final StringBuffer _barcodeBuffer = StringBuffer();
  final List<DateTime> _keystrokeTimestamps = [];

  static MobileScannerController _createController() {
    debugPrint('[BARCODE] Initializing MobileScannerController (web: $kIsWeb, facing: ${kIsWeb ? "front" : "back"})');
    return MobileScannerController(
      detectionSpeed: DetectionSpeed.unrestricted,
      facing: kIsWeb ? CameraFacing.front : CameraFacing.back,
      formats: const [
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.qrCode,
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = _createController();
    _focusNode = FocusNode();
    initWebBarcodeScannerDiagnostics(
      onCodeDetected: (code) {
        if (mounted && !_handled) {
          completeWithCode(code);
        }
      },
      focusNode: _focusNode,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_handled) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _handled = true;
    stopWebBarcodeScannerDiagnostics();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void completeWithCode(String rawCode) {
    if (_handled || !mounted) return;
    _handled = true;
    stopWebBarcodeScannerDiagnostics();

    final code = rawCode.trim();
    if (code.isEmpty) return;
    debugPrint('[BARCODE] completeWithCode: $code');

    try {
      _focusNode.unfocus();
    } catch (_) {}

    try {
      _controller.stop();
    } catch (_) {}

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop(code);
      }
    });
  }

  void cancelAndPop() {
    if (_handled || !mounted) return;
    _handled = true;
    stopWebBarcodeScannerDiagnostics();

    try {
      _focusNode.unfocus();
    } catch (_) {}

    try {
      _controller.stop();
    } catch (_) {}

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  Future<void> _tryAgain() async {
    if (_handled || !mounted || _isRestarting) return;
    setState(() {
      _isRestarting = true;
    });

    stopWebBarcodeScannerDiagnostics();

    try {
      await _controller.stop();
    } catch (_) {}
    try {
      _controller.dispose();
    } catch (_) {}

    if (!mounted) return;

    _controller = _createController();
    initWebBarcodeScannerDiagnostics(
      onCodeDetected: (code) {
        if (mounted && !_handled) {
          completeWithCode(code);
        }
      },
      focusNode: _focusNode,
    );
    setState(() {
      _scannerKey++;
      _isRestarting = false;
    });
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled || !mounted) {
      return;
    }

    debugPrint('[BARCODE] _onDetect received ${capture.barcodes.length} barcode(s)');
    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue?.trim();
      debugPrint('[BARCODE] Scanned barcode: format=${barcode.format}, value=$code');
      if (code != null && code.isNotEmpty) {
        completeWithCode(code);
        return;
      }
    }
  }

  void handleKeyEvent(KeyEvent event, {DateTime? customNow}) {
    if (_handled || _isManualDialogOpen || !mounted) return;

    if (event is! KeyDownEvent) return;

    final now = customNow ?? DateTime.now();

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      cancelAndPop();
      return;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      final code = _barcodeBuffer.toString().trim();
      final timestamps = List<DateTime>.from(_keystrokeTimestamps);
      _barcodeBuffer.clear();
      _keystrokeTimestamps.clear();

      if (code.length >= 3 && timestamps.length >= 3) {
        final totalDuration =
            timestamps.last.difference(timestamps.first).inMilliseconds;
        final averageInterval = totalDuration / (timestamps.length - 1);
        // USB/Bluetooth barcode scanners transmit characters in rapid bursts (typically < 100ms per key)
        if (averageInterval <= 100) {
          debugPrint('[BARCODE] Hardware scanner detected sequence: $code (avg interval ${averageInterval.toStringAsFixed(1)}ms)');
          completeWithCode(code);
          return;
        }
      }
      return;
    }

    final char = event.character;
    if (char != null &&
        char.isNotEmpty &&
        !char.contains(RegExp(r'[\r\n\t]'))) {
      if (_keystrokeTimestamps.isNotEmpty &&
          now.difference(_keystrokeTimestamps.last).inMilliseconds > 500) {
        _barcodeBuffer.clear();
        _keystrokeTimestamps.clear();
      }
      _barcodeBuffer.write(char);
      _keystrokeTimestamps.add(now);
    }
  }

  Future<void> _showManualEntryDialog() async {
    if (_handled || !mounted) return;
    _isManualDialogOpen = true;

    final textController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final code = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Enter Barcode Manually'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: textController,
              autofocus: true,
              textInputAction: TextInputAction.done,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'Barcode',
                hintText: 'Enter product barcode',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code_scanner),
              ),
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) {
                  return 'Please enter a barcode';
                }
                return null;
              },
              onFieldSubmitted: (_) {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(dialogContext).pop(textController.text.trim());
                }
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
              ),
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(dialogContext).pop(textController.text.trim());
                }
              },
              child: const Text('Use Barcode'),
            ),
          ],
        );
      },
    );

    _isManualDialogOpen = false;
    textController.dispose();

    if (code != null && code.trim().isNotEmpty && mounted && !_handled) {
      completeWithCode(code.trim());
    } else {
      if (mounted && !_handled) {
        _focusNode.requestFocus();
      }
    }
  }

  String _getErrorTitle(MobileScannerException error) {
    final details = error.errorDetails?.message?.toLowerCase() ?? '';
    if (error.errorCode == MobileScannerErrorCode.permissionDenied ||
        details.contains('notallowederror') ||
        details.contains('permission')) {
      return 'Camera Permission Blocked';
    }
    if (details.contains('notfounderror') || details.contains('not found')) {
      return 'Camera Not Found';
    }
    if (details.contains('notreadableerror') ||
        details.contains('trackstarterror') ||
        details.contains('in use') ||
        details.contains('busy')) {
      return 'Camera Unavailable';
    }
    if (error.errorCode == MobileScannerErrorCode.unsupported ||
        details.contains('notsupportederror') ||
        details.contains('unsupported')) {
      return 'Camera Scanning Unsupported';
    }
    return 'Camera Error';
  }

  String _getErrorMessage(MobileScannerException error) {
    final details = error.errorDetails?.message?.toLowerCase() ?? '';

    if (error.errorCode == MobileScannerErrorCode.permissionDenied ||
        details.contains('notallowederror') ||
        details.contains('permission')) {
      return kIsWeb
          ? 'Camera access is blocked. Please allow camera access in your browser address bar or settings.'
          : 'Camera permission is denied. Please enable camera access in your device settings.';
    }

    if (details.contains('notfounderror') || details.contains('not found')) {
      return kIsWeb
          ? 'No camera was found on this computer.'
          : 'No camera found on this device.';
    }

    if (details.contains('notreadableerror') ||
        details.contains('trackstarterror') ||
        details.contains('in use') ||
        details.contains('busy')) {
      return 'The camera is currently unavailable. It may be in use by another application or browser tab.';
    }

    if (error.errorCode == MobileScannerErrorCode.unsupported ||
        details.contains('notsupportederror') ||
        details.contains('unsupported')) {
      return kIsWeb
          ? 'Camera scanning is not available in this browser.'
          : 'Camera scanning is not supported on this device.';
    }

    if (details.contains('barcodereader script') ||
        details.contains('network error')) {
      return 'Unable to load the barcode scanner engine. Please check your network connection or enter barcode manually.';
    }

    if (details.contains('overconstrained')) {
      return 'The requested camera mode is not supported by your camera hardware.';
    }

    return 'Unable to start the camera scanner. You can enter the barcode manually.';
  }

  Widget _buildErrorWidget(BuildContext context, MobileScannerException error) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.videocam_off_outlined,
                  size: 48,
                  color: Colors.orangeAccent,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _getErrorTitle(error),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _getErrorMessage(error),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: _isRestarting ? null : _tryAgain,
                    icon: _isRestarting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.refresh, size: 18),
                    label: const Text('Try Again'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _showManualEntryDialog,
                    icon: const Icon(Icons.keyboard_outlined, size: 18),
                    label: const Text('Enter Barcode Manually'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 500;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        _handled = true;
        try {
          _controller.stop();
        } catch (_) {}
      },
      child: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: handleKeyEvent,
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: Text(widget.title),
            actions: [
              if (isWide || kIsWeb)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.keyboard_outlined, size: 18),
                  label: const Text('Enter Manually'),
                  onPressed: _showManualEntryDialog,
                )
              else
                IconButton(
                  icon: const Icon(Icons.keyboard_outlined),
                  tooltip: 'Enter Barcode Manually',
                  onPressed: _showManualEntryDialog,
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                key: ValueKey(_scannerKey),
                controller: _controller,
                onDetect: _onDetect,
                errorBuilder: (context, error, child) =>
                    _buildErrorWidget(context, error),
              ),
              ValueListenableBuilder<MobileScannerState>(
                valueListenable: _controller,
                builder: (context, state, _) {
                  if (state.error != null) {
                    return const SizedBox.shrink();
                  }
                  return ScannerOverlay(
                    onManualEntry: _showManualEntryDialog,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScannerOverlay extends StatefulWidget {
  const ScannerOverlay({
    super.key,
    required this.onManualEntry,
  });

  final VoidCallback onManualEntry;

  @override
  State<ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<ScannerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanAnimationController;

  @override
  void initState() {
    super.initState();
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        // Viewport rectangle calculation:
        final boxWidth = (screenWidth * 0.68).clamp(280.0, 500.0).toDouble();
        final boxHeight = (screenHeight * 0.22).clamp(140.0, 220.0).toDouble();

        final left = (screenWidth - boxWidth) / 2;
        final top = (screenHeight - boxHeight) / 2 - 24;
        final scanRect = Rect.fromLTWH(left, top, boxWidth, boxHeight);

        return Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: _scanAnimationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ScannerOverlayPainter(
                    scanRect: scanRect,
                    animationValue: _scanAnimationController.value,
                  ),
                );
              },
            ),
            Positioned(
              top: (scanRect.top - 44).clamp(12.0, screenHeight),
              left: 16,
              right: 16,
              child: const Text(
                'Align barcode inside the box',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: Colors.black87,
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: scanRect.bottom + 16,
              left: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Position the barcode until it looks sharp and fits inside the box.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      shadows: [
                        Shadow(
                          color: Colors.black87,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: widget.onManualEntry,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              const Color(0xFFE2C48D).withValues(alpha: 0.6),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.keyboard_outlined,
                            size: 16,
                            color: Color(0xFFE2C48D),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Or enter barcode manually',
                            style: TextStyle(
                              color: Color(0xFFE2C48D),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  _ScannerOverlayPainter({
    required this.scanRect,
    required this.animationValue,
  });

  final Rect scanRect;
  final double animationValue;

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = const Color(0x99000000);
    final borderPaint = Paint()
      ..color = const Color(0xFF00E676)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final subtleBorderPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final rrect =
        RRect.fromRectAndRadius(scanRect, const Radius.circular(12));

    // 1. Darkened backdrop cutout
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()..addRRect(rrect);
    final overlayPath =
        Path.combine(PathOperation.difference, backgroundPath, cutoutPath);
    canvas.drawPath(overlayPath, backgroundPaint);

    // 2. Subtle border around full cutout
    canvas.drawRRect(rrect, subtleBorderPaint);

    // 3. Corner brackets
    const cornerLength = 24.0;
    const radius = 12.0;
    final path = Path();

    // Top-left corner
    path.moveTo(scanRect.left, scanRect.top + cornerLength);
    path.lineTo(scanRect.left, scanRect.top + radius);
    path.arcToPoint(
      Offset(scanRect.left + radius, scanRect.top),
      radius: const Radius.circular(radius),
    );
    path.lineTo(scanRect.left + cornerLength, scanRect.top);

    // Top-right corner
    path.moveTo(scanRect.right - cornerLength, scanRect.top);
    path.lineTo(scanRect.right - radius, scanRect.top);
    path.arcToPoint(
      Offset(scanRect.right, scanRect.top + radius),
      radius: const Radius.circular(radius),
    );
    path.lineTo(scanRect.right, scanRect.top + cornerLength);

    // Bottom-right corner
    path.moveTo(scanRect.right, scanRect.bottom - cornerLength);
    path.lineTo(scanRect.right, scanRect.bottom - radius);
    path.arcToPoint(
      Offset(scanRect.right - radius, scanRect.bottom),
      radius: const Radius.circular(radius),
    );
    path.lineTo(scanRect.right - cornerLength, scanRect.bottom);

    // Bottom-left corner
    path.moveTo(scanRect.left + cornerLength, scanRect.bottom);
    path.lineTo(scanRect.left + radius, scanRect.bottom);
    path.arcToPoint(
      Offset(scanRect.left, scanRect.bottom - radius),
      radius: const Radius.circular(radius),
    );
    path.lineTo(scanRect.left, scanRect.bottom - cornerLength);

    canvas.drawPath(path, borderPaint);

    // 4. Glowing animated scan line inside cutout
    final lineY = scanRect.top + 8 + (scanRect.height - 16) * animationValue;
    final scanLineRect = Rect.fromLTWH(
      scanRect.left + 8,
      lineY - 1.5,
      scanRect.width - 16,
      3.0,
    );

    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF00E676).withValues(alpha: 0.0),
          const Color(0xFF00E676).withValues(alpha: 0.8),
          const Color(0xFF00E676),
          const Color(0xFF00E676).withValues(alpha: 0.8),
          const Color(0xFF00E676).withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
      ).createShader(scanLineRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(scanLineRect, const Radius.circular(1.5)),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.scanRect != scanRect;
  }
}
