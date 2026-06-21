class RefreshIntervals {
  const RefreshIntervals._();

  static const Duration dashboard = Duration(seconds: 20);
  static const Duration orders = Duration(seconds: 20);
  static const Duration notifications = Duration(seconds: 20);
  static const Duration contentManagement = Duration(seconds: 30);
  static const Duration auditLogs = Duration(seconds: 45);
  static const Duration websiteVersion = Duration(seconds: 15);
  static const Duration appResumeDebounce = Duration(seconds: 2);
}
