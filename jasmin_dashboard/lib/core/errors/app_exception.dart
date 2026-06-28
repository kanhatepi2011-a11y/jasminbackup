/// High-level classification of an API/network failure so the UI can show a
/// precise message instead of one generic "server error".
enum ApiErrorType {
  noInternet,
  timeout,
  ssl,
  server,
  maintenance,
  unauthorized,
  rateLimited,
  badRequest,
  unknown,
}

class AppException implements Exception {
  const AppException(
    this.message, {
    this.statusCode,
    this.type = ApiErrorType.unknown,
  });

  final String message;
  final int? statusCode;
  final ApiErrorType type;

  @override
  String toString() => 'AppException($statusCode, $type): $message';
}
