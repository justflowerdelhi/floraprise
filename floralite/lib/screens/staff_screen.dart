import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../widgets/common_widgets.dart';

class StaffScreen extends StatelessWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.staff),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 64,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: l10n.searchStaff,
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: const Icon(Icons.mic_none_rounded),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 64,
                    child: FilledButton.tonalIcon(
                      onPressed: () => _showFilterSheet(context),
                      icon: const Icon(Icons.tune_rounded),
                      label: Text(l10n.filter),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 96 + bottomInset),
                itemCount: 5,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final staff = [
                    {
                      'name': 'Rajesh Kumar',
                      'role': 'Lead Florist',
                      'phone': '+91 98765 43210',
                      'status': 'On Duty',
                      'assignedOrders': 3,
                      'currentTask': 'Wedding Bouquet - Priya Sharma',
                    },
                    {
                      'name': 'Sunil Verma',
                      'role': 'Delivery Driver',
                      'phone': '+91 87654 32109',
                      'status': 'On Delivery',
                      'assignedOrders': 2,
                      'currentTask': 'Delivering to Sector 15',
                    },
                    {
                      'name': 'Meena Devi',
                      'role': 'Florist',
                      'phone': '+91 76543 21098',
                      'status': 'On Duty',
                      'assignedOrders': 4,
                      'currentTask': 'Birthday Arrangement - Ankit',
                    },
                    {
                      'name': 'Amit Singh',
                      'role': 'Assistant',
                      'phone': '+91 65432 10987',
                      'status': 'Off Duty',
                      'assignedOrders': 0,
                      'currentTask': 'No active task',
                    },
                    {
                      'name': 'Kavita Roy',
                      'role': 'Customer Service',
                      'phone': '+91 54321 09876',
                      'status': 'On Duty',
                      'assignedOrders': 5,
                      'currentTask': 'Handling customer calls',
                    },
                  ];
                  final member = staff[index];

                  return GestureDetector(
                    onLongPress: () => _showStaffActions(context),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: colorScheme.primaryContainer,
                                child: Text(
                                  (member['name'] as String)[0],
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      member['name'] as String,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'S-${(index + 1).toString().padLeft(3, '0')}',
                                        style: TextStyle(
                                          color: colorScheme.primary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      member['role'] as String,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusChip(
                                label: member['status'] as String,
                                color:
                                    _getStatusColor(member['status'] as String),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            Icons.assignment,
                            l10n.assignedOrders,
                            '${member['assignedOrders']}',
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            Icons.task_alt,
                            l10n.currentTask,
                            member['currentTask'] as String,
                          ),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isCompact = constraints.maxWidth < 340 ||
                                  textScale > 1.15;

                              if (isCompact) {
                                return Column(
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () {},
                                        icon: const Icon(Icons.phone, size: 18),
                                        label: Text(l10n.call),
                                        style: OutlinedButton.styleFrom(
                                          minimumSize:
                                              const Size.fromHeight(48),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      child: WhatsAppButton(
                                        onTap: () {},
                                      ),
                                    ),
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.phone, size: 18),
                                      label: Text(l10n.call),
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size.fromHeight(48),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: WhatsAppButton(
                                      onTap: () {},
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.person_add),
        label: Text(l10n.addStaff),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'On Duty':
        return Colors.green;
      case 'On Delivery':
        return Colors.blue;
      case 'Off Duty':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  void _showFilterSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.filterStaff,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildFilterTile(
                l10n.role, 'Lead Florist, Florist, Driver, Assistant'),
            _buildFilterTile(l10n.status, 'On Duty, On Delivery, Off Duty'),
            _buildFilterTile(l10n.assignedOrders, '0, 1-3, 4+'),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.applyFilters),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTile(String title, String subtitle) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {},
    );
  }

  void _showStaffActions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: Text(l10n.editStaff),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.content_copy_rounded),
              title: Text(l10n.duplicate),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: Text(l10n.share),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded),
              title: Text(l10n.delete),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
