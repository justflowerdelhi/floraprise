import 'package:connectivity_plus/connectivity_plus.dart';

import '../data/repositories/cloud_product_repository.dart';
import '../data/repositories/product_repository.dart';
import 'mobile_auth_service.dart';
import 'product_cloud_syncability_service.dart';

typedef CloudProductVerifier = Future<CloudProduct> Function(String id);
typedef CloudOnlineCheck = Future<bool> Function();
typedef CurrentCompanyIdReader = Future<String?> Function();

class ProductCloudLinkingService {
  ProductCloudLinkingService({
    ProductRepository? productRepository,
    CloudProductVerifier? verifyCloudProduct,
    CloudOnlineCheck? isOnline,
    CurrentCompanyIdReader? currentCompanyId,
    MobileAuthService? auth,
  })  : _productRepository = productRepository ?? ProductRepository(),
        _verifyCloudProduct =
            verifyCloudProduct ?? CloudProductRepository().getProduct,
        _isOnline = isOnline ?? _defaultOnlineCheck,
        _currentCompanyId = currentCompanyId ??
            (() => ProductCloudSyncabilityService.currentCompanyIdFromAuth(
                  auth ?? MobileAuthService(),
                ));

  final ProductRepository _productRepository;
  final CloudProductVerifier _verifyCloudProduct;
  final CloudOnlineCheck _isOnline;
  final CurrentCompanyIdReader _currentCompanyId;

  Future<void> linkCloudProduct({
    required int localProductId,
    required String cloudProductId,
  }) async {
    final verified = await _verifyLinkAllowed(cloudProductId);
    await _productRepository.setCloudProductId(
      localProductId,
      verified.cloudProductId,
      verified.cloudProductCompanyId!,
    );
  }

  Future<void> changeCloudProduct({
    required int localProductId,
    required String cloudProductId,
  }) async {
    await _ensureNoProtectedOutboxReference(localProductId, 'change');
    final verified = await _verifyLinkAllowed(cloudProductId);
    await _productRepository.setCloudProductId(
      localProductId,
      verified.cloudProductId,
      verified.cloudProductCompanyId!,
    );
  }

  Future<void> unlinkCloudProduct({required int localProductId}) async {
    await _ensureNoProtectedOutboxReference(localProductId, 'unlink');
    await _productRepository.clearCloudProductId(localProductId);
  }

  Future<ProductCloudMapping> _verifyLinkAllowed(String cloudProductId) async {
    if (!await _isOnline()) {
      throw StateError('Cloud authentication and internet are required to link products.');
    }

    final product = await _verifyCloudProduct(cloudProductId);
    if (!product.isActive) {
      throw StateError('Inactive Cloud products cannot be linked.');
    }
    final companyId = await _currentCompanyId();
    final normalizedCompanyId =
        ProductCloudSyncabilityService.normalizeUuid(companyId);
    if (normalizedCompanyId == null) {
      throw StateError('Current authenticated company is not available.');
    }
    final normalizedProductId =
        ProductCloudSyncabilityService.normalizeUuid(product.id);
    if (normalizedProductId == null) {
      throw StateError('Cloud API returned an invalid product ID.');
    }
    return ProductCloudMapping(
      cloudProductId: normalizedProductId,
      cloudProductCompanyId: normalizedCompanyId,
    );
  }

  Future<void> _ensureNoProtectedOutboxReference(
    int localProductId,
    String action,
  ) async {
    final protected = await _productRepository
        .hasProtectedPosSyncOutboxReference(localProductId);
    if (protected) {
      throw StateError(
        'Cannot $action this Cloud link while a pending POS sync references this local product.',
      );
    }
  }

  static Future<bool> _defaultOnlineCheck() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }
}