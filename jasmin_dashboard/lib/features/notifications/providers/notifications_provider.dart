import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/constants/refresh_intervals.dart';
import '../data/notifications_repository.dart';
import '../models/admin_notification_model.dart';

final notificationsProvider = StateNotifierProvider.autoDispose<
    NotificationsController, NotificationsState>((ref) {
  final controller =
      NotificationsController(ref.watch(notificationsRepositoryProvider));
  controller.load(reset: true);
  controller.startAutoRefresh();
  return controller;
});

class NotificationsController extends StateNotifier<NotificationsState> {
  NotificationsController(this._repository) : super(const NotificationsState());
  final NotificationsRepository _repository;
  Timer? _timer;

  Future<void> load({bool reset = false, bool silent = false}) async {
    final page = reset ? 1 : state.page + 1;
    state = state.copyWith(
        isLoading: reset && state.notifications.isEmpty && !silent,
        isRefreshing: silent || (reset && state.notifications.isNotEmpty),
        isLoadingMore: !reset,
        clearError: true,
        clearSuccess: true);
    try {
      final response = await _repository.fetchNotifications(
          page: page, unreadOnly: state.unreadOnly);
      if (!mounted) {
        return;
      }
      state = state.copyWith(
          notifications: reset
              ? response.notifications
              : [...state.notifications, ...response.notifications],
          total: response.total,
          unreadCount: response.unreadCount,
          page: response.page,
          totalPages: response.totalPages,
          isLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
          lastUpdatedAt: DateTime.now());
    } catch (error) {
      if (!mounted) {
        return;
      }
      state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
          errorMessage: _message(error));
    }
  }

  Future<void> refresh() => load(reset: true, silent: true);
  Future<void> setUnreadOnly(bool value) async {
    state =
        state.copyWith(unreadOnly: value, clearError: true, clearSuccess: true);
    await load(reset: true);
  }

  Future<void> toggleRead(AdminNotificationModel notification) async {
    state = state.copyWith(
        actionNotificationId: notification.id,
        clearError: true,
        clearSuccess: true);
    try {
      await _repository.setRead(notification.id, !notification.isRead);
      if (!mounted) {
        return;
      }
      state = state.copyWith(
          actionNotificationId: null,
          successMessage:
              !notification.isRead ? 'Marked as read.' : 'Marked as unread.');
      await load(reset: true, silent: true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      state = state.copyWith(
          actionNotificationId: null, errorMessage: _message(error));
    }
  }

  Future<void> markAllRead() async {
    state =
        state.copyWith(isBulkBusy: true, clearError: true, clearSuccess: true);
    try {
      final updated = await _repository.markAllRead();
      if (!mounted) {
        return;
      }
      state = state.copyWith(
          isBulkBusy: false,
          successMessage: '$updated notifications marked as read.');
      await load(reset: true, silent: true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      state = state.copyWith(isBulkBusy: false, errorMessage: _message(error));
    }
  }

  void startAutoRefresh() {
    _timer?.cancel();
    _timer = Timer.periodic(RefreshIntervals.notifications, (_) {
      if (mounted) {
        load(reset: true, silent: true);
      }
    });
  }

  String _message(Object error) =>
      error is AppException ? error.message : 'Notification action failed.';
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class NotificationsState {
  const NotificationsState(
      {this.notifications = const <AdminNotificationModel>[],
      this.total = 0,
      this.unreadCount = 0,
      this.page = 0,
      this.totalPages = 0,
      this.unreadOnly = false,
      this.isLoading = false,
      this.isRefreshing = false,
      this.isLoadingMore = false,
      this.isBulkBusy = false,
      this.actionNotificationId,
      this.errorMessage,
      this.successMessage,
      this.lastUpdatedAt});
  final List<AdminNotificationModel> notifications;
  final int total;
  final int unreadCount;
  final int page;
  final int totalPages;
  final bool unreadOnly;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool isBulkBusy;
  final String? actionNotificationId;
  final String? errorMessage;
  final String? successMessage;
  final DateTime? lastUpdatedAt;
  bool get canLoadMore => page < totalPages;
  NotificationsState copyWith(
          {List<AdminNotificationModel>? notifications,
          int? total,
          int? unreadCount,
          int? page,
          int? totalPages,
          bool? unreadOnly,
          bool? isLoading,
          bool? isRefreshing,
          bool? isLoadingMore,
          bool? isBulkBusy,
          String? actionNotificationId,
          String? errorMessage,
          String? successMessage,
          bool clearError = false,
          bool clearSuccess = false,
          DateTime? lastUpdatedAt}) =>
      NotificationsState(
          notifications: notifications ?? this.notifications,
          total: total ?? this.total,
          unreadCount: unreadCount ?? this.unreadCount,
          page: page ?? this.page,
          totalPages: totalPages ?? this.totalPages,
          unreadOnly: unreadOnly ?? this.unreadOnly,
          isLoading: isLoading ?? this.isLoading,
          isRefreshing: isRefreshing ?? this.isRefreshing,
          isLoadingMore: isLoadingMore ?? this.isLoadingMore,
          isBulkBusy: isBulkBusy ?? this.isBulkBusy,
          actionNotificationId: actionNotificationId,
          errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
          successMessage:
              clearSuccess ? null : successMessage ?? this.successMessage,
          lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt);
}
