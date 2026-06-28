import 'dart:io';

import 'package:dio/dio.dart';

import 'app_exception.dart';

/// Converts a [DioException] into a user-facing [AppException] with a specific
/// [ApiErrorType], so the UI can show distinct messages for no-internet,
/// timeout, SSL, server, and maintenance cases instead of one generic error.
AppException mapDioError(DioException error, {String? fallback}) {
  final status = error.response?.statusCode;
  final serverMessage = _serverMessage(error);

  // Timeouts
  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.receiveTimeout) {
    return const AppException(
      'The server took too long to respond. Please try again.',
      type: ApiErrorType.timeout,
    );
  }

  // SSL / certificate problems
  if (error.type == DioExceptionType.badCertificate ||
      error.error is HandshakeException ||
      error.error is TlsException) {
    return const AppException(
      'Secure connection (SSL) failed. Please update the app or check your network.',
      type: ApiErrorType.ssl,
    );
  }

  // Connection errors -> usually no internet / DNS / host unreachable
  if (error.type == DioExceptionType.connectionError ||
      error.error is SocketException) {
    return const AppException(
      'No internet connection. Check your network and try again.',
      type: ApiErrorType.noInternet,
    );
  }

  // Responses that carry a status code
  if (status != null) {
    if (status == 401) {
      return AppException(
        serverMessage ?? 'Session expired. Please login again.',
        statusCode: status,
        type: ApiErrorType.unauthorized,
      );
    }
    if (status == 429) {
      return AppException(
        serverMessage ?? 'Too many requests. Please try again later.',
        statusCode: status,
        type: ApiErrorType.rateLimited,
      );
    }
    if (status == 503) {
      return AppException(
        serverMessage ??
            'The service is under maintenance. Please try again soon.',
        statusCode: status,
        type: ApiErrorType.maintenance,
      );
    }
    if (status >= 500) {
      return AppException(
        'Server error. Please try again in a few minutes.',
        statusCode: status,
        type: ApiErrorType.server,
      );
    }
    if (status >= 400) {
      return AppException(
        serverMessage ?? fallback ?? 'Request could not be completed.',
        statusCode: status,
        type: ApiErrorType.badRequest,
      );
    }
  }

  return AppException(
    serverMessage ?? fallback ?? 'Something went wrong. Please try again.',
    statusCode: status,
    type: ApiErrorType.unknown,
  );
}

String? _serverMessage(DioException error) {
  final data = error.response?.data;
  if (data is Map && data['error'] != null) {
    final msg = data['error'].toString().trim();
    if (msg.isNotEmpty) return msg;
  }
  return null;
}
