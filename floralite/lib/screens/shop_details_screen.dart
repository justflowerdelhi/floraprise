import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../data/repositories/business_profile_repository.dart';
import '../data/repositories/cloud_company_profile_repository.dart';
import '../managers/business_settings_manager.dart';
import '../models/fiscal_profile.dart';
import '../providers/storage_mode_provider.dart';
import '../services/mobile_auth_service.dart';
import '../widgets/common_widgets.dart';

class ShopDetailsScreen extends StatefulWidget {
  const ShopDetailsScreen({super.key});

  @override
  State<ShopDetailsScreen> createState() => _ShopDetailsScreenState();
}

class _ShopDetailsScreenState extends State<ShopDetailsScreen> {
  final BusinessSettingsManager _businessSettingsManager =
      BusinessSettingsManager();
  final BusinessProfileRepository _businessProfileRepository =
      BusinessProfileRepository();
  final CloudCompanyProfileRepository _cloudCompanyProfileRepository =
      CloudCompanyProfileRepository();
  final MobileAuthService _mobileAuthService = MobileAuthService();
  
  bool _isCloudMode = false;
  bool _isLoading = true;
  String? _loadError;
  
  String _shopName = 'My Flower Shop';
  String _ownerName = '';
  String _businessPhone = '';
  String _businessEmail = '';
  String _businessAddress = '';
  String _city = '';
  String _state = '';
  String _pinCode = '';
  bool _gstRegistered = true;
  String _gstNumber = '';
  FiscalProfile _fiscalProfile = CountryPresets.india();
  String _logoPath = '';
  final ImagePicker _imagePicker = ImagePicker();


  @override
  void initState() {
    super.initState();
    _loadBusinessSettings();
  }

  Future<void> _loadBusinessSettings() async {
    try {
      // Determine if we're in Cloud or Local mode
      final storageProvider = context.read<StorageModeProvider>();
      final isCloud = storageProvider.isCloud;
      
      final fiscal = await _businessSettingsManager.getFiscalProfile();

      setState(() {
        _isCloudMode = isCloud;
        _isLoading = true;
        _loadError = null;
        _fiscalProfile = fiscal;
      });
      
      if (isCloud) {
        await _loadCloudCompanyProfile();
      } else {
        await _loadLocalBusinessProfile();
      }
      
      final logoPath = await _businessSettingsManager.getLogoPath();
      if (!mounted) return;
      setState(() {
        _logoPath = logoPath;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Failed to load company profile: $e';
      });
    }
  }

  Future<void> _loadCloudCompanyProfile() async {
    try {
      // Get the base URL from the auth service
      final baseUrl = _mobileAuthService.baseUrl;
      
      // Get the access token
      final accessToken = await _mobileAuthService.getStoredAccessToken();
      if (accessToken == null || accessToken.trim().isEmpty) {
        setState(() {
          _loadError = 'Not authenticated. Please log in again.';
        });
        return;
      }
      
      // Fetch the company profile from the Cloud API
      final cloudProfile = await _cloudCompanyProfileRepository.fetchCompanyProfile(
        baseUrl: baseUrl,
        accessToken: accessToken,
      );
      
      if (!mounted) return;
      
      if (cloudProfile != null) {
        setState(() {
          _shopName = cloudProfile.name;
          _ownerName = ''; // Not available in current API
          _businessPhone = cloudProfile.phone ?? '';
          _businessEmail = cloudProfile.email ?? '';
          _businessAddress = cloudProfile.address ?? '';
          _city = ''; // Not available in current API
          _state = ''; // Not available in current API
          _pinCode = ''; // Not available in current API
          _gstRegistered = _fiscalProfile.taxEnabled;
          _gstNumber = _fiscalProfile.taxIdentifier ?? cloudProfile.taxIdentifier ?? '';
        });
      } else {
        setState(() {
          _loadError = 'Could not fetch company profile from Cloud.';
        });
      }
    } catch (e) {
      setState(() {
        _loadError = 'Error loading Cloud profile: $e';
      });
    }
  }

  Future<void> _loadLocalBusinessProfile() async {
    final profile = await _businessProfileRepository.getBusinessProfile();
    
    if (!mounted) return;
    
    if (profile != null) {
      setState(() {
        _shopName = profile.shopName;
        _ownerName = profile.ownerName;
        _businessPhone = profile.mobileNumber;
        _businessEmail = profile.email ?? '';
        _businessAddress = profile.address ?? '';
        _city = profile.city ?? '';
        _state = profile.state ?? '';
        _pinCode = profile.pinCode ?? '';
        _gstRegistered = _fiscalProfile.taxEnabled;
        _gstNumber = _fiscalProfile.taxIdentifier ?? profile.gstNumber ?? '';
      });
    } else {
      // Fallback to BusinessSettingsManager for backward compatibility
      final settings = await _businessSettingsManager.load();
      if (!mounted) return;
      setState(() {
        _shopName = settings.shopName;
        _ownerName = settings.ownerName;
        _businessPhone = settings.phone;
        _businessAddress = settings.address;
        _gstRegistered = _fiscalProfile.taxEnabled;
        _gstNumber = _fiscalProfile.taxIdentifier ?? settings.gstNumber;
      });
    }
  }


  Future<void> _pickBusinessLogo(ImageSource source) async {
    final image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 1600,
    );
    if (image == null) return;

    final selectedPath = image.path.trim();
    await _businessSettingsManager.setLogoPath(selectedPath);
    if (!mounted) return;
    setState(() => _logoPath = selectedPath);
  }

  Future<void> _removeBusinessLogo() async {
    await _businessSettingsManager.setLogoPath('');
    if (!mounted) return;
    setState(() => _logoPath = '');
  }

  Future<void> _showBusinessLogoSheet() async {
    if (!mounted) return;
    final hasLogo = _logoPath.trim().isNotEmpty;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickBusinessLogo(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickBusinessLogo(ImageSource.gallery);
              },
            ),
            if (hasLogo)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _removeBusinessLogo();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _editBusinessTextField({
    required String title,
    required String initialValue,
    required Future<void> Function(String value) onSave,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(labelText: title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null) return;
    await onSave(result);
  }

  Future<void> _saveBusinessProfile() async {
    // Validate required fields
    if (_shopName.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop Name is required')),
      );
      return;
    }
    if (_ownerName.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Owner Name is required')),
      );
      return;
    }
    if (_businessPhone.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mobile Number is required')),
      );
      return;
    }
    if (_gstRegistered && _gstNumber.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GST Number is required when GST Registered')),
      );
      return;
    }

    try {
      await _businessProfileRepository.saveBusinessProfile(
        shopName: _shopName.trim(),
        ownerName: _ownerName.trim(),
        mobileNumber: _businessPhone.trim(),
        email: _businessEmail.trim().isEmpty ? null : _businessEmail.trim(),
        address: _businessAddress.trim().isEmpty ? null : _businessAddress.trim(),
        city: _city.trim().isEmpty ? null : _city.trim(),
        state: _state.trim().isEmpty ? null : _state.trim(),
        pinCode: _pinCode.trim().isEmpty ? null : _pinCode.trim(),
        gstRegistered: _gstRegistered,
        gstNumber: _gstRegistered ? _gstNumber.trim() : null,
      );
      await _businessSettingsManager.setShopName(_shopName.trim());
      await _businessSettingsManager.setOwnerName(_ownerName.trim());
      await _businessSettingsManager.setPhone(_businessPhone.trim());
      await _businessSettingsManager.setAddress(_businessAddress.trim());
      await _businessSettingsManager.setGstRegistered(_gstRegistered);
      await _businessSettingsManager.setGstNumber(_gstRegistered ? _gstNumber.trim() : '');
      BusinessSettingsManager.notifySettingsChanged();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop Details saved successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    }
  }

  /// Dispatches to the Cloud or Local save path depending on the active storage mode.
  Future<void> _saveProfile() =>
      _isCloudMode ? _saveCloudCompanyProfile() : _saveBusinessProfile();

  Future<void> _saveCloudCompanyProfile() async {
    if (_shopName.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop Name is required')),
      );
      return;
    }
    if (_businessPhone.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mobile Number is required')),
      );
      return;
    }
    if (_gstRegistered && _gstNumber.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GST Number is required when GST Registered')),
      );
      return;
    }

    try {
      final baseUrl = _mobileAuthService.baseUrl;
      final accessToken = await _mobileAuthService.getStoredAccessToken();
      if (accessToken == null || accessToken.trim().isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not authenticated. Please log in again.')),
        );
        return;
      }

      await _cloudCompanyProfileRepository.updateCompanyProfile(
        baseUrl: baseUrl,
        accessToken: accessToken,
        name: _shopName.trim(),
        phone: _businessPhone.trim(),
        email: _businessEmail.trim().isEmpty ? null : _businessEmail.trim(),
        address: _businessAddress.trim().isEmpty ? null : _businessAddress.trim(),
        taxIdentifier: _gstRegistered ? _gstNumber.trim() : null,
      );
      BusinessSettingsManager.notifySettingsChanged();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop Details saved successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Shop Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final hasLogo = _logoPath.trim().isNotEmpty && !kIsWeb;
    final logoExists = hasLogo && File(_logoPath).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Details'),
        actions: [
          if (!_isCloudMode)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showBusinessLogoSheet(),
              tooltip: 'Edit Logo',
            ),
        ],
      ),
      body: SafeArea(
        child: _loadError != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _loadError!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _loadError = null;
                          });
                          _loadBusinessSettings();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
                children: [
                  if (_isCloudMode)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          border: Border.all(color: Colors.blue.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info, color: Colors.blue.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Shop Name, Mobile Number, Email, Address and GST details can be edited here. Owner Name, Logo, City, State and PIN Code are read-only in Cloud mode.',
                                style: TextStyle(
                                  color: Colors.blue.shade900,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Center(
                    child: InkWell(
                      onTap: _isCloudMode ? null : _showBusinessLogoSheet,
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.grey.shade100,
                                  backgroundImage: logoExists ? FileImage(File(_logoPath)) : null,
                                  child: logoExists
                                      ? null
                                      : Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Text('🏪', style: TextStyle(fontSize: 36)),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Logo',
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                                if (!_isCloudMode)
                                  Positioned(
                                    right: -2,
                                    bottom: -2,
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            hasLogo && logoExists
                                ? (_shopName.trim().isEmpty ? 'Business Logo' : _shopName)
                                : 'Add Shop Logo',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(
                          'Shop Name',
                          _shopName,
                          Icons.store,
                          () => _editBusinessTextField(
                            title: 'Shop Name',
                            initialValue: _shopName,
                            onSave: (value) async {
                              _shopName = value;
                              await _saveProfile();
                            },
                          ),
                        ),
                        const Divider(),
                        _buildDetailRow(
                          'Owner Name',
                          _ownerName.isEmpty ? '-' : _ownerName,
                          Icons.person,
                          _isCloudMode ? null : () => _editBusinessTextField(
                            title: 'Owner Name',
                            initialValue: _ownerName,
                            onSave: (value) async {
                              _ownerName = value;
                              await _saveBusinessProfile();
                            },
                          ),
                        ),
                        const Divider(),
                        _buildDetailRow(
                          'Mobile Number',
                          _businessPhone.isEmpty ? '-' : _businessPhone,
                          Icons.phone,
                          () => _editBusinessTextField(
                            title: 'Mobile Number',
                            initialValue: _businessPhone,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            onSave: (value) async {
                              _businessPhone = value;
                              await _saveProfile();
                            },
                          ),
                        ),
                        const Divider(),
                        _buildDetailRow(
                          'Email',
                          _businessEmail.isEmpty ? '-' : _businessEmail,
                          Icons.email,
                          () => _editBusinessTextField(
                            title: 'Email',
                            initialValue: _businessEmail,
                            keyboardType: TextInputType.emailAddress,
                            onSave: (value) async {
                              _businessEmail = value;
                              await _saveProfile();
                            },
                          ),
                        ),
                        const Divider(),
                        _buildDetailRow(
                          'Address',
                          _businessAddress.isEmpty ? '-' : _businessAddress,
                          Icons.location_on,
                          () => _editBusinessTextField(
                            title: 'Address',
                            initialValue: _businessAddress,
                            onSave: (value) async {
                              _businessAddress = value;
                              await _saveProfile();
                            },
                          ),
                        ),
                        const Divider(),
                        _buildDetailRow(
                          'City',
                          _city.isEmpty ? '-' : _city,
                          Icons.location_city,
                          _isCloudMode ? null : () => _editBusinessTextField(
                            title: 'City',
                            initialValue: _city,
                            onSave: (value) async {
                              _city = value;
                              await _saveBusinessProfile();
                            },
                          ),
                        ),
                        const Divider(),
                        _buildDetailRow(
                          'State',
                          _state.isEmpty ? '-' : _state,
                          Icons.map,
                          _isCloudMode ? null : () => _editBusinessTextField(
                            title: 'State',
                            initialValue: _state,
                            onSave: (value) async {
                              _state = value;
                              await _saveBusinessProfile();
                            },
                          ),
                        ),
                        const Divider(),
                        _buildDetailRow(
                          'PIN Code',
                          _pinCode.isEmpty ? '-' : _pinCode,
                          Icons.pin,
                          _isCloudMode ? null : () => _editBusinessTextField(
                            title: 'PIN Code',
                            initialValue: _pinCode,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            onSave: (value) async {
                              _pinCode = value;
                              await _saveBusinessProfile();
                            },
                          ),
                        ),
                        const Divider(),
                        _buildDetailRow(
                          'Floraprise Shop ID',
                          'Coming Soon',
                          Icons.storefront,
                          null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFiscalSettingsCard(),
                ],
              ),
      ),
    );
  }

  Widget _buildFiscalSettingsCard() {
    final taxIdLabel = _getTaxIdLabel(_fiscalProfile.countryCode);
    final currencyDisplay =
        '${_fiscalProfile.currencyCode} (${_fiscalProfile.currencySymbol})';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
            child: Row(
              children: [
                Icon(Icons.public,
                    color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Country & Tax Settings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const Divider(),
          _buildDetailRow(
            'Country',
            _getCountryDisplayName(_fiscalProfile.countryCode),
            Icons.flag_outlined,
            () => _showCountryPicker(),
          ),
          const Divider(),
          _buildDetailRow(
            'Currency',
            currencyDisplay,
            Icons.currency_exchange,
            null,
          ),
          const Divider(),
          SwitchListTile(
            title: Text('Enable ${_fiscalProfile.taxLabel}'),
            subtitle: Text(_fiscalProfile.taxEnabled
                ? 'Tax is applied at checkout'
                : 'Disabled (Zero Tax)'),
            value: _fiscalProfile.taxEnabled,
            onChanged: (value) async {
              setState(() {
                _fiscalProfile = _fiscalProfile.copyWith(taxEnabled: value);
                _gstRegistered = value;
              });
              await _saveFiscalProfile();
            },
            secondary: const Icon(Icons.receipt_long),
          ),
          const Divider(),
          _buildDetailRow(
            'Tax Name / Label',
            _fiscalProfile.taxLabel,
            Icons.label_outline,
            () => _editBusinessTextField(
              title: 'Tax Name / Label',
              initialValue: _fiscalProfile.taxLabel,
              onSave: (value) async {
                if (value.isNotEmpty) {
                  setState(() {
                    _fiscalProfile = _fiscalProfile.copyWith(taxLabel: value);
                  });
                  await _saveFiscalProfile();
                }
              },
            ),
          ),
          const Divider(),
          _buildDetailRow(
            'Default Tax Rate',
            '${_fiscalProfile.taxRatePercent}%',
            Icons.percent,
            () => _editTaxRateDialog(),
          ),
          const Divider(),
          _buildDetailRow(
            'Pricing Model',
            _fiscalProfile.taxInclusive
                ? 'Prices include tax'
                : 'Tax is added to prices',
            Icons.calculate_outlined,
            () => _showPricingModelDialog(),
          ),
          const Divider(),
          _buildDetailRow(
            taxIdLabel,
            _fiscalProfile.taxIdentifier?.isNotEmpty == true
                ? _fiscalProfile.taxIdentifier!
                : '-',
            Icons.confirmation_number,
            () => _editBusinessTextField(
              title: taxIdLabel,
              initialValue: _fiscalProfile.taxIdentifier ?? '',
              onSave: (value) async {
                setState(() {
                  _fiscalProfile = _fiscalProfile.copyWith(
                    taxIdentifier: value.trim().isEmpty ? null : value.trim(),
                  );
                  _gstNumber = value.trim();
                });
                await _saveFiscalProfile();
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCountryPicker() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Country'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'IN'),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text('🇮🇳  India (INR - ₹)'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'AE'),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text('🇦🇪  United Arab Emirates (AED - د.إ)'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'US'),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text('🇺🇸  United States (USD - \$)'),
            ),
          ),
        ],
      ),
    );

    if (selected != null && selected != _fiscalProfile.countryCode) {
      final preset = CountryPresets.forCountry(selected);
      setState(() {
        _fiscalProfile = preset;
        _gstRegistered = preset.taxEnabled;
        _gstNumber = preset.taxIdentifier ?? '';
      });
      await _saveFiscalProfile();
    }
  }

  Future<void> _editTaxRateDialog() async {
    final controller = TextEditingController(
      text: _fiscalProfile.taxRatePercent == 0
          ? '0'
          : _fiscalProfile.taxRatePercent.toString(),
    );
    String? errorText;

    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Default Tax Rate (%)'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Tax Rate (%)',
              errorText: errorText,
              suffixText: '%',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();
                final rate = double.tryParse(text);
                if (rate == null ||
                    rate < 0 ||
                    rate.isNaN ||
                    rate.isInfinite) {
                  setDialogState(() {
                    errorText = 'Please enter a valid rate (0 or higher)';
                  });
                  return;
                }
                Navigator.pop(dialogContext, rate);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _fiscalProfile = _fiscalProfile.copyWith(taxRatePercent: result);
      });
      await _saveFiscalProfile();
    }
  }

  Future<void> _showPricingModelDialog() async {
    bool isInclusive = _fiscalProfile.taxInclusive;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Pricing Model'),
          content: RadioGroup<bool>(
            groupValue: isInclusive,
            onChanged: (val) {
              if (val != null) {
                setDialogState(() => isInclusive = val);
              }
            },
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<bool>(
                  title: Text('Prices include tax'),
                  subtitle: Text('Catalog and shelf prices are tax-inclusive'),
                  value: true,
                ),
                RadioListTile<bool>(
                  title: Text('Tax is added to prices'),
                  subtitle:
                      Text('Tax is calculated and added on top at checkout'),
                  value: false,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, isInclusive),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _fiscalProfile = _fiscalProfile.copyWith(taxInclusive: result);
      });
      await _saveFiscalProfile();
    }
  }

  Future<void> _saveFiscalProfile() async {
    await _businessSettingsManager.setFiscalProfile(_fiscalProfile);
    if (_isCloudMode) {
      try {
        final baseUrl = _mobileAuthService.baseUrl;
        final accessToken = await _mobileAuthService.getStoredAccessToken();
        if (accessToken != null && accessToken.trim().isNotEmpty) {
          await _cloudCompanyProfileRepository.updateCompanyProfile(
            baseUrl: baseUrl,
            accessToken: accessToken,
            currencyCode: _fiscalProfile.currencyCode,
            taxIdentifier: _fiscalProfile.taxIdentifier,
            timeZone: _fiscalProfile.timeZone,
            region: _fiscalProfile.countryCode,
            taxEnabled: _fiscalProfile.taxEnabled,
            taxLabel: _fiscalProfile.taxLabel,
            taxRatePercent: _fiscalProfile.taxRatePercent,
            taxInclusive: _fiscalProfile.taxInclusive,
          );
        }
      } catch (e) {
        debugPrint('Cloud fiscal profile update error: $e');
      }
    }
    BusinessSettingsManager.notifySettingsChanged();
  }

  String _getCountryDisplayName(String code) {
    switch (code.toUpperCase()) {
      case 'IN':
        return 'India 🇮🇳';
      case 'AE':
        return 'United Arab Emirates 🇦🇪';
      case 'US':
        return 'United States 🇺🇸';
      default:
        return code;
    }
  }

  String _getTaxIdLabel(String countryCode) {
    switch (countryCode.toUpperCase()) {
      case 'IN':
        return 'GSTIN';
      case 'AE':
        return 'TRN';
      case 'US':
        return 'Tax ID / EIN';
      default:
        return 'Tax ID';
    }
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
    VoidCallback? onTap,
  ) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(
              icon,
              color: enabled ? null : Colors.grey.shade500,
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: enabled ? null : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: enabled ? null : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            if (enabled)
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
          ],
        ),
      ),
    );
  }
}
