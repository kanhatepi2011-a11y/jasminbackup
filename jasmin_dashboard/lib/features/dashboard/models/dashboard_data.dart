import 'dashboard_recent_order.dart';
import 'dashboard_stats.dart';
import 'system_status.dart';

class DashboardData {
  const DashboardData({
    required this.stats,
    required this.recentOrders,
    required this.systemStatus,
  });

  final DashboardStats stats;
  final List<DashboardRecentOrder> recentOrders;
  final SystemStatus systemStatus;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final ordersRaw = json['recentOrders'];
    final orders = ordersRaw is List
        ? ordersRaw
            .whereType<Map>()
            .map((item) =>
                DashboardRecentOrder.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: false)
        : const <DashboardRecentOrder>[];

    return DashboardData(
      stats: DashboardStats.fromJson(_mapOrNull(json['stats'])),
      recentOrders: orders,
      systemStatus: SystemStatus.fromJson(_mapOrNull(json['systemStatus'])),
    );
  }

  static Map<String, dynamic>? _mapOrNull(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }
}
