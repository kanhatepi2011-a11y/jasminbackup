import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../models/audit_logs_response.dart';
import 'audit_logs_api.dart';

final auditLogsRepositoryProvider = Provider<AuditLogsRepository>((ref) => AuditLogsRepository(ref.watch(auditLogsApiProvider)));

class AuditLogsRepository {
  const AuditLogsRepository(this._api);
  final AuditLogsApi _api;
  Future<AuditLogsResponse> fetchLogs({required int page, int perPage = 50, String? action, String? targetType, String? adminEmail}) async {
    try { return await _api.fetchLogs(page: page, perPage: perPage, action: action, targetType: targetType, adminEmail: adminEmail); }
    on DioException catch (e) { throw _exception(e, 'Could not load audit logs.'); }
  }
  AppException _exception(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map && data['error'] != null) return AppException(data['error'].toString(), statusCode: error.response?.statusCode);
    return AppException(fallback, statusCode: error.response?.statusCode);
  }
}
