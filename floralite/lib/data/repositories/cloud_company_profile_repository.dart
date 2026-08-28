import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Cloud Company Profile DTO
/// Represents the company profile fetched from the Cloud API.
class CloudCompanyProfile {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? shortDescription;
  final String timeZone;
  final String currencyCode;
  final String? taxIdentifier;
  final String region;
  final bool isActive;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;

  CloudCompanyProfile({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.shortDescription,
    required this.timeZone,
    required this.currencyCode,
    this.taxIdentifier,
    required this.region,
    required this.isActive,
    required this.createdAtUtc,
    this.updatedAtUtc,
  });

  factory CloudCompanyProfile.fromJson(Map<String, dynamic> json) {
    return CloudCompanyProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      shortDescription: json['shortDescription'],
      timeZone: json['timeZone'] ?? 'UTC',
      currencyCode: json['currencyCode'] ?? 'USD',
      taxIdentifier: json['taxIdentifier'],
      region: json['region'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAtUtc: json['createdAtUtc'] != null
          ? DateTime.parse(json['createdAtUtc'])
          : DateTime.now(),
      updatedAtUtc: json['updatedAtUtc'] != null
          ? DateTime.parse(json['updatedAtUtc'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'shortDescription': shortDescription,
        'timeZone': timeZone,
        'currencyCode': currencyCode,
        'taxIdentifier': taxIdentifier,
        'region': region,
        'isActive': isActive,
        'createdAtUtc': createdAtUtc.toIso8601String(),
        'updatedAtUtc': updatedAtUtc?.toIso8601String(),
      };
}

/// Repository for fetching company profile from Cloud API
/// This is used only in Cloud Store mode to display company information
/// in Settings → Shop Details.
class CloudCompanyProfileRepository {
  static const _cacheKey = 'cloud_company_profile';

  final FlutterSecureStorage _secureStorage;

  CloudCompanyProfileRepository({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Fetches the company profile from the Cloud API.
  /// The endpoint uses the authenticated JWT company_id claim,
  /// ensuring users can only access their own company.
  Future<CloudCompanyProfile?> fetchCompanyProfile({
    required String baseUrl,
    required String accessToken,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/mobile/company/profile');
    final hasAuthorization = accessToken.trim().isNotEmpty;
    String? jwtSub;
    String? jwtCompanyId;
    String? jwtExp;
    DateTime? jwtExpiry;

    try {
      final tokenParts = accessToken.split('.');
      if (tokenParts.length == 3) {
        final normalizedPayload = base64Url.normalize(tokenParts[1]);
        final payload = jsonDecode(
          utf8.decode(base64Url.decode(normalizedPayload)),
        );
        if (payload is Map) {
          jwtSub = payload['sub']?.toString();
          jwtCompanyId = payload['company_id']?.toString();
          final exp = payload['exp'];
          jwtExp = exp?.toString();
          if (exp is num) {
            jwtExpiry = DateTime.fromMillisecondsSinceEpoch(
              (exp * 1000).toInt(),
              isUtc: true,
            );
          }
        }
      }
    } on Object {
      // JWT diagnostics remain null when the token cannot be decoded.
    }

    final currentTime = DateTime.now().toUtc();
    final jwtExpired = jwtExpiry != null && !jwtExpiry.isAfter(currentTime);
    debugPrint('[SHOP-CLOUD-DIAGNOSTIC] URL: $uri');
    debugPrint('[SHOP-CLOUD-DIAGNOSTIC] METHOD: GET');
    debugPrint(
      '[SHOP-CLOUD-DIAGNOSTIC] Authorization present: ${hasAuthorization ? 'YES' : 'NO'}',
    );
    debugPrint('[SHOP-CLOUD-DIAGNOSTIC] JWT sub: ${jwtSub ?? '<unavailable>'}');
    debugPrint(
      '[SHOP-CLOUD-DIAGNOSTIC] JWT company_id: ${jwtCompanyId ?? '<unavailable>'}',
    );
    debugPrint('[SHOP-CLOUD-DIAGNOSTIC] JWT exp: ${jwtExp ?? '<unavailable>'}');
    debugPrint('[SHOP-CLOUD-DIAGNOSTIC] Current time: $currentTime');
    debugPrint(
      '[SHOP-CLOUD-DIAGNOSTIC] JWT expired: ${jwtExpired ? 'YES' : 'NO'}',
    );

    final httpClient = HttpClient();
    try {
      if (accessToken.trim().isEmpty) {
        return null;
      }

      final request = await httpClient.getUrl(uri);
      request.headers.add('Authorization', 'Bearer $accessToken');
      request.headers.contentType = ContentType.json;

      final response = await request.close().timeout(
            const Duration(seconds: 20),
          );

      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final json = jsonDecode(responseBody);
        
        // Handle API response envelope
        final data = json is Map<String, dynamic> ? json['data'] ?? json : json;
        
        if (data is Map<String, dynamic>) {
          final profile = CloudCompanyProfile.fromJson(data);
          
          // Cache the profile for offline use
          await _cacheProfile(profile);
          
          return profile;
        }
      }

      debugPrint('[SHOP-CLOUD-DIAGNOSTIC] HTTP STATUS: ${response.statusCode}');
      debugPrint('[SHOP-CLOUD-DIAGNOSTIC] RESPONSE: $responseBody');

      // If API call fails, try to use cached profile
      return await _getCachedProfile();
    } on Object catch (error, stackTrace) {
      debugPrint(
        '[SHOP-CLOUD-DIAGNOSTIC] EXCEPTION TYPE: ${error.runtimeType}',
      );
      debugPrint('[SHOP-CLOUD-DIAGNOSTIC] EXCEPTION: $error');
      debugPrint('[SHOP-CLOUD-DIAGNOSTIC] STACK TRACE: $stackTrace');

      // On error, return cached profile if available
      return await _getCachedProfile();
    } finally {
      httpClient.close(force: true);
    }
  }

  /// Gets the cached company profile from secure storage.
  Future<CloudCompanyProfile?> _getCachedProfile() async {
    try {
      final cached = await _secureStorage.read(key: _cacheKey);
      if (cached == null || cached.trim().isEmpty) {
        return null;
      }

      final json = jsonDecode(cached) as Map<String, dynamic>;
      return CloudCompanyProfile.fromJson(json);
    } on Object {
      return null;
    }
  }

  /// Caches the company profile in secure storage for offline access.
  Future<void> _cacheProfile(CloudCompanyProfile profile) async {
    try {
      await _secureStorage.write(
        key: _cacheKey,
        value: jsonEncode(profile.toJson()),
      );
    } on Object {
      // Ignore cache write errors
    }
  }

  /// Clears the cached company profile.
  Future<void> clearCache() async {
    try {
      await _secureStorage.delete(key: _cacheKey);
    } on Object {
      // Ignore errors
    }
  }

}
