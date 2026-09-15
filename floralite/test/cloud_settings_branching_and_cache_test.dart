import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/managers/reward_manager.dart';
import 'package:floraprise/models/share_branding.dart';
import 'package:floraprise/models/storage_mode.dart';
import 'package:floraprise/services/mobile_auth_service.dart';
import 'package:floraprise/services/share_branding_settings_service.dart';
import 'package:floraprise/services/storage_mode_service.dart';
import 'package:floraprise/data/repositories/cloud_rewards_settings_repository.dart';
import 'package:floraprise/data/repositories/cloud_share_branding_settings_repository.dart';

class _FakeStorageModeService extends StorageModeService {
  _FakeStorageModeService(this._mode);
  final StorageMode _mode;

  @override
  Future<StorageMode?> getCurrentMode() async => _mode;

  @override
  Future<bool> isCloud() async => _mode == StorageMode.cloud;

  @override
  Future<bool> isLocal() async => _mode == StorageMode.local;
}

class _FakeAuthService extends MobileAuthService {
  @override
  String get baseUrl => 'https://api.test.com';

  @override
  Future<String?> getStoredAccessToken() async => 'test_access_token';
}

class _MockCloudRewardsRepo extends CloudRewardsSettingsRepository {
  int fetchCallCount = 0;
  int saveCallCount = 0;
  RewardSettings settings = const RewardSettings(
    enabled: true,
    earnSpendPaisePerPoint: 9999,
    minimumBillPaise: 11111,
    pointValuePaise: 222,
    maximumRedemptionPercent: 33,
    expiryDays: 77,
  );

  @override
  Future<RewardSettings> fetchSettings({required String baseUrl, required String accessToken}) async {
    fetchCallCount++;
    return settings;
  }

  @override
  Future<RewardSettings> saveSettings({
    required String baseUrl,
    required String accessToken,
    required RewardSettings settings,
  }) async {
    saveCallCount++;
    this.settings = settings;
    return settings;
  }
}

class _MockCloudBrandingRepo extends CloudShareBrandingSettingsRepository {
  int fetchCallCount = 0;
  int saveCallCount = 0;
  ShareBrandingSettings settings = const ShareBrandingSettings(
    showPrice: false,
    showShopName: true,
    showPhoneNumber: false,
    showLogo: true,
    showWatermark: true,
    showWatermarkBusinessName: false,
    showWatermarkCity: true,
    watermarkOpacity: 0.9,
    watermarkSize: WatermarkSize.large,
    watermarkPosition: WatermarkPosition.topRight,
    showWebsite: false,
    footerColor: Color(0xFF112233),
  );

  @override
  Future<ShareBrandingSettings> fetchSettings({required String baseUrl, required String accessToken}) async {
    fetchCallCount++;
    return settings;
  }

  @override
  Future<ShareBrandingSettings> saveSettings({
    required String baseUrl,
    required String accessToken,
    required ShareBrandingSettings settings,
  }) async {
    saveCallCount++;
    this.settings = settings;
    return settings;
  }
}

void main() {
  group('Cloud Branching and In-Memory Caching', () {
    test('RewardManager caches Cloud settings in memory and invalidates on save', () async {
      final cloudRepo = _MockCloudRewardsRepo();
      final manager = RewardManager(
        storageModeService: _FakeStorageModeService(StorageMode.cloud),
        authService: _FakeAuthService(),
        cloudRepository: cloudRepo,
      );

      // First load fetches from network
      final first = await manager.loadSettings();
      expect(first.earnSpendPaisePerPoint, 9999);
      expect(cloudRepo.fetchCallCount, 1);

      // Second load uses memory cache (does not re-hit network)
      final second = await manager.loadSettings();
      expect(second.earnSpendPaisePerPoint, 9999);
      expect(cloudRepo.fetchCallCount, 1);

      // Save updates cache and calls saveSettings
      const updated = RewardSettings(
        enabled: true,
        earnSpendPaisePerPoint: 5555,
        minimumBillPaise: 22222,
        pointValuePaise: 333,
        maximumRedemptionPercent: 10,
        expiryDays: 50,
      );
      await manager.saveSettings(updated);
      expect(cloudRepo.saveCallCount, 1);

      // Subsequent load returns updated settings without extra fetch
      final third = await manager.loadSettings();
      expect(third.earnSpendPaisePerPoint, 5555);
      expect(cloudRepo.fetchCallCount, 1);

      // Explicit forceRefresh re-fetches
      await manager.loadSettings(forceRefresh: true);
      expect(cloudRepo.fetchCallCount, 2);
    });

    test('ShareBrandingSettingsService branches to Cloud repository in cloud mode', () async {
      final cloudRepo = _MockCloudBrandingRepo();
      final service = ShareBrandingSettingsService(
        storageModeService: _FakeStorageModeService(StorageMode.cloud),
        authService: _FakeAuthService(),
        cloudRepository: cloudRepo,
      );

      final loaded = await service.loadSettings();
      expect(loaded.watermarkOpacity, 0.9);
      expect(loaded.watermarkSize, WatermarkSize.large);
      expect(cloudRepo.fetchCallCount, 1);

      final toSave = loaded.copyWith(watermarkOpacity: 0.65);
      await service.saveSettings(toSave);
      expect(cloudRepo.saveCallCount, 1);
      expect(cloudRepo.settings.watermarkOpacity, 0.65);
    });
  });
}
