import 'package:darkord/views/chat_list.dart';
import 'package:darkord/views/register.dart';
import 'package:darkord/views/reset_password.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:darkord/api/api_service.dart';
import 'package:darkord/utils/dialog_utils.dart';
import 'package:darkord/utils/validators.dart';
import 'package:darkord/widgets/common_widgets.dart';
import 'package:darkord/consts/app_constants.dart';
import 'package:location/location.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _logger = Logger();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  
  bool _isLoading = false;
  Location? _location;
  LocationData? _locationData;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Check if the platform supports location services
  bool get _supportsLocation {
    if (kIsWeb) return false;
    try {
      if (Platform.isWindows) return false;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Request location permission and get location data
  Future<void> _requestLocationPermission() async {
    if (!_supportsLocation) {
      _logger.i('Location services not supported on this platform');
      return;
    }

    try {
      _location = Location();
      
      bool serviceEnabled = await _location!.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location!.requestService();
        if (!serviceEnabled) {
          _logger.w('Location service is not enabled');
          return;
        }
      }

      PermissionStatus permissionGranted = await _location!.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location!.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          _logger.w('Location permission denied');
          return;
        }
      }

      _locationData = await _location!.getLocation();
      _logger.i('Location data: ${_locationData?.latitude}, ${_locationData?.longitude}');
    } catch (e) {
      _logger.e('Error requesting location permission: $e');
    }
  }

  /// Handle form submission and login
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      DialogUtils.showLoading(context, 'Logging in...');

      final response = await _apiService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context);
      DialogUtils.showSuccess(context, 'Login successful!');

      // Request location on supported platforms
      if (_supportsLocation) {
        await _requestLocationPermission();
        if (_locationData != null) {
          print('User Location - Lat: ${_locationData!.latitude}, Long: ${_locationData!.longitude}');
        }
      }

      // Navigate to chat list
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatList(
            accessToken: _apiService.accessToken ?? '',
            apiService: _apiService,
          ),
        ),
      );

      print('Login payload: ${response.toString()}');
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
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
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(),
                  const AppTitle(),
                  const SizedBox(height: 20),
                  
                  // Email Field
                  CustomTextField(
                    controller: _emailController,
                    labelText: 'Email Address',
                    hintText: 'Email Address',
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                  ),
                  const SizedBox(height: 20),
                  
                  // Password Field
                  PasswordTextField(
                    controller: _passwordController,
                    validator: Validators.validatePassword,
                  ),
                  const SizedBox(height: 8),
                  
                  // Navigation Links
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      LinkButton(
                        text: "don't have account ?",
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterForm()),
                        ),
                      ),
                      LinkButton(
                        text: 'forgot password ?',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ResetPasswordForm()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  
                  // Login Button
                  PrimaryButton(
                    text: 'Login',
                    onPressed: _submitForm,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}