import 'package:darkord/views/register.dart';
import 'package:darkord/views/reset_password.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:darkord/api/auth_api.dart';
import 'package:darkord/utils/dialog_utils.dart';

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
    
    try {
      // Show loading dialog
      DialogUtils.showLoading(context, 'Logging in...');
      
      final response = await _authApi.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Handle successful login
      DialogUtils.showSuccess(context, 'Login successful!');
      
      // TODO: Navigate to home screen or store tokens
      print('Login payload: ${response.payload}');
      
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.pop(context);
      
      // Show error dialog
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
      // appBar: AppBar(
      //   title: const Text(
      //     'Login',
      //     style: TextStyle(color: Colors.white), // Set text color to black
      //   ),
      //   backgroundColor: const Color.fromARGB(255, 54, 22, 181), // Set background color to white
      //   iconTheme: const IconThemeData(
      //       color: Colors.white), // Set back icon color to black
      //   elevation: 0, // Optional: Remove shadow for a flat look
      // ),
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
                  // validator: (value) {
                  //   if (value == null || value.isEmpty) {
                  //     return 'Please enter your password';
                  //   }
                  //   return null;
                  // },
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
                // Container(
                //   alignment: Alignment.centerLeft, // Align text to left
                //   child: TextButton(
                //     onPressed: () {
                //       Navigator.push(
                //         context,
                //         MaterialPageRoute(builder: (context) => RegisterForm()),
                //       );
                //     },
                //     child: Text(
                //       'don\'t have account ?',
                //       style: TextStyle(
                //         color: const Color.fromARGB(255, 236, 57, 45),
                //         decoration: TextDecoration.underline, // Underline text
                //         decorationColor: Color.fromARGB(255, 236, 57, 45),
                //       ),
                //     ),
                //   ),
                // ),
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
                // ElevatedButton(
                //   onPressed: () {
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(builder: (context) => MyCustomForm()),
                //     );
                //   },
                //   child: Text('Go to Second View'),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
