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
    final payload = _payloadFrom(json);
    return AuthSession(
      token: _stringFrom(payload,
          const ['token', 'sessionToken', 'accessToken', 'access_token']),
      expiresAt: _dateFrom(payload, const [
        'expiresAt',
        'expires_at',
        'tokenExpiresAt',
        'token_expires_at'
      ]),
      admin: AdminUser.fromJson(_adminFrom(payload)),
    );
  }

  static Map<String, dynamic> _payloadFrom(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map) {
      final dataMap = data.cast<String, dynamic>();
      final nestedSession = dataMap['session'];
      if (nestedSession is Map) {
        return <String, dynamic>{
          ...dataMap,
          ...nestedSession.cast<String, dynamic>(),
        };
      }
      return dataMap;
    }

    final session = json['session'];
    if (session is Map) return session.cast<String, dynamic>();

    return json;
  }

  static String _stringFrom(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      if (value is num || value is bool) return value.toString();
    }
    return '';
  }

  static Map<String, dynamic> _adminFrom(Map<String, dynamic> json) {
    final admin = json['admin'];
    if (admin is Map) return admin.cast<String, dynamic>();

    final user = json['user'];
    if (user is Map) return user.cast<String, dynamic>();

    return <String, dynamic>{};
  }

  static DateTime _dateFrom(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final parsed = _parseDateOrDuration(json[key]);
      if (parsed != null) return parsed;
    }

    final expiresIn = json['expiresIn'] ?? json['expires_in'];
    final parsedExpiresIn = _parseDuration(expiresIn);
    if (parsedExpiresIn != null) return parsedExpiresIn;

    return DateTime.now().toUtc().add(const Duration(hours: 12));
  }

  static DateTime? _parseDateOrDuration(Object? value) {
    if (value == null) return null;
    if (value is num) return _parseNumber(value);

    final text = value.toString().trim();
    if (text.isEmpty) return null;

    final numeric = num.tryParse(text);
    if (numeric != null) return _parseNumber(numeric);

    return DateTime.tryParse(text)?.toUtc();
  }

  static DateTime? _parseDuration(Object? value) {
    if (value == null) return null;
    final seconds =
        value is num ? value.toInt() : int.tryParse(value.toString());
    if (seconds == null || seconds <= 0) return null;
    return DateTime.now().toUtc().add(Duration(seconds: seconds));
  }

  static DateTime? _parseNumber(num value) {
    final rounded = value.round();
    if (rounded <= 0) return null;

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
