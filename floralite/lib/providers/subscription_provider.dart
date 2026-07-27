import 'package:flutter/foundation.dart';

import '../models/subscription.dart';
import '../services/subscription_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  SubscriptionProvider(this._service);

  final SubscriptionService _service;

  SubscriptionAccess? _access;
  bool _isLoading = true;
  String? _message;

  SubscriptionAccess? get access => _access;
  bool get isLoading => _isLoading;
  String? get message => _message;
  SubscriptionState get state => _access?.state ?? SubscriptionState.locked;
  bool get blocksBusinessAccess => _access?.blocksBusinessAccess ?? true;
  bool get isGracePeriod => state == SubscriptionState.gracePeriod;
  bool get isLocked => state == SubscriptionState.locked;
  
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
      if (_access!.requiresInternet) {
        _message = _access!.clockTamperingDetected
            ? 'Clock change detected. Please connect to the internet to verify your subscription.'
            : 'Internet connection required. Floraprise verifies your subscription once every 3 days. Please connect to the internet.';
      }
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

  Future<void> restorePurchase() async {
    _isLoading = true;
    _message = null;
    notifyListeners();
    try {
      _access = await _service.restorePurchase();
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
    return !isLocked;
  }

  bool canCreatePurchases() {
    return !isLocked;
  }

  bool canModifyInventory() {
    return !isLocked;
  }

  bool canCreateCustomers() {
    return !isLocked;
  }

  bool canCreateStaff() {
    return !isLocked;
  }

  bool canPerformProduction() {
    return !isLocked;
  }
}
