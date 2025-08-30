import 'dart:ffi';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fetch User Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<Map<String, dynamic>>? _futureUser;
  final TextEditingController _controller = TextEditingController();
  String? _userAccessToken; // Make this nullable
  String? _userRefreshToken;
  bool _isLoading = false;

  Future<Map<String, String>?> _performLogin() async {
    try {
      final response =
          await loginUser('ii887522@gmail.com', 'ii887522@gmail.com');
      print('Login Response: $response');

      if (response['payload'] == null) {
        throw Exception('Login succeeded but no payload received');
      }

      return {
        'accessToken': response['payload']['access_token'],
        'refreshToken': response['payload']['refresh_token'],
      };
    } catch (e) {
      print('Login Error: $e');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    // Optionally auto-login when the app starts
    _performLoginAndFetchUser();
  }

  Future<void> _performLoginAndFetchUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // First perform login
      final tokens = await _performLogin();

      if (tokens != null) {
        _userAccessToken = tokens['accessToken'];
        _userRefreshToken = tokens['refreshToken'];

        // Then fetch user data using the access token
        setState(() {
          _futureUser = fetchUser(_userAccessToken);
        });
      } else {
        throw Exception('Login failed');
      }
    } catch (e) {
      print('Error during login or fetch: $e');
      // Handle error appropriately
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fetch User Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_futureUser == null)
              ElevatedButton(
                onPressed: _performLoginAndFetchUser,
                child: const Text('Login and Fetch User'),
              )
            else
              FutureBuilder<Map<String, dynamic>>(
                future: _futureUser,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData) {
                    return const Text('No data found');
                  } else {
                    final user = snapshot.data!;

                    if (user['payload'] == null) {
                      return const Text('Invalid user data format');
                    }

                    final payload = user['payload'] as Map<String, dynamic>;

                    // Check if results exist and has at least one item
                    if (payload['results'] == null ||
                        (payload['results'] as List).isEmpty) {
                      return const Text('No user data found in results');
                    }

                    // Get the first result (since we requested only one user)
                    final result =
                        (payload['results'] as List)[0] as Map<String, dynamic>;

                    // Check if identity and status exist in the result
                    if (result['identity'] == null ||
                        result['status'] == null) {
                      return const Text(
                          'Missing identity or status in user data');
                    }

                    final identity = result['identity'] as Map<String, dynamic>;
                    final status = result['status'] as Map<String, dynamic>;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('User ID: ${identity['user_id'] ?? 'N/A'}'),
                        Text('Username: ${identity['username'] ?? 'N/A'}'),
                        Text('Email: ${identity['email_addr'] ?? 'N/A'}'),
                        Text('Status: ${status['status'] ?? 'N/A'}'),
                        Text('About Me: ${status['about_me'] ?? 'N/A'}'),
                      ],
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ## 4) GET: list
Future<Map<String, dynamic>> fetchUser(String? accessToken) async {
  print(accessToken);
  if (accessToken == null) {
    throw Exception('No session token available');
  }

  try {
    // Build the URL with query parameters
    final uri = Uri.parse('https://d3v904dal0xey8.cloudfront.net/user/list')
        .replace(queryParameters: {
      'user_ids': '10000020',
      'identity': 'true',
      'status': 'true',
    });

    print('Request URL: ${uri.toString()}');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': accessToken,
      },
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'Failed to load data. Status code: ${response.statusCode}, Response: ${response.body}',
      );
    }
  } catch (e) {
    throw Exception('An error occurred: $e');
  }
}

// ## 3) PUT: Reset Password
Future<Map<String, dynamic>> resetPassword(
    String emailAddr, String password) async {
  try {
    // Step 1: Request password reset
    final requestResetUrl = Uri.parse(
        'https://d3v904dal0xey8.cloudfront.net/user/password/request');
    final verifyOtpUrl = Uri.parse(
        'https://d3v904dal0xey8.cloudfront.net/user/password/request/otp');
    final confirmResetUrl =
        Uri.parse('https://d3v904dal0xey8.cloudfront.net/user/password');

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

    // Get session token and OTP (in staging)
    final sessionToken =
        resetRequestData['payload']?['session_token'] as String?;
    final otp = resetRequestData['payload']?['otp'] as String?;

    if (sessionToken == null || otp == null) {
      throw Exception('Missing session token or OTP in response');
    }
    print(jsonEncode({'otp': otp}));
    // 2. Verify OTP
    final verifyResponse = await http.put(
      verifyOtpUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': sessionToken,
      },
      body: jsonEncode({'otp': otp}),
    );

    final verifyData = jsonDecode(verifyResponse.body) as Map<String, dynamic>;
    print('OTP Verification Response: $verifyData');

    if (verifyResponse.statusCode != 200) {
      throw Exception(
          'OTP verification failed: ${verifyData['message'] ?? 'Unknown error'}');
    }

    // 3. Confirm password reset
    final resetResponse = await http.put(
      confirmResetUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': verifyData['payload']?['session_token'],
      },
      body: jsonEncode({
        'password': password,
      }),
    );

    final resetData = jsonDecode(resetResponse.body) as Map<String, dynamic>;
    print('Password Reset Response: $resetData');

    if (resetResponse.statusCode != 200) {
      throw Exception(
          'Password reset failed: ${resetData['message'] ?? 'Unknown error'}');
    }

    return resetData;
  } catch (e) {
    print('Reset Password Error: $e');
    throw Exception('Password reset failed: ${e.toString()}');
  }
}

// ## 2) POST: Sign Up
Future<Map<String, dynamic>> signUpUser(
    String username, String emailAddr, String password) async {
  try {
    // Step 1: Initial sign up request
    final signUpUrl = Uri.parse('https://d3v904dal0xey8.cloudfront.net/user');
    final signUpOtpUrl =
        Uri.parse('https://d3v904dal0xey8.cloudfront.net/user/otp');
    final signUpMfaUrl =
        Uri.parse('https://d3v904dal0xey8.cloudfront.net/user/mfa');

    final headers = {
      'Content-Type': 'application/json',
    };

    // Initial sign up request
    final signUpResponse = await http.post(
      signUpUrl,
      headers: headers,
      body: jsonEncode({
        'username': username,
        'email_addr': emailAddr,
        'password': password,
      }),
    );

    final signUpData = jsonDecode(signUpResponse.body) as Map<String, dynamic>;
    print('Initial Sign Up Response: $signUpData');

    if (signUpResponse.statusCode != 200) {
      throw Exception('Sign up failed: ${signUpData['message']}');
    }

    // Extract OTP from response (only available in staging)
    final otp = signUpData['payload']?['otp'] as String?;
    if (otp == null) {
      throw Exception('OTP not received in response');
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

    return mfaData;
  } catch (e) {
    throw Exception('Sign up error: $e');
  }
}

// ## 1) POST: login
Future<Map<String, dynamic>> loginUser(String email, String password) async {
  try {
    final loginUrl =
        Uri.parse('https://d3v904dal0xey8.cloudfront.net/user/login');
    final mfaUrl =
        Uri.parse('https://d3v904dal0xey8.cloudfront.net/user/login/mfa');

    final headers = {
      'Authorization':
          'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6IjYifQ.eyJzdWIiOiIxMDAwMDAwMSIsImV4cCI6MTc0OTM0Mzk1MSwibmJmIjoxNzQ5MzQzNjUxLCJqdGkiOiJiOWEyOWI2Yi1mMjQyLTQxODMtYmYyNi1kMDE4NGJiYjI1MmYiLCJzY29wZSI6IlBPU1RfL3VzZXIvbG9naW4vbWZhIn0.PHFa-UIsqbOyz5wkdZzD77a4Z-4FFMzAin95HN2d_YE',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'email_addr': email,
      'password': password,
    });

    // Initial login request
    final response = await http.post(
      loginUrl,
      headers: headers,
      body: body,
    );

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    print(responseData);

    // Check if login was successful
    if (response.statusCode != 200) {
      throw Exception('Login failed: ${responseData['message']}');
    }

    // Check if payload exists
    if (responseData['payload'] == null) {
      throw Exception('Login failed: No payload received');
    }

    final sessionToken = responseData['payload']['session_token'];

    // MFA request
    final responseMfa = await http.post(
      mfaUrl,
      headers: {
        'Authorization': sessionToken,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'mfa_code': '123456'}),
    );

    final mfaData = jsonDecode(responseMfa.body) as Map<String, dynamic>;
    print(mfaData);

    if (responseMfa.statusCode != 200) {
      throw Exception('MFA failed: ${mfaData['message']}');
    }

    return mfaData;
  } catch (e) {
    throw Exception('Login error: $e');
  }
}

// ## 6) POST: refresh access Token - 5 min Refresh token - 1 days
Future<Map<String, dynamic>> refreshToken(
    String userId, String? refreshToken) async {
  if (refreshToken == null) {
    throw Exception('Refresh token is null');
  }

  try {
    // Define the URL for the refresh token endpoint
    final url = Uri.parse('https://d3v904dal0xey8.cloudfront.net/user/token');

    // Define the headers
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': refreshToken
    };

    // Define the body of the request with the user_id
    final body = jsonEncode({
      'user_id': userId,
    });

    // Make the POST request
    final response = await http.post(
      url,
      headers: headers,
      body: body,
    );

    // Check the response status code
    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, parse the JSON
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      // You might want to store the new tokens here
      final accessToken = responseData['payload']['access_token'];
      final refreshToken = responseData['payload']['refresh_token'];
      print('New Access Token: $accessToken');
      print('New Refresh Token: $refreshToken');

      return responseData;
    } else {
      // If the server returns an error, throw an exception
      throw Exception(
        'Failed to refresh token. Status code: ${response.statusCode}, Response: ${response.body}',
      );
    }
  } catch (e) {
    // Catch any exceptions and rethrow with additional context
    throw Exception('An error occurred during token refresh: $e');
  }
}
