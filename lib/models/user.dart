// models/user.dart
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
}