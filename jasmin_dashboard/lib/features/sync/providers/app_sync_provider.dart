import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/refresh_intervals.dart';
import '../../../core/errors/app_exception.dart';
import '../../notifications/data/notifications_repository.dart';
import '../data/public_version_repository.dart';

final appSyncProvider = StateNotifierProvider<AppSyncController, AppSyncState>((ref) {
  return AppSyncController(
    ref.watch(publicVersionRepositoryProvider),
    ref.watch(notificationsRepositoryProvider),
  );
});

class AppSyncController extends StateNotifier<AppSyncState> {
  AppSyncController(this._publicVersionRepository, this._notificationsRepository) : super(const AppSyncState());

  final PublicVersionRepository _publicVersionRepository;
  final NotificationsRepository _notificationsRepository;
  final Map<String, String> _knownVersions = <String, String>{};
  Timer? _websiteVersionTimer;
  Timer? _notificationTimer;
  bool _started = false;
  bool _polling = false;

  static const List<String> _publicScopes = <String>[
    'home',
    'settings',
    'games',
    'products',
    'banners',
    'faqs',
  ];

  void start() {
    if (_started) return;
    _started = true;
    unawaited(pollNow(reason: 'start'));
    _websiteVersionTimer = Timer.periodic(RefreshIntervals.websiteVersion, (_) {
      unawaited(_checkWebsiteVersions());
    });
    _notificationTimer = Timer.periodic(RefreshIntervals.notifications, (_) {
      unawaited(_refreshUnreadNotifications());
    });
  }

  void stop() {
    _started = false;
    _polling = false;
    _websiteVersionTimer?.cancel();
    _notificationTimer?.cancel();
    _websiteVersionTimer = null;
    _notificationTimer = null;
    _knownVersions.clear();
    state = const AppSyncState();
  }

  Future<void> pollNow({String reason = 'manual'}) async {
    if (!_started && reason != 'resume') return;
    await Future.wait<void>([
      _checkWebsiteVersions(),
      _refreshUnreadNotifications(),
    ]);
  }

  Future<void> recordAdminMutation(String scope) async {
    state = state.copyWith(
      pendingWebsiteSyncScope: scope,
      syncNotice: 'Waiting for website refresh: $scope',
      clearError: true,
    );
    await _checkWebsiteVersions();
  }

  Future<void> _checkWebsiteVersions() async {
    if (_polling) return;
    _polling = true;
    if (mounted) {
      state = state.copyWith(isCheckingWebsite: true, clearError: true);
    }

    try {
      final versions = await Future.wait(
        _publicScopes.map((scope) => _publicVersionRepository.fetchVersion(scope: scope)),
      );

      final changedScopes = <String>[];
      for (final item in versions) {
        final previousVersion = _knownVersions[item.scope];
        if (previousVersion != null && previousVersion != item.version) {
          changedScopes.add(item.scope);
        }
        _knownVersions[item.scope] = item.version;
      }

      if (!mounted) return;
      final pendingScope = state.pendingWebsiteSyncScope;
      final hasMatchedPending = pendingScope != null && changedScopes.contains(pendingScope);
      state = state.copyWith(
        isCheckingWebsite: false,
        websiteVersionReady: true,
        lastWebsiteCheckAt: DateTime.now(),
        changedScopes: changedScopes,
        pendingWebsiteSyncScope: hasMatchedPending ? null : pendingScope,
        clearPendingWebsiteSync: hasMatchedPending,
        syncNotice: changedScopes.isEmpty ? null : 'Website refreshed: ${changedScopes.join(', ')}',
        clearNotice: changedScopes.isEmpty,
        clearError: true,
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        isCheckingWebsite: false,
        errorMessage: _messageFromError(error),
      );
    } finally {
      _polling = false;
    }
  }

  Future<void> _refreshUnreadNotifications() async {
    try {
      final response = await _notificationsRepository.fetchNotifications(page: 1, perPage: 1);
      if (!mounted) return;
      state = state.copyWith(
        unreadNotifications: response.unreadCount,
        lastNotificationCheckAt: DateTime.now(),
        clearError: true,
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(errorMessage: _messageFromError(error));
    }
  }

  String _messageFromError(Object error) {
    if (error is AppException) return error.message;
    return 'Auto-update sync failed.';
  }

  @override
  void dispose() {
    _websiteVersionTimer?.cancel();
    _notificationTimer?.cancel();
    super.dispose();
  }
}

class AppSyncState {
  const AppSyncState({
    this.unreadNotifications = 0,
    this.websiteVersionReady = false,
    this.isCheckingWebsite = false,
    this.changedScopes = const <String>[],
    this.pendingWebsiteSyncScope,
    this.syncNotice,
    this.errorMessage,
    this.lastWebsiteCheckAt,
    this.lastNotificationCheckAt,
  });

  final int unreadNotifications;
  final bool websiteVersionReady;
  final bool isCheckingWebsite;
  final List<String> changedScopes;
  final String? pendingWebsiteSyncScope;
  final String? syncNotice;
  final String? errorMessage;
  final DateTime? lastWebsiteCheckAt;
  final DateTime? lastNotificationCheckAt;

  bool get hasUnreadNotifications => unreadNotifications > 0;
  bool get hasPendingWebsiteSync => pendingWebsiteSyncScope != null;
  bool get hasRecentWebsiteChange => changedScopes.isNotEmpty;

  AppSyncState copyWith({
    int? unreadNotifications,
    bool? websiteVersionReady,
    bool? isCheckingWebsite,
    List<String>? changedScopes,
    String? pendingWebsiteSyncScope,
    String? syncNotice,
    String? errorMessage,
    bool clearPendingWebsiteSync = false,
    bool clearNotice = false,
    bool clearError = false,
    DateTime? lastWebsiteCheckAt,
    DateTime? lastNotificationCheckAt,
  }) {
    return AppSyncState(
      unreadNotifications: unreadNotifications ?? this.unreadNotifications,
      websiteVersionReady: websiteVersionReady ?? this.websiteVersionReady,
      isCheckingWebsite: isCheckingWebsite ?? this.isCheckingWebsite,
      changedScopes: changedScopes ?? this.changedScopes,
      pendingWebsiteSyncScope: clearPendingWebsiteSync ? null : pendingWebsiteSyncScope ?? this.pendingWebsiteSyncScope,
      syncNotice: clearNotice ? null : syncNotice ?? this.syncNotice,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      lastWebsiteCheckAt: lastWebsiteCheckAt ?? this.lastWebsiteCheckAt,
      lastNotificationCheckAt: lastNotificationCheckAt ?? this.lastNotificationCheckAt,
    );
  }
}
