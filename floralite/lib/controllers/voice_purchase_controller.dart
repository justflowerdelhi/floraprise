import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../services/product_matcher.dart';
import '../services/speech_recognition_service.dart';
import '../services/voice_purchase_entry_service.dart';
import '../services/voice_purchase_parser.dart';

class VoicePurchaseAddedItem {
  const VoicePurchaseAddedItem({
    required this.productId,
    required this.productName,
    required this.spokenQuantity,
    required this.totalQuantity,
    required this.merged,
  });

  final int productId;
  final String productName;
  final int spokenQuantity;
  final int totalQuantity;
  final bool merged;
}

class VoicePurchaseApplyResult {
  const VoicePurchaseApplyResult({
    required this.merged,
    required this.totalQuantity,
  });

  final bool merged;
  final int totalQuantity;
}

class VoicePurchaseController extends ChangeNotifier {
  VoicePurchaseController({
    required SpeechRecognitionService speechRecognition,
    required VoicePurchaseEntryService voiceEntry,
    required Future<VoicePurchaseApplyResult> Function(
      ProductMatchCandidate product,
      VoicePurchaseParsedItem parsed,
    ) onApply,
  })  : _speechRecognition = speechRecognition,
        _voiceEntry = voiceEntry,
        _onApply = onApply;

  final SpeechRecognitionService _speechRecognition;
  final VoicePurchaseEntryService _voiceEntry;
  final Future<VoicePurchaseApplyResult> Function(
    ProductMatchCandidate product,
    VoicePurchaseParsedItem parsed,
  ) _onApply;

  bool _isListening = false;
  bool _isProcessing = false;
  String _liveTranscript = '';
  String? _message;
  int _messageVersion = 0;
  VoicePurchaseParsedItem? _pendingItem;
  List<ProductMatchCandidate> _pendingMatches = const [];
  VoicePurchaseAddedItem? _recentlyAdded;
  int _addedVersion = 0;
  Timer? _addedTimer;
  String _lastWords = '';
  DateTime? _lastWordsAt;
  DateTime? _lastHintAt;
  ProductMatchCandidate? _pendingQuantityProduct;
  bool _pendingSelectionNeedsQuantity = false;

  bool get isListening => _isListening;
  bool get isProcessing => _isProcessing;
  String get liveTranscript => _liveTranscript;
  String? get message => _message;
  int get messageVersion => _messageVersion;
  VoicePurchaseParsedItem? get pendingItem => _pendingItem;
  List<ProductMatchCandidate> get pendingMatches => _pendingMatches;
  VoicePurchaseAddedItem? get recentlyAdded => _recentlyAdded;
  int get addedVersion => _addedVersion;

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
          _pendingItem = null;
          _pendingMatches = const [];
          _pendingQuantityProduct = null;
          _pendingSelectionNeedsQuantity = false;
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

  Future<void> stop() async {
    await _speechRecognition.stop();
    _isListening = false;
    _pendingItem = null;
    _pendingMatches = const [];
    _pendingQuantityProduct = null;
    _pendingSelectionNeedsQuantity = false;
    notifyListeners();
  }

  Future<void> chooseProduct(ProductMatchCandidate product) async {
    final parsed = _pendingItem;
    if (parsed == null && !_pendingSelectionNeedsQuantity) return;

    if (_pendingSelectionNeedsQuantity) {
      _pendingSelectionNeedsQuantity = false;
      _pendingQuantityProduct = product;
      _pendingMatches = const [];
      _setMessage(
        'Quantity? Please say quantity for ${product.name}. Example: ${product.name} 200',
      );
      return;
    }

    _pendingItem = null;
    _pendingMatches = const [];
    notifyListeners();
    await _apply(product, parsed!);
  }

  void _handleWords(String words) {
    if (_isProcessing || _pendingMatches.isNotEmpty) return;

    final normalized = words.toLowerCase().trim();
    final now = DateTime.now();
    if (normalized == _lastWords &&
        _lastWordsAt != null &&
        now.difference(_lastWordsAt!) < const Duration(seconds: 2)) {
      return;
    }

    _lastWords = normalized;
    _lastWordsAt = now;

    final pendingProduct = _pendingQuantityProduct;
    if (pendingProduct != null) {
      final quantity = _voiceEntry.parser.parseQuantityOnly(words);
      if (quantity == null || quantity <= 0) {
        if (_canShowHint()) {
          _setMessage(
            'Please say quantity. Example: ${pendingProduct.name} 200',
          );
        }
        return;
      }

      _pendingQuantityProduct = null;
      _apply(
        pendingProduct,
        VoicePurchaseParsedItem(
          quantity: quantity,
          productName: pendingProduct.name,
        ),
      );
      return;
    }

    final result = _voiceEntry.process(words);
    if (result.parsed == null ||
        result.match.type == ProductMatchType.notFound) {
      final productOnly = _voiceEntry.matcher.match(words);
      if (productOnly.type == ProductMatchType.found) {
        _pendingQuantityProduct = productOnly.product;
        _pendingSelectionNeedsQuantity = false;
        _setMessage(
          'Quantity? Please say quantity for ${productOnly.product!.name}. Example: ${productOnly.product!.name} 200',
        );
        return;
      }

      if (productOnly.type == ProductMatchType.ambiguous) {
        _pendingSelectionNeedsQuantity = true;
        _pendingMatches = productOnly.matches;
        notifyListeners();
        return;
      }

      if (_canShowHint()) {
        _setMessage('Couldn\'t understand item. Please speak again.');
      }
      return;
    }

    if (result.match.type == ProductMatchType.ambiguous) {
      _pendingItem = result.parsed;
      _pendingMatches = result.match.matches;
      notifyListeners();
      return;
    }

    _apply(result.match.product!, result.parsed!);
  }

  Future<void> _apply(
    ProductMatchCandidate product,
    VoicePurchaseParsedItem parsed,
  ) async {
    _isProcessing = true;
    notifyListeners();

    try {
      final applyResult = await _onApply(product, parsed);
      _recentlyAdded = VoicePurchaseAddedItem(
        productId: product.id,
        productName: product.name,
        spokenQuantity: parsed.quantity,
        totalQuantity: applyResult.totalQuantity,
        merged: applyResult.merged,
      );
      _addedVersion++;
      _pendingQuantityProduct = null;
      _pendingSelectionNeedsQuantity = false;
      _addedTimer?.cancel();
      _addedTimer = Timer(const Duration(seconds: 1), () {
        _recentlyAdded = null;
        notifyListeners();
      });
      await HapticFeedback.selectionClick();
      notifyListeners();
    } catch (_) {
      _setMessage('Couldn\'t understand item. Please speak again.');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  bool _canShowHint() {
    final now = DateTime.now();
    if (_lastHintAt != null &&
        now.difference(_lastHintAt!) < const Duration(seconds: 2)) {
      return false;
    }
    _lastHintAt = now;
    return true;
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
