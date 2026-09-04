import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../models/gst_calculation_type.dart';
import '../../services/mobile_auth_service.dart';
import 'inventory_repository.dart';

class CloudInventoryRepository {
  CloudInventoryRepository({MobileAuthService? auth})
      : _auth = auth ?? MobileAuthService();

  final MobileAuthService _auth;

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
    var token = await _auth.getStoredAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw StateError('Cloud session is not available. Please log in again.');
    }

    final encodedBody = body == null ? null : jsonEncode(body);
    debugPrint('[INVENTORY-CLOUD] $method $uri');
    for (var attempt = 0; attempt < 2; attempt++) {
      final client = HttpClient();
      try {
        final request = await client.openUrl(method, uri).timeout(
              const Duration(seconds: 12),
            );
        request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
        if (body != null) {
          request.headers.contentType = ContentType.json;
          request.write(encodedBody);
        }

        final response =
            await request.close().timeout(const Duration(seconds: 20));
        final responseBody = await response.transform(utf8.decoder).join();
        debugPrint('[INVENTORY-CLOUD] HTTP STATUS: ${response.statusCode}');

        if (response.statusCode == 401 && attempt == 0) {
          final refreshed = await _auth.refreshAndBootstrap();
          token = refreshed.accessToken;
          continue;
        }

        final decoded = responseBody.trim().isEmpty
            ? <String, dynamic>{}
            : _decode(responseBody);
        if (response.statusCode < 200 || response.statusCode >= 300) {
          final message = decoded is Map
              ? decoded['message'] ??
                  decoded['detail'] ??
                  decoded['title'] ??
                  decoded['error']
              : null;
          throw StateError(
            message?.toString() ??
                'Cloud inventory request failed (HTTP ${response.statusCode}).',
          );
        }
        return decoded;
      } on SocketException catch (error) {
        throw StateError('Unable to connect to Floraprise Cloud: $error');
      } finally {
        client.close(force: true);
      }
    }
    throw StateError('Cloud inventory request failed.');
  }

  static dynamic _decode(String text) {
    try {
      return jsonDecode(text);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static String _key(Map<String, dynamic> json, String key) =>
      json.containsKey(key) ? key : '${key[0].toUpperCase()}${key.substring(1)}';

  static String _string(
    Map<String, dynamic> json,
    String key, {
    String fallback = '',
  }) =>
      json[_key(json, key)]?.toString() ?? fallback;

  static String? _nullableString(Map<String, dynamic> json, String key) {
    final value = json[_key(json, key)]?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  static int _int(Map<String, dynamic> json, String key) =>
      (json[_key(json, key)] as num?)?.toInt() ?? 0;

    static int? _nullableInt(Map<String, dynamic> json, String key) =>
      (json[_key(json, key)] as num?)?.toInt();

  static double? _nullableNumber(Map<String, dynamic> json, String key) =>
      (json[_key(json, key)] as num?)?.toDouble();

  static bool _bool(Map<String, dynamic> json, String key) =>
      json[_key(json, key)] is bool && json[_key(json, key)] as bool;
}
