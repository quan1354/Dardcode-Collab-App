import 'package:darkord/views/login.dart';
import 'package:darkord/views/email_verification.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

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
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isEmailVerified = false; // Track if email is verified

  // Function to validate password
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

  // Function to validate confirm password
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
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
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                    labelText: 'Email Address',
                    labelStyle: TextStyle(color: Colors.white),
                    hintText: 'Email Address',
                    hintStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.email, color: Colors.white),
                  ),
                  controller: _emailController,
                  readOnly:
                      _isEmailVerified, // Make field read-only only after verification
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
                if (_isEmailVerified) // Show password fields only if email is verified

                  Column(
                    children: [
                      const SizedBox(height: 20),
                      TextFormField(
                        obscureText: _obscurePassword,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.blueAccent),
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
                                _obscurePassword = !_obscurePassword;
                              });
                            },
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
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.blueAccent),
                          ),
                          labelText: 'Confirm Password',
                          labelStyle: TextStyle(color: Colors.white),
                          hintText: 'Confirm Password',
                          hintStyle: TextStyle(color: Colors.white70),
                          prefixIcon: Icon(Icons.lock, color: Colors.white),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        controller: _confirmPasswordController,
                        validator: _validateConfirmPassword,
                      ),
                      // TextFormField(
                      //   obscureText: _obscurePassword,
                      //   style: TextStyle(color: Colors.white),
                      //   decoration: InputDecoration(
                      //     border: OutlineInputBorder(
                      //       borderSide: BorderSide(color: Colors.white),
                      //     ),
                      //     enabledBorder: OutlineInputBorder(
                      //       borderSide: BorderSide(color: Colors.white),
                      //     ),
                      //     focusedBorder: OutlineInputBorder(
                      //       borderSide: BorderSide(color: Colors.blueAccent),
                      //     ),
                      //     labelText: 'Confirm Password',
                      //     labelStyle: TextStyle(color: Colors.white),
                      //     hintText: 'Confirm Password',
                      //     hintStyle: TextStyle(color: Colors.white70),
                      //     prefixIcon: Icon(Icons.lock, color: Colors.white),
                      //   ),
                      //   controller: _confirmPasswordController,
                      //   validator: _validateConfirmPassword,
                      // ),
                    ],
                  ),
                const SizedBox(height: 8),
                Container(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginForm()),
                      );
                    },
                    child: Text(
                      'Back to Login',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 236, 57, 45),
                        decoration: TextDecoration.underline,
                        decorationColor: Color.fromARGB(255, 236, 57, 45),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        if (!_isEmailVerified) {
                          // Navigate to EmailVerificationPage
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EmailVerificationPage(
                                userEmail: _emailController.text,
                              ),
                            ),
                          );

                          // If verification is successful, show password fields
                          if (result != null && result['verified'] == true) {
                            setState(() {
                              _isEmailVerified = true;
                            });
                          }
                        } else {
                          // Handle password reset logic
                          logger.i('Password reset successful');
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginForm()),
                          );
                        }
                      }
                    },
                    child: Text(
                        _isEmailVerified ? 'Reset Password' : 'Verify Email'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
