// auth_provider.dart
import 'package:flutter/foundation.dart';
import './api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  String? get accessToken => _apiService.accessToken;
  String? get refreshToken => _apiService.refreshToken;
  
  Future<Map<String, dynamic>> login(String email, String password) async {
    final result = await _apiService.login(email, password);
    notifyListeners(); // Notify listeners when auth state changes
    return result;
  }
  
  // Add other methods as needed
}