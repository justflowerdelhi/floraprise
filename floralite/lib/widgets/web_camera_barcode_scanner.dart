// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use, avoid_print
import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;

import 'package:flutter/widgets.dart';

Timer? _scannerLoopTimer;
bool _isWebScannerActive = false;
int _decodeAttemptCount = 0;
DateTime? _lastThrottledLogTime;

void _log(String message) {
  // Visible in release & debug mode in browser devtools and flutter console
  print(message);
  try {
    html.window.console.log(message);
  } catch (_) {}
}

void initWebBarcodeScannerDiagnostics({
  required void Function(String code) onCodeDetected,
  required FocusNode focusNode,
}) {
  stopWebBarcodeScannerDiagnostics();
  _isWebScannerActive = true;
  _decodeAttemptCount = 0;
  _lastThrottledLogTime = null;

  _log('[CAMERA] getUserMedia started');

  // Start initialization pipeline in background
  unawaited(_runWebBarcodeScannerPipeline(onCodeDetected));
}

Future<void> _runWebBarcodeScannerPipeline(
  void Function(String code) onCodeDetected,
) async {
  try {
    // 1. Wait for video element in DOM
    html.VideoElement? videoElement;
    final deadline = DateTime.now().add(const Duration(seconds: 10));

    while (_isWebScannerActive && DateTime.now().isBefore(deadline)) {
      final videos = html.document.querySelectorAll('video');
      if (videos.isNotEmpty) {
        videoElement = videos.first as html.VideoElement;
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    if (!_isWebScannerActive || videoElement == null) {
      _log('[CAMERA] Error: Video element not found in DOM within timeout');
      return;
    }

    _log('[CAMERA] video element attached');

    // 2. Wait for video stream and metadata
    final stream = videoElement.srcObject;
    if (stream is html.MediaStream) {
      final tracks = stream.getVideoTracks();
      final trackLabel = tracks.isNotEmpty ? tracks.first.label : 'unknown';
      _log('[CAMERA] stream obtained (track: $trackLabel, count: ${tracks.length})');

      // Request ideal 1280x720 resolution with safe fallback
      if (tracks.isNotEmpty) {
        final track = tracks.first;
        try {
          final jsTrack = js.JsObject.fromBrowserObject(track);
          if (jsTrack.hasProperty('applyConstraints')) {
            final constraintsObj = js.JsObject.jsify({
              'width': {'ideal': 1280},
              'height': {'ideal': 720},
            });
            final completer = Completer<void>();
            final promise = jsTrack.callMethod('applyConstraints', [constraintsObj]);
            if (promise != null && promise is js.JsObject && promise.hasProperty('then')) {
              promise.callMethod('then', [
                (_) {
                  if (!completer.isCompleted) completer.complete();
                },
                (err) {
                  _log('[CAMERA] applyConstraints notice: $err');
                  if (!completer.isCompleted) completer.complete();
                },
              ]);
              await completer.future.timeout(
                const Duration(seconds: 2),
                onTimeout: () {
                  _log('[CAMERA] applyConstraints timeout, continuing with current stream');
                },
              );
            }
          }
        } catch (e) {
          _log('[CAMERA] applyConstraints fallback: $e');
        }
      }
    } else {
      _log('[CAMERA] stream attached to video element');
    }

    // Wait until video has valid dimensions (metadata loaded)
    int waitCount = 0;
    while (_isWebScannerActive && videoElement.videoWidth == 0 && waitCount < 50) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      waitCount++;
    }

    if (!_isWebScannerActive) return;

    // Inspect actual track settings and video quality
    String trackSettingsStr = 'unavailable';
    if (stream is html.MediaStream && stream.getVideoTracks().isNotEmpty) {
      try {
        final jsTrack = js.JsObject.fromBrowserObject(stream.getVideoTracks().first);
        if (jsTrack.hasProperty('getSettings')) {
          final settings = jsTrack.callMethod('getSettings');
          if (settings != null) {
            final jsonStringify = js.context['JSON']['stringify'] as js.JsFunction;
            trackSettingsStr = jsonStringify.apply([settings]) as String;
          }
        }
      } catch (e) {
        trackSettingsStr = 'error: $e';
      }
    }

    _log(
      '[CAMERA] video metadata loaded (${videoElement.videoWidth}x${videoElement.videoHeight}, readyState: ${videoElement.readyState})',
    );
    _log('[CAMERA] video resolution: ${videoElement.videoWidth}x${videoElement.videoHeight}');
    _log('[CAMERA] track settings: $trackSettingsStr');
    _log(
      '[CAMERA] video.play completed (playing: ${!videoElement.paused && !videoElement.ended})',
    );

    // 3. Ensure ZXing library is loaded
    if (js.context['ZXing'] == null) {
      _log('[ZXING] Loading ZXing library from unpkg...');
      final scriptLoaded = Completer<void>();

      var script = html.document.querySelector('script#mobile-scanner-barcode-reader') as html.ScriptElement?;
      if (script == null) {
        script = html.ScriptElement()
          ..id = 'mobile-scanner-barcode-reader'
          ..src = 'https://unpkg.com/@zxing/library@0.21.3'
          ..async = true
          ..type = 'application/javascript';
        html.document.head?.append(script);
      }

      script.onLoad.listen((_) {
        if (!scriptLoaded.isCompleted) scriptLoaded.complete();
      });
      script.onError.listen((e) {
        if (!scriptLoaded.isCompleted) {
          scriptLoaded.completeError('Failed to load ZXing script: $e');
        }
      });

      // If already loaded in between
      if (js.context['ZXing'] != null && !scriptLoaded.isCompleted) {
        scriptLoaded.complete();
      }

      await scriptLoaded.future.timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          _log('[ZXING] Error: ZXing script load timeout');
        },
      );
    }

    if (!_isWebScannerActive) return;

    final zxing = js.context['ZXing'] as js.JsObject?;
    if (zxing == null) {
      _log('[ZXING] Error: window.ZXing global is undefined after script load');
      return;
    }

    _log('[ZXING] library loaded (window.ZXing available)');

    // 4. Initialize ZXing Reader with full 1D and 2D formats + TRY_HARDER
    final jsMapConstructor = js.context['Map'] as js.JsFunction;
    final hints = js.JsObject(jsMapConstructor);

    final decodeHintType = zxing['DecodeHintType'] as js.JsObject?;
    final barcodeFormat = zxing['BarcodeFormat'] as js.JsObject?;

    final possibleFormatsHintKey = decodeHintType != null ? decodeHintType['POSSIBLE_FORMATS'] : 2;
    final tryHarderHintKey = decodeHintType != null ? decodeHintType['TRY_HARDER'] : 3;

    final formatsArray = js.JsArray.from([
      if (barcodeFormat != null) ...[
        barcodeFormat['CODE_128'],
        barcodeFormat['CODE_39'],
        barcodeFormat['EAN_13'],
        barcodeFormat['EAN_8'],
        barcodeFormat['UPC_A'],
        barcodeFormat['UPC_E'],
        barcodeFormat['QR_CODE'],
        barcodeFormat['ITF'],
        barcodeFormat['CODABAR'],
      ] else ...[
        4, // CODE_128
        2, // CODE_39
        7, // EAN_13
        6, // EAN_8
        14, // UPC_A
        15, // UPC_E
        11, // QR_CODE
        8, // ITF
        1, // CODABAR
      ]
    ]);

    hints.callMethod('set', [possibleFormatsHintKey, formatsArray]);
    hints.callMethod('set', [tryHarderHintKey, true]);

    final readerConstructor = zxing['BrowserMultiFormatReader'] as js.JsFunction;
    final reader = js.JsObject(readerConstructor, [hints, 100]);

    _log(
      '[ZXING] reader initialized (formats: [Code128, Code39, EAN13, EAN8, UPCA, UPCE, QRCode], tryHarder: true)',
    );

    // 5. Start continuous decode loop
    _log('[ZXING] decode frame size: ${videoElement.videoWidth}x${videoElement.videoHeight}');
    _log('[ZXING] decode loop started');

    _scannerLoopTimer?.cancel();
    _scannerLoopTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isWebScannerActive || videoElement == null) {
        timer.cancel();
        return;
      }

      if (videoElement.videoWidth == 0 || videoElement.paused || videoElement.ended) {
        return;
      }

      _decodeAttemptCount++;
      try {
        final result = reader.callMethod('decode', [videoElement]) as js.JsObject?;
        if (result != null) {
          final rawText = result['text']?.toString().trim();
          final format = result['format']?.toString();
          if (rawText != null && rawText.isNotEmpty) {
            _log('[BARCODE] detected: $rawText (format: $format)');
            stopWebBarcodeScannerDiagnostics();
            onCodeDetected(rawText);
            return;
          }
        }
      } catch (err) {
        final errMsg = err.toString();
        final now = DateTime.now();
        if (_lastThrottledLogTime == null ||
            now.difference(_lastThrottledLogTime!).inMilliseconds >= 1000) {
          _lastThrottledLogTime = now;
          if (errMsg.contains('No MultiFormat Readers') ||
              errMsg.contains('NotFoundException')) {
            _log(
              '[ZXING] decode attempt (count: $_decodeAttemptCount, status: scanning...)',
            );
          } else {
            _log(
              '[ZXING] decode attempt error (count: $_decodeAttemptCount, message: $errMsg)',
            );
          }
        }
      }
    });
  } catch (e) {
    _log('[CAMERA] Pipeline initialization error: $e');
  }
}

void stopWebBarcodeScannerDiagnostics() {
  if (_isWebScannerActive) {
    _log('[ZXING] decode loop stopped');
  }
  _isWebScannerActive = false;
  _scannerLoopTimer?.cancel();
  _scannerLoopTimer = null;
}
