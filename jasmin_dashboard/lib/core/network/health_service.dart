import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_paths.dart';
import '../errors/api_error_mapper.dart';
import '../errors/app_exception.dart';
import 'api_client.dart';

final healthServiceProvider = Provider<HealthService>((ref) {
  return HealthService(ref.watch(dioProvider));
});

/// Calls the public GET /api/health endpoint at startup so the app can show a
/// precise connectivity error before the user reaches the login screen.
/// Throws an [AppException] (with a specific [ApiErrorType]) on failure.
final startupHealthProvider = FutureProvider<bool>((ref) async {
  return ref.watch(healthServiceProvider).check();
});

class HealthService {
  const HealthService(this._dio);

  final Dio _dio;

  Future<bool> check() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(ApiPaths.health);
      final ok = res.data?['ok'] == true;
      if (!ok) {
        throw const AppException(
          'Backend is reachable but not healthy. Please try again soon.',
          type: ApiErrorType.server,
        );
      }
      return true;
    } on DioException catch (error) {
      throw mapDioError(error, fallback: 'Cannot reach the server.');
    }
  }
}
