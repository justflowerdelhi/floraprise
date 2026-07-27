import 'package:flutter/foundation.dart';

import '../services/mobile_auth_service.dart';

enum AuthProviderState {
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._service);

  final MobileAuthService _service;

  AuthProviderState _state = AuthProviderState.loading;
  String? _message;
  Map<String, dynamic>? _bootstrap;

  AuthProviderState get state => _state;
  String? get message => _message;
  bool get isLoading => _state == AuthProviderState.loading;
  bool get isAuthenticated => _state == AuthProviderState.authenticated;
  Map<String, dynamic>? get bootstrap => _bootstrap;

  String get friendlyMessage {
    if (_message == null || _message!.trim().isEmpty) {
      return 'Something went wrong. Please try again.';
    }
    return _message!;
  }

  Future<void> initialize() async {
    _state = AuthProviderState.loading;
    _message = null;
    notifyListeners();

    try {
      final shouldAutoLogin = await _service.hasRememberedSession();
      if (!shouldAutoLogin) {
        _state = AuthProviderState.unauthenticated;
        notifyListeners();
        return;
      }

      final payload = await _service.refreshAndBootstrap();
      _bootstrap = payload.bootstrap;
      _message = _subscriptionMessage(_bootstrap);
      _state = _canAccess(_bootstrap)
          ? AuthProviderState.authenticated
          : AuthProviderState.error;
      notifyListeners();
    } on MobileAuthServiceException catch (ex) {
      _state = AuthProviderState.unauthenticated;
      _message = _mapErrorMessage(ex.code, ex.message);
      notifyListeners();
    }
  }

  Future<bool> login({
    required String identifier,
    required String password,
    required bool rememberLogin,
  }) async {
    _state = AuthProviderState.loading;
    _message = null;
    notifyListeners();

    try {
      final payload = await _service.login(
        identifier: identifier,
        password: password,
        rememberLogin: rememberLogin,
      );

      _bootstrap = payload.bootstrap;
      _message = _subscriptionMessage(_bootstrap);

      final canAccess = _canAccess(_bootstrap);
      _state =
          canAccess ? AuthProviderState.authenticated : AuthProviderState.error;
      notifyListeners();
      return canAccess;
    } on MobileAuthServiceException catch (ex) {
      _state = AuthProviderState.error;
      _message = _mapErrorMessage(ex.code, ex.message);
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String companyName,
    required String ownerName,
    required String mobile,
    required String address,
    required String city,
    required String email,
    required String password,
  }) async {
    _state = AuthProviderState.loading;
    _message = null;
    notifyListeners();

    try {
      final payload = await _service.register(
        companyName: companyName,
        ownerName: ownerName,
        mobile: mobile,
        address: address,
        city: city,
        email: email,
        password: password,
      );

      _bootstrap = payload.bootstrap;
      _message = _subscriptionMessage(_bootstrap);

      final canAccess = _canAccess(_bootstrap);
      _state =
          canAccess ? AuthProviderState.authenticated : AuthProviderState.error;
      notifyListeners();
      return canAccess;
    } on MobileAuthServiceException catch (ex) {
      _state = AuthProviderState.error;
      _message = _mapErrorMessage(ex.code, ex.message);
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _state = AuthProviderState.loading;
    notifyListeners();

    try {
      await _service.logout();
    } finally {
      _bootstrap = null;
      _message = null;
      _state = AuthProviderState.unauthenticated;
      notifyListeners();
    }
  }

  bool _canAccess(Map<String, dynamic>? bootstrap) {
    if (bootstrap == null) return false;
    final subscription = bootstrap['subscription'];
    if (subscription is! Map) return true;

    final status = (subscription['status'] ?? '').toString().toUpperCase();
    if (status == 'EXPIRED' ||
        status == 'SUSPENDED' ||
        status == 'DEACTIVATED') {
      return false;
    }

    final isTrial = subscription['isTrial'] == true;
    final trialEndsAtRaw = subscription['trialEndsAtUtc']?.toString();
    if (isTrial && trialEndsAtRaw != null && trialEndsAtRaw.isNotEmpty) {
      final trialEndsAt = DateTime.tryParse(trialEndsAtRaw)?.toUtc();
      if (trialEndsAt != null && DateTime.now().toUtc().isAfter(trialEndsAt)) {
        return false;
      }
    }

    return true;
  }

  String? _subscriptionMessage(Map<String, dynamic>? bootstrap) {
    if (bootstrap == null) return null;
    final subscription = bootstrap['subscription'];
    if (subscription is! Map) return null;

    final status = (subscription['status'] ?? '').toString().toUpperCase();
    if (status == 'EXPIRED') {
      return 'Your subscription has expired. Please renew to continue.';
    }

    if (status == 'SUSPENDED') {
      return 'Your account is suspended. Please contact support.';
    }

    if (status == 'DEACTIVATED') {
      return 'Your subscription is deactivated. Please contact support.';
    }

    final isTrial = subscription['isTrial'] == true;
    final trialEndsAtRaw = subscription['trialEndsAtUtc']?.toString();
    if (isTrial && trialEndsAtRaw != null && trialEndsAtRaw.isNotEmpty) {
      final trialEndsAt = DateTime.tryParse(trialEndsAtRaw)?.toUtc();
      if (trialEndsAt != null && DateTime.now().toUtc().isAfter(trialEndsAt)) {
        return 'Your trial period has expired. Please upgrade your plan.';
      }
    }

    return null;
  }

  String _mapErrorMessage(String code, String fallback) {
    switch (code) {
      case 'invalid_credentials':
        return 'Invalid login. Please check your mobile/email and password.';
      case 'network_unavailable':
        return 'Network unavailable. Please check your internet connection.';
      case 'server_unavailable':
        return 'Server unavailable right now. Please try again shortly.';
      case 'account_disabled':
        return 'Your account is disabled. Please contact support.';
      case 'email_exists':
        return 'This email is already registered.';
      case 'mobile_exists':
        return 'This mobile number is already registered.';
      default:
        return fallback;
    }
  }
}
