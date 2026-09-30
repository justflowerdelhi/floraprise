import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../models/library_models.dart';
import '../../services/mobile_auth_service.dart';

typedef LibraryHttpSender = Future<dynamic> Function(
  String method,
  Uri uri, {
  Map<String, dynamic>? body,
});

class LibraryRepository {
  LibraryRepository({
    MobileAuthService? auth,
    LibraryHttpSender? sender,
    http.Client? client,
  })  : _auth = auth ?? MobileAuthService(),
        _sender = sender,
        _client = client ?? http.Client();

  final MobileAuthService _auth;
  final LibraryHttpSender? _sender;
  final http.Client _client;

  // Local in-memory cache
  LibraryManifest? _cachedManifest;
  List<LibraryCategoryTree>? _cachedCategoryTree;

  Future<Map<String, String>> _headers() async {
    final token = await _auth.getStoredAccessToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> _send(String method, Uri uri, {Map<String, dynamic>? body}) async {
    if (_sender != null) {
      return _sender!(method, uri, body: body);
    }

    final headers = await _headers();
    http.Response response;

    switch (method.toUpperCase()) {
      case 'GET':
        response = await _client.get(uri, headers: headers);
        break;
      case 'POST':
        response = await _client.post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      default:
        throw UnsupportedError('HTTP method $method not supported');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    throw Exception('API error (${response.statusCode}): ${response.body}');
  }

  // ================= Manifest & Freshness =================

  Future<LibraryManifest?> getManifest({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedManifest != null) {
      return _cachedManifest;
    }

    try {
      final uri = Uri.parse('${_auth.baseUrl}/api/v1/library/manifest');
      final data = await _send('GET', uri);
      if (data is Map<String, dynamic>) {
        _cachedManifest = LibraryManifest.fromJson(data);
        return _cachedManifest;
      }
    } catch (e) {
      debugPrint('Error fetching library manifest: $e');
    }
    return _cachedManifest;
  }

  // ================= Categories =================

  Future<List<LibraryCategory>> getCategories({
    String? search,
    String? parentCategoryId,
    int page = 1,
    int pageSize = 50,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (parentCategoryId != null && parentCategoryId.isNotEmpty)
        'parentCategoryId': parentCategoryId,
    };

    final uri = Uri.parse('${_auth.baseUrl}/api/v1/library/categories')
        .replace(queryParameters: queryParams);

    final data = await _send('GET', uri);
    if (data is Map<String, dynamic> && data['items'] is List) {
      return (data['items'] as List)
          .map((c) => LibraryCategory.fromJson(c as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<LibraryCategoryTree>> getCategoryTree({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedCategoryTree != null && _cachedCategoryTree!.isNotEmpty) {
      return _cachedCategoryTree!;
    }

    try {
      final uri = Uri.parse('${_auth.baseUrl}/api/v1/library/categories/tree');
      final data = await _send('GET', uri);
      if (data is List) {
        _cachedCategoryTree = data
            .map((c) => LibraryCategoryTree.fromJson(c as Map<String, dynamic>))
            .toList();
        return _cachedCategoryTree!;
      }
    } catch (e) {
      debugPrint('Error fetching category tree: $e');
      if (_cachedCategoryTree != null) return _cachedCategoryTree!;
    }
    return [];
  }

  Future<LibraryCategory?> getCategoryById(String id) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/v1/library/categories/$id');
    final data = await _send('GET', uri);
    if (data is Map<String, dynamic>) {
      return LibraryCategory.fromJson(data);
    }
    return null;
  }

  // ================= Products =================

  Future<List<LibraryProduct>> getProducts({
    String? search,
    String? categoryId,
    String? productType,
    int page = 1,
    int pageSize = 30,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
      if (productType != null && productType.isNotEmpty) 'productType': productType,
    };

    final uri = Uri.parse('${_auth.baseUrl}/api/v1/library/products')
        .replace(queryParameters: queryParams);

    final data = await _send('GET', uri);
    if (data is Map<String, dynamic> && data['items'] is List) {
      return (data['items'] as List)
          .map((p) => LibraryProduct.fromJson(p as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<LibraryProduct?> getProductById(String id) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/v1/library/products/$id');
    final data = await _send('GET', uri);
    if (data is Map<String, dynamic>) {
      return LibraryProduct.fromJson(data);
    }
    return null;
  }

  Future<LibraryImportResult> importProduct(
    String libraryProductId, {
    String? customSku,
    double? customRetailPrice,
    double? customCostPrice,
    String? customCategoryId,
  }) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/v1/library/products/$libraryProductId/import');
    final body = <String, dynamic>{
      if (customSku != null && customSku.trim().isNotEmpty) 'customSku': customSku.trim(),
      if (customRetailPrice != null) 'customRetailPrice': customRetailPrice,
      if (customCostPrice != null) 'customCostPrice': customCostPrice,
      if (customCategoryId != null && customCategoryId.isNotEmpty)
        'customCategoryId': customCategoryId,
    };

    final data = await _send('POST', uri, body: body.isNotEmpty ? body : null);
    if (data is Map<String, dynamic>) {
      return LibraryImportResult.fromJson(data);
    }
    return const LibraryImportResult(
      success: false,
      alreadyImported: false,
      message: 'Failed to parse import response.',
    );
  }

  // ================= Recipes =================

  Future<List<LibraryRecipe>> getRecipes({
    String? search,
    String? categoryId,
    int page = 1,
    int pageSize = 30,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
    };

    final uri = Uri.parse('${_auth.baseUrl}/api/v1/library/recipes')
        .replace(queryParameters: queryParams);

    final data = await _send('GET', uri);
    if (data is Map<String, dynamic> && data['items'] is List) {
      return (data['items'] as List)
          .map((r) => LibraryRecipe.fromJson(r as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<LibraryRecipe?> getRecipeById(String id) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/v1/library/recipes/$id');
    final data = await _send('GET', uri);
    if (data is Map<String, dynamic>) {
      return LibraryRecipe.fromJson(data);
    }
    return null;
  }

  Future<LibraryImportResult> importRecipe(String libraryRecipeId) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/v1/library/recipes/$libraryRecipeId/import');
    final data = await _send('POST', uri);
    if (data is Map<String, dynamic>) {
      return LibraryImportResult.fromJson(data);
    }
    return const LibraryImportResult(
      success: false,
      alreadyImported: false,
      message: 'Failed to parse recipe import response.',
    );
  }

  // ================= Designs =================

  Future<List<LibraryDesign>> getDesigns({
    String? search,
    String? categoryId,
    String? occasion,
    String? style,
    int page = 1,
    int pageSize = 30,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
      if (occasion != null && occasion.trim().isNotEmpty) 'occasion': occasion.trim(),
      if (style != null && style.trim().isNotEmpty) 'style': style.trim(),
    };

    final uri = Uri.parse('${_auth.baseUrl}/api/v1/library/designs')
        .replace(queryParameters: queryParams);

    final data = await _send('GET', uri);
    if (data is Map<String, dynamic> && data['items'] is List) {
      return (data['items'] as List)
          .map((d) => LibraryDesign.fromJson(d as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<LibraryDesign?> getDesignById(String id) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/v1/library/designs/$id');
    final data = await _send('GET', uri);
    if (data is Map<String, dynamic>) {
      return LibraryDesign.fromJson(data);
    }
    return null;
  }

  Future<LibraryImportResult> importDesign(String libraryDesignId) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/v1/library/designs/$libraryDesignId/import');
    final data = await _send('POST', uri);
    if (data is Map<String, dynamic>) {
      return LibraryImportResult.fromJson(data);
    }
    return const LibraryImportResult(
      success: false,
      alreadyImported: false,
      message: 'Failed to parse design import response.',
    );
  }

  // ================= Greeting Cards =================

  Future<List<LibraryCardTemplate>> getCards({
    String? search,
    String? occasion,
    String? tone,
    String? language,
    String? categoryId,
    int page = 1,
    int pageSize = 50,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (occasion != null && occasion.trim().isNotEmpty) 'occasion': occasion.trim(),
      if (tone != null && tone.trim().isNotEmpty) 'tone': tone.trim(),
      if (language != null && language.trim().isNotEmpty) 'language': language.trim(),
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
    };

    final uri = Uri.parse('${_auth.baseUrl}/api/v1/library/cards')
        .replace(queryParameters: queryParams);

    final data = await _send('GET', uri);
    if (data is Map<String, dynamic> && data['items'] is List) {
      return (data['items'] as List)
          .map((c) => LibraryCardTemplate.fromJson(c as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<LibraryCardOccasionSummary>> getCardOccasions({String? language}) async {
    final queryParams = <String, String>{
      if (language != null && language.trim().isNotEmpty) 'language': language.trim(),
    };

    final uri = Uri.parse('${_auth.baseUrl}/api/v1/library/cards/occasions')
        .replace(queryParameters: queryParams);

    final data = await _send('GET', uri);
    if (data is List) {
      return data
          .map((o) => LibraryCardOccasionSummary.fromJson(o as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<LibraryCardTemplate?> getCardById(String id) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/v1/library/cards/$id');
    final data = await _send('GET', uri);
    if (data is Map<String, dynamic>) {
      return LibraryCardTemplate.fromJson(data);
    }
    return null;
  }

  // ================= Tutorials =================

  Future<List<LibraryTutorial>> getTutorials({
    String? search,
    String? categoryId,
    String? difficultyLevel,
    String? tag,
    int page = 1,
    int pageSize = 30,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
      if (difficultyLevel != null && difficultyLevel.trim().isNotEmpty)
        'difficultyLevel': difficultyLevel.trim(),
      if (tag != null && tag.trim().isNotEmpty) 'tag': tag.trim(),
    };

    final uri = Uri.parse('${_auth.baseUrl}/api/v1/library/tutorials')
        .replace(queryParameters: queryParams);

    final data = await _send('GET', uri);
    if (data is Map<String, dynamic> && data['items'] is List) {
      return (data['items'] as List)
          .map((t) => LibraryTutorial.fromJson(t as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<LibraryTutorial?> getTutorialById(String id) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/v1/library/tutorials/$id');
    final data = await _send('GET', uri);
    if (data is Map<String, dynamic>) {
      return LibraryTutorial.fromJson(data);
    }
    return null;
  }

  Future<LibraryTutorial?> getTutorialBySlug(String slug) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/v1/library/tutorials/slug/$slug');
    final data = await _send('GET', uri);
    if (data is Map<String, dynamic>) {
      return LibraryTutorial.fromJson(data);
    }
    return null;
  }

  // ================= Festivals =================

  Future<List<LibraryFestival>> getFestivals({
    String? search,
    int? month,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int pageSize = 50,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (month != null) 'month': month.toString(),
      if (from != null) 'from': from.toUtc().toIso8601String(),
      if (to != null) 'to': to.toUtc().toIso8601String(),
    };

    final uri = Uri.parse('${_auth.baseUrl}/api/v1/library/festivals')
        .replace(queryParameters: queryParams);

    try {
      final data = await _send('GET', uri);
      if (data is Map<String, dynamic> && data['items'] is List) {
        return (data['items'] as List)
            .map((f) => LibraryFestival.fromJson(f as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching library festivals: $e');
    }
    return [];
  }

  Future<LibraryFestival?> getFestivalById(String id) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/v1/library/festivals/$id');
    final data = await _send('GET', uri);
    if (data is Map<String, dynamic>) {
      return LibraryFestival.fromJson(data);
    }
    return null;
  }

  // ================= Wedding Dates (Muhurats) =================

  Future<List<LibraryWeddingDate>> getWeddingDates({
    String? search,
    String? season,
    String? demandLevel,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int pageSize = 50,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (season != null && season.trim().isNotEmpty) 'season': season.trim(),
      if (demandLevel != null && demandLevel.trim().isNotEmpty)
        'demandLevel': demandLevel.trim(),
      if (from != null) 'from': from.toUtc().toIso8601String(),
      if (to != null) 'to': to.toUtc().toIso8601String(),
    };

    final uri = Uri.parse('${_auth.baseUrl}/api/v1/library/wedding-dates')
        .replace(queryParameters: queryParams);

    try {
      final data = await _send('GET', uri);
      if (data is Map<String, dynamic> && data['items'] is List) {
        return (data['items'] as List)
            .map((w) => LibraryWeddingDate.fromJson(w as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching library wedding dates: $e');
    }
    return [];
  }

  Future<LibraryWeddingDate?> getWeddingDateById(String id) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/v1/library/wedding-dates/$id');
    final data = await _send('GET', uri);
    if (data is Map<String, dynamic>) {
      return LibraryWeddingDate.fromJson(data);
    }
    return null;
  }
}

