import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/delivery_tracking_service.dart';

class DriverDeliveryScreen extends StatefulWidget {
  const DriverDeliveryScreen({super.key, required this.token});

  final String token;

  @override
  State<DriverDeliveryScreen> createState() => _DriverDeliveryScreenState();
}

class _DriverDeliveryScreenState extends State<DriverDeliveryScreen> {
  final DeliveryTrackingService _service = DeliveryTrackingService();
  final TextEditingController _notesController = TextEditingController();

  DriverLinkResponse? _delivery;
  StreamSubscription<Position>? _positionSubscription;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  bool get _tracking => _positionSubscription != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final delivery = await _service.getDriverLinkByToken(widget.token);
      if (!mounted) return;
      setState(() {
        _delivery = delivery;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _startDelivery() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final status = _normalizeStatus(_delivery?.status ?? '');
      if (status == 'assigned') {
        await _service.updateDeliveryStatus(widget.token, 'Accepted');
      }
      await _service.updateDeliveryStatus(widget.token, 'PickedUp');
      await _service.updateDeliveryStatus(widget.token, 'OutForDelivery');
      await _startGpsPublishing();
      await _load();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _completeDelivery() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _service.updateDeliveryStatus(widget.token, 'Delivered');
      await _stopGpsPublishing();
      await _load();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startGpsPublishing() async {
    await _ensureLocationPermission();
    await _service.flushDriverTokenLocationQueue();
    await _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: _locationSettings(),
    ).listen((position) async {
      try {
        await _service.uploadDriverLocation(
          token: widget.token,
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          speed: position.speed,
          heading: position.heading,
          recordedAt: position.timestamp,
        );
        await _service.flushDriverTokenLocationQueue();
      } catch (_) {
        await _service.queueDriverTokenLocation(
          token: widget.token,
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          speed: position.speed,
          heading: position.heading,
          recordedAt: position.timestamp,
        );
      }
    });
    if (mounted) setState(() {});
  }

  Future<void> _stopGpsPublishing() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    if (mounted) setState(() {});
  }

  Future<void> _ensureLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const DeliveryTrackingException('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const DeliveryTrackingException('Location permission was denied.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const DeliveryTrackingException(
        'Location permission is permanently denied. Enable it in app settings.',
      );
    }
  }

  LocationSettings _locationSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
        intervalDuration: const Duration(seconds: 20),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Floraprise delivery tracking',
          notificationText:
              'Sharing delivery location while this trip is active.',
          enableWakeLock: true,
        ),
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20,
    );
  }

  Future<void> _callCustomer() async {
    final phone = _delivery?.customerPhone;
    if (phone == null || phone.trim().isEmpty) return;
    await launchUrl(Uri.parse('tel:$phone'));
  }

  Future<void> _navigate() async {
    final delivery = _delivery;
    if (delivery == null) return;

    final Uri uri;
    if (delivery.destinationLatitude != null &&
        delivery.destinationLongitude != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${delivery.destinationLatitude},${delivery.destinationLongitude}',
      );
    } else {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(delivery.deliveryAddress)}',
      );
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final delivery = _delivery;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Assignment'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : delivery == null
              ? _MessageView(
                  title: 'Delivery not available',
                  message: _error ?? 'The delivery link could not be loaded.',
                  onRetry: _load,
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_error != null) ...[
                      _InlineError(message: _error!),
                      const SizedBox(height: 12),
                    ],
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    delivery.orderNumber,
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                ),
                                _StatusPill(status: delivery.status),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _DetailRow(
                              icon: Icons.person_outline_rounded,
                              label: 'Customer',
                              value: delivery.customerName,
                            ),
                            _DetailRow(
                              icon: Icons.location_on_outlined,
                              label: 'Address',
                              value: delivery.deliveryAddress,
                            ),
                            _DetailRow(
                              icon: Icons.phone_outlined,
                              label: 'Phone',
                              value: delivery.customerPhone ?? '-',
                            ),
                            _DetailRow(
                              icon: Icons.schedule_rounded,
                              label: 'Time Slot',
                              value: delivery.timeSlot,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _callCustomer,
                            icon: const Icon(Icons.call_outlined),
                            label: const Text('Call Customer'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _navigate,
                            icon: const Icon(Icons.navigation_outlined),
                            label: const Text('Navigate'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Delivery Notes',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _tracking
                                  ? 'GPS publishing is active'
                                  : 'GPS starts after Start Delivery',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 12),
                            if (_canStart(delivery.status))
                              FilledButton.icon(
                                onPressed: _busy ? null : _startDelivery,
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text('Start Delivery'),
                              ),
                            if (_canComplete(delivery.status) || _tracking)
                              FilledButton.icon(
                                onPressed: _busy ? null : _completeDelivery,
                                icon: const Icon(Icons.done_all_rounded),
                                label: const Text('Complete Delivery'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  bool _canStart(String status) {
    final normalized = _normalizeStatus(status);
    return normalized == 'assigned' ||
        normalized == 'accepted' ||
        normalized == 'pickedup';
  }

  bool _canComplete(String status) {
    final normalized = _normalizeStatus(status);
    return normalized == 'outfordelivery' || normalized == 'arrivednearby';
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView(
      {required this.title, required this.message, this.onRetry});

  final String title;
  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(message,
            style: TextStyle(color: colorScheme.onErrorContainer)),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = switch (_normalizeStatus(status)) {
      'assigned' => colorScheme.outline,
      'accepted' => colorScheme.primary,
      'pickedup' => colorScheme.tertiary,
      'outfordelivery' => colorScheme.primary,
      'arrivednearby' => colorScheme.secondary,
      'delivered' => Colors.green.shade700,
      'cancelled' || 'failed' || 'returned' => colorScheme.error,
      _ => colorScheme.outline,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          _readableStatus(status),
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

String _normalizeStatus(String status) {
  return status.replaceAll(RegExp(r'[^A-Za-z]'), '').toLowerCase();
}

String _readableStatus(String status) {
  final compact = status.replaceAllMapped(
    RegExp(r'(?<=[a-z])(?=[A-Z])'),
    (_) => ' ',
  );
  return compact.isEmpty ? 'Unknown' : compact;
}
