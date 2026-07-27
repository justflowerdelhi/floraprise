class VoiceParsedItem {
  const VoiceParsedItem({
    required this.quantity,
    required this.productName,
    required this.purchasePrice,
  });

  final int quantity;
  final String productName;
  final double purchasePrice;
}

class VoiceParser {
  static final RegExp _numericPattern = RegExp(
    r'^\s*(\d+)\s+(.+?)\s+(?:(?:at|price|rate)\s+)?(\d+(?:\.\d+)?)\s*$',
    caseSensitive: false,
  );

  static final RegExp _currencyTerms = RegExp(
    r'\b(?:rupee|rupees|rs|inr)\b',
    caseSensitive: false,
  );

  static const Set<String> _connectorWords = {
    'at',
    'price',
    'rate',
    'for',
  };

  static const Map<String, int> _numberWords = {
    'zero': 0,
    'one': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
    'eleven': 11,
    'twelve': 12,
    'thirteen': 13,
    'fourteen': 14,
    'fifteen': 15,
    'sixteen': 16,
    'seventeen': 17,
    'eighteen': 18,
    'nineteen': 19,
    'twenty': 20,
    'thirty': 30,
    'forty': 40,
    'fifty': 50,
    'sixty': 60,
    'seventy': 70,
    'eighty': 80,
    'ninety': 90,
  };

  VoiceParsedItem? parse(String input) {
    final normalized = _normalize(input);
    if (normalized.isEmpty) return null;

    final numericMatch = _numericPattern.firstMatch(normalized);
    if (numericMatch != null) {
      return _build(
        int.tryParse(numericMatch.group(1)!),
        numericMatch.group(2)!,
        double.tryParse(numericMatch.group(3)!),
      );
    }

    final digitBoundaries = _parseUsingDigitBoundaries(normalized);
    if (digitBoundaries != null) {
      return digitBoundaries;
    }

    final words = normalized.split(' ');
    final leading = _readNumberWords(words);
    var trailingStart = words.length;
    while (trailingStart > 0 && _isNumberWord(words[trailingStart - 1])) {
      trailingStart--;
    }
    final trailing = _readNumberWords(words.sublist(trailingStart));
    if (leading == null || trailing == null) return null;
    final productStart = leading.length;
    final productEnd = trailingStart;
    if (productStart >= productEnd) return null;

    return _build(
      leading.value,
      words.sublist(productStart, productEnd).join(' '),
      trailing.value.toDouble(),
    );
  }

  String _normalize(String input) {
    final asciiNormalized = input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9.\s]'), ' ')
        .replaceAll(_currencyTerms, ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return asciiNormalized;
  }

  VoiceParsedItem? _parseUsingDigitBoundaries(String normalized) {
    final words = normalized.split(' ');
    final digitIndexes = <int>[];
    for (var i = 0; i < words.length; i++) {
      if (double.tryParse(words[i]) != null) {
        digitIndexes.add(i);
      }
    }

    if (digitIndexes.length < 2) {
      return null;
    }

    final quantity = int.tryParse(words[digitIndexes.first]);
    final purchasePrice = double.tryParse(words[digitIndexes.last]);
    if (quantity == null || purchasePrice == null) {
      return null;
    }

    var productTokens = words
        .sublist(digitIndexes.first + 1, digitIndexes.last)
        .where((token) => token.trim().isNotEmpty)
        .toList();

    while (productTokens.isNotEmpty &&
        _connectorWords.contains(productTokens.first)) {
      productTokens.removeAt(0);
    }
    while (productTokens.isNotEmpty &&
        _connectorWords.contains(productTokens.last)) {
      productTokens.removeLast();
    }

    if (productTokens.isEmpty) {
      return null;
    }

    return _build(
      quantity,
      productTokens.join(' '),
      purchasePrice,
    );
  }

  VoiceParsedItem? _build(
    int? quantity,
    String productName,
    double? purchasePrice,
  ) {
    final cleanName = productName.trim();
    if (quantity == null ||
        quantity <= 0 ||
        purchasePrice == null ||
        purchasePrice <= 0 ||
        cleanName.isEmpty) {
      return null;
    }
    return VoiceParsedItem(
      quantity: quantity,
      productName: cleanName,
      purchasePrice: purchasePrice,
    );
  }

  bool _isNumberWord(String word) {
    return _numberWords.containsKey(word) ||
        word == 'and' ||
        word == 'hundred' ||
        word == 'thousand';
  }

  _NumberWords? _readNumberWords(List<String> words) {
    var total = 0;
    var current = 0;
    var length = 0;
    for (final word in words) {
      if (word == 'and') {
        if (length == 0) return null;
        length++;
        continue;
      }
      final value = _numberWords[word];
      if (value != null) {
        current += value;
      } else if (word == 'hundred' && current > 0) {
        current *= 100;
      } else if (word == 'thousand' && current > 0) {
        total += current * 1000;
        current = 0;
      } else {
        break;
      }
      length++;
    }
    if (length == 0 || (length == 1 && words.first == 'and')) return null;
    return _NumberWords(total + current, length);
  }
}

class _NumberWords {
  const _NumberWords(this.value, this.length);

  final int value;
  final int length;
}
