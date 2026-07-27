import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
        _baseUrl =
            (baseUrl ?? _defaultBaseUrl).replaceFirst(RegExp(r'/+$'), ''),
        _now = now ?? DateTime.now;

  static const _defaultBaseUrl = String.fromEnvironment(
    'FLORAPRISE_LICENSE_API_URL',
    defaultValue: 'https://license.floraprise.com',
  );
  static const _offlineGrace = Duration(days: 7);

  static const _customerIdKey = 'cloud_license_customer_id';
  static const _deviceIdKey = 'cloud_license_device_id';
  static const _statusKey = 'cloud_license_status';
  static const _planKey = 'cloud_license_plan';
  static const _expiryKey = 'cloud_license_expiry';
  static const _remainingDaysKey = 'cloud_license_remaining_days';
  static const _lastVerifiedKey = 'cloud_license_last_verified_at';

  final FlutterSecureStorage _secureStorage;
  final HttpClient _httpClient;
  final String _baseUrl;
  final DateTime Function() _now;

  Future<bool> get isRegistered async {
    final customerId = await _secureStorage.read(key: _customerIdKey);
    return customerId != null && customerId.trim().isNotEmpty;
  }

  Future<String> getDeviceId() async {
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
    final deviceId = await getDeviceId();
    final appVersion = await _appVersion();
    final body = <String, Object?>{
      'businessName': input.businessName.trim(),
      'ownerName': input.ownerName.trim(),
      'mobile': input.mobile.trim(),
      'email': input.email?.trim(),
      'deviceId': deviceId,
      'platform': _platformName(),
      'model': _deviceModel(),
      'androidVersion': _androidVersion(),
      'appVersion': appVersion,
    };
    final city = input.city?.trim();
    if (city != null && city.isNotEmpty) {
      body['city'] = city;
    }

    final json = await _postJson('/api/license/register', body);
    final result = _resultFromJson(json, deviceId: deviceId);
    await _saveResult(result,
        customerId: result.customerId, deviceId: deviceId);
    return result;
  }

  Future<CloudLicenseCheckResult> checkLicense() async {
    final customerId = await _secureStorage.read(key: _customerIdKey);
    final deviceId = await _secureStorage.read(key: _deviceIdKey);
    if (customerId == null || customerId.trim().isEmpty) {
      return const CloudLicenseCheckResult.unregistered();
    }
    if (deviceId == null || deviceId.trim().isEmpty) {
      return const CloudLicenseCheckResult.unregistered();
    }

    try {
      final uri = _uri('/api/license/check').replace(queryParameters: {
        'customerId': customerId,
        'deviceId': deviceId,
      });
      final json = await _sendJson('GET', uri);
      final result =
          _resultFromJson(json, customerId: customerId, deviceId: deviceId);
      await _saveResult(result, customerId: customerId, deviceId: deviceId);
      return result;
    } on SocketException {
      return _offlineResult();
    } on TimeoutException {
      return _offlineResult();
    }
  }

  Future<void> heartbeat() async {
    final customerId = await _secureStorage.read(key: _customerIdKey);
    final deviceId = await _secureStorage.read(key: _deviceIdKey);
    if (customerId == null || deviceId == null) return;

    try {
      await _postJson('/api/license/heartbeat', {
        'customerId': customerId,
        'deviceId': deviceId,
        'appVersion': await _appVersion(),
      });
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
    final resolvedCustomerId = _readString(json, 'customerId') ?? customerId;
    return CloudLicenseCheckResult(
      customerId: resolvedCustomerId,
      deviceId: deviceId,
      status: CloudLicenseStatusLabel.fromApi(
        _readString(json, 'licenseStatus') ?? _readString(json, 'status'),
      ),
      plan: CloudLicensePlanLabel.fromApi(_readString(json, 'plan')),
      expiry: DateTime.tryParse(
        _readString(json, 'trialExpiry') ?? _readString(json, 'expiry') ?? '',
      ),
      remainingDays: _readInt(json, 'remainingDays') ?? 0,
      isOfflineGrace: false,
    );
  }

  Future<Map<String, Object?>> _postJson(
    String path,
    Map<String, Object?> body,
  ) {
    return _sendJson('POST', _uri(path), body: body);
  }

  Future<Map<String, Object?>> _sendJson(
    String method,
    Uri uri, {
    Map<String, Object?>? body,
  }) async {
    final request = await _httpClient.openUrl(method, uri).timeout(
          const Duration(seconds: 12),
        );
    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
    if (body != null) {
      request.write(jsonEncode(body));
    }

    final response = await request.close().timeout(const Duration(seconds: 20));
    final responseBody = await response.transform(utf8.decoder).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw LicenseServiceException(
        responseBody.trim().isEmpty
            ? 'License server returned ${response.statusCode}.'
            : responseBody,
      );
    }
    final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
    return decoded.cast<String, Object?>();
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<String> _appVersion() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version}+${info.buildNumber}';
  }

  String _platformName() {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return Platform.operatingSystem;
  }

  String _deviceModel() => Platform.localHostname;

  String? _androidVersion() {
    if (!Platform.isAndroid) return null;
    return Platform.operatingSystemVersion;
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
}
