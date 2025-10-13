// api.dart
import 'dart:convert';
import 'package:darkord/models/user.dart';
import 'package:http/http.dart' as http;
import '../models/auth_response.dart';

class AuthApi {
  static const String _baseUrl = 'https://d3v904dal0xey8.cloudfront.net';
  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print(email);
      print(password);
      // email = 'ii887522@gmail.com';
      // password = 'ii887522@gmail.com';
      final url = Uri.parse('$_baseUrl/user/login');
      final url_mfa = Uri.parse('$_baseUrl/user/login/mfa');

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

      final sessionToken = responseData['payload']['session_token'];
      //final mfa_secret = responseData['payload']['mfa_secret'];
      //print(sessionToken);

      final responseMfa = await http.post(
        url_mfa,
        headers: {
          'Authorization': sessionToken,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'mfa_code': '123456'}),
      );

      final mfaData = jsonDecode(responseMfa.body) as Map<String, dynamic>;
      // print(mfaData);

      _accessToken = mfaData['payload']['access_token'];
      print(accessToken);
      // _refreshToken = responseData['payload']['refresh_token'];
      return mfaData;
      //return AuthResponse.fromJson(responseData);f
    } catch (e) {
      throw Exception('Login error: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> signUpUser(
      String username, String emailAddr, String password) async {
    try {
      final signUpUrl = Uri.parse('$_baseUrl/user');
      final signUpOtpUrl = Uri.parse('$_baseUrl/user/otp');
      final signUpMfaUrl = Uri.parse('$_baseUrl/user/mfa');

      final headers = {
        'Content-Type': 'application/json',
      };

      // Step 1: Initial sign up request
      final signUpResponse = await http.post(
        signUpUrl,
        headers: headers,
        body: jsonEncode({
          'username': username,
          'email_addr': emailAddr,
          'password': password,
        }),
      );

      final signUpData =
          jsonDecode(signUpResponse.body) as Map<String, dynamic>;
      print('Initial Sign Up Response: $signUpData');

      if (signUpResponse.statusCode != 200) {
        throw Exception('Sign up failed: ${signUpData['message']}');
      }

      // Extract OTP from response
      final otp = signUpData['payload']?['otp'] as String?;
      if (otp == null) {
        throw Exception('OTP not received in response');
      }

      // Extract session token
      final sessionToken = signUpData['payload']?['session_token'] as String?;
      if (sessionToken == null) {
        throw Exception('Session token not received');
      }

      // Step 2: Verify OTP
      final otpResponse = await http.post(
        signUpOtpUrl,
        headers: {'Authorization': signUpData['payload']?['session_token']},
        body: jsonEncode({'otp': otp}),
      );

      final otpData = jsonDecode(otpResponse.body) as Map<String, dynamic>;
      print('OTP Verification Response: $otpData');

      if (otpResponse.statusCode != 200) {
        throw Exception('OTP verification failed: ${otpData['message']}');
      }

      // Step 3: Complete MFA verification
      // In a real app, you would get this from user input
      final mfaCode =
          otpData['payload']?['mfa_secret']; // This should come from user input
      print(mfaCode);
      final mfaResponse = await http.post(
        signUpMfaUrl,
        headers: {'Authorization': otpData['payload']?['session_token']},
        body: jsonEncode({'mfa_code': mfaCode}),
      );

      final mfaData = jsonDecode(mfaResponse.body) as Map<String, dynamic>;
      print('MFA Verification Response: $mfaData');

      if (mfaResponse.statusCode != 200) {
        throw Exception('MFA verification failed: ${mfaData['message']}');
      }
      print(mfaData);

      // Extract reset token
      final resetToken = signUpData['payload']?['resend_otp_token'] as String?;
      if (resetToken == null) {
        throw Exception('Reset token not received');
      }

      return {
        'success': true,
        'otp': otp,
        'session_token': sessionToken,
        'reset_token': resetToken,
        'message': 'Sign up initiated successfully'
      };
    } catch (e) {
      throw Exception('Sign up error: $e');
    }
  }

  Future<Map<String, dynamic>> verifyOtp(
      String sessionToken, String otp) async {
    try {
      final otpUrl = Uri.parse('$_baseUrl/user/otp');

      final response = await http.post(
        otpUrl,
        headers: {
          'Authorization': sessionToken,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'otp': otp}),
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      print('OTP Verification Response: $responseData');

      if (response.statusCode != 200) {
        throw Exception('OTP verification failed: ${responseData['message']}');
      }

      return {
        'success': true,
        'session_token': responseData['payload']?['session_token'],
        'mfa_secret': responseData['payload']?['mfa_secret'],
        'message': 'OTP verified successfully'
      };
    } catch (e) {
      throw Exception('OTP verification error: $e');
    }
  }

  Future<Map<String, dynamic>> verifyMfa(
      String sessionToken, String mfaCode) async {
    try {
      final mfaUrl = Uri.parse('$_baseUrl/user/mfa');

      final response = await http.post(
        mfaUrl,
        headers: {
          'Authorization': sessionToken,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'mfa_code': mfaCode}),
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      print('MFA Verification Response: $responseData');

      if (response.statusCode != 200) {
        throw Exception('MFA verification failed: ${responseData['message']}');
      }

      return {
        'success': true,
        'message': 'Registration completed successfully',
        'user_data': responseData
      };
    } catch (e) {
      throw Exception('MFA verification error: $e');
    }
  }

  Future<Map<String, dynamic>> resendOtp(String sessionToken) async {
    try {
      final resendOtpUrl = Uri.parse('$_baseUrl/user/otp/resend');

      final response = await http.post(
        resendOtpUrl,
        headers: {
          'Authorization': sessionToken,
          'Content-Type': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      print('Resend OTP Response: $responseData');

      if (response.statusCode != 200) {
        throw Exception('Resend OTP failed: ${responseData['message']}');
      }

      return {'success': true, 'message': 'OTP resent successfully'};
    } catch (e) {
      throw Exception('Resend OTP error: $e');
    }
  }

  Future<Map<String, dynamic>> resetPassword(
      String emailAddr, String password) async {
    try {
      final requestResetUrl = Uri.parse('$_baseUrl/user/password/request');
      final verifyOtpUrl = Uri.parse('$_baseUrl/user/password/request/otp');
      final confirmResetUrl = Uri.parse('$_baseUrl/user/password');

      final headers = {
        'Content-Type': 'application/json',
      };

      // 1. Initiate password reset request
      final resetRequest = await http.put(
        requestResetUrl,
        headers: headers,
        body: jsonEncode({'email_addr': emailAddr}),
      );

      final resetRequestData =
          jsonDecode(resetRequest.body) as Map<String, dynamic>;
      print('Reset Request Response: $resetRequestData');

      if (resetRequest.statusCode != 200) {
        throw Exception(
            'Reset request failed: ${resetRequestData['message'] ?? 'Unknown error'}');
      }

      // Get session token and OTP
      final sessionToken =
          resetRequestData['payload']?['session_token'] as String?;
      final otp = resetRequestData['payload']?['otp'] as String?;

      if (sessionToken == null || otp == null) {
        throw Exception('Missing session token or OTP in response');
      }

      // 2. Verify OTP
      final verifyResponse = await http.put(
        verifyOtpUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': sessionToken,
        },
        body: jsonEncode({'otp': otp}),
      );

      final verifyData =
          jsonDecode(verifyResponse.body) as Map<String, dynamic>;
      print('OTP Verification Response: $verifyData');

      if (verifyResponse.statusCode != 200) {
        throw Exception(
            'OTP verification failed: ${verifyData['message'] ?? 'Unknown error'}');
      }

      // Get the updated session token for password reset
      final resetSessionToken =
          verifyData['payload']?['session_token'] as String?;
      if (resetSessionToken == null) {
        throw Exception('Missing session token for password reset');
      }

      // 3. Confirm password reset
      final resetResponse = await http.put(
        confirmResetUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': resetSessionToken,
        },
        body: jsonEncode({'password': password}),
      );

      final resetData = jsonDecode(resetResponse.body) as Map<String, dynamic>;
      print('Password Reset Response: $resetData');

      if (resetResponse.statusCode != 200) {
        throw Exception(
            'Password reset failed: ${resetData['message'] ?? 'Unknown error'}');
      }

      return {
        'success': true,
        'message': 'Password reset successfully',
        'data': resetData
      };
    } catch (e) {
      print('Reset Password Error: $e');
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> verifyPasswordResetOtp(
      String sessionToken, String otp) async {
    try {
      final verifyOtpUrl = Uri.parse('$_baseUrl/user/password/request/otp');

      final response = await http.put(
        verifyOtpUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': sessionToken,
        },
        body: jsonEncode({'otp': otp}),
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      print('Password Reset OTP Verification Response: $responseData');

      if (response.statusCode != 200) {
        throw Exception('OTP verification failed: ${responseData['message']}');
      }

      return {
        'success': true,
        'session_token': responseData['payload']?['session_token'],
        'message': 'OTP verified successfully'
      };
    } catch (e) {
      throw Exception('OTP verification error: $e');
    }
  }

  Future<Map<String, dynamic>> initiatePasswordReset(String emailAddr) async {
    try {
      final requestResetUrl = Uri.parse('$_baseUrl/user/password/request');

      final response = await http.put(
        requestResetUrl,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email_addr': emailAddr}),
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      print('Initiate Password Reset Response: $responseData');

      if (response.statusCode != 200) {
        throw Exception(
            'Password reset initiation failed: ${responseData['message']}');
      }

      return {
        'success': true,
        'session_token': responseData['payload']?['session_token'],
        'otp': responseData['payload']?['otp'],
        'reset_token': responseData['payload']?['resend_otp_token'],
        'message': 'Password reset initiated successfully'
      };
    } catch (e) {
      throw Exception('Password reset initiation error: $e');
    }
  }

  Future<User> fetchSingleUser(String accessToken, String userId) async {
    try {
      final uri = Uri.parse('$_baseUrl/user/list').replace(queryParameters: {
        'user_ids': userId,
      });

      final response = await http.get(
        uri,
        headers: {
          'Authorization': accessToken,
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print(responseData);

        if (responseData['payload'] != null &&
            responseData['payload']['results'] != null &&
            (responseData['payload']['results'] as List).isNotEmpty) {
          final userData = responseData['payload']['results'][0];
          return User.fromJson(userData);
        } else {
          throw Exception('No user data found');
        }
      } else {
        throw Exception('Failed to fetch user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }

  Future<List<User>> findNearbyUsers(String accessToken) async {
    try {
      final uri = Uri.parse('$_baseUrl/user/list');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': accessToken,
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        // print(responseData);

        if (responseData['payload'] != null &&
            responseData['payload']['results'] != null) {
          final usersData = responseData['payload']['results'] as List;
          return usersData.map((userJson) => User.fromJson(userJson)).toList();
        } else {
          throw Exception('No user data found');
        }
      } else {
        throw Exception('Failed to fetch users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  Future<Map<String, dynamic>> addUsers(String accessToken, String user_id, List<String> other_user_ids)async{
    try {
      print('TTTTTTTTTTTTTTTTTTTTTTTT: $accessToken');
      final addUsersUrl = Uri.parse('$_baseUrl/chat/$user_id/list');

      final response = await http.post(
        addUsersUrl,
        headers: {
          'Authorization': accessToken,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'other_user_ids': other_user_ids}),
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      print('Add Users Response: $responseData');

      if (response.statusCode != 200) {
        throw Exception('Add Users failed: ${responseData['message']}');
      }

      return {'success': true, 'message': 'Add Users successfully'};
    } catch (e) {
      throw Exception('Add Users error: $e');
    }
  }

  Future<Map<String, dynamic>> fetchUsers(String accessToken, String user_id) async {
  try {
    final fetchUsersUrl = Uri.parse('$_baseUrl/chat/$user_id/list');

    final response = await http.get(
      fetchUsersUrl,
      headers: {
        'Authorization': accessToken,
        'Content-Type': 'application/json',
      },
    );

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    print('Fetch Users successfully: $responseData');

    if (response.statusCode != 200) {
      throw Exception('Fetch Users failed: ${responseData['message']}');
    }

    // Return both success and the actual data
    return {
      'success': true,
      'message': 'Fetch Users successfully',
      'data': responseData // Include the actual data
    };
    
  } catch (e) {
    throw Exception('Fetch Users error: $e');
  }
}

}
