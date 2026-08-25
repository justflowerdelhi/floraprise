import 'dart:io';

enum ProductImageSource {
  productCatalog,
  orderReference,
  none,
}

class ProductImageResult {
  const ProductImageResult({
    required this.source,
    this.reference,
    this.isNetwork = false,
  });

  final ProductImageSource source;
  final String? reference;
  final bool isNetwork;

  bool get hasImage => reference != null && reference!.trim().isNotEmpty;
}

class ProductImageService {
  const ProductImageService();

  ProductImageResult resolveForOrderLine(Map<String, Object?> line) {
    final catalogImage = _readString(line, 'product_image_path');
    if (_isLikelyImageReference(catalogImage)) {
      return ProductImageResult(
        source: ProductImageSource.productCatalog,
        reference: catalogImage,
        isNetwork: _isNetworkImage(catalogImage!),
      );
    }

    final orderReferenceImage = _resolveOrderReferenceImage(line);
    if (_isLikelyImageReference(orderReferenceImage)) {
      return ProductImageResult(
        source: ProductImageSource.orderReference,
        reference: orderReferenceImage,
        isNetwork: _isNetworkImage(orderReferenceImage!),
      );
    }

    return const ProductImageResult(source: ProductImageSource.none);
  }

  String? _resolveOrderReferenceImage(Map<String, Object?> line) {
    final candidates = <String?>[
      _readString(line, 'order_reference_image_path'),
      _readString(line, 'reference_image_path'),
      _readString(line, 'customer_reference_image_path'),
      _readString(line, 'customer_image_path'),
      _readString(line, 'design_ref'),
    ];

    for (final candidate in candidates) {
      if (_isLikelyImageReference(candidate)) {
        return candidate;
      }
    }

    return null;
  }

  String? _readString(Map<String, Object?> line, String key) {
    final value = line[key];
    if (value == null) return null;
    final normalized = value.toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  bool _isLikelyImageReference(String? value) {
    if (value == null) return false;
    final normalized = value.trim();
    if (normalized.isEmpty) return false;

    if (_isNetworkImage(normalized)) {
      return true;
    }

    final lower = normalized.toLowerCase();
    const imageExtensions = <String>[
      '.jpg',
      '.jpeg',
      '.png',
      '.webp',
      '.gif',
      '.bmp',
      '.heic',
      '.heif',
    ];

    final hasImageExtension = imageExtensions.any(
      (extension) => lower.contains(extension),
    );
    if (!hasImageExtension) {
      return false;
    }

    if (normalized.startsWith('file://')) {
      return true;
    }

    return File(normalized).existsSync();
  }

  bool _isNetworkImage(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
  }
}
