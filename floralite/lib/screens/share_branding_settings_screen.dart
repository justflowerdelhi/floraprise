import 'package:flutter/material.dart';

import '../models/share_branding.dart';
import '../services/share_branding_settings_service.dart';
import '../widgets/common_widgets.dart';

class ShareBrandingSettingsScreen extends StatefulWidget {
  const ShareBrandingSettingsScreen({super.key});

  @override
  State<ShareBrandingSettingsScreen> createState() =>
      _ShareBrandingSettingsScreenState();
}

class _ShareBrandingSettingsScreenState
    extends State<ShareBrandingSettingsScreen> {
  final ShareBrandingSettingsService _service = ShareBrandingSettingsService();

  static const List<Color> _footerColorChoices = [
    Color(0xCC1B5E20),
    Color(0xCC004D40),
    Color(0xCC37474F),
    Color(0xCC6A1B9A),
    Color(0xCCAD1457),
    Color(0xCC0D47A1),
  ];

  ShareBrandingSettings? _settings;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final loaded = await _service.loadSettings();
      if (!mounted) return;
      setState(() {
        _settings = loaded;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _save(ShareBrandingSettings updated) async {
    setState(() {
      _settings = updated;
    });
    await _service.saveSettings(updated);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final settings = _settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Share Branding')),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _load,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset),
                    children: [
                      AppCard(
                        child: Column(
                          children: [
                            _switchTile(
                              title: 'Show Price',
                              value: settings!.showPrice,
                              onChanged: (value) =>
                                  _save(settings.copyWith(showPrice: value)),
                            ),
                            const Divider(height: 1),
                            _switchTile(
                              title: 'Show Shop Name',
                              value: settings.showShopName,
                              onChanged: (value) =>
                                  _save(settings.copyWith(showShopName: value)),
                            ),
                            const Divider(height: 1),
                            _switchTile(
                              title: 'Show Phone Number',
                              value: settings.showPhoneNumber,
                              onChanged: (value) => _save(
                                  settings.copyWith(showPhoneNumber: value)),
                            ),
                            const Divider(height: 1),
                            _switchTile(
                              title: 'Show Website',
                              value: settings.showWebsite,
                              onChanged: (value) =>
                                  _save(settings.copyWith(showWebsite: value)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.branding_watermark_outlined),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Glass Card Watermark',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _switchTile(
                              title: 'Enable Watermark',
                              value: settings.showWatermark,
                              onChanged: (value) => _save(
                                  settings.copyWith(showWatermark: value)),
                            ),
                            const Divider(height: 1),
                            IgnorePointer(
                              ignoring: !settings.showWatermark,
                              child: AnimatedOpacity(
                                opacity: settings.showWatermark ? 1 : 0.45,
                                duration: const Duration(milliseconds: 180),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _switchTile(
                                      title: 'Logo',
                                      value: settings.showLogo,
                                      onChanged: (value) => _save(
                                          settings.copyWith(showLogo: value)),
                                    ),
                                    const Divider(height: 1),
                                    _switchTile(
                                      title: 'Business Name',
                                      value: settings.showWatermarkBusinessName,
                                      onChanged: (value) => _save(
                                        settings.copyWith(
                                          showWatermarkBusinessName: value,
                                        ),
                                      ),
                                    ),
                                    const Divider(height: 1),
                                    _switchTile(
                                      title: 'City',
                                      value: settings.showWatermarkCity,
                                      onChanged: (value) => _save(
                                        settings.copyWith(
                                          showWatermarkCity: value,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Opacity',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '${(settings.watermarkOpacity * 100).round()}%',
                                        ),
                                      ],
                                    ),
                                    Slider(
                                      value: settings.watermarkOpacity,
                                      min: 0.2,
                                      max: 1,
                                      divisions: 8,
                                      label:
                                          '${(settings.watermarkOpacity * 100).round()}%',
                                      onChanged: (value) => _save(settings
                                          .copyWith(watermarkOpacity: value)),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Size',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      child: SegmentedButton<WatermarkSize>(
                                        segments: const [
                                          ButtonSegment(
                                            value: WatermarkSize.small,
                                            label: Text('Small'),
                                          ),
                                          ButtonSegment(
                                            value: WatermarkSize.medium,
                                            label: Text('Medium'),
                                          ),
                                          ButtonSegment(
                                            value: WatermarkSize.large,
                                            label: Text('Large'),
                                          ),
                                        ],
                                        selected: {settings.watermarkSize},
                                        onSelectionChanged: (selection) =>
                                            _save(settings.copyWith(
                                          watermarkSize: selection.first,
                                        )),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    DropdownButtonFormField<WatermarkPosition>(
                                      initialValue: settings.watermarkPosition,
                                      decoration: const InputDecoration(
                                        labelText: 'Position',
                                        border: OutlineInputBorder(),
                                      ),
                                      items: WatermarkPosition.values
                                          .map((position) => DropdownMenuItem(
                                                value: position,
                                                child: Text(
                                                  _positionLabel(position),
                                                ),
                                              ))
                                          .toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          _save(settings.copyWith(
                                            watermarkPosition: value,
                                          ));
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Footer Color',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: _footerColorChoices.map((color) {
                                final selected =
                                    settings.footerColor.toARGB32() ==
                                        color.toARGB32();
                                return InkWell(
                                  onTap: () => _save(
                                      settings.copyWith(footerColor: color)),
                                  borderRadius: BorderRadius.circular(999),
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: selected
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Colors.transparent,
                                        width: 3,
                                      ),
                                    ),
                                    child: selected
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 18,
                                          )
                                        : null,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      title: Text(title),
      contentPadding: EdgeInsets.zero,
    );
  }

  String _positionLabel(WatermarkPosition position) {
    return switch (position) {
      WatermarkPosition.topLeft => 'Top left',
      WatermarkPosition.topCenter => 'Top center',
      WatermarkPosition.topRight => 'Top right',
      WatermarkPosition.bottomLeft => 'Bottom left',
      WatermarkPosition.bottomCenter => 'Bottom center',
      WatermarkPosition.bottomRight => 'Bottom right',
    };
  }
}
