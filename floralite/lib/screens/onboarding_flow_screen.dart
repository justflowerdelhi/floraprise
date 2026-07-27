import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../controllers/voice_dictation_controller.dart';
import '../managers/onboarding_manager.dart';
import '../managers/onboarding_setup_manager.dart';
import '../managers/business_settings_manager.dart';
import '../l10n/app_localizations.dart';
import '../models/license.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../providers/license_provider.dart';
import '../services/speech_recognition_service.dart';
import '../widgets/voice_dictation_field_header.dart';

class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  final OnboardingManager _onboardingManager = OnboardingManager();
  final OnboardingSetupManager _setupManager = OnboardingSetupManager();
  final BusinessSettingsManager _businessSettingsManager =
      BusinessSettingsManager();
  final ImagePicker _imagePicker = ImagePicker();

  int _stepIndex = 0;
  bool _recommendedSetup = true;
  bool _sameNumberForWhatsApp = true;
  bool _gstRegistered = false;
  String _logoPath = '';
  bool _isPreparing = false;
  bool _setupFailed = false;
  String? _setupError;
  final Set<SetupStage> _doneStages = <SetupStage>{};

  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _whatsAppController = TextEditingController();
  final TextEditingController _gstNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final VoiceDictationController _addressDictationController =
      VoiceDictationController(
    speechRecognition: SpeechRecognitionService(),
  );

  @override
  void initState() {
    super.initState();
    _addressDictationController.bindController(_addressController);
    _loadPersistedLogo();
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _mobileController.dispose();
    _ownerNameController.dispose();
    _whatsAppController.dispose();
    _gstNumberController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _addressDictationController.dispose();
    super.dispose();
  }

  Future<void> _loadPersistedLogo() async {
    final savedLogoPath = await _businessSettingsManager.getLogoPath();
    if (!mounted || savedLogoPath.isEmpty) return;
    setState(() => _logoPath = savedLogoPath);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final body = switch (_stepIndex) {
      0 => _buildLanguageStep(l10n),
      1 => _buildWelcomeStep(l10n),
      2 => _buildBusinessSetupStep(l10n),
      3 => _buildRecommendedStep(l10n),
      4 => _buildPermissionsStep(l10n),
      _ => _buildPreparingStep(l10n),
    };

    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: body,
        ),
      ),
    );
  }

  Widget _buildLanguageStep(AppLocalizations l10n) {
    final provider = context.watch<LanguageProvider>();
    final selected = provider.currentLocale.languageCode;

    return Padding(
      key: const ValueKey<String>('language'),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.onboardingChooseLanguage,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _languageTile('en', '🇬🇧 English', selected),
          _languageTile('hi', '🇮🇳 हिन्दी', selected),
          _languageTile('gu', '🇮🇳 ગુજરાતી', selected),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _goTo(1),
              child: Text(l10n.next),
            ),
          ),
        ],
      ),
    );
  }

  Widget _languageTile(String code, String label, String selected) {
    final isSelected = selected == code;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(label),
        trailing: isSelected ? const Icon(Icons.check_circle) : null,
        onTap: () async {
          await context.read<LanguageProvider>().setLanguage(code);
          await _onboardingManager.setLanguageSelected(true);
          if (!mounted) return;
          setState(() {});
        },
      ),
    );
  }

  Widget _buildWelcomeStep(AppLocalizations l10n) {
    return Padding(
      key: const ValueKey<String>('welcome'),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          Center(
            child: Image.asset(
              'assets/icon.png',
              width: 96,
              height: 96,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Floraprise',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingPoweringModernFlorists,
            style: TextStyle(fontSize: 16, color: Colors.green.shade700),
          ),
          const SizedBox(height: 28),
          Text(
            l10n.onboardingWelcomeTitle,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.onboardingWelcomeBody,
            style: const TextStyle(fontSize: 17, height: 1.4),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _goTo(2),
              child: Text(l10n.onboardingGetStarted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessSetupStep(AppLocalizations l10n) {
    return SingleChildScrollView(
      key: const ValueKey<String>('business'),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.onboardingBusinessSetup,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _shopNameController,
            textCapitalization: TextCapitalization.words,
            decoration:
                InputDecoration(labelText: l10n.onboardingShopNameRequired),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _mobileController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration:
                InputDecoration(labelText: l10n.onboardingMobileNumberRequired),
            onChanged: (value) {
              if (_sameNumberForWhatsApp) {
                _whatsAppController.text = value;
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ownerNameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Owner Name *'),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _sameNumberForWhatsApp,
            onChanged: (value) {
              setState(() {
                _sameNumberForWhatsApp = value ?? true;
                if (_sameNumberForWhatsApp) {
                  _whatsAppController.text = _mobileController.text;
                }
              });
            },
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(l10n.onboardingUseSameWhatsapp),
          ),
          if (!_sameNumberForWhatsApp) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _whatsAppController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration:
                  InputDecoration(labelText: l10n.onboardingWhatsappNumber),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            l10n.onboardingGstRegisteredRequired,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ChoiceChip(
                label: Text(l10n.yes),
                selected: _gstRegistered,
                onSelected: (value) {
                  if (!value) return;
                  setState(() => _gstRegistered = true);
                },
              ),
              const SizedBox(width: 10),
              ChoiceChip(
                label: Text(l10n.no),
                selected: !_gstRegistered,
                onSelected: (value) {
                  if (!value) return;
                  setState(() {
                    _gstRegistered = false;
                    _gstNumberController.clear();
                  });
                },
              ),
            ],
          ),
          if (_gstRegistered) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _gstNumberController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(labelText: l10n.onboardingGstNumber),
            ),
          ],
          const SizedBox(height: 18),
          _buildLogoPicker(l10n),
          const SizedBox(height: 12),
          VoiceDictationFieldHeader(
            label: 'Address *',
            controller: _addressDictationController,
          ),
          TextField(
            controller: _addressController,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cityController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'City *'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _validateBusinessStep,
              child: Text(l10n.next),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoPicker(AppLocalizations l10n) {
    final hasLogo = _logoPath.trim().isNotEmpty;
    final logoFile = hasLogo ? File(_logoPath) : null;
    final logoExists = logoFile != null && logoFile.existsSync();

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _showLogoSourceSheet,
            child: SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade100,
                    backgroundImage: logoExists ? FileImage(logoFile) : null,
                    child: logoExists
                        ? null
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🏪', style: TextStyle(fontSize: 26)),
                              const SizedBox(height: 4),
                              Text(
                                'Logo',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            hasLogo && logoExists
                ? l10n.onboardingLogoSelected
                : l10n.onboardingShopLogoOptional,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (hasLogo && logoExists) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _removeLogo,
              icon: const Icon(Icons.delete_outline),
              label: Text(l10n.delete),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendedStep(AppLocalizations l10n) {
    return Padding(
      key: const ValueKey<String>('recommended'),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.onboardingRecommendedTitle,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.onboardingRecommendedBody,
            style: const TextStyle(fontSize: 16, height: 1.4),
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              title: Text(l10n.onboardingRecommendedDefault),
              subtitle: Text(l10n.onboardingRecommendedSubtitle),
              trailing: _recommendedSetup
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: () => setState(() => _recommendedSetup = true),
            ),
          ),
          Card(
            child: ListTile(
              title: Text(l10n.onboardingSkip),
              trailing: !_recommendedSetup
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: () => setState(() => _recommendedSetup = false),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _goTo(4),
              child: Text(l10n.next),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsStep(AppLocalizations l10n) {
    return Padding(
      key: const ValueKey<String>('permissions'),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.onboardingPermissionsTitle,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _permissionRow(Icons.contacts, l10n.onboardingContactsPermission),
          _permissionRow(Icons.camera_alt, l10n.onboardingCameraPermission),
          _permissionRow(Icons.folder, l10n.onboardingStoragePermission),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _requestPermissionsAndContinue,
              child: Text(l10n.onboardingContinue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _permissionRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(text),
        ),
      ),
    );
  }

  Widget _buildPreparingStep(AppLocalizations l10n) {
    if (!_isPreparing && !_setupFailed) {
      _isPreparing = true;
      _runSetup();
    }

    return Padding(
      key: const ValueKey<String>('preparing'),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.onboardingPreparingTitle,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _progressItem(
              l10n.onboardingCreatingCategories, SetupStage.categories),
          _progressItem(l10n.onboardingCreatingProducts, SetupStage.products),
          _progressItem(l10n.onboardingCreatingStaff, SetupStage.staff),
          _progressItem(
              l10n.onboardingConfiguringSettings, SetupStage.settings),
          _progressItem(l10n.onboardingReady, SetupStage.ready),
          const SizedBox(height: 20),
          if (_setupFailed) ...[
            Text(
              _setupError ?? l10n.onboardingSetupFailed,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _setupFailed = false;
                    _setupError = null;
                    _doneStages.clear();
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Setup'),
              ),
            ),
          ] else
            const LinearProgressIndicator(),
        ],
      ),
    );
  }

  Widget _progressItem(String label, SetupStage stage) {
    final done = _doneStages.contains(stage);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: done ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
    );
  }

  Future<void> _pickLogo(ImageSource source) async {
    final image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 1600,
    );
    if (image == null || !mounted) return;

    final selectedPath = image.path.trim();
    setState(() => _logoPath = selectedPath);
    await _businessSettingsManager.setLogoPath(selectedPath);
  }

  Future<void> _removeLogo() async {
    setState(() => _logoPath = '');
    await _businessSettingsManager.setLogoPath('');
  }

  Future<void> _showLogoSourceSheet() async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext)!;
        final hasLogo = _logoPath.trim().isNotEmpty;

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickLogo(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickLogo(ImageSource.gallery);
                },
              ),
              if (hasLogo)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: Text(l10n.delete),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _removeLogo();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _requestPermissionsAndContinue() async {
    final permissions = <Permission>[
      Permission.contacts,
      Permission.camera,
    ];

    if (defaultTargetPlatform == TargetPlatform.android) {
      permissions.add(Permission.storage);
    }

    try {
      await permissions.request();
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Permission request failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    try {
      await _onboardingManager.setPermissionsRequested(true);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Persisting permissions step failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    if (!mounted) return;
    setState(() {
      _setupFailed = false;
      _setupError = null;
      _doneStages.clear();
    });
    _goTo(5);
  }

  Future<void> _runSetup() async {
    final l10n = AppLocalizations.of(context)!;
    final languageCode =
        context.read<LanguageProvider>().currentLocale.languageCode;

    try {
      final shopName = _shopNameController.text.trim();
      final mobile = _mobileController.text.trim();
      final ownerName = _ownerNameController.text.trim();
      final email = _buildProvisioningEmail(mobile);
      final password = _buildProvisioningPassword(mobile);

      await _setupManager.runSetup(
        installRecommended: _recommendedSetup,
        languageCode: languageCode,
        businessInput: BusinessSetupInput(
          shopName: shopName,
          mobile: mobile,
          ownerName: ownerName,
          sameNumberForWhatsApp: _sameNumberForWhatsApp,
          whatsApp:
              _sameNumberForWhatsApp ? mobile : _whatsAppController.text.trim(),
          gstRegistered: _gstRegistered,
          gstNumber: _gstNumberController.text.trim(),
          logoPath: _logoPath,
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
        ),
        onStageDone: (stage) async {
          if (!mounted) return;
          setState(() => _doneStages.add(stage));
          await Future<void>.delayed(const Duration(milliseconds: 350));
        },
      );

      if (!mounted) return;

      await _provisionCloudIdentityAndTrial(
        businessName: shopName,
        ownerName: ownerName,
        mobile: mobile,
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        email: email,
        password: password,
      );

      await _onboardingManager.setShopSetupCompleted(true);
      await _onboardingManager.setStarterCatalogueCompleted(true);
      await _onboardingManager.completeOnboarding();

      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/dashboard', (route) => false);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.onboardingSetupFailed)),
      );
      setState(() {
        _isPreparing = false;
        _setupFailed = true;
        _setupError = error.toString();
      });
    }
  }

  Future<void> _provisionCloudIdentityAndTrial({
    required String businessName,
    required String ownerName,
    required String mobile,
    required String address,
    required String city,
    required String email,
    required String password,
  }) async {
    final authProvider = context.read<AuthProvider>();
    final licenseProvider = context.read<LicenseProvider>();
    final provisioningIssues = <String>[];

    final authRegistered = await authProvider.register(
      companyName: businessName,
      ownerName: ownerName,
      mobile: mobile,
      address: address,
      city: city,
      email: email,
      password: password,
    );
    if (!authRegistered) {
      provisioningIssues.add(authProvider.friendlyMessage);
    }

    try {
      final licenseRegistered = await licenseProvider.register(
        BusinessRegistrationInput(
          businessName: businessName,
          ownerName: ownerName,
          mobile: mobile,
          email: email,
        ),
      );
      if (!licenseRegistered) {
        provisioningIssues.add(
          'License activation pending. Please connect internet to sync.',
        );
      }
    } catch (_) {
      provisioningIssues.add(
        'License activation pending. Please connect internet to sync.',
      );
    }

    if (provisioningIssues.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cloud sync pending: ${provisioningIssues.first}',
          ),
        ),
      );
    }
  }

  String _buildProvisioningEmail(String mobile) {
    final digits = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    final safeMobile = digits.isEmpty ? 'device' : digits;
    return 'auto.$safeMobile@floraprise.local';
  }

  String _buildProvisioningPassword(String mobile) {
    final digits = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    final normalized = digits.padLeft(10, '0');
    final tail = normalized.substring(normalized.length - 6);
    return 'Fp@$tail#2026';
  }

  void _validateBusinessStep() {
    final l10n = AppLocalizations.of(context)!;
    final shopName = _shopNameController.text.trim();
    final phone = _mobileController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final ownerName = _ownerNameController.text.trim();
    final address = _addressController.text.trim();
    final city = _cityController.text.trim();
    final whatsApp = _whatsAppController.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (shopName.isEmpty) {
      _showMessage(l10n.onboardingShopNameRequiredError);
      return;
    }
    if (phone.length < 10) {
      _showMessage(l10n.onboardingMobileRequiredError);
      return;
    }
    if (ownerName.isEmpty) {
      _showMessage('Owner name is required');
      return;
    }
    if (address.isEmpty) {
      _showMessage('Address is required');
      return;
    }
    if (city.isEmpty) {
      _showMessage('City is required');
      return;
    }
    if (!_sameNumberForWhatsApp && whatsApp.length < 10) {
      _showMessage(l10n.onboardingWhatsappRequiredError);
      return;
    }
    if (_gstRegistered && _gstNumberController.text.trim().isEmpty) {
      _showMessage(l10n.onboardingGstRequiredError);
      return;
    }

    _goTo(3);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _goTo(int index) {
    setState(() => _stepIndex = index);
  }
}
