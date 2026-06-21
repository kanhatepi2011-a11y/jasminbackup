class PublicDataVersion {
  const PublicDataVersion({
    required this.scope,
    required this.version,
    required this.checkedAt,
  });

  final String scope;
  final String version;
  final DateTime checkedAt;

  factory PublicDataVersion.fromJson(Map<String, dynamic> json) {
    return PublicDataVersion(
      scope: json['scope']?.toString() ?? 'home',
      version: json['version']?.toString() ?? '',
      checkedAt: DateTime.tryParse(json['checkedAt']?.toString() ?? '')?.toUtc() ?? DateTime.now().toUtc(),
    );
  }
}
