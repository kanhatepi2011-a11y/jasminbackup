import 'admin_user.dart';

class AuthSession {
  const AuthSession({
    required this.token,
    required this.expiresAt,
    required this.admin,
  });

  final String token;
  final DateTime expiresAt;
  final AdminUser admin;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: json['token']?.toString() ?? '',
      expiresAt: DateTime.parse(json['expiresAt']?.toString() ?? DateTime.now().toUtc().toIso8601String()),
      admin: AdminUser.fromJson((json['admin'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{}),
    );
  }
}
