import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MobileAuthServiceException implements Exception {
  const MobileAuthServiceException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

class MobileAuthService {
  MobileAuthService({
    FlutterSecureStorage? secureStorage,
    HttpClient? httpClient,
    String? baseUrl,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _httpClient = httpClient ?? HttpClient(),
        _baseUrl =
            (baseUrl ?? _defaultBaseUrl).replaceFirst(RegExp(r'/+$'), '');

  static const _defaultBaseUrl = String.fromEnvironment(
    'FLORAPRISE_API_URL',
    defaultValue: 'http://localhost:5148',
  );

  static const _accessTokenKey = 'mobile_auth_access_token';
  static const _refreshTokenKey = 'mobile_auth_refresh_token';
  static const _rememberLoginKey = 'mobile_auth_remember_login';
  static const _sessionKey = 'mobile_auth_session';
  static const _userKey = 'mobile_auth_user';
  static const _companyKey = 'mobile_auth_company';
  static const _subscriptionKey = 'mobile_auth_subscription';
  static const _permissionsKey = 'mobile_auth_permissions';
  static const _appConfigKey = 'mobile_auth_app_config';
  static const _featureFlagsKey = 'mobile_auth_feature_flags';
  static const _deviceFingerprintKey = 'mobile_auth_device_fingerprint';

  final FlutterSecureStorage _secureStorage;
  final HttpClient _httpClient;
  final String _baseUrl;

  Future<bool> hasRememberedSession() async {
    final remember = await _secureStorage.read(key: _rememberLoginKey);
    final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
    return remember == 'true' &&
        refreshToken != null &&
        refreshToken.trim().isNotEmpty;
  }

  Future<MobileAuthPayload> register({
    required String companyName,
    required String ownerName,
    required String mobile,
    required String address,
    required String city,
    required String email,
    required String password,
  }) async {
    final device = await _buildDevicePayload();
    final response = await _postJson('/api/v1/mobile/auth/register', {
      'companyName': companyName.trim(),
      'ownerName': ownerName.trim(),
      'address': address.trim(),
      'city': city.trim(),
      'mobile': mobile.trim(),
      'email': email.trim(),
      'password': password,
      'device': device,
    });

    return _parseAndPersistAuthPayload(response, rememberLogin: true);
  }

  Future<MobileAuthPayload> login({
    required String identifier,
    required String password,
    required bool rememberLogin,
  }) async {
    final device = await _buildDevicePayload();
    final response = await _postJson('/api/v1/mobile/auth/login', {
      'identifier': identifier.trim(),
      'password': password,
      'device': device,
    });

    return _parseAndPersistAuthPayload(response, rememberLogin: rememberLogin);
  }

  Future<MobileAuthPayload> refreshAndBootstrap() async {
    final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
    if (refreshToken == null || refreshToken.trim().isEmpty) {
      throw const MobileAuthServiceException(
        'missing_refresh_token',
        'No refresh token found.',
      );
    }

    final refreshResponse = await _postJson('/api/v1/mobile/auth/refresh', {
      'refreshToken': refreshToken,
    });

    final refreshData = _extractData(refreshResponse);
    final accessToken = _readString(refreshData, 'accessToken') ?? '';
    final newRefreshToken = _readString(refreshData, 'refreshToken') ?? '';
    if (accessToken.isEmpty || newRefreshToken.isEmpty) {
      throw const MobileAuthServiceException(
        'invalid_response',
        'Invalid refresh response.',
      );
    }

    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: newRefreshToken);

    final bootstrapResponse = await _getJson(
      '/api/v1/mobile/bootstrap',
      bearerToken: accessToken,
    );
    final bootstrapData = _extractData(bootstrapResponse);

    final userJson = _readMap(bootstrapData, 'user') ??
        jsonDecode(await _secureStorage.read(key: _userKey) ?? '{}')
            as Map<String, dynamic>;

    final payload = MobileAuthPayload(
      accessToken: accessToken,
      refreshToken: newRefreshToken,
      session: jsonDecode(await _secureStorage.read(key: _sessionKey) ?? '{}')
          as Map<String, dynamic>,
      user: userJson,
      bootstrap: bootstrapData,
    );

    await _persistProfileAndBootstrap(payload);
    return payload;
  }

  Future<void> logout() async {
    final accessToken = await _secureStorage.read(key: _accessTokenKey);

    if (accessToken != null && accessToken.trim().isNotEmpty) {
      try {
        await _postJson(
          '/api/v1/mobile/auth/logout',
          const {},
          bearerToken: accessToken,
        );
      } on Object {
        // Best effort logout call.
      }
    }

    await clearAuthState();
  }

  Future<void> clearAuthState() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _rememberLoginKey);
    await _secureStorage.delete(key: _sessionKey);
    await _secureStorage.delete(key: _userKey);
    await _secureStorage.delete(key: _companyKey);
    await _secureStorage.delete(key: _subscriptionKey);
    await _secureStorage.delete(key: _permissionsKey);
    await _secureStorage.delete(key: _appConfigKey);
    await _secureStorage.delete(key: _featureFlagsKey);
  }

  Future<Map<String, dynamic>?> readBootstrap() async {
    final user = await _secureStorage.read(key: _userKey);
    if (user == null || user.trim().isEmpty) return null;

    return {
      'user': jsonDecode(user),
      'company':
          jsonDecode(await _secureStorage.read(key: _companyKey) ?? 'null'),
      'subscription': jsonDecode(
        await _secureStorage.read(key: _subscriptionKey) ?? '{}',
      ),
      'permissions': jsonDecode(
        await _secureStorage.read(key: _permissionsKey) ?? '[]',
      ),
      'appConfig':
          jsonDecode(await _secureStorage.read(key: _appConfigKey) ?? '{}'),
      'featureFlags': jsonDecode(
        await _secureStorage.read(key: _featureFlagsKey) ?? '{}',
      ),
    };
  }

  Future<MobileAuthPayload> _parseAndPersistAuthPayload(
    Map<String, dynamic> response, {
    required bool rememberLogin,
  }) async {
    final data = _extractData(response);
    final accessToken = _readString(data, 'accessToken') ?? '';
    final refreshToken = _readString(data, 'refreshToken') ?? '';

    if (accessToken.isEmpty || refreshToken.isEmpty) {
      throw const MobileAuthServiceException(
        'invalid_response',
        'Authentication response is missing tokens.',
      );
    }

    final payload = MobileAuthPayload(
      accessToken: accessToken,
      refreshToken: refreshToken,
      session: _readMap(data, 'session') ?? <String, dynamic>{},
      user: _readMap(data, 'user') ?? <String, dynamic>{},
      bootstrap: _readMap(data, 'bootstrap') ?? <String, dynamic>{},
    );

    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    await _secureStorage.write(key: _rememberLoginKey, value: '$rememberLogin');
    await _secureStorage.write(
      key: _refreshTokenKey,
      value: rememberLogin ? refreshToken : '',
    );
    await _secureStorage.write(
      key: _sessionKey,
      value: jsonEncode(payload.session),
    );

    await _persistProfileAndBootstrap(payload);
    return payload;
  }

  Future<void> _persistProfileAndBootstrap(MobileAuthPayload payload) async {
    final bootstrap = payload.bootstrap;
    final company = _readMap(bootstrap, 'company');
    final subscription = _readMap(bootstrap, 'subscription') ?? {};
    final permissions = bootstrap['permissions'] ?? [];
    final appConfig = _readMap(bootstrap, 'appConfig') ?? {};
    final featureFlags = _readMap(bootstrap, 'featureFlags') ?? {};

    await _secureStorage.write(key: _userKey, value: jsonEncode(payload.user));
    await _secureStorage.write(key: _companyKey, value: jsonEncode(company));
    await _secureStorage.write(
      key: _subscriptionKey,
      value: jsonEncode(subscription),
    );
    await _secureStorage.write(
      key: _permissionsKey,
      value: jsonEncode(permissions),
    );
    await _secureStorage.write(
        key: _appConfigKey, value: jsonEncode(appConfig));
    await _secureStorage.write(
      key: _featureFlagsKey,
      value: jsonEncode(featureFlags),
    );
  }

  Future<Map<String, dynamic>> _buildDevicePayload() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final existingFingerprint =
        await _secureStorage.read(key: _deviceFingerprintKey);

    final fingerprint =
        (existingFingerprint == null || existingFingerprint.trim().isEmpty)
            ? _generateDeviceFingerprint()
            : existingFingerprint;

    if (existingFingerprint == null || existingFingerprint.trim().isEmpty) {
      await _secureStorage.write(
          key: _deviceFingerprintKey, value: fingerprint);
    }

    return {
      'deviceFingerprint': fingerprint,
      'deviceName': Platform.localHostname,
      'platform': _platformName(),
      'appVersion': '${packageInfo.version}+${packageInfo.buildNumber}',
      'osVersion': Platform.operatingSystemVersion,
      'pushToken': null,
    };
  }

  String _generateDeviceFingerprint() {
    final random = Random.secure();
    final bytes = List<int>.generate(24, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  String _platformName() {
    if (kIsWeb) return 'WEB';
    if (Platform.isAndroid) return 'ANDROID';
    if (Platform.isIOS) return 'IOS';
    if (Platform.isWindows) return 'WINDOWS';
    if (Platform.isMacOS) return 'MACOS';
    if (Platform.isLinux) return 'LINUX';
    return Platform.operatingSystem.toUpperCase();
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, Object?> body, {
    String? bearerToken,
  }) async {
    return _sendJson('POST', _uri(path), body: body, bearerToken: bearerToken);
  }

  Future<Map<String, dynamic>> _getJson(
    String path, {
    String? bearerToken,
  }) async {
    return _sendJson('GET', _uri(path), bearerToken: bearerToken);
  }

  Future<Map<String, dynamic>> _sendJson(
    String method,
    Uri uri, {
    Map<String, Object?>? body,
    String? bearerToken,
  }) async {
    try {
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

      final response =
          await request.close().timeout(const Duration(seconds: 20));
      final responseBody = await response.transform(utf8.decoder).join();
      final decoded = responseBody.trim().isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(responseBody) as Map<String, dynamic>);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = _extractError(decoded);
        throw MobileAuthServiceException(
          error.$1,
          error.$2,
        );
      }

      return decoded;
    } on SocketException {
      if (!kIsWeb && Platform.isAndroid) {
        final host = uri.host.toLowerCase();
        if (host == 'localhost' || host == '127.0.0.1') {
          throw const MobileAuthServiceException(
            'network_unavailable',
            'Cannot reach local API from Android. Start API and run adb reverse tcp:5000 tcp:5000, or set FLORAPRISE_API_URL to your PC LAN IP.',
          );
        }
      }

      throw const MobileAuthServiceException(
        'network_unavailable',
        'Network unavailable. Please check your internet connection.',
      );
    } on TimeoutException {
      throw const MobileAuthServiceException(
        'server_unavailable',
        'Server is taking too long to respond. Please try again.',
      );
    }
  }

  (String, String) _extractError(Map<String, dynamic> decoded) {
    final errorMap = _readMap(decoded, 'error');
    if (errorMap != null) {
      final code = _readString(errorMap, 'code') ?? 'request_failed';
      final message = _readString(errorMap, 'message') ??
          'Request failed. Please try again.';
      return (code, message);
    }

    return ('request_failed', 'Request failed. Please try again.');
  }

  Map<String, dynamic> _extractData(Map<String, dynamic> decoded) {
    final success = decoded['success'];
    if (success is bool && !success) {
      final error = _extractError(decoded);
      throw MobileAuthServiceException(error.$1, error.$2);
    }

    final data = decoded['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.cast<String, dynamic>();

    return decoded;
  }

  String? _readString(Map<String, dynamic> json, String key) {
    final value = json[key] ?? json[_pascalCase(key)];
    return value?.toString();
  }

  Map<String, dynamic>? _readMap(Map<String, dynamic> json, String key) {
    final value = json[key] ?? json[_pascalCase(key)];
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return null;
  }

  String _pascalCase(String key) {
    if (key.isEmpty) return key;
    return '${key[0].toUpperCase()}${key.substring(1)}';
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<List<Map<String, dynamic>>> getSubscriptionPlans() async {
    final decoded = await _getJson('/api/v1/mobile/subscription/plans');
    final data = _extractData(decoded);
    final plansData = data['plans'];

    if (plansData is List) {
      return plansData.cast<Map<String, dynamic>>();
    }

    return [];
  }

  Future<Map<String, dynamic>> createSubscriptionOrder(String planId) async {
    final decoded = await _postJson(
      '/api/v1/mobile/subscription/create-order',
      {'planId': planId},
    );
    return _extractData(decoded);
  }

  Future<Map<String, dynamic>> verifySubscriptionPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    required String planId,
  }) async {
    return _postJson(
      '/api/v1/mobile/subscription/verify-payment',
      {
        'orderId': orderId,
        'paymentId': paymentId,
        'signature': signature,
        'planId': planId,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    final decoded = await _getJson('/api/v1/mobile/subscription/payment-history');
    final data = _extractData(decoded);
    final paymentsData = data['payments'];

    if (paymentsData is List) {
      return paymentsData.cast<Map<String, dynamic>>();
    }

    return [];
  }
}

class MobileAuthPayload {
  MobileAuthPayload({
    required this.accessToken,
    required this.refreshToken,
    required this.session,
    required this.user,
    required this.bootstrap,
  });

  final String accessToken;
  final String refreshToken;
  final Map<String, dynamic> session;
  final Map<String, dynamic> user;
  final Map<String, dynamic> bootstrap;
}

