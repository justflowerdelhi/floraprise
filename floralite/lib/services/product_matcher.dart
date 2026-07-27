class ProductMatchCandidate {
  const ProductMatchCandidate({required this.id, required this.name});

  final int id;
  final String name;
}

enum ProductMatchType { found, ambiguous, notFound }

class ProductMatchResult {
  const ProductMatchResult._(this.type, this.matches, this.product);

  const ProductMatchResult.found(ProductMatchCandidate product)
      : this._(ProductMatchType.found, const [], product);

  const ProductMatchResult.ambiguous(List<ProductMatchCandidate> matches)
      : this._(ProductMatchType.ambiguous, matches, null);

  const ProductMatchResult.notFound()
      : this._(ProductMatchType.notFound, const [], null);

  final ProductMatchType type;
  final List<ProductMatchCandidate> matches;
  final ProductMatchCandidate? product;
}

class ProductMatcher {
  ProductMatcher(Iterable<ProductMatchCandidate> products)
      : _products = List.unmodifiable(products);

  final List<ProductMatchCandidate> _products;
  static const Map<String, String> _spokenAliases = {
    // Common STT drift in florist vocabulary.
    'wide': 'white',
    'wait': 'white',
    'wight': 'white',
    'lilly': 'lily',
    'lili': 'lily',
  };

  ProductMatchResult match(String spokenName) {
    final query = normalize(spokenName);
    if (query.isEmpty) return const ProductMatchResult.notFound();

    final exact =
        _products.where((product) => normalize(product.name) == query).toList();
    if (exact.length == 1) return ProductMatchResult.found(exact.first);
    if (exact.length > 1) return ProductMatchResult.ambiguous(exact);

    final queryWords = query.split(' ').toSet();
    final partial = _products.where((product) {
      final candidate = normalize(product.name);
      final candidateWords = candidate.split(' ').toSet();
      return candidate.contains(query) ||
          query.contains(candidate) ||
          queryWords.every(candidateWords.contains);
    }).toList();
    if (partial.length == 1) return ProductMatchResult.found(partial.first);
    if (partial.length > 1) return ProductMatchResult.ambiguous(partial);
    return const ProductMatchResult.notFound();
  }

  static String normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map(_normalizeSpokenWord)
        .map(_singularize)
        .join(' ');
  }

  static String _normalizeSpokenWord(String word) {
    return _spokenAliases[word] ?? word;
  }

  static String _singularize(String word) {
    if (word.length > 4 && word.endsWith('ies')) {
      return '${word.substring(0, word.length - 3)}y';
    }
    if (word.length > 4 &&
        (word.endsWith('ches') ||
            word.endsWith('shes') ||
            word.endsWith('ses') ||
            word.endsWith('xes') ||
            word.endsWith('zes'))) {
      return word.substring(0, word.length - 2);
    }
    if (word.length > 3 && word.endsWith('s') && !word.endsWith('ss')) {
      return word.substring(0, word.length - 1);
    }
    return word;
  }
}
