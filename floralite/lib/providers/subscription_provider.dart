import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../models/subscription.dart';
import '../services/mobile_auth_service.dart';
import '../services/subscription_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  SubscriptionProvider(this._service);

  final SubscriptionService _service;
  final MobileAuthService _mobileAuthService = MobileAuthService();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  SubscriptionAccess? _access;
  bool _isLoading = true;
  String? _message;
  String? _policyMessage;
  bool _forceUpdateRequired = false;
  bool _readOnlyMode = false;
  bool _hardLockMode = false;

  SubscriptionAccess? get access => _access;
  bool get isLoading => _isLoading;
  String? get message => _policyMessage ?? _message;
  SubscriptionState get state => _access?.state ?? SubscriptionState.locked;
  bool get isForceUpdateRequired => _forceUpdateRequired;
  bool get isReadOnlyMode => _readOnlyMode && !isLocked;
  bool get hasWriteRestrictions => isLocked || isReadOnlyMode;
  bool get blocksBusinessAccess => isLocked;
  bool get isGracePeriod => state == SubscriptionState.gracePeriod;
  bool get isLocked =>
      state == SubscriptionState.locked ||
      _forceUpdateRequired ||
      _hardLockMode;

  String get gracePeriodMessage {
    if (!isGracePeriod) return '';
    return 'Your subscription has expired. Please renew to continue uninterrupted.';
  }

  Future<void> initialize() async {
    _isLoading = true;
    _message = null;
    notifyListeners();
    try {
      _access = await _service.load();
      await _applyBootstrapPolicy();
      if (_access!.requiresInternet) {
        _message = _access!.clockTamperingDetected
            ? 'Clock change detected. Please connect to the internet to verify your subscription.'
            : 'Internet connection required. Floraprise verifies your subscription once every 3 days. Please connect to the internet.';
      }
      _startSilentVerificationWatcher();
      unawaited(_refreshRemotePolicyAndSubscription());
    } catch (e) {
      _message = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyNow() async {
    _isLoading = true;
    _message = null;
    notifyListeners();
    try {
      _access = await _service.verifySubscription();
      await _refreshLicensePolicy();
      _message = _access!.requiresInternet
          ? 'Internet connection required. Floraprise verifies your subscription once every 3 days. Please connect to the internet.'
          : 'Subscription checked.';
    } catch (e) {
      _message =
          'Internet connection required. Floraprise verifies your subscription once every 3 days. Please connect to the internet.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startSilentVerificationWatcher() {
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final hasNetwork =
          results.any((value) => value != ConnectivityResult.none);
      if (!hasNetwork) return;
      unawaited(_refreshRemotePolicyAndSubscription());
    });
  }

  Future<void> _refreshRemotePolicyAndSubscription() async {
    try {
      final resolved = await _service.retryPendingVerification();
      if (resolved != null) {
        _access = resolved;
        _message = 'Payment verified and subscription updated.';
      }
    } on Object {
      // Keep trying through standard subscription refresh path.
    }

    try {
      _access = await _service.verifySubscription();
    } on Object {
      // Keep local state when remote verification is unavailable.
    }

    try {
      await _refreshLicensePolicy();
    } on Object {
      // Keep existing policy when license endpoint is unavailable.
    }

    notifyListeners();
  }

  Future<void> _applyBootstrapPolicy() async {
    final bootstrap = await _mobileAuthService.readBootstrap();
    if (bootstrap == null) return;

    final appConfig = _asMap(bootstrap['appConfig']);
    _forceUpdateRequired =
        appConfig['forceUpdate'] == true || appConfig['ForceUpdate'] == true;

    if (_forceUpdateRequired) {
      _hardLockMode = true;
      _readOnlyMode = false;
      _policyMessage =
          'A mandatory app update is required before you can continue.';
      return;
    }

    final subscription = _asMap(bootstrap['subscription']);
    if (subscription.isNotEmpty) {
      _applySubscriptionStatusPolicy(
        _enumName(subscription['status'] ?? subscription['Status']),
      );
    }
  }

  Future<void> _refreshLicensePolicy() async {
    final status = await _mobileAuthService.getLicenseStatus();

    if (_forceUpdateRequired) {
      _hardLockMode = true;
      _readOnlyMode = false;
      _policyMessage =
          'A mandatory app update is required before you can continue.';
      return;
    }

    final allowsAccess =
        status['allowsAccess'] == true || status['AllowsAccess'] == true;
    final licenseStatus =
        _enumName(status['licenseStatus'] ?? status['LicenseStatus']);
    final subscriptionStatus =
        _enumName(status['subscriptionStatus'] ?? status['SubscriptionStatus']);

    if (!allowsAccess ||
        licenseStatus == 'suspended' ||
        licenseStatus == 'revoked' ||
        licenseStatus == 'expired' ||
        subscriptionStatus == 'suspended' ||
        subscriptionStatus == 'cancelled' ||
        subscriptionStatus == 'expired') {
      _hardLockMode = true;
      _readOnlyMode = false;
      _policyMessage =
          'Your license is currently inactive. Please renew or contact support.';
      return;
    }

    if (subscriptionStatus == 'grace') {
      _hardLockMode = false;
      _readOnlyMode = true;
      _policyMessage =
          'Your subscription is in grace period. You can view data, but write actions are temporarily restricted.';
      return;
    }

    _hardLockMode = false;
    _readOnlyMode = false;
    _policyMessage = null;
  }

  void _applySubscriptionStatusPolicy(String status) {
    if (status == 'grace') {
      _readOnlyMode = true;
      _hardLockMode = false;
      _policyMessage =
          'Your subscription is in grace period. You can view data, but write actions are temporarily restricted.';
      return;
    }

    if (status == 'suspended' || status == 'cancelled' || status == 'expired') {
      _hardLockMode = true;
      _readOnlyMode = false;
      _policyMessage =
          'Your subscription is inactive. Please renew or contact support.';
      return;
    }

    _hardLockMode = false;
    _readOnlyMode = false;
    _policyMessage = null;
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

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return <String, dynamic>{};
  }

  Future<void> restorePurchase() async {
    _isLoading = true;
    _message = null;
    notifyListeners();
    try {
      _access = await _service.restorePurchase();
      await _refreshLicensePolicy();
      _message = _access!.state == SubscriptionState.active
          ? 'Purchase restored.'
          : 'No active subscription was found.';
    } catch (e) {
      _message =
          'Unable to restore purchase. Please connect to the internet and try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startPurchase(SubscriptionPlan plan) async {
    _isLoading = true;
    _message = null;
    notifyListeners();
    try {
      _access = await _service.startPurchase(plan);
      await _refreshLicensePolicy();
      _message = _access!.state == SubscriptionState.active
          ? 'Subscription activated.'
          : 'Unable to start subscription. Please try again.';
    } catch (e) {
      _message = 'Unable to start subscription. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool canCreateOrders() {
    return !hasWriteRestrictions;
  }

  bool canCreatePurchases() {
    return !hasWriteRestrictions;
  }

  bool canModifyInventory() {
    return !hasWriteRestrictions;
  }

  bool canCreateCustomers() {
    return !hasWriteRestrictions;
  }

  bool canCreateStaff() {
    return !hasWriteRestrictions;
  }

  bool canPerformProduction() {
    return !hasWriteRestrictions;
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }
}
