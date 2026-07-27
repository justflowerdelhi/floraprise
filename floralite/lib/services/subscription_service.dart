import 'dart:async';

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
    Razorpay? razorpay,
  })  : _mobileAuthService = mobileAuthService,
        _razorpay = razorpay ?? Razorpay();

  final MobileAuthService _mobileAuthService;
  final Razorpay _razorpay;

  @override
  Future<LicenseVerificationResult> verify(SubscriptionRecord record) async {
    if (record.purchaseToken == null || record.purchaseToken!.trim().isEmpty) {
      return const LicenseVerificationResult.unverified();
    }
    return const LicenseVerificationResult.unverified();
  }

  @override
  Future<LicenseVerificationResult> restorePurchase() async {
    return const LicenseVerificationResult.unverified();
  }

  @override
  Future<LicenseVerificationResult> startPurchase(SubscriptionPlan plan) async {
    // Get plan ID from backend plans
    final plans = await _mobileAuthService.getSubscriptionPlans();
    final planData = plans.firstWhere(
      (p) => p['code']?.toString().toLowerCase() == plan.name.toLowerCase(),
      orElse: () => <String, dynamic>{},
    );

    if (planData.isEmpty) {
      return const LicenseVerificationResult.unverified();
    }

    final planId = planData['id'] as String?;
    if (planId == null) {
      return const LicenseVerificationResult.unverified();
    }

    // Call backend to create Razorpay order
    try {
      final response = await _mobileAuthService.createSubscriptionOrder(planId);
      final orderId = response['orderId'] as String?;
      final amount = response['amount'] as num?;
      final currency = response['currency'] as String?;
      final keyId = response['keyId'] as String?;

      if (orderId == null ||
          amount == null ||
          currency == null ||
          keyId == null) {
        return const LicenseVerificationResult.unverified();
      }

      // Open Razorpay checkout
      final completer = Completer<LicenseVerificationResult>();

      final options = {
        'key': keyId,
        'amount': (amount * 100).toInt(), // Razorpay expects amount in paise
        'name': 'Floraprise',
        'description': plan.name,
        'order_id': orderId,
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
        final orderId = response.orderId;

        if (paymentId == null || signature == null || orderId == null) {
          completer.complete(const LicenseVerificationResult.unverified());
          return;
        }

        // Verify payment with backend
        try {
          final verifyResponse =
              await _mobileAuthService.verifySubscriptionPayment(
            orderId: orderId,
            paymentId: paymentId,
            signature: signature,
            planId: planId,
          );

          if (verifyResponse['success'] == true) {
            final licenseData = verifyResponse['data'] as Map<String, dynamic>?;
            if (licenseData != null) {
              final subscriptionEndUtc =
                  licenseData['subscriptionEndUtc'] as String?;

              final config = SubscriptionPlans.byPlan(plan);
              final expiryDate = subscriptionEndUtc != null
                  ? DateTime.parse(subscriptionEndUtc)
                  : DateTime.now().add(config.duration);

              completer.complete(LicenseVerificationResult.active(
                plan: plan,
                expiryDate: expiryDate,
                purchaseToken: paymentId,
              ));
            } else {
              completer.complete(const LicenseVerificationResult.unverified());
            }
          } else {
            completer.complete(const LicenseVerificationResult.unverified());
          }
        } catch (e) {
          completer.complete(const LicenseVerificationResult.unverified());
        }
      });

      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR,
          (PaymentFailureResponse response) {
        completer.complete(const LicenseVerificationResult.unverified());
      });

      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET,
          (ExternalWalletResponse response) {
        // Handle external wallet if needed
      });

      _razorpay.open(options);

      final result = await completer.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () => const LicenseVerificationResult.unverified(),
      );

      return result;
    } catch (e) {
      return const LicenseVerificationResult.unverified();
    }
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
}

class SubscriptionService {
  SubscriptionService({
    required MobileAuthService mobileAuthService,
    SubscriptionVerificationClient? razorpayClient,
    SubscriptionVerificationClient? licenseClient,
    SubscriptionSecureStore? secureStore,
    DateTime Function()? now,
  })  : _razorpayClient = razorpayClient ??
            RazorpaySubscriptionClient(mobileAuthService: mobileAuthService),
        _licenseClient = licenseClient ?? const FlorapriseLicenseClient(),
        _secureStore = secureStore ?? const FlutterSubscriptionSecureStore(),
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
