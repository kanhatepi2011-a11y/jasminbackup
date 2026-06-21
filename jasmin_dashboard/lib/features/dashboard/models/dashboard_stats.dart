class DashboardStats {
  const DashboardStats({
    required this.totalOrders,
    required this.pendingOrders,
    required this.paidOrders,
    required this.processingOrders,
    required this.completedOrders,
    required this.failedOrders,
    required this.cancelledOrders,
    required this.refundedOrders,
    required this.todayRevenueUsd,
    required this.todayRevenueKhr,
    required this.totalCustomers,
    required this.newOrdersToday,
    required this.totalGames,
    required this.activeGames,
    required this.totalProducts,
    required this.activeProducts,
    required this.unreadNotifications,
  });

  final int totalOrders;
  final int pendingOrders;
  final int paidOrders;
  final int processingOrders;
  final int completedOrders;
  final int failedOrders;
  final int cancelledOrders;
  final int refundedOrders;
  final double todayRevenueUsd;
  final double todayRevenueKhr;
  final int totalCustomers;
  final int newOrdersToday;
  final int totalGames;
  final int activeGames;
  final int totalProducts;
  final int activeProducts;
  final int unreadNotifications;

  int get openOrders => pendingOrders + paidOrders + processingOrders;
  int get inactiveProducts => totalProducts - activeProducts;
  int get inactiveGames => totalGames - activeGames;

  factory DashboardStats.empty() => const DashboardStats(
        totalOrders: 0,
        pendingOrders: 0,
        paidOrders: 0,
        processingOrders: 0,
        completedOrders: 0,
        failedOrders: 0,
        cancelledOrders: 0,
        refundedOrders: 0,
        todayRevenueUsd: 0,
        todayRevenueKhr: 0,
        totalCustomers: 0,
        newOrdersToday: 0,
        totalGames: 0,
        activeGames: 0,
        totalProducts: 0,
        activeProducts: 0,
        unreadNotifications: 0,
      );

  factory DashboardStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DashboardStats.empty();
    return DashboardStats(
      totalOrders: _int(json['totalOrders']),
      pendingOrders: _int(json['pendingOrders']),
      paidOrders: _int(json['paidOrders']),
      processingOrders: _int(json['processingOrders']),
      completedOrders: _int(json['completedOrders']),
      failedOrders: _int(json['failedOrders']),
      cancelledOrders: _int(json['cancelledOrders']),
      refundedOrders: _int(json['refundedOrders']),
      todayRevenueUsd: _double(json['todayRevenueUsd']),
      todayRevenueKhr: _double(json['todayRevenueKhr']),
      totalCustomers: _int(json['totalCustomers']),
      newOrdersToday: _int(json['newOrdersToday']),
      totalGames: _int(json['totalGames']),
      activeGames: _int(json['activeGames']),
      totalProducts: _int(json['totalProducts']),
      activeProducts: _int(json['activeProducts']),
      unreadNotifications: _int(json['unreadNotifications']),
    );
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
