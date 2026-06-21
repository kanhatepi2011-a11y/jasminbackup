import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/constants/refresh_intervals.dart';
import '../data/audit_logs_repository.dart';
import '../models/audit_log_model.dart';

final auditLogsProvider = StateNotifierProvider.autoDispose<AuditLogsController, AuditLogsState>((ref) {
  final controller = AuditLogsController(ref.watch(auditLogsRepositoryProvider));
  controller.load(reset: true);
  controller.startAutoRefresh();
  return controller;
});

class AuditLogsController extends StateNotifier<AuditLogsState> {
  AuditLogsController(this._repository) : super(const AuditLogsState());
  final AuditLogsRepository _repository;
  Timer? _autoRefreshTimer;

  Future<void> load({bool reset = false}) async {
    final page = reset ? 1 : state.page + 1;
    state = state.copyWith(isLoading: reset && state.logs.isEmpty, isLoadingMore: !reset, clearError: true);
    try {
      final response = await _repository.fetchLogs(page: page, action: state.action, targetType: state.targetType, adminEmail: state.adminEmail);
      if (!mounted) return;
      state = state.copyWith(logs: reset ? response.logs : [...state.logs, ...response.logs], total: response.total, page: response.page, totalPages: response.totalPages, isLoading: false, isLoadingMore: false, lastUpdatedAt: DateTime.now());
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, isLoadingMore: false, errorMessage: error is AppException ? error.message : 'Audit logs failed to load.');
    }
  }

  Future<void> refresh() => load(reset: true);

  void startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(RefreshIntervals.auditLogs, (_) {
      if (mounted) load(reset: true);
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
  Future<void> applyFilters({String? action, String? targetType, String? adminEmail}) async { state = state.copyWith(action: action ?? state.action, targetType: targetType ?? state.targetType, adminEmail: adminEmail ?? state.adminEmail, clearError: true); await load(reset: true); }
}

class AuditLogsState {
  const AuditLogsState({this.logs = const <AuditLogModel>[], this.total = 0, this.page = 0, this.totalPages = 0, this.action = '', this.targetType = 'ALL', this.adminEmail = '', this.isLoading = false, this.isLoadingMore = false, this.errorMessage, this.lastUpdatedAt});
  final List<AuditLogModel> logs;
  final int total;
  final int page;
  final int totalPages;
  final String action;
  final String targetType;
  final String adminEmail;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final DateTime? lastUpdatedAt;
  bool get canLoadMore => page < totalPages;
  AuditLogsState copyWith({List<AuditLogModel>? logs, int? total, int? page, int? totalPages, String? action, String? targetType, String? adminEmail, bool? isLoading, bool? isLoadingMore, String? errorMessage, bool clearError = false, DateTime? lastUpdatedAt}) => AuditLogsState(logs: logs ?? this.logs, total: total ?? this.total, page: page ?? this.page, totalPages: totalPages ?? this.totalPages, action: action ?? this.action, targetType: targetType ?? this.targetType, adminEmail: adminEmail ?? this.adminEmail, isLoading: isLoading ?? this.isLoading, isLoadingMore: isLoadingMore ?? this.isLoadingMore, errorMessage: clearError ? null : errorMessage ?? this.errorMessage, lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt);
}
