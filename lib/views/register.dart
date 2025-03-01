import 'package:darkord/views/login.dart';
import 'package:darkord/views/email_verification.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  _RegisterFormState createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final logger = Logger();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController =
      TextEditingController(); // Add email controller
  bool _obscurePassword = true; // Track password visibility

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Registration')),
      body: Center(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.music_note,
                  size: 70,
                  color: Colors.white,
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
                      borderSide: BorderSide(
                          color: Colors.white), // Normal border color
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color:
                              Colors.blueAccent), // Border color when focused
                    ),
                    labelText: 'Username',
                    labelStyle: TextStyle(color: Colors.white),
                    hintText: 'Username',
                    hintStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.person, color: Colors.white),
                  ),
                  controller: _usernameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
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
                  controller: _emailController,
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
                  validator:
                      _validatePassword, // Use the new validation function
                ),
                const SizedBox(height: 8),
                Container(
                  alignment: Alignment.centerLeft, // Align text to left
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
                        decoration: TextDecoration.underline, // Underline text
                        decorationColor: Color.fromARGB(255, 236, 57, 45),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                SizedBox(
                  width: 200, // Set the button width
                  child: ElevatedButton(
                    // onPressed: () {
                    //   if (_formKey.currentState!.validate()) {
                    //     logger.i('Registration successful');
                    //     String email = _emailController.text;
                    //     String username = _usernameController.text;
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //           builder: (context) =>
                    //               EmailVerificationPage(userEmail: email, userName: username)),
                    //     );
                    //   }
                    // },
                    // child: Text('Sign up for an account'),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        logger.i('Registration successful');
                        String email = _emailController.text;
                        String username = _usernameController.text;

                        // Navigate to EmailVerificationPage and wait for result
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EmailVerificationPage(
                              userEmail: email,
                              userName: username,
                            ),
                          ),
                        );

                        // If result is not null, populate the fields
                        if (result != null) {
                          setState(() {
                            _usernameController.text = result['username'];
                            _emailController.text = result['email'];
                          });
                        }
                      }
                    },
                    child: Text('Sign up for an account'),
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
