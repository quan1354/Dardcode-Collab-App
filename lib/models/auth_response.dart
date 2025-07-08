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

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      code: json['code'],
      message: json['message'],
      payload: json['payload'],
      requestId: json['request_id'],
    );
  }
}