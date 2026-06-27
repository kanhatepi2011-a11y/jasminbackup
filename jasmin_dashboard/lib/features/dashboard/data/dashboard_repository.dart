import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../models/dashboard_data.dart';
import 'dashboard_api.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(dashboardApiProvider));
});

class DashboardRepository {
  const DashboardRepository(this._api);

  final DashboardApi _api;

  Future<DashboardData> fetchDashboard() async {
    try {
      return await _api.fetchDashboard();
    } on DioException catch (error) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['error'] ?? data['message'];
        if (message != null) {
          throw AppException(message.toString());
        }
      }
      throw const AppException(
          'Could not load dashboard. Check your connection and try again.');
    }
  }
}
