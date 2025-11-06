import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:darkord/api/api_service.dart';
import 'package:darkord/utils/validators.dart';
import 'package:darkord/widgets/common_widgets.dart';
import 'package:darkord/consts/app_constants.dart';

class EmailVerificationPage extends StatefulWidget {
  final String userEmail;
  final String userName;
  final String sessionToken;
  final String resetToken;
  final bool isPasswordReset;

  const EmailVerificationPage({
    super.key,
    required this.userEmail,
    this.userName = '',
    required this.sessionToken,
    this.resetToken = '',
    this.isPasswordReset = false,
  });

  @override
  _EmailVerificationPageState createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final _logger = Logger();
  final _formKey = GlobalKey<FormState>();
  final _verificationCodeController = TextEditingController();
  final _apiService = ApiService();
  
  late Timer _timer;
  int _countdown = AppConstants.verificationCodeExpiry;
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer.cancel();
    _verificationCodeController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  String _formatCountdown(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _handleVerification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final otp = _verificationCodeController.text.trim();
      Map<String, dynamic> otpResult;

      if (widget.isPasswordReset) {
        otpResult = await _apiService.verifyPasswordResetOtp(widget.sessionToken, otp);
      } else {
        otpResult = await _apiService.verifyOtp(widget.sessionToken, otp);
      }

      if (otpResult['success'] == true) {
        setState(() => _successMessage = 'Email verified successfully!');
        await Future.delayed(const Duration(seconds: 2));

        if (!mounted) return;
        Navigator.pop(context, {
          'verified': true,
          'session_token': otpResult['session_token'],
          'message': 'Email verified successfully'
        });
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
      _logger.e('Verification error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleResendOtp() async {
    setState(() {
      _isResending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final result = await _apiService.resendOtp(widget.resetToken);

      if (result['success'] == true) {
        setState(() {
          _successMessage = 'New verification code sent to your email!';
          _countdown = AppConstants.verificationCodeExpiry;
          _verificationCodeController.clear();
        });
        _startCountdown();
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
      _logger.e('Resend OTP error: $e');
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
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
                  const SizedBox(height: 15),

                  // Instructions
                  Text(
                    widget.isPasswordReset
                        ? 'A verification code has been sent to your email for password reset. Please enter the code below.'
                        : 'A verification email has been sent to your email address. Please check your inbox and enter the verification code below.',
                    style: AppConstants.labelStyle.copyWith(fontSize: 16),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 10),

                  // Countdown Timer
                  Text(
                    'Code expires in: ${_formatCountdown(_countdown)}',
                    style: TextStyle(
                      color: _countdown < 60 ? Colors.red : AppConstants.warningColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Success Message
                  if (_successMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(color: AppConstants.successColor, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Error Message
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Email Field (Read-only)
                  CustomTextField(
                    initialValue: widget.userEmail,
                    labelText: 'Email Address',
                    hintText: 'Email Address',
                    prefixIcon: Icons.email,
                    readOnly: true,
                  ),
                  const SizedBox(height: 20),

                  // Verification Code Field
                  CustomTextField(
                    controller: _verificationCodeController,
                    labelText: 'Verification Code',
                    hintText: 'Enter 6-digit code',
                    prefixIcon: Icons.lock,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    validator: Validators.validateVerificationCode,
                  ),

                  // Back Button
                  LinkButton(
                    text: widget.isPasswordReset ? 'Back to Reset Password' : 'Back to Registration',
                    icon: Icons.arrow_back,
                    onPressed: () => Navigator.pop(context, {
                      'username': widget.userName,
                      'email': widget.userEmail,
                    }),
                  ),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_countdown > 0 || _isResending)
                        PrimaryButton(
                          text: 'Verify',
                          onPressed: _handleVerification,
                          isLoading: _isLoading,
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: _isResending ? null : _handleResendOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              child: _isResending
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    )
                                  : const Text('Resend Code'),
                            ),
                            const SizedBox(width: 20),
                            PrimaryButton(
                              text: 'Verify',
                              onPressed: _handleVerification,
                              isLoading: _isLoading,
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Help Text
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Check your spam folder if you don\'t see the email. The verification code will expire in 5 minutes.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
