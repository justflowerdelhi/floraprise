import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/delivery_tracking_service.dart';

class LiveDeliveryTrackingScreen extends StatefulWidget {
  const LiveDeliveryTrackingScreen({
    super.key,
    this.orderId,
    this.assignmentId,
    this.trackingLink,
    this.publicView = false,
  });

  final int? orderId;
  final String? assignmentId;
  final String? trackingLink;
  final bool publicView;

  @override
  State<LiveDeliveryTrackingScreen> createState() =>
      _LiveDeliveryTrackingScreenState();
}

class _LiveDeliveryTrackingScreenState
    extends State<LiveDeliveryTrackingScreen> {
  final DeliveryTrackingService _trackingService = DeliveryTrackingService();

  DeliveryTrackingSnapshot? _snapshot;
  StreamSubscription<DeliveryTrackingSnapshot>? _streamSub;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    if (widget.publicView &&
        (widget.trackingLink == null || widget.trackingLink!.trim().isEmpty)) {
      setState(() {
        _error = 'Tracking link is missing.';
        _loading = false;
      });
      return;
    }

    if (!widget.publicView &&
        widget.orderId == null &&
        (widget.assignmentId == null || widget.assignmentId!.trim().isEmpty)) {
      setState(() {
        _error = 'Tracking reference is missing.';
        _loading = false;
      });
      return;
    }

    try {
      final snapshot = widget.publicView
          ? await _trackingService.getPublicTrackingByLink(
              widget.trackingLink!,
            )
          : widget.assignmentId != null &&
                  widget.assignmentId!.trim().isNotEmpty
              ? await _trackingService
                  .getTrackingByAssignmentId(widget.assignmentId!)
              : await _trackingService
                  .getTrackingForLocalOrder(widget.orderId!);

      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _loading = false;
      });

      _streamSub?.cancel();
      _streamSub = (widget.publicView
              ? _trackingService.watchPublicTrackingByLink(
                  widget.trackingLink!,
                  snapshot,
                )
              : _trackingService.watchTracking(snapshot))
          .listen((event) {
        if (!mounted) return;
        setState(() => _snapshot = event);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.publicView ? 'Track Your Delivery' : 'Live Delivery Tracking',
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : snapshot == null
                  ? const Center(child: Text('Tracking data unavailable.'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: [
                          _buildMap(snapshot),
                          const SizedBox(height: 12),
                          _buildEtaAndStatus(snapshot),
                          if (widget.publicView) ...[
                            const SizedBox(height: 12),
                            _buildPublicDeliverySummary(snapshot),
                          ],
                          if (!widget.publicView) ...[
                            const SizedBox(height: 12),
                            _buildDriver(snapshot),
                          ],
                          const SizedBox(height: 12),
                          _buildTimeline(snapshot),
                          const SizedBox(height: 12),
                          _buildProof(snapshot),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildMap(DeliveryTrackingSnapshot snapshot) {
    final route = snapshot.route;
    final center = route.isNotEmpty
        ? LatLng(route.last.latitude, route.last.longitude)
        : const LatLng(19.076, 72.8777);

    final polylinePoints =
        route.map((point) => LatLng(point.latitude, point.longitude)).toList();

    return Card(
      child: SizedBox(
        height: 240,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: route.isEmpty ? 11 : 14,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.floraprise.mobile',
            ),
            if (polylinePoints.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: polylinePoints,
                    color: Theme.of(context).colorScheme.primary,
                    strokeWidth: 4,
                  ),
                ],
              ),
            if (route.isNotEmpty)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(route.last.latitude, route.last.longitude),
                    width: 44,
                    height: 44,
                    child: const Icon(Icons.local_shipping_rounded, size: 28),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriver(DeliveryTrackingSnapshot snapshot) {
    final driver = snapshot.driver;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Driver Details',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Name: ${driver?.name ?? '-'}'),
            Text('Phone: ${driver?.phone ?? '-'}'),
            Text('Vehicle: ${driver?.vehicle ?? '-'}'),
          ],
        ),
      ),
    );
  }

  Widget _buildEtaAndStatus(DeliveryTrackingSnapshot snapshot) {
    final eta = snapshot.eta;
    final etaLabel = eta == null
        ? '-'
        : '${eta.day}/${eta.month}/${eta.year} ${eta.hour.toString().padLeft(2, '0')}:${eta.minute.toString().padLeft(2, '0')}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.publicView) ...[
              const Text(
                'Your order is on the way',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text('Live location refreshes automatically.'),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Status',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(snapshot.status),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ETA',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(etaLabel),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPublicDeliverySummary(DeliveryTrackingSnapshot snapshot) {
    final lastLocation = snapshot.lastLocation;
    final lastSeen = lastLocation == null
        ? '-'
        : '${lastLocation.recordedAt.day}/${lastLocation.recordedAt.month} ${lastLocation.recordedAt.hour.toString().padLeft(2, '0')}:${lastLocation.recordedAt.minute.toString().padLeft(2, '0')}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Delivery Updates',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Last location update: $lastSeen'),
            Text('Route points received: ${snapshot.route.length}'),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(DeliveryTrackingSnapshot snapshot) {
    final timeline = snapshot.timeline;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.publicView ? 'Delivery Progress' : 'Status Timeline',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (timeline.isEmpty)
              const Text('No timeline events yet.')
            else
              ...timeline.map(
                (event) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.history, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${event.status} • ${event.recordedAt.day}/${event.recordedAt.month} ${event.recordedAt.hour.toString().padLeft(2, '0')}:${event.recordedAt.minute.toString().padLeft(2, '0')}${widget.publicView || event.note == null || event.note!.isEmpty ? '' : '\n${event.note}'}',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProof(DeliveryTrackingSnapshot snapshot) {
    final proof = snapshot.proof;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Proof of Delivery',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (proof == null)
              Text(widget.publicView
                  ? 'Proof will appear here after delivery is completed.'
                  : 'Proof not uploaded yet.')
            else ...[
              if (proof.photoUrl.isNotEmpty)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    proof.photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Center(child: Text('Proof image unavailable.')),
                  ),
                ),
              const SizedBox(height: 8),
              if (!widget.publicView)
                Text('Recipient: ${proof.recipientName ?? '-'}'),
              Text('Note: ${proof.note ?? '-'}'),
            ],
          ],
        ),
      ),
    );
  }
}
