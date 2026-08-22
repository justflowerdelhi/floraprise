import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_base_url.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/license.dart';

class LicenseServiceException implements Exception {
  const LicenseServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LicenseService {
  LicenseService({
    FlutterSecureStorage? secureStorage,
    HttpClient? httpClient,
    String? baseUrl,
    DateTime Function()? now,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _httpClient = httpClient ?? HttpClient(),
        _baseUrl = _computeBaseUrl(baseUrl),
        _now = now ?? DateTime.now;

  static String _computeBaseUrl(String? baseUrl) {
    final configured = (baseUrl ?? _defaultBaseUrl).replaceFirst(
      RegExp(r'/+$'),
      '',
    );
    if (configured.isNotEmpty) return configured;
    return resolveFlorapriseApiBaseUrl(
      explicitValue: '',
      isDebug: kDebugMode,
      platform: defaultTargetPlatform,
    );
  }

  static const _defaultBaseUrl = String.fromEnvironment(
    'FLORAPRISE_API_URL',
    defaultValue: '',
  );
  static const _offlineGrace = Duration(days: 7);

  static const _customerIdKey = 'cloud_license_customer_id';
  static const _deviceIdKey = 'cloud_license_device_id';
  static const _statusKey = 'cloud_license_status';
  static const _planKey = 'cloud_license_plan';
  static const _expiryKey = 'cloud_license_expiry';
  static const _remainingDaysKey = 'cloud_license_remaining_days';
  static const _lastVerifiedKey = 'cloud_license_last_verified_at';
  static const _accessTokenKey = 'mobile_auth_access_token';
  static const _authDeviceIdKey = 'mobile_auth_device_fingerprint';

  final FlutterSecureStorage _secureStorage;
  final HttpClient _httpClient;
  late final String _baseUrl;
  final DateTime Function() _now;

  Future<bool> get isRegistered async {
    final accessToken = await _secureStorage.read(key: _accessTokenKey);
    return accessToken != null && accessToken.trim().isNotEmpty;
  }

  Future<String> getDeviceId() async {
    final authDeviceId = await _secureStorage.read(key: _authDeviceIdKey);
    if (authDeviceId != null && authDeviceId.trim().isNotEmpty) {
      await _secureStorage.write(key: _deviceIdKey, value: authDeviceId.trim());
      return authDeviceId.trim();
    }

    final existing = await _secureStorage.read(key: _deviceIdKey);
    if (existing != null && existing.trim().isNotEmpty) return existing;

    final random = Random.secure();
    final bytes = List<int>.generate(18, (_) => random.nextInt(256));
    final generated = 'fp-${base64Url.encode(bytes).replaceAll('=', '')}';
    await _secureStorage.write(key: _deviceIdKey, value: generated);
    return generated;
  }

  Future<CloudLicenseCheckResult> register(
    BusinessRegistrationInput input,
  ) async {
    final accessToken = await _secureStorage.read(key: _accessTokenKey);
    if (accessToken != null && accessToken.trim().isNotEmpty) {
      await getDeviceId();
      return checkLicense();
    }

    final deviceId = await getDeviceId();
    final appVersion = await _appVersion();
    final payload = <String, Object?>{
      'businessName': input.businessName.trim(),
      'ownerName': input.ownerName.trim(),
      'mobile': input.mobile.trim(),
      'email': input.email?.trim(),
      'city': input.city?.trim(),
      'state': null,
      'country': 'India',
      'deviceId': deviceId,
      'platform': _platformName(),
      'model': Platform.localHostname,
      'androidVersion': Platform.operatingSystemVersion,
      'appVersion': appVersion,
    };

    final response = await _postJson('/api/license/register', payload);
    final data = _extractData(response);
    final customerId = _readString(data, 'customerId') ?? '';
    final status = CloudLicenseStatusLabel.fromApi(
      _readString(data, 'licenseStatus') ?? _readString(data, 'status'),
    );
    final trialExpiry = DateTime.tryParse(
      _readString(data, 'trialExpiry') ??
          _readString(data, 'trialExpiryUtc') ??
          '',
    );
    final remainingDays = _readInt(data, 'remainingDays') ?? 0;

    final result = CloudLicenseCheckResult(
      customerId: customerId.isEmpty ? null : customerId,
      deviceId: deviceId,
      status: status,
      plan: CloudLicensePlan.trial,
      expiry: trialExpiry,
      remainingDays: remainingDays,
      isOfflineGrace: false,
      message: 'Cloud license registration completed.',
    );

    await _saveResult(
      result,
      customerId: result.customerId,
      deviceId: deviceId,
    );

    return result;
  }

  Future<CloudLicenseCheckResult> checkLicense() async {
    final accessToken = await _secureStorage.read(key: _accessTokenKey);
    final deviceId = await _secureStorage.read(key: _deviceIdKey);
    if (accessToken == null ||
        accessToken.trim().isEmpty ||
        deviceId == null ||
        deviceId.trim().isEmpty) {
      final storedRecord = await _loadStoredRecord();
      if (storedRecord != null) {
        return _offlineResult();
      }
      return const CloudLicenseCheckResult.unregistered();
    }

    try {
      final json = await _getJson(
        '/api/v1/mobile/license/status',
        bearerToken: accessToken,
      );
      final result = _resultFromJson(json, deviceId: deviceId);
      await _saveResult(result,
          customerId: result.customerId, deviceId: deviceId);
      return result;
    } on SocketException {
      return _offlineResult();
    } on TimeoutException {
      return _offlineResult();
    }
  }

  Future<void> heartbeat() async {
    final accessToken = await _secureStorage.read(key: _accessTokenKey);
    final deviceId = await _secureStorage.read(key: _deviceIdKey);
    if (accessToken == null || accessToken.trim().isEmpty || deviceId == null) {
      return;
    }

    try {
      await _postJson(
          '/api/v1/mobile/auth/heartbeat',
          {
            'deviceId': deviceId,
            'appVersion': await _appVersion(),
            'lastSyncUtc': _now().toUtc().toIso8601String(),
            'ipAddress': null,
          },
          bearerToken: accessToken);
    } on Object catch (error, stackTrace) {
      debugPrint('License heartbeat failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<CloudLicenseCheckResult> _offlineResult() async {
    final record = await _loadStoredRecord();
    if (record == null || !record.allowsAccess) {
      return const CloudLicenseCheckResult.internetRequired(
        message: 'Internet required to verify license.',
      );
    }
    if (_now().difference(record.lastVerifiedAt) > _offlineGrace) {
      return const CloudLicenseCheckResult.internetRequired(
        message: 'Internet required to verify license.',
      );
    }
    return CloudLicenseCheckResult(
      customerId: record.customerId,
      deviceId: record.deviceId,
      status: record.status,
      plan: record.plan,
      expiry: record.expiry,
      remainingDays: record.remainingDays,
      isOfflineGrace: true,
      message: 'Using last verified license. Please connect within 7 days.',
    );
  }

  Future<CloudLicenseRecord?> _loadStoredRecord() async {
    final customerId = await _secureStorage.read(key: _customerIdKey);
    final deviceId = await _secureStorage.read(key: _deviceIdKey);
    final status = await _secureStorage.read(key: _statusKey);
    final plan = await _secureStorage.read(key: _planKey);
    final lastVerified = await _secureStorage.read(key: _lastVerifiedKey);
    if (customerId == null || deviceId == null || lastVerified == null) {
      return null;
    }

    return CloudLicenseRecord(
      customerId: customerId,
      deviceId: deviceId,
      status: CloudLicenseStatusLabel.fromApi(status),
      plan: CloudLicensePlanLabel.fromApi(plan),
      expiry:
          DateTime.tryParse(await _secureStorage.read(key: _expiryKey) ?? ''),
      remainingDays: int.tryParse(
            await _secureStorage.read(key: _remainingDaysKey) ?? '',
          ) ??
          0,
      lastVerifiedAt: DateTime.tryParse(lastVerified) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Future<void> _saveResult(
    CloudLicenseCheckResult result, {
    required String? customerId,
    required String deviceId,
  }) async {
    final resolvedCustomerId = customerId ?? result.customerId;
    if (resolvedCustomerId == null || resolvedCustomerId.trim().isEmpty) return;

    await _secureStorage.write(key: _customerIdKey, value: resolvedCustomerId);
    await _secureStorage.write(key: _deviceIdKey, value: deviceId);
    await _secureStorage.write(key: _statusKey, value: result.status.label);
    await _secureStorage.write(key: _planKey, value: result.plan.label);
    await _secureStorage.write(
      key: _expiryKey,
      value: result.expiry?.toIso8601String() ?? '',
    );
    await _secureStorage.write(
      key: _remainingDaysKey,
      value: result.remainingDays.toString(),
    );
    await _secureStorage.write(
      key: _lastVerifiedKey,
      value: _now().toIso8601String(),
    );
  }

  CloudLicenseCheckResult _resultFromJson(
    Map<String, Object?> json, {
    String? customerId,
    required String deviceId,
  }) {
    final data = _extractData(json);
    final resolvedCustomerId = _readString(data, 'mobileUserId') ??
        _readString(data, 'customerId') ??
        customerId;

    final subscriptionStatus =
        (_readString(data, 'subscriptionStatus') ?? '').trim().toUpperCase();
    final trialLike = subscriptionStatus == 'TRIAL';
    final statusLabel = trialLike
        ? 'trial'
        : (_readString(data, 'licenseStatus') ?? _readString(data, 'status'));

    return CloudLicenseCheckResult(
      customerId: resolvedCustomerId,
      deviceId: deviceId,
      status: CloudLicenseStatusLabel.fromApi(
        statusLabel,
      ),
      plan: CloudLicensePlanLabel.fromApi(
        _readString(data, 'planCode') ?? _readString(data, 'plan'),
      ),
      expiry: DateTime.tryParse(
        _readString(data, 'expiryUtc') ?? _readString(data, 'expiry') ?? '',
      ),
      remainingDays: _readInt(data, 'remainingDays') ?? 0,
      isOfflineGrace: false,
    );
  }

  Future<Map<String, Object?>> _postJson(
    String path,
    Map<String, Object?> body, {
    String? bearerToken,
  }) {
    return _sendJson('POST', _uri(path), body: body, bearerToken: bearerToken);
  }

  Future<Map<String, Object?>> _getJson(
    String path, {
    String? bearerToken,
  }) {
    return _sendJson('GET', _uri(path), bearerToken: bearerToken);
  }

  Future<Map<String, Object?>> _sendJson(
    String method,
    Uri uri, {
    Map<String, Object?>? body,
    String? bearerToken,
  }) async {
    final request = await _httpClient.openUrl(method, uri).timeout(
          const Duration(seconds: 12),
        );
    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
    if (bearerToken != null && bearerToken.trim().isNotEmpty) {
      request.headers
          .set(HttpHeaders.authorizationHeader, 'Bearer $bearerToken');
    }
    if (body != null) {
      request.write(jsonEncode(body));
    }

    final response = await request.close().timeout(const Duration(seconds: 20));
    final responseBody = await response.transform(utf8.decoder).join();

    // Log request/response details for debugging
    final contentType = response.headers.contentType?.mimeType ?? 'unknown';
    final bodyPreview = responseBody.length > 500
        ? '${responseBody.substring(0, 500)}...'
        : responseBody;
    debugPrint('[LicenseService] $method $uri');
    debugPrint('[LicenseService] Status: ${response.statusCode}');
    debugPrint('[LicenseService] Content-Type: $contentType');
    debugPrint('[LicenseService] Response body preview: $bodyPreview');

    // Check if Content-Type is JSON before attempting to parse
    if (!contentType.contains('application/json') &&
        !contentType.contains('text/json') &&
        responseBody.trim().isNotEmpty) {
      throw LicenseServiceException(
        'Server returned non-JSON response (Content-Type: $contentType). URL: $uri, Status: ${response.statusCode}. Response: $bodyPreview',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final parsed = _tryParseJsonObject(responseBody);
      if (parsed != null) {
        final detail = _readString(parsed, 'detail');
        final title = _readString(parsed, 'title');
        throw LicenseServiceException(
          (detail ??
                  title ??
                  'License server returned HTTP ${response.statusCode}.')
              .trim(),
        );
      }

      throw LicenseServiceException(
        _buildHttpErrorMessage(response.statusCode, responseBody),
      );
    }

    if (responseBody.trim().isEmpty) {
      return <String, Object?>{};
    }

    final decoded = _tryParseJsonObject(responseBody);
    if (decoded == null) {
      throw LicenseServiceException(
        _buildHttpErrorMessage(response.statusCode, responseBody),
      );
    }

    return decoded;
  }

  String _buildHttpErrorMessage(int statusCode, String responseBody) {
    final trimmed = responseBody.trim();
    if (trimmed.isEmpty) {
      return 'License server returned HTTP $statusCode.';
    }

    if (trimmed.startsWith('<!DOCTYPE') || trimmed.startsWith('<html')) {
      return 'License server returned HTML (HTTP $statusCode) instead of JSON. This usually means wrong API route or outdated deployment.';
    }

    final compact = trimmed.replaceAll(RegExp(r'\s+'), ' ');
    final preview =
        compact.length > 180 ? '${compact.substring(0, 180)}...' : compact;
    return 'License server returned HTTP $statusCode: $preview';
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  String _platformName() {
    if (kIsWeb) return 'WEB';
    if (Platform.isAndroid) return 'ANDROID';
    if (Platform.isIOS) return 'IOS';
    if (Platform.isWindows) return 'WINDOWS';
    if (Platform.isMacOS) return 'MACOS';
    if (Platform.isLinux) return 'LINUX';
    return Platform.operatingSystem.toUpperCase();
  }

  Future<String> _appVersion() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version}+${info.buildNumber}';
  }

  String? _readString(Map<String, Object?> json, String key) {
    final value = json[key] ?? json[_pascalCase(key)];
    return value?.toString();
  }

  int? _readInt(Map<String, Object?> json, String key) {
    final value = json[key] ?? json[_pascalCase(key)];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  String _pascalCase(String key) {
    if (key.isEmpty) return key;
    return '${key[0].toUpperCase()}${key.substring(1)}';
  }

  Map<String, Object?> _extractData(Map<String, Object?> decoded) {
    final data = decoded['data'];
    if (data is Map<String, Object?>) return data;
    if (data is Map) return data.cast<String, Object?>();
    return decoded;
  }

  Map<String, Object?>? _tryParseJsonObject(String responseBody) {
    final trimmed = responseBody.trim();
    if (trimmed.isEmpty) return <String, Object?>{};
    if (!trimmed.startsWith('{')) return null;

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, Object?>) return decoded;
      if (decoded is Map) return decoded.cast<String, Object?>();
      return null;
    } on FormatException {
      return null;
    }
  }
}
