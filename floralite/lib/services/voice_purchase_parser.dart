class VoicePurchaseParsedItem {
  const VoicePurchaseParsedItem({
    required this.quantity,
    required this.productName,
  });

  final int quantity;
  final String productName;
}

class VoicePurchaseParser {
  VoicePurchaseParsedItem? parse(String input) {
    final normalized = _normalize(input);
    if (normalized.isEmpty) return null;

    final tokens = normalized.split(' ');
    if (tokens.length < 2) return null;

    final firstNumber = int.tryParse(tokens.first);
    if (firstNumber != null && firstNumber > 0) {
      final product = tokens.sublist(1).join(' ').trim();
      if (product.isEmpty) return null;
      return VoicePurchaseParsedItem(
          quantity: firstNumber, productName: product);
    }

    final lastNumber = int.tryParse(tokens.last);
    if (lastNumber != null && lastNumber > 0) {
      final product = tokens.sublist(0, tokens.length - 1).join(' ').trim();
      if (product.isEmpty) return null;
      return VoicePurchaseParsedItem(
          quantity: lastNumber, productName: product);
    }

    return null;
  }

  int? parseQuantityOnly(String input) {
    final normalized = _normalize(input);
    if (normalized.isEmpty) return null;

    final exact = int.tryParse(normalized);
    if (exact != null && exact > 0) {
      return exact;
    }

    final match = RegExp(r'\b(\d+)\b').firstMatch(normalized);
    if (match == null) return null;
    final value = int.tryParse(match.group(1)!);
    if (value == null || value <= 0) return null;
    return value;
  }

  String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
