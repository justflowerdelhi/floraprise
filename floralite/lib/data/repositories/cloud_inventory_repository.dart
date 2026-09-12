import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../models/gst_calculation_type.dart';
import '../../services/mobile_auth_service.dart';
import 'inventory_repository.dart';

class CloudLowStockProduct {
  const CloudLowStockProduct({
    required this.productId,
    required this.name,
    required this.sku,
    required this.currentQuantity,
    required this.minimumQuantity,
    required this.status,
  });

  final String productId;
  final String name;
  final String sku;
  final int currentQuantity;
  final int minimumQuantity;
  final String status;

  bool get isOutOfStock => status == 'outOfStock' || currentQuantity <= 0;
  bool get isLowStock =>
      status == 'lowStock' ||
      (currentQuantity > 0 && currentQuantity <= minimumQuantity);

  factory CloudLowStockProduct.fromJson(Map<String, dynamic> json) {
    return CloudLowStockProduct(
      productId: _string(json, 'productId'),
      name: _string(json, 'name'),
      sku: _string(json, 'sku'),
      currentQuantity: _int(json, 'currentQuantity'),
      minimumQuantity: _int(json, 'minimumQuantity'),
      status: _string(json, 'status'),
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'sku': sku,
        'currentQuantity': currentQuantity,
        'minimumQuantity': minimumQuantity,
        'status': status,
      };
}

typedef CloudLowStockSender = Future<dynamic> Function(Uri uri);

typedef CloudInventorySender = Future<dynamic> Function(
  String method,
  Uri uri, {
  Map<String, dynamic>? body,
});

class CloudInventoryRepository {
  CloudInventoryRepository({
    MobileAuthService? auth,
    CloudLowStockSender? lowStockSender,
    FlutterSecureStorage? secureStorage,
    CloudInventorySender? sender,
  })  : _auth = auth ?? MobileAuthService(),
        _lowStockSender = lowStockSender,
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _sender = sender;

  final MobileAuthService _auth;
  final CloudLowStockSender? _lowStockSender;
  final FlutterSecureStorage? _secureStorage;
  final CloudInventorySender? _sender;
  final Map<String, List<CloudLowStockProduct>> _lowStockCache = {};
  static const String _lowStockStorageKey = 'cloud_low_stock_cache';

  Future<List<InventoryProductRecord>> listInventoryProducts() async {
    final response = await _send(
      'GET',
      Uri.parse('${_auth.baseUrl}/api/inventory/products'),
    );
    if (response is! List) return const [];

    final products = <InventoryProductRecord>[];
    for (final raw in response.whereType<Map>()) {
      final json = raw.cast<String, dynamic>();
      final cloudId = _string(
        json,
        'productId',
        fallback: _string(json, 'id'),
      );
      if (cloudId.isEmpty) continue;
      products.add(
        InventoryProductRecord(
          productId: -(products.length + 1),
          cloudProductId: cloudId,
          name: _string(json, 'name'),
          category: _string(json, 'category', fallback: 'Other'),
          unit: _string(json, 'unit', fallback: 'Piece'),
          sku: _string(json, 'sku'),
          barcode: _nullableString(json, 'manufacturerBarcode') ??
              _nullableString(json, 'internalBarcode') ??
              '',
          manufacturerBarcode: _nullableString(json, 'manufacturerBarcode'),
          internalBarcode: _nullableString(json, 'internalBarcode'),
          trackInventory: _bool(json, 'trackInventory'),
          gstPercent: 0,
          gstCalculationType: GstCalculationType.inclusive,
          currentQty: _int(json, 'currentQuantity'),
          minQty: _int(json, 'minimumQuantity'),
        ),
      );
    }
    return products;
  }

  Future<List<CloudLowStockProduct>> listLowStockProducts() async {
    const cacheKey = 'low-stock';
    final sender = _lowStockSender;

    try {
      final response = sender != null
          ? await sender(
              Uri.parse('${_auth.baseUrl}/api/v1/mobile/inventory/low-stock'))
          : await _send(
              'GET',
              Uri.parse('${_auth.baseUrl}/api/v1/mobile/inventory/low-stock'),
            );
      if (response is! List) {
        return await _readLowStockCache(cacheKey);
      }

      final items = response
          .whereType<Map>()
          .map((row) =>
              CloudLowStockProduct.fromJson(row.cast<String, dynamic>()))
          .toList(growable: false);
      _lowStockCache[cacheKey] = items;
      await _writeLowStockCache(items);
      return items;
    } catch (_) {
      return await _readLowStockCache(cacheKey);
    }
  }

  Future<List<CloudLowStockProduct>> _readLowStockCache(String key) async {
    final memory = _lowStockCache[key];
    if (memory != null && memory.isNotEmpty) {
      return memory;
    }
    try {
      final cached = await _secureStorage?.read(key: _lowStockStorageKey);
      if (cached != null && cached.trim().isNotEmpty) {
        final decoded = jsonDecode(cached);
        if (decoded is List) {
          final items = decoded
              .whereType<Map>()
              .map((row) =>
                  CloudLowStockProduct.fromJson(row.cast<String, dynamic>()))
              .toList(growable: false);
          _lowStockCache[key] = items;
          return items;
        }
      }
    } catch (_) {
      // Ignore storage read errors in test/unsupported environments
    }
    return _lowStockCache[key] ?? const [];
  }

  Future<void> _writeLowStockCache(List<CloudLowStockProduct> items) async {
    try {
      await _secureStorage?.write(
        key: _lowStockStorageKey,
        value: jsonEncode(items.map((i) => i.toJson()).toList()),
      );
    } catch (_) {
      // Ignore storage write errors in test/unsupported environments
    }
  }

  Future<List<InventoryTransactionRecord>> loadHistory({
    required String productId,
    required int localProductId,
  }) async {
    final response = await _send(
      'GET',
      Uri.parse(
        '${_auth.baseUrl}/api/inventory/products/'
        '${Uri.encodeComponent(productId)}/history',
      ),
    );
    if (response is! List) return const [];

    final history = <InventoryTransactionRecord>[];
    for (final raw in response.whereType<Map>()) {
      final json = raw.cast<String, dynamic>();
      final cost = _nullableNumber(json, 'costPerUnit');
      history.add(
        InventoryTransactionRecord(
          id: -(history.length + 1),
          cloudId: _string(json, 'id'),
          productId: localProductId,
          txnType: _string(json, 'operation', fallback: 'adjustment'),
          qty: _int(json, 'quantity'),
          purchasePricePaise: cost == null ? null : (cost * 100).round(),
          supplier: _string(json, 'supplier'),
          source: _string(json, 'source', fallback: 'Cloud Inventory'),
          reason: _string(json, 'reason'),
          note: _string(json, 'notes'),
          createdAt: _string(json, 'createdAtUtc'),
          previousQty: _nullableInt(json, 'previousBalance'),
          balanceAfter: _nullableInt(json, 'balanceAfter'),
        ),
      );
    }
    return history;
  }

  Future<void> applyStockChange({
    required String productId,
    required String operation,
    required int quantity,
    bool? increase,
    int? purchasePricePaise,
    String? supplier,
    String? reason,
    String? note,
  }) async {
    await _send(
      'POST',
      Uri.parse('${_auth.baseUrl}/api/inventory/stock-changes'),
      body: {
        'productId': productId,
        'operation': operation,
        'quantity': quantity,
        if (increase != null) 'increase': increase,
        if (purchasePricePaise != null)
          'costPerUnit': purchasePricePaise / 100,
        if (supplier?.trim().isNotEmpty == true) 'supplier': supplier!.trim(),
        if (reason?.trim().isNotEmpty == true) 'reason': reason!.trim(),
        if (note?.trim().isNotEmpty == true) 'notes': note!.trim(),
      },
    );
  }

  Future<List<InventoryTransactionRecord>> getWastageTransactions({
    required DateTime startDate,
    required DateTime endDate,
    String? category,
    int? productId,
    String? supplier,
    String? reason,
  }) async {
    final startUtc = DateTime.utc(startDate.year, startDate.month, startDate.day);
    final endUtc = DateTime.utc(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    final queryParams = <String, String>{
      'wastageOnly': 'true',
      'fromDate': startUtc.toIso8601String(),
      'toDate': endUtc.toIso8601String(),
      'page': '1',
      'pageSize': '1000',
    };

    final response = await _send(
      'GET',
      Uri.parse('${_auth.baseUrl}/api/inventory/adjustments').replace(
        queryParameters: queryParams,
      ),
    );

    dynamic itemsRaw;
    if (response is Map) {
      itemsRaw = response['items'] ?? response['Items'];
    } else if (response is List) {
      itemsRaw = response;
    }

    if (itemsRaw is! List) return const [];

    final records = <InventoryTransactionRecord>[];
    for (var i = 0; i < itemsRaw.length; i++) {
      final raw = itemsRaw[i];
      if (raw is! Map) continue;
      final json = raw.cast<String, dynamic>();

      final itemCategory = _string(json, 'category', fallback: 'Other');
      final itemProductName = _string(json, 'productName', fallback: 'Unknown');
      final itemSupplier = _string(json, 'supplierName');
      final itemReason = _string(json, 'reason', fallback: _string(json, 'adjustmentType'));

      if (category != null && category.trim().isNotEmpty && category != 'All') {
        if (itemCategory.toLowerCase() != category.trim().toLowerCase()) continue;
      }

      if (supplier != null && supplier.trim().isNotEmpty && supplier != 'All') {
        if (itemSupplier.toLowerCase() != supplier.trim().toLowerCase()) continue;
      }

      if (reason != null && reason.trim().isNotEmpty && reason != 'All') {
        if (itemReason.toLowerCase() != reason.trim().toLowerCase()) continue;
      }

      final qty = _int(json, 'quantity').abs();
      final costPerUnit = (json[_key(json, 'costPerUnit')] as num?)?.toDouble() ?? 0.0;
      final purchasePricePaise = (costPerUnit * 100).round();
      final dateStr = _string(json, 'adjustmentDate', fallback: _string(json, 'createdAtUtc'));

      records.add(InventoryTransactionRecord(
        id: -(i + 1),
        cloudId: _string(json, 'id'),
        productId: 0,
        txnType: 'wastage',
        qty: qty,
        purchasePricePaise: purchasePricePaise,
        supplier: itemSupplier,
        source: 'cloud',
        reason: itemReason,
        note: _string(json, 'notes'),
        createdAt: dateStr,
        productName: itemProductName,
        category: itemCategory,
        unit: _string(json, 'unit', fallback: 'Piece'),
      ));
    }

    return records;
  }

  Future<String?> findProductIdByBarcode(String barcode) async {
    final value = barcode.trim();
    if (value.isEmpty) return null;
    final response = await _send(
      'POST',
      Uri.parse('${_auth.baseUrl}/api/barcodes/search'),
      body: {'barcode': value, 'includeOutOfStock': true},
    );
    if (response is! Map) return null;
    final json = response.cast<String, dynamic>();
    final productId = _string(json, 'productId');
    return productId.isEmpty ? null : productId;
  }

  Future<dynamic> _send(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    final override = _sender;
    if (override != null) return override(method, uri, body: body);

    var token = await _auth.getStoredAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw StateError('Cloud session is not available. Please log in again.');
    }

    final encodedBody = body == null ? null : jsonEncode(body);
    debugPrint('[INVENTORY-CLOUD] $method $uri');
    for (var attempt = 0; attempt < 2; attempt++) {
      final client = http.Client();
      try {
        final request = http.Request(method, uri);
        request.headers['Accept'] = 'application/json';
        request.headers['Authorization'] = 'Bearer $token';
        if (encodedBody != null) {
          request.headers['Content-Type'] = 'application/json';
          request.body = encodedBody;
        }

        final streamedResponse =
            await client.send(request).timeout(const Duration(seconds: 20));
        final responseBody = await streamedResponse.stream.bytesToString();
        final statusCode = streamedResponse.statusCode;
        debugPrint('[INVENTORY-CLOUD] HTTP STATUS: $statusCode');

        if (statusCode == 401 && attempt == 0) {
          final refreshed = await _auth.refreshAndBootstrap();
          token = refreshed.accessToken;
          continue;
        }

        final decoded = responseBody.trim().isEmpty
            ? <String, dynamic>{}
            : _decode(responseBody);
        if (statusCode < 200 || statusCode >= 300) {
          final message = decoded is Map
              ? decoded['message'] ??
                  decoded['detail'] ??
                  decoded['title'] ??
                  decoded['error']
              : null;
          throw StateError(
            message?.toString() ??
                'Cloud inventory request failed (HTTP $statusCode).',
          );
        }
        return decoded;
      } on SocketException catch (error) {
        throw StateError('Unable to connect to Floraprise Cloud: $error');
      } finally {
        client.close();
      }
    }
    throw StateError('Cloud inventory request failed.');
  }
}

class CloudLowStockRepository {
  CloudLowStockRepository({
    CloudInventoryRepository? inventoryRepository,
  }) : _inventoryRepository = inventoryRepository ?? CloudInventoryRepository();

  final CloudInventoryRepository _inventoryRepository;

  Future<List<CloudLowStockProduct>> listLowStockProducts() =>
      _inventoryRepository.listLowStockProducts();
}

dynamic _decode(String text) {
  try {
    return jsonDecode(text);
  } catch (_) {
    return <String, dynamic>{};
  }
}

String _key(Map<String, dynamic> json, String key) =>
    json.containsKey(key) ? key : '${key[0].toUpperCase()}${key.substring(1)}';

String _string(
  Map<String, dynamic> json,
  String key, {
  String fallback = '',
}) =>
    json[_key(json, key)]?.toString() ?? fallback;

String? _nullableString(Map<String, dynamic> json, String key) {
  final value = json[_key(json, key)]?.toString().trim();
  return value == null || value.isEmpty ? null : value;
}

int _int(Map<String, dynamic> json, String key) =>
    (json[_key(json, key)] as num?)?.toInt() ?? 0;

int? _nullableInt(Map<String, dynamic> json, String key) =>
    (json[_key(json, key)] as num?)?.toInt();

double? _nullableNumber(Map<String, dynamic> json, String key) =>
    (json[_key(json, key)] as num?)?.toDouble();

bool _bool(Map<String, dynamic> json, String key) =>
    json[_key(json, key)] is bool && json[_key(json, key)] as bool;
