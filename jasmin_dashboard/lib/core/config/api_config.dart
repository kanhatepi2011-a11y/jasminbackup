class ApiConfig {
  const ApiConfig._();

  /// Use --dart-define=JASMIN_API_BASE_URL=https://www.jasmintopup.site
  /// Android emulator local backend default is http://10.0.2.2:3000.
  static const String baseUrl = String.fromEnvironment(
    'JASMIN_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
