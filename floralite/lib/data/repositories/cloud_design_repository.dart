import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/design.dart';
import '../../services/mobile_auth_service.dart';

typedef CloudDesignSender = Future<dynamic> Function(
  String method,
  Uri uri, {
  dynamic body,
});

class CloudDesignRepository {
  CloudDesignRepository({
    MobileAuthService? auth,
    CloudDesignSender? sender,
  })  : _auth = auth ?? MobileAuthService(),
        _sender = sender;

  final MobileAuthService _auth;
  final CloudDesignSender? _sender;

  Future<List<DesignRecord>> listDesigns({
    String? query,
    String? flower,
    String? occasion,
    String? color,
    String? status,
    bool? favourite,
    int? minPricePaise,
    int? maxPricePaise,
  }) async {
    final queryParams = <String, String>{};
    if (query != null && query.trim().isNotEmpty) {
      queryParams['query'] = query.trim();
    }
    if (flower != null && flower.trim().isNotEmpty) {
      queryParams['flower'] = flower.trim();
    }
    if (occasion != null && occasion.trim().isNotEmpty) {
      queryParams['occasion'] = occasion.trim();
    }
    if (color != null && color.trim().isNotEmpty) {
      queryParams['color'] = color.trim();
    }
    if (status != null && status.trim().isNotEmpty) {
      queryParams['status'] = status.trim();
    }
    if (favourite != null) {
      queryParams['favorite'] = favourite.toString();
    }
    if (minPricePaise != null) {
      queryParams['minPricePaise'] = minPricePaise.toString();
    }
    if (maxPricePaise != null) {
      queryParams['maxPricePaise'] = maxPricePaise.toString();
    }

    final uri = Uri.parse('${_auth.baseUrl}/api/designs').replace(
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    final response = await _request('GET', uri);
    if (response is! List) return const [];

    return response
        .whereType<Map<String, dynamic>>()
        .map(DesignRecord.fromCloudJson)
        .toList();
  }

  Future<DesignRecord?> getDesign(String id) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/designs/$id');
    final response = await _request('GET', uri);
    if (response is! Map<String, dynamic>) return null;
    return DesignRecord.fromCloudJson(response);
  }

  Future<DesignRecord> create({
    required String? imagePath,
    required String description,
    int? sellingPricePaise,
    String? flowers,
    String? occasion,
    String? color,
    String? collection,
    String? notes,
    bool isFavorite = false,
  }) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/designs');
    final body = {
      'description': description.trim(),
      'imageReference': imagePath?.trim(),
      'sellingPricePaise': sellingPricePaise,
      'flowers': flowers?.trim(),
      'occasion': occasion?.trim(),
      'color': color?.trim(),
      'collection': collection?.trim(),
      'notes': notes?.trim(),
      'isFavorite': isFavorite,
    };

    final response = await _request('POST', uri, body: body);
    if (response is! Map<String, dynamic>) {
      throw StateError('Failed to create cloud design: unexpected response.');
    }
    return DesignRecord.fromCloudJson(response);
  }

  Future<DesignRecord> update(
    String id, {
    String? imagePath,
    required String description,
    int? sellingPricePaise,
    String? flowers,
    String? occasion,
    String? color,
    String? collection,
    String? notes,
    bool? isFavorite,
  }) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/designs/$id');
    final body = {
      'description': description.trim(),
      'imageReference': imagePath?.trim(),
      'sellingPricePaise': sellingPricePaise,
      'flowers': flowers?.trim(),
      'occasion': occasion?.trim(),
      'color': color?.trim(),
      'collection': collection?.trim(),
      'notes': notes?.trim(),
      'isFavorite': isFavorite ?? false,
    };

    final response = await _request('PUT', uri, body: body);
    if (response is! Map<String, dynamic>) {
      throw StateError('Failed to update cloud design: unexpected response.');
    }
    return DesignRecord.fromCloudJson(response);
  }

  Future<void> setFavorite(String id, bool isFavorite) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/designs/$id/favorite');
    await _request('PUT', uri, body: isFavorite);
  }

  Future<void> delete(String id) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/designs/$id');
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
