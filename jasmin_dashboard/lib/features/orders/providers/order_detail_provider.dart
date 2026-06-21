import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../data/orders_repository.dart';
import '../models/order_model.dart';

final orderDetailProvider = StateNotifierProvider.autoDispose.family<OrderDetailController, OrderDetailState, String>((ref, orderNumber) {
  final controller = OrderDetailController(ref.watch(ordersRepositoryProvider), orderNumber);
  controller.load();
  return controller;
});

class OrderDetailController extends StateNotifier<OrderDetailState> {
  OrderDetailController(this._repository, this._orderNumber) : super(const OrderDetailState());

  final OrdersRepository _repository;
  final String _orderNumber;

  Future<void> load({bool silent = false}) async {
    state = state.copyWith(
      isLoading: !silent && state.order == null,
      isRefreshing: silent || state.order != null,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final order = await _repository.fetchOrder(_orderNumber);
      if (!mounted) return;
      state = state.copyWith(
        order: order,
        isLoading: false,
        isRefreshing: false,
        lastUpdatedAt: DateTime.now(),
        clearError: true,
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: _messageFromError(error),
      );
    }
  }

  Future<void> updateOrder({
    String? status,
    String? deliveryNote,
    String? failureReason,
    String? adminNote,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);
    try {
      final order = await _repository.updateOrder(
        orderNumber: _orderNumber,
        status: status,
        deliveryNote: deliveryNote,
        failureReason: failureReason,
        adminNote: adminNote,
      );
      if (!mounted) return;
      state = state.copyWith(
        order: order,
        isSaving: false,
        successMessage: 'Order updated successfully.',
        lastUpdatedAt: DateTime.now(),
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(isSaving: false, errorMessage: _messageFromError(error));
    }
  }

  String _messageFromError(Object error) {
    if (error is AppException) return error.message;
    return 'Could not update this order. Please try again.';
  }
}

class OrderDetailState {
  const OrderDetailState({
    this.order,
    this.isLoading = false,
    this.isRefreshing = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
    this.lastUpdatedAt,
  });

  final OrderModel? order;
  final bool isLoading;
  final bool isRefreshing;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;
  final DateTime? lastUpdatedAt;

  OrderDetailState copyWith({
    OrderModel? order,
    bool? isLoading,
    bool? isRefreshing,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    DateTime? lastUpdatedAt,
  }) {
    return OrderDetailState(
      order: order ?? this.order,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage: clearSuccess ? null : successMessage ?? this.successMessage,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}
