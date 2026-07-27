import 'package:flutter/foundation.dart';

import '../models/license.dart';
import '../services/license_service.dart';

enum LicenseProviderState {
  loading,
  unregistered,
  valid,
  expired,
  suspended,
  internetRequired,
}

class LicenseProvider extends ChangeNotifier {
  LicenseProvider(this._service);

  final LicenseService _service;

  LicenseProviderState _state = LicenseProviderState.loading;
  CloudLicenseCheckResult? _license;
  String? _message;

  LicenseProviderState get state => _state;
  CloudLicenseCheckResult? get license => _license;
  String? get message => _message;
  bool get isLoading => _state == LicenseProviderState.loading;
  bool get isRegistered => _state != LicenseProviderState.unregistered;
  bool get blocksBusinessAccess =>
      _state == LicenseProviderState.expired ||
      _state == LicenseProviderState.suspended ||
      _state == LicenseProviderState.internetRequired;

  Future<void> initialize() async {
    _state = LicenseProviderState.loading;
    _message = null;
    notifyListeners();
    await _check();
  }

  Future<bool> register(BusinessRegistrationInput input) async {
    _state = LicenseProviderState.loading;
    _message = null;
    notifyListeners();
    try {
      final result = await _service.register(input);
      _applyResult(result);
      return result.allowsAccess;
    } on Object catch (error) {
      _state = LicenseProviderState.unregistered;
      _message = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> refresh() => _check();

  Future<void> heartbeat() async {
    if (blocksBusinessAccess || _state == LicenseProviderState.unregistered) {
      return;
    }
    await _service.heartbeat();
  }

  Future<void> _check() async {
    try {
      final result = await _service.checkLicense();
      _applyResult(result);
    } on Object catch (error) {
      _state = LicenseProviderState.internetRequired;
      _message = error.toString();
      notifyListeners();
    }
  }

  void _applyResult(CloudLicenseCheckResult result) {
    _license = result;
    _message = result.message;
    switch (result.status) {
      case CloudLicenseStatus.trial:
      case CloudLicenseStatus.active:
        _state = LicenseProviderState.valid;
      case CloudLicenseStatus.expired:
        _state = LicenseProviderState.expired;
      case CloudLicenseStatus.suspended:
        _state = LicenseProviderState.suspended;
      case CloudLicenseStatus.unregistered:
        _state = LicenseProviderState.unregistered;
      case CloudLicenseStatus.internetRequired:
        _state = LicenseProviderState.internetRequired;
    }
    notifyListeners();
  }
}
