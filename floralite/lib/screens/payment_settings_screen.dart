import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../managers/business_settings_manager.dart';
import '../managers/payment_settings_manager.dart';
import '../widgets/app_header.dart';
import '../widgets/common_widgets.dart';
import '../widgets/upi_qr_widget.dart';

class PaymentSettingsScreen extends StatefulWidget {
  const PaymentSettingsScreen({
    super.key,
    this.paymentSettingsManager,
    this.businessSettingsManager,
  });

  final PaymentSettingsManager? paymentSettingsManager;
  final BusinessSettingsManager? businessSettingsManager;

  @override
  State<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends State<PaymentSettingsScreen> {
  late final PaymentSettingsManager _manager;
  BusinessSettingsManager? _businessSettingsManager;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isTestingGateway = false;

  // Local payment toggles
  bool _cashEnabled = true;
  bool _upiEnabled = true;
  final _upiIdController = TextEditingController();
  final _upiMerchantNameController = TextEditingController();

  bool _cardEnabled = true;
  bool _hasCardMachine = false;
  final _cardTerminalIdController = TextEditingController();

  // Online gateway fields (Cloud/Pro)
  bool _onlineEnabled = false;
  String _selectedGateway = 'Razorpay';
  String _selectedEnvironment = 'Production';
  final _onlineKeyIdController = TextEditingController();
  final _onlineKeySecretController = TextEditingController();
  bool _showKeySecret = false;
  String? _onlineGatewayId;
  String? _onlineWebhookUrl;
  DateTime? _onlineLastTestedAt;
  bool? _onlineLastTestSuccessful;
  bool _isCloudMode = false;

  @override
  void initState() {
    super.initState();
    _manager = widget.paymentSettingsManager ?? PaymentSettingsManager();
    _businessSettingsManager = widget.businessSettingsManager;
    _loadSettings();
  }

  @override
  void dispose() {
    _upiIdController.dispose();
    _upiMerchantNameController.dispose();
    _cardTerminalIdController.dispose();
    _onlineKeyIdController.dispose();
    _onlineKeySecretController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _manager.load();
      String shopName = '';
      try {
        final businessSettings = await (_businessSettingsManager ?? BusinessSettingsManager()).load();
        shopName = businessSettings.shopName;
      } catch (_) {}

      if (mounted) {
        setState(() {
          _cashEnabled = settings.cashEnabled;
          _upiEnabled = settings.upiEnabled;
          _upiIdController.text = settings.upiId;
          _upiMerchantNameController.text = settings.upiMerchantName.isNotEmpty
              ? settings.upiMerchantName
              : shopName;

          _cardEnabled = settings.cardEnabled;
          _hasCardMachine = settings.hasCardMachine;
          _cardTerminalIdController.text = settings.cardTerminalId;

          _onlineEnabled = settings.onlineEnabled;
          _onlineGatewayId = settings.onlineGatewayId;
          _selectedGateway = settings.onlineGatewayType.isNotEmpty
              ? settings.onlineGatewayType
              : 'Razorpay';
          _selectedEnvironment = settings.onlineEnvironment.isNotEmpty
              ? settings.onlineEnvironment
              : 'Production';
          _onlineKeyIdController.text = settings.onlinePublicKey;
          _onlineWebhookUrl = settings.onlineWebhookUrl;
          _onlineLastTestedAt = settings.onlineLastTestedAt;
          _onlineLastTestSuccessful = settings.onlineLastTestSuccessful;
          _isCloudMode = settings.isCloudMode;

          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveAllSettings() async {
    setState(() => _isSaving = true);
    try {
      await _manager.saveLocalPaymentSettings(
        cashEnabled: _cashEnabled,
        upiEnabled: _upiEnabled,
        upiId: _upiIdController.text.trim(),
        upiMerchantName: _upiMerchantNameController.text.trim(),
        cardEnabled: _cardEnabled,
        hasCardMachine: _hasCardMachine,
        cardTerminalId: _cardTerminalIdController.text.trim(),
        onlineEnabled: _onlineEnabled,
      );

      // Save Cloud Gateway if configured and on Cloud
      if (_isCloudMode && _onlineKeyIdController.text.trim().isNotEmpty) {
        final savedConfig = await _manager.saveCloudGateway(
          existingId: _onlineGatewayId,
          gatewayType: _selectedGateway,
          name: '$_selectedGateway Gateway',
          publicKey: _onlineKeyIdController.text.trim(),
          secretKey: _onlineKeySecretController.text.trim(),
          environment: _selectedEnvironment,
        );
        _onlineGatewayId = savedConfig.id;
        _onlineWebhookUrl = savedConfig.webhookUrl;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment settings saved successfully'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _testOnlineGateway() async {
    if (_onlineGatewayId == null || _onlineGatewayId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please save gateway configuration before testing'),
        ),
      );
      return;
    }

    setState(() => _isTestingGateway = true);
    try {
      final result = await _manager.testGatewayConnection(_onlineGatewayId!);
      if (mounted) {
        setState(() {
          _onlineLastTestedAt = result.testedAt;
          _onlineLastTestSuccessful = result.success;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.success
                  ? 'Connection successful! Gateway is active and ready.'
                  : 'Connection test failed: ${result.message}',
            ),
            backgroundColor:
                result.success ? const Color(0xFF2E7D32) : Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test connection failed: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTestingGateway = false);
      }
    }
  }

  Future<void> _disconnectOnlineGateway() async {
    if (_onlineGatewayId == null || _onlineGatewayId!.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect Gateway'),
        content: const Text(
          'Are you sure you want to disconnect this online payment gateway?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);
    try {
      await _manager.deleteGateway(_onlineGatewayId!);
      setState(() {
        _onlineGatewayId = null;
        _onlineKeyIdController.clear();
        _onlineKeySecretController.clear();
        _onlineWebhookUrl = null;
        _onlineLastTestedAt = null;
        _onlineLastTestSuccessful = null;
        _onlineEnabled = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment gateway disconnected')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error disconnecting gateway: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    if (_isLoading) {
      return Scaffold(
        appBar: const AppHeader(title: 'Payment Settings'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: const AppHeader(title: 'Payment Settings'),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
          children: [
            // Informative header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: colorScheme.primary,
                    child: const Icon(Icons.payments_outlined, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment Methods',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Choose how customers can pay in your shop and online.',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── 1. CASH PAYMENT ──
            _buildCashCard(),
            const SizedBox(height: 16),

            // ── 2. UPI / QR PAYMENT ──
            _buildUpiCard(),
            const SizedBox(height: 16),

            // ── 3. CARD MACHINE / POS ──
            _buildCardMachineCard(),
            const SizedBox(height: 16),

            // ── 4. ONLINE PAYMENT GATEWAYS ──
            _buildOnlinePaymentCard(),
            const SizedBox(height: 24),

            // ── SAVE BUTTON ──
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveAllSettings,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_isSaving ? 'Saving...' : 'Save Payment Settings'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCashCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.payments, color: Colors.green.shade700),
            ),
            title: const Text(
              'Cash',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: const Text(
              'Accept cash at counter and on delivery',
              style: TextStyle(fontSize: 12),
            ),
            value: _cashEnabled,
            onChanged: (val) => setState(() => _cashEnabled = val),
          ),
          if (_cashEnabled) ...[
            const Divider(height: 16),
            Row(
              children: [
                Icon(Icons.check_circle_outline,
                    size: 16, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cash receipts automatically record to your daily Cash Book.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUpiCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.qr_code_2, color: Colors.blue.shade700),
            ),
            title: const Text(
              'UPI / QR Code',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: const Text(
              'Accept payments via Google Pay, PhonePe, Paytm, BHIM',
              style: TextStyle(fontSize: 12),
            ),
            value: _upiEnabled,
            onChanged: (val) => setState(() => _upiEnabled = val),
          ),
          if (_upiEnabled) ...[
            const Divider(height: 20),
            TextField(
              controller: _upiIdController,
              decoration: const InputDecoration(
                labelText: 'UPI ID / VPA',
                hintText: 'e.g. yourshopname@icici or 9876543210@upi',
                prefixIcon: Icon(Icons.alternate_email),
                border: OutlineInputBorder(),
                helperText: 'Your store UPI address where payments will be received',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _upiMerchantNameController,
              decoration: const InputDecoration(
                labelText: 'Business / Payee Name',
                hintText: 'e.g. Flower Boutique',
                prefixIcon: Icon(Icons.storefront_outlined),
                border: OutlineInputBorder(),
                helperText: 'Name displayed to customer when scanning the QR code',
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Preview UPI QR Code'),
              onPressed: () {
                if (_upiIdController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a UPI ID first')),
                  );
                  return;
                }
                showUpiQrPreviewSheet(
                  context: context,
                  upiId: _upiIdController.text.trim(),
                  merchantName: _upiMerchantNameController.text.trim(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardMachineCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.credit_card, color: Colors.purple.shade700),
            ),
            title: const Text(
              'Card Payments',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: const Text(
              'Accept Debit and Credit cards',
              style: TextStyle(fontSize: 12),
            ),
            value: _cardEnabled,
            onChanged: (val) => setState(() => _cardEnabled = val),
          ),
          if (_cardEnabled) ...[
            const Divider(height: 20),
            const Text(
              'Card Machine Setup',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            RadioListTile<bool>(
              contentPadding: EdgeInsets.zero,
              title: const Text('I have a card machine / swipe terminal'),
              subtitle: const Text(
                'Record terminal ID, card brand, and approval ref at checkout',
                style: TextStyle(fontSize: 12),
              ),
              value: true,
              groupValue: _hasCardMachine,
              onChanged: (val) => setState(() => _hasCardMachine = val ?? true),
            ),
            RadioListTile<bool>(
              contentPadding: EdgeInsets.zero,
              title: const Text("I don't have a card machine"),
              subtitle: const Text(
                'Manual card payment tracking only',
                style: TextStyle(fontSize: 12),
              ),
              value: false,
              groupValue: _hasCardMachine,
              onChanged: (val) => setState(() => _hasCardMachine = val ?? false),
            ),
            if (_hasCardMachine) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _cardTerminalIdController,
                decoration: const InputDecoration(
                  labelText: 'Card Machine / Terminal Name',
                  hintText: 'e.g. Counter 1 - HDFC POS, Pine Labs 01',
                  prefixIcon: Icon(Icons.point_of_sale),
                  border: OutlineInputBorder(),
                  helperText: 'Default terminal name auto-filled on POS card payments',
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildOnlinePaymentCard() {
    if (!_isCloudMode) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.language, color: Colors.orange.shade800),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Online Payments',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Chip(
                  label: const Text('Pro / Cloud'),
                  backgroundColor: Colors.orange.shade50,
                  labelStyle: TextStyle(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Online payment processing with Razorpay, PayU, or Cashfree requires Floraprise Cloud. Connect Cloud to accept online payments and send payment links to customers.',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('Upgrade to Floraprise Cloud'),
              onPressed: () => Navigator.pushNamed(context, '/subscription'),
            ),
          ],
        ),
      );
    }

    // Cloud / Pro Mode:
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.language, color: Colors.teal.shade700),
            ),
            title: const Text(
              'Online Payment Gateway',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: const Text(
              'Accept payments via Razorpay, PayU, or Cashfree',
              style: TextStyle(fontSize: 12),
            ),
            value: _onlineEnabled,
            onChanged: (val) => setState(() => _onlineEnabled = val),
          ),
          if (_onlineEnabled) ...[
            const Divider(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedGateway,
              decoration: const InputDecoration(
                labelText: 'Payment Provider',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Razorpay', child: Text('Razorpay (India)')),
                DropdownMenuItem(value: 'PayU', child: Text('PayU (India)')),
                DropdownMenuItem(value: 'Cashfree', child: Text('Cashfree (India)')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedGateway = val);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedEnvironment,
              decoration: const InputDecoration(
                labelText: 'Account Mode',
                prefixIcon: Icon(Icons.tune),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Production', child: Text('Live / Production')),
                DropdownMenuItem(value: 'Sandbox', child: Text('Test / Sandbox')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedEnvironment = val);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _onlineKeyIdController,
              decoration: InputDecoration(
                labelText: 'Key ID / Client ID',
                hintText: _selectedGateway == 'Razorpay'
                    ? 'rzp_live_...'
                    : 'Your API Key ID',
                prefixIcon: const Icon(Icons.key),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _onlineKeySecretController,
              obscureText: !_showKeySecret,
              decoration: InputDecoration(
                labelText: 'Key Secret',
                hintText: 'Enter secret key',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                helperText: _onlineGatewayId != null
                    ? 'Leave blank to keep existing secret'
                    : 'Your secret API key from provider dashboard',
                suffixIcon: IconButton(
                  icon: Icon(_showKeySecret
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _showKeySecret = !_showKeySecret),
                ),
              ),
            ),
            if (_onlineWebhookUrl != null && _onlineWebhookUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.webhook, size: 20, color: Colors.blueGrey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Webhook URL (Configure in Provider Dashboard):',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                            ),
                          ),
                          Text(
                            _onlineWebhookUrl!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      tooltip: 'Copy Webhook URL',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _onlineWebhookUrl!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Webhook URL copied')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Status and test row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _onlineGatewayId != null
                        ? (_onlineLastTestSuccessful == true
                            ? Colors.green.shade50
                            : (_onlineLastTestSuccessful == false
                                ? Colors.red.shade50
                                : Colors.blue.shade50))
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _onlineGatewayId != null
                          ? (_onlineLastTestSuccessful == true
                              ? Colors.green.shade300
                              : (_onlineLastTestSuccessful == false
                                  ? Colors.red.shade300
                                  : Colors.blue.shade300))
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _onlineGatewayId != null
                            ? (_onlineLastTestSuccessful == true
                                ? Icons.check_circle
                                : (_onlineLastTestSuccessful == false
                                    ? Icons.error
                                    : Icons.info))
                            : Icons.radio_button_unchecked,
                        size: 14,
                        color: _onlineGatewayId != null
                            ? (_onlineLastTestSuccessful == true
                                ? Colors.green.shade800
                                : (_onlineLastTestSuccessful == false
                                    ? Colors.red.shade800
                                    : Colors.blue.shade800))
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _onlineGatewayId != null
                            ? (_onlineLastTestSuccessful == true
                                ? (_onlineLastTestedAt != null
                                    ? 'Connected (Verified)'
                                    : 'Connected')
                                : (_onlineLastTestSuccessful == false
                                    ? 'Test Failed'
                                    : 'Configured'))
                            : 'Not Configured',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _onlineGatewayId != null
                              ? (_onlineLastTestSuccessful == true
                                  ? Colors.green.shade800
                                  : (_onlineLastTestSuccessful == false
                                      ? Colors.red.shade800
                                      : Colors.blue.shade800))
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (_onlineGatewayId != null) ...[
                  TextButton.icon(
                    onPressed: _isTestingGateway ? null : _testOnlineGateway,
                    icon: _isTestingGateway
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Test Connection'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Disconnect Gateway',
                    onPressed: _disconnectOnlineGateway,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
