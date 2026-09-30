import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../services/mobile_auth_service.dart';
import 'production_repository.dart';

typedef CloudProductionSender = Future<dynamic> Function(
  String method,
  Uri uri, {
  Map<String, dynamic>? body,
});

class CloudProductionRepository {
  CloudProductionRepository({
    MobileAuthService? auth,
    CloudProductionSender? sender,
  })  : _auth = auth ?? MobileAuthService(),
        _sender = sender;

  final MobileAuthService _auth;
  final CloudProductionSender? _sender;

  static final Map<int, String> _intToCloudGuid = {};
  static final Map<String, int> _cloudGuidToInt = {};
  static int _nextSyntheticId = 1;

  static int _resolveIntId(String cloudGuid) {
    if (_cloudGuidToInt.containsKey(cloudGuid)) {
      return _cloudGuidToInt[cloudGuid]!;
    }
    final id = _nextSyntheticId++;
    _cloudGuidToInt[cloudGuid] = id;
    _intToCloudGuid[id] = cloudGuid;
    return id;
  }

  static String _toGuidString(String? input, {int? fallbackInt}) {
    if (input != null && input.trim().isNotEmpty) {
      return input.trim();
    }
    if (fallbackInt != null && _intToCloudGuid.containsKey(fallbackInt)) {
      return _intToCloudGuid[fallbackInt]!;
    }
    final baseStr = input ?? fallbackInt?.toString() ?? '0';
    final hex = baseStr.codeUnits
        .map((c) => c.toRadixString(16).padLeft(2, '0'))
        .join()
        .padRight(32, '0')
        .substring(0, 32);
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  Future<String> _locationId() async {
    final response = await _send('GET', Uri.parse('${_auth.baseUrl}/api/locations'));
    if (response is! List || response.isEmpty) {
      throw StateError('No active Cloud location is available.');
    }
    final first = response.first;
    if (first is! Map) throw StateError('No active Cloud location is available.');
    final id = (first['id'] ?? first['Id'])?.toString() ?? '';
    if (id.isEmpty) throw StateError('Cloud location is missing its identifier.');
    return id;
  }

  Future<List<ProductionProduct>> listFinishedProducts() async {
    final response = await _send(
      'GET',
      Uri.parse('${_auth.baseUrl}/api/production/recipes'),
    );

    if (response is! List) return const [];

    final products = <ProductionProduct>[];
    for (final raw in response) {
      if (raw is! Map) continue;
      final json = raw.cast<String, dynamic>();

      final cloudId = _string(json, 'id');
      final intId = _resolveIntId(cloudId);
      final name = _string(json, 'name', fallback: 'Bouquet');
      final sellingPrice =
          (json[_key(json, 'sellingPrice')] as num?)?.toDouble() ?? 0.0;

      products.add(ProductionProduct(
        id: intId,
        name: name,
        unit: 'Piece',
        barcode: 'FLR-$intId',
        sellingPricePaise: (sellingPrice * 100).round(),
        purchasePricePaise: 0,
        currentQty: 0,
        hasRecipe: true,
      ));
    }

    return products;
  }

  Future<List<ProductionProduct>> listRawProducts() async {
    final response = await _send(
      'GET',
      Uri.parse(
          '${_auth.baseUrl}/api/products?pageSize=200&isActive=true&trackInventory=true'),
    );

    final dynamic items = response is Map
        ? (response['items'] ??
            response['Items'] ??
            response['data'] ??
            response['Data'])
        : response;

    if (items is! List) return const [];

    final products = <ProductionProduct>[];
    for (final raw in items) {
      if (raw is! Map) continue;
      final json = raw.cast<String, dynamic>();

      final category = _string(json, 'category', fallback: 'Other');
      if (ProductionRepository.isFinishedProductCategory(category)) continue;

      final cloudId = _string(json, 'id');
      final intId = _resolveIntId(cloudId);
      final name = _string(json, 'name', fallback: 'Raw Product');
      final unit = _string(json, 'unitOfMeasure', fallback: 'Piece');
      final barcode = _string(json, 'barcode');
      final retailPrice =
          (json[_key(json, 'retailPrice')] as num?)?.toDouble() ?? 0.0;
      final costPrice =
          (json[_key(json, 'costPrice')] as num?)?.toDouble() ?? 0.0;
      final stockQuantity = _int(json, 'stockQuantity');

      products.add(ProductionProduct(
        id: intId,
        name: name,
        unit: unit,
        barcode: barcode,
        sellingPricePaise: (retailPrice * 100).round(),
        purchasePricePaise: (costPrice * 100).round(),
        currentQty: stockQuantity,
        hasRecipe: false,
      ));
    }

    return products;
  }

  Future<ProductionRecipeDetail?> getRecipeDetail(int finishedProductId) async {
    final cloudId = _intToCloudGuid[finishedProductId] ?? finishedProductId.toString();
    final response = await _send(
      'GET',
      Uri.parse('${_auth.baseUrl}/api/production/recipes/$cloudId'),
    );

    if (response is! Map) return null;
    final json = response.cast<String, dynamic>();

    final name = _string(json, 'name', fallback: 'Bouquet');
    final category = _string(json, 'category', fallback: 'Bouquet');
    final sellingPrice =
        (json[_key(json, 'sellingPrice')] as num?)?.toDouble() ?? 0.0;
    final laborCost =
        (json[_key(json, 'laborCost')] as num?)?.toDouble() ?? 0.0;
    final sampleImages = json[_key(json, 'sampleImages')];
    String? imagePath;
    if (sampleImages is List && sampleImages.isNotEmpty) {
      imagePath = sampleImages.first?.toString();
    }

    final rawComponents = json[_key(json, 'components')];
    final items = <RecipeItem>[];
    if (rawComponents is List) {
      for (final rawC in rawComponents) {
        if (rawC is! Map) continue;
        final c = rawC.cast<String, dynamic>();
        final compProdId = _string(c, 'productId');
        final compIntId = _resolveIntId(compProdId);
        final compName = _string(c, 'productName', fallback: 'Component');
        final qty = _int(c, 'quantityRequired');
        final unitCost =
            (c[_key(c, 'unitCost')] as num?)?.toDouble() ?? 0.0;

        items.add(RecipeItem(
          rawProductId: compIntId,
          cloudProductId: compProdId.isNotEmpty ? compProdId : null,
          productName: compName,
          unit: 'Piece',
          quantity: qty > 0 ? qty : 1,
          currentQty: 0,
          purchasePricePaise: (unitCost * 100).round(),
        ));
      }
    }

    return ProductionRecipeDetail(
      finishedProductId: finishedProductId,
      cloudRecipeId: cloudId,
      name: name,
      category: category,
      sellingPricePaise: (sellingPrice * 100).round(),
      labourCostPaise: (laborCost * 100).round(),
      imagePath: imagePath,
      shelfLifeDays: 3,
      refreshAfterDays: 2,
      occasion: null,
      items: items,
    );
  }

  Future<List<RecipeItem>> getRecipeItems(int finishedProductId) async {
    final detail = await getRecipeDetail(finishedProductId);
    return detail?.items ?? const [];
  }

  Future<Map<String, dynamic>?> getRecipeMetadata(int finishedProductId) async {
    final detail = await getRecipeDetail(finishedProductId);
    if (detail == null) return null;
    return {
      'shelf_life_days': detail.shelfLifeDays,
      'refresh_after_days': detail.refreshAfterDays,
      'occasion': detail.occasion,
    };
  }

  Future<int> getMaximumProducibleQuantity(int finishedProductId) async {
    final items = await getRecipeItems(finishedProductId);
    if (items.isEmpty) return 0;
    if (items.any((item) => item.quantity <= 0)) return 0;
    final available = items
        .map((item) =>
            item.currentQty > 0 ? item.currentQty ~/ item.quantity : 999)
        .toList();
    return available.reduce((min, val) => val < min ? val : min);
  }

  Future<int> saveBouquetRecipe({
    int? finishedProductId,
    String? productName,
    String? category,
    required List<RecipeItem> items,
    int sellingPricePaise = 0,
    int shelfLifeDays = 3,
    int refreshAfterDays = 2,
    String? occasion,
    String? imagePath,
    int labourCostPaise = 0,
  }) async {
    if (items.isEmpty) {
      throw StateError('Add at least one component to the recipe');
    }
    if (items.any((item) => item.quantity <= 0)) {
      throw StateError('Recipe quantities must be greater than zero');
    }
    if (finishedProductId == null &&
        (productName == null || productName.trim().isEmpty)) {
      throw StateError('Recipe name is required');
    }

    final trimmedName = (productName ?? '').trim();
    final trimmedCategory = (category ?? 'Bouquet').trim().isEmpty
        ? 'Bouquet'
        : (category ?? 'Bouquet').trim();

    final componentsPayload = items.map((item) {
      final cloudProdGuid =
          _toGuidString(item.cloudProductId, fallbackInt: item.rawProductId);
      return {
        'productId': cloudProdGuid,
        'productName': item.productName,
        'quantityRequired': item.quantity,
        'unitCost': item.purchasePricePaise / 100.0,
      };
    }).toList();

    final body = <String, dynamic>{
      'name': trimmedName.isNotEmpty ? trimmedName : 'Bouquet',
      'category': trimmedCategory,
      'sellingPrice': sellingPricePaise / 100.0,
      'laborCost': labourCostPaise / 100.0,
      'components': componentsPayload,
      if (imagePath != null && imagePath.trim().isNotEmpty)
        'sampleImages': [imagePath.trim()],
      'isActive': true,
    };

    String? existingCloudId = finishedProductId != null
        ? _intToCloudGuid[finishedProductId]
        : null;

    if (existingCloudId == null && trimmedName.isNotEmpty) {
      try {
        final recipes = await listFinishedProducts();
        final match = recipes.firstWhere(
          (r) => r.name.trim().toLowerCase() == trimmedName.toLowerCase(),
          orElse: () => const ProductionProduct(
            id: -1,
            name: '',
            unit: '',
            barcode: '',
            sellingPricePaise: 0,
            purchasePricePaise: 0,
            currentQty: 0,
            hasRecipe: false,
          ),
        );
        if (match.id != -1 && _intToCloudGuid.containsKey(match.id)) {
          existingCloudId = _intToCloudGuid[match.id];
        }
      } catch (_) {}
    }

    dynamic response;
    if (existingCloudId != null) {
      response = await _send(
        'PUT',
        Uri.parse('${_auth.baseUrl}/api/production/recipes/$existingCloudId'),
        body: body,
      );
    } else {
      response = await _send(
        'POST',
        Uri.parse('${_auth.baseUrl}/api/production/recipes'),
        body: body,
      );
    }

    if (response is! Map) {
      throw StateError('Failed to save recipe to Floraprise Cloud.');
    }

    final cloudId = _string(response.cast<String, dynamic>(), 'id');
    final intId = _resolveIntId(cloudId);
    return intId;
  }

  Future<void> saveRecipe({
    required int finishedProductId,
    required List<RecipeItem> items,
    int shelfLifeDays = 3,
    int refreshAfterDays = 2,
    String? occasion,
  }) async {
    final detail = await getRecipeDetail(finishedProductId);
    await saveBouquetRecipe(
      finishedProductId: finishedProductId,
      productName: detail?.name,
      category: detail?.category,
      items: items,
      sellingPricePaise: detail?.sellingPricePaise ?? 0,
      labourCostPaise: detail?.labourCostPaise ?? 0,
      shelfLifeDays: shelfLifeDays,
      refreshAfterDays: refreshAfterDays,
      occasion: occasion,
      imagePath: detail?.imagePath,
    );
  }

  Future<ProductionResult> produce({
    required int finishedProductId,
    required int quantity,
    String? note,
    String operatorName = 'Admin',
    String? deviceName,
  }) async {
    if (quantity <= 0) {
      throw StateError('Production quantity must be greater than zero');
    }

    final cloudRecipeGuid =
        _toGuidString(null, fallbackInt: finishedProductId);
    final locationId = await _locationId();
    final expiry =
        DateTime.now().toUtc().add(const Duration(days: 3)).toIso8601String();

    final runResponse = await _send(
      'POST',
      Uri.parse('${_auth.baseUrl}/api/production/runs'),
      body: {
        'recipeId': cloudRecipeGuid,
        'quantity': quantity,
        'expectedExpiry': expiry,
        'locationId': locationId,
        'operatorName':
            operatorName.trim().isEmpty ? 'Admin' : operatorName.trim(),
      },
    );

    if (runResponse is! Map) {
      throw StateError('Failed to record production run on Floraprise Cloud.');
    }

    final json = runResponse.cast<String, dynamic>();
    final batchId = _string(json, 'batchId');
    final batchCode = _string(json, 'batchCode');
    final barcode = _string(json, 'barcode');
    final quantityProduced = _int(json, 'quantityProduced');
    final totalCost = (json[_key(json, 'totalCost')] as num?)?.toDouble() ?? 0.0;
    final productionId = _resolveIntId(batchId);

    return ProductionResult(
      productionId: productionId,
      productionCostPaise: (totalCost * 100).round(),
      finishedQuantity: quantityProduced > 0 ? quantityProduced : quantity,
      finishedProductId: finishedProductId,
      barcode:
          barcode.isNotEmpty ? barcode : (batchCode.isNotEmpty ? batchCode : null),
    );
  }

  Future<ProductionResult> produceBouquet({
    required int? finishedProductId,
    required String productName,
    required String category,
    int quantity = 1,
    required List<RecipeItem> components,
    required int sellingPricePaise,
    int labourCostPaise = 0,
    String? imagePath,
    int shelfLifeDays = 3,
    int refreshAfterDays = 2,
    String? note,
    String operatorName = 'Admin',
    String? deviceName,
  }) async {
    if (quantity <= 0) {
      throw StateError('Production quantity must be greater than zero');
    }
    if (components.isEmpty) {
      throw StateError('Add at least one component to the bouquet');
    }
    if (components.any((c) => c.quantity <= 0)) {
      throw StateError('Component quantities must be greater than zero');
    }

    // Step 1: Ensure recipe exists on Cloud
    int targetProductId;
    if (finishedProductId != null &&
        _intToCloudGuid.containsKey(finishedProductId)) {
      targetProductId = finishedProductId;
    } else {
      targetProductId = await saveBouquetRecipe(
        finishedProductId: finishedProductId,
        productName: productName,
        category: category,
        items: components,
        sellingPricePaise: sellingPricePaise,
        labourCostPaise: labourCostPaise,
        shelfLifeDays: shelfLifeDays,
        refreshAfterDays: refreshAfterDays,
        imagePath: imagePath,
      );
    }

    final cloudRecipeGuid =
        _toGuidString(null, fallbackInt: targetProductId);
    final locationId = await _locationId();
    final expiryDays = shelfLifeDays > 0 ? shelfLifeDays : 3;
    final expiry =
        DateTime.now().toUtc().add(Duration(days: expiryDays)).toIso8601String();

    final runResponse = await _send(
      'POST',
      Uri.parse('${_auth.baseUrl}/api/production/runs'),
      body: {
        'recipeId': cloudRecipeGuid,
        'quantity': quantity,
        'expectedExpiry': expiry,
        'locationId': locationId,
        'operatorName':
            operatorName.trim().isEmpty ? 'Admin' : operatorName.trim(),
      },
    );

    if (runResponse is! Map) {
      throw StateError('Failed to record production run on Floraprise Cloud.');
    }

    final json = runResponse.cast<String, dynamic>();
    final batchId = _string(json, 'batchId');
    final batchCode = _string(json, 'batchCode');
    final barcode = _string(json, 'barcode');
    final quantityProduced = _int(json, 'quantityProduced');
    final totalCost = (json[_key(json, 'totalCost')] as num?)?.toDouble() ?? 0.0;
    final productionId = _resolveIntId(batchId);

    return ProductionResult(
      productionId: productionId,
      productionCostPaise: (totalCost * 100).round(),
      finishedQuantity: quantityProduced > 0 ? quantityProduced : quantity,
      finishedProductId: targetProductId,
      barcode:
          barcode.isNotEmpty ? barcode : (batchCode.isNotEmpty ? batchCode : null),
      productName: productName,
      sellingPricePaise: sellingPricePaise,
    );
  }

  Future<List<ProductionReportRecord>> getProductionReport({
    required DateTime startDate,
    required DateTime endDate,
    int? productId,
  }) async {
    final startUtc =
        DateTime.utc(startDate.year, startDate.month, startDate.day);
    final endUtc =
        DateTime.utc(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    final response = await _send(
      'GET',
      Uri.parse('${_auth.baseUrl}/api/production/finished-goods').replace(
        queryParameters: {
          'startDate': startUtc.toIso8601String(),
          'endDate': endUtc.toIso8601String(),
        },
      ),
    );

    if (response is! List) return const [];

    final records = <ProductionReportRecord>[];
    for (final raw in response) {
      if (raw is! Map) continue;
      final json = raw.cast<String, dynamic>();

      final cloudId = _string(json, 'id');
      final intId = _resolveIntId(cloudId);
      final recipeName = _string(json, 'recipeName', fallback: 'Bouquet');
      final quantityProduced = _int(json, 'quantityProduced');
      final quantityAvailable = _int(json, 'quantityAvailable');
      final totalCost =
          (json[_key(json, 'totalCost')] as num?)?.toDouble() ?? 0.0;
      final isReversed = json[_key(json, 'isReversed')] == true ||
          _string(json, 'status').toLowerCase() == 'reversed' ||
          _string(json, 'reversedAt').isNotEmpty;
      final producedAt =
          _string(json, 'producedAt', fallback: DateTime.now().toIso8601String());

      records.add(ProductionReportRecord(
        id: intId,
        producedAt: producedAt,
        productName: recipeName,
        quantity: quantityProduced,
        productionCostPaise: (totalCost * 100).round(),
        currentStock: quantityAvailable,
        isReversed: isReversed,
      ));
    }

    return records;
  }

  Future<ProductionDetail?> getProductionDetail(int productionId) async {
    final cloudId = _intToCloudGuid[productionId] ?? productionId.toString();
    final response = await _send(
      'GET',
      Uri.parse('${_auth.baseUrl}/api/production/finished-goods/$cloudId'),
    );

    if (response is! Map) return null;
    final json = response.cast<String, dynamic>();

    final rawConsumptions = json[_key(json, 'consumptions')];
    final consumptions = <ProductionConsumptionDetail>[];

    if (rawConsumptions is List) {
      for (var i = 0; i < rawConsumptions.length; i++) {
        final cRaw = rawConsumptions[i];
        if (cRaw is! Map) continue;
        final c = cRaw.cast<String, dynamic>();
        final cUnitCost =
            (c[_key(c, 'unitCost')] as num?)?.toDouble() ?? 0.0;
        final cTotalCost =
            (c[_key(c, 'totalCost')] as num?)?.toDouble() ?? 0.0;

        consumptions.add(ProductionConsumptionDetail(
          rawProductId: -(i + 1),
          productName: _string(c, 'productName', fallback: 'Component'),
          unit: _string(c, 'unit', fallback: 'Piece'),
          quantity: _int(c, 'quantity'),
          unitCostPaise: (cUnitCost * 100).round(),
          totalCostPaise: (cTotalCost * 100).round(),
        ));
      }
    }

    final totalCost =
        (json[_key(json, 'totalCost')] as num?)?.toDouble() ?? 0.0;
    final isReversed = json[_key(json, 'isReversed')] == true ||
        _string(json, 'status').toLowerCase() == 'reversed' ||
        _string(json, 'reversedAt').isNotEmpty;

    return ProductionDetail(
      id: productionId,
      finishedProductId: 0,
      productName: _string(json, 'recipeName', fallback: 'Bouquet'),
      quantity: _int(json, 'quantityProduced'),
      productionCostPaise: (totalCost * 100).round(),
      producedAt:
          _string(json, 'producedAt', fallback: DateTime.now().toIso8601String()),
      operatorName: _string(json, 'operatorName', fallback: 'Staff'),
      deviceName: _nullableString(json, 'locationName') ?? 'Store',
      note: _string(json, 'batchCode'),
      reversedAt: isReversed
          ? _nullableString(json, 'reversedAt') ??
              DateTime.now().toIso8601String()
          : null,
      reversalNote: _nullableString(json, 'reversalNote'),
      consumptions: consumptions,
    );
  }

  Future<void> reverseProduction({
    required int productionId,
    String? note,
  }) async {
    final cloudId = _intToCloudGuid[productionId] ?? productionId.toString();
    await _send(
      'POST',
      Uri.parse('${_auth.baseUrl}/api/production/finished-goods/$cloudId/reverse'),
      body: {
        if (note?.trim().isNotEmpty == true) 'reason': note!.trim(),
      },
    );
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
    final client = http.Client();
    try {
      final request = http.Request(method, uri);
      request.headers['Accept'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $token';
      if (body != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = encodedBody!;
      }

      final streamedResponse =
          await client.send(request).timeout(const Duration(seconds: 20));
      final responseBody = await streamedResponse.stream.bytesToString();

      final decoded = responseBody.trim().isEmpty
          ? <String, dynamic>{}
          : _decode(responseBody);

      if (streamedResponse.statusCode < 200 ||
          streamedResponse.statusCode >= 300) {
        final message = decoded is Map
            ? decoded['message'] ??
                decoded['detail'] ??
                decoded['title'] ??
                decoded['error']
            : null;
        throw StateError(
          message?.toString() ??
              'Cloud production request failed (HTTP ${streamedResponse.statusCode}).',
        );
      }
      return decoded;
    } catch (error) {
      if (error is StateError) rethrow;
      throw StateError('Unable to connect to Floraprise Cloud: $error');
    } finally {
      client.close();
    }
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
}
