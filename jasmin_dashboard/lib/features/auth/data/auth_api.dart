import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/errors/app_exception.dart';
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
      );
    }

    if (error.response?.statusCode == 429) {
      final retryAfter = data is Map ? data['retryAfter']?.toString() : null;
      final message = retryAfter == null || retryAfter.isEmpty
          ? 'Too many login attempts. Please try again later.'
          : 'Too many login attempts. Please try again in $retryAfter.';
      return AppException(message, statusCode: error.response?.statusCode);
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return AppException(
          'Connection timed out. Please check internet or API URL.');
    }

    if (error.type == DioExceptionType.connectionError) {
      return AppException(
          'Connection timed out. Please check internet or API URL.');
    }

    // Do not reveal whether email or password is wrong.
    return AppException('Invalid email or password',
        statusCode: error.response?.statusCode);
  }

  AppException _toAppException(DioException error, {required String fallback}) {
    String message = fallback;

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      message = 'Connection timed out. Please check internet or API URL.';
    }

    if (error.type == DioExceptionType.connectionError) {
      message = 'Connection timed out. Please check internet or API URL.';
    }

    if (error.response?.statusCode == 429) {
      message = 'Too many attempts. Please try again later.';
    }

    return AppException(message, statusCode: error.response?.statusCode);
  }
}
