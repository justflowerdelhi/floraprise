import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_base_url.dart';
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
        _baseUrl = _computeBaseUrl(baseUrl);

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
  static const _defaultCompanyId = String.fromEnvironment(
    'FLORAPRISE_COMPANY_ID',
    defaultValue: '',
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
  late final String _baseUrl;

  String get baseUrl => _baseUrl;

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
      'mobile': mobile.trim(),
      'address': address.trim(),
      'city': city.trim(),
      'email': email.trim(),
      'password': password,
      'deviceId': device['deviceId'],
      'platform': device['platform'],
      'manufacturer': device['manufacturer'],
      'model': device['model'],
      'osVersion': device['osVersion'],
      'appVersion': device['appVersion'],
      'pushToken': device['pushToken'],
      'ipAddress': device['ipAddress'],
    });

    return _parseAndPersistAuthPayload(response, rememberLogin: true);
  }

  Future<MobileAuthPayload> login({
    required String identifier,
    required String password,
    required bool rememberLogin,
  }) async {
    final companyId = await _resolveCompanyId();
    final device = await _buildDevicePayload();
    final response = await _postJson('/api/v1/mobile/auth/login', {
      'companyId': companyId,
      'identifier': identifier.trim(),
      'password': password,
      'deviceId': device['deviceId'],
      'platform': device['platform'],
      'manufacturer': device['manufacturer'],
      'model': device['model'],
      'osVersion': device['osVersion'],
      'appVersion': device['appVersion'],
      'pushToken': device['pushToken'],
      'ipAddress': device['ipAddress'],
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

    final normalizedBootstrap = _normalizeBootstrapPayload(bootstrapData);

    final payload = MobileAuthPayload(
      accessToken: accessToken,
      refreshToken: newRefreshToken,
      session: jsonDecode(await _secureStorage.read(key: _sessionKey) ?? '{}')
          as Map<String, dynamic>,
      user: userJson,
      bootstrap: normalizedBootstrap,
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

  /// Returns the stored access token without triggering a network refresh.
  Future<String?> getStoredAccessToken() =>
      _secureStorage.read(key: _accessTokenKey);

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
        await _secureStorage.read(key: _featureFlagsKey) ?? '[]',
      ),
    };
  }

  Future<List<Map<String, dynamic>>> getSubscriptionPlans() async {
    final token = await _secureStorage.read(key: _accessTokenKey);
    final decoded = await _getJson(
      '/api/v1/mobile/subscription/plans',
      bearerToken: token,
    );
    final rawData = decoded['data'];

    // Plans endpoint may return either data: [] or data: { items: [] }.
    if (rawData is List) {
      return _listOfMaps(rawData);
    }

    if (rawData is Map<String, dynamic>) {
      final items = rawData['items'];
      if (items is List) {
        return _listOfMaps(items);
      }
    }

    return [];
  }

  Future<Map<String, dynamic>> getCurrentSubscription() async {
    final token = await _secureStorage.read(key: _accessTokenKey);
    if (token == null || token.trim().isEmpty) {
      throw const MobileAuthServiceException(
        'missing_token',
        'A registered device session is required before loading subscription details.',
      );
    }

    final decoded = await _getJson(
      '/api/v1/mobile/subscription/current',
      bearerToken: token,
    );
    return _extractData(decoded);
  }

  Future<Map<String, dynamic>> createSubscriptionOrder(
    String planId, {
    String billingCycle = 'annual',
  }) async {
    final token = await _secureStorage.read(key: _accessTokenKey);
    if (token == null || token.trim().isEmpty) {
      throw const MobileAuthServiceException(
        'missing_token',
        'A registered device session is required before creating a subscription order.',
      );
    }

    final current = await getCurrentSubscription();
    final subscriptionId = (current['subscriptionId'] ?? '').toString();
    if (subscriptionId.isEmpty) {
      throw const MobileAuthServiceException(
        'subscription_missing',
        'Current subscription was not found.',
      );
    }

    final plans = await getSubscriptionPlans();
    final plan = plans.firstWhere(
      (p) => (p['id'] ?? '').toString() == planId,
      orElse: () => <String, dynamic>{},
    );

    if (plan.isEmpty) {
      throw const MobileAuthServiceException(
        'plan_not_found',
        'Selected subscription plan was not found.',
      );
    }

    final annualPrice = _toDouble(plan['annualPrice']);
    final monthlyPrice = _toDouble(plan['monthlyPrice']);
    final amount = annualPrice > 0 ? annualPrice : monthlyPrice;
    if (amount <= 0) {
      throw const MobileAuthServiceException(
        'invalid_plan_amount',
        'Selected plan has no payable amount.',
      );
    }

    final decoded = await _postJson(
      '/api/v1/mobile/payment/subscription-order',
      {
        'gateway': 1,
        'subscriptionId': subscriptionId,
        'amount': amount,
        'currency': ((plan['currency'] ?? 'INR').toString()).toUpperCase(),
        'planCode': (plan['code'] ?? '').toString(),
        'billingCycle': billingCycle,
        'returnUrl': null,
      },
      bearerToken: token,
    );
    final data = _extractData(decoded);
    if (!data.containsKey('transactionRef') &&
        decoded['transactionRef'] != null) {
      data['transactionRef'] = decoded['transactionRef'];
    }
    if (!data.containsKey('gatewayOrderId') &&
        decoded['gatewayOrderId'] != null) {
      data['gatewayOrderId'] = decoded['gatewayOrderId'];
    }
    if (!data.containsKey('clientPayload') &&
        decoded['clientPayload'] != null) {
      data['clientPayload'] = decoded['clientPayload'];
    }
    return data;
  }

  Future<Map<String, dynamic>> verifySubscriptionPayment({
    required String transactionRef,
    required String gatewayOrderId,
    required String paymentId,
    required String signature,
    required String planCode,
    required String billingCycle,
  }) async {
    final token = await _secureStorage.read(key: _accessTokenKey);
    if (token == null || token.trim().isEmpty) {
      throw const MobileAuthServiceException(
        'missing_token',
        'A registered device session is required before verifying payment.',
      );
    }

    return _postJson(
      '/api/v1/mobile/payment/verify',
      {
        'gateway': 1,
        'transactionRef': transactionRef,
        'gatewayOrderId': gatewayOrderId,
        'gatewayPaymentId': paymentId,
        'signature': signature,
        'planCode': planCode,
        'billingCycle': billingCycle,
      },
      bearerToken: token,
    );
  }

  Future<Map<String, dynamic>> renewSubscription({
    String billingCycle = 'annual',
    bool autoRenew = true,
  }) async {
    final token = await _secureStorage.read(key: _accessTokenKey);
    if (token == null || token.trim().isEmpty) {
      throw const MobileAuthServiceException(
        'missing_token',
        'A registered device session is required before renewing subscription.',
      );
    }

    final decoded = await _postJson(
      '/api/v1/mobile/subscription/renew',
      {
        'billingCycle': billingCycle,
        'autoRenew': autoRenew,
      },
      bearerToken: token,
    );
    return _extractData(decoded);
  }

  Future<Map<String, dynamic>> upgradeSubscription({
    required String planId,
    String billingCycle = 'annual',
  }) async {
    final token = await _secureStorage.read(key: _accessTokenKey);
    if (token == null || token.trim().isEmpty) {
      throw const MobileAuthServiceException(
        'missing_token',
        'A registered device session is required before upgrading subscription.',
      );
    }

    final decoded = await _postJson(
      '/api/v1/mobile/subscription/upgrade',
      {
        'planId': planId,
        'billingCycle': billingCycle,
      },
      bearerToken: token,
    );
    return _extractData(decoded);
  }

  Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    final token = await _secureStorage.read(key: _accessTokenKey);
    final decoded = await _getJson(
      '/api/v1/mobile/payment/history',
      bearerToken: token,
    );
    final data = _extractData(decoded);

    final paymentsData = data['payments'] ?? data['items'] ?? data['data'];

    if (paymentsData is List) {
      return _listOfMaps(paymentsData);
    }

    if (paymentsData is Map<String, dynamic>) {
      final items = paymentsData['items'];
      if (items is List) {
        return _listOfMaps(items);
      }
    }

    return [];
  }

  Future<Map<String, dynamic>> getLicenseStatus() async {
    final token = await _secureStorage.read(key: _accessTokenKey);
    if (token == null || token.trim().isEmpty) {
      throw const MobileAuthServiceException(
        'missing_token',
        'A registered device session is required before checking license status.',
      );
    }

    final decoded = await _getJson(
      '/api/v1/mobile/license/status',
      bearerToken: token,
    );
    return _extractData(decoded);
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

    final bootstrapData = _readMap(data, 'bootstrap') ?? <String, dynamic>{};
    final payload = MobileAuthPayload(
      accessToken: accessToken,
      refreshToken: refreshToken,
      session: _readMap(data, 'session') ?? <String, dynamic>{},
      user: _readMap(data, 'user') ?? <String, dynamic>{},
      bootstrap: _normalizeBootstrapPayload(bootstrapData),
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
    final appConfig = _readMap(bootstrap, 'appConfig') ??
        {
          'appVersion': _readString(bootstrap, 'appVersion') ?? '',
          'minimumSupportedVersion':
              _readString(bootstrap, 'minimumSupportedVersion') ?? '',
          'forceUpdate': bootstrap['forceUpdate'] == true,
        };
    final featureFlags =
        bootstrap['featureFlags'] ?? bootstrap['featureEntitlements'] ?? [];

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

  Map<String, dynamic> _normalizeBootstrapPayload(
      Map<String, dynamic> bootstrap) {
    final normalized = Map<String, dynamic>.from(bootstrap);
    final company = _readMap(bootstrap, 'company');
    if (company != null) {
      normalized['company'] = company;
    }

    final subscription = _readMap(bootstrap, 'subscription');
    if (subscription != null) {
      normalized['subscription'] = subscription;
    }

    final trial = _readMap(bootstrap, 'trial');
    if (trial != null) {
      normalized['trial'] = trial;
    }

    final license = _readMap(bootstrap, 'license');
    if (license != null) {
      normalized['license'] = license;
    }

    final appConfig = _readMap(bootstrap, 'appConfig');
    if (appConfig != null) {
      normalized['appConfig'] = appConfig;
    }

    if (!normalized.containsKey('permissions') &&
        bootstrap.containsKey('permissions')) {
      normalized['permissions'] = bootstrap['permissions'];
    }
    if (!normalized.containsKey('featureFlags')) {
      if (bootstrap.containsKey('featureFlags')) {
        normalized['featureFlags'] = bootstrap['featureFlags'];
      } else if (bootstrap.containsKey('featureEntitlements')) {
        normalized['featureFlags'] = bootstrap['featureEntitlements'];
      }
    }
    if (!normalized.containsKey('language')) {
      normalized['language'] = _readString(bootstrap, 'language') ?? 'en';
    }
    if (!normalized.containsKey('theme')) {
      normalized['theme'] = _readString(bootstrap, 'theme') ?? 'light';
    }
    if (!normalized.containsKey('appVersion')) {
      normalized['appVersion'] = _readString(bootstrap, 'appVersion') ?? '';
    }
    if (!normalized.containsKey('minimumSupportedVersion')) {
      normalized['minimumSupportedVersion'] =
          _readString(bootstrap, 'minimumSupportedVersion') ?? '';
    }
    if (!normalized.containsKey('forceUpdate')) {
      normalized['forceUpdate'] = bootstrap['forceUpdate'] == true;
    }

    return normalized;
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
      'deviceId': fingerprint,
      'platform': _platformName(),
      'manufacturer': kIsWeb ? 'Web' : Platform.operatingSystem,
      'model': Platform.localHostname,
      'osVersion': Platform.operatingSystemVersion,
      'appVersion': '${packageInfo.version}+${packageInfo.buildNumber}',
      'pushToken': null,
      'ipAddress': null,
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

      // Log request/response details for debugging
      final contentType = response.headers.contentType?.mimeType ?? 'unknown';
      final bodyPreview = responseBody.length > 500
          ? '${responseBody.substring(0, 500)}...'
          : responseBody;
      debugPrint('[API] $method $uri');
      debugPrint('[API] Status: ${response.statusCode}');
      debugPrint('[API] Content-Type: $contentType');
      debugPrint('[API] Response body preview: $bodyPreview');

      // Check if Content-Type is JSON before attempting to parse
      if (!contentType.contains('application/json') &&
          !contentType.contains('text/json') &&
          responseBody.trim().isNotEmpty) {
        throw MobileAuthServiceException(
          'invalid_content_type',
          'Server returned non-JSON response (Content-Type: $contentType). URL: $uri, Status: ${response.statusCode}. Response: $bodyPreview',
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final parsed = _tryParseJsonObject(responseBody);
        if (parsed != null) {
          final error = _extractError(parsed);
          throw MobileAuthServiceException(error.$1, error.$2);
        }

        throw MobileAuthServiceException(
          'request_failed',
          _buildHttpErrorMessage(response.statusCode, responseBody),
        );
      }

      if (responseBody.trim().isEmpty) {
        return <String, dynamic>{};
      }

      final decoded = _tryParseJsonObject(responseBody);
      if (decoded == null) {
        throw const MobileAuthServiceException(
          'invalid_response',
          'Server returned a non-JSON response. Please verify API URL and server deployment.',
        );
      }

      return decoded;
    } on SocketException {
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

  Map<String, dynamic>? _tryParseJsonObject(String responseBody) {
    final trimmed = responseBody.trim();
    if (trimmed.isEmpty) return <String, dynamic>{};
    if (!trimmed.startsWith('{')) return null;

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return decoded.cast<String, dynamic>();
      return null;
    } on FormatException {
      return null;
    }
  }

  String _buildHttpErrorMessage(int statusCode, String responseBody) {
    final trimmed = responseBody.trim();
    if (trimmed.isEmpty) {
      return 'Server returned HTTP $statusCode.';
    }

    if (trimmed.startsWith('<!DOCTYPE') || trimmed.startsWith('<html')) {
      return 'Server returned HTML (HTTP $statusCode) instead of JSON. This usually means wrong API route or outdated deployment.';
    }

    final compact = trimmed.replaceAll(RegExp(r'\s+'), ' ');
    final preview =
        compact.length > 180 ? '${compact.substring(0, 180)}...' : compact;
    return 'Server returned HTTP $statusCode: $preview';
  }

  (String, String) _extractError(Map<String, dynamic> decoded) {
    final detail = _readString(decoded, 'detail');
    final title = _readString(decoded, 'title');

    // Extract error code from detail if it contains a prefix like "DUPLICATE_EMAIL:"
    String? errorCode;
    String? errorMessage;

    if (detail != null && detail.trim().isNotEmpty) {
      final detailTrimmed = detail.trim();
      final colonIndex = detailTrimmed.indexOf(':');
      if (colonIndex > 0) {
        errorCode = detailTrimmed.substring(0, colonIndex).trim();
        errorMessage = detailTrimmed.substring(colonIndex + 1).trim();
        return (errorCode, errorMessage);
      }
      return ('request_failed', detailTrimmed);
    }

    if (title != null && title.trim().isNotEmpty) {
      return ('request_failed', title.trim());
    }

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

  Uri _uri(String path) {
    final fullUrl = '$_baseUrl$path';
    debugPrint('[API] Full URL: $fullUrl');
    return Uri.parse(fullUrl);
  }

  Future<String> _resolveCompanyId() async {
    final configured = _defaultCompanyId.trim();
    if (configured.isNotEmpty) {
      if (Guid.tryParse(configured) == null) {
        throw const MobileAuthServiceException(
          'invalid_company_id',
          'FLORAPRISE_COMPANY_ID is not a valid GUID.',
        );
      }
      return configured;
    }

    final companyJson = await _secureStorage.read(key: _companyKey);
    if (companyJson != null && companyJson.trim().isNotEmpty) {
      try {
        final map = jsonDecode(companyJson) as Map<String, dynamic>;
        final id = (map['id'] ?? map['Id'] ?? '').toString().trim();
        if (id.isNotEmpty && Guid.tryParse(id) != null) {
          return id;
        }
      } on Object {
        // Ignore malformed local cache and use explicit message below.
      }
    }

    throw const MobileAuthServiceException(
      'missing_company_id',
      'Company ID is required for login. Set FLORAPRISE_COMPANY_ID at build time.',
    );
  }

  double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<Map<String, dynamic>> _listOfMaps(List<dynamic> rows) {
    return rows
        .whereType<Map>()
        .map((row) => row.cast<String, dynamic>())
        .toList();
  }
}

class Guid {
  static final RegExp _regex = RegExp(
      r'^[{(]?[0-9A-Fa-f]{8}[-]?[0-9A-Fa-f]{4}[-]?[0-9A-Fa-f]{4}[-]?[0-9A-Fa-f]{4}[-]?[0-9A-Fa-f]{12}[)}]?$');

  static String? tryParse(String input) {
    final value = input.trim();
    return _regex.hasMatch(value) ? value : null;
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
