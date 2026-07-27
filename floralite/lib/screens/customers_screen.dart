import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/customer_provider.dart';
import '../services/contact_picker_service.dart';
import '../widgets/common_widgets.dart';
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
      appBar: AppBar(
        title: Text(l10n.customers),
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
                                  name: customer['name'] as String,
                                  phone: customer['phone'] as String,
                                  lastOrder: customer['lastOrder'] as String,
                                  birthday: customer['birthday'] as String,
                                  pendingPayment:
                                      customer['pendingPayment'] as String,
                                  totalOrders: customer['totalOrders'] as int,
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
                                          child: Text(
                                            customer['name'] as String,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
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
                                            'C-${(customer['id'] as int).toString().padLeft(3, '0')}',
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
                                          child: Text(
                                            customer['phone'] as String,
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
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
      floatingActionButton: FloatingActionButton.extended(
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
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
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
                Navigator.pop(context);
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
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
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
                  await context.read<CustomerProvider>().updateCustomer(
                        id: customer['id'] as int,
                        phone: phone,
                        name: name,
                      );

              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.customerUpdatedSuccessfully)),
                  );
                } else {
                  final error = context.read<CustomerProvider>().error;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(error ?? l10n.failedToUpdateCustomer)),
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

  void _showDeleteConfirmDialog(
      BuildContext context, Map<String, dynamic> customer) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteCustomer),
        content: Text('${l10n.deleteCustomerConfirm} ${customer['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final success =
                  await context.read<CustomerProvider>().deleteCustomer(
                        customer['id'] as int,
                      );

              if (context.mounted) {
                Navigator.pop(context);
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
}
