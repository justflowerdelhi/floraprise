import 'package:flutter/material.dart';

import '../services/delivery_tracking_service.dart';
import 'live_delivery_tracking_screen.dart';

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
          _DeliveryWorkspaceTab(status: 'active'),
          _DeliveryWorkspaceTab(status: 'completed'),
          _DeliveryWorkspaceTab(status: 'cancelled'),
        ],
      ),
    );
  }
}

class _DeliveryWorkspaceTab extends StatefulWidget {
  const _DeliveryWorkspaceTab({required this.status});

  final String status;

  @override
  State<_DeliveryWorkspaceTab> createState() => _DeliveryWorkspaceTabState();
}

class _DeliveryWorkspaceTabState extends State<_DeliveryWorkspaceTab> {
  final DeliveryTrackingService _service = DeliveryTrackingService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DeliveryWorkspaceRecord>>(
      future: _service.getWorkspace(widget.status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }

        final records = snapshot.data ?? const <DeliveryWorkspaceRecord>[];
        if (records.isEmpty) {
          return const Center(child: Text('No deliveries found.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = records[index];
            return Card(
              child: ListTile(
                title: Text(item.orderNo),
                subtitle: Text('${item.recipientName} • ${item.status}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LiveDeliveryTrackingScreen(
                        orderId: item.orderId,
                        assignmentId: item.assignmentId,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
