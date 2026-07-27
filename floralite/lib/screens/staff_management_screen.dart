import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/voice_dictation_controller.dart';
import '../data/repositories/staff_repository.dart';
import '../providers/staff_provider.dart';
import '../services/contact_picker_service.dart';
import '../services/speech_recognition_service.dart';
import '../utils/whatsapp_phone_utils.dart';
import '../widgets/common_widgets.dart';
import '../widgets/voice_dictation_field_header.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffProvider>().loadStaff();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StaffProvider>();
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff'),
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
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            provider.setQuery('');
                            setState(() {});
                          },
                          icon: const Icon(Icons.clear),
                        ),
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

  Widget _buildFilters(StaffProvider provider) {
    const roles = [
      StaffRole.designer,
      StaffRole.chef,
      StaffRole.delivery,
      StaffRole.sales,
      StaffRole.manager,
    ];
    return SizedBox(
      height: 42,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AppChip(
              label: 'All',
              isSelected: provider.roleFilter == null &&
                  provider.statusFilter == StaffStatusFilter.all,
              onTap: () {
                provider.setRoleFilter(null);
                provider.setStatusFilter(StaffStatusFilter.all);
              },
            ),
          ),
          ...roles.map(
            (role) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AppChip(
                label: role.displayName,
                isSelected: provider.roleFilter == role,
                onTap: () {
                  provider.setRoleFilter(role);
                  provider.setStatusFilter(StaffStatusFilter.all);
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AppChip(
              label: 'Active',
              isSelected: provider.statusFilter == StaffStatusFilter.active,
              onTap: () {
                provider.setRoleFilter(null);
                provider.setStatusFilter(StaffStatusFilter.active);
              },
            ),
          ),
          AppChip(
            label: 'Inactive',
            isSelected: provider.statusFilter == StaffStatusFilter.inactive,
            onTap: () {
              provider.setRoleFilter(null);
              provider.setStatusFilter(StaffStatusFilter.inactive);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(StaffProvider provider, double bottomInset) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(provider.error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
                onPressed: provider.loadStaff, child: const Text('Retry')),
          ],
        ),
      );
    }
    final staff = provider.staff;
    if (staff.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.badge_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('No staff found'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _showStaffForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add Staff'),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 96 + bottomInset),
      itemCount: staff.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildStaffCard(staff[index]),
    );
  }

  Widget _buildStaffCard(Staff member) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppCard(
      onTap: () => _showStaffDetail(member),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  member.name.isEmpty ? '?' : member.name[0].toUpperCase(),
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _badge(member.role.displayName, colorScheme.primary),
                        _badge(
                          member.active ? 'Active' : 'Inactive',
                          member.active ? Colors.green : Colors.grey,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(member.phone,
                        style: TextStyle(color: Colors.grey.shade700)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleMore(value, member),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'view', child: Text('View')),
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                    value: member.active ? 'deactivate' : 'reactivate',
                    child: Text(member.active ? 'Deactivate' : 'Reactivate'),
                  ),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _canContact(member.phone)
                      ? () => _launchPhone(member.phone)
                      : null,
                  icon: const Icon(Icons.call, size: 18),
                  label: const Text('Call'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: IgnorePointer(
                  ignoring: !_canContact(member.whatsapp ?? member.phone),
                  child: Opacity(
                    opacity:
                        _canContact(member.whatsapp ?? member.phone) ? 1 : 0.45,
                    child: WhatsAppButton(
                      onTap: () =>
                          _launchWhatsApp(member.whatsapp ?? member.phone),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _handleMore(String value, Staff member) {
    switch (value) {
      case 'view':
        _showStaffDetail(member);
      case 'edit':
        _showStaffForm(existing: member);
      case 'deactivate':
        _confirmStatus(member, false);
      case 'reactivate':
        _confirmStatus(member, true);
      case 'delete':
        _confirmDelete(member);
    }
  }

  Future<void> _showStaffForm({Staff? existing}) async {
    final input = await showDialog<StaffUpsertInput>(
      context: context,
      builder: (context) => _StaffFormDialog(existing: existing),
    );
    if (input == null || !mounted) return;
    try {
      final provider = context.read<StaffProvider>();
      if (existing == null) {
        await provider.createStaff(input);
      } else {
        await provider.updateStaff(existing.id, input);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existing == null
              ? 'Staff added successfully.'
              : 'Staff updated successfully.'),
        ),
      );
      await context.read<StaffProvider>().loadStaff();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _confirmStatus(Staff member, bool active) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(active ? 'Reactivate Staff' : 'Deactivate Staff'),
        content:
            Text('${active ? 'Reactivate' : 'Deactivate'} ${member.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(active ? 'Reactivate' : 'Deactivate'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final provider = context.read<StaffProvider>();
      if (active) {
        await provider.reactivateStaff(member.id);
      } else {
        await provider.deactivateStaff(member.id);
      }
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _confirmDelete(Staff member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Staff'),
        content: Text('Permanently delete ${member.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<StaffProvider>().deleteStaff(member.id);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _showStaffDetail(Staff member) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Expanded(child: Text(member.name)),
            _badge(
                member.role.displayName, Theme.of(context).colorScheme.primary),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detail('Staff Code', member.staffCode),
                _detail('Phone', member.phone),
                _detail('WhatsApp', member.whatsapp ?? '-'),
                _detail('Email', member.email ?? '-'),
                _detail('City', member.city ?? '-'),
                _detail('Address', member.address ?? '-'),
                _detail('Joining Date', _formatDate(member.joiningDate)),
                _detail('Salary Type', member.salaryType?.displayName ?? '-'),
                _detail(
                  'Salary Amount',
                  member.salaryAmount == null
                      ? '-'
                      : '₹${member.salaryAmount!.toStringAsFixed(2)}',
                ),
                _detail('Notes', member.notes ?? '-'),
                const Divider(height: 28),
                const Text(
                  'Future Sections',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _detail('Assigned Orders', '0'),
                _detail('Completed Deliveries', '0'),
                _detail('Completed Designs', '0'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showStaffForm(existing: member);
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri)) _showError('Could not open phone app.');
  }

  Future<void> _launchWhatsApp(String phone) async {
    final uri = WhatsAppPhoneUtils.buildUri(phone);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showError('Could not open WhatsApp.');
    }
  }

  bool _canContact(String value) => RegExp(r'\d').hasMatch(value);

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  void _showError(Object error) {
    if (!mounted) return;
    final message = error.toString().replaceFirst('Bad state: ', '');
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _StaffFormDialog extends StatefulWidget {
  const _StaffFormDialog({this.existing});

  final Staff? existing;

  @override
  State<_StaffFormDialog> createState() => _StaffFormDialogState();
}

class _StaffFormDialogState extends State<_StaffFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _whatsappController;
  late final TextEditingController _emailController;
  late final TextEditingController _cityController;
  late final TextEditingController _addressController;
  late final TextEditingController _salaryAmountController;
  late final TextEditingController _notesController;
  late StaffRole _role;
  StaffSalaryType? _salaryType;
  late bool _sameAsPhone;
  late bool _active;
  DateTime? _joiningDate;
  final VoiceDictationController _addressDictationController =
      VoiceDictationController(
    speechRecognition: SpeechRecognitionService(),
  );
  final VoiceDictationController _notesDictationController =
      VoiceDictationController(
    speechRecognition: SpeechRecognitionService(),
  );

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _phoneController = TextEditingController(text: existing?.phone ?? '');
    _whatsappController = TextEditingController(text: existing?.whatsapp ?? '');
    _emailController = TextEditingController(text: existing?.email ?? '');
    _cityController = TextEditingController(text: existing?.city ?? '');
    _addressController = TextEditingController(text: existing?.address ?? '');
    _salaryAmountController = TextEditingController(
      text: existing?.salaryAmount?.toString() ?? '',
    );
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _addressDictationController.bindController(_addressController);
    _notesDictationController.bindController(_notesController);
    _role = existing?.role ?? StaffRole.designer;
    _salaryType = existing?.salaryType;
    _sameAsPhone = existing?.sameAsPhone ?? true;
    _active = existing?.active ?? true;
    _joiningDate = existing?.joiningDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _salaryAmountController.dispose();
    _notesController.dispose();
    _addressDictationController.dispose();
    _notesDictationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add Staff' : 'Edit Staff'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: widget.existing?.staffCode ?? 'Auto-generated',
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Staff Code'),
              ),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Name *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: const InputDecoration(labelText: 'Phone *'),
                onChanged: (value) {
                  if (_sameAsPhone) _whatsappController.text = value;
                },
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _pickFromContacts,
                  icon: const Icon(Icons.contacts_outlined, size: 18),
                  label: const Text('From Contacts'),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _whatsappController,
                readOnly: _sameAsPhone,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: const InputDecoration(labelText: 'WhatsApp'),
              ),
              CheckboxListTile(
                value: _sameAsPhone,
                onChanged: (value) {
                  setState(() {
                    _sameAsPhone = value ?? true;
                    if (_sameAsPhone) {
                      _whatsappController.text = _phoneController.text;
                    }
                  });
                },
                title: const Text('Same as Phone'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              DropdownButtonFormField<StaffRole>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Role *'),
                items: StaffRole.values
                    .map(
                      (role) => DropdownMenuItem(
                        value: role,
                        child: Text(role.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _role = value);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _cityController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'City'),
              ),
              const SizedBox(height: 10),
              VoiceDictationFieldHeader(
                label: 'Address',
                controller: _addressDictationController,
              ),
              TextField(
                controller: _addressController,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(),
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month),
                title: const Text('Joining Date'),
                subtitle: Text(_joiningDate == null
                    ? 'Not selected'
                    : '${_joiningDate!.day}/${_joiningDate!.month}/${_joiningDate!.year}'),
                trailing: _joiningDate == null
                    ? null
                    : IconButton(
                        onPressed: () => setState(() => _joiningDate = null),
                        icon: const Icon(Icons.clear),
                      ),
                onTap: _pickJoiningDate,
              ),
              DropdownButtonFormField<StaffSalaryType>(
                initialValue: _salaryType,
                decoration: InputDecoration(
                  labelText: 'Salary Type',
                  suffixIcon: _salaryType == null
                      ? null
                      : IconButton(
                          onPressed: () {
                            setState(() {
                              _salaryType = null;
                              _salaryAmountController.clear();
                            });
                          },
                          icon: const Icon(Icons.clear),
                        ),
                ),
                hint: const Text('Not set'),
                items: StaffSalaryType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _salaryType = value),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _salaryAmountController,
                enabled: _salaryType != null,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Salary Amount',
                  prefixText: '₹ ',
                ),
              ),
              const SizedBox(height: 10),
              VoiceDictationFieldHeader(
                label: 'Notes',
                controller: _notesDictationController,
              ),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(),
              ),
              if (widget.existing != null)
                SwitchListTile(
                  value: _active,
                  onChanged: (value) => setState(() => _active = value),
                  title: const Text('Active'),
                  contentPadding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }

  Future<void> _pickJoiningDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _joiningDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _joiningDate = picked);
  }

  Future<void> _pickFromContacts() async {
    final picked = await ContactPickerService.pickContact(context);
    if (picked == null || !mounted) return;
    setState(() {
      _nameController.text = picked.name;
      _phoneController.text = picked.mobile;
      if (_sameAsPhone) {
        _whatsappController.text = picked.mobile;
      }
    });
  }

  void _save() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final salaryText = _salaryAmountController.text.trim();
    final salaryAmount =
        salaryText.isEmpty ? null : double.tryParse(salaryText);
    if (name.isEmpty) {
      _showValidation('Name is required.');
      return;
    }
    if (phone.isEmpty) {
      _showValidation('Phone is required.');
      return;
    }
    if (salaryText.isNotEmpty && (salaryAmount == null || salaryAmount < 0)) {
      _showValidation('Enter a valid salary amount.');
      return;
    }
    Navigator.pop(
      context,
      StaffUpsertInput(
        name: name,
        phone: phone,
        whatsapp: _whatsappController.text.trim(),
        sameAsPhone: _sameAsPhone,
        email: _emailController.text.trim(),
        role: _role,
        city: _cityController.text.trim(),
        address: _addressController.text.trim(),
        joiningDate: _joiningDate,
        salaryType: _salaryType,
        salaryAmount: _salaryType == null ? null : salaryAmount,
        active: _active,
        notes: _notesController.text.trim(),
      ),
    );
  }

  void _showValidation(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
