import 'package:darkord/views/login.dart';
import 'package:darkord/views/email_verification.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:darkord/api/api_service.dart';
import 'package:darkord/utils/validators.dart';
import 'package:darkord/widgets/common_widgets.dart';
import 'package:darkord/consts/app_constants.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  _RegisterFormState createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _logger = Logger();
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _apiService.signUpUser(
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (result['success'] == true) {
        _logger.i('Sign up initiated successfully');

        if (!mounted) return;
        
        // Navigate to email verification
        final verificationResult = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmailVerificationPage(
              userEmail: _emailController.text.trim(),
              userName: _usernameController.text.trim(),
              sessionToken: result['session_token'],
              resetToken: result['reset_token'],
            ),
          ),
        );

        _logger.i('Verification result: $verificationResult');

        if (verificationResult != null && verificationResult['verified'] == true) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration completed successfully!')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up failed: ${e.toString()}')),
      );
      _logger.e('Sign up error: $e');
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

                  // Username Field
                  CustomTextField(
                    controller: _usernameController,
                    labelText: 'Username',
                    hintText: 'Username',
                    prefixIcon: Icons.person,
                    validator: Validators.validateUsername,
                  ),
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

                  // Back to Login Link
                  Container(
                    alignment: Alignment.centerLeft,
                    child: LinkButton(
                      text: 'Back to Login',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginForm()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Sign Up Button
                  PrimaryButton(
                    text: 'Sign up for an account',
                    onPressed: _handleSignUp,
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
