import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../services/speech_recognition_service.dart';

class VoiceDictationController extends ChangeNotifier {
  VoiceDictationController({
    required SpeechRecognitionService speechRecognition,
  }) : _speechRecognition = speechRecognition;

  final SpeechRecognitionService _speechRecognition;

  bool _isListening = false;
  String? _message;
  int _messageVersion = 0;
  String _liveTranscript = '';
  String _lastCommittedText = '';
  DateTime? _lastCommittedAt;
  TextEditingController? _boundController;
  FocusNode? _boundFocusNode;
  bool _isDisposed = false;

  bool get isListening => _isListening;
  String? get message => _message;
  int get messageVersion => _messageVersion;
  String get liveTranscript => _liveTranscript;

  void bindController(
    TextEditingController controller, {
    FocusNode? focusNode,
  }) {
    _boundController = controller;
    bindFocusNode(focusNode);
  }

  void unbindController(TextEditingController controller) {
    if (_boundController == controller) {
      _boundController = null;
      bindFocusNode(null);
    }
  }

  void bindFocusNode(FocusNode? focusNode) {
    if (identical(_boundFocusNode, focusNode)) {
      return;
    }

    _boundFocusNode?.removeListener(_onBoundFocusChanged);
    _boundFocusNode = focusNode;
    _boundFocusNode?.addListener(_onBoundFocusChanged);
  }

  Future<bool> start() async {
    if (_isDisposed) return false;

    if (_boundFocusNode != null && !_boundFocusNode!.hasFocus) {
      _boundFocusNode!.requestFocus();
    }

    final started = await _speechRecognition.startContinuous(
      onResult: _handleResult,
      onTranscript: (words) {
        if (_isDisposed) return;
        _liveTranscript = words;
        _notifySafely();
      },
      onError: (message) => _setMessage(_friendlySpeechError(message)),
      onListeningChanged: (value) {
        if (_isDisposed) return;
        _isListening = value;
        if (!value) {
          _liveTranscript = '';
        }
        _notifySafely();
      },
    );

    if (_isDisposed) return false;

    if (started) {
      _isListening = true;
      await HapticFeedback.mediumImpact();
      _notifySafely();
    } else {
      _setMessage(
        _speechRecognition.startFailureMessage ??
            'Speech recognition is not available on this device.',
      );
    }
    return started;
  }

  Future<void> stop() async {
    if (_isDisposed) return;
    await _speechRecognition.stop();
    if (_isDisposed) return;
    _isListening = false;
    _notifySafely();
  }

  void _onBoundFocusChanged() {
    if (_isDisposed) return;
    final hasFocus = _boundFocusNode?.hasFocus ?? false;
    if (_isListening && !hasFocus) {
      unawaited(stop());
    }
  }

  void _handleResult(String words) {
    if (_isDisposed) return;
    final normalized = _normalize(words);
    if (normalized.isEmpty) return;

    final now = DateTime.now();
    if (normalized == _lastCommittedText &&
        _lastCommittedAt != null &&
        now.difference(_lastCommittedAt!) < const Duration(seconds: 2)) {
      return;
    }

    _lastCommittedText = normalized;
    _lastCommittedAt = now;
    _liveTranscript = words;
    final controller = _boundController;
    if (controller != null) {
      controller.value = applyToValue(controller.value, words);
    }
    _notifySafely();
  }

  TextEditingValue applyToValue(TextEditingValue currentValue, String words) {
    final insertion = _formatInsertion(words);
    if (insertion.isEmpty) return currentValue;

    final selection = currentValue.selection;
    final text = currentValue.text;
    final rangeStart = selection.isValid ? selection.start : text.length;
    final rangeEnd = selection.isValid ? selection.end : text.length;
    final before = text.substring(0, rangeStart);
    final after = text.substring(rangeEnd);
    final prefix = _needsSpacer(before, insertion) ? ' ' : '';
    final suffix = _needsSpacer(insertion, after) ? ' ' : '';
    final nextText = '$before$prefix$insertion$suffix$after';
    final cursor =
        (before.length + prefix.length + insertion.length + suffix.length)
            .clamp(0, nextText.length);

    return TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }

  String _formatInsertion(String words) {
    var value = words.trim();
    if (value.isEmpty) return '';

    final replacements = <Pattern, String>{
      RegExp(r'\bnew line\b', caseSensitive: false): '\n',
      RegExp(r'\bcomma\b', caseSensitive: false): ',',
      RegExp(r'\bperiod\b', caseSensitive: false): '.',
      RegExp(r'\bfull stop\b', caseSensitive: false): '.',
      RegExp(r'\bquestion mark\b', caseSensitive: false): '?',
      RegExp(r'\bexclamation mark\b', caseSensitive: false): '!',
    };

    for (final entry in replacements.entries) {
      value = value.replaceAll(entry.key, entry.value);
    }

    value = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    return value;
  }

  bool _needsSpacer(String left, String right) {
    if (left.isEmpty || right.isEmpty) return false;
    if (left.endsWith('\n') || right.startsWith('\n')) return false;
    if (RegExp(r'[\s(\[\{\-\/\n]$').hasMatch(left)) return false;
    if (RegExp(r'^[,.;:!?\)\]\}]').hasMatch(right)) return false;
    return true;
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _friendlySpeechError(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('permission') ||
        normalized.contains('denied') ||
        normalized.contains('not allowed')) {
      return 'Microphone permission is blocked. Enable it in app settings.';
    }
    if (normalized.contains('network')) {
      return 'Speech service needs internet for this device language. Check connection and try again.';
    }
    if (normalized.contains('audio') || normalized.contains('recorder')) {
      return 'Microphone is busy or unavailable. Close other recording apps and try again.';
    }
    if (normalized.contains('recognizer busy') || normalized.contains('busy')) {
      return 'Voice recognizer is busy. Please wait a moment and try again.';
    }
    return 'Voice service unavailable (${message.trim()}).';
  }

  void _setMessage(String value) {
    if (_isDisposed) return;
    _message = value;
    _messageVersion++;
    _notifySafely();
  }

  void _notifySafely() {
    if (_isDisposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _boundFocusNode?.removeListener(_onBoundFocusChanged);
    unawaited(_speechRecognition.dispose());
    super.dispose();
  }
}
