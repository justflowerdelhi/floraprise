import 'package:sqflite/sqflite.dart';

import '../data/database/app_database.dart';
import 'mobile_auth_service.dart';

typedef ProductCloudCurrentCompanyIdReader = Future<String?> Function();

class ProductCloudSyncabilityResult {
  const ProductCloudSyncabilityResult.unavailable()
      : isSyncable = false,
        localProductId = null,
        cloudProductId = null;

  const ProductCloudSyncabilityResult.syncable({
    required this.localProductId,
    required this.cloudProductId,
  }) : isSyncable = true;

  final bool isSyncable;
  final int? localProductId;
  final String? cloudProductId;
}

class ProductCloudSyncabilityService {
  ProductCloudSyncabilityService({
    ProductCloudCurrentCompanyIdReader? currentCompanyId,
    MobileAuthService? auth,
  }) : _currentCompanyId = currentCompanyId ??
            (() => currentCompanyIdFromAuth(auth ?? MobileAuthService()));

  final ProductCloudCurrentCompanyIdReader _currentCompanyId;

  Future<ProductCloudSyncabilityResult> evaluate({
    required int localProductId,
    DatabaseExecutor? db,
  }) async {
    final executor = db ?? await AppDatabase.instance.database;
    final currentCompanyId = normalizeUuid(await _currentCompanyId());
    if (currentCompanyId == null) {
      return const ProductCloudSyncabilityResult.unavailable();
    }

    final rows = await executor.query(
      'products',
      columns: [
        'id',
        'active',
        'deleted_at',
        'cloud_product_id',
        'cloud_product_company_id',
      ],
      where: 'id = ?',
      whereArgs: [localProductId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return const ProductCloudSyncabilityResult.unavailable();
    }

    final row = rows.single;
    final active = (row['active'] as int? ?? 1) == 1;
    final deletedAt = (row['deleted_at'] as String?)?.trim();
    if (!active || (deletedAt != null && deletedAt.isNotEmpty)) {
      return const ProductCloudSyncabilityResult.unavailable();
    }

    final cloudProductId = normalizeUuid(row['cloud_product_id'] as String?);
    final cloudCompanyId =
        normalizeUuid(row['cloud_product_company_id'] as String?);
    if (cloudProductId == null || cloudCompanyId == null) {
      return const ProductCloudSyncabilityResult.unavailable();
    }
    if (cloudCompanyId != currentCompanyId) {
      return const ProductCloudSyncabilityResult.unavailable();
    }

    return ProductCloudSyncabilityResult.syncable(
      localProductId: localProductId,
      cloudProductId: cloudProductId,
    );
  }

  static Future<String?> currentCompanyIdFromAuth(MobileAuthService auth) async {
    final bootstrap = await auth.readBootstrap();
    final company = bootstrap?['company'];
    if (company is Map) {
      return (company['id'] ?? company['Id'])?.toString();
    }
    return null;
  }

  static String? normalizeUuid(String? value) {
    final trimmed = value?.trim() ?? '';
    final parsed = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    return parsed.hasMatch(trimmed) ? trimmed.toLowerCase() : null;
  }
}