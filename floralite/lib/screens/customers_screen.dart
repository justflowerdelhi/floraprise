import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../managers/customer_import_manager.dart';
import '../providers/customer_provider.dart';
import '../services/contact_picker_service.dart';
import '../widgets/app_header.dart';
import '../widgets/common_widgets.dart';
import '../widgets/floraprise_page_header.dart';
import 'customer_profile_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _isValidPhone(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 10;
  }

  String _displayCustomerId(Object? id) {
    final value = id?.toString() ?? '';
    if (value.isEmpty) return '---';
    return value.length <= 8 ? value.toUpperCase() : value.substring(0, 8).toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CustomerProvider>().loadCustomers();
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
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppHeader(
        title: FloraprisePageHeader.isDesktop(context) ? null : l10n.customers,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            FloraprisePageHeader(
              title: l10n.customers,
              subtitle: 'Build stronger relationships with your customers',
              icon: Icons.people_alt_rounded,
              actions: [
                FloraprisePageHeaderAction(
                  label: l10n.importCustomers,
                  icon: Icons.file_upload_outlined,
                  onPressed: () => _showImportOptions(context),
                ),
                FloraprisePageHeaderAction(
                  label: l10n.addCustomer,
                  icon: Icons.person_add_rounded,
                  primary: true,
                  onPressed: () => _showAddCustomerDialog(context),
                ),
              ],
            ),
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
                              .read<CustomerProvider>()
                              .setSearchQuery(value);
                        },
                        decoration: InputDecoration(
                          hintText: l10n.searchByCustomerIdNamePhone,
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
              child: Consumer<CustomerProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(provider.error!),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => provider.refresh(),
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
                    );
                  }

                  if (provider.customers.isEmpty) {
                    return ListView(
                      padding:
                          EdgeInsets.fromLTRB(16, 16, 16, 96 + bottomInset),
                      children: [
                        AppCard(
                          child: Column(
                            children: [
                              Icon(
                                Icons.person_search,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.noCustomersFound,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 96 + bottomInset),
                    itemCount: provider.customers.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final customer = provider.customers[index];
                      final hasPendingPayment =
                          customer['pendingPayment'] != '₹0';

                      return GestureDetector(
                        onLongPress: () =>
                            _showCustomerActions(context, customer),
                        child: AppCard(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CustomerProfileScreen(
                                  customerId: customer['id']?.toString() ?? '',
                                  name: customer['name'] as String,
                                  phone: customer['phone'] as String,
                                  lastOrder: customer['lastOrder'] as String,
                                  birthday: customer['birthday'] as String,
                                  pendingPayment:
                                      customer['pendingPayment'] as String,
                                  totalOrders: customer['totalOrders'] as int,
                                  rewardPoints: customer['rewardPoints'] as int,
                                  lifetimeRewardPoints:
                                      customer['lifetimeRewardPoints'] as int,
                                  redeemedRewardPoints:
                                      customer['redeemedRewardPoints'] as int,
                                  lastRewardActivity:
                                      customer['lastRewardActivity'] as String,
                                ),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: colorScheme.primaryContainer,
                                child: Text(
                                  (customer['name'] as String)[0],
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
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SelectableText(
                                            customer['name'] as String,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            maxLines: 1,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primaryContainer,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'C-${_displayCustomerId(customer['id'])}',
                                            style: TextStyle(
                                              color: colorScheme.primary,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone,
                                          size: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: SelectableText(
                                            customer['phone'] as String,
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 4,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.cake,
                                              size: 14,
                                              color: Colors.pink,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              customer['birthday'] as String,
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (hasPendingPayment)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${l10n.pendingPayment}: ${customer['pendingPayment']}',
                                              style: TextStyle(
                                                color: Colors.red.shade700,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade100,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Rewards: ${customer['rewardPoints']} pts',
                                            style: TextStyle(
                                              color: Colors.green.shade700,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert,
                                  color: Colors.grey.shade500,
                                ),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditCustomerDialog(context, customer);
                                    return;
                                  }
                                  if (value == 'delete') {
                                    _showDeleteConfirmDialog(context, customer);
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text(l10n.editCustomer),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text(l10n.deleteCustomer),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloraprisePageHeader.isDesktop(context)
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddCustomerDialog(context),
              icon: const Icon(Icons.person_add),
              label: Text(l10n.addCustomer),
            ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => Consumer<CustomerProvider>(
        builder: (context, provider, child) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.filterCustomers,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildFilterTile(
                  l10n,
                  l10n.pendingPayment,
                  provider.pendingPaymentFilter,
                  (value) => provider.setPendingPaymentFilter(value),
                  ['all', 'yes', 'no'],
                ),
                _buildFilterTile(
                  l10n,
                  l10n.totalOrders,
                  provider.totalOrdersFilter,
                  (value) => provider.setTotalOrdersFilter(value),
                  ['all', '1-5', '5-10', '10+'],
                ),
                _buildMultiFilterTile(
                  'Purchased Category',
                  provider.purchasedCategoriesFilter,
                  (value) {
                    final current = List<String>.from(provider.purchasedCategoriesFilter);
                    if (current.contains(value)) {
                      current.remove(value);
                    } else {
                      current.add(value);
                    }
                    provider.setPurchasedCategoriesFilter(current);
                  },
                  ['Flowers', 'Gifts', 'Cakes', 'Bakery', 'Stationery', 'Plants', 'Other'],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          provider.clearFilters();
                          Navigator.pop(context);
                        },
                        child: Text(l10n.clearFilters),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.applyFilters),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterTile(
    AppLocalizations l10n,
    String title,
    String selectedValue,
    Function(String) onSelected,
    List<String> options,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: options.map((option) {
            final isSelected = selectedValue == option;
            final label = switch (option) {
              'all' => l10n.allDesigns,
              'yes' => l10n.yes,
              'no' => l10n.no,
              _ => option,
            };
            return FilterChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => onSelected(option),
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMultiFilterTile(
    String title,
    List<String> selectedValues,
    Function(String) onSelected,
    List<String> options,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: options.map((option) {
            final isSelected = selectedValues.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (_) => onSelected(option),
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showCustomerActions(
      BuildContext context, Map<String, dynamic> customer) {
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
              title: Text(l10n.editCustomer),
              onTap: () {
                Navigator.pop(context);
                _showEditCustomerDialog(context, customer);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded),
              title: Text(l10n.delete),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmDialog(context, customer);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final phoneController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.addCustomer),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: l10n.phoneNumber,
                hintText: '+91 98765 43210',
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final picked =
                      await ContactPickerService.pickContact(context);
                  if (picked == null || !context.mounted) return;
                  nameController.text = picked.name;
                  phoneController.text = picked.mobile;
                },
                icon: const Icon(Icons.contacts_outlined, size: 18),
                label: const Text('From Contacts'),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: l10n.name,
                hintText: l10n.customerName,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final phone = phoneController.text.trim();
              final name = nameController.text.trim();

              if (phone.isEmpty || name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.pleaseFillAllFields)),
                );
                return;
              }

              if (!_isValidPhone(phone)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.pleaseEnterValidPhone)),
                );
                return;
              }

              final success =
                  await context.read<CustomerProvider>().addCustomer(
                        phone: phone,
                        name: name,
                      );

              if (context.mounted) {
                Navigator.pop(dialogContext);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.customerAddedSuccessfully)),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.failedToAddCustomer)),
                  );
                }
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showEditCustomerDialog(
      BuildContext context, Map<String, dynamic> customer) {
    final l10n = AppLocalizations.of(context)!;
    final phoneController =
        TextEditingController(text: customer['phone'] as String);
    final nameController =
        TextEditingController(text: customer['name'] as String);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.editCustomer),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: l10n.phoneNumber,
                hintText: '+91 98765 43210',
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: l10n.name,
                hintText: l10n.customerName,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final phone = phoneController.text.trim();
              final name = nameController.text.trim();

              if (phone.isEmpty || name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.pleaseFillAllFields)),
                );
                return;
              }

              if (!_isValidPhone(phone)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.pleaseEnterValidPhone)),
                );
                return;
              }

              final provider = context.read<CustomerProvider>();
              final messenger = ScaffoldMessenger.of(context);

              final success = await provider.updateCustomer(
                id: customer['id'],
                phone: phone,
                name: name,
              );

              if (!dialogContext.mounted) return;

              if (success) {
                // Close the edit dialog after successful save.
                Navigator.of(dialogContext).pop();

                messenger.showSnackBar(
                  SnackBar(
                    content: Text(l10n.customerUpdatedSuccessfully),
                  ),
                );
              } else {
                final error = provider.error;

                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      error ?? l10n.failedToUpdateCustomer,
                    ),
                  ),
                );
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(
      BuildContext context, Map<String, dynamic> customer) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteCustomer),
        content: Text('${l10n.deleteCustomerConfirm} ${customer['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final success =
                  await context.read<CustomerProvider>().deleteCustomer(
                        customer['id'],
                      );

              if (context.mounted) {
                Navigator.pop(dialogContext);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.customerDeletedSuccessfully)),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.failedToDeleteCustomer)),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  void _showImportOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                l10n.importCustomers,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.table_chart_rounded,
                  color: colorScheme.primary,
                ),
              ),
              title: Text(
                l10n.importExcelCsv,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Supports .xlsx and .csv files'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _pickAndImportFile(context);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kIsWeb
                      ? Colors.grey.shade200
                      : colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.contacts_rounded,
                  color: kIsWeb ? Colors.grey : colorScheme.primary,
                ),
              ),
              title: Text(
                l10n.importContacts,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: kIsWeb ? Colors.grey : null,
                ),
              ),
              subtitle: const Text(
                kIsWeb
                    ? 'Available on Android & iOS mobile devices'
                    : 'Import contacts stored on this device',
              ),
              trailing: const Icon(Icons.chevron_right),
              enabled: !kIsWeb,
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _importFromDeviceContacts(context);
              },
            ),
            const Divider(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.download_rounded,
                  color: Colors.black87,
                ),
              ),
              title: Text(
                l10n.downloadSampleTemplate,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Download CSV spreadsheet format'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _downloadSampleTemplate(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadSampleTemplate(BuildContext context) async {
    try {
      final csv = CustomerImportManager.buildSampleTemplateCsv();
      if (kIsWeb) {
        final uri = Uri.dataFromString(
          csv,
          mimeType: 'text/csv',
          encoding: utf8,
        );
        await launchUrl(uri);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sample template downloaded.')),
        );
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final path = p.join(dir.path, 'floraprise_customers_template.csv');
      await File(path).writeAsString(csv);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Template saved to: $path')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to download template: $e')),
      );
    }
  }

  Future<void> _pickAndImportFile(BuildContext context) async {
    try {
      final picked = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'Spreadsheets',
            extensions: ['xlsx', 'csv'],
          ),
        ],
      );

      if (picked == null || !context.mounted) return;

      final bytes = await picked.readAsBytes();
      if (!context.mounted) return;
      final provider = context.read<CustomerProvider>();
      final preview = await provider.prepareImportBytes(bytes, picked.name);

      if (!context.mounted) return;

      if (preview.totalRows == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data rows found in selected file.')),
        );
        return;
      }

      _showPreviewAndConfirm(context, preview);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reading file: $e')),
      );
    }
  }

  Future<void> _importFromDeviceContacts(BuildContext context) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Device contacts import is supported on Android & iOS.'),
        ),
      );
      return;
    }

    try {
      final status = await FlutterContacts.permissions.request(PermissionType.read);
      if (status != PermissionStatus.granted) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contacts permission is required to import contacts.'),
          ),
        );
        return;
      }

      final contacts = await FlutterContacts.getAll(
        properties: {ContactProperty.phone, ContactProperty.name},
      );

      if (contacts.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No contacts found on device.')),
        );
        return;
      }

      if (!context.mounted) return;
      final provider = context.read<CustomerProvider>();
      final preview = await provider.prepareImportFromContacts(contacts);

      if (!context.mounted) return;
      if (preview.totalRows == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No valid contacts with phone numbers found.'),
          ),
        );
        return;
      }

      _showPreviewAndConfirm(context, preview);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading device contacts: $e')),
      );
    }
  }

  void _showPreviewAndConfirm(
    BuildContext context,
    CustomerImportPreview preview,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    var selectedOption = DuplicateHandlingOption.skipExisting;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (stateContext, setDialogState) {
          final totalEligible = preview.ready.length;

          return AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.rate_review_rounded, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.previewSummary,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(dialogContext),
                ),
              ],
            ),
            content: SizedBox(
              width: 540,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary stat cards
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStatChip(
                          label: '${l10n.totalRowsCount}: ${preview.totalRows}',
                          color: Colors.blue.shade50,
                          textColor: Colors.blue.shade800,
                        ),
                        _buildStatChip(
                          label: '${l10n.readyToImport}: ${preview.readyRows}',
                          color: Colors.green.shade50,
                          textColor: Colors.green.shade800,
                        ),
                        if (preview.duplicateRows > 0)
                          _buildStatChip(
                            label: '${l10n.duplicatesFound}: ${preview.duplicateRows}',
                            color: Colors.orange.shade50,
                            textColor: Colors.orange.shade800,
                          ),
                        if (preview.invalidRows > 0)
                          _buildStatChip(
                            label: '${l10n.invalidRowsCount}: ${preview.invalidRows}',
                            color: Colors.red.shade50,
                            textColor: Colors.red.shade800,
                          ),
                      ],
                    ),
                    if (preview.duplicateRows > 0) ...[
                      const SizedBox(height: 16),
                      Text(
                        l10n.duplicateHandling,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: RadioGroup<DuplicateHandlingOption>(
                          groupValue: selectedOption,
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedOption = val);
                            }
                          },
                          child: Column(
                            children: [
                              RadioListTile<DuplicateHandlingOption>(
                                value: DuplicateHandlingOption.skipExisting,
                                title: Text(
                                  l10n.skipExisting,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                subtitle: const Text(
                                  'Only new customers will be added. Existing records remain unchanged.',
                                  style: TextStyle(fontSize: 12),
                                ),
                                dense: true,
                              ),
                              const Divider(height: 1),
                              RadioListTile<DuplicateHandlingOption>(
                                value: DuplicateHandlingOption.updateExisting,
                                title: Text(
                                  l10n.updateExisting,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                subtitle: const Text(
                                  'Update name and details for existing matching phone numbers.',
                                  style: TextStyle(fontSize: 12),
                                ),
                                dense: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Preview Contacts (${preview.items.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 240),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: preview.items.length,
                        separatorBuilder: (c, i) => const Divider(height: 1),
                        itemBuilder: (c, i) {
                          final item = preview.items[i];
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: colorScheme.primaryContainer,
                              child: Text(
                                item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            title: Text(
                              item.name.isNotEmpty ? item.name : '(No Name)',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              item.mobile.isNotEmpty
                                  ? item.mobile
                                  : (item.rawMobile.isNotEmpty ? item.rawMobile : '(No Phone)'),
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            trailing: _buildStatusBadge(item.status),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l10n.cancel),
              ),
              FilledButton.icon(
                onPressed: totalEligible == 0
                    ? null
                    : () {
                        Navigator.pop(dialogContext);
                        _executeImport(context, preview, selectedOption);
                      },
                icon: const Icon(Icons.file_download_done_rounded),
                label: Text('${l10n.import} ($totalEligible)'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(CustomerImportRowStatus status) {
    Color bg;
    Color fg;
    String text;

    switch (status) {
      case CustomerImportRowStatus.ready:
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        text = 'Ready';
        break;
      case CustomerImportRowStatus.duplicateInStore:
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade700;
        text = 'Existing';
        break;
      case CustomerImportRowStatus.duplicateInBatch:
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        text = 'Duplicate in File';
        break;
      case CustomerImportRowStatus.invalidPhone:
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        text = 'Invalid Phone';
        break;
      case CustomerImportRowStatus.invalidName:
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        text = 'Missing Name';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _executeImport(
    BuildContext context,
    CustomerImportPreview preview,
    DuplicateHandlingOption duplicateHandling,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    // Show loading progress
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (c) => AlertDialog(
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 24),
              Expanded(
                child: Text(
                  l10n.importProgress,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final provider = context.read<CustomerProvider>();
      final result = await provider.importCustomers(
        rows: preview.ready,
        duplicateHandling: duplicateHandling,
      );

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog

      // Show Result Dialog
      showDialog(
        context: context,
        useRootNavigator: true,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green),
              const SizedBox(width: 12),
              Text(
                l10n.importResult,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                dense: true,
                leading: const Icon(Icons.person_add_alt_1, color: Colors.green),
                title: Text('${l10n.importedCount}: ${result.imported}'),
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.update, color: Colors.blue),
                title: Text('${l10n.updatedCount}: ${result.updated}'),
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.skip_next, color: Colors.grey),
                title: Text('${l10n.skippedCount}: ${result.skipped}'),
              ),
              if (result.errorCounts.isNotEmpty) ...[
                const Divider(),
                const Text(
                  'Errors:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                ...result.errorCounts.entries.map(
                  (e) => Text(
                    '${e.key}: ${e.value}',
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext, rootNavigator: true).pop(),
              child: Text(l10n.done),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to import customers: $e')),
      );
    }
  }
}

