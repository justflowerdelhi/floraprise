import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/repositories/associate_repository.dart';
import '../controllers/voice_dictation_controller.dart';
import '../l10n/app_localizations.dart';
import '../providers/associate_provider.dart';
import '../services/contact_picker_service.dart';
import '../services/speech_recognition_service.dart';
import '../widgets/common_widgets.dart';

import '../widgets/voice_dictation_field_header.dart';

class AssociatesScreen extends StatefulWidget {
  const AssociatesScreen({super.key});

  @override
  State<AssociatesScreen> createState() => _AssociatesScreenState();
}

class _AssociatesScreenState extends State<AssociatesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AssociateProvider>().loadAssociates();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Associates'),
        actions: [
          PopupMenuButton<AssociateSort>(
            icon: const Icon(Icons.sort),
            onSelected: (sort) =>
                context.read<AssociateProvider>().setSort(sort),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: AssociateSort.businessNameAsc,
                child: Text('Business Name A-Z'),
              ),
              PopupMenuItem(
                value: AssociateSort.cityAsc,
                child: Text('City A-Z'),
              ),
              PopupMenuItem(
                value: AssociateSort.recentlyAdded,
                child: Text('Recently Added'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AssociateProvider>().refresh(),
          ),
        ],
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
                        controller: _searchController,
                        onChanged: (value) {
                          context
                              .read<AssociateProvider>()
                              .setSearchQuery(value);
                        },
                        decoration: InputDecoration(
                          hintText:
                              'Search by Business Name, Contact Person, Phone, City',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    context
                                        .read<AssociateProvider>()
                                        .setSearchQuery('');
                                  },
                                  icon: const Icon(Icons.clear_rounded),
                                )
                              : null,
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
                      label: const Text('Filter'),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTypeChip(null, 'All'),
                    ...AssociateTypeExtension.allTypes.map((type) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildTypeChip(type, type.displayName),
                      );
                    }),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AppChip(
                        label: context.watch<AssociateProvider>().showInactive
                            ? 'Show Inactive On'
                            : 'Show Inactive',
                        isSelected:
                            context.watch<AssociateProvider>().showInactive,
                        onTap: () {
                          final provider = context.read<AssociateProvider>();
                          provider.setStatusFilters(
                            showActive: provider.showActive,
                            showInactive: !provider.showInactive,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _buildBody(l10n, bottomInset),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAssociateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Associate'),
      ),
    );
  }

  Widget _buildTypeChip(AssociateType? type, String label) {
    final provider = context.watch<AssociateProvider>();
    final isSelected = provider.typeFilter == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: AppChip(
        label: label,
        isSelected: isSelected,
        onTap: () {
          provider.setTypeFilter(type);
        },
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, double bottomInset) {
    final provider = context.watch<AssociateProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                provider.error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: provider.refresh,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.associates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.business,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No Associates Yet',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _showAddAssociateDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Associate'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 96 + bottomInset),
      children: provider.associates
          .map((associate) => _buildAssociateCard(associate))
          .toList(),
    );
  }

  Widget _buildAssociateCard(AssociateRecord associate) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusLabel = associate.isActive ? 'Active' : 'Inactive';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        associate.businessName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (associate.contactPerson != null)
                        Text(
                          associate.contactPerson!,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      Text(
                        '${associate.phone} • ${associate.city}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: associate.types
                            .map((type) => Chip(
                                  label: Text(
                                    type.displayName,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      associate.associateCode,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: associate.isActive
                            ? Colors.green
                            : Colors.grey.shade600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Spacer(),
                if (associate.isActive)
                  TextButton.icon(
                    onPressed: () => _confirmDeactivate(associate),
                    icon: const Icon(Icons.block, size: 16),
                    label: const Text('Deactivate',
                        style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                else
                  TextButton.icon(
                    onPressed: () => _confirmReactivate(associate),
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: const Text('Reactivate',
                        style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () => _showEditAssociateDialog(associate),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () => _confirmDelete(associate),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Delete', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final provider = context.read<AssociateProvider>();
    var localShowActive = provider.showActive;
    var localShowInactive = provider.showInactive;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter Associates',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  value: localShowActive,
                  onChanged: (value) =>
                      setStateModal(() => localShowActive = value),
                  title: const Text('Active'),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  value: localShowInactive,
                  onChanged: (value) =>
                      setStateModal(() => localShowInactive = value),
                  title: const Text('Inactive'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      await provider.setStatusFilters(
                        showActive: localShowActive,
                        showInactive: localShowInactive,
                      );
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddAssociateDialog() async {
    final input = await _showAssociateFormDialog();
    if (input == null) return;

    if (!mounted) return;

    try {
      await context.read<AssociateProvider>().createAssociate(input);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Associate added successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyErrorMessage(e))),
      );
    }
  }

  Future<void> _showEditAssociateDialog(AssociateRecord associate) async {
    final input = await _showAssociateFormDialog(existing: associate);
    if (input == null) return;

    if (!mounted) return;

    try {
      await context
          .read<AssociateProvider>()
          .updateAssociate(associate.id, input);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Associate updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyErrorMessage(e))),
      );
    }
  }

  Future<void> _confirmDeactivate(AssociateRecord associate) async {
    final shouldDeactivate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Associate'),
        content: Text('Deactivate ${associate.businessName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (shouldDeactivate != true) return;

    if (!mounted) return;

    try {
      await context.read<AssociateProvider>().deactivateAssociate(associate.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Associate deactivated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyErrorMessage(e))),
      );
    }
  }

  Future<void> _confirmReactivate(AssociateRecord associate) async {
    final shouldReactivate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reactivate Associate'),
        content: Text('Reactivate ${associate.businessName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reactivate'),
          ),
        ],
      ),
    );

    if (shouldReactivate != true) return;

    if (!mounted) return;

    try {
      await context.read<AssociateProvider>().reactivateAssociate(associate.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Associate reactivated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyErrorMessage(e))),
      );
    }
  }

  Future<void> _confirmDelete(AssociateRecord associate) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Associate'),
        content: Text('Delete ${associate.businessName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    if (!mounted) return;

    try {
      await context.read<AssociateProvider>().deleteAssociate(associate.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Associate deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyErrorMessage(e))),
      );
    }
  }

  Future<AssociateUpsertInput?> _showAssociateFormDialog({
    AssociateRecord? existing,
  }) async {
    final businessNameController =
        TextEditingController(text: existing?.businessName ?? '');
    final contactPersonController =
        TextEditingController(text: existing?.contactPerson ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    final whatsappController =
        TextEditingController(text: existing?.whatsapp ?? '');
    final emailController = TextEditingController(text: existing?.email ?? '');
    final cityController = TextEditingController(text: existing?.city ?? '');
    final stateController = TextEditingController(text: existing?.state ?? '');
    final pincodeController =
        TextEditingController(text: existing?.pincode ?? '');
    final addressController =
        TextEditingController(text: existing?.address ?? '');
    final gstNumberController =
        TextEditingController(text: existing?.gstNumber ?? '');
    final websiteController =
        TextEditingController(text: existing?.website ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');
    final addressDictationController = VoiceDictationController(
      speechRecognition: SpeechRecognitionService(),
    );
    final notesDictationController = VoiceDictationController(
      speechRecognition: SpeechRecognitionService(),
    );
    addressDictationController.bindController(addressController);
    notesDictationController.bindController(notesController);

    var selectedTypes = existing?.types ?? [AssociateType.other];
    var isActive = existing?.isActive ?? true;
    var sameAsPhone = existing == null || existing.whatsapp == existing.phone;

    final result = await showDialog<AssociateUpsertInput>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(existing == null ? 'Add Associate' : 'Edit Associate'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: businessNameController,
                      decoration:
                          const InputDecoration(labelText: 'Business Name *'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: contactPersonController,
                      decoration:
                          const InputDecoration(labelText: 'Contact Person'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: const InputDecoration(labelText: 'Phone *'),
                      onChanged: (value) {
                        if (sameAsPhone) {
                          whatsappController.text = value;
                        }
                      },
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked =
                              await ContactPickerService.pickContact(context);
                          if (picked == null || !context.mounted) return;
                          setStateDialog(() {
                            contactPersonController.text = picked.name;
                            phoneController.text = picked.mobile;
                            if (sameAsPhone) {
                              whatsappController.text = picked.mobile;
                            }
                          });
                        },
                        icon: const Icon(Icons.contacts_outlined, size: 18),
                        label: const Text('From Contacts'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: whatsappController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: const InputDecoration(labelText: 'WhatsApp'),
                      readOnly: sameAsPhone,
                    ),
                    CheckboxListTile(
                      value: sameAsPhone,
                      onChanged: (value) {
                        setStateDialog(() {
                          sameAsPhone = value ?? false;
                          if (sameAsPhone) {
                            whatsappController.text = phoneController.text;
                          }
                        });
                      },
                      title: const Text('Same as Phone Number'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: cityController,
                      decoration: const InputDecoration(labelText: 'City *'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: stateController,
                      decoration: const InputDecoration(labelText: 'State'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: pincodeController,
                      decoration: const InputDecoration(labelText: 'Pincode *'),
                    ),
                    const SizedBox(height: 10),
                    VoiceDictationFieldHeader(
                      label: 'Address',
                      controller: addressDictationController,
                      compact: true,
                    ),
                    TextField(
                      controller: addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: gstNumberController,
                      decoration:
                          const InputDecoration(labelText: 'GST Number'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: websiteController,
                      decoration: const InputDecoration(labelText: 'Website'),
                    ),
                    const SizedBox(height: 10),
                    VoiceDictationFieldHeader(
                      label: 'Notes',
                      controller: notesDictationController,
                      compact: true,
                    ),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Associate Types *',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AssociateTypeExtension.allTypes.map((type) {
                        final isSelected = selectedTypes.contains(type);
                        return FilterChip(
                          label: Text(type.displayName),
                          selected: isSelected,
                          onSelected: (selected) {
                            setStateDialog(() {
                              if (selected) {
                                if (!selectedTypes.contains(type)) {
                                  selectedTypes = [...selectedTypes, type];
                                }
                              } else {
                                if (selectedTypes.length > 1) {
                                  selectedTypes = selectedTypes
                                      .where((t) => t != type)
                                      .toList();
                                }
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      value: isActive,
                      onChanged: (value) =>
                          setStateDialog(() => isActive = value),
                      title: const Text('Active'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final businessName = businessNameController.text.trim();
                final phone = phoneController.text.trim();
                final city = cityController.text.trim();
                final pincode = pincodeController.text.trim();

                if (businessName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Business Name is required.')),
                  );
                  return;
                }

                if (phone.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Phone is required.')),
                  );
                  return;
                }

                if (city.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('City is required.')),
                  );
                  return;
                }

                if (pincode.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pincode is required.')),
                  );
                  return;
                }

                if (selectedTypes.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('At least one type is required.')),
                  );
                  return;
                }

                Navigator.pop(
                  context,
                  AssociateUpsertInput(
                    businessName: businessName,
                    contactPerson: contactPersonController.text.trim(),
                    phone: phone,
                    whatsapp: whatsappController.text.trim(),
                    email: emailController.text.trim(),
                    city: city,
                    state: stateController.text.trim(),
                    pincode: pincode,
                    address: addressController.text.trim(),
                    gstNumber: gstNumberController.text.trim(),
                    website: websiteController.text.trim(),
                    notes: notesController.text.trim(),
                    types: selectedTypes,
                    isActive: isActive,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    addressDictationController.dispose();
    notesDictationController.dispose();
    return result;
  }

  String _friendlyErrorMessage(dynamic error) {
    if (error is Exception) {
      final message = error.toString();
      if (message.contains('business name and phone already exists')) {
        return 'An associate with this business name and phone already exists.';
      }
      if (message.contains('being used and cannot be deleted')) {
        return 'This Associate is being used and cannot be deleted.';
      }
    }
    return error.toString();
  }
}
