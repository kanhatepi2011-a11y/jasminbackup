import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_client.dart';
import '../models/admin_notification_model.dart';
import '../models/notifications_response.dart';

final notificationsApiProvider = Provider<NotificationsApi>((ref) => NotificationsApi(ref.watch(dioProvider)));

class NotificationsApi {
  const NotificationsApi(this._dio);
  final Dio _dio;

  Future<NotificationsResponse> fetchNotifications({required int page, int perPage = 25, bool unreadOnly = false}) async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.notifications, queryParameters: <String, dynamic>{'page': page, 'perPage': perPage, if (unreadOnly) 'unreadOnly': true});
    return NotificationsResponse.fromJson(response.data ?? const <String, dynamic>{});
  }

  Future<AdminNotificationModel> setRead(String id, bool read) async {
    final response = await _dio.patch<Map<String, dynamic>>(ApiPaths.notificationDetail(id), data: <String, dynamic>{'read': read});
    return AdminNotificationModel.fromJson(response.data ?? const <String, dynamic>{});
  }

  Future<int> markAllRead() async {
    final response = await _dio.patch<Map<String, dynamic>>(ApiPaths.notifications, data: <String, dynamic>{'action': 'mark_all_read'});
    final updated = response.data?['updated'];
    if (updated is int) return updated;
    if (updated is num) return updated.toInt();
    return int.tryParse(updated?.toString() ?? '') ?? 0;
  }
}
