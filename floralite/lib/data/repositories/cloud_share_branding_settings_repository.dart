import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import '../../models/share_branding.dart';

typedef CloudSettingsHttpSender = Future<http.Response> Function(
  String method,
  Uri uri, {
  Map<String, String>? headers,
  Object? body,
});

class CloudShareBrandingSettingsRepository {
  CloudShareBrandingSettingsRepository({
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

  Future<ShareBrandingSettings> fetchSettings({
    required String baseUrl,
    required String accessToken,
  }) async {
    final cleanBase = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$cleanBase/api/v1/mobile/company/settings/share-branding');
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

    throw StateError('Failed to load share branding settings: ${response.statusCode}');
  }

  Future<ShareBrandingSettings> saveSettings({
    required String baseUrl,
    required String accessToken,
    required ShareBrandingSettings settings,
  }) async {
    final cleanBase = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$cleanBase/api/v1/mobile/company/settings/share-branding');
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

    String errorMessage = 'Failed to save share branding settings: ';
    try {
      final errData = jsonDecode(response.body);
      if (errData is Map && errData['detail'] != null) {
        errorMessage = errData['detail'].toString();
      }
    } catch (_) {}

    throw StateError(errorMessage);
  }

  static ShareBrandingSettings parseSettingsFromJson(Map<String, dynamic> json) {
    final sizeStr = (json['watermarkSize'] ?? json['WatermarkSize'] ?? 'medium').toString();
    final posStr = (json['watermarkPosition'] ?? json['WatermarkPosition'] ?? 'bottomCenter').toString();
    final colorRaw = json['footerColorArgb'] ?? json['FooterColorArgb'] ?? 0xCC1B5E20;
    final colorInt = colorRaw is num ? colorRaw.toInt() : (int.tryParse(colorRaw.toString()) ?? 0xCC1B5E20);

    return ShareBrandingSettings(
      showPrice: (json['showPrice'] ?? json['ShowPrice'] ?? true) as bool,
      showShopName: (json['showShopName'] ?? json['ShowShopName'] ?? true) as bool,
      showPhoneNumber: (json['showPhoneNumber'] ?? json['ShowPhoneNumber'] ?? true) as bool,
      showWebsite: (json['showWebsite'] ?? json['ShowWebsite'] ?? true) as bool,
      showLogo: (json['showLogo'] ?? json['ShowLogo'] ?? false) as bool,
      showWatermark: (json['showWatermark'] ?? json['ShowWatermark'] ?? true) as bool,
      showWatermarkBusinessName: (json['showWatermarkBusinessName'] ?? json['ShowWatermarkBusinessName'] ?? true) as bool,
      showWatermarkCity: (json['showWatermarkCity'] ?? json['ShowWatermarkCity'] ?? true) as bool,
      watermarkOpacity: ((json['watermarkOpacity'] ?? json['WatermarkOpacity'] ?? 0.72) as num).toDouble(),
      watermarkSize: parseWatermarkSize(sizeStr),
      watermarkPosition: parseWatermarkPosition(posStr),
      footerColor: Color(colorInt),
    );
  }

  static Map<String, dynamic> serializeSettingsToJson(ShareBrandingSettings settings) {
    return {
      'showPrice': settings.showPrice,
      'showShopName': settings.showShopName,
      'showPhoneNumber': settings.showPhoneNumber,
      'showWebsite': settings.showWebsite,
      'showLogo': settings.showLogo,
      'showWatermark': settings.showWatermark,
      'showWatermarkBusinessName': settings.showWatermarkBusinessName,
      'showWatermarkCity': settings.showWatermarkCity,
      'watermarkOpacity': settings.watermarkOpacity,
      'watermarkSize': settings.watermarkSize.name,
      'watermarkPosition': settings.watermarkPosition.name,
      'footerColorArgb': settings.footerColor.toARGB32(),
    };
  }

  static WatermarkSize parseWatermarkSize(String raw) {
    return WatermarkSize.values.firstWhere(
      (v) => v.name.toLowerCase() == raw.toLowerCase(),
      orElse: () => WatermarkSize.medium,
    );
  }

  static WatermarkPosition parseWatermarkPosition(String raw) {
    return WatermarkPosition.values.firstWhere(
      (v) => v.name.toLowerCase() == raw.toLowerCase(),
      orElse: () => WatermarkPosition.bottomCenter,
    );
  }
}
