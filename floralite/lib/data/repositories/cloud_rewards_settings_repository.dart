import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../managers/reward_manager.dart';

typedef CloudSettingsHttpSender = Future<http.Response> Function(
  String method,
  Uri uri, {
  Map<String, String>? headers,
  Object? body,
});

class CloudRewardsSettingsRepository {
  CloudRewardsSettingsRepository({
    http.Client? client,
    CloudSettingsHttpSender? sender,
  })  : _client = client ?? http.Client(),
        _sender = sender;

  final http.Client _client;
  final CloudSettingsHttpSender? _sender;

  Future<http.Response> _send(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) {
    if (_sender != null) {
      return _sender!(method, uri, headers: headers, body: body);
    }
    if (method.toUpperCase() == 'PUT') {
      return _client.put(uri, headers: headers, body: body);
    }
    return _client.get(uri, headers: headers);
  }

  Future<RewardSettings> fetchSettings({
    required String baseUrl,
    required String accessToken,
  }) async {
    final cleanBase = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$cleanBase/api/v1/mobile/company/settings/rewards');
    final response = await _send(
      'GET',
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return parseSettingsFromJson(data);
      }
    }

    throw StateError('Failed to load rewards settings: ${response.statusCode}');
  }

  Future<RewardSettings> saveSettings({
    required String baseUrl,
    required String accessToken,
    required RewardSettings settings,
  }) async {
    final cleanBase = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$cleanBase/api/v1/mobile/company/settings/rewards');
    final payload = serializeSettingsToJson(settings);
    final response = await _send(
      'PUT',
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return parseSettingsFromJson(data);
      }
      return settings;
    }

    String errorMessage = 'Failed to save rewards settings: ';
    try {
      final errData = jsonDecode(response.body);
      if (errData is Map && errData['detail'] != null) {
        errorMessage = errData['detail'].toString();
      }
    } catch (_) {}

    throw StateError(errorMessage);
  }

  static RewardSettings parseSettingsFromJson(Map<String, dynamic> json) {
    return RewardSettings(
      enabled: (json['enabled'] ?? json['Enabled'] ?? true) as bool,
      earnSpendPaisePerPoint: (json['earnSpendPaisePerPoint'] ?? json['EarnSpendPaisePerPoint'] ?? 10000) as int,
      minimumBillPaise: (json['minimumBillPaise'] ?? json['MinimumBillPaise'] ?? 30000) as int,
      pointValuePaise: (json['pointValuePaise'] ?? json['PointValuePaise'] ?? 100) as int,
      maximumRedemptionPercent: (json['maximumRedemptionPercent'] ?? json['MaximumRedemptionPercent'] ?? 20) as int,
      expiryDays: (json['expiryDays'] ?? json['ExpiryDays'] ?? 365) as int,
    );
  }

  static Map<String, dynamic> serializeSettingsToJson(RewardSettings settings) {
    return {
      'enabled': settings.enabled,
      'earnSpendPaisePerPoint': settings.earnSpendPaisePerPoint,
      'minimumBillPaise': settings.minimumBillPaise,
      'pointValuePaise': settings.pointValuePaise,
      'maximumRedemptionPercent': settings.maximumRedemptionPercent,
      'expiryDays': settings.expiryDays,
    };
  }
}
