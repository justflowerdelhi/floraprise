import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../data/repositories/cloud_customer_repository.dart';
import '../data/repositories/customer_repository.dart';
import 'mobile_auth_service.dart';
import 'product_cloud_syncability_service.dart';

typedef CloudCustomerByPhoneFinder = Future<CloudCustomer?> Function(String phone);
typedef CloudCustomerSearcher = Future<List<CloudCustomer>> Function({String? query});
typedef CustomerCloudOnlineCheck = Future<bool> Function();
typedef CustomerCurrentCompanyIdReader = Future<String?> Function();

/// Resolves a customer by phone or search query for POS (Take Away, Pickup Later, Delivery)
/// using the tenant-scoped local cache first, falling back to Cloud lookup
/// (and caching the result) only when online and authenticated to a company.
class CustomerCloudLookupService {
  CustomerCloudLookupService({
    CustomerRepository? customerRepository,
    CloudCustomerByPhoneFinder? findCloudCustomerByPhone,
    CloudCustomerSearcher? cloudSearcher,
    CustomerCloudOnlineCheck? isOnline,
    CustomerCurrentCompanyIdReader? currentCompanyId,
    MobileAuthService? auth,
  })  : _customerRepository = customerRepository ?? CustomerRepository(),
        _findCloudCustomerByPhone =
            findCloudCustomerByPhone ?? CloudCustomerRepository().findByPhone,
        _cloudSearcher = cloudSearcher ??
            (({String? query}) => CloudCustomerRepository().getAll(query: query)),
        _isOnline = isOnline ?? _defaultOnlineCheck,
        _currentCompanyId = currentCompanyId ??
            (() => ProductCloudSyncabilityService.currentCompanyIdFromAuth(
                  auth ?? MobileAuthService(),
                ));

  final CustomerRepository _customerRepository;
  final CloudCustomerByPhoneFinder _findCloudCustomerByPhone;
  final CloudCustomerSearcher _cloudSearcher;
  final CustomerCloudOnlineCheck _isOnline;
  final CustomerCurrentCompanyIdReader _currentCompanyId;

  Future<CustomerRecord?> lookupByPhone(String normalizedPhone) async {
    if (normalizedPhone.length != 10) return null;

    final companyId = ProductCloudSyncabilityService.normalizeUuid(
      await _currentCompanyId(),
    );
    if (kIsWeb) {
      final cloudCustomer = await _findCloudCustomerByPhone(normalizedPhone);
      if (cloudCustomer == null || cloudCustomer.id.isEmpty) return null;
      final linkPhone = (cloudCustomer.phone ?? '').trim();
      return CustomerRecord(
        id: -1,
        phone: linkPhone.isNotEmpty ? linkPhone : normalizedPhone,
        name: cloudCustomer.name,
        cloudCustomerId: cloudCustomer.id,
        cloudCompanyId: companyId,
        createdAt: DateTime.now().toIso8601String(),
      );
    }

    if (companyId == null) {
      // Not authenticated to a Cloud company; behave like Local mode.
      return _customerRepository.findByPhone(normalizedPhone);
    }

    final cached = await _customerRepository.findByPhone(
      normalizedPhone,
      companyId: companyId,
    );
    if (cached != null) return cached;

    if (!await _isOnline()) return null;

    final cloudCustomer = await _findCloudCustomerByPhone(normalizedPhone);
    if (cloudCustomer == null || cloudCustomer.id.isEmpty) return null;

    final linkPhone = (cloudCustomer.phone ?? '').trim();
    return _customerRepository.upsertFromCloud(
      cloudCustomerId: cloudCustomer.id,
      cloudCompanyId: companyId,
      phone: linkPhone.isNotEmpty ? linkPhone : normalizedPhone,
      name: cloudCustomer.name,
    );
  }

  Future<List<CustomerRecord>> search(
    String query, {
    bool isCloud = false,
  }) async {
    final trimmedQuery = query.trim();

    if (kIsWeb) {
      final companyId = ProductCloudSyncabilityService.normalizeUuid(
        await _currentCompanyId(),
      );
      try {
        final cloudResults = await _cloudSearcher(
          query: trimmedQuery.isEmpty ? null : trimmedQuery,
        );
        return cloudResults.map((c) {
          final linkPhone = (c.phone ?? '').trim();
          return CustomerRecord(
            id: -1,
            phone: linkPhone,
            name: c.name,
            cloudCustomerId: c.id,
            cloudCompanyId: companyId,
            createdAt: DateTime.now().toIso8601String(),
          );
        }).toList();
      } catch (e) {
        debugPrint('CustomerCloudLookupService Web search error: $e');
        return const [];
      }
    }

    if (!isCloud) {
      return trimmedQuery.isEmpty
          ? _customerRepository.getAll()
          : _customerRepository.search(trimmedQuery);
    }

    final companyId = ProductCloudSyncabilityService.normalizeUuid(
      await _currentCompanyId(),
    );

    final cached = companyId == null
        ? (trimmedQuery.isEmpty
            ? await _customerRepository.getAll()
            : await _customerRepository.search(trimmedQuery))
        : await _customerRepository.search(trimmedQuery, companyId: companyId);

    if (companyId == null) {
      return cached;
    }

    if (!await _isOnline()) {
      return cached;
    }

    try {
      final cloudResults = await _cloudSearcher(
        query: trimmedQuery.isEmpty ? null : trimmedQuery,
      );
      if (cloudResults.isEmpty) {
        return cached;
      }

      for (final cloudCustomer in cloudResults) {
        if (cloudCustomer.id.trim().isEmpty) {
          continue;
        }

        final trimmedPhone = (cloudCustomer.phone ?? '').trim();
        try {
          await _customerRepository.upsertFromCloud(
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

      return await _customerRepository.search(trimmedQuery, companyId: companyId);
    } catch (_) {
      return cached;
    }
  }

  static Future<bool> _defaultOnlineCheck() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }
}
