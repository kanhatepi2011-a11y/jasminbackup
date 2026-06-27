import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/constants/refresh_intervals.dart';
import '../data/dashboard_repository.dart';
import '../models/dashboard_data.dart';

final dashboardProvider =
    StateNotifierProvider.autoDispose<DashboardController, DashboardState>(
        (ref) {
  final controller =
      DashboardController(ref.watch(dashboardRepositoryProvider));
  controller.load();
  controller.startAutoRefresh();
  return controller;
});

class DashboardController extends StateNotifier<DashboardState> {
  DashboardController(this._repository) : super(const DashboardState());

  final DashboardRepository _repository;
  Timer? _autoRefreshTimer;

  Future<void> load({bool silent = false}) async {
    if (!mounted) {
      return;
    }
    state = state.copyWith(
      isLoading: !silent && state.data == null,
      isRefreshing: silent || state.data != null,
      clearError: true,
    );

    try {
      final data = await _repository.fetchDashboard();
      if (!mounted) {
        return;
      }
      state = DashboardState(
        data: data,
        lastUpdatedAt: DateTime.now(),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: _messageFromError(error),
      );
    }
  }

  Future<void> refresh() => load(silent: true);

  void startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(RefreshIntervals.dashboard, (_) {
      if (mounted) {
        load(silent: true);
      }
    });
  }

  String _messageFromError(Object error) {
    if (error is AppException) {
      return error.message;
    }
    return 'Dashboard refresh failed. Please try again.';
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
}

class DashboardState {
  const DashboardState({
    this.data,
    this.isLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
    this.lastUpdatedAt,
  });

  final DashboardData? data;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;
  final DateTime? lastUpdatedAt;

  bool get hasData => data != null;

  DashboardState copyWith({
    DashboardData? data,
    bool? isLoading,
    bool? isRefreshing,
    String? errorMessage,
    bool clearError = false,
    DateTime? lastUpdatedAt,
  }) {
    return DashboardState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}
