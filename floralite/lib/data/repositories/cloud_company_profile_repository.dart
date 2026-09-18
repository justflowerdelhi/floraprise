import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

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
  final bool? taxEnabled;
  final String? taxLabel;
  final double? taxRatePercent;
  final bool? taxInclusive;
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
    this.taxEnabled,
    this.taxLabel,
    this.taxRatePercent,
    this.taxInclusive,
    required this.isActive,
    required this.createdAtUtc,
    this.updatedAtUtc,
  });

  CloudCompanyProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? shortDescription,
    String? timeZone,
    String? currencyCode,
    String? taxIdentifier,
    String? region,
    bool? taxEnabled,
    String? taxLabel,
    double? taxRatePercent,
    bool? taxInclusive,
    bool? isActive,
    DateTime? createdAtUtc,
    DateTime? updatedAtUtc,
  }) {
    return CloudCompanyProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      shortDescription: shortDescription ?? this.shortDescription,
      timeZone: timeZone ?? this.timeZone,
      currencyCode: currencyCode ?? this.currencyCode,
      taxIdentifier: taxIdentifier ?? this.taxIdentifier,
      region: region ?? this.region,
      taxEnabled: taxEnabled ?? this.taxEnabled,
      taxLabel: taxLabel ?? this.taxLabel,
      taxRatePercent: taxRatePercent ?? this.taxRatePercent,
      taxInclusive: taxInclusive ?? this.taxInclusive,
      isActive: isActive ?? this.isActive,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
    );
  }

  factory CloudCompanyProfile.fromJson(Map<String, dynamic> json) {
    final rawTaxEnabled = json['taxEnabled'] ?? json['TaxEnabled'];
    final bool? taxEnabled = rawTaxEnabled == null
        ? null
        : (rawTaxEnabled is bool
            ? rawTaxEnabled
            : (rawTaxEnabled is num
                ? rawTaxEnabled != 0
                : rawTaxEnabled.toString().toLowerCase() == 'true' ||
                    rawTaxEnabled.toString() == '1'));

    final rawTaxInclusive = json['taxInclusive'] ?? json['TaxInclusive'];
    final bool? taxInclusive = rawTaxInclusive == null
        ? null
        : (rawTaxInclusive is bool
            ? rawTaxInclusive
            : (rawTaxInclusive is num
                ? rawTaxInclusive != 0
                : rawTaxInclusive.toString().toLowerCase() == 'true' ||
                    rawTaxInclusive.toString() == '1'));

    final rawTaxRate = json['taxRatePercent'] ?? json['TaxRatePercent'];
    final double? taxRatePercent = rawTaxRate == null
        ? null
        : (rawTaxRate is num
            ? rawTaxRate.toDouble()
            : double.tryParse(rawTaxRate.toString()));

    final taxLabel = (json['taxLabel'] ?? json['TaxLabel'])?.toString();

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
      taxEnabled: taxEnabled,
      taxLabel: taxLabel,
      taxRatePercent: taxRatePercent,
      taxInclusive: taxInclusive,
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
        if (taxEnabled != null) 'taxEnabled': taxEnabled,
        if (taxLabel != null) 'taxLabel': taxLabel,
        if (taxRatePercent != null) 'taxRatePercent': taxRatePercent,
        if (taxInclusive != null) 'taxInclusive': taxInclusive,
        'isActive': isActive,
        'createdAtUtc': createdAtUtc.toIso8601String(),
        'updatedAtUtc': updatedAtUtc?.toIso8601String(),
      };
}

/// Repository for fetching company profile from Cloud API
/// This is used only in Cloud Store mode to display company information
/// in Settings → Shop Details.
typedef CloudCompanyProfileSender = Future<dynamic> Function(
  String method,
  Uri uri, {
  Map<String, dynamic>? body,
});

class CloudCompanyProfileRepository {
  static const _cacheKey = 'cloud_company_profile';

  final FlutterSecureStorage _secureStorage;
  final CloudCompanyProfileSender? _sender;
  final http.Client? _client;

  CloudCompanyProfileRepository({
    FlutterSecureStorage? secureStorage,
    CloudCompanyProfileSender? sender,
    http.Client? client,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _sender = sender,
        _client = client;

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

    final client = _client ?? http.Client();
    final shouldClose = _client == null;
    try {
      if (accessToken.trim().isEmpty) {
        return null;
      }

      final response = await client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 20));

      final responseBody = response.body;

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
      return await getCachedProfile();
    } on Object catch (error, stackTrace) {
      debugPrint(
        '[SHOP-CLOUD-DIAGNOSTIC] EXCEPTION TYPE: ${error.runtimeType}',
      );
      debugPrint('[SHOP-CLOUD-DIAGNOSTIC] EXCEPTION: $error');
      debugPrint('[SHOP-CLOUD-DIAGNOSTIC] STACK TRACE: $stackTrace');

      // On error, return cached profile if available
      return await getCachedProfile();
    } finally {
      if (shouldClose) {
        client.close();
      }
    }
  }

  /// Updates the company profile via the Cloud API.
  /// Only non-null fields are sent, matching the backend's partial-update contract.
  /// Requires the caller to hold the CompanyAdmin role.
  Future<CloudCompanyProfile> updateCompanyProfile({
    required String baseUrl,
    required String accessToken,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? shortDescription,
    String? timeZone,
    String? currencyCode,
    String? taxIdentifier,
    String? region,
    bool? taxEnabled,
    String? taxLabel,
    double? taxRatePercent,
    bool? taxInclusive,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/mobile/company/profile');
    final override = _sender;
    if (override != null) {
      final json = await override('PUT', uri, body: {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (address != null) 'address': address,
        if (shortDescription != null) 'shortDescription': shortDescription,
        if (timeZone != null) 'timeZone': timeZone,
        if (currencyCode != null) 'currencyCode': currencyCode,
        if (taxIdentifier != null) 'taxIdentifier': taxIdentifier,
      });
      final data = json is Map<String, dynamic> ? json['data'] ?? json : json;
      var profile = CloudCompanyProfile.fromJson(data as Map<String, dynamic>);
      profile = profile.copyWith(
        region: region,
        taxEnabled: taxEnabled,
        taxLabel: taxLabel,
        taxRatePercent: taxRatePercent,
        taxInclusive: taxInclusive,
      );
      await _cacheProfile(profile);
      return profile;
    }

    final client = _client ?? http.Client();
    final shouldClose = _client == null;
    try {
      final response = await client.put(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
          if (email != null) 'email': email,
          if (address != null) 'address': address,
          if (shortDescription != null) 'shortDescription': shortDescription,
          if (timeZone != null) 'timeZone': timeZone,
          if (currencyCode != null) 'currencyCode': currencyCode,
          if (taxIdentifier != null) 'taxIdentifier': taxIdentifier,
        }),
      ).timeout(const Duration(seconds: 20));

      final responseBody = response.body;

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Cloud company profile update failed (HTTP ${response.statusCode}).');
      }

      final json = jsonDecode(responseBody);
      final data = json is Map<String, dynamic> ? json['data'] ?? json : json;
      var profile = CloudCompanyProfile.fromJson(data as Map<String, dynamic>);
      profile = profile.copyWith(
        region: region,
        taxEnabled: taxEnabled,
        taxLabel: taxLabel,
        taxRatePercent: taxRatePercent,
        taxInclusive: taxInclusive,
      );
      await _cacheProfile(profile);
      return profile;
    } finally {
      if (shouldClose) {
        client.close();
      }
    }
  }

  /// Directly saves / updates the cached company profile.
  Future<void> saveCachedProfile(CloudCompanyProfile profile) => _cacheProfile(profile);

  /// Gets the cached company profile from secure storage.
  /// Checks 'cloud_company_profile' first, and falls back to 'mobile_auth_company'
  /// saved during login/bootstrap.
  Future<CloudCompanyProfile?> getCachedProfile() async {
    try {
      final cached = await _secureStorage.read(key: _cacheKey);
      if (cached != null && cached.trim().isNotEmpty) {
        final json = jsonDecode(cached) as Map<String, dynamic>;
        return CloudCompanyProfile.fromJson(json);
      }

      final companyRaw = await _secureStorage.read(key: 'mobile_auth_company');
      if (companyRaw != null && companyRaw.trim().isNotEmpty) {
        final companyMap = jsonDecode(companyRaw) as Map<String, dynamic>;
        final name =
            (companyMap['name'] ?? companyMap['Name'] ?? '').toString().trim();
        if (name.isNotEmpty) {
          final id =
              (companyMap['id'] ?? companyMap['Id'] ?? '').toString().trim();
          final taxIdentifier =
              (companyMap['taxIdentifier'] ?? companyMap['TaxIdentifier'])
                  ?.toString()
                  .trim();
          final phone = (companyMap['phone'] ?? companyMap['Phone'])
              ?.toString()
              .trim();
          final email = (companyMap['email'] ?? companyMap['Email'])
              ?.toString()
              .trim();
          final address = (companyMap['address'] ?? companyMap['Address'])
              ?.toString()
              .trim();
          final timeZone =
              (companyMap['timeZone'] ?? companyMap['TimeZone'] ?? 'UTC')
                  .toString();
          final currencyCode = (companyMap['currency'] ??
                  companyMap['currencyCode'] ??
                  companyMap['CurrencyCode'] ??
                  'INR')
              .toString();
          final region =
              (companyMap['region'] ?? companyMap['Region'] ?? '').toString();

          return CloudCompanyProfile(
            id: id,
            name: name,
            email: email != null && email.isNotEmpty ? email : null,
            phone: phone != null && phone.isNotEmpty ? phone : null,
            address: address != null && address.isNotEmpty ? address : null,
            shortDescription: null,
            timeZone: timeZone,
            currencyCode: currencyCode,
            taxIdentifier: taxIdentifier != null && taxIdentifier.isNotEmpty
                ? taxIdentifier
                : null,
            region: region,
            isActive: true,
            createdAtUtc: DateTime.now(),
          );
        }
      }
      return null;
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

      // Keep mobile_auth_company in sync with updated company name and tax identifier
      final companyRaw = await _secureStorage.read(key: 'mobile_auth_company');
      if (companyRaw != null && companyRaw.trim().isNotEmpty) {
        final map = Map<String, dynamic>.from(
          jsonDecode(companyRaw) as Map<String, dynamic>,
        );
        map['name'] = profile.name;
        if (profile.taxIdentifier != null) {
          map['taxIdentifier'] = profile.taxIdentifier;
        }
        if (profile.phone != null) {
          map['phone'] = profile.phone;
        }
        if (profile.address != null) {
          map['address'] = profile.address;
        }
        if (profile.email != null) {
          map['email'] = profile.email;
        }
        await _secureStorage.write(
          key: 'mobile_auth_company',
          value: jsonEncode(map),
        );
      }
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
