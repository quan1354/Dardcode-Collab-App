// auth_provider.dart
import 'package:flutter/foundation.dart';
import './auth_api.dart';

class AuthProvider with ChangeNotifier {
  final AuthApi _authApi = AuthApi();
  
  String? get accessToken => _authApi.accessToken;
  String? get refreshToken => _authApi.refreshToken;
  
  Future<Map<String, dynamic>> login(String email, String password) async {
    final result = await _authApi.login(email, password);
    notifyListeners(); // Notify listeners when auth state changes
    return result;
  }
  
  // Add other methods as needed
}