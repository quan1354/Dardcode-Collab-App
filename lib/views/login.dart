import 'package:darkord/views/register.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final logger = Logger();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true; // Track password visibility
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
                        logger.i('Login successful');
                      }
                    },
                    child: Text('Login'),
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
