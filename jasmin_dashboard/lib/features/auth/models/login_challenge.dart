class LoginChallenge {
  const LoginChallenge({
    required this.challengeId,
    required this.expiresAt,
    required this.requires2FA,
  });

  final String challengeId;
  final DateTime expiresAt;
  final bool requires2FA;

  factory LoginChallenge.fromJson(Map<String, dynamic> json) {
    return LoginChallenge(
      challengeId: json['challengeId']?.toString() ?? '',
      expiresAt: DateTime.parse(json['expiresAt']?.toString() ?? DateTime.now().toUtc().toIso8601String()),
      requires2FA: json['requires2FA'] == true,
    );
  }
}
