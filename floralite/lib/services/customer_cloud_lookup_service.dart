import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../data/repositories/cloud_customer_repository.dart';
import '../data/repositories/customer_repository.dart';
import 'mobile_auth_service.dart';
import 'product_cloud_syncability_service.dart';

typedef CloudCustomerByPhoneFinder = Future<CloudCustomer?> Function(String phone);
typedef CustomerCloudOnlineCheck = Future<bool> Function();
typedef CustomerCurrentCompanyIdReader = Future<String?> Function();

/// Resolves a customer by phone for POS (Take Away, Pickup Later, Delivery)
/// using the tenant-scoped local cache first, falling back to Cloud lookup
/// (and caching the result) only when online and authenticated to a company.
class CustomerCloudLookupService {
  CustomerCloudLookupService({
    CustomerRepository? customerRepository,
    CloudCustomerByPhoneFinder? findCloudCustomerByPhone,
    CustomerCloudOnlineCheck? isOnline,
    CustomerCurrentCompanyIdReader? currentCompanyId,
    MobileAuthService? auth,
  })  : _customerRepository = customerRepository ?? CustomerRepository(),
        _findCloudCustomerByPhone =
            findCloudCustomerByPhone ?? CloudCustomerRepository().findByPhone,
        _isOnline = isOnline ?? _defaultOnlineCheck,
        _currentCompanyId = currentCompanyId ??
            (() => ProductCloudSyncabilityService.currentCompanyIdFromAuth(
                  auth ?? MobileAuthService(),
                ));

  final CustomerRepository _customerRepository;
  final CloudCustomerByPhoneFinder _findCloudCustomerByPhone;
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

  static Future<bool> _defaultOnlineCheck() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }
}
