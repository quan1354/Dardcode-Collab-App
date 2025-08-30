import 'package:darkord/views/login.dart';
import 'package:darkord/views/email_verification.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:darkord/api/auth_api.dart'; // Import your API service

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  _RegisterFormState createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final logger = Logger();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthApi _authApi = AuthApi();
  bool _isLoading = false;
  bool _obscurePassword = true;

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

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final String username = _usernameController.text;
        final String email = _emailController.text;
        final String password = _passwordController.text;

        // Call the sign-up API
        final result = await _authApi.signUpUser(username, email, password);

        if (result['success'] == true) {
          logger.i('Sign up initiated successfully');

          // Navigate to email verification with the necessary data
          final verificationResult = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EmailVerificationPage(
                userEmail: email,
                userName: username,
                sessionToken: result['session_token'],
                resetToken: result['reset_token'],
              ),
            ),
          );

          logger.i('Verification result: $verificationResult');

          if (verificationResult != null &&
              verificationResult['verified'] == true) {
            // Registration completed successfully
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Registration completed successfully!')));
            Navigator.pop(context); // Go back to login or wherever appropriate
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sign up failed: ${e.toString()}')));
        logger.e('Sign up error: $e');
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
                  // Your existing UI components...
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.yellow, width: 5.0),
                    ),
                    child: Image.asset('assets/logo2.png',
                        width: 200, height: 190),
                  ),
                  Text(
                    'Darkord',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Username field
                  TextFormField(
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white)),
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white)),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueAccent)),
                      labelText: 'Username',
                      labelStyle: TextStyle(color: Colors.white),
                      hintText: 'Username',
                      hintStyle: TextStyle(color: Colors.white70),
                      prefixIcon: Icon(Icons.person, color: Colors.white),
                    ),
                    controller: _usernameController,
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Please enter your username'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Email field
                  TextFormField(
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white)),
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white)),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueAccent)),
                      labelText: 'Email Address',
                      labelStyle: TextStyle(color: Colors.white),
                      hintText: 'Email Address',
                      hintStyle: TextStyle(color: Colors.white70),
                      prefixIcon: Icon(Icons.email, color: Colors.white),
                    ),
                    controller: _emailController,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Please enter your email';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password field
                  TextFormField(
                    obscureText: _obscurePassword,
                    controller: _passwordController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white)),
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white)),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueAccent)),
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
                            color: Colors.white),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 8),

                  // Back to login
                  Container(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (context) => LoginForm())),
                      child: Text(
                        'Back to Login',
                        style: TextStyle(
                            color: Color.fromARGB(255, 236, 57, 45),
                            decoration: TextDecoration.underline),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Sign up button
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignUp,
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Sign up for an account'),
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
