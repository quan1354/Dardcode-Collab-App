import 'package:darkord/views/login.dart';
import 'package:darkord/views/email_verification.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../api/auth_api.dart'; // Import your API service

class ResetPasswordForm extends StatefulWidget {
  const ResetPasswordForm({super.key});

  @override
  _ResetPasswordFormState createState() => _ResetPasswordFormState();
}

class _ResetPasswordFormState extends State<ResetPasswordForm> {
  final logger = Logger();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final AuthApi _authApi = AuthApi();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isEmailVerified = false;
  bool _isLoading = false;
  String? _sessionToken; // Store session token for password reset

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    int count = 0;
    if (RegExp(r'[A-Za-z]').hasMatch(value)) count++;
    if (RegExp(r'[0-9]').hasMatch(value)) count++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) count++;

    if (count < 2) {
      return 'Password must include at least two of: letter, number, or symbol';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _handleEmailVerification() async {
    if (_formKey.currentState!.validate() && _emailController.text.isNotEmpty) {
      setState(() => _isLoading = true);
      
      try {
        final String email = _emailController.text;
        
        // Initiate password reset
        final result = await _authApi.initiatePasswordReset(email);
        
        if (result['success'] == true) {
          // Navigate to EmailVerificationPage for OTP verification
          final verificationResult = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EmailVerificationPage(
                userEmail: email,
                sessionToken: result['session_token'],
                isPasswordReset: true, // Add this flag
                resetToken: result['reset_token'], // Pass reset token
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'))
        );
        logger.e('Email verification error: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handlePasswordReset() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final String password = _passwordController.text;
        
        // Complete password reset
        final result = await _authApi.resetPassword(_emailController.text, password);
        
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Password reset successfully!'))
          );
          
          // Navigate back to login
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginForm()),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset failed: ${e.toString()}'))
        );
        logger.e('Password reset error: $e');
      } finally {
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
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.yellow, width: 5.0),
                    ),
                    child: Image.asset('assets/logo2.png', width: 200, height: 190),
                  ),
                  Text(
                    'Darkord',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  
                  TextFormField(
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                      labelText: 'Email Address', labelStyle: TextStyle(color: Colors.white),
                      hintText: 'Email Address', hintStyle: TextStyle(color: Colors.white70),
                      prefixIcon: Icon(Icons.email, color: Colors.white),
                    ),
                    controller: _emailController,
                    readOnly: _isEmailVerified,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter your email';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  
                  if (_isEmailVerified) 
                    Column(
                      children: [
                        const SizedBox(height: 20),
                        TextFormField(
                          obscureText: _obscurePassword,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                            labelText: 'New Password', labelStyle: TextStyle(color: Colors.white),
                            hintText: 'New Password', hintStyle: TextStyle(color: Colors.white70),
                            prefixIcon: Icon(Icons.lock, color: Colors.white),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.white),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          controller: _passwordController,
                          validator: _validatePassword,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          obscureText: _obscureConfirmPassword,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                            labelText: 'Confirm Password', labelStyle: TextStyle(color: Colors.white),
                            hintText: 'Confirm Password', hintStyle: TextStyle(color: Colors.white70),
                            prefixIcon: Icon(Icons.lock, color: Colors.white),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off, color: Colors.white),
                              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                          ),
                          controller: _confirmPasswordController,
                          validator: _validateConfirmPassword,
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 8),
                  Container(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoginForm())),
                      child: Text(
                        'Back to Login',
                        style: TextStyle(color: Color.fromARGB(255, 236, 57, 45), decoration: TextDecoration.underline),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : (_isEmailVerified ? _handlePasswordReset : _handleEmailVerification),
                      child: _isLoading 
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(_isEmailVerified ? 'Reset Password' : 'Verify Email'),
                    ),
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