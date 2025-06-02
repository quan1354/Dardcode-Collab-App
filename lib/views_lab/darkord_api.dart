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
  // Change the type to Future<Map<String, dynamic>>?
  Future<Map<String, dynamic>>? _futureUser;
  final TextEditingController _controller = TextEditingController();

  void _performLogin() async {
    try {
      // Example usage of the loginUser function
      final response =
          await loginUser('ii887522@gmail.com', 'ii887522@gmail.com');
      print(
          'Login Response: ${jsonEncode(response)}'); // Print the entire JSON content
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    // Call refresh token first
    refreshToken('10000001').then((response) {
      print('Token refresh successful: $response');
      // After refreshing token, fetch the user data
      _futureUser = fetchUser();
    }).catchError((error) {
      print('Error refreshing token: $error');
      // Even if refresh fails, try to fetch user (might work if token is still valid)
      _futureUser = fetchUser();
    });
    _futureUser = fetchUser();
    _performLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fetch User Example'),
      ),
      body: Center(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _futureUser,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (!snapshot.hasData) {
              return const Text('No data found');
            } else {
              // Access the data directly from the snapshot
              final user = snapshot.data!;
              final payload = user['payload'] as Map<String, dynamic>;
              final identity = payload['identity'] as Map<String, dynamic>;
              final status = payload['status'] as Map<String, dynamic>;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('User ID: ${identity['user_id']}'),
                  Text('Username: ${identity['username']}'),
                  Text('Email: ${identity['email_addr']}'),
                  Text('Status: ${status['status']}'),
                  Text('About Me: ${status['about_me']}'),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}

// ## 1) POST: login 
Future<Map<String, dynamic>> loginUser(String email, String password) async {
  try {
    // Define the URL for the login endpoint
    final url = Uri.parse('https://d3v904dal0xey8.cloudfront.net/user/login');

    // Define the headers, including the authorization token
    final headers = {
      'Authorization':
          'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6IjMifQ.eyJzdWIiOiIxMDAwMDAwMSIsImV4cCI6MTc0MTUyOTU4MSwibmJmIjoxNzQxNTI4NjgxLCJqdGkiOiI3MzlhNGMzYi00ZDE3LTQ4YWYtYWJmNS02NDM0M2NkN2YxNTIiLCJmYW1pbHkiOiI2Z25LcXlPbS1Bd0dyX3dacjkxN3hRIiwic2NvcGUiOiJHRVRfL3VzZXIve3VzZXJfaWR9IFBVVF8vdXNlci97dXNlcl9pZH0gUE9TVF8vdXNlci9sb2dvdXQifQ.ej_RctbAE51yD4n6zBTP8xs7deUmRcTT23RLzv2V0wg','Content-Type': 'application/json',
    };

    // Define the body of the request
    final body = jsonEncode({
      'email_addr': email,
      'password': password,
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
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      // If the server returns an error, throw an exception with the status code and response body
      throw Exception(
        'Failed to login. Status code: ${response.statusCode}, Response: ${response.body}',
      );
    }
  } catch (e) {
    // Catch any exceptions (e.g., network errors, JSON parsing errors) and rethrow with additional context
    throw Exception('An error occurred during login: $e');
  }
}


// ## 4) GET: list 
Future<Map<String, dynamic>> fetchUser() async {
  try {
    final response = await http.get(
      Uri.parse('https://d3v904dal0xey8.cloudfront.net/user/10000001'),
      // Send authorization headers to the backend if needed.
      headers: {
        'Authorization':
            'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6IjMifQ.eyJzdWIiOiIxMDAwMDAwMSIsImV4cCI6MTc0MTUyOTU4MSwibmJmIjoxNzQxNTI4NjgxLCJqdGkiOiI3MzlhNGMzYi00ZDE3LTQ4YWYtYWJmNS02NDM0M2NkN2YxNTIiLCJmYW1pbHkiOiI2Z25LcXlPbS1Bd0dyX3dacjkxN3hRIiwic2NvcGUiOiJHRVRfL3VzZXIve3VzZXJfaWR9IFBVVF8vdXNlci97dXNlcl9pZH0gUE9TVF8vdXNlci9sb2dvdXQifQ.ej_RctbAE51yD4n6zBTP8xs7deUmRcTT23RLzv2V0wg'},
    );

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON and return it as a Map.
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      // If the server did not return a 200 OK response,
      // throw an exception with the status code and response body.
      throw Exception(
        'Failed to load data. Status code: ${response.statusCode}, Response: ${response.body}',
      );
    }
  } catch (e) {
    // Catch any exceptions (e.g., network errors, JSON parsing errors)
    // and rethrow with additional context.
    throw Exception('An error occurred: $e');
  }
}

// ## 6) POST: refresh 
Future<Map<String, dynamic>> refreshToken(String userId) async {
  try {
    // Define the URL for the refresh token endpoint
    final url = Uri.parse('https://d3v904dal0xey8.cloudfront.net/user/token');

    // Define the headers
    final headers = {
      'Content-Type': 'application/json',
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