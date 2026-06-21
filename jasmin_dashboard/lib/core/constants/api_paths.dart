class ApiPaths {
  const ApiPaths._();

  static const String login = '/api/admin/auth/login';
  static const String twoFactor = '/api/admin/auth/2fa';
  static const String me = '/api/admin/auth/me';
  static const String logout = '/api/admin/auth/logout';

  static const String dashboard = '/api/admin/dashboard';
  static const String orders = '/api/admin/orders';
  static String orderDetail(String orderNumber) => '/api/admin/orders/${Uri.encodeComponent(orderNumber)}';
  static const String products = '/api/admin/products';
  static String productDetail(String id) => '/api/admin/products/${Uri.encodeComponent(id)}';
  static const String games = '/api/admin/games';
  static String gameDetail(String id) => '/api/admin/games/${Uri.encodeComponent(id)}';
  static const String gameReorder = '/api/admin/games/reorder';
  static const String banners = '/api/admin/banners';
  static String bannerDetail(String id) => '/api/admin/banners/${Uri.encodeComponent(id)}';
  static const String settings = '/api/admin/settings';
  static const String faqs = '/api/admin/faqs';
  static String faqDetail(String id) => '/api/admin/faqs/${Uri.encodeComponent(id)}';
  static const String customers = '/api/admin/customers';
  static String customerDetail(String key) => '/api/admin/customers/${Uri.encodeComponent(key)}';
  static const String promoCodes = '/api/admin/promo-codes';
  static String promoCodeDetail(String id) => '/api/admin/promo-codes/${Uri.encodeComponent(id)}';
  static const String auditLogs = '/api/admin/audit-logs';
  static const String notifications = '/api/admin/notifications';
  static const String publicVersion = '/api/public/version';
  static String notificationDetail(String id) => '/api/admin/notifications/${Uri.encodeComponent(id)}';
}
