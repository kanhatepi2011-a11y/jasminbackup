import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/api_error_mapper.dart';
import '../models/admin_notification_model.dart';
import '../models/notifications_response.dart';
import 'notifications_api.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
    (ref) => NotificationsRepository(ref.watch(notificationsApiProvider)));

class NotificationsRepository {
  const NotificationsRepository(this._api);
  final NotificationsApi _api;

  Future<NotificationsResponse> fetchNotifications(
      {required int page, int perPage = 25, bool unreadOnly = false}) async {
    try {
      return await _api.fetchNotifications(
          page: page, perPage: perPage, unreadOnly: unreadOnly);
    } on DioException catch (e) {
      throw _exception(e, 'Could not load notifications.');
    }
  }

  Future<AdminNotificationModel> setRead(String id, bool read) async {
    try {
      return await _api.setRead(id, read);
    } on DioException catch (e) {
      throw _exception(e, 'Could not update notification.');
    }
  }

  Future<int> markAllRead() async {
    try {
      return await _api.markAllRead();
    } on DioException catch (e) {
      throw _exception(e, 'Could not mark notifications as read.');
    }
  }

  AppException _exception(DioException error, String fallback) {
    return mapDioError(error, fallback: fallback);
  }
}
