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
    final payload = _payloadFrom(json);
    final challengeId = _stringFrom(payload, const [
      'challengeId',
      'challenge_id',
      'twoFactorChallengeId',
      'two_factor_challenge_id',
      'id',
    ]);

    return LoginChallenge(
      challengeId: challengeId,
      expiresAt: _dateFrom(payload, const [
        'expiresAt',
        'expires_at',
        'challengeExpiresAt',
        'challenge_expires_at',
      ]),
      requires2FA: _boolFrom(payload, const [
            'requires2FA',
            'requires2fa',
            'requiresTwoFactor',
            'twoFactorRequired',
          ]) ??
          challengeId.isNotEmpty,
    );
  }

  static Map<String, dynamic> _payloadFrom(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map) {
      final dataMap = data.cast<String, dynamic>();
      final nestedChallenge = dataMap['challenge'];
      if (nestedChallenge is Map) {
        return <String, dynamic>{
          ...dataMap,
          ...nestedChallenge.cast<String, dynamic>(),
        };
      }
      return dataMap;
    }

    final challenge = json['challenge'];
    if (challenge is Map) {
      return challenge.cast<String, dynamic>();
    }

    return json;
  }

  static String _stringFrom(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
      if (value is num || value is bool) {
        return value.toString();
      }
    }
    return '';
  }

  static bool? _boolFrom(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is bool) {
        return value;
      }
      if (value is String) {
        final normalized = value.toLowerCase().trim();
        if (normalized == 'true') {
          return true;
        }
        if (normalized == 'false') {
          return false;
        }
      }
    }
    return null;
  }

  static DateTime _dateFrom(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final parsed = _parseDateOrDuration(json[key]);
      if (parsed != null) {
        return parsed;
      }
    }

    final expiresIn = json['expiresIn'] ?? json['expires_in'];
    final parsedExpiresIn = _parseDuration(expiresIn);
    if (parsedExpiresIn != null) {
      return parsedExpiresIn;
    }

    return DateTime.now().toUtc().add(const Duration(minutes: 5));
  }

  static DateTime? _parseDateOrDuration(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return _parseNumber(value);
    }

    final text = value.toString().trim();
    if (text.isEmpty) {
      return null;
    }

    final numeric = num.tryParse(text);
    if (numeric != null) {
      return _parseNumber(numeric);
    }

    return DateTime.tryParse(text)?.toUtc();
  }

  static DateTime? _parseDuration(Object? value) {
    if (value == null) {
      return null;
    }
    final seconds =
        value is num ? value.toInt() : int.tryParse(value.toString());
    if (seconds == null || seconds <= 0) {
      return null;
    }
    return DateTime.now().toUtc().add(Duration(seconds: seconds));
  }

  static DateTime? _parseNumber(num value) {
    final rounded = value.round();
    if (rounded <= 0) {
      return null;
    }

    if (rounded < 86400) {
      return DateTime.now().toUtc().add(Duration(seconds: rounded));
    }

    if (rounded > 1000000000000) {
      return DateTime.fromMillisecondsSinceEpoch(rounded, isUtc: true);
    }

    if (rounded > 1000000000) {
      return DateTime.fromMillisecondsSinceEpoch(rounded * 1000, isUtc: true);
    }

    return null;
  }
}
