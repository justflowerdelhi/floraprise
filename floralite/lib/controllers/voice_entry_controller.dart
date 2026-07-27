import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../services/product_matcher.dart';
import '../services/speech_recognition_service.dart';
import '../services/voice_parser.dart';
import '../services/voice_stock_entry_service.dart';

class VoiceStockRow {
  const VoiceStockRow({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.purchasePricePaise,
  });

  final int productId;
  final String productName;
  final int quantity;
  final int purchasePricePaise;
}

class VoiceEntryController extends ChangeNotifier {
  VoiceEntryController({
    required SpeechRecognitionService speechRecognition,
    required VoiceStockEntryService voiceEntry,
  })  : _speechRecognition = speechRecognition,
        _voiceEntry = voiceEntry;

  final SpeechRecognitionService _speechRecognition;
  final VoiceStockEntryService _voiceEntry;
  final List<VoiceStockRow> _rows = [];
  bool _isListening = false;
  bool _isProcessing = false;
  String? _message;
  int _messageVersion = 0;
  VoiceStockRow? _recentlyAdded;
  VoiceParsedItem? _pendingItem;
  List<ProductMatchCandidate> _pendingMatches = const [];
  Timer? _addedTimer;
  String _lastWords = '';
  DateTime? _lastWordsAt;
  String _lastRowSignature = '';
  DateTime? _lastRowAddedAt;
  String _liveTranscript = '';
  DateTime? _lastHintAt;
  String? _pendingSpeechFragment;
  DateTime? _pendingSpeechFragmentAt;

  List<VoiceStockRow> get rows => List.unmodifiable(_rows);
  bool get isListening => _isListening;
  String get liveTranscript => _liveTranscript;
  String? get message => _message;
  int get messageVersion => _messageVersion;
  VoiceStockRow? get recentlyAdded => _recentlyAdded;
  VoiceParsedItem? get pendingItem => _pendingItem;
  List<ProductMatchCandidate> get pendingMatches => _pendingMatches;

  Future<bool> start() async {
    final started = await _speechRecognition.startContinuous(
      onResult: _handleWords,
      onTranscript: (words) {
        _liveTranscript = words;
        notifyListeners();
      },
      onError: (message) => _setMessage(_friendlySpeechError(message)),
      onListeningChanged: (value) {
        _isListening = value;
        if (!value) {
          _liveTranscript = '';
        }
        notifyListeners();
      },
    );
    if (started) {
      _isListening = true;
      await HapticFeedback.mediumImpact();
      notifyListeners();
    } else {
      _setMessage(
        _speechRecognition.startFailureMessage ??
            'Speech recognition is not available on this device.',
      );
    }
    return started;
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

  Future<void> stop() async {
    await _speechRecognition.stop();
    _isListening = false;
    _pendingSpeechFragment = null;
    _pendingSpeechFragmentAt = null;
    notifyListeners();
  }

  void chooseProduct(ProductMatchCandidate product) {
    final parsed = _pendingItem;
    if (parsed == null) return;
    _pendingItem = null;
    _pendingMatches = const [];
    _addRow(parsed, product);
  }

  void removeAt(int index) {
    _rows.removeAt(index);
    notifyListeners();
  }

  void removeFirst() {
    if (_rows.isEmpty) return;
    _rows.removeAt(0);
    notifyListeners();
  }

  void clear() {
    _rows.clear();
    notifyListeners();
  }

  void _handleWords(String words) {
    final now = DateTime.now();
    if (_isProcessing || _pendingMatches.isNotEmpty) return;
    if (words.toLowerCase() == _lastWords &&
        _lastWordsAt != null &&
        now.difference(_lastWordsAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastWords = words.toLowerCase();
    _lastWordsAt = now;
    _isProcessing = true;
    try {
      final candidateWords = _combineWithPendingFragment(words);
      final result = _voiceEntry.process(candidateWords);
      final parsed = result.parsed;
      if (parsed == null || result.match.type == ProductMatchType.notFound) {
        _updatePendingFragment(words);
        if (_looksLikeCompleteAttempt(words) && _canShowHint()) {
          _setMessage('Use: Quantity Product Price, e.g. 50 red roses 12.');
        }
        return;
      }
      _pendingSpeechFragment = null;
      _pendingSpeechFragmentAt = null;
      if (result.match.type == ProductMatchType.ambiguous) {
        _pendingItem = parsed;
        _pendingMatches = result.match.matches;
        notifyListeners();
        return;
      }
      _addRow(parsed, result.match.product!);
    } finally {
      _isProcessing = false;
    }
  }

  String _combineWithPendingFragment(String words) {
    final fragment = _pendingSpeechFragment;
    final fragmentAt = _pendingSpeechFragmentAt;
    if (fragment == null || fragment.trim().isEmpty || fragmentAt == null) {
      return words;
    }

    final freshEnough =
        DateTime.now().difference(fragmentAt) <= const Duration(seconds: 8);
    if (!freshEnough) {
      _pendingSpeechFragment = null;
      _pendingSpeechFragmentAt = null;
      return words;
    }

    final normalizedFragment = fragment.toLowerCase().trim();
    final normalizedWords = words.toLowerCase().trim();
    if (normalizedWords.isEmpty || normalizedWords == normalizedFragment) {
      return words;
    }

    return '$fragment $words'.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  void _updatePendingFragment(String words) {
    final normalized = words.trim();
    if (normalized.isEmpty) return;

    final hasLeadingQty = RegExp(r'^\d+\b').hasMatch(normalized);
    final hasTrailingPrice = RegExp(r'\b\d+(?:\.\d+)?$').hasMatch(normalized);

    // Example split: "20 white" then "lily 70".
    if (hasLeadingQty && !hasTrailingPrice) {
      _pendingSpeechFragment = normalized;
      _pendingSpeechFragmentAt = DateTime.now();
      return;
    }

    // If we already have a recent fragment, allow continuation chunks.
    if (_pendingSpeechFragment != null && _pendingSpeechFragmentAt != null) {
      final freshEnough =
          DateTime.now().difference(_pendingSpeechFragmentAt!) <=
              const Duration(seconds: 8);
      if (freshEnough) {
        _pendingSpeechFragment = '$_pendingSpeechFragment $normalized'
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        _pendingSpeechFragmentAt = DateTime.now();
      }
    }
  }

  void _addRow(VoiceParsedItem parsed, ProductMatchCandidate product) {
    final rowSignature =
        '${product.id}|${parsed.quantity}|${parsed.purchasePrice.toStringAsFixed(2)}';
    final now = DateTime.now();
    if (rowSignature == _lastRowSignature &&
        _lastRowAddedAt != null &&
        now.difference(_lastRowAddedAt!) < const Duration(seconds: 10)) {
      return;
    }

    final row = VoiceStockRow(
      productId: product.id,
      productName: product.name,
      quantity: parsed.quantity,
      purchasePricePaise: (parsed.purchasePrice * 100).round(),
    );

    _lastRowSignature = rowSignature;
    _lastRowAddedAt = now;
    _rows.add(row);
    _recentlyAdded = row;
    _pendingItem = null;
    _pendingMatches = const [];
    _addedTimer?.cancel();
    _addedTimer = Timer(const Duration(seconds: 1), () {
      _recentlyAdded = null;
      notifyListeners();
    });
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  bool _looksLikeCompleteAttempt(String words) {
    final normalized = words.toLowerCase();
    final tokenCount = normalized
        .split(RegExp(r'\s+'))
        .where((token) => token.trim().isNotEmpty)
        .length;
    final hasDigit = RegExp(r'\d').hasMatch(normalized);
    final hasNumberWord = RegExp(
      r'\b(one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety|hundred|thousand)\b',
    ).hasMatch(normalized);
    return tokenCount >= 3 && (hasDigit || hasNumberWord);
  }

  bool _canShowHint() {
    final now = DateTime.now();
    if (_lastHintAt != null &&
        now.difference(_lastHintAt!) < const Duration(seconds: 4)) {
      return false;
    }
    _lastHintAt = now;
    return true;
  }

  void _setMessage(String value) {
    _message = value;
    _messageVersion++;
    notifyListeners();
  }

  @override
  void dispose() {
    _addedTimer?.cancel();
    unawaited(_speechRecognition.dispose());
    super.dispose();
  }
}
