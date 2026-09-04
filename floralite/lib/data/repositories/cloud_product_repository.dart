import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../services/mobile_auth_service.dart';

class CloudProduct {
  const CloudProduct({
    required this.id,
    required this.companyId,
    required this.name,
    required this.sku,
    required this.barcode,
    required this.manufacturerBarcode,
    required this.internalBarcode,
    required this.brand,
    required this.description,
    required this.category,
    required this.categoryId,
    required this.unitOfMeasure,
    required this.retailPrice,
    required this.costPrice,
    required this.wholesalePrice,
    required this.weddingEventPrice,
    required this.taxCategory,
    required this.trackInventory,
    required this.trackBatch,
    required this.stockQuantity,
    required this.minimumStockLevel,
    required this.reorderLevel,
    required this.isActive,
    required this.shelfLifeDays,
    required this.expiryAlertDays,
    required this.temperatureNotes,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });

  final String id;
  final String companyId;
  final String name;
  final String sku;
  final String? barcode;
  final String? manufacturerBarcode;
  final String? internalBarcode;
  final String? brand;
  final String? description;
  final String category;
  final String? categoryId;
  final String unitOfMeasure;
  final double retailPrice;
  final double costPrice;
  final double? wholesalePrice;
  final double? weddingEventPrice;
  final String taxCategory;
  final bool trackInventory;
  final bool trackBatch;
  final int stockQuantity;
  final int minimumStockLevel;
  final int reorderLevel;
  final bool isActive;
  final int? shelfLifeDays;
  final int? expiryAlertDays;
  final String? temperatureNotes;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;

  factory CloudProduct.fromJson(Map<String, dynamic> json) {
    return CloudProduct(
      id: _string(json, 'id'),
      companyId: _string(json, 'companyId'),
      name: _string(json, 'name'),
      sku: _string(json, 'sku'),
      barcode: _nullableString(json, 'barcode'),
      manufacturerBarcode: _nullableString(json, 'manufacturerBarcode'),
      internalBarcode: _nullableString(json, 'internalBarcode'),
      brand: _nullableString(json, 'brand'),
      description: _nullableString(json, 'description'),
      category: _string(json, 'category', fallback: 'Other'),
      categoryId: _nullableString(json, 'categoryId'),
      unitOfMeasure: _string(json, 'unitOfMeasure', fallback: 'Stem'),
      retailPrice: _number(json, 'retailPrice'),
      costPrice: _number(json, 'costPrice'),
      wholesalePrice: _nullableNumber(json, 'wholesalePrice'),
      weddingEventPrice: _nullableNumber(json, 'weddingEventPrice'),
      taxCategory: _string(json, 'taxCategory', fallback: 'Standard'),
      trackInventory: _bool(json, 'trackInventory'),
      trackBatch: _bool(json, 'trackBatch'),
      stockQuantity: _int(json, 'stockQuantity'),
      minimumStockLevel: _int(json, 'minimumStockLevel'),
      reorderLevel: _int(json, 'reorderLevel'),
      isActive: _bool(json, 'isActive', fallback: true),
      shelfLifeDays: _nullableInt(json, 'shelfLifeDays'),
      expiryAlertDays: _nullableInt(json, 'expiryAlertDays'),
      temperatureNotes: _nullableString(json, 'temperatureNotes'),
      createdAtUtc: DateTime.tryParse(_string(json, 'createdAtUtc')) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAtUtc: _nullableDate(json, 'updatedAtUtc'),
    );
  }

  static String _key(Map<String, dynamic> json, String key) =>
      json.containsKey(key) ? key : '${key[0].toUpperCase()}${key.substring(1)}';

  static String _string(Map<String, dynamic> json, String key,
          {String fallback = ''}) =>
      json[_key(json, key)]?.toString() ?? fallback;

  static String? _nullableString(Map<String, dynamic> json, String key) {
    final value = json[_key(json, key)]?.toString();
    return value == null || value.isEmpty ? null : value;
  }

  static double _number(Map<String, dynamic> json, String key) =>
      (json[_key(json, key)] as num?)?.toDouble() ?? 0;

  static double? _nullableNumber(Map<String, dynamic> json, String key) =>
      (json[_key(json, key)] as num?)?.toDouble();

  static int _int(Map<String, dynamic> json, String key) =>
      (json[_key(json, key)] as num?)?.toInt() ?? 0;

  static int? _nullableInt(Map<String, dynamic> json, String key) =>
      (json[_key(json, key)] as num?)?.toInt();

  static bool _bool(Map<String, dynamic> json, String key,
          {bool fallback = false}) =>
      json[_key(json, key)] is bool ? json[_key(json, key)] as bool : fallback;

  static DateTime? _nullableDate(Map<String, dynamic> json, String key) {
    final value = json[_key(json, key)]?.toString();
    return value == null ? null : DateTime.tryParse(value);
  }
}

class CloudProductInput {
  const CloudProductInput({
    required this.name,
    required this.sku,
    required this.categoryId,
    required this.unitOfMeasure,
    required this.retailPrice,
    required this.costPrice,
    required this.manufacturerBarcode,
    required this.description,
    required this.trackInventory,
    required this.trackBatch,
    required this.reorderLevel,
  });

  final String name;
  final String sku;
  final String categoryId;
  final String unitOfMeasure;
  final double retailPrice;
  final double costPrice;
  final String? manufacturerBarcode;
  final String? description;
  final bool trackInventory;
  final bool trackBatch;
  final int reorderLevel;

  Map<String, dynamic> toCreateJson() => {
        'productName': name,
        'sku': sku,
        'categoryId': categoryId,
        'category': 'Other',
        'productType': 'SingleFlower',
        'unitOfMeasure': unitOfMeasure,
        'retailPrice': retailPrice,
        'costPrice': costPrice,
        // Backend's Barcode field represents the Manufacturer barcode.
        'barcode': manufacturerBarcode,
        'description': description,
        'trackInventory': trackInventory,
        'trackBatch': trackBatch,
        'reorderLevel': reorderLevel,
        'taxCategory': 'Standard',
        'accounting': {'incomeAccount': '4000', 'expenseAccount': '5000'},
        'settings': {
          'status': 'active',
          'allowAsRawMaterial': false,
          'availableOnline': false,
          'commissionEligible': false,
        },
      };

  Map<String, dynamic> toUpdateJson() => {
        'productName': name,
        'categoryId': categoryId,
        'barcode': manufacturerBarcode,
        'description': description,
        'retailPrice': retailPrice,
        'costPrice': costPrice,
        'trackInventory': trackInventory,
        'trackBatch': trackBatch,
        'reorderLevel': reorderLevel,
        'taxCategory': 'Standard',
      };
}

class CloudCategory {
  const CloudCategory({
    required this.id,
    required this.name,
    required this.isActive,
    required this.isPerishable,
    required this.trackBatchByDefault,
  });

  final String id;
  final String name;
  final bool isActive;
  final bool isPerishable;
  final bool trackBatchByDefault;

  factory CloudCategory.fromJson(Map<String, dynamic> json) => CloudCategory(
        id: _read(json, 'id'),
        name: _read(json, 'name'),
        isActive: _readBool(json, 'isActive', true),
        isPerishable: _readBool(json, 'isPerishable', false),
        trackBatchByDefault: _readBool(json, 'trackBatchByDefault', false),
      );

  static String _read(Map<String, dynamic> json, String key) =>
      json[key]?.toString() ?? json['${key[0].toUpperCase()}${key.substring(1)}']?.toString() ?? '';

  static bool _readBool(Map<String, dynamic> json, String key, bool fallback) =>
      (json[key] ?? json['${key[0].toUpperCase()}${key.substring(1)}']) is bool
          ? (json[key] ?? json['${key[0].toUpperCase()}${key.substring(1)}']) as bool
          : fallback;
}

class CloudProductRepository {
  CloudProductRepository({MobileAuthService? auth})
      : _auth = auth ?? MobileAuthService();

  final MobileAuthService _auth;

  Future<List<CloudProduct>> listProducts({
    String query = '',
    String? category,
    bool? trackInventory,
    bool showActive = true,
    bool showInactive = false,
  }) async {
    final queryParameters = <String, String>{
      'page': '1',
      'pageSize': '200',
    };
    if (query.trim().isNotEmpty) queryParameters['query'] = query.trim();
    if (category != null && category.trim().isNotEmpty) {
      queryParameters['category'] = category.trim();
    }
    if (trackInventory != null) {
      queryParameters['trackInventory'] = '$trackInventory';
    }
    if (showActive != showInactive) {
      queryParameters['isActive'] = '$showActive';
    }

    final response = await _send(
      'GET',
      Uri.parse('${_auth.baseUrl}/api/products/search')
          .replace(queryParameters: queryParameters),
    );
    final rawItems = response['items'] ?? response['Items'] ?? [];
    if (rawItems is! List) return [];
    return rawItems
        .whereType<Map>()
        .map((item) => CloudProduct.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<CloudProduct> createProduct(CloudProductInput input) async {
    final response = await _send(
      'POST',
      Uri.parse('${_auth.baseUrl}/api/products'),
      body: input.toCreateJson(),
    );
    final id = _readString(response as Map<String, dynamic>, 'id');
    if (id.isEmpty) throw StateError('Cloud API did not return a product ID.');
    return getProduct(id);
  }

  Future<CloudProduct> getProduct(String id) async {
    final response = await _send(
      'GET',
      Uri.parse('${_auth.baseUrl}/api/products/$id'),
    );
    return CloudProduct.fromJson(response as Map<String, dynamic>);
  }

  Future<void> updateProduct(String id, CloudProductInput input) async {
    await _send(
      'PUT',
      Uri.parse('${_auth.baseUrl}/api/products/$id'),
      body: input.toUpdateJson(),
    );
  }

  Future<void> setActive(String id, bool active) async {
    await _send(
      'PUT',
      Uri.parse('${_auth.baseUrl}/api/products/$id/${active ? 'activate' : 'deactivate'}'),
    );
  }

  Future<List<CloudCategory>> listCategories() async {
    final response = await _send(
      'GET',
      Uri.parse('${_auth.baseUrl}/api/categories?includeInactive=true'),
    );
    final rawItems = response is Map ? (response['items'] ?? response) : response;
    if (rawItems is! List) return [];
    return rawItems
        .whereType<Map>()
        .map((item) => CloudCategory.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<CloudCategory> createCategory(String name) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/categories');
    debugPrint('[CATEGORY-CLOUD-DIAGNOSTIC] POST URL: $uri');
    debugPrint(
      '[CATEGORY-CLOUD-DIAGNOSTIC] Authorization present: ${((await _auth.getStoredAccessToken())?.trim().isNotEmpty ?? false) ? 'YES' : 'NO'}',
    );
    debugPrint('[CATEGORY-CLOUD-DIAGNOSTIC] Category name: $name');
    final response = await _send(
      'POST',
      uri,
      body: {
        'name': name,
        'isPerishable': false,
        'trackBatchByDefault': false,
      },
    );
    debugPrint('[CATEGORY-CLOUD-DIAGNOSTIC] HTTP STATUS: 2xx');
    debugPrint('[CATEGORY-CLOUD-DIAGNOSTIC] RESPONSE: $response');
    final id = _readString(response, 'id');
    if (id.isEmpty) throw StateError('Cloud API did not return a category ID.');
    final categories = await listCategories();
    return categories.firstWhere((category) => category.id == id);
  }

  Future<void> updateCategory(String id, String name) async {
    await _send(
      'PUT',
      Uri.parse('${_auth.baseUrl}/api/categories/$id'),
      body: {
        'name': name,
        'isPerishable': false,
        'trackBatchByDefault': false,
      },
    );
  }

  Future<void> setCategoryActive(String id, bool active) async {
    await _send(
      active ? 'PUT' : 'DELETE',
      Uri.parse(active
          ? '${_auth.baseUrl}/api/categories/$id/activate'
          : '${_auth.baseUrl}/api/categories/$id'),
    );
  }

  Future<dynamic> _send(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    var token = await _auth.getStoredAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw StateError('Cloud session is not available.');
    }
    final loggable = uri.path.startsWith('/api/products') || uri.path.startsWith('/api/categories');
    if (loggable) {
      debugPrint('[CLOUD-API] $method $uri');
    }

    for (var attempt = 0; attempt < 2; attempt++) {
      final client = HttpClient();
      try {
        final request = await client.openUrl(method, uri);
        request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
        if (body != null) {
          request.headers.contentType = ContentType.json;
          request.write(jsonEncode(body));
        }
        final response = await request.close().timeout(const Duration(seconds: 20));
        final responseBody = await response.transform(utf8.decoder).join();
        if (loggable) {
          debugPrint('[CLOUD-API] HTTP STATUS: ${response.statusCode}');
          debugPrint('[CLOUD-API] RESPONSE: $responseBody');
        }
        if (response.statusCode == 401 && attempt == 0) {
          final refreshed = await _auth.refreshAndBootstrap();
          token = refreshed.accessToken;
          continue;
        }
        final decoded = responseBody.trim().isEmpty
            ? <String, dynamic>{}
            : jsonDecode(responseBody);
        if (response.statusCode < 200 || response.statusCode >= 300) {
          if (loggable) debugPrint('[CLOUD-API] EXCEPTION: StateError (HTTP ${response.statusCode})');
          throw StateError('Cloud API HTTP ${response.statusCode}: $responseBody');
        }
        if (decoded is Map<String, dynamic> || decoded is List) return decoded;
        throw StateError('Cloud API returned an unexpected response.');
      } finally {
        client.close(force: true);
      }
    }
    throw StateError('Cloud request failed.');
  }

  static String _readString(Map<String, dynamic> json, String key) =>
      json[key]?.toString() ?? json['${key[0].toUpperCase()}${key.substring(1)}']?.toString() ?? '';
}
