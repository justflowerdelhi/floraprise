import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../data/database/app_database.dart';
import '../managers/business_settings_manager.dart';
import 'api_base_url.dart';
import 'mobile_auth_service.dart';

class DeliveryTrackingException implements Exception {
  const DeliveryTrackingException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DeliveryDriverInfo {
  const DeliveryDriverInfo({
    required this.name,
    required this.phone,
    this.vehicle,
  });

  final String name;
  final String phone;
  final String? vehicle;
}

class DeliveryLocationPoint {
  const DeliveryLocationPoint({
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    required this.speedKph,
    this.accuracyMeters,
    this.batteryPercentage,
  });

  final double latitude;
  final double longitude;
  final DateTime recordedAt;
  final double speedKph;
  final double? accuracyMeters;
  final int? batteryPercentage;
}

class DeliveryTimelineEvent {
  const DeliveryTimelineEvent({
    required this.status,
    required this.recordedAt,
    this.note,
  });

  final String status;
  final DateTime recordedAt;
  final String? note;
}

class DeliveryProof {
  const DeliveryProof({
    required this.photoUrl,
    this.note,
    this.recipientName,
    this.recordedAt,
    this.otpVerified,
    this.signatureCaptured,
    this.signatureValue,
  });

  final String photoUrl;
  final String? note;
  final String? recipientName;
  final DateTime? recordedAt;
  final bool? otpVerified;
  final bool? signatureCaptured;
  final String? signatureValue;
}

class DeliveryTrackingSnapshot {
  const DeliveryTrackingSnapshot({
    required this.assignmentId,
    required this.orderId,
    required this.trackingId,
    required this.trackingLink,
    required this.status,
    required this.eta,
    required this.driver,
    required this.route,
    required this.timeline,
    required this.proof,
    required this.lastLocation,
  });

  final String assignmentId;
  final int orderId;
  final String trackingId;
  final String trackingLink;
  final String status;
  final DateTime? eta;
  final DeliveryDriverInfo? driver;
  final List<DeliveryLocationPoint> route;
  final List<DeliveryTimelineEvent> timeline;
  final DeliveryProof? proof;
  final DeliveryLocationPoint? lastLocation;

  DeliveryTrackingSnapshot copyWith({
    String? assignmentId,
    int? orderId,
    String? trackingId,
    String? trackingLink,
    String? status,
    DateTime? eta,
    DeliveryDriverInfo? driver,
    List<DeliveryLocationPoint>? route,
    List<DeliveryTimelineEvent>? timeline,
    DeliveryProof? proof,
    DeliveryLocationPoint? lastLocation,
  }) {
    return DeliveryTrackingSnapshot(
      assignmentId: assignmentId ?? this.assignmentId,
      orderId: orderId ?? this.orderId,
      trackingId: trackingId ?? this.trackingId,
      trackingLink: trackingLink ?? this.trackingLink,
      status: status ?? this.status,
      eta: eta ?? this.eta,
      driver: driver ?? this.driver,
      route: route ?? this.route,
      timeline: timeline ?? this.timeline,
      proof: proof ?? this.proof,
      lastLocation: lastLocation ?? this.lastLocation,
    );
  }
}

class DeliveryWorkspaceRecord {
  const DeliveryWorkspaceRecord({
    required this.assignmentId,
    required this.orderId,
    required this.orderNo,
    required this.customerName,
    required this.recipientName,
    required this.deliveryAddress,
    required this.deliveryArea,
    required this.customerPhone,
    required this.deliveryTime,
    required this.status,
    required this.trackingLink,
    required this.eta,
    required this.updatedAt,
    this.driver,
  });

  final String assignmentId;
  final String orderId;
  final String orderNo;
  final String customerName;
  final String recipientName;
  final String deliveryAddress;
  final String deliveryArea;
  final String? customerPhone;
  final String deliveryTime;
  final String status;
  final String trackingLink;
  final DateTime? eta;
  final DateTime updatedAt;
  final DeliveryDriverInfo? driver;
}

class DeliveryTrackingService {
  DeliveryTrackingService({
    MobileAuthService? auth,
    HttpClient? httpClient,
    String? trackingHubPath,
  })  : _auth = auth ?? MobileAuthService(),
        _httpClient = httpClient ?? HttpClient(),
        _trackingHubPath = trackingHubPath ?? '/hubs/delivery-tracking';

  final MobileAuthService _auth;
  final HttpClient _httpClient;
  final String _trackingHubPath;

  static const _assignmentLocationQueueKey =
      'delivery_assignment_location_queue';
  static const _driverTokenLocationQueueKey = 'delivery_driver_location_queue';

  String get _baseUrl {
    const explicit =
        String.fromEnvironment('FLORAPRISE_API_URL', defaultValue: '');
    return resolveFlorapriseApiBaseUrl(
      explicitValue: explicit,
      isDebug: kDebugMode,
      platform: defaultTargetPlatform,
    );
  }

  Future<List<DeliveryWorkspaceRecord>> getWorkspace(String status) async {
    final localRows = await _getLocalWorkspace(status);

    try {
      final payload =
          await _getJson('/api/v1/mobile/delivery/workspace?status=$status');
      final rows = _asList(payload['items'] ?? payload['records']);
      return _mergeWorkspaceRows(
        localRows,
        rows.map(_toWorkspaceRecord).toList(),
      );
    } on Object {
      if (localRows.isNotEmpty) return localRows;
      rethrow;
    }
  }

  Future<List<DeliveryWorkspaceRecord>> getActiveDeliveries() async {
    final localRows = await _getLocalWorkspace('active');

    try {
      final payload =
          await _getJson('/api/v1/mobile/delivery/workspace/active');
      final rows = _asList(payload['items'] ?? payload['records']);
      return _mergeWorkspaceRows(
        localRows,
        rows.map(_toWorkspaceRecord).toList(),
      );
    } on Object {
      if (localRows.isNotEmpty) return localRows;
      rethrow;
    }
  }

  Future<String?> getCloudDeliveryIdForOrder(String orderNo) async {
    final normalizedOrderNo = orderNo.trim().toLowerCase();
    if (normalizedOrderNo.isEmpty) return null;

    for (final status in const [
      'active',
      'Created',
      'Confirmed',
      'InProduction',
      'Ready',
      'Scheduled',
    ]) {
      final payload =
          await _getJson('/api/v1/mobile/delivery/workspace?status=$status');
      final rows = _asList(payload['items'] ?? payload['records']);
      for (final row in rows) {
        final cloudOrderNo = _readString(row, 'orderNo')?.trim();
        final deliveryId = _readString(row, 'assignmentId');
        if (cloudOrderNo?.toLowerCase() == normalizedOrderNo &&
            deliveryId != null) {
          return deliveryId;
        }
      }
    }
    return null;
  }

  /// Resolves or creates a cloud Delivery record for an order.
  /// This method does NOT depend on local order_workflow_assignments.
  /// It queries the local orders table directly and calls the backend
  /// sync-assignment endpoint to create/retrieve the cloud Delivery.
  ///
  /// Returns the cloud Delivery UUID if successful, null otherwise.
  Future<String?> resolveOrCreateCloudDeliveryId(int orderId) async {
    debugPrint('[DeliveryService] resolveOrCreateCloudDeliveryId - Local Order ID: $orderId');

    final db = await AppDatabase.instance.database;

    // Query the local orders table directly
    final orderRows = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [orderId],
      limit: 1,
    );

    if (orderRows.isEmpty) {
      throw const DeliveryTrackingException(
        'Order not found locally.',
      );
    }

    final order = orderRows.first;
    final orderNo = order['order_no'] as String?;
    if (orderNo == null || orderNo.trim().isEmpty) {
      throw const DeliveryTrackingException(
        'Order number is missing.',
      );
    }

    debugPrint('[DeliveryService] resolveOrCreateCloudDeliveryId - Order Number: $orderNo');

    // Try to find existing cloud Delivery first via workspace API
    final existingDeliveryId = await getCloudDeliveryIdForOrder(orderNo);
    if (existingDeliveryId != null && existingDeliveryId.trim().isNotEmpty) {
      debugPrint('[DeliveryService] resolveOrCreateCloudDeliveryId - Found existing Cloud Delivery UUID: $existingDeliveryId');
      return existingDeliveryId;
    }

    debugPrint('[DeliveryService] resolveOrCreateCloudDeliveryId - No existing Delivery, calling POST /api/v1/mobile/delivery/sync-assignment');

    // Create cloud Delivery via sync-assignment without driver
    // Use fresh HttpClient to avoid socket resolution issues
    final payload = await _postSyncAssignmentWithFreshClient(
      {
        'orderNumber': orderNo.trim(),
        'customerName': order['customer_name'],
        'customerPhone': order['customer_phone'],
        'recipientName': order['recipient_name'],
        'recipientPhone': order['recipient_phone'],
        'deliveryAddress': order['delivery_address'],
        'deliveryPincode': order['delivery_pincode'],
        'deliveryDate': order['scheduled_at'],
        'deliverySlot': order['delivery_slot'],
        // No driver info - backend will create unassigned Delivery
      },
    );

    final backendOrderId = _readString(payload, 'backendOrderId') ??
        _readString(payload, 'orderId') ??
        '';
    final backendDeliveryId = _readString(payload, 'deliveryId') ?? '';
    if (backendOrderId.isEmpty || backendDeliveryId.isEmpty) {
      throw const DeliveryTrackingException(
        'Delivery creation did not return backend IDs.',
      );
    }

    debugPrint('[DeliveryService] resolveOrCreateCloudDeliveryId - Created Cloud Delivery UUID: $backendDeliveryId');
    return backendDeliveryId;
  }

  Future<List<DeliveryWorkspaceRecord>> _getLocalWorkspace(
      String status) async {
    // Simplified local workspace - no longer depends on workflow assignments
    // Local orders are shown only when cloud is unavailable
    final db = await AppDatabase.instance.database;
    final normalized = status.trim().toLowerCase();
    final statuses = switch (normalized) {
      'completed' => const ['delivered'],
      'cancelled' => const ['cancelled', 'delivery_failed'],
      _ => const [
          'confirmed',
          'sent_to_designer',
          'preparing',
          'ready',
          'out_for_delivery',
        ],
    };

    final rows = await db.rawQuery('''
      SELECT
        o.id,
        o.order_no,
        o.customer_name,
        o.customer_phone,
        o.recipient_name,
        o.recipient_phone,
        o.delivery_address,
        o.delivery_pincode,
        o.delivery_slot,
        o.scheduled_at,
        o.status,
        o.updated_at
      FROM orders o
      WHERE o.fulfilment_type = 'delivery'
        AND o.status IN (${List.filled(statuses.length, '?').join(',')})
      ORDER BY COALESCE(o.scheduled_at, o.updated_at, o.created_at) DESC
    ''', statuses);

    return rows.map(_toLocalWorkspaceRecord).toList();
  }

  List<DeliveryWorkspaceRecord> _mergeWorkspaceRows(
    List<DeliveryWorkspaceRecord> localRows,
    List<DeliveryWorkspaceRecord> cloudRows,
  ) {
    if (localRows.isEmpty) return cloudRows;
    if (cloudRows.isEmpty) return localRows;

    final seenOrderNos = localRows.map((row) => row.orderNo).toSet();
    return [
      ...localRows,
      ...cloudRows.where((row) => !seenOrderNos.contains(row.orderNo)),
    ];
  }







  /// Syncs driver information to an existing cloud delivery.
  /// This is called after local driver assignment to update the cloud delivery.
  /// The cloud delivery must already exist (created via resolveOrCreateCloudDeliveryId).
  Future<void> syncDeliveryAssignment(int orderId) async {
    debugPrint('[DeliveryService] syncDeliveryAssignment - Order ID: $orderId');

    // First resolve the cloud delivery - it should already exist
    final deliveryId = await resolveOrCreateCloudDeliveryId(orderId);
    if (deliveryId == null || deliveryId.trim().isEmpty) {
      debugPrint('[DeliveryService] syncDeliveryAssignment - No cloud delivery found, skipping sync');
      return;
    }

    // Get local driver assignment info
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT
        s.name AS driver_name,
        s.phone AS driver_phone
      FROM order_workflow_assignments owa
      JOIN staff s ON s.id = owa.associate_id
      WHERE owa.order_id = ? AND owa.assignment_type = 'delivery'
      LIMIT 1
    ''', [orderId]);

    if (rows.isEmpty) {
      debugPrint('[DeliveryService] syncDeliveryAssignment - No local driver assignment found');
      return;
    }

    final row = rows.first;
    final driverName = (row['driver_name'] as String?)?.trim() ?? '';
    final driverPhone = (row['driver_phone'] as String?)?.trim() ?? '';

    if (driverName.isEmpty && driverPhone.isEmpty) {
      debugPrint('[DeliveryService] syncDeliveryAssignment - No driver info to sync');
      return;
    }

    // Sync driver info to cloud delivery
    try {
      final response = await _postJson(
        '/api/v1/mobile/delivery/assignments/$deliveryId/driver',
        {
          'driverName': driverName,
          'driverPhone': driverPhone,
        },
      );
      debugPrint('[DeliveryService] syncDeliveryAssignment - Driver info synced to cloud delivery: $response');
    } on Object catch (error) {
      debugPrint('[DeliveryService] syncDeliveryAssignment - Failed to sync driver info: $error');
      rethrow; // Throw error to caller so florist can see the failure
    }
  }

  bool isPendingSyncAssignment(String assignmentId) =>
      assignmentId.startsWith('local:') ||
      assignmentId.startsWith('pending-sync:');

  /// POST to sync-assignment endpoint using a fresh HttpClient instance.
  /// This avoids socket resolution issues that occur with the shared client.
  Future<Map<String, dynamic>> _postSyncAssignmentWithFreshClient(
    Map<String, Object?> body,
  ) async {
    debugPrint('[DeliveryService] sync-assignment POST starting');

    final freshClient = HttpClient();
    try {
      final token = await _readAccessToken();
      if (token == null || token.trim().isEmpty) {
        throw const DeliveryTrackingException(
          'Cloud delivery session is not available on this device.',
        );
      }

      final uri = _uri('/api/v1/mobile/delivery/sync-assignment');

      final request = await freshClient.openUrl('POST', uri).timeout(
            const Duration(seconds: 12),
          );
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');

      request.add(utf8.encode(jsonEncode(body)));

      final response =
          await request.close().timeout(const Duration(seconds: 20));
      final responseBody = await response.transform(utf8.decoder).join();

      debugPrint('[DeliveryService] sync-assignment POST HTTP ${response.statusCode}');
      debugPrint('[DeliveryService] sync-assignment response $responseBody');

      // Refresh token and retry once on 401
      if (response.statusCode == 401) {
        debugPrint('[DeliveryService] sync-assignment 401 received; refreshing token and retrying');
        try {
          final refreshed = await _auth.refreshAndBootstrap();
          if (refreshed.accessToken.isNotEmpty) {
            debugPrint('[DeliveryService] sync-assignment Token refresh succeeded, retrying');
            // Retry with fresh client
            return _postSyncAssignmentWithFreshClient(body);
          }
        } on Object catch (e) {
          debugPrint('[DeliveryService] sync-assignment Token refresh failed: $e');
          throw const DeliveryTrackingException(
              'Cloud delivery session expired and could not be refreshed.');
        }
      }

      final decoded = responseBody.trim().isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(responseBody) as Map<String, dynamic>);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        // Expose actual server response for 400/500
        final serverMsg = _readString(_asMap(decoded['error']), 'message') ??
            _readString(decoded, 'title') ??
            _readString(decoded, 'detail') ??
            responseBody;
        throw DeliveryTrackingException(
          'HTTP ${response.statusCode}: $serverMsg',
        );
      }

      final data = decoded['data'];
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return data.cast<String, dynamic>();
      return decoded;
    } on SocketException catch (e) {
      debugPrint('[DeliveryService] sync-assignment socket failure: $e');
      throw DeliveryTrackingException(_connectionFailureMessage());
    } on DeliveryTrackingException {
      rethrow;
    } on Object catch (e) {
      debugPrint('[DeliveryService] sync-assignment unexpected error: $e');
      throw DeliveryTrackingException('Unexpected error: $e');
    } finally {
      freshClient.close();
    }
  }

  /// Gets tracking for a local order by resolving the cloud delivery first.
  /// This is the canonical order-centric tracking method.
  Future<DeliveryTrackingSnapshot> getTrackingForLocalOrder(int orderId) async {
    debugPrint('[DeliveryService] getTrackingForLocalOrder - Order ID: $orderId');

    // Resolve cloud Delivery UUID first
    final deliveryId = await resolveOrCreateCloudDeliveryId(orderId);
    if (deliveryId == null || deliveryId.trim().isEmpty) {
      throw const DeliveryTrackingException(
        'Could not resolve cloud Delivery for this order.',
      );
    }

    debugPrint('[DeliveryService] getTrackingForLocalOrder - Cloud Delivery UUID: $deliveryId');

    // Use delivery UUID to get tracking
    final payload = await _getJson(
      '/api/v1/mobile/delivery/assignments/$deliveryId/tracking',
    );
    return _toSnapshot(payload);
  }


  Future<DeliveryTrackingSnapshot> getTrackingByAssignmentId(
      String assignmentId) async {
    final payload = await _getJson(
        '/api/v1/mobile/delivery/assignments/$assignmentId/tracking');
    return _toSnapshot(payload);
  }

  Future<String> updateAssignmentStatus({
    required String assignmentId,
    required String action,
    String? notes,
  }) async {
    final payload = await _postJson(
      '/api/v1/mobile/delivery/assignments/$assignmentId/status',
      {
        'action': action,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );
    return _readString(payload, 'status') ?? action;
  }

  Future<void> uploadAssignmentLocation({
    required String assignmentId,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? speed,
    double? heading,
    DateTime? recordedAt,
  }) async {
    await _postJson(
      '/api/v1/mobile/delivery/assignments/$assignmentId/location',
      {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'speed': speed,
        'heading': heading,
        'recordedAt': recordedAt?.toIso8601String(),
      },
    );
  }

  Future<void> queueAssignmentLocation({
    required String assignmentId,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? speed,
    double? heading,
    DateTime? recordedAt,
  }) async {
    await _appendQueuedLocation(
      _assignmentLocationQueueKey,
      _QueuedDeliveryLocation(
        reference: assignmentId,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        speed: speed,
        heading: heading,
        recordedAt: recordedAt ?? DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> flushAssignmentLocationQueue() async {
    final pending = await _readQueuedLocations(_assignmentLocationQueueKey);
    if (pending.isEmpty) return;

    final remaining = <_QueuedDeliveryLocation>[];
    for (final location in pending) {
      try {
        await uploadAssignmentLocation(
          assignmentId: location.reference,
          latitude: location.latitude,
          longitude: location.longitude,
          accuracy: location.accuracy,
          speed: location.speed,
          heading: location.heading,
          recordedAt: location.recordedAt,
        );
      } on Object {
        remaining.add(location);
      }
    }
    await _writeQueuedLocations(_assignmentLocationQueueKey, remaining);
  }

  Future<void> queueDriverTokenLocation({
    required String token,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? speed,
    double? heading,
    DateTime? recordedAt,
  }) async {
    await _appendQueuedLocation(
      _driverTokenLocationQueueKey,
      _QueuedDeliveryLocation(
        reference: token,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        speed: speed,
        heading: heading,
        recordedAt: recordedAt ?? DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> flushDriverTokenLocationQueue() async {
    final pending = await _readQueuedLocations(_driverTokenLocationQueueKey);
    if (pending.isEmpty) return;

    final remaining = <_QueuedDeliveryLocation>[];
    for (final location in pending) {
      try {
        await uploadDriverLocation(
          token: location.reference,
          latitude: location.latitude,
          longitude: location.longitude,
          accuracy: location.accuracy,
          speed: location.speed,
          heading: location.heading,
          recordedAt: location.recordedAt,
        );
      } on Object {
        remaining.add(location);
      }
    }
    await _writeQueuedLocations(_driverTokenLocationQueueKey, remaining);
  }

  Future<DeliveryTrackingSnapshot> getPublicTrackingByLink(
    String trackingLink,
  ) async {
    final payload = await _getPublicJsonFromLink(trackingLink);
    return _toSnapshot(payload);
  }

  Future<TrackingLinksResponse> generateTrackingLinks(String deliveryId) async {
    final token = await _readAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw const DeliveryTrackingException(
        'Cloud delivery session is not available on this device.',
      );
    }

    try {
      final uri = _uri('/api/public/tracking/generate-token');
      final request = await _httpClient.openUrl('POST', uri).timeout(
            const Duration(seconds: 12),
          );
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');

      final body = jsonEncode({'deliveryId': deliveryId});
      request.add(utf8.encode(body));

      final response =
          await request.close().timeout(const Duration(seconds: 20));
      final responseBody = await response.transform(utf8.decoder).join();
      debugPrint('[DeliveryService] POST /api/public/tracking/generate-token -> HTTP ${response.statusCode}');
      debugPrint('[DeliveryService] Response: $responseBody');
      final decoded = responseBody.trim().isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(responseBody) as Map<String, dynamic>);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw DeliveryTrackingException(
          _readString(_asMap(decoded['error']), 'message') ??
              'Failed to generate tracking links.',
        );
      }

      return TrackingLinksResponse(
        token: _readString(decoded, 'token') ?? '',
        driverLink: _readString(decoded, 'driverLink') ?? '',
        customerLink: _readString(decoded, 'customerLink') ?? '',
      );
    } on SocketException {
      throw DeliveryTrackingException(_connectionFailureMessage());
    }
  }

  Future<DriverLinkResponse> getDriverLinkByToken(String token) async {
    try {
      final uri = _uri('/api/public/tracking/driver/$token');
      final request = await _httpClient.openUrl('GET', uri).timeout(
            const Duration(seconds: 12),
          );
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);

      final response =
          await request.close().timeout(const Duration(seconds: 20));
      final responseBody = await response.transform(utf8.decoder).join();
      final decoded = responseBody.trim().isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(responseBody) as Map<String, dynamic>);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw DeliveryTrackingException(
          _readString(_asMap(decoded['error']), 'message') ??
              'Failed to get driver link.',
        );
      }

      return DriverLinkResponse(
        deliveryId: _readString(decoded, 'deliveryId') ?? '',
        orderId: _readString(decoded, 'orderId') ?? '',
        orderNumber: _readString(decoded, 'orderNumber') ?? '',
        customerName: _readString(decoded, 'customerName') ?? '',
        recipientName: _readString(decoded, 'recipientName') ?? '',
        deliveryAddress: _readString(decoded, 'deliveryAddress') ?? '',
        destinationLatitude: _readDouble(decoded, 'destinationLatitude'),
        destinationLongitude: _readDouble(decoded, 'destinationLongitude'),
        customerPhone: _readString(decoded, 'customerPhone'),
        timeSlot: _readString(decoded, 'timeSlot') ?? '',
        status: _readString(decoded, 'status') ?? '',
        trackingToken: _readString(decoded, 'trackingToken') ?? '',
        mapsUrl: _readString(decoded, 'mapsUrl'),
      );
    } on SocketException {
      throw DeliveryTrackingException(_connectionFailureMessage());
    }
  }

  Future<bool> updateDeliveryStatus(String token, String status) async {
    try {
      final uri = _uri('/api/public/tracking/driver/status');
      final request = await _httpClient.openUrl('POST', uri).timeout(
            const Duration(seconds: 12),
          );
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);

      final body = jsonEncode({
        'trackingToken': token,
        'status': status,
      });
      request.add(utf8.encode(body));

      final response =
          await request.close().timeout(const Duration(seconds: 20));
      final responseBody = await response.transform(utf8.decoder).join();
      final decoded = responseBody.trim().isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(responseBody) as Map<String, dynamic>);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw DeliveryTrackingException(
          _readString(_asMap(decoded['error']), 'message') ??
              'Failed to update delivery status.',
        );
      }

      final success = decoded['success'];
      return success is bool && success;
    } on SocketException {
      throw DeliveryTrackingException(_connectionFailureMessage());
    }
  }

  Future<bool> uploadDriverLocation({
    required String token,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? speed,
    double? heading,
    DateTime? recordedAt,
    String? driverMobile,
  }) async {
    try {
      final uri = _uri('/api/public/tracking/driver/location');
      final request = await _httpClient.openUrl('POST', uri).timeout(
            const Duration(seconds: 12),
          );
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);

      final body = jsonEncode({
        'trackingToken': token,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'speed': speed,
        'heading': heading,
        'recordedAt': recordedAt?.toIso8601String(),
        'driverMobile': driverMobile,
      });
      request.add(utf8.encode(body));

      final response =
          await request.close().timeout(const Duration(seconds: 20));
      final responseBody = await response.transform(utf8.decoder).join();
      final decoded = responseBody.trim().isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(responseBody) as Map<String, dynamic>);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw DeliveryTrackingException(
          _readString(_asMap(decoded['error']), 'message') ??
              'Failed to upload location.',
        );
      }

      final success = decoded['success'];
      return success is bool && success;
    } on SocketException {
      throw DeliveryTrackingException(_connectionFailureMessage());
    }
  }

  Stream<DeliveryTrackingSnapshot> watchTracking(
      DeliveryTrackingSnapshot seed) {
    final controller = StreamController<DeliveryTrackingSnapshot>();
    WebSocketChannel? socket;
    StreamSubscription<dynamic>? socketSub;
    Timer? pollingTimer;
    var current = seed;

    Future<void> refreshWithPolling() async {
      try {
        // Only use assignmentId - orderId-based tracking is obsolete
        if (current.assignmentId.trim().isEmpty) {
          throw const DeliveryTrackingException(
            'No assignment ID available for tracking.',
          );
        }
        final next = await getTrackingByAssignmentId(current.assignmentId);
        current = next;
        if (!controller.isClosed) {
          controller.add(current);
        }
      } on Object catch (error) {
        if (!controller.isClosed) {
          controller.addError(error);
        }
      }
    }

    Future<void> attach() async {
      final accessToken = await _readAccessToken();
      if (accessToken == null || accessToken.trim().isEmpty) {
        controller.add(current);
        pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
          refreshWithPolling();
        });
        return;
      }

      try {
        final wsUri = _webSocketUri(_trackingHubPath, token: accessToken);
        socket = WebSocketChannel.connect(wsUri);
        socketSub = socket!.stream.listen(
          (raw) {
            final decoded = _decodeSocketMessage(raw);
            if (decoded.isEmpty) return;

            final event = _readString(decoded, 'event') ??
                _readString(decoded, 'type') ??
                _readString(decoded, 'name');
            final payload =
                _asMap(decoded['payload'] ?? decoded['data'] ?? decoded);
            final envelopePayload =
                _asMap(payload['payload'] ?? payload['data']);
            final payloadToUse =
                envelopePayload.isNotEmpty ? envelopePayload : payload;

            final eventName = (event ?? '').toLowerCase();
            if (eventName.contains('status')) {
              final assignment = _readString(payloadToUse, 'assignmentId');
              if (assignment != null && assignment != current.assignmentId) {
                return;
              }
              final status = _readString(payloadToUse, 'status');
              final timelineEvent = DeliveryTimelineEvent(
                status: status ?? current.status,
                recordedAt: _readDate(payload, 'recordedAt') ?? DateTime.now(),
                note: _readString(payloadToUse, 'note'),
              );
              final timeline =
                  List<DeliveryTimelineEvent>.from(current.timeline)
                    ..insert(0, timelineEvent);
              current = current.copyWith(status: status, timeline: timeline);
              controller.add(current);
              return;
            }

            if (eventName.contains('proof')) {
              final assignment = _readString(payload, 'assignmentId');
              if (assignment != null && assignment != current.assignmentId) {
                return;
              }
              final proof = _toProof(payloadToUse);
              if (proof == null) return;
              current = current.copyWith(proof: proof);
              controller.add(current);
              return;
            }

            final assignment = _readString(payloadToUse, 'assignmentId');
            if (assignment != null && assignment != current.assignmentId) {
              return;
            }
            final location = _toLocation(payloadToUse);
            if (location == null) return;
            final route = List<DeliveryLocationPoint>.from(current.route)
              ..add(location);
            current = current.copyWith(lastLocation: location, route: route);
            controller.add(current);
          },
          onError: (_) {
            pollingTimer ??= Timer.periodic(const Duration(seconds: 15), (_) {
              refreshWithPolling();
            });
          },
          cancelOnError: false,
        );

        socket!.sink.add(jsonEncode({
          'action': 'subscribe',
          'channel': 'order_tracking',
          'orderId': current.orderId,
          'assignmentId': current.assignmentId,
        }));

        controller.add(current);
      } on SocketException {
        controller.add(current);
        pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
          refreshWithPolling();
        });
      }
    }

    attach();

    controller.onCancel = () async {
      final active = socket;
      socket = null;
      pollingTimer?.cancel();
      await socketSub?.cancel();
      if (active != null) {
        active.sink.add(jsonEncode({
          'action': 'unsubscribe',
          'channel': 'order_tracking',
          'orderId': seed.orderId,
          'assignmentId': seed.assignmentId,
        }));
        await active.sink.close();
      }
    };

    return controller.stream;
  }

  Stream<DeliveryTrackingSnapshot> watchPublicTrackingByLink(
    String trackingLink,
    DeliveryTrackingSnapshot seed, {
    Duration interval = const Duration(seconds: 15),
  }) {
    final controller = StreamController<DeliveryTrackingSnapshot>();
    Timer? timer;
    var current = seed;

    Future<void> refresh() async {
      try {
        final next = await getPublicTrackingByLink(trackingLink);
        current = next;
        if (!controller.isClosed) {
          controller.add(current);
        }
      } on Object catch (error) {
        if (!controller.isClosed) {
          controller.addError(error);
        }
      }
    }

    controller.onListen = () {
      controller.add(current);
      timer = Timer.periodic(interval, (_) {
        refresh();
      });
    };

    controller.onCancel = () async {
      timer?.cancel();
    };

    return controller.stream;
  }

  Future<String?> _readAccessToken() async {
    // Use the stored token directly — avoids a network round-trip on every call.
    final stored = await _auth.getStoredAccessToken();
    if (stored != null && stored.trim().isNotEmpty) return stored;

    // No stored token: attempt a refresh once as a fallback.
    try {
      final refreshed = await _auth.refreshAndBootstrap();
      return refreshed.accessToken;
    } on Object {
      return _provisionDeviceSessionFromLocalShop();
    }
  }

  Future<String?> _provisionDeviceSessionFromLocalShop() async {
    try {
      final settings = await BusinessSettingsManager().load();
      final mobile = settings.phone.replaceAll(RegExp(r'[^0-9]'), '');
      final shopName = settings.shopName.trim();
      if (shopName.isEmpty ||
          shopName == 'My Flower Shop' ||
          mobile.length < 8) {
        return null;
      }

      final payload = await _auth.register(
        companyName: shopName,
        ownerName: settings.ownerName.trim().isEmpty
            ? shopName
            : settings.ownerName.trim(),
        mobile: mobile,
        address: settings.address.trim(),
        city: '',
        email: _buildProvisioningEmail(mobile),
        password: _buildProvisioningPassword(mobile),
      );
      return payload.accessToken;
    } on Object catch (error) {
      debugPrint('[DeliveryService] Silent device provisioning failed: $error');
      return null;
    }
  }

  String _buildProvisioningEmail(String mobile) {
    final digits = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    final safeMobile = digits.isEmpty ? 'device' : digits;
    return 'auto.$safeMobile@floraprise.local';
  }

  String _buildProvisioningPassword(String mobile) {
    final digits = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    final normalized = digits.padLeft(10, '0');
    final tail = normalized.substring(normalized.length - 6);
    return 'Fp@$tail#2026';
  }

  Future<Map<String, dynamic>> _getJson(String path) async {
    return _getJsonWithToken(path, retryOnUnauthorized: true);
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, Object?> body,
  ) async {
    return _sendJsonWithToken(
      'POST',
      path,
      body: body,
      retryOnUnauthorized: true,
    );
  }

  Future<Map<String, dynamic>> _getJsonWithToken(
    String path, {
    bool retryOnUnauthorized = false,
    String? bearerToken,
  }) async {
    final token = bearerToken ?? await _readAccessToken();
    final uri = _uri(path);

    if (token == null || token.trim().isEmpty) {
      throw const DeliveryTrackingException(
        'Cloud delivery session is not available on this device. Register the shop/device or use account recovery when cloud services are needed.',
      );
    }

    final requestHeaders = <String, List<String>>{
      HttpHeaders.acceptHeader: [ContentType.json.mimeType],
      HttpHeaders.authorizationHeader: ['Bearer $token'],
    };

    debugPrint('[DeliveryService] Request URL: $uri');
    debugPrint('[DeliveryService] Request Method: GET');
    debugPrint(
      '[DeliveryService] Authorization header present: ${requestHeaders.containsKey(HttpHeaders.authorizationHeader)}',
    );

    try {
      final request = await _httpClient.openUrl('GET', uri).timeout(
            const Duration(seconds: 12),
          );
      for (final entry in requestHeaders.entries) {
        request.headers.set(entry.key, entry.value);
      }

      final response =
          await request.close().timeout(const Duration(seconds: 20));
      final body = await response.transform(utf8.decoder).join();
      final responseHeaders = <String, List<String>>{};
      response.headers.forEach((name, values) {
        responseHeaders[name] = values;
      });

      debugPrint('[DeliveryService] Response Status: ${response.statusCode}');
      debugPrint(
          '[DeliveryService] Response Headers: ${jsonEncode(responseHeaders)}');
      debugPrint('[DeliveryService] Raw Response Body: $body');

      // Refresh token and retry once on 401
      if (response.statusCode == 401 && retryOnUnauthorized) {
        debugPrint(
            '[DeliveryService] 401 received; refreshing token and retrying with the new access token');
        try {
          final refreshed = await _auth.refreshAndBootstrap();
          if (refreshed.accessToken.isNotEmpty) {
            debugPrint('[DeliveryService] Token refresh succeeded.');
            return _getJsonWithToken(
              path,
              retryOnUnauthorized: false,
              bearerToken: refreshed.accessToken,
            );
          }
        } on Object catch (e) {
          debugPrint('[DeliveryService] Token refresh failed: $e');
          throw const DeliveryTrackingException(
              'Cloud delivery session expired and could not be refreshed. Use device recovery when cloud services are needed.');
        }
      }

      final decoded = body.trim().isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(body) as Map<String, dynamic>);

      debugPrint('[DeliveryService] Decoded JSON: ${jsonEncode(decoded)}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final serverMsg = _readString(_asMap(decoded['error']), 'message') ??
            _readString(decoded, 'title') ??
            _readString(decoded, 'detail') ??
            'HTTP ${response.statusCode}';
        throw DeliveryTrackingException(serverMsg);
      }

      final success = decoded['success'];
      if (success is bool && !success) {
        throw DeliveryTrackingException(
          _readString(_asMap(decoded['error']), 'message') ??
              'Failed to load delivery data.',
        );
      }

      final data = decoded['data'];
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return data.cast<String, dynamic>();
      return decoded;
    } on SocketException catch (e) {
      debugPrint('[DeliveryService] SocketException: $e');
      throw DeliveryTrackingException(_connectionFailureMessage());
    } on DeliveryTrackingException {
      rethrow;
    } on Object catch (e) {
      debugPrint('[DeliveryService] Unexpected error: $e');
      throw DeliveryTrackingException('Unexpected error: $e');
    }
  }

  Future<Map<String, dynamic>> _sendJsonWithToken(
    String method,
    String path, {
    Map<String, Object?>? body,
    bool retryOnUnauthorized = false,
    String? bearerToken,
  }) async {
    final token = bearerToken ?? await _readAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw const DeliveryTrackingException(
        'Cloud delivery session is not available on this device. Register the shop/device or use account recovery when cloud services are needed.',
      );
    }

    try {
      final request = await _httpClient.openUrl(method, _uri(path)).timeout(
            const Duration(seconds: 12),
          );
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      if (body != null) {
        request.add(utf8.encode(jsonEncode(body)));
      }

      final response =
          await request.close().timeout(const Duration(seconds: 20));
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 401 && retryOnUnauthorized) {
        final refreshed = await _auth.refreshAndBootstrap();
        return _sendJsonWithToken(
          method,
          path,
          body: body,
          retryOnUnauthorized: false,
          bearerToken: refreshed.accessToken,
        );
      }

      final decoded = responseBody.trim().isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(responseBody) as Map<String, dynamic>);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw DeliveryTrackingException(
          _readString(_asMap(decoded['error']), 'message') ??
              _readString(decoded, 'title') ??
              _readString(decoded, 'detail') ??
              'HTTP ${response.statusCode}',
        );
      }

      final data = decoded['data'];
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return data.cast<String, dynamic>();
      return decoded;
    } on SocketException catch (e) {
      throw DeliveryTrackingException('Network unavailable: $e');
    } on DeliveryTrackingException {
      rethrow;
    } on Object catch (e) {
      throw DeliveryTrackingException('Unexpected error: $e');
    }
  }

  Future<Map<String, dynamic>> _getPublicJsonFromLink(
      String trackingLink) async {
    try {
      final uri = _publicTrackingPayloadUri(trackingLink);
      final request = await _httpClient.openUrl('GET', uri).timeout(
            const Duration(seconds: 12),
          );
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);

      final response =
          await request.close().timeout(const Duration(seconds: 20));
      final body = await response.transform(utf8.decoder).join();
      final decoded = body.trim().isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(body) as Map<String, dynamic>);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw DeliveryTrackingException(
          _readString(_asMap(decoded['error']), 'message') ??
              'Failed to load public tracking.',
        );
      }

      final success = decoded['success'];
      if (success is bool && !success) {
        throw DeliveryTrackingException(
          _readString(_asMap(decoded['error']), 'message') ??
              'Failed to load public tracking.',
        );
      }

      final data = decoded['data'];
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return data.cast<String, dynamic>();
      return decoded;
    } on SocketException {
      throw DeliveryTrackingException(_connectionFailureMessage());
    }
  }

  String _connectionFailureMessage() {
    return 'Unable to connect to the server. Please check your internet connection and try again.';
  }

  DeliveryWorkspaceRecord _toWorkspaceRecord(Map<String, dynamic> map) {
    return DeliveryWorkspaceRecord(
      assignmentId: _readString(map, 'assignmentId') ?? '',
      orderId: _readString(map, 'orderId') ?? '',
      orderNo: _readString(map, 'orderNo') ?? '-',
      customerName: _readString(map, 'customerName') ?? '-',
      recipientName: _readString(map, 'recipientName') ?? '-',
      deliveryAddress: _readString(map, 'deliveryAddress') ?? '-',
      deliveryArea: _readString(map, 'deliveryArea') ?? '-',
      customerPhone: _readString(map, 'customerPhone'),
      deliveryTime: _readString(map, 'deliveryTime') ?? '-',
      status: _readString(map, 'status') ?? 'assigned',
      trackingLink: _readString(map, 'trackingLink') ?? '',
      eta: _readDate(map, 'eta'),
      updatedAt: _readDate(map, 'updatedAt') ?? DateTime.now(),
      driver: _toDriver(_asMap(map['driver'])),
    );
  }

  DeliveryWorkspaceRecord _toLocalWorkspaceRecord(Map<String, Object?> row) {
    final orderId = row['id'] as int? ?? 0;
    final scheduledAt = _parseLocalDate(row['scheduled_at']);
    final updatedAt = _parseLocalDate(row['updated_at']) ?? DateTime.now();

    return DeliveryWorkspaceRecord(
      assignmentId: 'local:$orderId',
      orderId: '$orderId',
      orderNo: (row['order_no'] as String?) ?? 'ORD-$orderId',
      customerName: (row['customer_name'] as String?) ?? '-',
      recipientName: (row['recipient_name'] as String?) ??
          (row['customer_name'] as String?) ??
          '-',
      deliveryAddress: (row['delivery_address'] as String?) ?? '-',
      deliveryArea: (row['delivery_pincode'] as String?) ?? '-',
      customerPhone: (row['recipient_phone'] as String?) ??
          (row['customer_phone'] as String?),
      deliveryTime: _localDeliveryTime(row, scheduledAt),
      status: _cloudStatusForLocalOrder((row['status'] as String?) ?? ''),
      trackingLink: '',
      eta: scheduledAt,
      updatedAt: updatedAt,
      driver: null, // Local workspace no longer shows driver info - use cloud
    );
  }

  String _cloudStatusForLocalOrder(String status) {
    return switch (status) {
      'out_for_delivery' => 'OutForDelivery',
      'delivered' => 'Delivered',
      'cancelled' => 'Cancelled',
      'delivery_failed' => 'Failed',
      'ready' || 'confirmed' || 'sent_to_designer' => 'Assigned',
      'preparing' => 'Accepted',
      _ => 'Assigned',
    };
  }

  String _localDeliveryTime(Map<String, Object?> row, DateTime? scheduledAt) {
    final slot = (row['delivery_slot'] as String?)?.trim() ?? '';
    if (slot.isNotEmpty) return slot;
    if (scheduledAt == null) return '-';
    return scheduledAt.toLocal().toString().split('.').first;
  }

  DateTime? _parseLocalDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  DeliveryTrackingSnapshot _toSnapshot(Map<String, dynamic> map) {
    final routeRows = _asList(map['route'] ?? map['locations']);
    final route = routeRows
        .map(_toLocationMap)
        .whereType<DeliveryLocationPoint>()
        .toList();
    final timelineRows = _asList(map['timeline'] ?? map['events']);
    final timeline = timelineRows
        .map(_toTimelineMap)
        .whereType<DeliveryTimelineEvent>()
        .toList();

    final proofMap = _asMap(map['proof'] ?? map['deliveryProof']);
    final proof = _toProof(proofMap);
    final last = _toLocationMap(_asMap(map['lastLocation'])) ??
        (route.isEmpty ? null : route.last);

    return DeliveryTrackingSnapshot(
      assignmentId: _readString(map, 'assignmentId') ?? '',
      orderId: _readInt(map, 'orderId') ?? 0,
      trackingId: _readString(map, 'trackingId') ?? '',
      trackingLink: _readString(map, 'trackingLink') ?? '',
      status: _readString(map, 'status') ?? 'assigned',
      eta: _readDate(map, 'eta'),
      driver: _toDriver(_asMap(map['driver'])),
      route: route,
      timeline: timeline,
      proof: proof,
      lastLocation: last,
    );
  }

  DeliveryDriverInfo? _toDriver(Map<String, dynamic> map) {
    if (map.isEmpty) return null;
    final name =
        _readString(map, 'name') ?? _readString(map, 'driverName') ?? '';
    final phone =
        _readString(map, 'phone') ?? _readString(map, 'driverPhone') ?? '';
    if (name.isEmpty && phone.isEmpty) return null;
    return DeliveryDriverInfo(
      name: name.isEmpty ? '-' : name,
      phone: phone.isEmpty ? '-' : phone,
      vehicle: _readString(map, 'vehicle'),
    );
  }

  DeliveryProof? _toProof(Map<String, dynamic> map) {
    if (map.isEmpty) return null;
    final photoUrl = _readString(map, 'photoUrl') ??
        _readString(map, 'deliveryProofPhotoPath') ??
        '';
    final otpVerified = _readBool(map, 'otpVerified') ??
        _readBool(map, 'isOtpVerified') ??
        _readBool(map, 'otpMatched');
    final signatureCaptured = _readBool(map, 'signatureCaptured') ??
        _readBool(map, 'isSignatureCaptured');
    final signatureValue = _readString(map, 'signature') ??
        _readString(map, 'signatureData') ??
        _readString(map, 'signatureUrl');
    final hasAnyProof = photoUrl.isNotEmpty ||
        otpVerified == true ||
        signatureCaptured == true ||
        (signatureValue != null && signatureValue.trim().isNotEmpty);
    if (!hasAnyProof) return null;

    return DeliveryProof(
      photoUrl: photoUrl,
      note: _readString(map, 'note'),
      recipientName: _readString(map, 'recipientName'),
      recordedAt: _readDate(map, 'recordedAt'),
      otpVerified: otpVerified,
      signatureCaptured: signatureCaptured,
      signatureValue: signatureValue,
    );
  }

  DeliveryLocationPoint? _toLocation(Map<String, dynamic> map) {
    return _toLocationMap(map);
  }

  DeliveryLocationPoint? _toLocationMap(Map<String, dynamic> map) {
    if (map.isEmpty) return null;
    final lat = _readDouble(map, 'latitude');
    final lng = _readDouble(map, 'longitude');
    if (lat == null || lng == null) return null;

    return DeliveryLocationPoint(
      latitude: lat,
      longitude: lng,
      speedKph: _readDouble(map, 'speedKph') ?? 0,
      recordedAt: _readDate(map, 'recordedAt') ?? DateTime.now(),
      accuracyMeters:
          _readDouble(map, 'accuracy') ?? _readDouble(map, 'accuracyMeters'),
      batteryPercentage:
          _readInt(map, 'batteryLevel') ?? _readInt(map, 'batteryPercentage'),
    );
  }

  DeliveryTimelineEvent? _toTimelineMap(Map<String, dynamic> map) {
    if (map.isEmpty) return null;
    final status = _readString(map, 'status');
    if (status == null || status.trim().isEmpty) return null;
    return DeliveryTimelineEvent(
      status: status,
      recordedAt: _readDate(map, 'recordedAt') ?? DateTime.now(),
      note: _readString(map, 'note'),
    );
  }

  Uri _uri(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Uri.parse(path);
    }
    return Uri.parse('$_baseUrl$path');
  }

  Uri _publicTrackingPayloadUri(String trackingLink) {
    final uri = Uri.parse(trackingLink);
    if (uri.path.endsWith('/payload')) {
      return uri;
    }

    final segments = List<String>.from(uri.pathSegments);
    if (segments.isEmpty) {
      return uri.replace(path: '/payload');
    }

    return uri.replace(pathSegments: [...segments, 'payload']);
  }

  Uri _webSocketUri(String path, {required String token}) {
    final base = Uri.parse(_baseUrl);
    final wsScheme = base.scheme == 'https' ? 'wss' : 'ws';
    return Uri(
      scheme: wsScheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: path,
      queryParameters: {'access_token': token},
    );
  }

  Future<void> _appendQueuedLocation(
    String key,
    _QueuedDeliveryLocation location,
  ) async {
    final pending = await _readQueuedLocations(key);
    pending.add(location);
    await _writeQueuedLocations(key, pending);
  }

  Future<List<_QueuedDeliveryLocation>> _readQueuedLocations(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.trim().isEmpty) return <_QueuedDeliveryLocation>[];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <_QueuedDeliveryLocation>[];
      return decoded
          .map((item) => _QueuedDeliveryLocation.fromJson(_asMap(item)))
          .whereType<_QueuedDeliveryLocation>()
          .toList();
    } on Object {
      return <_QueuedDeliveryLocation>[];
    }
  }

  Future<void> _writeQueuedLocations(
    String key,
    List<_QueuedDeliveryLocation> locations,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (locations.isEmpty) {
      await prefs.remove(key);
      return;
    }

    await prefs.setString(
      key,
      jsonEncode(locations.map((item) => item.toJson()).toList()),
    );
  }

  Map<String, dynamic> _decodeSocketMessage(dynamic raw) {
    try {
      if (raw is String) {
        return _asMap(jsonDecode(raw));
      }
      return _asMap(raw);
    } on Object {
      return <String, dynamic>{};
    }
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return <String, dynamic>{};
  }

  static List<Map<String, dynamic>> _asList(Object? value) {
    if (value is! List) return const [];
    return value.map((row) => _asMap(row)).toList();
  }

  static String? _readString(Map<String, dynamic> map, String key) {
    final value = map[key] ?? map[_pascalCase(key)];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int? _readInt(Map<String, dynamic> map, String key) {
    final value = map[key] ?? map[_pascalCase(key)];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  static double? _readDouble(Map<String, dynamic> map, String key) {
    final value = map[key] ?? map[_pascalCase(key)];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value == null) return null;
    return double.tryParse(value.toString());
  }

  static bool? _readBool(Map<String, dynamic> map, String key) {
    final value = map[key] ?? map[_pascalCase(key)];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value == null) return null;

    final normalized = value.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
    return null;
  }

  static DateTime? _readDate(Map<String, dynamic> map, String key) {
    final value = map[key] ?? map[_pascalCase(key)];
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static String _pascalCase(String key) {
    if (key.isEmpty) return key;
    return '${key[0].toUpperCase()}${key.substring(1)}';
  }
}

class _QueuedDeliveryLocation {
  const _QueuedDeliveryLocation({
    required this.reference,
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    this.accuracy,
    this.speed,
    this.heading,
  });

  final String reference;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? speed;
  final double? heading;
  final DateTime recordedAt;

  Map<String, Object?> toJson() => {
        'reference': reference,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'speed': speed,
        'heading': heading,
        'recordedAt': recordedAt.toIso8601String(),
      };

  static _QueuedDeliveryLocation? fromJson(Map<String, dynamic> map) {
    final reference = map['reference']?.toString() ?? '';
    final latitude = DeliveryTrackingService._readDouble(map, 'latitude');
    final longitude = DeliveryTrackingService._readDouble(map, 'longitude');
    final recordedAt = DeliveryTrackingService._readDate(map, 'recordedAt');
    if (reference.isEmpty || latitude == null || longitude == null) {
      return null;
    }

    return _QueuedDeliveryLocation(
      reference: reference,
      latitude: latitude,
      longitude: longitude,
      accuracy: DeliveryTrackingService._readDouble(map, 'accuracy'),
      speed: DeliveryTrackingService._readDouble(map, 'speed'),
      heading: DeliveryTrackingService._readDouble(map, 'heading'),
      recordedAt: recordedAt ?? DateTime.now().toUtc(),
    );
  }
}

class TrackingLinksResponse {
  const TrackingLinksResponse({
    required this.token,
    required this.driverLink,
    required this.customerLink,
  });

  final String token;
  final String driverLink;
  final String customerLink;
}

class DriverLinkResponse {
  const DriverLinkResponse({
    required this.deliveryId,
    required this.orderId,
    required this.orderNumber,
    required this.customerName,
    required this.recipientName,
    required this.deliveryAddress,
    this.destinationLatitude,
    this.destinationLongitude,
    this.customerPhone,
    required this.timeSlot,
    required this.status,
    required this.trackingToken,
    this.mapsUrl,
  });

  final String deliveryId;
  final String orderId;
  final String orderNumber;
  final String customerName;
  final String recipientName;
  final String deliveryAddress;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final String? customerPhone;
  final String timeSlot;
  final String status;
  final String trackingToken;
  final String? mapsUrl;
}
