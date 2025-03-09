import 'dart:async'; // Add this import for Timer
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class EmailVerificationPage extends StatefulWidget {
  final String userEmail;
  final String userName;

  const EmailVerificationPage(
      {super.key, required this.userEmail, this.userName=''});

  @override
  _EmailVerificationPageState createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final logger = Logger();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _verificationCodeController =
      TextEditingController();
  int _countdown = 60;
  late Timer _timer;

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
      }
    });
  }

  String formatCountdown(int seconds) {
    return '${(seconds ~/ 60)}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Email Verification')),
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
                const Text(
                  'Darkord',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'A verification email has been sent to your email. Please check the verification code and enter here',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 30),
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
                    hintText: 'Enter verification code',
                    hintStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.lock, color: Colors.white),
                  ),
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Please enter the verification code'
                      : null,
                ),
                // const SizedBox(height: 20),
                // Text(
                //   'Time remaining: ${formatCountdown(_countdown)}',
                //   style: const TextStyle(color: Colors.white, fontSize: 16),
                // ),
                TextButton(
                  onPressed: () {
                    // Navigate back to the RegisterForm and pass the username and email
                    Navigator.pop(context, {
                      'username': widget.userName,
                      'email': widget.userEmail,
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.arrow_back, // Add a back icon
                        color: Color.fromARGB(255, 236, 57, 45),
                      ),
                      const SizedBox(
                          width: 5), // Add spacing between icon and text
                      Text(
                        'Back',
                        style: TextStyle(
                          color: const Color.fromARGB(255, 236, 57, 45),
                          decoration: TextDecoration.underline,
                          decorationColor: Color.fromARGB(255, 236, 57, 45),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _countdown > 0
                          ? () {} // Disable the button if countdown is active
                          : () {
                              setState(
                                  () => _countdown = 60); // Reset countdown
                              startCountdown(); // Restart the timer
                              logger.i('Resend verification email');
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _countdown > 0
                            ? Colors.grey
                            : Colors.blue, // Change color when disabled
                        foregroundColor: Colors.white, // Text color
                      ),
                      child: Text(
                        _countdown > 0
                            ? 'Resend Email (${formatCountdown(_countdown)})'
                            : 'Resend Email',
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          logger.i('Verification code submitted');
                          Navigator.pop(context, {'verified': true});
                        }
                      },
                      child: const Text('Submit'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
