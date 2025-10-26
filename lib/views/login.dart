import 'package:darkord/views/chat_list.dart';
import 'package:darkord/views/register.dart';
import 'package:darkord/views/reset_password.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:darkord/api/auth_api.dart';
import 'package:darkord/utils/dialog_utils.dart';
import 'package:location/location.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final logger = Logger();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true; // Track password visibility
  bool _isLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthApi _authApi = AuthApi();

  Location location = new Location();
  bool _locationServiceEnabled = false;
  PermissionStatus? _permissionGranted;
  LocationData? _locationData;

  // Check if the platform supports location services
  bool get _supportsLocation {
    // Skip location on web and Windows
    if (kIsWeb) return false;
    if (Platform.isWindows) return false;
    // You can add other unsupported platforms if needed
    // if (Platform.isLinux) return false;
    // if (Platform.isMacOS) return false;
    return true;
  }

  Future<void> _requestLocationPermission() async {
    // Skip location request if platform doesn't support it
    if (!_supportsLocation) {
      logger.i('Location services not supported on this platform');
      return;
    }

    try {
      _locationServiceEnabled = await location.serviceEnabled();
      if (!_locationServiceEnabled) {
        _locationServiceEnabled = await location.requestService();
        if (!_locationServiceEnabled) {
          logger.w('Location service is not enabled');
          return;
        }
      }

      _permissionGranted = await location.hasPermission();
      if (_permissionGranted == PermissionStatus.denied) {
        _permissionGranted = await location.requestPermission();
        if (_permissionGranted != PermissionStatus.granted) {
          logger.w('Location permission denied');
          return;
        }
      }

      _locationData = await location.getLocation();
      setState(() {});
      logger.i('Location permission granted. Location data: $_locationData');
    } catch (e) {
      logger.e('Error requesting location permission: $e');
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    // Check for at least two of the following: letter, number, or symbol
    int count = 0;
    if (RegExp(r'[A-Za-z]').hasMatch(value)) count++; // Check for letters
    if (RegExp(r'[0-9]').hasMatch(value)) count++; // Check for numbers
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value))
      count++; // Check for symbols

    if (count < 2) {
      return 'Password must include at least two of the following: letter, number, or symbol';
    }

    return null;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Variables to store location data
    double? userLatitude;
    double? userLongitude;

    try {
      DialogUtils.showLoading(context, 'Logging in...');

      final response = await _authApi.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      Navigator.pop(context);
      DialogUtils.showSuccess(context, 'Login successful!');

      // Only request location on supported platforms
      if (_supportsLocation) {
        await _requestLocationPermission();

        if (_locationData != null) {
          userLatitude = _locationData!.latitude;
          userLongitude = _locationData!.longitude;

          // Print location data
          print(
              'User Location - Latitude: $userLatitude, Longitude: $userLongitude');

          logger.i(
              'Location data stored - Lat: $userLatitude, Long: $userLongitude');
        } else {
          logger.w('Location data is null');
        }
      } else {
        logger.i('Skipping location request on this platform');
        print('Platform does not support location services');
      }

      // Pass the response data and location to ChatList
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatList(
            accessToken: _authApi.accessToken ?? '',
            loginPayload: response, // Pass the response data
            // If you want to pass location to ChatList, add these parameters:
            // userLatitude: userLatitude,
            // userLongitude: userLongitude,
          ),
        ),
      );

      print('Login payload: ${response.toString()}');
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        DialogUtils.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          // Added SingleChildScrollView
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white, // White background color
                      border: Border.all(
                        color: Colors.yellow, // Border color
                        width: 5.0, // Border width
                      ),
                    ),
                    child: Image.asset(
                      'assets/logo2.png', // Path to your image
                      width: 200, // Set the width
                      height: 190, // Set the height
                    ),
                  ),
                  Text(
                    'Darkord',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Colors.white), // Normal border color
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color:
                                Colors.blueAccent), // Border color when focused
                      ),
                      labelText: 'Email Address',
                      labelStyle: TextStyle(color: Colors.white),
                      hintText: 'Email Address',
                      hintStyle: TextStyle(color: Colors.white70),
                      prefixIcon: Icon(Icons.email, color: Colors.white),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword, // Use the state variable
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Colors.white), // Normal border color
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color:
                                Colors.blueAccent), // Border color when focused
                      ),
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Colors.white),
                      hintText: 'Password',
                      hintStyle: TextStyle(color: Colors.white70),
                      prefixIcon: Icon(Icons.lock, color: Colors.white),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword =
                                !_obscurePassword; // Toggle visibility
                          });
                        },
                      ),
                    ),
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => RegisterForm()),
                          );
                        },
                        child: Text(
                          'don\'t have account ?',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 236, 57, 45),
                            decoration:
                                TextDecoration.underline, // Underline text
                            decorationColor: Color.fromARGB(255, 236, 57, 45),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ResetPasswordForm()),
                          );
                        },
                        child: Text(
                          'forgot password ?',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 236, 57, 45),
                            decoration:
                                TextDecoration.underline, // Underline text
                            decorationColor: Color.fromARGB(255, 236, 57, 45),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: 200, // Set the button width
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _isLoading ? null : _submitForm();
                        }
                      },
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Login'),
                    ),
                  ),
                  const SizedBox(height: 20), // Added extra space at the bottom
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}