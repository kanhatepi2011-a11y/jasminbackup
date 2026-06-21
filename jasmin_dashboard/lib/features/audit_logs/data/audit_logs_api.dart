import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_client.dart';
import '../models/audit_logs_response.dart';

final auditLogsApiProvider = Provider<AuditLogsApi>((ref) => AuditLogsApi(ref.watch(dioProvider)));

class AuditLogsApi {
  const AuditLogsApi(this._dio);
  final Dio _dio;

  Future<AuditLogsResponse> fetchLogs({required int page, int perPage = 50, String? action, String? targetType, String? adminEmail}) async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.auditLogs, queryParameters: <String, dynamic>{
      'page': page,
      'perPage': perPage,
      if (action != null && action.trim().isNotEmpty) 'action': action.trim(),
      if (targetType != null && targetType.trim().isNotEmpty && targetType != 'ALL') 'targetType': targetType.trim(),
      if (adminEmail != null && adminEmail.trim().isNotEmpty) 'adminEmail': adminEmail.trim(),
    });
    return AuditLogsResponse.fromJson(response.data ?? const <String, dynamic>{});
  }
}
