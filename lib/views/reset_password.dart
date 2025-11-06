import 'package:darkord/views/login.dart';
import 'package:darkord/views/email_verification.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:darkord/api/api_service.dart';
import 'package:darkord/utils/validators.dart';
import 'package:darkord/widgets/common_widgets.dart';
import 'package:darkord/consts/app_constants.dart';

class ResetPasswordForm extends StatefulWidget {
  const ResetPasswordForm({super.key});

  @override
  _ResetPasswordFormState createState() => _ResetPasswordFormState();
}

class _ResetPasswordFormState extends State<ResetPasswordForm> {
  final _logger = Logger();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _apiService = ApiService();
  
  bool _isEmailVerified = false;
  bool _isLoading = false;
  String? _sessionToken;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailVerification() async {
    if (!_formKey.currentState!.validate() || _emailController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final result = await _apiService.initiatePasswordReset(_emailController.text.trim());

      if (result['success'] == true) {
        if (!mounted) return;
        
        final verificationResult = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmailVerificationPage(
              userEmail: _emailController.text.trim(),
              sessionToken: result['session_token'],
              isPasswordReset: true,
              resetToken: result['reset_token'],
            ),
          ),
        );

        if (verificationResult != null && verificationResult['verified'] == true) {
          setState(() {
            _isEmailVerified = true;
            _sessionToken = verificationResult['session_token'];
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      _logger.e('Email verification error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handlePasswordReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _apiService.resetPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (result['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset successfully!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginForm()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset failed: ${e.toString()}')),
      );
      _logger.e('Password reset error: $e');
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
                    readOnly: _isEmailVerified,
                    validator: Validators.validateEmail,
                  ),

                  // Password Fields (shown after email verification)
                  if (_isEmailVerified) ...[
                    const SizedBox(height: 20),
                    PasswordTextField(
                      controller: _passwordController,
                      labelText: 'New Password',
                      hintText: 'New Password',
                      validator: Validators.validatePassword,
                    ),
                    const SizedBox(height: 20),
                    PasswordTextField(
                      controller: _confirmPasswordController,
                      labelText: 'Confirm Password',
                      hintText: 'Confirm Password',
                      validator: (value) => Validators.validateConfirmPassword(
                        value,
                        _passwordController.text,
                      ),
                    ),
                  ],

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

                  // Action Button
                  PrimaryButton(
                    text: _isEmailVerified ? 'Reset Password' : 'Verify Email',
                    onPressed: _isEmailVerified ? _handlePasswordReset : _handleEmailVerification,
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
