import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:sqflite/sqflite.dart';

import '../data/database/app_database.dart';
import '../models/subscription.dart';
import 'mobile_auth_service.dart';

abstract class SubscriptionVerificationClient {
  Future<LicenseVerificationResult> verify(SubscriptionRecord record);
  Future<LicenseVerificationResult> restorePurchase();
  Future<LicenseVerificationResult> startPurchase(SubscriptionPlan plan);
  Future<LicenseVerificationResult> retryPendingVerification();
}

abstract class SubscriptionSecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class FlutterSubscriptionSecureStore implements SubscriptionSecureStore {
  const FlutterSubscriptionSecureStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) {
    return _storage.write(key: key, value: value);
  }
}

class MemorySubscriptionSecureStore implements SubscriptionSecureStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}

class RazorpaySubscriptionClient implements SubscriptionVerificationClient {
  RazorpaySubscriptionClient({
    required MobileAuthService mobileAuthService,
    required SubscriptionSecureStore secureStore,
    Razorpay? razorpay,
  })  : _mobileAuthService = mobileAuthService,
        _secureStore = secureStore,
        _razorpay = razorpay ?? Razorpay();

  final MobileAuthService _mobileAuthService;
  final SubscriptionSecureStore _secureStore;
  final Razorpay _razorpay;

  static const _pendingTransactionRefKey = 'subscription_pending_tx_ref';
  static const _pendingGatewayOrderIdKey = 'subscription_pending_gateway_order';
  static const _pendingPlanCodeKey = 'subscription_pending_plan_code';
  static const _pendingBillingCycleKey = 'subscription_pending_billing_cycle';
  static const _pendingPaymentIdKey = 'subscription_pending_payment_id';
  static const _pendingSignatureKey = 'subscription_pending_signature';

  @override
  Future<LicenseVerificationResult> verify(SubscriptionRecord record) async {
    try {
      final current = await _mobileAuthService.getCurrentSubscription();
      final statusName = _enumName(
        current['status'] ?? current['subscriptionStatus'],
      );
      final plan = _mapRemotePlan(_resolveString(current, 'planCode'));

      final trialEndRaw = _resolveString(current, 'trialEndUtc');
      final endRaw = _resolveString(current, 'endUtc');
      final graceEndRaw = _resolveString(current, 'graceEndUtc');

      final expiryDate = DateTime.tryParse(
            trialEndRaw.isNotEmpty
                ? trialEndRaw
                : (endRaw.isNotEmpty ? endRaw : graceEndRaw),
          ) ??
          record.expiryDate;

      final token = record.purchaseToken ??
          _resolveString(current, 'lastPaymentId').trim();

      final isActiveLike = statusName == 'trial' ||
          statusName == 'active' ||
          statusName == 'grace';

      if (isActiveLike) {
        return LicenseVerificationResult.active(
          plan: plan,
          expiryDate: expiryDate,
          purchaseToken: token,
        );
      }

      return LicenseVerificationResult.expired(
        plan: plan,
        expiryDate: expiryDate,
        purchaseToken: token,
      );
    } catch (_) {
      return const LicenseVerificationResult.unverified();
    }
  }

  @override
  Future<LicenseVerificationResult> restorePurchase() async {
    return const LicenseVerificationResult.unverified();
  }

  @override
  Future<LicenseVerificationResult> retryPendingVerification() async {
    final transactionRef = await _secureStore.read(_pendingTransactionRefKey);
    final gatewayOrderId = await _secureStore.read(_pendingGatewayOrderIdKey);
    final planCode = await _secureStore.read(_pendingPlanCodeKey);
    final billingCycle = await _secureStore.read(_pendingBillingCycleKey);
    final paymentId = await _secureStore.read(_pendingPaymentIdKey);
    final signature = await _secureStore.read(_pendingSignatureKey);

    if ([
      transactionRef,
      gatewayOrderId,
      planCode,
      billingCycle,
      paymentId,
      signature
    ].any((value) => value == null || value.trim().isEmpty)) {
      return const LicenseVerificationResult.unverified();
    }

    try {
      final verifyResponse = await _mobileAuthService.verifySubscriptionPayment(
        transactionRef: transactionRef!,
        gatewayOrderId: gatewayOrderId!,
        paymentId: paymentId!,
        signature: signature!,
        planCode: planCode!,
        billingCycle: billingCycle!,
      );

      final verified = verifyResponse['verified'] == true ||
          _resolveString(verifyResponse, 'status').toLowerCase() == 'paid';
      if (!verified) {
        return const LicenseVerificationResult.unverified();
      }

      final updated = await _mobileAuthService.getCurrentSubscription();
      await _clearPendingVerification();
      return _verificationResultFromCurrent(updated,
          fallbackPlanCode: planCode);
    } catch (_) {
      return const LicenseVerificationResult.unverified();
    }
  }

  @override
  Future<LicenseVerificationResult> startPurchase(SubscriptionPlan plan) async {
    final plans = await _mobileAuthService.getSubscriptionPlans();
    final planData = plans.firstWhere(
      (p) => _resolveString(p, 'code').toLowerCase() == plan.storageValue,
      orElse: () => <String, dynamic>{},
    );

    if (planData.isEmpty) {
      return const LicenseVerificationResult.unverified();
    }

    final planId = _resolveString(planData, 'id');
    if (planId.isEmpty) {
      return const LicenseVerificationResult.unverified();
    }

    final selectedBillingCycle = _billingCycleForPlan(plan);

    try {
      final response = await _mobileAuthService.createSubscriptionOrder(
        planId,
        billingCycle: selectedBillingCycle,
      );

      final clientPayload = _asMap(response['clientPayload']);
      final gatewayOrderId =
          _resolveString(response, 'gatewayOrderId').isNotEmpty
              ? _resolveString(response, 'gatewayOrderId')
              : _resolveString(response, 'orderId');
      final transactionRef = _resolveString(response, 'transactionRef');
      final amount =
          _toNum(response['amount']) ?? _toNum(clientPayload['amount']);
      final currency = _resolveString(response, 'currency').isNotEmpty
          ? _resolveString(response, 'currency')
          : _resolveString(clientPayload, 'currency');
      final keyId = _resolveCheckoutKey(response, clientPayload);

      if (gatewayOrderId.isEmpty ||
          transactionRef.isEmpty ||
          amount == null ||
          currency.isEmpty ||
          keyId.isEmpty) {
        return const LicenseVerificationResult.unverified();
      }

      final completer = Completer<LicenseVerificationResult>();

      final options = {
        'key': keyId,
        'amount': (amount * 100).toInt(), // Razorpay expects amount in paise
        'name': 'Floraprise',
        'description': plan.name,
        'order_id': gatewayOrderId,
        'currency': currency,
        'prefill': {
          'contact': '',
          'email': '',
        },
      };

      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS,
          (PaymentSuccessResponse response) async {
        final paymentId = response.paymentId;
        final signature = response.signature;
        final paidOrderId = response.orderId;

        if (paymentId == null || signature == null || paidOrderId == null) {
          if (!completer.isCompleted) {
            completer.complete(const LicenseVerificationResult.unverified());
          }
          return;
        }

        try {
          await _storePendingVerification(
            transactionRef: transactionRef,
            gatewayOrderId: paidOrderId,
            paymentId: paymentId,
            signature: signature,
            planCode: _resolveString(planData, 'code'),
            billingCycle: selectedBillingCycle,
          );

          final verifyResponse =
              await _mobileAuthService.verifySubscriptionPayment(
            transactionRef: transactionRef,
            gatewayOrderId: paidOrderId,
            paymentId: paymentId,
            signature: signature,
            planCode: _resolveString(planData, 'code'),
            billingCycle: selectedBillingCycle,
          );

          final verified = verifyResponse['verified'] == true ||
              _resolveString(verifyResponse, 'status').toLowerCase() == 'paid';
          if (!verified) {
            if (!completer.isCompleted) {
              completer.complete(const LicenseVerificationResult.unverified());
            }
            return;
          }

          final updated = await _mobileAuthService.getCurrentSubscription();
          await _clearPendingVerification();
          final result = _verificationResultFromCurrent(
            updated,
            fallbackPlanCode: _resolveString(planData, 'code'),
          );
          if (!completer.isCompleted) {
            completer.complete(result);
          }
        } catch (_) {
          if (!completer.isCompleted) {
            completer.complete(const LicenseVerificationResult.unverified());
          }
        }
      });

      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR,
          (PaymentFailureResponse response) {
        if (!completer.isCompleted) {
          completer.complete(const LicenseVerificationResult.unverified());
        }
      });

      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET,
          (ExternalWalletResponse response) {
        // Handle external wallet if needed
      });

      _razorpay.open(options);

      final result = await completer.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () async {
          return const LicenseVerificationResult.unverified();
        },
      );

      return result;
    } catch (e) {
      debugPrint('Subscription purchase failed: $e');
      return const LicenseVerificationResult.unverified();
    }
  }

  Future<void> _storePendingVerification({
    required String transactionRef,
    required String gatewayOrderId,
    required String paymentId,
    required String signature,
    required String planCode,
    required String billingCycle,
  }) async {
    await _secureStore.write(_pendingTransactionRefKey, transactionRef);
    await _secureStore.write(_pendingGatewayOrderIdKey, gatewayOrderId);
    await _secureStore.write(_pendingPaymentIdKey, paymentId);
    await _secureStore.write(_pendingSignatureKey, signature);
    await _secureStore.write(_pendingPlanCodeKey, planCode);
    await _secureStore.write(_pendingBillingCycleKey, billingCycle);
  }

  Future<void> _clearPendingVerification() async {
    await _secureStore.write(_pendingTransactionRefKey, '');
    await _secureStore.write(_pendingGatewayOrderIdKey, '');
    await _secureStore.write(_pendingPaymentIdKey, '');
    await _secureStore.write(_pendingSignatureKey, '');
    await _secureStore.write(_pendingPlanCodeKey, '');
    await _secureStore.write(_pendingBillingCycleKey, '');
  }

  LicenseVerificationResult _verificationResultFromCurrent(
    Map<String, dynamic> current, {
    required String fallbackPlanCode,
  }) {
    final planCode = _resolveString(current, 'planCode').isNotEmpty
        ? _resolveString(current, 'planCode')
        : fallbackPlanCode;
    final plan = _mapRemotePlan(planCode);
    final statusName =
        _enumName(current['status'] ?? current['subscriptionStatus']);
    final trialEndRaw = _resolveString(current, 'trialEndUtc');
    final endUtcRaw = _resolveString(current, 'endUtc');
    final graceEndRaw = _resolveString(current, 'graceEndUtc');
    final expiryDate = DateTime.tryParse(
          trialEndRaw.isNotEmpty
              ? trialEndRaw
              : (endUtcRaw.isNotEmpty ? endUtcRaw : graceEndRaw),
        ) ??
        DateTime.now().add(SubscriptionPlans.byPlan(plan).duration);

    if (statusName == 'active' ||
        statusName == 'trial' ||
        statusName == 'grace') {
      return LicenseVerificationResult.active(
        plan: plan,
        expiryDate: expiryDate,
        purchaseToken: _resolveString(current, 'lastPaymentId'),
      );
    }

    return LicenseVerificationResult.expired(
      plan: plan,
      expiryDate: expiryDate,
      purchaseToken: _resolveString(current, 'lastPaymentId'),
    );
  }

  String _billingCycleForPlan(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.quarterly:
        return 'quarterly';
      case SubscriptionPlan.halfYearly:
        return 'half-yearly';
      case SubscriptionPlan.annual:
        return 'annual';
      case SubscriptionPlan.trial:
        return 'monthly';
    }
  }

  SubscriptionPlan _mapRemotePlan(String planCode) {
    final normalized = planCode.trim().toLowerCase();
    if (normalized.contains('quarter')) return SubscriptionPlan.quarterly;
    if (normalized.contains('half')) return SubscriptionPlan.halfYearly;
    if (normalized.contains('annual') || normalized.contains('year')) {
      return SubscriptionPlan.annual;
    }
    return SubscriptionPlan.trial;
  }

  String _enumName(Object? value) {
    if (value is String) {
      return value.trim().toLowerCase();
    }
    if (value is num) {
      switch (value.toInt()) {
        case 1:
          return 'trial';
        case 2:
          return 'active';
        case 3:
          return 'grace';
        case 4:
          return 'suspended';
        case 5:
          return 'cancelled';
        case 6:
          return 'expired';
      }
    }
    return '';
  }

  String _resolveCheckoutKey(
    Map<String, dynamic> response,
    Map<String, dynamic> clientPayload,
  ) {
    final direct = _resolveString(response, 'keyId');
    if (direct.isNotEmpty) return direct;

    final alternate = _resolveString(response, 'key');
    if (alternate.isNotEmpty) return alternate;

    final nested = _resolveString(clientPayload, 'keyId');
    if (nested.isNotEmpty) return nested;

    return _resolveString(clientPayload, 'key');
  }

  String _resolveString(Map<String, dynamic> json, String key) {
    final value = json[key] ?? json[_pascalCase(key)];
    return value?.toString().trim() ?? '';
  }

  String _pascalCase(String key) {
    if (key.isEmpty) return key;
    return '${key[0].toUpperCase()}${key.substring(1)}';
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return <String, dynamic>{};
  }

  num? _toNum(Object? value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '');
  }
}

class FlorapriseLicenseClient implements SubscriptionVerificationClient {
  const FlorapriseLicenseClient();

  @override
  Future<LicenseVerificationResult> verify(SubscriptionRecord record) async {
    return const LicenseVerificationResult.unverified();
  }

  @override
  Future<LicenseVerificationResult> restorePurchase() async {
    return const LicenseVerificationResult.unverified();
  }

  @override
  Future<LicenseVerificationResult> startPurchase(SubscriptionPlan plan) async {
    return const LicenseVerificationResult.unverified();
  }

  @override
  Future<LicenseVerificationResult> retryPendingVerification() async {
    return const LicenseVerificationResult.unverified();
  }
}

class SubscriptionService {
  SubscriptionService({
    MobileAuthService? mobileAuthService,
    SubscriptionVerificationClient? razorpayClient,
    SubscriptionVerificationClient? licenseClient,
    SubscriptionSecureStore? secureStore,
    DateTime Function()? now,
  })  : _secureStore = secureStore ?? const FlutterSubscriptionSecureStore(),
        _razorpayClient = razorpayClient ??
            RazorpaySubscriptionClient(
              mobileAuthService: mobileAuthService ?? MobileAuthService(),
              secureStore:
                  secureStore ?? const FlutterSubscriptionSecureStore(),
            ),
        _licenseClient = licenseClient ?? const FlorapriseLicenseClient(),
        _now = now ?? DateTime.now;

  static final trialDuration = SubscriptionPlans.trial.duration;
  static const graceDuration = Duration(days: 30);
  static const offlineDuration = Duration(days: 3);
  static const _appVersion = '1.0.0';

  final SubscriptionVerificationClient _razorpayClient;
  final SubscriptionVerificationClient _licenseClient;
  final SubscriptionSecureStore _secureStore;
  final DateTime Function() _now;

  Future<SubscriptionAccess> load() async {
    final record = await _loadOrCreateTrial();
    return _accessFor(record);
  }

  bool isVerificationDue(SubscriptionAccess access) {
    final now = _now();
    return now.isAfter(access.record.offlineExpiry) ||
        access.clockTamperingDetected;
  }

  Future<SubscriptionAccess> verifySubscription() async {
    final record = await _loadOrCreateTrial();
    final result = await _verifyWithAvailableClients(record);
    if (!result.verified) {
      await _log('verification_unavailable', record.status.storageValue);
      return _accessFor(record);
    }

    final updated = _recordFromVerification(record, result);
    await _save(updated);
    await _log('verification_success', updated.status.storageValue);
    return _accessFor(updated);
  }

  Future<SubscriptionAccess?> retryPendingVerification() async {
    final record = await _loadOrCreateTrial();
    final result = await _razorpayClient.retryPendingVerification();
    if (!result.verified) {
      return null;
    }

    final updated = _recordFromVerification(record, result);
    await _save(updated);
    await _log('pending_verification_resolved', updated.status.storageValue);
    return _accessFor(updated);
  }

  Future<SubscriptionAccess> restorePurchase() async {
    final record = await _loadOrCreateTrial();
    final result = await _razorpayClient.restorePurchase();
    if (!result.verified) {
      await _log('restore_unavailable', record.status.storageValue);
      return _accessFor(record);
    }

    final updated = _recordFromVerification(record, result);
    await _save(updated);
    await _log('restore_success', updated.status.storageValue);
    return _accessFor(updated);
  }

  Future<SubscriptionAccess> startPurchase(SubscriptionPlan plan) async {
    final record = await _loadOrCreateTrial();
    final result = await _razorpayClient.startPurchase(plan);
    if (!result.verified) {
      await _log('purchase_unavailable', record.status.storageValue);
      return _accessFor(record);
    }

    final updated = _recordFromVerification(record, result);
    await _save(updated);
    await _log('purchase_success', updated.status.storageValue);
    return _accessFor(updated);
  }

  Future<SubscriptionAccess> activateLocalSubscription({
    required SubscriptionPlan plan,
    required DateTime expiryDate,
    required String purchaseToken,
  }) async {
    final record = await _loadOrCreateTrial();
    final updated = _recordFromVerification(
      record,
      LicenseVerificationResult.active(
        plan: plan,
        expiryDate: expiryDate,
        purchaseToken: purchaseToken,
      ),
    );
    await _save(updated);
    await _log('local_activation', updated.status.storageValue);
    return _accessFor(updated);
  }

  Future<LicenseVerificationResult> _verifyWithAvailableClients(
    SubscriptionRecord record,
  ) async {
    final razorpayResult = await _razorpayClient.verify(record);
    if (razorpayResult.verified) return razorpayResult;
    return _licenseClient.verify(record);
  }

  SubscriptionRecord _recordFromVerification(
    SubscriptionRecord current,
    LicenseVerificationResult result,
  ) {
    final now = _now();
    final expiryDate = result.expiryDate ?? current.expiryDate;
    final status = result.expired || expiryDate.isBefore(now)
        ? _stateForExpiredPaidPlan(result.plan, expiryDate, now)
        : SubscriptionState.active;

    return current.copyWith(
      status: status,
      plan: result.plan,
      purchaseToken: result.purchaseToken,
      expiryDate: expiryDate,
      graceEndDate: result.plan == SubscriptionPlan.trial
          ? expiryDate
          : expiryDate.add(graceDuration),
      lastVerification: now,
      offlineExpiry: now.add(offlineDuration),
      lastAppVersion: _appVersion,
    );
  }

  SubscriptionState _stateForExpiredPaidPlan(
    SubscriptionPlan plan,
    DateTime expiryDate,
    DateTime now,
  ) {
    if (plan == SubscriptionPlan.trial) return SubscriptionState.locked;
    final graceEnd = expiryDate.add(graceDuration);
    if (!now.isAfter(graceEnd)) return SubscriptionState.gracePeriod;
    return SubscriptionState.locked;
  }

  SubscriptionAccess _accessFor(SubscriptionRecord record) {
    final now = _now();
    final state = _computedState(record, now);
    final clockTamperingDetected = now.isBefore(
      record.lastVerification.subtract(const Duration(minutes: 5)),
    );
    final requiresInternet =
        clockTamperingDetected || now.isAfter(record.offlineExpiry);
    final updated =
        record.status == state ? record : record.copyWith(status: state);

    if (record.status != state) {
      _save(updated);
    }

    return SubscriptionAccess(
      record: updated,
      state: state,
      requiresInternet: requiresInternet,
      clockTamperingDetected: clockTamperingDetected,
    );
  }

  SubscriptionState _computedState(SubscriptionRecord record, DateTime now) {
    if (record.status == SubscriptionState.locked &&
        record.plan == SubscriptionPlan.trial) {
      return SubscriptionState.locked;
    }
    if (!now.isAfter(record.expiryDate)) return SubscriptionState.active;
    if (record.plan == SubscriptionPlan.trial) return SubscriptionState.locked;
    if (!now.isAfter(record.graceEndDate)) return SubscriptionState.gracePeriod;
    return SubscriptionState.locked;
  }

  Future<SubscriptionRecord> _loadOrCreateTrial() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('subscription', limit: 1);
    if (rows.isNotEmpty) {
      return _withSecureTimestamps(SubscriptionRecord.fromMap(rows.first));
    }

    final trialStarted = await _hasLog(db, 'trial_started') ||
        (await _secureStore.read('trial_started')) == 'true';
    final now = _now();
    final record = SubscriptionRecord(
      status:
          trialStarted ? SubscriptionState.locked : SubscriptionState.active,
      plan: SubscriptionPlan.trial,
      purchaseToken: null,
      expiryDate: trialStarted ? now : now.add(trialDuration),
      graceEndDate: trialStarted ? now : now.add(trialDuration),
      lastVerification: now,
      offlineExpiry: now.add(offlineDuration),
      lastAppVersion: _appVersion,
    );

    await _save(record);
    await _secureStore.write('trial_started', 'true');
    await _log(trialStarted ? 'trial_reuse_blocked' : 'trial_started',
        record.status.storageValue);
    return record;
  }

  Future<SubscriptionRecord> _withSecureTimestamps(
    SubscriptionRecord record,
  ) async {
    if (record.status == SubscriptionState.locked &&
        record.plan == SubscriptionPlan.trial) {
      return record;
    }

    final securedLastVerification = await _secureDate('last_verification');
    final securedOfflineExpiry = await _secureDate('offline_expiry');
    return record.copyWith(
      lastVerification: securedLastVerification ?? record.lastVerification,
      offlineExpiry: securedOfflineExpiry ?? record.offlineExpiry,
    );
  }

  Future<DateTime?> _secureDate(String key) async {
    final value = await _secureStore.read(key);
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value);
  }

  Future<bool> _hasLog(Database db, String event) async {
    final rows = await db.query(
      'license_log',
      columns: ['id'],
      where: 'event = ?',
      whereArgs: [event],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> _save(SubscriptionRecord record) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'subscription',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _writeSecureRecord(record);
  }

  Future<void> _writeSecureRecord(SubscriptionRecord record) async {
    await _secureStore.write(
      'last_verification',
      record.lastVerification.toIso8601String(),
    );
    await _secureStore.write(
      'offline_expiry',
      record.offlineExpiry.toIso8601String(),
    );
  }

  Future<void> _log(String event, String status) async {
    final db = await AppDatabase.instance.database;
    await db.insert('license_log', {
      'event': event,
      'status': status,
      'created_at': _now().toIso8601String(),
    });
  }
}
