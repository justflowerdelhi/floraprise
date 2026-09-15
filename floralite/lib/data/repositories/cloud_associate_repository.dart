import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../services/mobile_auth_service.dart';
import 'associate_repository.dart';

typedef CloudAssociateSender = Future<dynamic> Function(
  String method,
  Uri uri, {
  dynamic body,
});

class CloudAssociateRepository {
  CloudAssociateRepository({
    MobileAuthService? auth,
    CloudAssociateSender? sender,
  })  : _auth = auth ?? MobileAuthService(),
        _sender = sender;

  final MobileAuthService _auth;
  final CloudAssociateSender? _sender;

  Future<List<AssociateRecord>> getAll({
    bool includeDeleted = false,
    bool activeOnly = false,
  }) async {
    final queryParams = <String, String>{};
    if (!activeOnly) {
      queryParams['includeInactive'] = 'true';
    }

    final uri = Uri.parse('${_auth.baseUrl}/api/associates').replace(
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    final response = await _request('GET', uri);
    if (response is! List) return const [];

    final associates = response
        .whereType<Map<String, dynamic>>()
        .map(AssociateRecord.fromCloudJson)
        .toList();

    if (!includeDeleted) {
      return associates.where((a) => a.deletedAt == null).toList();
    }
    return associates;
  }

  Future<List<AssociateRecord>> searchAssociates({
    String? query,
    List<AssociateType>? types,
    bool activeOnly = true,
  }) async {
    final queryParams = <String, String>{};
    if (query != null && query.trim().isNotEmpty) {
      queryParams['query'] = query.trim();
    }
    if (!activeOnly) {
      queryParams['includeInactive'] = 'true';
    }

    final uri = Uri.parse('${_auth.baseUrl}/api/associates').replace(
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    final response = await _request('GET', uri);
    if (response is! List) return const [];

    var associates = response
        .whereType<Map<String, dynamic>>()
        .map(AssociateRecord.fromCloudJson)
        .where((a) => a.deletedAt == null);

    if (types != null && types.isNotEmpty) {
      associates = associates.where(
        (a) => a.types.any((t) => types.contains(t)),
      );
    }

    return associates.toList();
  }

  Future<AssociateRecord?> findById(String cloudId) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/associates/$cloudId');
    final response = await _request('GET', uri);
    if (response is! Map<String, dynamic>) return null;
    return AssociateRecord.fromCloudJson(response);
  }

  Future<AssociateRecord> create(AssociateUpsertInput input) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/associates');
    final body = {
      'businessName': input.businessName.trim(),
      'contactPerson': input.contactPerson?.trim(),
      'phone': input.phone.trim(),
      'whatsapp': input.whatsapp?.trim(),
      'email': input.email?.trim(),
      'city': input.city.trim(),
      'state': input.state?.trim(),
      'pincode': input.pincode.trim(),
      'address': input.address?.trim(),
      'gstNumber': input.gstNumber?.trim(),
      'website': input.website?.trim(),
      'notes': input.notes?.trim(),
      'types': input.types.map((t) => t.storageValue).toList(),
      'isActive': input.isActive,
    };

    final response = await _request('POST', uri, body: body);
    if (response is! Map<String, dynamic>) {
      throw StateError('Failed to create cloud associate');
    }
    return AssociateRecord.fromCloudJson(response);
  }

  Future<AssociateRecord> update(
    String cloudId,
    AssociateUpsertInput input,
  ) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/associates/$cloudId');
    final body = {
      'businessName': input.businessName.trim(),
      'contactPerson': input.contactPerson?.trim(),
      'phone': input.phone.trim(),
      'whatsapp': input.whatsapp?.trim(),
      'email': input.email?.trim(),
      'city': input.city.trim(),
      'state': input.state?.trim(),
      'pincode': input.pincode.trim(),
      'address': input.address?.trim(),
      'gstNumber': input.gstNumber?.trim(),
      'website': input.website?.trim(),
      'notes': input.notes?.trim(),
      'types': input.types.map((t) => t.storageValue).toList(),
      'isActive': input.isActive,
    };

    final response = await _request('PUT', uri, body: body);
    if (response is! Map<String, dynamic>) {
      throw StateError('Failed to update cloud associate');
    }
    return AssociateRecord.fromCloudJson(response);
  }

  Future<void> deactivate(String cloudId) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/associates/$cloudId/deactivate');
    await _request('PUT', uri);
  }

  Future<void> reactivate(String cloudId) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/associates/$cloudId/reactivate');
    await _request('PUT', uri);
  }

  Future<void> delete(String cloudId) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/associates/$cloudId');
    await _request('DELETE', uri);
  }

  Future<int> getActiveCount() async {
    final associates = await getAll(activeOnly: true);
    return associates.length;
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
