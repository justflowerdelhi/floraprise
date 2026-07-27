import '../data/database/app_database.dart';
import '../data/catalogue/catalogue_installer.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/inventory_repository.dart';
import '../data/repositories/product_repository.dart';
import '../data/repositories/staff_repository.dart';
import 'business_settings_manager.dart';
import 'package:sqflite/sqflite.dart';

enum SetupStage {
  categories,
  products,
  staff,
  settings,
  ready,
}

class BusinessSetupInput {
  const BusinessSetupInput({
    required this.shopName,
    required this.mobile,
    required this.ownerName,
    required this.sameNumberForWhatsApp,
    required this.whatsApp,
    required this.gstRegistered,
    required this.gstNumber,
    required this.logoPath,
    required this.address,
    required this.city,
  });

  final String shopName;
  final String mobile;
  final String ownerName;
  final bool sameNumberForWhatsApp;
  final String whatsApp;
  final bool gstRegistered;
  final String gstNumber;
  final String logoPath;
  final String address;
  final String city;
}

class OnboardingSetupManager {
  final CategoryRepository _categoryRepository = CategoryRepository();
  final ProductRepository _productRepository = ProductRepository();
  final StaffRepository _staffRepository = StaffRepository();
  final BusinessSettingsManager _settingsManager = BusinessSettingsManager();

  static const List<String> _recommendedCategories = <String>[
    'Flowers',
    'Fillers',
    'Foliage',
    'Packing',
    'Accessories',
    'Chocolates',
    'Soft Toys',
    'Cakes',
    'Balloons',
    'Plants',
    'Vases',
    'Baskets',
    'Finished Bouquets',
    'Others',
  ];

  Future<void> runSetup({
    required bool installRecommended,
    required String languageCode,
    required BusinessSetupInput businessInput,
    required Future<void> Function(SetupStage stage) onStageDone,
  }) async {
    await _installRecommendedCategories();
    await onStageDone(SetupStage.categories);

    await _installMasterCatalogue(
      replaceLegacyDemoOnly: installRecommended,
    );
    await onStageDone(SetupStage.products);

    // Owner staff setup should not block onboarding completion.
    await _ensureOwnerStaff(
      onboardingPhone: businessInput.mobile,
      onboardingName: businessInput.ownerName,
    );
    await onStageDone(SetupStage.staff);

    await _configureBusinessSettings(
      input: businessInput,
      languageCode: languageCode,
    );
    await onStageDone(SetupStage.settings);

    await onStageDone(SetupStage.ready);
  }

  Future<void> _installRecommendedCategories() async {
    final existing =
        await _categoryRepository.listCategories(includeInactive: true);
    final existingSet =
        existing.map((e) => e.name.trim().toLowerCase()).toSet();

    for (final name in _recommendedCategories) {
      if (existingSet.contains(name.toLowerCase())) {
        continue;
      }
      await _categoryRepository.createCategory(
        name: name,
        defaultUnit: _defaultUnitForCategory(name),
      );
    }
  }

  Future<void> _installMasterCatalogue({
    required bool replaceLegacyDemoOnly,
  }) async {
    final installer = CatalogueInstaller(
      productRepository: _productRepository,
      inventoryRepository: InventoryRepository(),
    );
    await installer.installStarterCatalogue(
      replaceLegacyDemoOnly: replaceLegacyDemoOnly,
    );
  }

  Future<void> _ensureOwnerStaff({
    required String onboardingPhone,
    required String onboardingName,
  }) async {
    final all = await _staffRepository.getAll();
    final owner = all.where((s) => s.role == StaffRole.owner).toList();

    if (owner.isNotEmpty) {
      final existing = owner.first;
      try {
        await _staffRepository.update(
          existing.id,
          StaffUpsertInput(
            name: onboardingName,
            phone: onboardingPhone,
            whatsapp: onboardingPhone,
            sameAsPhone: true,
            role: StaffRole.owner,
            city: existing.city,
            address: existing.address,
            joiningDate: existing.joiningDate,
            salaryType: existing.salaryType,
            salaryAmount: existing.salaryAmount,
            active: true,
            notes: existing.notes,
          ),
        );
      } on StateError catch (_) {
        // If the onboarding phone already belongs to another staff member,
        // keep current owner phone and continue onboarding.
        await _staffRepository.update(
          existing.id,
          StaffUpsertInput(
            name: onboardingName,
            phone: existing.phone,
            whatsapp: existing.whatsapp ?? existing.phone,
            sameAsPhone: existing.sameAsPhone,
            role: StaffRole.owner,
            city: existing.city,
            address: existing.address,
            joiningDate: existing.joiningDate,
            salaryType: existing.salaryType,
            salaryAmount: existing.salaryAmount,
            active: true,
            notes: existing.notes,
          ),
        );
      } on DatabaseException catch (error) {
        if (error
            .toString()
            .contains('UNIQUE constraint failed: staff.phone')) {
          await _staffRepository.update(
            existing.id,
            StaffUpsertInput(
              name: onboardingName,
              phone: existing.phone,
              whatsapp: existing.whatsapp ?? existing.phone,
              sameAsPhone: existing.sameAsPhone,
              role: StaffRole.owner,
              city: existing.city,
              address: existing.address,
              joiningDate: existing.joiningDate,
              salaryType: existing.salaryType,
              salaryAmount: existing.salaryAmount,
              active: true,
              notes: existing.notes,
            ),
          );
        } else {
          rethrow;
        }
      }
      return;
    }

    try {
      await _staffRepository.create(
        StaffUpsertInput(
          name: onboardingName,
          phone: onboardingPhone,
          whatsapp: onboardingPhone,
          sameAsPhone: true,
          role: StaffRole.owner,
          active: true,
        ),
      );
    } on StateError catch (_) {
      // Fallback when the onboarding phone is already used by another staff.
      final fallbackPhone = 'OWNER_${DateTime.now().millisecondsSinceEpoch}';
      await _staffRepository.create(
        StaffUpsertInput(
          name: onboardingName,
          phone: fallbackPhone,
          whatsapp: fallbackPhone,
          sameAsPhone: true,
          role: StaffRole.owner,
          active: true,
        ),
      );
    } on DatabaseException catch (error) {
      if (error.toString().contains('UNIQUE constraint failed: staff.phone')) {
        final fallbackPhone = 'OWNER_${DateTime.now().millisecondsSinceEpoch}';
        await _staffRepository.create(
          StaffUpsertInput(
            name: onboardingName,
            phone: fallbackPhone,
            whatsapp: fallbackPhone,
            sameAsPhone: true,
            role: StaffRole.owner,
            active: true,
          ),
        );
      } else {
        rethrow;
      }
    }
  }

  Future<void> _configureBusinessSettings({
    required BusinessSetupInput input,
    required String languageCode,
  }) async {
    await _settingsManager.setShopName(input.shopName);
    await _settingsManager.setOwnerName(input.ownerName);
    await _settingsManager.setPhone(input.mobile);
    await _settingsManager.setWhatsapp(
        input.sameNumberForWhatsApp ? input.mobile : input.whatsApp);
    await _settingsManager.setSamePhoneAsWhatsapp(input.sameNumberForWhatsApp);
    await _settingsManager.setAddress(input.address);
    await _settingsManager.setGstRegistered(input.gstRegistered);
    await _settingsManager
        .setGstNumber(input.gstRegistered ? input.gstNumber : '');
    await _settingsManager.setLogoPath(input.logoPath);
    await _settingsManager.saveBusinessProfile(
      shopName: input.shopName,
      ownerName: input.ownerName,
      mobileNumber: input.mobile,
      address: input.address,
      city: input.city,
      gstRegistered: input.gstRegistered,
      gstNumber: input.gstRegistered ? input.gstNumber : null,
    );

    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    await db.insert(
      'settings',
      {
        'key': 'language',
        'value': languageCode,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.insert(
      'settings',
      {
        'key': 'business.default_gst_percent',
        'value': input.gstRegistered ? '12' : '0',
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.insert(
      'settings',
      {
        'key': 'printer.auto_connect',
        'value': '0',
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  String _defaultUnitForCategory(String category) {
    switch (category) {
      case 'Flowers':
        return 'Stem';
      case 'Fillers':
      case 'Foliage':
        return 'Bunch';
      case 'Plants':
        return 'Pot';
      case 'Packing':
        return 'Roll';
      case 'Chocolates':
        return 'Box';
      default:
        return 'Piece';
    }
  }
}
