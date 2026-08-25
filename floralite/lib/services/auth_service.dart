import 'package:http/http.dart' as http;

import 'mobile_auth_service.dart';

class AuthService {
  AuthService({
    MobileAuthService? mobileAuthService,
    http.Client? httpClient,
  })  : _mobileAuthService = mobileAuthService ?? MobileAuthService(),
        httpClient = httpClient ?? http.Client();

  final MobileAuthService _mobileAuthService;
  final http.Client httpClient;

  String get baseUrl => _mobileAuthService.baseUrl;

  Future<String?> getAccessToken() {
    return _mobileAuthService.getStoredAccessToken();
  }
}
