import 'dart:convert';
import 'dart:io';

import '../data/database/app_database.dart';
import '../data/repositories/pos_sync_outbox_repository.dart';
import 'mobile_auth_service.dart';

typedef PosSaleSyncSender = Future<PosSaleSyncHttpResponse> Function(
  Uri uri,
  String payloadJson,
  String bearerToken,
);
typedef PosSaleAccessTokenReader = Future<String?> Function();
typedef PosSaleAccessTokenRefresher = Future<String> Function();

class PosSaleSyncHttpResponse {
  const PosSaleSyncHttpResponse({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final String body;
}

class PosSaleSyncResult {
  const PosSaleSyncResult({
    required this.processedCount,
    required this.completedCount,
    required this.failedCount,
  });

  final int processedCount;
  final int completedCount;
  final int failedCount;
}

class PosSaleSyncService {
  PosSaleSyncService({
    MobileAuthService? auth,
    PosSyncOutboxRepository? outboxRepository,
    PosSaleSyncSender? sender,
    PosSaleAccessTokenReader? readAccessToken,
    PosSaleAccessTokenRefresher? refreshAccessToken,
  })  : _auth = auth ?? MobileAuthService(),
        _outboxRepository = outboxRepository ?? PosSyncOutboxRepository(),
        _sender = sender,
        _readAccessToken = readAccessToken,
        _refreshAccessToken = refreshAccessToken;

  final MobileAuthService _auth;
  final PosSyncOutboxRepository _outboxRepository;
  final PosSaleSyncSender? _sender;
  final PosSaleAccessTokenReader? _readAccessToken;
  final PosSaleAccessTokenRefresher? _refreshAccessToken;

  Future<PosSaleSyncResult> syncPending() async {
    final db = await AppDatabase.instance.database;
    final rows = await _outboxRepository.listRetryable(db);
    var completed = 0;
    var failed = 0;

    for (final row in rows) {
      try {
        await _syncRow(row);
        completed++;
      } catch (error) {
        await _outboxRepository.markRetryableFailure(
          id: row.id,
          previousAttemptCount: row.attemptCount,
          error: error,
        );
        failed++;
      }
    }

    return PosSaleSyncResult(
      processedCount: rows.length,
      completedCount: completed,
      failedCount: failed,
    );
  }

  Future<void> _syncRow(PosSyncOutboxRecord row) async {
    var token = await (_readAccessToken ?? _auth.getStoredAccessToken)();
    if (token == null || token.trim().isEmpty) {
      throw StateError('Cloud session is not available. Please log in again.');
    }

    var response = await _send(row.payloadJson, token);
    if (response.statusCode == HttpStatus.unauthorized) {
      token = await _refreshToken();
      response = await _send(row.payloadJson, token);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'POS sale sync failed (HTTP ${response.statusCode}). Body: ${response.body}',
      );
    }

    final decoded = response.body.trim().isEmpty
        ? <String, dynamic>{}
        : (jsonDecode(response.body) as Map).cast<String, dynamic>();
    final cloudOrderId = _readString(decoded, 'cloudOrderId');
    if (cloudOrderId == null || cloudOrderId.trim().isEmpty) {
      throw StateError('POS sale sync response did not include cloudOrderId.');
    }
    await _outboxRepository.markCompleted(
      id: row.id,
      cloudOrderId: cloudOrderId,
      cloudCustomerId: _readString(decoded, 'cloudCustomerId'),
    );
  }

  Future<String> _refreshToken() async {
    final refresh = _refreshAccessToken;
    if (refresh != null) return refresh();
    final payload = await _auth.refreshAndBootstrap();
    return payload.accessToken;
  }

  Future<PosSaleSyncHttpResponse> _send(String payloadJson, String token) {
    final uri = Uri.parse('${_auth.baseUrl}/api/v1/mobile/pos-sales/sync');
    final sender = _sender;
    if (sender != null) return sender(uri, payloadJson, token);
    return _defaultSend(uri, payloadJson, token);
  }

  Future<PosSaleSyncHttpResponse> _defaultSend(
    Uri uri,
    String payloadJson,
    String token,
  ) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(uri).timeout(
            const Duration(seconds: 12),
          );
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.headers.contentType = ContentType.json;
      request.write(payloadJson);
      final response = await request.close().timeout(const Duration(seconds: 20));
      final body = await response.transform(utf8.decoder).join();
      return PosSaleSyncHttpResponse(statusCode: response.statusCode, body: body);
    } finally {
      client.close(force: true);
    }
  }

  static String? _readString(Map<String, dynamic> json, String key) {
    final value = json[key] ?? json['${key[0].toUpperCase()}${key.substring(1)}'];
    return value?.toString();
  }
}