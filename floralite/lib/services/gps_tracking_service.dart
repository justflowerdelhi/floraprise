import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';

class Guid {
  static String? tryParse(String? input) {
    final value = input?.trim() ?? '';
    return value.isEmpty ? null : value;
  }
}

class LocationUpdate {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? speed;
  final double? heading;
  final double? altitude;
  final int? batteryLevel;
  final DateTime recordedAt;

  LocationUpdate({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.speed,
    this.heading,
    this.altitude,
    this.batteryLevel,
    required this.recordedAt,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'speed': speed,
    'heading': heading,
    'altitude': altitude,
    'batteryLevel': batteryLevel,
    'recordedAt': recordedAt.toIso8601String(),
  };
}

class GPSTrackingService {
  static const String _trackingActiveKey = 'gps_tracking_active';
  static const String _currentDeliveryIdKey = 'current_delivery_id';
  static const int _uploadIntervalSeconds = 15;
  static const double _minDistanceMeters = 25.0;

  StreamSubscription<Position>? _positionSubscription;
  Timer? _uploadTimer;
  final List<LocationUpdate> _offlineQueue = [];
  final AuthService _authService = AuthService();
  
  bool _isTracking = false;
  Guid? _currentDeliveryId;
  DateTime? _lastUploadTime;
  Position? _lastPosition;

  final _locationUpdateController = StreamController<LocationUpdate>.broadcast();
  Stream<LocationUpdate> get locationUpdates => _locationUpdateController.stream;

  bool get isTracking => _isTracking;
  Guid? get currentDeliveryId => _currentDeliveryId;

  Future<bool> checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<void> startTracking(Guid deliveryId) async {
    if (_isTracking) {
      debugPrint('GPS tracking already active');
      return;
    }

    final hasPermission = await checkLocationPermission();
    if (!hasPermission) {
      throw Exception('Location permission denied');
    }

    _currentDeliveryId = deliveryId;
    _isTracking = true;

    // Save state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_trackingActiveKey, true);
    await prefs.setString(_currentDeliveryIdKey, deliveryId.toString());

    // Start high-accuracy position stream
    final locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: _minDistanceMeters,
      forceLocationManager: true,
      intervalDuration: const Duration(seconds: 5),
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _onPositionUpdate(position);
      },
      onError: (error) {
        debugPrint('GPS error: $error');
      },
    );

    // Start upload timer
    _uploadTimer = Timer.periodic(
      const Duration(seconds: _uploadIntervalSeconds),
      (_) => _uploadLocation(),
    );

    debugPrint('GPS tracking started for delivery: $deliveryId');
  }

  void _onPositionUpdate(Position position) {
    final update = LocationUpdate(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      speed: position.speed,
      heading: position.heading,
      altitude: position.altitude,
      recordedAt: DateTime.now(),
    );

    _lastPosition = position;
    _locationUpdateController.add(update);

    // Check if should upload immediately (significant distance change)
    if (_lastPosition != null) {
      final distance = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      
      if (distance >= _minDistanceMeters) {
        _uploadLocation();
      }
    }
  }

  Future<void> _uploadLocation() async {
    if (_lastPosition == null || _currentDeliveryId == null) return;

    final now = DateTime.now();
    _lastUploadTime = now;

    final update = LocationUpdate(
      latitude: _lastPosition!.latitude,
      longitude: _lastPosition!.longitude,
      accuracy: _lastPosition!.accuracy,
      speed: _lastPosition!.speed,
      heading: _lastPosition!.heading,
      altitude: _lastPosition!.altitude,
      recordedAt: now,
    );

    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = connectivityResult != ConnectivityResult.none;

    if (hasInternet) {
      // Upload immediately
      await _uploadToServer(update);
      
      // Upload queued locations
      if (_offlineQueue.isNotEmpty) {
        await _uploadQueuedLocations();
      }
    } else {
      // Queue for offline upload
      _offlineQueue.add(update);
      await _saveOfflineQueue();
      debugPrint('Location queued (offline): ${update.latitude}, ${update.longitude}');
    }
  }

  Future<void> _uploadToServer(LocationUpdate update) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('No auth token');
      }

      final response = await http.post(
        Uri.parse('${_authService.baseUrl}/api/delivery/tracking/location'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'deliveryId': _currentDeliveryId.toString(),
          'latitude': update.latitude,
          'longitude': update.longitude,
          'speedKph': update.speed,
          'accuracy': update.accuracy,
          'heading': update.heading,
          'altitude': update.altitude,
          'batteryLevel': update.batteryLevel,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Location uploaded successfully');
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      _offlineQueue.add(update);
      await _saveOfflineQueue();
    }
  }

  Future<void> _uploadQueuedLocations() async {
    if (_offlineQueue.isEmpty) return;

    try {
      final token = await _authService.getAccessToken();
      if (token == null) return;

      final batch = _offlineQueue.map((update) => {
        return {
          'deliveryId': _currentDeliveryId.toString(),
          'latitude': update.latitude,
          'longitude': update.longitude,
          'speedKph': update.speed,
          'accuracy': update.accuracy,
          'heading': update.heading,
          'altitude': update.altitude,
          'batteryLevel': update.batteryLevel,
        };
      }).toList();

      final response = await http.post(
        Uri.parse('${_authService.baseUrl}/api/delivery/tracking/location/batch'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(batch),
      );

      if (response.statusCode == 200) {
        _offlineQueue.clear();
        await _clearOfflineQueue();
        debugPrint('Queued locations uploaded: ${batch.length}');
      }
    } catch (e) {
      debugPrint('Batch upload error: $e');
    }
  }

  Future<void> _saveOfflineQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = _offlineQueue.map((u) => u.toJson()).toList();
    await prefs.setString('offline_location_queue', jsonEncode(queueJson));
  }

  Future<void> _loadOfflineQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = prefs.getString('offline_location_queue');
    if (queueJson != null) {
      final List<dynamic> decoded = jsonDecode(queueJson);
      _offlineQueue.clear();
      _offlineQueue.addAll(decoded.map((j) => LocationUpdate(
        latitude: j['latitude'],
        longitude: j['longitude'],
        accuracy: j['accuracy'],
        speed: j['speed'],
        heading: j['heading'],
        altitude: j['altitude'],
        batteryLevel: j['batteryLevel'],
        recordedAt: DateTime.parse(j['recordedAt']),
      )));
    }
  }

  Future<void> _clearOfflineQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('offline_location_queue');
  }

  Future<void> stopTracking() async {
    _isTracking = false;
    _currentDeliveryId = null;

    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _uploadTimer?.cancel();
    _uploadTimer = null;

    // Clear state
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_trackingActiveKey);
    await prefs.remove(_currentDeliveryIdKey);

    debugPrint('GPS tracking stopped');
  }

  Future<void> restoreTracking() async {
    final prefs = await SharedPreferences.getInstance();
    final wasTracking = prefs.getBool(_trackingActiveKey) ?? false;
    final deliveryIdStr = prefs.getString(_currentDeliveryIdKey);

    if (wasTracking && deliveryIdStr != null) {
      final deliveryId = Guid(deliveryIdStr);
      await _loadOfflineQueue();
      await startTracking(deliveryId);
      debugPrint('GPS tracking restored for delivery: $deliveryId');
    }
  }

  void dispose() {
    _positionSubscription?.cancel();
    _uploadTimer?.cancel();
    _locationUpdateController.close();
  }
}
