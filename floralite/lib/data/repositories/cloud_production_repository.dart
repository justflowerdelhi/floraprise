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

  Future<List<ProductionReportRecord>> getProductionReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final startUtc = DateTime.utc(startDate.year, startDate.month, startDate.day);
    final endUtc = DateTime.utc(endDate.year, endDate.month, endDate.day, 23, 59, 59);

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
      final totalCost = (json[_key(json, 'totalCost')] as num?)?.toDouble() ?? 0.0;
      final isReversed = json[_key(json, 'isReversed')] == true ||
          _string(json, 'status').toLowerCase() == 'reversed' ||
          _string(json, 'reversedAt').isNotEmpty;
      final producedAt = _string(json, 'producedAt', fallback: DateTime.now().toIso8601String());

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
        final cUnitCost = (c[_key(c, 'unitCost')] as num?)?.toDouble() ?? 0.0;
        final cTotalCost = (c[_key(c, 'totalCost')] as num?)?.toDouble() ?? 0.0;

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

    final totalCost = (json[_key(json, 'totalCost')] as num?)?.toDouble() ?? 0.0;
    final isReversed = json[_key(json, 'isReversed')] == true ||
        _string(json, 'status').toLowerCase() == 'reversed' ||
        _string(json, 'reversedAt').isNotEmpty;

    return ProductionDetail(
      id: productionId,
      finishedProductId: 0,
      productName: _string(json, 'recipeName', fallback: 'Bouquet'),
      quantity: _int(json, 'quantityProduced'),
      productionCostPaise: (totalCost * 100).round(),
      producedAt: _string(json, 'producedAt', fallback: DateTime.now().toIso8601String()),
      operatorName: _string(json, 'operatorName', fallback: 'Staff'),
      deviceName: _nullableString(json, 'locationName') ?? 'Store',
      note: _string(json, 'batchCode'),
      reversedAt: isReversed ? _nullableString(json, 'reversedAt') ?? DateTime.now().toIso8601String() : null,
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

      if (streamedResponse.statusCode < 200 || streamedResponse.statusCode >= 300) {
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
