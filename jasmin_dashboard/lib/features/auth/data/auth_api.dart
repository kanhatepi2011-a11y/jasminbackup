import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/api_error_mapper.dart';
import '../../../core/network/api_client.dart';
import '../models/admin_user.dart';
import '../models/auth_session.dart';
import '../models/login_challenge.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(dioProvider));
});

class AuthApi {
  const AuthApi(this._dio);

  final Dio _dio;

  Future<LoginChallenge> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiPaths.login,
        data: {'email': email.trim().toLowerCase(), 'password': password},
      );
      return LoginChallenge.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (error) {
      throw _toLoginException(error);
    }
  }

  Future<AuthSession> verifyTwoFactor({
    required String challengeId,
    required String code,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiPaths.twoFactor,
        data: {'challengeId': challengeId, 'code': code.trim()},
      );
      return AuthSession.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (error) {
      throw _toAppException(error,
          fallback: 'Invalid Google Authenticator code');
    }
  }

  Future<AdminUser> me() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(ApiPaths.me);
      final data = response.data ?? <String, dynamic>{};
      final admin = (data['admin'] as Map?)?.cast<String, dynamic>() ?? data;
      return AdminUser.fromJson(admin);
    } on DioException catch (error) {
      throw _toAppException(error,
          fallback: 'Session expired. Please login again.');
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post<void>(ApiPaths.logout);
    } on DioException {
      // Local logout still clears token even if network fails.
    }
  }

  AppException _toLoginException(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['needsSetup'] == true) {
      return AppException(
        'Google Authenticator is not configured for this admin.',
        statusCode: error.response?.statusCode,
        type: ApiErrorType.badRequest,
      );
    }

    // Network / timeout / SSL / server -> precise differentiated messages.
    if (error.type != DioExceptionType.badResponse) {
      return mapDioError(error, fallback: 'Invalid email or password');
    }

    final status = error.response?.statusCode;
    if (status == 429) {
      final retryAfter = data is Map ? data['retryAfter']?.toString() : null;
      final message = retryAfter == null || retryAfter.isEmpty
          ? 'Too many login attempts. Please try again later.'
          : 'Too many login attempts. Please try again in $retryAfter.';
      return AppException(message,
          statusCode: status, type: ApiErrorType.rateLimited);
    }

    // Do not reveal whether the email or the password was wrong.
    return AppException('Invalid email or password',
        statusCode: status, type: ApiErrorType.badRequest);
  }

  AppException _toAppException(DioException error, {required String fallback}) {
    return mapDioError(error, fallback: fallback);
  }
}
