import 'dart:math';

/// Service responsible for generating and validating product SKUs across
/// Floraprise Solo and Cloud environments.
class SkuGeneratorService {
  const SkuGeneratorService();

  static const Map<String, String> _knownCategoryPrefixes = {
    'flowers': 'FLW',
    'flower': 'FLW',
    'fresh flowers': 'FLW',
    'fresh flower': 'FLW',
    'fillers': 'FIL',
    'filler': 'FIL',
    'foliage': 'FOL',
    'greens & foliage': 'FOL',
    'finished products': 'BQT',
    'finished product': 'BQT',
    'bouquets': 'BQT',
    'bouquet': 'BQT',
    'arrangements': 'ARR',
    'arrangement': 'ARR',
    'plants': 'PLT',
    'plant': 'PLT',
    'packing': 'PCK',
    'accessories': 'ACC',
    'accessory': 'ACC',
    'supplies': 'SUP',
    'supply': 'SUP',
    'vases': 'VAS',
    'vase': 'VAS',
    'others': 'OTH',
    'other': 'OTH',
  };

  /// Derives a 3-character uppercase prefix from an arbitrary category name.
  static String deriveCategoryPrefix(String category) {
    final clean = category.trim().toLowerCase();
    if (_knownCategoryPrefixes.containsKey(clean)) {
      return _knownCategoryPrefixes[clean]!;
    }
    final alphaOnly = clean.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    if (alphaOnly.isEmpty) return 'FLR';

    final consonants = alphaOnly.replaceAll(RegExp(r'[AEIOU]'), '');
    final code = consonants.length >= 3
        ? consonants.substring(0, 3)
        : alphaOnly.length >= 3
            ? alphaOnly.substring(0, 3)
            : alphaOnly.padRight(3, 'X');
    return code;
  }

  /// Derives a 3-character uppercase name code from a product name.
  static String deriveNameCode(String productName) {
    final alphaOnly =
        productName.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (alphaOnly.isEmpty) return 'GEN';

    final consonants = alphaOnly.replaceAll(RegExp(r'[AEIOU]'), '');
    if (consonants.length >= 3) {
      return consonants.substring(0, 3);
    }
    if (alphaOnly.length >= 3) {
      return alphaOnly.substring(0, 3);
    }
    return alphaOnly.padRight(3, 'X');
  }

  /// Generates a unique, standardized SKU in the form:
  /// `[CAT]-[NAME]-[RANDOM]` (e.g. `FLW-ROS-742`)
  /// If product name is empty: `[CAT]-[RANDOM]` (e.g. `FLW-742`)
  static String generateSku({
    required String categoryName,
    required String productName,
    int? randomDigits,
  }) {
    final prefix = deriveCategoryPrefix(categoryName);
    final rand = randomDigits ?? (100 + Random().nextInt(900));

    final trimmedName = productName.trim();
    if (trimmedName.isEmpty) {
      return '$prefix-$rand';
    }

    final nameCode = deriveNameCode(trimmedName);
    return '$prefix-$nameCode-$rand';
  }

  /// Validates that a user-entered or generated SKU meets standard requirements.
  static bool isValidSku(String sku) {
    final trimmed = sku.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.length < 2 || trimmed.length > 50) return false;
    // Allow alphanumeric characters, hyphens, and underscores
    return RegExp(r'^[A-Za-z0-9\-_]+$').hasMatch(trimmed);
  }
}
