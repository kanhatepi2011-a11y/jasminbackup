import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/constants/refresh_intervals.dart';
import '../data/orders_repository.dart';
import '../models/order_model.dart';

final ordersProvider =
    StateNotifierProvider.autoDispose<OrdersController, OrdersState>((ref) {
  final controller = OrdersController(ref.watch(ordersRepositoryProvider));
  controller.load();
  controller.startAutoRefresh();
  return controller;
});

class OrdersController extends StateNotifier<OrdersState> {
  OrdersController(this._repository) : super(const OrdersState());

  final OrdersRepository _repository;
  Timer? _autoRefreshTimer;

  Future<void> load({bool silent = false, int? page}) async {
    if (!mounted) {
      return;
    }
    final targetPage = page ?? state.page;
    state = state.copyWith(
      isLoading: !silent && state.orders.isEmpty,
      isRefreshing: silent || state.orders.isNotEmpty,
      clearError: true,
    );

    try {
      final result = await _repository.fetchOrders(
        page: targetPage,
        perPage: state.perPage,
        status: state.status,
        query: state.query,
      );
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        orders: result.orders,
        total: result.total,
        page: result.page,
        totalPages: result.totalPages <= 0 ? 1 : result.totalPages,
        isLoading: false,
        isRefreshing: false,
        lastUpdatedAt: DateTime.now(),
        clearError: true,
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

  Future<void> setStatus(String status) async {
    state = state.copyWith(status: status, page: 1, clearError: true);
    await load();
  }

  Future<void> setQuery(String query) async {
    if (query.trim() == state.query.trim()) {
      return;
    }
    state = state.copyWith(query: query.trim(), page: 1, clearError: true);
    await load();
  }

  Future<void> nextPage() async {
    if (state.page >= state.totalPages ||
        state.isLoading ||
        state.isRefreshing) {
      return;
    }
    await load(silent: true, page: state.page + 1);
  }

  Future<void> previousPage() async {
    if (state.page <= 1 || state.isLoading || state.isRefreshing) {
      return;
    }
    await load(silent: true, page: state.page - 1);
  }

  void startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(RefreshIntervals.orders, (_) {
      if (mounted) {
        load(silent: true);
      }
    });
  }

  String _messageFromError(Object error) {
    if (error is AppException) {
      return error.message;
    }
    return 'Orders refresh failed. Please try again.';
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
}

class OrdersState {
  const OrdersState({
    this.orders = const <OrderModel>[],
    this.query = '',
    this.status = 'ALL',
    this.total = 0,
    this.page = 1,
    this.perPage = 25,
    this.totalPages = 1,
    this.isLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
    this.lastUpdatedAt,
  });

  final List<OrderModel> orders;
  final String query;
  final String status;
  final int total;
  final int page;
  final int perPage;
  final int totalPages;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;
  final DateTime? lastUpdatedAt;

  bool get hasOrders => orders.isNotEmpty;
  bool get canGoNext => page < totalPages;
  bool get canGoPrevious => page > 1;

  OrdersState copyWith({
    List<OrderModel>? orders,
    String? query,
    String? status,
    int? total,
    int? page,
    int? perPage,
    int? totalPages,
    bool? isLoading,
    bool? isRefreshing,
    String? errorMessage,
    bool clearError = false,
    DateTime? lastUpdatedAt,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      query: query ?? this.query,
      status: status ?? this.status,
      total: total ?? this.total,
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}
