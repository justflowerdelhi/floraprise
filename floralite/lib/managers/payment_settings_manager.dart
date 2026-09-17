import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../data/database/app_database.dart';
import '../data/repositories/cloud_payment_gateway_repository.dart';
import '../services/storage_mode_service.dart';

class PaymentSettings {
  final bool cashEnabled;
  final bool upiEnabled;
  final String upiId;
  final String upiMerchantName;
  final bool cardEnabled;
  final bool hasCardMachine;
  final String cardTerminalId;
  final bool onlineEnabled;
  final String? onlineGatewayId;
  final String onlineGatewayType;
  final String onlinePublicKey;
  final String onlineEnvironment;
  final String? onlineWebhookUrl;
  final DateTime? onlineLastTestedAt;
  final bool? onlineLastTestSuccessful;
  final bool isCloudMode;

  const PaymentSettings({
    this.cashEnabled = true,
    this.upiEnabled = true,
    this.upiId = '',
    this.upiMerchantName = '',
    this.cardEnabled = true,
    this.hasCardMachine = false,
    this.cardTerminalId = '',
    this.onlineEnabled = false,
    this.onlineGatewayId,
    this.onlineGatewayType = 'Razorpay',
    this.onlinePublicKey = '',
    this.onlineEnvironment = 'Production',
    this.onlineWebhookUrl,
    this.onlineLastTestedAt,
    this.onlineLastTestSuccessful,
    this.isCloudMode = false,
  });

  PaymentSettings copyWith({
    bool? cashEnabled,
    bool? upiEnabled,
    String? upiId,
    String? upiMerchantName,
    bool? cardEnabled,
    bool? hasCardMachine,
    String? cardTerminalId,
    bool? onlineEnabled,
    String? onlineGatewayId,
    String? onlineGatewayType,
    String? onlinePublicKey,
    String? onlineEnvironment,
    String? onlineWebhookUrl,
    DateTime? onlineLastTestedAt,
    bool? onlineLastTestSuccessful,
    bool? isCloudMode,
  }) {
    return PaymentSettings(
      cashEnabled: cashEnabled ?? this.cashEnabled,
      upiEnabled: upiEnabled ?? this.upiEnabled,
      upiId: upiId ?? this.upiId,
      upiMerchantName: upiMerchantName ?? this.upiMerchantName,
      cardEnabled: cardEnabled ?? this.cardEnabled,
      hasCardMachine: hasCardMachine ?? this.hasCardMachine,
      cardTerminalId: cardTerminalId ?? this.cardTerminalId,
      onlineEnabled: onlineEnabled ?? this.onlineEnabled,
      onlineGatewayId: onlineGatewayId ?? this.onlineGatewayId,
      onlineGatewayType: onlineGatewayType ?? this.onlineGatewayType,
      onlinePublicKey: onlinePublicKey ?? this.onlinePublicKey,
      onlineEnvironment: onlineEnvironment ?? this.onlineEnvironment,
      onlineWebhookUrl: onlineWebhookUrl ?? this.onlineWebhookUrl,
      onlineLastTestedAt: onlineLastTestedAt ?? this.onlineLastTestedAt,
      onlineLastTestSuccessful:
          onlineLastTestSuccessful ?? this.onlineLastTestSuccessful,
      isCloudMode: isCloudMode ?? this.isCloudMode,
    );
  }

  String get upiQrString {
    final cleanId = upiId.trim();
    if (cleanId.isEmpty) return '';
    final name = upiMerchantName.trim().isNotEmpty
        ? Uri.encodeComponent(upiMerchantName.trim())
        : 'Florist';
    return 'upi://pay?pa=$cleanId&pn=$name&cu=INR';
  }
}

class PaymentSettingsManager {
  PaymentSettingsManager({
    CloudPaymentGatewayRepository? cloudRepository,
    StorageModeService? storageModeService,
  })  : _cloudRepository = cloudRepository ?? CloudPaymentGatewayRepository(),
        _storageModeService = storageModeService ?? StorageModeService();

  final CloudPaymentGatewayRepository _cloudRepository;
  final StorageModeService _storageModeService;

  static const _cashEnabledKey = 'payment.cash_enabled';
  static const _upiEnabledKey = 'payment.upi_enabled';
  static const _upiIdKey = 'payment.upi_id';
  static const _upiMerchantNameKey = 'payment.upi_merchant_name';
  static const _cardEnabledKey = 'payment.card_enabled';
  static const _hasCardMachineKey = 'payment.has_card_machine';
  static const _cardTerminalIdKey = 'payment.card_terminal_id';
  static const _onlineEnabledKey = 'payment.online_enabled';

  Future<PaymentSettings> load() async {
    final isCloud = kIsWeb || await _storageModeService.isCloud();

    bool cashEnabled = true;
    bool upiEnabled = true;
    String upiId = '';
    String upiMerchantName = '';
    bool cardEnabled = true;
    bool hasCardMachine = false;
    String cardTerminalId = '';
    bool onlineEnabled = false;

    if (!kIsWeb) {
      try {
        final db = await AppDatabase.instance.database;
        final cashRaw = await _readValue(db, _cashEnabledKey);
        final upiRaw = await _readValue(db, _upiEnabledKey);
        final upiIdRaw = await _readValue(db, _upiIdKey);
        final upiNameRaw = await _readValue(db, _upiMerchantNameKey);
        final cardRaw = await _readValue(db, _cardEnabledKey);
        final machineRaw = await _readValue(db, _hasCardMachineKey);
        final termRaw = await _readValue(db, _cardTerminalIdKey);
        final onlineRaw = await _readValue(db, _onlineEnabledKey);

        cashEnabled = cashRaw == null ? true : cashRaw == '1';
        upiEnabled = upiRaw == null ? true : upiRaw == '1';
        upiId = upiIdRaw ?? '';
        upiMerchantName = upiNameRaw ?? '';
        cardEnabled = cardRaw == null ? true : cardRaw == '1';
        hasCardMachine = machineRaw == '1';
        cardTerminalId = termRaw ?? '';
        onlineEnabled = onlineRaw == '1';
      } catch (_) {}
    }

    String? onlineGatewayId;
    String onlineGatewayType = 'Razorpay';
    String onlinePublicKey = '';
    String onlineEnvironment = 'Production';
    String? onlineWebhookUrl;
    DateTime? onlineLastTestedAt;
    bool? onlineLastTestSuccessful;

    if (isCloud) {
      try {
        final configs = await _cloudRepository.fetchConfigs();
        if (configs.isNotEmpty) {
          final activeConfig = configs.firstWhere(
            (c) => c.isDefault || c.isActive,
            orElse: () => configs.first,
          );
          onlineGatewayId = activeConfig.id;
          onlineGatewayType = activeConfig.gatewayTypeName;
          onlinePublicKey = activeConfig.publicKey;
          onlineEnvironment = activeConfig.environmentName;
          onlineWebhookUrl = activeConfig.webhookUrl;
          onlineLastTestedAt = activeConfig.lastTestedAt;
          onlineLastTestSuccessful = activeConfig.lastTestSuccessful;
          onlineEnabled = activeConfig.isActive;
        }
      } catch (_) {}
    }

    return PaymentSettings(
      cashEnabled: cashEnabled,
      upiEnabled: upiEnabled,
      upiId: upiId,
      upiMerchantName: upiMerchantName,
      cardEnabled: cardEnabled,
      hasCardMachine: hasCardMachine,
      cardTerminalId: cardTerminalId,
      onlineEnabled: onlineEnabled,
      onlineGatewayId: onlineGatewayId,
      onlineGatewayType: onlineGatewayType,
      onlinePublicKey: onlinePublicKey,
      onlineEnvironment: onlineEnvironment,
      onlineWebhookUrl: onlineWebhookUrl,
      onlineLastTestedAt: onlineLastTestedAt,
      onlineLastTestSuccessful: onlineLastTestSuccessful,
      isCloudMode: isCloud,
    );
  }

  Future<void> saveLocalPaymentSettings({
    required bool cashEnabled,
    required bool upiEnabled,
    required String upiId,
    required String upiMerchantName,
    required bool cardEnabled,
    required bool hasCardMachine,
    required String cardTerminalId,
    bool onlineEnabled = false,
  }) async {
    if (kIsWeb) return;
    try {
      final db = await AppDatabase.instance.database;
      await _writeValue(db, _cashEnabledKey, cashEnabled ? '1' : '0');
      await _writeValue(db, _upiEnabledKey, upiEnabled ? '1' : '0');
      await _writeValue(db, _upiIdKey, upiId.trim());
      await _writeValue(db, _upiMerchantNameKey, upiMerchantName.trim());
      await _writeValue(db, _cardEnabledKey, cardEnabled ? '1' : '0');
      await _writeValue(db, _hasCardMachineKey, hasCardMachine ? '1' : '0');
      await _writeValue(db, _cardTerminalIdKey, cardTerminalId.trim());
      await _writeValue(db, _onlineEnabledKey, onlineEnabled ? '1' : '0');
    } catch (_) {}
  }

  Future<CloudPaymentGatewayConfig> saveCloudGateway({
    String? existingId,
    required String gatewayType,
    required String name,
    required String publicKey,
    required String secretKey,
    String? webhookSecret,
    String? merchantId,
    String environment = 'Production',
    bool isDefault = true,
  }) async {
    if (existingId != null && existingId.isNotEmpty) {
      return await _cloudRepository.updateConfig(
        id: existingId,
        name: name,
        publicKey: publicKey,
        secretKey: secretKey,
        webhookSecret: webhookSecret,
        merchantId: merchantId,
        environment: environment,
        isActive: true,
        isDefault: isDefault,
      );
    } else {
      return await _cloudRepository.createConfig(
        gatewayType: gatewayType,
        name: name,
        publicKey: publicKey,
        secretKey: secretKey,
        webhookSecret: webhookSecret,
        merchantId: merchantId,
        environment: environment,
        isDefault: isDefault,
      );
    }
  }

  Future<PaymentGatewayTestResult> testGatewayConnection(String gatewayId) async {
    return await _cloudRepository.testConnection(gatewayId);
  }

  Future<bool> deleteGateway(String gatewayId) async {
    return await _cloudRepository.deleteConfig(gatewayId);
  }

  Future<String?> _readValue(Database db, String key) async {
    final rows = await db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> _writeValue(Database db, String key, String value) async {
    await db.insert(
      'settings',
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
