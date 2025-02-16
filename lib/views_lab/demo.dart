import 'package:flutter/material.dart';

class Experiment extends StatelessWidget {
  const Experiment({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900], // Dark theme
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Welcome to Second View!',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Go back to Entry page
              },
              child: Text('Back to Entry'),
            ),
          ],
        ),
      ),
    );
  }
}