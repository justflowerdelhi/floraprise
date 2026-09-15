import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../services/mobile_auth_service.dart';
import 'ready_bouquet_repository.dart';

typedef CloudReadyBouquetSender = Future<dynamic> Function(
  String method,
  Uri uri, {
  dynamic body,
});

class CloudReadyBouquetRepository {
  CloudReadyBouquetRepository({
    MobileAuthService? auth,
    CloudReadyBouquetSender? sender,
  })  : _auth = auth ?? MobileAuthService(),
        _sender = sender;

  final MobileAuthService _auth;
  final CloudReadyBouquetSender? _sender;

  ReadyBouquetStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'needs_refresh':
      case 'needsrefresh':
        return ReadyBouquetStatus.needsRefresh;
      case 'near_expiry':
      case 'nearexpiry':
        return ReadyBouquetStatus.nearExpiry;
      case 'expired':
        return ReadyBouquetStatus.expired;
      case 'fresh':
      default:
        return ReadyBouquetStatus.fresh;
    }
  }

  ReadyBouquetBatch _parseBatch(Map<String, dynamic> item) {
    final Map<String, dynamic> b =
        item['batch'] is Map<String, dynamic> ? item['batch'] as Map<String, dynamic> : item;

    final idStr = (b['id'] ?? b['Id'])?.toString() ?? '';
    final fpIdStr = (b['finishedProductId'] ?? b['FinishedProductId'])?.toString() ?? '';
    final recipeIdStr = (b['recipeId'] ?? b['RecipeId'])?.toString();
    final prodIdStr = (b['productionId'] ?? b['ProductionId'])?.toString();

    final pName = (b['productName'] ?? b['ProductName'])?.toString() ?? 'Bouquet';
    final unit = (b['unit'] ?? b['Unit'])?.toString() ?? 'Piece';

    final initQty = (b['initialQuantity'] ?? b['InitialQuantity'] ?? 0) as int;
    final remQty = (b['remainingQuantity'] ?? b['RemainingQuantity'] ?? 0) as int;
    final shelfLife = (b['shelfLifeDays'] ?? b['ShelfLifeDays'] ?? 3) as int;
    final refreshDays = (b['refreshAfterDays'] ?? b['RefreshAfterDays'] ?? 2) as int;

    final prodStr = (b['producedAt'] ?? b['ProducedAt'])?.toString() ?? '';
    final refStr = (b['lastRefreshAt'] ?? b['LastRefreshAt'])?.toString();
    final expStr = (b['expiryAt'] ?? b['ExpiryAt'])?.toString() ?? '';

    final loc = (b['location'] ?? b['Location'])?.toString() ?? 'Store';
    final note = (b['note'] ?? b['Note'])?.toString();

    final statusStr = (item['computedStatus'] ?? b['status'] ?? b['Status'])?.toString();
    final status = _parseStatus(statusStr);

    final producedAt = DateTime.tryParse(prodStr) ?? DateTime.now();
    final lastRefreshAt = refStr != null ? DateTime.tryParse(refStr) : null;
    final expiryAt = DateTime.tryParse(expStr) ?? producedAt.add(Duration(days: shelfLife));

    return ReadyBouquetBatch(
      id: int.tryParse(idStr) ?? idStr.hashCode.abs(),
      cloudId: idStr,
      finishedProductId: int.tryParse(fpIdStr) ?? fpIdStr.hashCode.abs(),
      cloudFinishedProductId: fpIdStr,
      productName: pName,
      unit: unit,
      recipeId: recipeIdStr != null ? int.tryParse(recipeIdStr) ?? recipeIdStr.hashCode.abs() : null,
      cloudRecipeId: recipeIdStr,
      productionId: prodIdStr != null ? int.tryParse(prodIdStr) ?? prodIdStr.hashCode.abs() : null,
      cloudProductionId: prodIdStr,
      initialQuantity: initQty,
      remainingQuantity: remQty,
      shelfLifeDays: shelfLife,
      refreshAfterDays: refreshDays,
      producedAt: producedAt,
      lastRefreshAt: lastRefreshAt,
      expiryAt: expiryAt,
      location: loc,
      status: status,
      note: note,
    );
  }

  Future<Map<String, String>> _getProductNames() async {
    try {
      final uri = Uri.parse('${_auth.baseUrl}/api/products');
      final res = await _request('GET', uri);
      if (res is List) {
        final map = <String, String>{};
        for (final p in res.whereType<Map<String, dynamic>>()) {
          final id = (p['id'] ?? p['Id'])?.toString();
          final name = (p['name'] ?? p['Name'])?.toString();
          if (id != null && name != null) {
            map[id] = name;
          }
        }
        return map;
      }
    } catch (_) {}
    return const {};
  }

  Future<List<ReadyBouquetBatch>> listAllBatches({bool attentionOnly = false}) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/ready-bouquets').replace(
      queryParameters: attentionOnly ? {'attentionOnly': 'true'} : null,
    );

    final response = await _request('GET', uri);
    if (response is! List) return const [];

    final productNames = await _getProductNames();

    return response.whereType<Map<String, dynamic>>().map((item) {
      final batch = _parseBatch(item);
      final resolvedName = productNames[batch.cloudFinishedProductId] ?? batch.productName;
      if (resolvedName != batch.productName && resolvedName.isNotEmpty) {
        return ReadyBouquetBatch(
          id: batch.id,
          cloudId: batch.cloudId,
          finishedProductId: batch.finishedProductId,
          cloudFinishedProductId: batch.cloudFinishedProductId,
          productName: resolvedName,
          unit: batch.unit,
          recipeId: batch.recipeId,
          cloudRecipeId: batch.cloudRecipeId,
          productionId: batch.productionId,
          cloudProductionId: batch.cloudProductionId,
          initialQuantity: batch.initialQuantity,
          remainingQuantity: batch.remainingQuantity,
          shelfLifeDays: batch.shelfLifeDays,
          refreshAfterDays: batch.refreshAfterDays,
          producedAt: batch.producedAt,
          lastRefreshAt: batch.lastRefreshAt,
          expiryAt: batch.expiryAt,
          location: batch.location,
          status: batch.status,
          note: batch.note,
        );
      }
      return batch;
    }).toList();
  }

  Future<List<ReadyBouquetSummary>> listReadyBouquets() async {
    final batches = await listAllBatches();
    final byProduct = <String, List<ReadyBouquetBatch>>{};

    for (final b in batches.where((b) => b.remainingQuantity > 0)) {
      final key = b.cloudFinishedProductId ?? b.finishedProductId.toString();
      byProduct.putIfAbsent(key, () => []).add(b);
    }

    return byProduct.entries.map((entry) {
      final productBatches = entry.value;
      final first = productBatches.first;
      final productName = first.productName;
      final unit = first.unit;
      final currentStock = productBatches.fold(0, (sum, b) => sum + b.remainingQuantity);
      final oldest = productBatches.map((b) => b.producedAt).reduce((a, b) => a.isBefore(b) ? a : b);
      final lastRefresh = productBatches
          .where((b) => b.lastRefreshAt != null)
          .map((b) => b.lastRefreshAt!)
          .fold<DateTime?>(null, (latest, dt) => latest == null || dt.isAfter(latest) ? dt : latest);

      var worstStatus = ReadyBouquetStatus.fresh;
      for (final b in productBatches) {
        if (b.status == ReadyBouquetStatus.expired) {
          worstStatus = ReadyBouquetStatus.expired;
          break;
        } else if (b.status == ReadyBouquetStatus.needsRefresh) {
          worstStatus = ReadyBouquetStatus.needsRefresh;
        } else if (b.status == ReadyBouquetStatus.nearExpiry && worstStatus != ReadyBouquetStatus.needsRefresh) {
          worstStatus = ReadyBouquetStatus.nearExpiry;
        }
      }

      final ageDays = DateTime.now().difference(lastRefresh ?? oldest).inDays;

      return ReadyBouquetSummary(
        productId: first.finishedProductId,
        cloudProductId: first.cloudFinishedProductId,
        productName: productName,
        unit: unit,
        currentStock: currentStock,
        batchCount: productBatches.length,
        oldestProducedAt: oldest,
        lastRefreshAt: lastRefresh,
        ageDays: ageDays,
        status: worstStatus,
      );
    }).toList();
  }

  Future<List<ReadyBouquetSummary>> getAttentionBouquets() async {
    final all = await listReadyBouquets();
    return all
        .where((b) =>
            b.status == ReadyBouquetStatus.needsRefresh ||
            b.status == ReadyBouquetStatus.nearExpiry ||
            b.status == ReadyBouquetStatus.expired)
        .toList();
  }

  Future<List<ReadyBouquetBatch>> listBatchesForProduct(
    dynamic finishedProductId,
  ) async {
    final all = await listAllBatches();
    final target = finishedProductId.toString();
    return all.where((b) {
      return (b.finishedProductId.toString() == target ||
              b.cloudFinishedProductId == target) &&
          b.remainingQuantity > 0;
    }).toList();
  }

  Future<ReadyBouquetBatch?> getBatch(dynamic batchId) async {
    final idStr = batchId.toString();
    try {
      final uri = Uri.parse('${_auth.baseUrl}/api/ready-bouquets/$idStr');
      final res = await _request('GET', uri);
      if (res is Map<String, dynamic>) {
        return _parseBatch(res);
      }
    } catch (_) {
      // Search in full list if single get fails
      final all = await listAllBatches();
      for (final b in all) {
        if (b.id.toString() == idStr || b.cloudId == idStr) return b;
      }
    }
    return null;
  }

  Future<List<RefreshEventRecord>> listRefreshEvents(dynamic batchId) async {
    final idStr = batchId.toString();
    try {
      final uri = Uri.parse('${_auth.baseUrl}/api/ready-bouquets/$idStr/history');
      final res = await _request('GET', uri);
      if (res is List) {
        return res.whereType<Map<String, dynamic>>().map((item) {
          final refresh = item['refresh'] is Map<String, dynamic>
              ? item['refresh'] as Map<String, dynamic>
              : item;
          final idStr = (refresh['id'] ?? refresh['Id'])?.toString() ?? '';
          final bIdStr = (refresh['batchId'] ?? refresh['BatchId'])?.toString() ?? '';
          final pIdStr = (refresh['productId'] ?? refresh['ProductId'])?.toString() ?? '';
          final pName = (item['productName'] ?? refresh['productName'])?.toString() ?? '';

          return RefreshEventRecord(
            id: int.tryParse(idStr) ?? idStr.hashCode.abs(),
            cloudId: idStr,
            batchId: int.tryParse(bIdStr) ?? bIdStr.hashCode.abs(),
            cloudBatchId: bIdStr,
            actionType: (refresh['actionType'] ?? refresh['ActionType'])?.toString() ?? '',
            productId: int.tryParse(pIdStr) ?? pIdStr.hashCode.abs(),
            cloudProductId: pIdStr,
            productName: pName,
            quantity: (refresh['quantity'] ?? refresh['Quantity'] ?? 0) as int,
            wastageQuantity: (refresh['wastageQuantity'] ?? refresh['WastageQuantity'] ?? 0) as int,
            reason: (refresh['reason'] ?? refresh['Reason'])?.toString(),
            note: (refresh['note'] ?? refresh['Note'])?.toString(),
            createdAt: DateTime.tryParse((refresh['createdAtUtc'] ?? refresh['CreatedAtUtc'])?.toString() ?? '') ?? DateTime.now(),
          );
        }).toList();
      }
    } catch (_) {}
    return const [];
  }

  Future<String> _resolveBatchId(dynamic batchId) async {
    final str = batchId.toString();
    if (str.contains('-') || str.length >= 32) return str;
    try {
      final all = await listAllBatches();
      for (final b in all) {
        if (b.id.toString() == str || b.cloudId == str) {
          if (b.cloudId != null && b.cloudId!.isNotEmpty) {
            return b.cloudId!;
          }
        }
      }
    } catch (_) {}
    return str;
  }

  Future<String> _resolveProductId(dynamic productId) async {
    final str = productId.toString();
    if (str.contains('-') || str.length >= 32) return str;
    try {
      final names = await _getProductNames();
      if (names.containsKey(str)) return str;
    } catch (_) {}
    return str;
  }

  Future<void> expireBouquet({
    required dynamic batchId,
    required int quantity,
    required String reason,
    String? note,
  }) async {
    final idStr = await _resolveBatchId(batchId);
    final uri = Uri.parse('${_auth.baseUrl}/api/ready-bouquets/$idStr/expire');
    final body = {
      'quantity': quantity,
      'reason': reason,
      'note': note?.trim(),
    };
    await _request('POST', uri, body: body);
  }

  Future<void> refreshBouquet({
    required dynamic batchId,
    required String actionType,
    required dynamic productId,
    required int quantity,
    bool returnToInventory = false,
    String? reason,
    String? note,
  }) async {
    final idStr = await _resolveBatchId(batchId);
    final pIdStr = await _resolveProductId(productId);
    final uri = Uri.parse('${_auth.baseUrl}/api/ready-bouquets/$idStr/refresh');
    final body = {
      'actionType': actionType,
      'productId': pIdStr,
      'quantity': quantity,
      'returnToInventory': returnToInventory,
      'reason': reason,
      'note': note?.trim(),
    };
    await _request('POST', uri, body: body);
  }

  Future<ReadyBouquetBatch> createBatch({
    required dynamic finishedProductId,
    dynamic recipeId,
    dynamic productionId,
    required int initialQuantity,
    required DateTime producedAt,
    required int shelfLifeDays,
    required int refreshAfterDays,
    required DateTime expiryAt,
    String? location,
    String? note,
  }) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/ready-bouquets');
    final body = {
      'finishedProductId': finishedProductId.toString(),
      if (recipeId != null) 'recipeId': recipeId.toString(),
      if (productionId != null) 'productionId': productionId.toString(),
      'initialQuantity': initialQuantity,
      'producedAt': producedAt.toUtc().toIso8601String(),
      'shelfLifeDays': shelfLifeDays,
      'refreshAfterDays': refreshAfterDays,
      'expiryAt': expiryAt.toUtc().toIso8601String(),
      'location': location?.trim() ?? 'Store',
      'note': note?.trim(),
    };

    final response = await _request('POST', uri, body: body);
    if (response is! Map<String, dynamic>) {
      throw StateError('Failed to create ready bouquet batch in cloud');
    }
    return _parseBatch(response);
  }

  Future<dynamic> _request(
    String method,
    Uri uri, {
    dynamic body,
  }) async {
    final sender = _sender;
    if (sender != null) {
      return await sender(method, uri, body: body);
    }

    final token = await _auth.getStoredAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw StateError('Not authenticated with Floraprise Cloud.');
    }

    final client = http.Client();
    try {
      final request = http.Request(method, uri);
      request.headers['Accept'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $token';

      if (body != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode(body);
      }

      final streamedResponse =
          await client.send(request).timeout(const Duration(seconds: 20));
      final text = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode >= 200 &&
          streamedResponse.statusCode < 300) {
        if (text.trim().isEmpty) return null;
        return jsonDecode(text);
      }

      throw StateError(
        'Cloud API error ${streamedResponse.statusCode}: $text',
      );
    } finally {
      client.close();
    }
  }
}
