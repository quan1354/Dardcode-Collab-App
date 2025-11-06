/// User model representing a user in the application
class User {
  final String userId;
  final String username;
  final String emailAddr;
  final String? avatarUrl;
  final String status;
  final String aboutMe;

  User({
    required this.userId,
    required this.username,
    required this.emailAddr,
    this.avatarUrl,
    required this.status,
    required this.aboutMe,
  });

  /// Create User from JSON response
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['identity']['user_id'] ?? '',
      username: json['identity']['username'] ?? '',
      emailAddr: json['identity']['email_addr'] ?? '',
      avatarUrl: json['identity']['avatar_url'],
      status: json['status']['status'] ?? '',
      aboutMe: json['status']['about_me'] ?? '',
    );
  }

  /// Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'identity': {
        'user_id': userId,
        'username': username,
        'email_addr': emailAddr,
        'avatar_url': avatarUrl,
      },
      'status': {
        'status': status,
        'about_me': aboutMe,
      },
    };
  }

  /// Create a copy of User with updated fields
  User copyWith({
    String? userId,
    String? username,
    String? emailAddr,
    String? avatarUrl,
    String? status,
    String? aboutMe,
  }) {
    return User(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      emailAddr: emailAddr ?? this.emailAddr,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
      aboutMe: aboutMe ?? this.aboutMe,
    );
  }

  @override
  String toString() {
    return 'User(userId: $userId, username: $username, email: $emailAddr, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}