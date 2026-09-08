import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../services/mobile_auth_service.dart';
import 'staff_repository.dart';

typedef CloudStaffHttpSender = Future<dynamic> Function(
  String method,
  Uri uri, {
  Map<String, dynamic>? body,
});

/// Raised when the signed-in Cloud user is not a CompanyAdmin.
class CloudStaffPermissionException implements Exception {
  const CloudStaffPermissionException([this.message =
      'Your Cloud account is not allowed to manage staff. Ask a company admin.']);

  final String message;

  @override
  String toString() => message;
}

/// Raised when an app role has no Cloud counterpart, so it is never mis-mapped.
class CloudStaffRoleNotSupportedException implements Exception {
  const CloudStaffRoleNotSupportedException(this.role);

  final StaffRole role;

  @override
  String toString() =>
      '${role.displayName} is not a Cloud staff role. Cloud supports Designer, '
      'Delivery, Cashier and Manager.';
}

/// Cloud staff roles use the existing local enum only as a UI adapter; local
/// storage roles and behavior are not changed.
class CloudStaffRoles {
  static const Map<StaffRole, String> _appToCloud = {
    StaffRole.designer: 'Designer',
    StaffRole.delivery: 'Driver',
    StaffRole.other: 'Staff',
  };

  static List<StaffRole> get supportedAppRoles =>
      _appToCloud.keys.toList(growable: false);

  static bool isSupported(StaffRole role) => _appToCloud.containsKey(role);

  static String toCloud(StaffRole role) {
    final cloud = _appToCloud[role];
    if (cloud == null) throw CloudStaffRoleNotSupportedException(role);
    return cloud;
  }

  /// Returns null when the Cloud role has no app equivalent (Admin, Staff).
  static StaffRole? toAppRole(String? cloudRole) {
    final normalized = cloudRole?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;
    for (final entry in _appToCloud.entries) {
      if (entry.value.toLowerCase() == normalized) return entry.key;
    }
    return null;
  }

  static String displayName(StaffRole role) => switch (role) {
        StaffRole.other => 'Staff',
        StaffRole.delivery => 'Delivery Person',
        _ => role.displayName,
      };
}

class CloudStaff {
  const CloudStaff({
    required this.id,
    required this.name,
    required this.cloudRole,
    required this.isActive,
    this.email,
    this.phone,
    this.commissionType,
    this.commissionRate,
    this.hourlyRate,
    this.driverStatus,
    this.loginIdentifier,
    this.loginRole,
    this.createdAtUtc,
  });

  final String id;
  final String name;
  final String cloudRole;
  final bool isActive;
  final String? email;
  final String? phone;
  final String? commissionType;
  final double? commissionRate;
  final double? hourlyRate;
  final String? driverStatus;
  final String? loginIdentifier;
  final String? loginRole;
  final DateTime? createdAtUtc;

  StaffRole? get appRole => CloudStaffRoles.toAppRole(cloudRole);

  String get roleLabel =>
      appRole == null ? cloudRole : CloudStaffRoles.displayName(appRole!);
}

class CloudStaffInput {
  const CloudStaffInput({
    required this.name,
    required this.role,
    this.phone,
    this.email,
    this.isActive = true,
  });

  final String name;
  final StaffRole role;
  final String? phone;
  final String? email;
  final bool isActive;
}

class CloudStaffRepository {
  CloudStaffRepository({
    MobileAuthService? auth,
    CloudStaffHttpSender? sender,
  })  : _auth = auth ?? MobileAuthService(),
        _sender = sender;

  final MobileAuthService _auth;
  final CloudStaffHttpSender? _sender;

  Future<List<CloudStaff>> list() async {
    final response = await _send('GET', Uri.parse('${_auth.baseUrl}/api/staff'));
    return _staffList(response);
  }

  Future<List<CloudStaff>> search({
    String? query,
    StaffRole? role,
    bool? isActive,
    int page = 1,
    int pageSize = 200,
  }) async {
    final parameters = <String, String>{
      'page': '$page',
      'pageSize': '${pageSize.clamp(1, 200)}',
      if (query != null && query.trim().isNotEmpty) 'query': query.trim(),
      if (role != null) 'role': CloudStaffRoles.toCloud(role),
      if (isActive != null) 'isActive': '$isActive',
    };

    final response = await _send(
      'GET',
      Uri.parse('${_auth.baseUrl}/api/staff/search')
          .replace(queryParameters: parameters),
    );
    return _staffList(response);
  }

  Future<CloudStaff?> getById(String staffId) async {
    final id = staffId.trim();
    if (id.isEmpty) return null;
    final response = await _send(
      'GET',
      Uri.parse('${_auth.baseUrl}/api/staff/${Uri.encodeComponent(id)}'),
    );
    if (response is! Map) return null;
    return _staff(response.cast<String, dynamic>());
  }

  Future<String> create(CloudStaffInput input) async {
    final response = await _send(
      'POST',
      Uri.parse('${_auth.baseUrl}/api/staff'),
      body: _upsertBody(input),
    );
    final map = response is Map ? response.cast<String, dynamic>() : null;
    return _string(map ?? const {}, 'id');
  }

  Future<void> update(String staffId, CloudStaffInput input) async {
    await _send(
      'PUT',
      Uri.parse('${_auth.baseUrl}/api/staff/${Uri.encodeComponent(staffId.trim())}'),
      body: _upsertBody(input),
    );
  }

  Future<void> setActive(String staffId, bool isActive) async {
    await _send(
      'PUT',
      Uri.parse('${_auth.baseUrl}/api/staff/${Uri.encodeComponent(staffId.trim())}'),
      body: {'isActive': isActive},
    );
  }

  Future<bool> hasOrders(String staffId) async {
    final response = await _send(
      'GET',
      Uri.parse(
        '${_auth.baseUrl}/api/staff/${Uri.encodeComponent(staffId.trim())}/has-orders',
      ),
    );
    if (response is! Map) return false;
    final value = response.cast<String, dynamic>();
    return value[_key(value, 'hasOrders')] == true;
  }

  static Map<String, dynamic> _upsertBody(CloudStaffInput input) => {
        'name': input.name.trim(),
        'role': CloudStaffRoles.toCloud(input.role),
        if (input.phone?.trim().isNotEmpty == true) 'phone': input.phone!.trim(),
        if (input.email?.trim().isNotEmpty == true) 'email': input.email!.trim(),
        'isActive': input.isActive,
      };

  Future<dynamic> _send(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    final override = _sender;
    if (override != null) return override(method, uri, body: body);

    var token = await _auth.getStoredAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw StateError('Cloud session is not available. Please log in again.');
    }

    debugPrint('[STAFF-CLOUD] $method $uri');
    for (var attempt = 0; attempt < 2; attempt++) {
      final client = HttpClient();
      try {
        final request = await client.openUrl(method, uri).timeout(
              const Duration(seconds: 12),
            );
        request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
        if (body != null) {
          request.headers.contentType = ContentType.json;
          request.write(jsonEncode(body));
        }

        final response =
            await request.close().timeout(const Duration(seconds: 20));
        final responseBody = await response.transform(utf8.decoder).join();
        debugPrint('[STAFF-CLOUD] HTTP STATUS: ${response.statusCode}');

        if (response.statusCode == 401 && attempt == 0) {
          final refreshed = await _auth.refreshAndBootstrap();
          token = refreshed.accessToken;
          continue;
        }

        if (response.statusCode == 403) {
          throw const CloudStaffPermissionException();
        }

        final decoded = responseBody.trim().isEmpty
            ? <String, dynamic>{}
            : _decode(responseBody);
        if (response.statusCode < 200 || response.statusCode >= 300) {
          final message = decoded is Map
              ? decoded['message'] ??
                  decoded['error'] ??
                  decoded['detail'] ??
                  decoded['title']
              : null;
          throw StateError(
            message?.toString() ??
                'Cloud staff request failed (HTTP ${response.statusCode}).',
          );
        }
        return decoded;
      } on SocketException catch (error) {
        throw StateError('Unable to connect to Floraprise Cloud: $error');
      } finally {
        client.close(force: true);
      }
    }
    throw StateError('Cloud staff request failed.');
  }

  static dynamic _decode(String text) {
    try {
      return jsonDecode(text);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static List<CloudStaff> _staffList(dynamic response) {
    final rows = response is List
        ? response
        : response is Map
            ? response[_key(response.cast<String, dynamic>(), 'items')]
            : null;
    if (rows is! List) return const [];

    return rows
        .whereType<Map>()
        .map((row) => row.cast<String, dynamic>())
        .where((row) => _string(row, 'id').trim().isNotEmpty)
        .map(_staff)
        .toList();
  }

  static CloudStaff _staff(Map<String, dynamic> json) => CloudStaff(
        id: _string(json, 'id'),
        name: _string(json, 'name', fallback: '-'),
        cloudRole: _string(json, 'role', fallback: 'Staff'),
        isActive: json[_key(json, 'isActive')] != false,
        email: _nullableString(json, 'email'),
        phone: _nullableString(json, 'phone'),
        commissionType: _nullableString(json, 'commissionType'),
        commissionRate: _double(json, 'commissionRate'),
        hourlyRate: _double(json, 'hourlyRate'),
        driverStatus: _nullableString(json, 'driverStatus'),
        loginIdentifier: _nullableString(json, 'loginIdentifier'),
        loginRole: _nullableString(json, 'loginRole'),
        createdAtUtc: DateTime.tryParse(_string(json, 'createdAtUtc')),
      );

  static String _key(Map<String, dynamic> json, String key) =>
      json.containsKey(key) ? key : '${key[0].toUpperCase()}${key.substring(1)}';

  static String _string(
    Map<String, dynamic> json,
    String key, {
    String fallback = '',
  }) =>
      json[_key(json, key)]?.toString() ?? fallback;

  static String? _nullableString(Map<String, dynamic> json, String key) {
    final value = json[_key(json, key)]?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  static double? _double(Map<String, dynamic> json, String key) {
    final value = json[_key(json, key)];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}
