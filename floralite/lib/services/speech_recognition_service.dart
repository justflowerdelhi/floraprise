import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'first_use_permission_service.dart';

class SpeechRecognitionService {
  SpeechRecognitionService({SpeechToText? speech, BuildContext? context})
      : _speech = speech ?? SpeechToText(),
        _context = context;

  final SpeechToText _speech;
  final BuildContext? _context;
  bool _initialized = false;
  bool _shouldListen = false;
  bool _starting = false;
  Timer? _restartTimer;
  Timer? _partialCommitTimer;
  String _lastPartialWords = '';
  String _lastEmittedWords = '';
  DateTime? _lastEmittedAt;
  void Function(String words)? _onResult;
  void Function(String words)? _onTranscript;
  void Function(String message)? _onError;
  void Function(bool listening)? _onListeningChanged;
  String? _startFailureMessage;

  bool get isListening => _shouldListen;
  String? get startFailureMessage => _startFailureMessage;

  Future<bool> startContinuous({
    required void Function(String words) onResult,
    void Function(String words)? onTranscript,
    required void Function(String message) onError,
    required void Function(bool listening) onListeningChanged,
  }) async {
    _startFailureMessage = null;
    _onResult = onResult;
    _onTranscript = onTranscript;
    _onError = onError;
    _onListeningChanged = onListeningChanged;

    final permissionOk = await _ensureRuntimePermission();
    if (!permissionOk) {
      return false;
    }

    if (!_initialized) {
      _initialized = await _speech.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
      );
    }
    if (!_initialized) {
      _startFailureMessage ??=
          'Speech recognition is not available on this device.';
      return false;
    }

    final hasPermission = await _speech.hasPermission;
    if (!hasPermission) {
      _startFailureMessage =
          'Microphone permission is missing for speech recognition.';
      return false;
    }

    final isAvailable = _speech.isAvailable;
    if (!isAvailable) {
      _startFailureMessage =
          'Speech recognizer is unavailable on this device. Install or enable a speech service.';
      return false;
    }

    _shouldListen = true;
    _onListeningChanged?.call(true);
    await _startSession();
    return true;
  }

  Future<void> stop() async {
    _shouldListen = false;
    _restartTimer?.cancel();
    _partialCommitTimer?.cancel();
    _lastPartialWords = '';
    _lastEmittedWords = '';
    _lastEmittedAt = null;
    await _speech.stop();
    _onListeningChanged?.call(false);
  }

  Future<void> dispose() async {
    await stop();
    _onResult = null;
    _onTranscript = null;
    _onError = null;
    _onListeningChanged = null;
  }

  Future<void> _startSession() async {
    if (!_shouldListen || _starting || _speech.isListening) return;
    _starting = true;
    try {
      await _listenWithFallback();
    } finally {
      _starting = false;
    }
  }

  Future<void> _listenWithFallback() async {
    final primaryOptions = SpeechListenOptions(
      listenMode: ListenMode.dictation,
      // Prefer compatibility across Android engines.
      onDevice: false,
      partialResults: true,
      cancelOnError: false,
      autoPunctuation: false,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );

    try {
      await _speech.listen(
        onResult: _handleResult,
        listenOptions: primaryOptions,
      );
      return;
    } catch (_) {
      // Fallback for engines that reject the first option set.
    }

    await _speech.listen(
      onResult: _handleResult,
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        onDevice: true,
        partialResults: true,
        cancelOnError: false,
        autoPunctuation: false,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      ),
    );
  }

  void _handleResult(SpeechRecognitionResult result) {
    final words = result.recognizedWords.trim();
    if (words.isEmpty) return;
    _onTranscript?.call(words);

    if (result.finalResult) {
      _partialCommitTimer?.cancel();
      _lastPartialWords = words;
      _emitResult(words);
      return;
    }

    _lastPartialWords = words;
    // Some Android engines intermittently skip final results. Commit
    // the latest partial when speech has been stable for a short window.
    _partialCommitTimer?.cancel();
    _partialCommitTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!_shouldListen || _lastPartialWords.trim().isEmpty) return;
      final candidate = _lastPartialWords.trim();
      if (_looksLikePhrase(candidate)) {
        _emitResult(candidate);
      }
    });
  }

  void _emitResult(String words) {
    final normalized =
        words.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) return;

    // Some engines only emit useful text on committed/final callbacks.
    // Mirror committed text to transcript UI so "Heard" always updates.
    _onTranscript?.call(words);

    final now = DateTime.now();
    if (normalized == _lastEmittedWords &&
        _lastEmittedAt != null &&
        now.difference(_lastEmittedAt!) < const Duration(seconds: 8)) {
      return;
    }

    _lastEmittedWords = normalized;
    _lastEmittedAt = now;
    _onResult?.call(words);
  }

  bool _looksLikePhrase(String words) {
    final tokenCount = words
        .split(RegExp(r'\s+'))
        .where((token) => token.trim().isNotEmpty)
        .length;
    return tokenCount >= 3;
  }

  void _handleStatus(String status) {
    if (!_shouldListen) return;
    if (status == SpeechToText.doneStatus ||
        status == SpeechToText.notListeningStatus) {
      _scheduleRestart();
    }
  }

  void _handleError(SpeechRecognitionError error) {
    if (!_shouldListen) return;
    if (_isActionableError(error)) {
      _onError?.call(error.errorMsg);
    }
    if (!error.permanent) _scheduleRestart();
  }

  bool _isNoMatchError(String value) {
    final normalized = value.toLowerCase();
    return normalized.contains('no_match') ||
        normalized.contains('no match') ||
        normalized.contains('error_no_match');
  }

  bool _isActionableError(SpeechRecognitionError error) {
    final normalized = error.errorMsg.toLowerCase();

    // These can still appear as "permanent" in some engines but are transient
    // during continuous dictation and should not be surfaced to users.
    if (normalized.contains('speech_timeout') ||
        normalized.contains('speech timeout') ||
        normalized.contains('no speech') ||
        normalized.contains('error_client') ||
        normalized.contains('client') ||
        normalized.contains('recognizer busy') ||
        normalized.contains('busy') ||
        normalized.contains('retry')) {
      return false;
    }

    if (_isNoMatchError(normalized)) {
      return false;
    }

    if (error.permanent) {
      return true;
    }

    return true;
  }

  Future<bool> _ensureRuntimePermission() async {
    final granted = await FirstUsePermissionService.ensurePermission(
      context: _context,
      flowKey: 'microphone.voice_entry',
      permission: Permission.microphone,
      title: 'Floraprise uses your microphone',
      body:
          'Floraprise uses your microphone to understand your voice commands.\n\nYour recordings are processed only for voice input.',
      permanentlyDeniedMessage:
          'Microphone permission is disabled. You can enable it anytime from Settings > Apps > Floraprise > Permissions to use Voice Entry.',
    );

    if (granted) return true;

    final status = await Permission.microphone.status;
    if (status.isPermanentlyDenied || status.isRestricted) {
      _startFailureMessage =
          'Microphone permission is disabled. Enable it in app settings to use Voice Entry.';
      return false;
    }

    _startFailureMessage =
        'Microphone permission is required for voice stock entry.';
    return false;
  }

  void _scheduleRestart() {
    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(milliseconds: 250), _startSession);
  }
}
