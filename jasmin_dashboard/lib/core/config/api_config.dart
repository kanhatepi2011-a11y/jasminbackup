class ApiConfig {
  const ApiConfig._();

  /// Use --dart-define=API_BASE_URL=http://10.0.2.2:3000 for Android emulator local testing.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://jasminbackup.vercel.app',
  );

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
