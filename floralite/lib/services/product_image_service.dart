import 'dart:io';

import 'package:flutter/foundation.dart';

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
    // 1. Prefer historical snapshot / explicit order reference image captured with the order
    final orderReferenceImage = _resolveOrderReferenceImage(line);
    if (_isLikelyImageReference(orderReferenceImage)) {
      return ProductImageResult(
        source: ProductImageSource.orderReference,
        reference: orderReferenceImage,
        isNetwork: _isNetworkImage(orderReferenceImage!),
      );
    }

    // 2. Fall back to current catalog product image if no order-level snapshot exists
    final catalogImage = _readString(line, 'product_image_path') ??
        _readString(line, 'image_url') ??
        _readString(line, 'imageUrl') ??
        _readString(line, 'image_path');
    if (_isLikelyImageReference(catalogImage)) {
      return ProductImageResult(
        source: ProductImageSource.productCatalog,
        reference: catalogImage,
        isNetwork: _isNetworkImage(catalogImage!),
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
      _readString(line, 'designRef'),
      _readString(line, 'reference_image_url'),
      _readString(line, 'imageReference'),
      _readString(line, 'ImageReference'),
      _readString(line, 'attachment_path'),
      _readString(line, 'attachmentPath'),
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

    if (_isNetworkImage(normalized) ||
        normalized.startsWith('data:image') ||
        normalized.startsWith('assets/')) {
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

    if (kIsWeb) {
      return true;
    }

    try {
      final file = File(normalized);
      if (file.existsSync()) return true;
    } catch (_) {
      // In non-io test environments or custom paths, hasImageExtension is sufficient
    }
    return true;
  }

  bool _isNetworkImage(String value) {
    return value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('blob:');
  }
}
