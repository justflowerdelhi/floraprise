import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:web_socket_channel/web_socket_channel.dart';

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
  });

  final double latitude;
  final double longitude;
  final DateTime recordedAt;
  final double speedKph;
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
  });

  final String photoUrl;
  final String? note;
  final String? recipientName;
  final DateTime? recordedAt;
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
    required this.status,
    required this.trackingLink,
    required this.eta,
    required this.updatedAt,
    this.driver,
  });

  final String assignmentId;
  final int orderId;
  final String orderNo;
  final String customerName;
  final String recipientName;
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
    String? baseUrl,
    String? trackingHubPath,
  })  : _auth = auth ?? MobileAuthService(),
        _httpClient = httpClient ?? HttpClient(),
        _baseUrl =
            (baseUrl ?? _resolveBaseUrl()).replaceFirst(RegExp(r'/+$'), ''),
        _trackingHubPath = trackingHubPath ?? '/hubs/delivery-tracking';

  final MobileAuthService _auth;
  final HttpClient _httpClient;
  final String _baseUrl;
  final String _trackingHubPath;

  static String _resolveBaseUrl() {
    const explicit =
        String.fromEnvironment('FLORAPRISE_API_URL', defaultValue: '');
    if (explicit.trim().isNotEmpty) {
      return explicit.trim();
    }
    const fallback = String.fromEnvironment('MOBILE_AUTH_BASE_URL',
        defaultValue: 'http://localhost:5148');
    return fallback.trim();
  }

  Future<List<DeliveryWorkspaceRecord>> getWorkspace(String status) async {
    final payload =
        await _getJson('/api/v1/mobile/delivery/workspace?status=$status');
    final rows = _asList(payload['items'] ?? payload['records']);
    return rows.map(_toWorkspaceRecord).toList();
  }

  Future<List<DeliveryWorkspaceRecord>> getActiveDeliveries() async {
    final payload = await _getJson('/api/v1/mobile/delivery/workspace/active');
    final rows = _asList(payload['items'] ?? payload['records']);
    return rows.map(_toWorkspaceRecord).toList();
  }

  Future<DeliveryTrackingSnapshot> getTrackingByOrderId(int orderId) async {
    final payload =
        await _getJson('/api/v1/mobile/delivery/orders/$orderId/tracking');
    return _toSnapshot(payload);
  }

  Future<DeliveryTrackingSnapshot> getTrackingByAssignmentId(
      String assignmentId) async {
    final payload = await _getJson(
        '/api/v1/mobile/delivery/assignments/$assignmentId/tracking');
    return _toSnapshot(payload);
  }

  Future<DeliveryTrackingSnapshot> getPublicTrackingByLink(
    String trackingLink,
  ) async {
    final payload = await _getPublicJsonFromLink(trackingLink);
    return _toSnapshot(payload);
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
        final next = current.assignmentId.trim().isNotEmpty
            ? await getTrackingByAssignmentId(current.assignmentId)
            : await getTrackingByOrderId(current.orderId);
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

            final eventName = (event ?? '').toLowerCase();
            if (eventName.contains('status')) {
              final assignment = _readString(payload, 'assignmentId');
              if (assignment != null && assignment != current.assignmentId) {
                return;
              }
              final status = _readString(payload, 'status');
              final timelineEvent = DeliveryTimelineEvent(
                status: status ?? current.status,
                recordedAt: _readDate(payload, 'recordedAt') ?? DateTime.now(),
                note: _readString(payload, 'note'),
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
              final proof = _toProof(payload);
              if (proof == null) return;
              current = current.copyWith(proof: proof);
              controller.add(current);
              return;
            }

            final assignment = _readString(payload, 'assignmentId');
            if (assignment != null && assignment != current.assignmentId) {
              return;
            }
            final location = _toLocation(payload);
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
    final bootstrap = await _auth.readBootstrap();
    if (bootstrap == null) return null;

    // Token may not exist in bootstrap, fallback to refresh cycle if needed.
    try {
      final refreshed = await _auth.refreshAndBootstrap();
      return refreshed.accessToken;
    } on Object {
      return null;
    }
  }

  Future<Map<String, dynamic>> _getJson(String path) async {
    final token = await _readAccessToken();

    try {
      final uri = _uri(path);
      final request = await _httpClient.openUrl('GET', uri).timeout(
            const Duration(seconds: 12),
          );
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
      if (token != null && token.trim().isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }

      final response =
          await request.close().timeout(const Duration(seconds: 20));
      final body = await response.transform(utf8.decoder).join();
      final decoded = body.trim().isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(body) as Map<String, dynamic>);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw DeliveryTrackingException(
          _readString(_asMap(decoded['error']), 'message') ??
              'Failed to load delivery tracking.',
        );
      }

      final success = decoded['success'];
      if (success is bool && !success) {
        throw DeliveryTrackingException(
          _readString(_asMap(decoded['error']), 'message') ??
              'Failed to load delivery tracking.',
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
    final uri = Uri.tryParse(_baseUrl);
    final host = uri?.host.toLowerCase() ?? '';
    final port = uri?.hasPort == true ? uri!.port : null;

    if (host == 'localhost' || host == '127.0.0.1') {
      final portText = port == null ? '' : ' on port $port';
      return 'Delivery tracking server is not reachable at localhost$portText. Start the API server or configure FLORAPRISE_API_URL to the correct backend address.';
    }

    return 'Delivery tracking server is not reachable right now. Check the backend connection and try again.';
  }

  DeliveryWorkspaceRecord _toWorkspaceRecord(Map<String, dynamic> map) {
    return DeliveryWorkspaceRecord(
      assignmentId: _readString(map, 'assignmentId') ?? '',
      orderId: _readInt(map, 'orderId') ?? 0,
      orderNo: _readString(map, 'orderNo') ?? '-',
      customerName: _readString(map, 'customerName') ?? '-',
      recipientName: _readString(map, 'recipientName') ?? '-',
      status: _readString(map, 'status') ?? 'assigned',
      trackingLink: _readString(map, 'trackingLink') ?? '',
      eta: _readDate(map, 'eta'),
      updatedAt: _readDate(map, 'updatedAt') ?? DateTime.now(),
      driver: _toDriver(_asMap(map['driver'])),
    );
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
    if (photoUrl.isEmpty) return null;
    return DeliveryProof(
      photoUrl: photoUrl,
      note: _readString(map, 'note'),
      recipientName: _readString(map, 'recipientName'),
      recordedAt: _readDate(map, 'recordedAt'),
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
