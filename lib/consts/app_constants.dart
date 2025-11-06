import 'package:flutter/material.dart';

/// Application-wide constants
class AppConstants {
  // App Info
  static const String appName = 'Darkord';
  
  // Asset Paths
  static const String logoPath = 'assets/logo2.png';
  static const double logoWidth = 200.0;
  static const double logoHeight = 190.0;
  
  // UI Dimensions
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double buttonHeight = 50.0;
  static const double buttonWidth = 200.0;
  
  // Colors
  static const Color primaryColor = Colors.blue;
  static const Color errorColor = Color.fromARGB(255, 236, 57, 45);
  static const Color successColor = Colors.green;
  static const Color warningColor = Colors.yellow;
  static const Color whiteColor = Colors.white;
  static const Color greyColor = Colors.grey;
  static const Color mainBGColor = Color.fromARGB(255, 15, 8, 84);
  
  // Border Colors
  static const Color borderColorNormal = Colors.white;
  static const Color borderColorFocused = Colors.blueAccent;
  static const Color borderColorYellow = Colors.yellow;
  
  // Text Styles
  static const TextStyle appTitleStyle = TextStyle(
    color: Colors.white,
    fontSize: 28,
    fontWeight: FontWeight.bold,
  );
  
  static const TextStyle labelStyle = TextStyle(
    color: Colors.white,
  );
  
  static const TextStyle hintStyle = TextStyle(
    color: Colors.white70,
  );
  
  static const TextStyle linkStyle = TextStyle(
    color: errorColor,
    decoration: TextDecoration.underline,
    decorationColor: errorColor,
  );
  
  // Timing
  static const int verificationCodeExpiry = 300; // 5 minutes in seconds
  static const int typingDebounceMilliseconds = 1000;
  
  // Status
  static const String statusOnline = 'online';
  static const String statusOffline = 'offline';
}