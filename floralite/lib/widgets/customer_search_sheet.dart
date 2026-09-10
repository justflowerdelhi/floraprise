import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repositories/cloud_customer_repository.dart';
import '../data/repositories/customer_repository.dart';
import '../l10n/app_localizations.dart';
import '../providers/storage_mode_provider.dart';
import '../services/mobile_auth_service.dart';
import '../services/product_cloud_syncability_service.dart';

typedef DeliveryCloudCustomerSearcher = Future<List<CloudCustomer>> Function({String? query});
typedef DeliveryCompanyIdReader = Future<String?> Function();
typedef DeliveryOnlineChecker = Future<bool> Function();

class DeliveryCustomerSearchService {
  DeliveryCustomerSearchService({
    CustomerRepository? repository,
    DeliveryCloudCustomerSearcher? cloudSearcher,
    DeliveryCompanyIdReader? currentCompanyId,
    DeliveryOnlineChecker? isOnline,
  })  : _repository = repository ?? CustomerRepository(),
        _cloudSearcher = cloudSearcher ??
            (({String? query}) => CloudCustomerRepository().getAll(query: query)),
        _currentCompanyId = currentCompanyId ??
            (() => ProductCloudSyncabilityService.currentCompanyIdFromAuth(
                  MobileAuthService(),
                )),
        _isOnline = isOnline ?? _defaultOnlineCheck;

  final CustomerRepository _repository;
  final DeliveryCloudCustomerSearcher _cloudSearcher;
  final DeliveryCompanyIdReader _currentCompanyId;
  final DeliveryOnlineChecker _isOnline;

  Future<List<CustomerRecord>> search(
    String query, {
    required bool isCloud,
  }) async {
    final trimmedQuery = query.trim();

    if (!isCloud) {
      return trimmedQuery.isEmpty
          ? _repository.getAll()
          : _repository.search(trimmedQuery);
    }

    final companyId = ProductCloudSyncabilityService.normalizeUuid(
      await _currentCompanyId(),
    );

    final cached = companyId == null
        ? (trimmedQuery.isEmpty
            ? await _repository.getAll()
            : await _repository.search(trimmedQuery))
        : await _repository.search(trimmedQuery, companyId: companyId);

    if (companyId == null) {
      return cached;
    }

    if (!await _isOnline()) {
      return cached;
    }

    final cloudResults = await _cloudSearcher(query: trimmedQuery.isEmpty ? null : trimmedQuery);
    if (cloudResults.isEmpty) {
      return cached;
    }

    for (final cloudCustomer in cloudResults) {
      if (cloudCustomer.id.trim().isEmpty) {
        continue;
      }

      final trimmedPhone = (cloudCustomer.phone ?? '').trim();
      try {
        await _repository.upsertFromCloud(
          cloudCustomerId: cloudCustomer.id,
          cloudCompanyId: companyId,
          phone: trimmedPhone.isEmpty ? '' : trimmedPhone,
          name: cloudCustomer.name,
          notes: cloudCustomer.notes ?? '',
        );
      } on ArgumentError {
        // Ignore Cloud rows that conflict with a different tenant's cached phone.
        continue;
      }
    }

    return await _repository.search(trimmedQuery, companyId: companyId);
  }

  static Future<bool> _defaultOnlineCheck() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }
}

class CustomerSearchSheet extends StatefulWidget {
  const CustomerSearchSheet({super.key, required this.repository});

  final CustomerRepository repository;

  @override
  State<CustomerSearchSheet> createState() => _CustomerSearchSheetState();
}

class _CustomerSearchSheetState extends State<CustomerSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  List<CustomerRecord> _results = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    setState(() => _isLoading = true);

    try {
      final isCloud = context.read<StorageModeProvider?>()?.isCloud ?? false;
      final rows = await DeliveryCustomerSearchService(
        repository: widget.repository,
      ).search(query, isCloud: isCloud);

      if (!mounted) return;
      setState(() {
        _results = rows;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = const [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.searchCustomer,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: _search,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? Center(child: Text(l10n.noCustomersFound))
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _results[index];
                          return ListTile(
                            title: Text(item.name),
                            subtitle: Text(item.phone),
                            onTap: () => Navigator.pop(context, item),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
