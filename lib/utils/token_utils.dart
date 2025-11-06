import 'dart:convert';

/// Utility class for JWT token operations
class TokenUtils {
  /// Extract user ID from JWT access token
  static String? getUserIdFromToken(String? accessToken) {
    if (accessToken == null) return null;

    try {
      final parts = accessToken.split('.');
      if (parts.length != 3) return null;

      final payloadBase64 = parts[1];
      String paddedPayload = payloadBase64;
      
      // Add padding if needed
      while (paddedPayload.length % 4 != 0) {
        paddedPayload += '=';
      }

      final decodedJson = utf8.decode(base64Url.decode(paddedPayload));
      final tokenData = json.decode(decodedJson) as Map<String, dynamic>;

      return tokenData['sub']?.toString();
    } catch (e) {
      print('Error decoding token: $e');
      return null;
    }
  }

  /// Decode JWT token payload
  static Map<String, dynamic>? decodeToken(String? token) {
    if (token == null) return null;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payloadBase64 = parts[1];
      String paddedPayload = payloadBase64;
      
      // Add padding if needed
      while (paddedPayload.length % 4 != 0) {
        paddedPayload += '=';
      }

      final decodedJson = utf8.decode(base64Url.decode(paddedPayload));
      return json.decode(decodedJson) as Map<String, dynamic>;
    } catch (e) {
      print('Error decoding token: $e');
      return null;
    }
  }
}