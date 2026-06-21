import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/constants/refresh_intervals.dart';
import '../data/customers_repository.dart';
import '../models/customer_detail_model.dart';
import '../models/customer_summary_model.dart';

final customersProvider = StateNotifierProvider.autoDispose<CustomersController, CustomersState>((ref) {
  final controller = CustomersController(ref.watch(customersRepositoryProvider));
  controller.load();
  controller.startAutoRefresh();
  return controller;
});

class CustomersController extends StateNotifier<CustomersState> {
  CustomersController(this._repository) : super(const CustomersState());
  final CustomersRepository _repository;
  Timer? _timer;

  Future<void> load({bool silent = false}) async {
    state = state.copyWith(isLoading: !silent && state.customers.isEmpty, isRefreshing: silent || state.customers.isNotEmpty, clearError: true, clearSuccess: true);
    try {
      final response = await _repository.fetchCustomers(query: state.serverQuery);
      if (!mounted) return;
      state = state.copyWith(customers: response.customers, total: response.total, isLoading: false, isRefreshing: false, lastUpdatedAt: DateTime.now());
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, isRefreshing: false, errorMessage: _message(error));
    }
  }

  Future<void> refresh() => load(silent: true);
  Future<void> search(String query) async { state = state.copyWith(serverQuery: query.trim(), clearError: true, clearSuccess: true); await load(); }
  void startAutoRefresh() { _timer?.cancel(); _timer = Timer.periodic(RefreshIntervals.contentManagement, (_) { if (mounted) load(silent: true); }); }
  String _message(Object error) => error is AppException ? error.message : 'Customer action failed.';
  @override void dispose() { _timer?.cancel(); super.dispose(); }
}

class CustomersState {
  const CustomersState({this.customers = const <CustomerSummaryModel>[], this.total = 0, this.serverQuery = '', this.isLoading = false, this.isRefreshing = false, this.errorMessage, this.successMessage, this.lastUpdatedAt});
  final List<CustomerSummaryModel> customers;
  final int total;
  final String serverQuery;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;
  final String? successMessage;
  final DateTime? lastUpdatedAt;
  CustomersState copyWith({List<CustomerSummaryModel>? customers, int? total, String? serverQuery, bool? isLoading, bool? isRefreshing, String? errorMessage, String? successMessage, bool clearError = false, bool clearSuccess = false, DateTime? lastUpdatedAt}) => CustomersState(customers: customers ?? this.customers, total: total ?? this.total, serverQuery: serverQuery ?? this.serverQuery, isLoading: isLoading ?? this.isLoading, isRefreshing: isRefreshing ?? this.isRefreshing, errorMessage: clearError ? null : errorMessage ?? this.errorMessage, successMessage: clearSuccess ? null : successMessage ?? this.successMessage, lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt);
}

final customerDetailProvider = StateNotifierProvider.autoDispose.family<CustomerDetailController, CustomerDetailState, String>((ref, key) {
  final controller = CustomerDetailController(ref.watch(customersRepositoryProvider), key);
  controller.load();
  return controller;
});

class CustomerDetailController extends StateNotifier<CustomerDetailState> {
  CustomerDetailController(this._repository, this.key) : super(const CustomerDetailState());
  final CustomersRepository _repository;
  final String key;

  Future<void> load() async {
    state = state.copyWith(isLoading: state.detail == null, isRefreshing: state.detail != null, clearError: true, clearSuccess: true);
    try {
      final detail = await _repository.fetchCustomer(key);
      if (!mounted) return;
      state = state.copyWith(detail: detail, isLoading: false, isRefreshing: false);
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, isRefreshing: false, errorMessage: _message(error));
    }
  }

  Future<void> setBan({required bool banned, String? reason}) async {
    state = state.copyWith(isActionBusy: true, clearError: true, clearSuccess: true);
    try {
      await _repository.setBan(key, banned: banned, reason: reason);
      if (!mounted) return;
      state = state.copyWith(isActionBusy: false, successMessage: banned ? 'Customer banned.' : 'Customer unbanned.');
      await load();
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(isActionBusy: false, errorMessage: _message(error));
    }
  }

  String _message(Object error) => error is AppException ? error.message : 'Customer action failed.';
}

class CustomerDetailState {
  const CustomerDetailState({this.detail, this.isLoading = false, this.isRefreshing = false, this.isActionBusy = false, this.errorMessage, this.successMessage});
  final CustomerDetailModel? detail;
  final bool isLoading;
  final bool isRefreshing;
  final bool isActionBusy;
  final String? errorMessage;
  final String? successMessage;
  CustomerDetailState copyWith({CustomerDetailModel? detail, bool? isLoading, bool? isRefreshing, bool? isActionBusy, String? errorMessage, String? successMessage, bool clearError = false, bool clearSuccess = false}) => CustomerDetailState(detail: detail ?? this.detail, isLoading: isLoading ?? this.isLoading, isRefreshing: isRefreshing ?? this.isRefreshing, isActionBusy: isActionBusy ?? this.isActionBusy, errorMessage: clearError ? null : errorMessage ?? this.errorMessage, successMessage: clearSuccess ? null : successMessage ?? this.successMessage);
}
