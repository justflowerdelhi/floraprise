import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/delivery_tracking_service.dart';
import '../utils/whatsapp_phone_utils.dart';

class DeliveryWorkspaceScreen extends StatefulWidget {
  const DeliveryWorkspaceScreen({super.key});

  @override
  State<DeliveryWorkspaceScreen> createState() =>
      _DeliveryWorkspaceScreenState();
}

class _DeliveryWorkspaceScreenState extends State<DeliveryWorkspaceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Workspace'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _DeliveryWorkspaceList(status: 'active'),
          _DeliveryWorkspaceList(status: 'completed'),
          _DeliveryWorkspaceList(status: 'cancelled'),
        ],
      ),
    );
  }
}

class _DeliveryWorkspaceList extends StatefulWidget {
  const _DeliveryWorkspaceList({required this.status});

  final String status;

  @override
  State<_DeliveryWorkspaceList> createState() => _DeliveryWorkspaceListState();
}

class _DeliveryWorkspaceListState extends State<_DeliveryWorkspaceList> {
  final DeliveryTrackingService _service = DeliveryTrackingService();
  late Future<List<DeliveryWorkspaceRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<DeliveryWorkspaceRecord>> _load() {
    return _service.getWorkspace(widget.status);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DeliveryWorkspaceRecord>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _WorkspaceMessage(
            icon: Icons.warning_amber_rounded,
            title: _errorTitle(snapshot.error),
            message: snapshot.error.toString(),
            actionLabel: 'Retry',
            onAction: _refresh,
          );
        }

        final deliveries = snapshot.data ?? const <DeliveryWorkspaceRecord>[];
        if (deliveries.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              children: [
                SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
                _WorkspaceMessage(
                  icon: Icons.local_shipping_outlined,
                  title: _emptyTitle(widget.status),
                  message: _emptyMessage(widget.status),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: deliveries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final delivery = deliveries[index];
              return _DeliveryCard(
                delivery: delivery,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DeliveryWorkspaceDetailScreen(
                        delivery: delivery,
                      ),
                    ),
                  );
                  if (mounted) await _refresh();
                },
              );
            },
          ),
        );
      },
    );
  }

  static String _emptyTitle(String status) {
    return switch (status) {
      'active' => 'No active deliveries',
      'completed' => 'No completed deliveries',
      'cancelled' => 'No cancelled deliveries',
      _ => 'No deliveries',
    };
  }

  static String _emptyMessage(String status) {
    return switch (status) {
      'active' =>
        'Assigned deliveries appear here when they are ready for a driver.',
      'completed' => 'Delivered orders will appear here after closure.',
      'cancelled' => 'Rejected or cancelled deliveries will appear here.',
      _ => 'There are no deliveries for this view.',
    };
  }

  static String _errorTitle(Object? error) {
    final text = error.toString();
    if (text.contains('Cloud delivery session')) {
      return 'Cloud session unavailable';
    }
    if (text.contains('Network')) return 'Network unavailable';
    return 'Delivery request failed';
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.delivery, required this.onTap});

  final DeliveryWorkspaceRecord delivery;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      delivery.orderNo,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  _StatusPill(status: delivery.status),
                ],
              ),
              const SizedBox(height: 12),
              _InfoLine(
                icon: Icons.person_outline_rounded,
                label: delivery.customerName,
              ),
              const SizedBox(height: 8),
              _InfoLine(
                icon: Icons.location_on_outlined,
                label: delivery.deliveryArea,
              ),
              const SizedBox(height: 8),
              _InfoLine(
                icon: Icons.schedule_rounded,
                label: delivery.deliveryTime,
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Icon(
                    Icons.badge_outlined,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      delivery.driver == null
                          ? 'Driver not assigned'
                          : '${delivery.driver!.name} ${delivery.driver!.phone}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DeliveryWorkspaceDetailScreen extends StatefulWidget {
  const DeliveryWorkspaceDetailScreen({super.key, required this.delivery});

  final DeliveryWorkspaceRecord delivery;

  @override
  State<DeliveryWorkspaceDetailScreen> createState() =>
      _DeliveryWorkspaceDetailScreenState();
}

class _DeliveryWorkspaceDetailScreenState
    extends State<DeliveryWorkspaceDetailScreen> {
  final DeliveryTrackingService _service = DeliveryTrackingService();
  DeliveryWorkspaceRecord get delivery => widget.delivery;

  DeliveryTrackingSnapshot? _snapshot;
  StreamSubscription<DeliveryTrackingSnapshot>? _trackingSubscription;
  String? _error;
  bool get _isWaitingToSync =>
      DeliveryTrackingService().isPendingSyncAssignment(delivery.assignmentId);

  @override
  void initState() {
    super.initState();
    if (!_isWaitingToSync) {
      _loadTracking();
    }
  }

  @override
  void dispose() {
    _trackingSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadTracking() async {
    if (_isWaitingToSync) return;
    setState(() => _error = null);
    try {
      final snapshot =
          await _service.getTrackingByAssignmentId(delivery.assignmentId);
      if (!mounted) return;
      setState(() => _snapshot = snapshot);
      await _trackingSubscription?.cancel();
      _trackingSubscription = _service.watchTracking(snapshot).listen(
        (event) {
          if (mounted) setState(() => _snapshot = event);
        },
        onError: (Object error) {
          if (mounted) setState(() => _error = error.toString());
        },
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _callCustomer() async {
    final phone = delivery.customerPhone;
    if (phone == null || phone.trim().isEmpty) return;
    await launchUrl(Uri.parse('tel:$phone'));
  }

  Future<void> _callDriver() async {
    final phone = _snapshot?.driver?.phone ?? delivery.driver?.phone;
    if (phone == null || phone.trim().isEmpty || phone.trim() == '-') return;
    await launchUrl(Uri.parse('tel:$phone'));
  }

  Future<void> _navigate() async {
    final lastLocation = _snapshot?.lastLocation;
    final uri = lastLocation != null
        ? Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=${lastLocation.latitude},${lastLocation.longitude}',
          )
        : Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(delivery.deliveryAddress.trim())}',
          );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _shareCustomerTrackingLink() async {
    final trackingLink =
        (_snapshot?.trackingLink ?? delivery.trackingLink).trim();
    if (trackingLink.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Customer tracking link is not ready yet.')),
      );
      return;
    }

    await Share.share(
      'Track your delivery live for ${delivery.orderNo}:\n$trackingLink',
      subject: 'Floraprise customer tracking link',
    );
  }

  Future<void> _shareDriverPanel() async {
    if (_isWaitingToSync) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Delivery link is available after sync completes.')),
      );
      return;
    }

    String? driverLink;
    try {
      // Generate tracking links - backend reuses existing tokens if available
      final links = await _service.generateTrackingLinks(delivery.assignmentId);
      driverLink = links.driverLink.trim();
    } catch (error) {
      // If link generation fails, log it but still allow sending basic WhatsApp message
      debugPrint('[DeliveryWorkspace] Link generation failed: $error');
    }

    final phone = _snapshot?.driver?.phone ?? delivery.driver?.phone;
    // Send WhatsApp with link if available, or without link if generation failed
    final message = _driverWhatsappMessage(driverLink);
    final primary = WhatsAppPhoneUtils.buildUri(phone, message: message);
    final fallback = WhatsAppPhoneUtils.buildFallbackUri(
      phone,
      message: message,
    );

    final openedPrimary = primary != null &&
        await launchUrl(primary, mode: LaunchMode.externalApplication);
    if (openedPrimary) return;

    final openedFallback = fallback != null &&
        await launchUrl(fallback, mode: LaunchMode.externalApplication);
    if (openedFallback) return;

    await Share.share(message, subject: 'Floraprise delivery link');
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    final status = snapshot?.status ?? delivery.status;
    final normalizedStatus = _normalizeStatus(status);
    final driverAccepted = _isDriverAccepted(normalizedStatus);
    final showSendDeliveryLink = !driverAccepted && !_isWaitingToSync;
    final showMonitoringActions = driverAccepted;
    return Scaffold(
      appBar: AppBar(title: Text(delivery.orderNo)),
      body: ListView(
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
                          delivery.customerName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      _StatusPill(status: status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Customer',
                    value: delivery.recipientName,
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
                    label: 'Delivery Time',
                    value: delivery.deliveryTime,
                  ),
                  _DetailRow(
                    icon: Icons.badge_outlined,
                    label: 'Driver',
                    value: snapshot?.driver?.name ??
                        delivery.driver?.name ??
                        'Driver not assigned',
                  ),
                  _DetailRow(
                    icon: Icons.update_rounded,
                    label: 'Status',
                    value: _statusHeadline(normalizedStatus),
                  ),
                  _DetailRow(
                    icon: Icons.circle,
                    label: 'Driver Connectivity',
                    value: _onlineLabel(snapshot?.lastLocation),
                    valueColor: _onlineColor(snapshot?.lastLocation),
                  ),
                  _DetailRow(
                    icon: Icons.battery_charging_full_rounded,
                    label: 'Battery',
                    value: _batteryLabel(
                      snapshot?.lastLocation?.batteryPercentage,
                    ),
                    valueColor: _batteryColor(
                      snapshot?.lastLocation?.batteryPercentage,
                    ),
                  ),
                  _DetailRow(
                    icon: Icons.my_location_rounded,
                    label: 'Last GPS',
                    value: _lastGpsLabel(snapshot?.lastLocation),
                  ),
                  _DetailRow(
                    icon: Icons.history_rounded,
                    label: 'Last Updated',
                    value: _lastUpdatedLabel(snapshot?.lastLocation),
                  ),
                  _DetailRow(
                    icon: Icons.timer_outlined,
                    label: 'ETA',
                    value: _etaLabel(
                      snapshot?.eta ?? delivery.eta,
                      normalizedStatus,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (normalizedStatus == 'delivered') ...[
            const SizedBox(height: 12),
            _DeliveredSummaryCard(
              deliveredAt: _deliveredAt(snapshot),
              deliveredBy:
                  snapshot?.driver?.name ?? delivery.driver?.name ?? '-',
              hasPhoto: (snapshot?.proof?.photoUrl.trim().isNotEmpty ?? false),
              otpVerified: snapshot?.proof?.otpVerified == true,
              signatureCaptured: snapshot?.proof?.signatureCaptured == true ||
                  ((snapshot?.proof?.signatureValue ?? '').trim().isNotEmpty),
            ),
          ],
          const SizedBox(height: 12),
          if (showSendDeliveryLink) ...[
            OutlinedButton.icon(
              onPressed: _shareDriverPanel,
              icon: const Icon(Icons.send_to_mobile_rounded),
              label: const Text('Send Delivery Link'),
            ),
            const SizedBox(height: 12),
          ],
          if (showMonitoringActions) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _callDriver,
                    icon: const Icon(Icons.support_agent_rounded),
                    label: const Text('Call Driver'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _shareCustomerTrackingLink,
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share Tracking Link'),
                  ),
                ),
              ],
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
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Open Google Map'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          _MonitoringPanel(
            snapshot: snapshot,
            status: normalizedStatus,
            onOpenMap: _navigate,
          ),
          const SizedBox(height: 16),
          _TimelineCard(snapshot: snapshot),
        ],
      ),
    );
  }

  String _etaLabel(DateTime? eta, String normalizedStatus) {
    if (eta == null) {
      return _isDriverAccepted(normalizedStatus)
          ? 'Waiting for GPS start'
          : 'Waiting for driver';
    }
    return DateFormat('dd MMM, h:mm a').format(eta.toLocal());
  }

  String _statusHeadline(String normalizedStatus) {
    return switch (normalizedStatus) {
      'assigned' => 'Waiting for Driver',
      'accepted' => 'Preparing to Start',
      'pickedup' => 'Picked Up',
      'outfordelivery' => 'Out for Delivery',
      'arrivednearby' => 'Arrived Nearby',
      'delivered' => 'Delivered',
      'rejected' => 'Rejected',
      'cancelled' => 'Cancelled',
      _ => delivery.status,
    };
  }

  bool _isDriverAccepted(String normalizedStatus) {
    return normalizedStatus != 'assigned' &&
        normalizedStatus != 'rejected' &&
        normalizedStatus != 'cancelled';
  }

  String _onlineLabel(DeliveryLocationPoint? location) {
    if (location == null) return 'Waiting for Driver Location';
    return _isOnline(location) ? 'Online' : 'Offline';
  }

  Color? _onlineColor(DeliveryLocationPoint? location) {
    if (location == null) return null;
    return _isOnline(location) ? Colors.green : Colors.grey.shade700;
  }

  bool _isOnline(DeliveryLocationPoint location) {
    return DateTime.now().difference(location.recordedAt.toLocal()) <=
        const Duration(minutes: 3);
  }

  String _batteryLabel(int? battery) {
    if (battery == null) return 'Not available';
    return '$battery%';
  }

  Color? _batteryColor(int? battery) {
    if (battery == null) return null;
    if (battery <= 20) return Colors.red;
    if (battery <= 40) return Colors.amber.shade700;
    return Colors.green;
  }

  String _lastGpsLabel(DeliveryLocationPoint? location) {
    if (location == null) return 'Not available';
    return DateFormat('h:mm a').format(location.recordedAt.toLocal());
  }

  String _lastUpdatedLabel(DeliveryLocationPoint? location) {
    if (location == null) return 'Waiting for first ping';
    final diff = DateTime.now().difference(location.recordedAt.toLocal());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} day ago';
  }

  String _driverWhatsappMessage(String? driverLink) {
    final googleMaps =
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(delivery.deliveryAddress.trim())}';
    final phone = (delivery.customerPhone ?? '').trim();
    final slot =
        delivery.deliveryTime.trim().isEmpty ? '-' : delivery.deliveryTime;

    final lines = [
      'FLORAPRISE DELIVERY',
      '',
      'Order: ${delivery.orderNo}',
      '',
      'Recipient',
      delivery.recipientName.trim().isEmpty ? '-' : delivery.recipientName,
      '',
      'Customer',
      delivery.customerName,
      '',
      'Phone',
      phone.isEmpty ? '-' : phone,
      '',
      'Address',
      delivery.deliveryAddress,
      '',
      'Time Slot',
      slot,
      '',
      'Google Maps',
      googleMaps,
    ];

    // Only include START DELIVERY link if it was successfully generated
    if (driverLink != null && driverLink.trim().isNotEmpty) {
      lines.addAll([
        '',
        'START DELIVERY',
        driverLink.trim(),
        '',
        'Click the Start Delivery link when you leave the shop.',
        'Your live location will be shared with the florist and customer.',
      ]);
    }

    return lines.join('\n');
  }

  DateTime? _deliveredAt(DeliveryTrackingSnapshot? snapshot) {
    final proofTime = snapshot?.proof?.recordedAt;
    if (proofTime != null) return proofTime;

    final timeline = snapshot?.timeline ?? const <DeliveryTimelineEvent>[];
    DateTime? lastDelivered;
    for (final event in timeline) {
      final normalized = _normalizeStatus(event.status);
      if (normalized == 'delivered') {
        lastDelivered = event.recordedAt;
      }
    }
    if (lastDelivered != null) return lastDelivered;
    return snapshot?.lastLocation?.recordedAt;
  }
}

class _DeliveredSummaryCard extends StatelessWidget {
  const _DeliveredSummaryCard({
    required this.deliveredAt,
    required this.deliveredBy,
    required this.hasPhoto,
    required this.otpVerified,
    required this.signatureCaptured,
  });

  final DateTime? deliveredAt;
  final String deliveredBy;
  final bool hasPhoto;
  final bool otpVerified;
  final bool signatureCaptured;

  @override
  Widget build(BuildContext context) {
    final proofRows = <Widget>[];
    if (hasPhoto) {
      proofRows.add(
        const _DetailRow(
          icon: Icons.photo_camera_outlined,
          label: 'Proof',
          value: 'Photo Available',
          valueColor: Colors.green,
        ),
      );
    }
    if (otpVerified) {
      proofRows.add(
        const _DetailRow(
          icon: Icons.verified_outlined,
          label: 'OTP',
          value: 'Verified',
          valueColor: Colors.green,
        ),
      );
    }
    if (signatureCaptured) {
      proofRows.add(
        const _DetailRow(
          icon: Icons.draw_outlined,
          label: 'Signature',
          value: 'Captured',
          valueColor: Colors.green,
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'Delivered Successfully',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.access_time_rounded,
              label: 'Delivered At',
              value: deliveredAt == null
                  ? 'Not available'
                  : DateFormat('h:mm a').format(deliveredAt!.toLocal()),
            ),
            _DetailRow(
              icon: Icons.badge_outlined,
              label: 'By',
              value: deliveredBy.trim().isEmpty ? '-' : deliveredBy,
            ),
            if (proofRows.isNotEmpty) ...proofRows,
          ],
        ),
      ),
    );
  }
}

class _MonitoringPanel extends StatelessWidget {
  const _MonitoringPanel({
    required this.snapshot,
    required this.status,
    required this.onOpenMap,
  });

  final DeliveryTrackingSnapshot? snapshot;
  final String status;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    final route = snapshot?.route ?? const <DeliveryLocationPoint>[];
    final center = route.isNotEmpty
        ? LatLng(route.last.latitude, route.last.longitude)
        : const LatLng(19.076, 72.8777);
    final points =
        route.map((point) => LatLng(point.latitude, point.longitude)).toList();
    final statusLabel = _statusLabel(status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live Monitoring',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              route.isEmpty
                  ? 'Driver GPS will appear here after the driver taps Start Delivery.'
                  : 'Current trip is publishing live location updates.',
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: route.isEmpty ? 11 : 14,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.floraprise.mobile',
                    ),
                    if (points.length >= 2)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: points,
                            color: Theme.of(context).colorScheme.primary,
                            strokeWidth: 4,
                          ),
                        ],
                      ),
                    if (route.isNotEmpty)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: points.last,
                            width: 44,
                            height: 44,
                            child: const Icon(
                              Icons.local_shipping_rounded,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.route_outlined, size: 18),
                  label: Text(statusLabel),
                ),
                Chip(
                  avatar: const Icon(Icons.place_outlined, size: 18),
                  label: Text(route.isEmpty
                      ? 'Awaiting first location'
                      : 'Last update ${DateFormat('h:mm a').format(route.last.recordedAt.toLocal())}'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: route.isEmpty ? null : onOpenMap,
              icon: const Icon(Icons.map_rounded),
              label: const Text('Open in Google Maps'),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String rawStatus) {
    final normalized = _normalizeStatus(rawStatus);
    return switch (normalized) {
      'assigned' => 'Driver assigned',
      'accepted' => 'Accepted by driver',
      'pickedup' => 'Picked up',
      'outfordelivery' => 'Out for delivery',
      'arrivednearby' => 'Driver arrived nearby',
      'delivered' => 'Delivered',
      'cancelled' => 'Cancelled',
      'rejected' => 'Rejected by driver',
      _ => rawStatus,
    };
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.snapshot});

  final DeliveryTrackingSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final events = snapshot?.timeline ?? const <DeliveryTimelineEvent>[];
    final proof = snapshot?.proof;
    final hasPhoto = proof?.photoUrl.trim().isNotEmpty ?? false;
    final otpVerified = proof?.otpVerified == true;
    final signatureCaptured = proof?.signatureCaptured == true ||
        ((proof?.signatureValue ?? '').trim().isNotEmpty);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status Timeline',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (events.isEmpty)
              const Text('Waiting for the first delivery update.')
            else
              ...events.map(
                (event) {
                  final delivered =
                      _normalizeStatus(event.status) == 'delivered';
                  final showProofBadges = delivered &&
                      (hasPhoto || otpVerified || signatureCaptured);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.radio_button_checked_rounded),
                        title: Text(event.status),
                        subtitle: Text(DateFormat('dd MMM, h:mm a')
                            .format(event.recordedAt.toLocal())),
                      ),
                      if (showProofBadges) ...[
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 40),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (hasPhoto)
                                _proofChip(
                                  context,
                                  icon: Icons.photo_camera_outlined,
                                  text: 'Photo Available',
                                ),
                              if (otpVerified)
                                _proofChip(
                                  context,
                                  icon: Icons.verified_outlined,
                                  text: 'OTP Verified',
                                ),
                              if (signatureCaptured)
                                _proofChip(
                                  context,
                                  icon: Icons.draw_outlined,
                                  text: 'Signature Captured',
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _proofChip(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    final color = Colors.green.shade700;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceMessage extends StatelessWidget {
  const _WorkspaceMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(actionLabel!),
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

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Expanded(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

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
                Text(value, style: TextStyle(color: valueColor)),
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
    final color = _statusColor(status, Theme.of(context).colorScheme);
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
  if (_normalizeStatus(status) == 'waitingtosync') return 'Waiting to sync';

  final compact = status.replaceAllMapped(
    RegExp(r'(?<=[a-z])(?=[A-Z])'),
    (_) => ' ',
  );
  return compact.isEmpty ? 'Unknown' : compact;
}

Color _statusColor(String status, ColorScheme colorScheme) {
  return switch (_normalizeStatus(status)) {
    'assigned' => colorScheme.outline,
    'accepted' => colorScheme.primary,
    'waitingtosync' => Colors.orange.shade800,
    'pickedup' => colorScheme.tertiary,
    'outfordelivery' => colorScheme.primary,
    'arrivednearby' => colorScheme.secondary,
    'delivered' => Colors.green.shade700,
    'cancelled' || 'failed' || 'returned' => colorScheme.error,
    _ => colorScheme.outline,
  };
}
