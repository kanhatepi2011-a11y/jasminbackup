import 'admin_notification_model.dart';

class NotificationsResponse {
  const NotificationsResponse({required this.notifications, required this.total, required this.unreadCount, required this.page, required this.perPage, required this.totalPages});
  final List<AdminNotificationModel> notifications;
  final int total;
  final int unreadCount;
  final int page;
  final int perPage;
  final int totalPages;

  factory NotificationsResponse.fromJson(Map<String, dynamic> json) => NotificationsResponse(
        notifications: (json['notifications'] as List? ?? const <dynamic>[]).whereType<Map>().map((item) => AdminNotificationModel.fromJson(Map<String, dynamic>.from(item))).toList(),
        total: _intFrom(json['total']),
        unreadCount: _intFrom(json['unreadCount']),
        page: _intFrom(json['page']),
        perPage: _intFrom(json['perPage']),
        totalPages: _intFrom(json['totalPages']),
      );
  static int _intFrom(dynamic value) => value is int ? value : value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
}
