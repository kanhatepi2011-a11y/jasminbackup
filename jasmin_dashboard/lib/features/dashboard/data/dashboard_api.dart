import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_client.dart';
import '../models/dashboard_data.dart';

final dashboardApiProvider = Provider<DashboardApi>((ref) {
  return DashboardApi(ref.watch(dioProvider));
});

class DashboardApi {
  const DashboardApi(this._dio);

  final Dio _dio;

  Future<DashboardData> fetchDashboard() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.dashboard);
    return DashboardData.fromJson(response.data ?? const <String, dynamic>{});
  }
}
