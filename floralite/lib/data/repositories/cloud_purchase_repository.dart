import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../services/mobile_auth_service.dart';
import 'purchase_repository.dart';

typedef CloudPurchaseSender = Future<dynamic> Function(
  String method,
  Uri uri, {
  dynamic body,
});

class CloudPurchaseRepository {
  CloudPurchaseRepository({
    MobileAuthService? auth,
    CloudPurchaseSender? sender,
  })  : _auth = auth ?? MobileAuthService(),
        _sender = sender;

  final MobileAuthService _auth;
  final CloudPurchaseSender? _sender;

  Future<List<PurchaseListItem>> getByDate(DateTime date, {bool? purchased}) async {
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final queryParams = <String, String>{'date': dateStr};
    if (purchased != null) {
      queryParams['purchased'] = purchased.toString();
    }

    final uri = Uri.parse('${_auth.baseUrl}/api/morning-purchase-list').replace(
      queryParameters: queryParams,
    );

    final response = await _request('GET', uri);
    if (response is! List) return const [];

    return response
        .whereType<Map<String, dynamic>>()
        .map(PurchaseListItem.fromCloudJson)
        .toList();
  }

  Future<PurchaseListItem> addOrUpdateItem({
    required DateTime date,
    required String productId,
    required int quantity,
    required String unit,
    String? supplier,
    String priority = 'Normal',
    String? remarks,
  }) async {
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final uri = Uri.parse('${_auth.baseUrl}/api/morning-purchase-list').replace(
      queryParameters: {'date': dateStr},
    );

    final body = {
      'productId': productId,
      'quantity': quantity,
      'unit': unit,
      'supplier': supplier,
      'priority': priority,
      'remarks': remarks,
    };

    final response = await _request('POST', uri, body: body);
    if (response is! Map<String, dynamic>) {
      throw StateError('Failed to save purchase item: invalid response');
    }

    return PurchaseListItem.fromCloudJson(response);
  }

  Future<PurchaseListItem> updateItem({
    required String cloudId,
    required String productId,
    required int quantity,
    required String unit,
    String? supplier,
    String priority = 'Normal',
    String? remarks,
  }) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/morning-purchase-list/$cloudId');

    final body = {
      'productId': productId,
      'quantity': quantity,
      'unit': unit,
      'supplier': supplier,
      'priority': priority,
      'remarks': remarks,
    };

    final response = await _request('PUT', uri, body: body);
    if (response is! Map<String, dynamic>) {
      throw StateError('Failed to update purchase item: invalid response');
    }

    return PurchaseListItem.fromCloudJson(response);
  }

  Future<void> setPurchased(String cloudId, bool purchased) async {
    final uri =
        Uri.parse('${_auth.baseUrl}/api/morning-purchase-list/$cloudId/purchased');
    final body = {'purchased': purchased};
    await _request('PUT', uri, body: body);
  }

  Future<void> markInventoryUpdated(String cloudId) async {
    final uri = Uri.parse(
        '${_auth.baseUrl}/api/morning-purchase-list/$cloudId/inventory-updated');
    await _request('PUT', uri);
  }

  Future<void> deleteItem(String cloudId) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/morning-purchase-list/$cloudId');
    await _request('DELETE', uri);
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

      if (streamedResponse.statusCode >= 200 && streamedResponse.statusCode < 300) {
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
