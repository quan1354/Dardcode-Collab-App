import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:darkord/api/auth_api.dart';

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
  final logger = Logger();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _verificationCodeController =
      TextEditingController();
  final AuthApi _authApi = AuthApi();
  int _countdown = 300;
  late Timer _timer;
  bool _isLoading = false;
  bool _isResending = false;
  bool _showOtpField = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    startCountdown();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
        setState(() => _showOtpField = false);
      }
    });
  }

  String formatCountdown(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _handleVerification() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _successMessage = null;
      });

      try {
        final String otp = _verificationCodeController.text;

        Map<String, dynamic> otpResult;

        if (widget.isPasswordReset) {
          // Use password reset OTP verification
          otpResult =
              await _authApi.verifyPasswordResetOtp(widget.sessionToken, otp);
        } else {
          // Use regular OTP verification
          otpResult = await _authApi.verifyOtp(widget.sessionToken, otp);
        }

        if (otpResult['success'] == true) {
          setState(() => _successMessage = 'Email verified successfully!');

          await Future.delayed(const Duration(seconds: 2));

          Navigator.pop(context, {
            'verified': true,
            'session_token': otpResult['session_token'],
            'message': 'Email verified successfully'
          });
        }
      } catch (e) {
        setState(() => _errorMessage = e.toString());
        logger.e('Verification error: $e');
      } finally {
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
      final String tokenToUse = widget.resetToken;

      final result = await _authApi.resendOtp(tokenToUse);

      if (result['success'] == true) {
        setState(() {
          _successMessage = 'New verification code sent to your email!';
          _countdown = 300;
          _showOtpField = true;
          _verificationCodeController.clear();
        });
        startCountdown();
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
      logger.e('Resend OTP error: $e');
    } finally {
      setState(() => _isResending = false);
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
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.yellow, width: 5.0),
                    ),
                    child: Image.asset('assets/logo2.png',
                        width: 200, height: 190),
                  ),
                  const Text(
                    'Darkord',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  Text(
                    widget.isPasswordReset
                        ? 'A verification code has been sent to your email for password reset. Please enter the code below.'
                        : 'A verification email has been sent to your email address. Please check your inbox and enter the verification code below.',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.justify,
                  ),

                  const SizedBox(height: 10),
                  Text(
                    'Code expires in: ${formatCountdown(_countdown)}',
                    style: TextStyle(
                        color: _countdown < 60 ? Colors.red : Colors.yellow,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),

                  if (_successMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        _successMessage!,
                        style: TextStyle(color: Colors.green, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 20),

                  TextFormField(
                    initialValue: widget.userEmail,
                    readOnly: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white)),
                      enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white)),
                      focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueAccent)),
                      labelText: 'Email Address',
                      labelStyle: const TextStyle(color: Colors.white),
                      hintText: 'Email Address',
                      hintStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.email, color: Colors.white),
                    ),
                  ),

                  // if (_showOtpField) ...[
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _verificationCodeController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white)),
                      enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white)),
                      focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueAccent)),
                      labelText: 'Verification Code',
                      labelStyle: const TextStyle(color: Colors.white),
                      hintText: 'Enter 6-digit code',
                      hintStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.lock, color: Colors.white),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Please enter the verification code';
                      if (value.length != 6)
                        return 'Verification code must be 6 digits';
                      return null;
                    },
                  ),
                  // ] else ...[
                  //   const SizedBox(height: 20),
                  //   const Text(
                  //     'Verification code expired. Please request a new one.',
                  //     style: TextStyle(color: Colors.yellow, fontSize: 14),
                  //     textAlign: TextAlign.center,
                  //   ),
                  // ],

                  TextButton(
                    onPressed: () => Navigator.pop(context, {
                      'username': widget.userName,
                      'email': widget.userEmail,
                    }),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Icon(Icons.arrow_back,
                            color: Color.fromARGB(255, 236, 57, 45)),
                        const SizedBox(width: 5),
                        Text(
                          widget.isPasswordReset
                              ? 'Back to Reset Password'
                              : 'Back to Registration',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 236, 57, 45),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_countdown > 0 || _isResending)
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleVerification,
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2)
                              : const Text('Verify'),
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
                                      color: Colors.white, strokeWidth: 2)
                                  : const Text('Resend Code'),
                            ),
                            const SizedBox(width: 20),
                            ElevatedButton(
                              onPressed:
                                  _isLoading ? null : _handleVerification,
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2)
                                  : const Text('Verify'),
                            ),
                          ],
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

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
