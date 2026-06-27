import 'audit_log_model.dart';

class AuditLogsResponse {
  const AuditLogsResponse(
      {required this.logs,
      required this.total,
      required this.page,
      required this.perPage,
      required this.totalPages});
  final List<AuditLogModel> logs;
  final int total;
  final int page;
  final int perPage;
  final int totalPages;

  factory AuditLogsResponse.fromJson(Map<String, dynamic> json) =>
      AuditLogsResponse(
        logs: (json['logs'] as List? ?? const <dynamic>[])
            .whereType<Map>()
            .map((item) =>
                AuditLogModel.fromJson(Map<String, dynamic>.from(item)))
            .toList(),
        total: _intFrom(json['total']),
        page: _intFrom(json['page']),
        perPage: _intFrom(json['perPage']),
        totalPages: _intFrom(json['totalPages']),
      );
  static int _intFrom(dynamic value) => value is int
      ? value
      : value is num
          ? value.toInt()
          : int.tryParse(value?.toString() ?? '') ?? 0;
}
