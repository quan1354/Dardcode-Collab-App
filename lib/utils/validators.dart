/// Validation utilities for form fields
class Validators {
  /// Validates email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Validates password strength
  /// Requires at least 8 characters and 2 of: letter, number, symbol
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    int count = 0;
    if (RegExp(r'[A-Za-z]').hasMatch(value)) count++; // Letters
    if (RegExp(r'[0-9]').hasMatch(value)) count++; // Numbers
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) count++; // Symbols

    if (count < 2) {
      return 'Password must include at least two of: letter, number, or symbol';
    }

    return null;
  }

  /// Validates password confirmation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validates username
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your username';
    }
    return null;
  }

  /// Validates verification code (6 digits)
  static String? validateVerificationCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the verification code';
    }
    if (value.length != 6) {
      return 'Verification code must be 6 digits';
    }
    return null;
  }
}