import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../l10n/app_localizations.dart';
import '../services/gps_tracking_service.dart';
import '../services/auth_service.dart';

class DriverJourneyScreen extends StatefulWidget {
  final String deliveryId;
  final String orderNumber;
  final String customerName;
  final String address;

  const DriverJourneyScreen({
    super.key,
    required this.deliveryId,
    required this.orderNumber,
    required this.customerName,
    required this.address,
  });

  @override
  State<DriverJourneyScreen> createState() => _DriverJourneyScreenState();
}

class _DriverJourneyScreenState extends State<DriverJourneyScreen> {
  late final GPSTrackingService _gpsService;
  final AuthService _authService = AuthService();

  String _status = 'Assigned';
  bool _isTracking = false;
  Position? _currentPosition;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _gpsService = GPSTrackingService(context: context);
    _checkTrackingState();
  }

  Future<void> _checkTrackingState() async {
    await _gpsService.restoreTracking();
    setState(() {
      _isTracking = _gpsService.isTracking;
    });
  }

  Future<void> _acceptDelivery() async {
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getAccessToken();
      final response = await _authService.httpClient.post(
        Uri.parse('${_authService.baseUrl}/api/delivery/journey/accept'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: '{"deliveryId": "${widget.deliveryId}"}',
      );

      if (response.statusCode == 200) {
        setState(() => _status = 'Accepted');
        _showSuccessSnackBar('Delivery accepted');
      } else {
        _showErrorSnackBar('Failed to accept delivery');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startJourney() async {
    // Request location permission
    final hasPermission = await _gpsService.checkLocationPermission();
    if (!hasPermission) {
      _showErrorSnackBar('Location permission is required for tracking');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final token = await _authService.getAccessToken();
      final response = await _authService.httpClient.post(
        Uri.parse('${_authService.baseUrl}/api/delivery/journey/start'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: '{"deliveryId": "${widget.deliveryId}"}',
      );

      if (response.statusCode == 200) {
        setState(() => _status = 'PickedUp');

        // Start GPS tracking
        await _gpsService.startTracking(Guid(widget.deliveryId));
        setState(() => _isTracking = true);

        _showSuccessSnackBar('Journey started - GPS tracking active');
      } else {
        _showErrorSnackBar('Failed to start journey');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markEnRoute() async {
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getAccessToken();
      final response = await _authService.httpClient.post(
        Uri.parse('${_authService.baseUrl}/api/delivery/journey/enroute'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: '{"deliveryId": "${widget.deliveryId}"}',
      );

      if (response.statusCode == 200) {
        setState(() => _status = 'OutForDelivery');
        _showSuccessSnackBar('Marked as en route');
      } else {
        _showErrorSnackBar('Failed to update status');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markArrived() async {
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getAccessToken();
      final response = await _authService.httpClient.post(
        Uri.parse('${_authService.baseUrl}/api/delivery/journey/arrived'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: '{"deliveryId": "${widget.deliveryId}"}',
      );

      if (response.statusCode == 200) {
        setState(() => _status = 'ArrivedNearby');
        _showSuccessSnackBar('Arrived at location');
      } else {
        _showErrorSnackBar('Failed to update status');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeDelivery() async {
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getAccessToken();

      // Get current position for completion coordinates
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (e) {
        debugPrint('Could not get current position: $e');
      }

      final response = await _authService.httpClient.post(
        Uri.parse('${_authService.baseUrl}/api/delivery/journey/complete'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'deliveryId': widget.deliveryId,
          'completionLatitude': position?.latitude,
          'completionLongitude': position?.longitude,
        }),
      );

      if (response.statusCode == 200) {
        // Stop GPS tracking
        await _gpsService.stopTracking();
        setState(() {
          _status = 'Delivered';
          _isTracking = false;
        });

        _showSuccessSnackBar('Delivery completed successfully');

        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        _showErrorSnackBar('Failed to complete delivery');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Journey'),
        actions: [
          if (_isTracking)
            Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.gps_fixed, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text('Tracking',
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivery Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${widget.orderNumber}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Customer: ${widget.customerName}'),
                    const SizedBox(height: 4),
                    Text('Address: ${widget.address}'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildStatusChip(_status),
                        const SizedBox(width: 16),
                        if (_currentPosition != null)
                          Text(
                            'GPS: ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Status Timeline
            _buildStatusTimeline(),
            const SizedBox(height: 24),

            // Action Buttons
            _buildActionButtons(localizations),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Accepted':
        color = Colors.blue;
        break;
      case 'PickedUp':
        color = Colors.orange;
        break;
      case 'OutForDelivery':
        color = Colors.purple;
        break;
      case 'ArrivedNearby':
        color = Colors.teal;
        break;
      case 'Delivered':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(status),
      backgroundColor: color.withValues(alpha: 0.2),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildStatusTimeline() {
    final steps = [
      'Assigned',
      'Accepted',
      'PickedUp',
      'OutForDelivery',
      'ArrivedNearby',
      'Delivered',
    ];

    final currentIndex = steps.indexOf(_status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Progress',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        ...steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isCompleted = index <= currentIndex;
          final isCurrent = index == currentIndex;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? Colors.green : Colors.grey,
                    border: isCurrent
                        ? Border.all(color: Colors.green, width: 3)
                        : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : Text('${index + 1}',
                            style: const TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step,
                        style: TextStyle(
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCompleted ? Colors.green : Colors.grey,
                        ),
                      ),
                      if (isCurrent)
                        const Text(
                          'Current Status',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActionButtons(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_status == 'Assigned')
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _acceptDelivery,
            icon: const Icon(Icons.check_circle),
            label: const Text('Accept Delivery'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        if (_status == 'Accepted')
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _startJourney,
            icon: const Icon(Icons.directions_car),
            label: const Text('Start Journey'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        if (_status == 'PickedUp')
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _markEnRoute,
            icon: const Icon(Icons.local_shipping),
            label: const Text('Mark En Route'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        if (_status == 'OutForDelivery')
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _markArrived,
            icon: const Icon(Icons.location_on),
            label: const Text('Mark Arrived'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        if (_status == 'ArrivedNearby')
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _completeDelivery,
            icon: const Icon(Icons.done_all),
            label: const Text('Complete Delivery'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        if (_status == 'Delivered')
          Card(
            color: Colors.green.withValues(alpha: 0.1),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Delivery Completed',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _gpsService.dispose();
    super.dispose();
  }
}
