/// Authentication response model
class AuthResponse {
  final int code;
  final String message;
  final Map<String, dynamic>? payload;
  final String? requestId;

  AuthResponse({
    required this.code,
    required this.message,
    this.payload,
    this.requestId,
  });

  /// Create AuthResponse from JSON
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      code: json['code'] as int,
      message: json['message'] as String,
      payload: json['payload'] as Map<String, dynamic>?,
      requestId: json['request_id'] as String?,
    );
  }

  /// Convert AuthResponse to JSON
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
      'payload': payload,
      'request_id': requestId,
    };
  }

  /// Check if response is successful (code 200)
  bool get isSuccess => code == 200;

  /// Check if response has payload
  bool get hasPayload => payload != null && payload!.isNotEmpty;

  /// Get access token from payload
  String? get accessToken => payload?['access_token'] as String?;

  /// Get refresh token from payload
  String? get refreshToken => payload?['refresh_token'] as String?;

  /// Get session token from payload
  String? get sessionToken => payload?['session_token'] as String?;

  @override
  String toString() {
    return 'AuthResponse(code: $code, message: $message, hasPayload: $hasPayload)';
  }
}