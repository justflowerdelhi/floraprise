import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/repositories/cloud_staff_repository.dart';
import '../data/repositories/staff_repository.dart';
import '../providers/cloud_staff_provider.dart';
import '../providers/staff_provider.dart';
import '../providers/storage_mode_provider.dart';
import '../services/contact_picker_service.dart';
import '../widgets/common_widgets.dart';
import 'staff_management_screen.dart';

/// Routes the Staff destination to the Cloud or the untouched local screen.
class StaffModeScreen extends StatelessWidget {
  const StaffModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isCloud = context.watch<StorageModeProvider>().isCloud;
    return isCloud ? const CloudStaffScreen() : const StaffManagementScreen();
  }
}

/// Cloud-mode staff management. Uses Cloud Guid ids and the /api/staff
/// endpoints only; hard delete is intentionally unavailable in Cloud.
class CloudStaffScreen extends StatefulWidget {
  const CloudStaffScreen({super.key});

  @override
  State<CloudStaffScreen> createState() => _CloudStaffScreenState();
}

class _CloudStaffScreenState extends State<CloudStaffScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CloudStaffProvider>().loadStaff();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CloudStaffProvider>();
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff (Cloud)'),
        actions: [
          PopupMenuButton<StaffSort>(
            icon: const Icon(Icons.sort),
            initialValue: provider.sort,
            onSelected: provider.setSort,
            itemBuilder: (context) => const [
              PopupMenuItem(value: StaffSort.name, child: Text('Name')),
              PopupMenuItem(value: StaffSort.role, child: Text('Role')),
              PopupMenuItem(
                value: StaffSort.recentlyAdded,
                child: Text('Recently Added'),
              ),
            ],
          ),
          IconButton(
            onPressed: provider.loadStaff,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: provider.setQuery,
                decoration: InputDecoration(
                  hintText: 'Search name, phone or role',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            _buildFilters(provider),
            const SizedBox(height: 8),
            Expanded(child: _buildBody(provider, bottomInset)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStaffForm(),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Staff'),
      ),
    );
  }

  Widget _buildFilters(CloudStaffProvider provider) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          FilterChip(
            label: const Text('All roles'),
            selected: provider.roleFilter == null,
            onSelected: (_) => provider.setRoleFilter(null),
          ),
          for (final role in CloudStaffRoles.supportedAppRoles) ...[
            const SizedBox(width: 8),
            FilterChip(
              label: Text(role.displayName),
              selected: provider.roleFilter == role,
              onSelected: (_) => provider.setRoleFilter(
                provider.roleFilter == role ? null : role,
              ),
            ),
          ],
          const SizedBox(width: 16),
          for (final status in StaffStatusFilter.values) ...[
            const SizedBox(width: 8),
            FilterChip(
              label: Text(switch (status) {
                StaffStatusFilter.all => 'All',
                StaffStatusFilter.active => 'Active',
                StaffStatusFilter.inactive => 'Inactive',
              }),
              selected: provider.statusFilter == status,
              onSelected: (_) => provider.setStatusFilter(status),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody(CloudStaffProvider provider, double bottomInset) {
    if (provider.isLoading && provider.staff.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            provider.error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }
    final staff = provider.staff;
    if (staff.isEmpty) {
      return const Center(child: Text('No Cloud staff found.'));
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 96 + bottomInset),
      itemCount: staff.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildStaffCard(staff[index]),
    );
  }

  Widget _buildStaffCard(CloudStaff member) {
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            child: Text(member.name.isEmpty ? '?' : member.name[0].toUpperCase()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  '${member.roleLabel}  ·  ${member.isActive ? 'Active' : 'Inactive'}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                if (member.phone != null)
                  Text(
                    member.phone!,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleAction(value, member),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'view', child: Text('View')),
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(
                value: 'toggle',
                child: Text(member.isActive ? 'Deactivate' : 'Reactivate'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(String action, CloudStaff member) async {
    switch (action) {
      case 'view':
        await _showStaffDetail(member);
      case 'edit':
        await _showStaffForm(existing: member);
      case 'toggle':
        await _guard(() {
          final provider = context.read<CloudStaffProvider>();
          return member.isActive
              ? provider.deactivateStaff(member.id)
              : provider.reactivateStaff(member.id);
        });
    }
  }

  Future<void> _showStaffDetail(CloudStaff member) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(member.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Role', member.roleLabel),
              _detailRow('Status', member.isActive ? 'Active' : 'Inactive'),
              _detailRow('Phone', member.phone ?? '-'),
              _detailRow('Email', member.email ?? '-'),
              if (member.driverStatus != null)
                _detailRow('Driver Status', member.driverStatus!),
              if (member.commissionType != null)
                _detailRow('Commission', member.commissionType!),
              if (member.commissionRate != null)
                _detailRow('Commission Rate', '${member.commissionRate}'),
              if (member.hourlyRate != null)
                _detailRow('Hourly Rate', '${member.hourlyRate}'),
              if (member.loginIdentifier != null)
                _detailRow('Login', member.loginIdentifier!),
              if (member.loginRole != null)
                _detailRow('Login Role', member.loginRole!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _showStaffForm({CloudStaff? existing}) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => _CloudStaffFormDialog(existing: existing),
    );
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_message(error))),
      );
    }
  }

  static String _message(Object error) {
    if (error is CloudStaffPermissionException) return error.message;
    if (error is CloudStaffRoleNotSupportedException) return error.toString();
    return 'Unable to save staff: $error';
  }
}

/// Owns its own controllers so they are disposed with the dialog element, not
/// when showDialog's future completes while the route is still animating out.
class _CloudStaffFormDialog extends StatefulWidget {
  const _CloudStaffFormDialog({this.existing});

  final CloudStaff? existing;

  @override
  State<_CloudStaffFormDialog> createState() => _CloudStaffFormDialogState();
}

class _CloudStaffFormDialogState extends State<_CloudStaffFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late StaffRole _role;
  late bool _isActive;
  bool _isSaving = false;
  String? _formError;

  CloudStaff? get _existing => widget.existing;

  // A Cloud role with no app equivalent must be chosen again explicitly.
  bool get _hasUnmappedRole => _existing != null && _existing!.appRole == null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _existing?.name ?? '');
    _phoneController = TextEditingController(text: _existing?.phone ?? '');
    _emailController = TextEditingController(text: _existing?.email ?? '');
    _role = _existing?.appRole ?? StaffRole.designer;
    _isActive = _existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_existing == null ? 'Add Staff' : 'Edit Staff'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_hasUnmappedRole)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'This member currently has the Cloud role '
                  '"${_existing!.cloudRole}", which has no app equivalent. '
                  'Saving will change it to the selected role.',
                  style: TextStyle(color: Colors.orange.shade800),
                ),
              ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _isSaving ? null : _pickFromContacts,
                icon: const Icon(Icons.contacts_outlined),
                label: const Text('From Contacts'),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<StaffRole>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: [
                for (final option in CloudStaffRoles.supportedAppRoles)
                  DropdownMenuItem(
                    value: option,
                    child: Text(CloudStaffRoles.displayName(option)),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _role = value);
              },
            ),
            if (_existing != null) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
            ],
            if (_formError != null) ...[
              const SizedBox(height: 8),
              Text(
                _formError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _pickFromContacts() async {
    final picked = await ContactPickerService.pickContact(context);
    if (picked == null || !mounted) return;
    setState(() {
      _nameController.text = picked.name;
      _phoneController.text = picked.mobile;
    });
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _formError = 'Name is required.');
      return;
    }

    final navigator = Navigator.of(context);
    final provider = context.read<CloudStaffProvider>();
    final input = CloudStaffInput(
      name: _nameController.text.trim(),
      role: _role,
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      isActive: _existing == null ? true : _isActive,
    );

    setState(() {
      _isSaving = true;
      _formError = null;
    });

    try {
      if (_existing == null) {
        await provider.createStaff(input);
      } else {
        await provider.updateStaff(_existing!.id, input);
      }
      navigator.pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _formError = _CloudStaffScreenState._message(error);
      });
    }
  }
}
