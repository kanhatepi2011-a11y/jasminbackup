class SystemStatus {
  const SystemStatus({
    required this.database,
    required this.api,
    required this.auth,
  });

  final String database;
  final String api;
  final String auth;

  factory SystemStatus.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const SystemStatus(
          database: 'unknown', api: 'unknown', auth: 'unknown');
    }
    return SystemStatus(
      database: (json['database'] ?? 'unknown').toString(),
      api: (json['api'] ?? 'unknown').toString(),
      auth: (json['auth'] ?? 'unknown').toString(),
    );
  }
}
