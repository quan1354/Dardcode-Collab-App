import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth_response.dart';

class AuthApi {
  static const String _baseUrl = 'https://d3v904dal0xey8.cloudfront.net';

  Future<AuthResponse> login(String email, String password) async {
    try {
      print(email);
      print(password);
      final url = Uri.parse('$_baseUrl/user/login');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email_addr': email,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);
      print(responseData);

      if (response.statusCode != 200) {
        throw Exception(responseData['message'] ?? 'Login failed');
      }

      // For now, just return the initial login response
      return AuthResponse.fromJson(responseData);

      // If you need to automatically handle MFA with a dummy code:
      /*
    final sessionToken = responseData['payload']['session_token'];
    final mfaResponse = await http.post(
      Uri.parse('$_baseUrl/user/login/mfa'),
      headers: {
        'Authorization': sessionToken,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'mfa_code': '123456'}),
    );
    
    return AuthResponse.fromJson(jsonDecode(mfaResponse.body));
    */
    } catch (e) {
      throw Exception('Login error: ${e.toString()}');
    }
  }
}
