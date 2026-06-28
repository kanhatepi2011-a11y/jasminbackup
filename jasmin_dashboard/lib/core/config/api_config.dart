import 'package:flutter/foundation.dart';

/// Centralized API configuration for the JASMIN admin dashboard.
///
/// The Flutter app talks ONLY to the public backend API. No admin secrets,
/// API keys, or tokens are stored here — the session token is obtained at
/// runtime after login and kept in secure storage.
class ApiConfig {
  const ApiConfig._();

  /// Production backend. Override locally with:
  ///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
  /// Release builds always default to the HTTPS production URL below.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://jasminbackup.vercel.app',
  );

  /// Timeouts kept well above the 15s minimum for slow mobile networks.
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 20);

  /// Verbose network logging only in debug builds. Never logs in release.
  static bool get enableDebugLogs => kDebugMode;

  /// True when the configured backend uses HTTPS (required in production).
  static bool get isSecure => baseUrl.startsWith('https://');
}
