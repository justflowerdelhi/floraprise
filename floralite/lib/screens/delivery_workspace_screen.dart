import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/delivery_tracking_service.dart';

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
  final TextEditingController _notesController = TextEditingController();
  DeliveryWorkspaceRecord get delivery => widget.delivery;

  DeliveryTrackingSnapshot? _snapshot;
  StreamSubscription<DeliveryTrackingSnapshot>? _trackingSubscription;
  StreamSubscription<Position>? _positionSubscription;
  bool _busy = false;
  String? _error;

  bool get _isTracking => _positionSubscription != null;

  @override
  void initState() {
    super.initState();
    _loadTracking();
  }

  @override
  void dispose() {
    _trackingSubscription?.cancel();
    _positionSubscription?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadTracking() async {
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

  Future<void> _runAction(String action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _service.updateAssignmentStatus(
        assignmentId: delivery.assignmentId,
        action: action,
        notes: _notesController.text,
      );
      if (action == 'start') await _startGpsPublishing();
      if (action == 'complete' || action == 'reject' || action == 'cancel') {
        await _stopGpsPublishing();
      }
      await _loadTracking();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startGpsPublishing() async {
    await _ensureLocationPermission();
    await _service.flushAssignmentLocationQueue();
    await _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: _locationSettings(),
    ).listen((position) async {
      try {
        await _service.uploadAssignmentLocation(
          assignmentId: delivery.assignmentId,
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          speed: position.speed,
          heading: position.heading,
          recordedAt: position.timestamp,
        );
        await _service.flushAssignmentLocationQueue();
      } catch (_) {
        await _service.queueAssignmentLocation(
          assignmentId: delivery.assignmentId,
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
    final phone = delivery.customerPhone;
    if (phone == null || phone.trim().isEmpty) return;
    await launchUrl(Uri.parse('tel:$phone'));
  }

  Future<void> _navigate() async {
    final address = delivery.deliveryAddress.trim();
    if (address.isEmpty || address == '-') return;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    final status = snapshot?.status ?? delivery.status;
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
                    value: delivery.driver?.name ?? 'Driver not assigned',
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
          _ActionPanel(
            status: status,
            busy: _busy,
            tracking: _isTracking,
            onAccept: () => _runAction('accept'),
            onStart: () => _runAction('start'),
            onComplete: () => _runAction('complete'),
            onReject: () => _runAction('reject'),
          ),
          const SizedBox(height: 16),
          _TimelineCard(snapshot: snapshot),
        ],
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.status,
    required this.busy,
    required this.tracking,
    required this.onAccept,
    required this.onStart,
    required this.onComplete,
    required this.onReject,
  });

  final String status;
  final bool busy;
  final bool tracking;
  final VoidCallback onAccept;
  final VoidCallback onStart;
  final VoidCallback onComplete;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final normalized = _normalizeStatus(status);
    final canAccept = normalized == 'assigned';
    final canStart = normalized == 'assigned' ||
        normalized == 'accepted' ||
        normalized == 'pickedup';
    final canComplete = normalized == 'outfordelivery' ||
        normalized == 'arrivednearby' ||
        tracking;
    final canReject = normalized == 'assigned' || normalized == 'accepted';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tracking
                  ? 'GPS publishing is active'
                  : 'GPS starts after Start Delivery',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            if (canAccept)
              FilledButton.icon(
                onPressed: busy ? null : onAccept,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Accept Delivery'),
              ),
            if (canStart)
              FilledButton.icon(
                onPressed: busy ? null : onStart,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start Delivery'),
              ),
            if (canComplete)
              FilledButton.icon(
                onPressed: busy ? null : onComplete,
                icon: const Icon(Icons.done_all_rounded),
                label: const Text('Complete Delivery'),
              ),
            if (canReject)
              OutlinedButton.icon(
                onPressed: busy ? null : onReject,
                icon: const Icon(Icons.close_rounded),
                label: const Text('Reject Delivery'),
              ),
          ],
        ),
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.snapshot});

  final DeliveryTrackingSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final events = snapshot?.timeline ?? const <DeliveryTimelineEvent>[];
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
                (event) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.radio_button_checked_rounded),
                  title: Text(event.status),
                  subtitle: Text(DateFormat('dd MMM, h:mm a')
                      .format(event.recordedAt.toLocal())),
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
    'pickedup' => colorScheme.tertiary,
    'outfordelivery' => colorScheme.primary,
    'arrivednearby' => colorScheme.secondary,
    'delivered' => Colors.green.shade700,
    'cancelled' || 'failed' || 'returned' => colorScheme.error,
    _ => colorScheme.outline,
  };
}
