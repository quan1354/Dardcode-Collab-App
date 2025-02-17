import 'dart:async'; // Add this import for Timer
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class EmailVerificationPage extends StatefulWidget {
  final String userEmail;

  const EmailVerificationPage({super.key, required this.userEmail});

  @override
  _EmailVerificationPageState createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final logger = Logger();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _verificationCodeController = TextEditingController();
  int _countdown = 300;
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
                const Icon(Icons.music_note, size: 70, color: Colors.white),
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
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _countdown > 0 ? null : () {
                        setState(() => _countdown = 300);
                        startCountdown();
                        logger.i('Resend verification email');
                      },
                      child: Text(_countdown > 0 
                          ? 'Resend Email (${formatCountdown(_countdown)})' 
                          : 'Resend Email'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          logger.i('Verification code submitted');
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