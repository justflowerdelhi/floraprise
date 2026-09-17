import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/mobile_auth_service.dart';

class CloudPaymentGatewayConfig {
  final String id;
  final String gatewayType;
  final String gatewayTypeName;
  final String name;
  final String publicKey;
  final String? merchantId;
  final String environment;
  final String environmentName;
  final String currency;
  final String? supportedCurrencies;
  final bool isActive;
  final bool isDefault;
  final String? webhookUrl;
  final DateTime? lastTestedAt;
  final bool? lastTestSuccessful;
  final String region;
  final DateTime createdAt;

  const CloudPaymentGatewayConfig({
    required this.id,
    required this.gatewayType,
    required this.gatewayTypeName,
    required this.name,
    required this.publicKey,
    this.merchantId,
    required this.environment,
    required this.environmentName,
    required this.currency,
    this.supportedCurrencies,
    required this.isActive,
    required this.isDefault,
    this.webhookUrl,
    this.lastTestedAt,
    this.lastTestSuccessful,
    required this.region,
    required this.createdAt,
  });

  factory CloudPaymentGatewayConfig.fromJson(Map<String, dynamic> json) {
    return CloudPaymentGatewayConfig(
      id: json['id']?.toString() ?? '',
      gatewayType: json['gatewayType']?.toString() ?? '',
      gatewayTypeName: json['gatewayTypeName']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      publicKey: json['publicKey']?.toString() ?? '',
      merchantId: json['merchantId']?.toString(),
      environment: json['environment']?.toString() ?? '',
      environmentName: json['environmentName']?.toString() ?? '',
      currency: json['currency']?.toString() ?? 'INR',
      supportedCurrencies: json['supportedCurrencies']?.toString(),
      isActive: json['isActive'] == true,
      isDefault: json['isDefault'] == true,
      webhookUrl: json['webhookUrl']?.toString(),
      lastTestedAt: json['lastTestedAt'] != null
          ? DateTime.tryParse(json['lastTestedAt'].toString())
          : null,
      lastTestSuccessful: json['lastTestSuccessful'] as bool?,
      region: json['region']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class PaymentGatewayTestResult {
  final bool success;
  final String message;
  final DateTime testedAt;

  const PaymentGatewayTestResult({
    required this.success,
    required this.message,
    required this.testedAt,
  });

  factory PaymentGatewayTestResult.fromJson(Map<String, dynamic> json) {
    return PaymentGatewayTestResult(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      testedAt: json['testedAt'] != null
          ? DateTime.tryParse(json['testedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class CloudPaymentGatewayRepository {
  CloudPaymentGatewayRepository({
    MobileAuthService? auth,
    http.Client? client,
  })  : _auth = auth ?? MobileAuthService(),
        _client = client ?? http.Client();

  final MobileAuthService _auth;
  final http.Client _client;

  Future<Map<String, String>> _headers() async {
    final token = await _auth.getStoredAccessToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  String get _baseUrl => _auth.baseUrl.replaceAll(RegExp(r'/+$'), '');

  Future<List<CloudPaymentGatewayConfig>> fetchConfigs() async {
    final uri = Uri.parse('$_baseUrl/api/payment-gateways');
    final response = await _client.get(uri, headers: await _headers());

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> list = jsonDecode(response.body);
      return list
          .map((item) => CloudPaymentGatewayConfig.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    throw StateError('Failed to load payment gateway configurations (${response.statusCode})');
  }

  Future<CloudPaymentGatewayConfig> createConfig({
    required String gatewayType,
    required String name,
    required String publicKey,
    required String secretKey,
    String? webhookSecret,
    String? merchantId,
    String environment = 'Production',
    String currency = 'INR',
    bool isDefault = true,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/payment-gateways');
    final payload = {
      'gatewayType': gatewayType,
      'name': name,
      'publicKey': publicKey,
      'secretKey': secretKey,
      'webhookSecret': webhookSecret,
      'merchantId': merchantId,
      'environment': environment,
      'currency': currency,
      'isDefault': isDefault,
    };

    final response = await _client.post(
      uri,
      headers: await _headers(),
      body: jsonEncode(payload),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return CloudPaymentGatewayConfig.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    String message = 'Failed to create gateway configuration (${response.statusCode})';
    try {
      final err = jsonDecode(response.body);
      if (err is Map && err['message'] != null) {
        message = err['message'].toString();
      }
    } catch (_) {}

    throw StateError(message);
  }

  Future<CloudPaymentGatewayConfig> updateConfig({
    required String id,
    required String name,
    String? publicKey,
    String? secretKey,
    String? webhookSecret,
    String? merchantId,
    String? environment,
    String? currency,
    bool? isActive,
    bool? isDefault,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/payment-gateways/$id');
    final payload = <String, dynamic>{
      'name': name,
      if (publicKey != null) 'publicKey': publicKey,
      if (secretKey != null && secretKey.isNotEmpty) 'secretKey': secretKey,
      if (webhookSecret != null) 'webhookSecret': webhookSecret,
      if (merchantId != null) 'merchantId': merchantId,
      if (environment != null) 'environment': environment,
      if (currency != null) 'currency': currency,
      if (isActive != null) 'isActive': isActive,
      if (isDefault != null) 'isDefault': isDefault,
    };

    final response = await _client.put(
      uri,
      headers: await _headers(),
      body: jsonEncode(payload),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return CloudPaymentGatewayConfig.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    String message = 'Failed to update gateway configuration (${response.statusCode})';
    try {
      final err = jsonDecode(response.body);
      if (err is Map && err['message'] != null) {
        message = err['message'].toString();
      }
    } catch (_) {}

    throw StateError(message);
  }

  Future<bool> deleteConfig(String id) async {
    final uri = Uri.parse('$_baseUrl/api/payment-gateways/$id');
    final response = await _client.delete(uri, headers: await _headers());
    return response.statusCode == 200 || response.statusCode == 204;
  }

  Future<PaymentGatewayTestResult> testConnection(String id) async {
    final uri = Uri.parse('$_baseUrl/api/payment-gateways/$id/test');
    final response = await _client.post(uri, headers: await _headers());

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return PaymentGatewayTestResult.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    return PaymentGatewayTestResult(
      success: false,
      message: 'Test request failed with status code ${response.statusCode}',
      testedAt: DateTime.now(),
    );
  }
}
