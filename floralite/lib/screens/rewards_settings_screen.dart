import 'package:flutter/material.dart';

import '../managers/reward_manager.dart';
import '../widgets/common_widgets.dart';

class RewardsSettingsScreen extends StatefulWidget {
  const RewardsSettingsScreen({super.key});

  @override
  State<RewardsSettingsScreen> createState() => _RewardsSettingsScreenState();
}

class _RewardsSettingsScreenState extends State<RewardsSettingsScreen> {
  final RewardManager _rewardManager = RewardManager();
  final TextEditingController _earnSpendController = TextEditingController();
  final TextEditingController _minimumBillController = TextEditingController();
  final TextEditingController _pointValueController = TextEditingController();
  final TextEditingController _maximumRedemptionController =
      TextEditingController();
  final TextEditingController _expiryDaysController = TextEditingController();

  bool _enabled = true;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _earnSpendController.dispose();
    _minimumBillController.dispose();
    _pointValueController.dispose();
    _maximumRedemptionController.dispose();
    _expiryDaysController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final settings = await _rewardManager.loadSettings();
    if (!mounted) return;
    setState(() {
      _enabled = settings.enabled;
      _earnSpendController.text =
          (settings.earnSpendPaisePerPoint / 100).toStringAsFixed(0);
      _minimumBillController.text =
          (settings.minimumBillPaise / 100).toStringAsFixed(0);
      _pointValueController.text =
          (settings.pointValuePaise / 100).toStringAsFixed(0);
      _maximumRedemptionController.text =
          settings.maximumRedemptionPercent.toString();
      _expiryDaysController.text = settings.expiryDays.toString();
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final settings = RewardSettings(
      enabled: _enabled,
      earnSpendPaisePerPoint: _rupeesToPaise(_earnSpendController.text),
      minimumBillPaise: _rupeesToPaise(_minimumBillController.text),
      pointValuePaise: _rupeesToPaise(_pointValueController.text),
      maximumRedemptionPercent:
          int.tryParse(_maximumRedemptionController.text.trim()) ??
              RewardSettings.defaults.maximumRedemptionPercent,
      expiryDays: int.tryParse(_expiryDaysController.text.trim()) ??
          RewardSettings.defaults.expiryDays,
    );
    await _rewardManager.saveSettings(settings);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rewards settings saved')),
    );
  }

  int _rupeesToPaise(String value) {
    final rupees = int.tryParse(value.trim());
    return (rupees == null || rupees <= 0) ? 100 : rupees * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rewards Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AppCard(
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Customer Rewards'),
                        subtitle: const Text('Earn and redeem reward points'),
                        value: _enabled,
                        onChanged: (value) => setState(() => _enabled = value),
                      ),
                      const Divider(height: 24),
                      _numberField(
                        controller: _earnSpendController,
                        label: 'Earn 1 point for every rupees',
                      ),
                      const SizedBox(height: 12),
                      _numberField(
                        controller: _minimumBillController,
                        label: 'Minimum bill rupees',
                      ),
                      const SizedBox(height: 12),
                      _numberField(
                        controller: _pointValueController,
                        label: 'Value of 1 point in rupees',
                      ),
                      const SizedBox(height: 12),
                      _numberField(
                        controller: _maximumRedemptionController,
                        label: 'Maximum redemption percent',
                      ),
                      const SizedBox(height: 12),
                      _numberField(
                        controller: _expiryDaysController,
                        label: 'Expiry days',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Save Settings'),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
