import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../data/repositories/business_profile_repository.dart';
import '../managers/business_settings_manager.dart';
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
  String _logoPath = '';
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadBusinessSettings();
  }

  Future<void> _loadBusinessSettings() async {
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
        _gstRegistered = profile.gstRegistered;
        _gstNumber = profile.gstNumber ?? '';
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
        _gstRegistered = settings.gstRegistered;
        _gstNumber = settings.gstNumber;
      });
    }

    final logoPath = await _businessSettingsManager.getLogoPath();
    if (!mounted) return;
    setState(() => _logoPath = logoPath);
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
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final hasLogo = _logoPath.trim().isNotEmpty;
    final logoFile = hasLogo ? File(_logoPath) : null;
    final logoExists = logoFile != null && logoFile.existsSync();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showBusinessLogoSheet(),
            tooltip: 'Edit Logo',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
          children: [
            Center(
              child: InkWell(
                onTap: _showBusinessLogoSheet,
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
                            backgroundImage: logoExists ? FileImage(logoFile) : null,
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
                        await _saveBusinessProfile();
                      },
                    ),
                  ),
                  const Divider(),
                  _buildDetailRow(
                    'Owner Name',
                    _ownerName.isEmpty ? '-' : _ownerName,
                    Icons.person,
                    () => _editBusinessTextField(
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
                        await _saveBusinessProfile();
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
                        await _saveBusinessProfile();
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
                        await _saveBusinessProfile();
                      },
                    ),
                  ),
                  const Divider(),
                  _buildDetailRow(
                    'City',
                    _city.isEmpty ? '-' : _city,
                    Icons.location_city,
                    () => _editBusinessTextField(
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
                    () => _editBusinessTextField(
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
                    () => _editBusinessTextField(
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
                  SwitchListTile(
                    title: const Text('GST Registered'),
                    subtitle: Text(_gstRegistered ? 'Yes' : 'No'),
                    value: _gstRegistered,
                    onChanged: (value) async {
                      setState(() => _gstRegistered = value);
                      await _saveBusinessProfile();
                    },
                    secondary: const Icon(Icons.receipt_long),
                  ),
                  const Divider(),
                  if (_gstRegistered)
                    _buildDetailRow(
                      'GST Number',
                      _gstNumber.isEmpty ? '-' : _gstNumber,
                      Icons.confirmation_number,
                      () => _editBusinessTextField(
                        title: 'GST Number',
                        initialValue: _gstNumber,
                        onSave: (value) async {
                          _gstNumber = value;
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
          ],
        ),
      ),
    );
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
