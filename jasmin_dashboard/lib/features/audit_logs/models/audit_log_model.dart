class AuditLogModel {
  const AuditLogModel({required this.id, this.adminId, this.adminEmail, required this.action, this.targetType, this.targetId, this.details, this.ipAddress, this.userAgent, this.createdAt});
  final String id;
  final String? adminId;
  final String? adminEmail;
  final String action;
  final String? targetType;
  final String? targetId;
  final String? details;
  final String? ipAddress;
  final String? userAgent;
  final DateTime? createdAt;

  factory AuditLogModel.fromJson(Map<String, dynamic> json) => AuditLogModel(
        id: json['id']?.toString() ?? '',
        adminId: _nullable(json['adminId']),
        adminEmail: _nullable(json['adminEmail']),
        action: json['action']?.toString() ?? 'unknown',
        targetType: _nullable(json['targetType']),
        targetId: _nullable(json['targetId']),
        details: _nullable(json['details']),
        ipAddress: _nullable(json['ipAddress']),
        userAgent: _nullable(json['userAgent']),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      );
  static String? _nullable(dynamic value) { final text = value?.toString().trim() ?? ''; return text.isEmpty ? null : text; }
}
