import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/constants/refresh_intervals.dart';
import '../data/promo_codes_repository.dart';
import '../models/promo_code_model.dart';
import '../models/promo_code_payload.dart';

final promoCodesProvider = StateNotifierProvider.autoDispose<PromoCodesController, PromoCodesState>((ref) {
  final controller = PromoCodesController(ref.watch(promoCodesRepositoryProvider));
  controller.load();
  controller.startAutoRefresh();
  return controller;
});

class PromoCodesController extends StateNotifier<PromoCodesState> {
  PromoCodesController(this._repository) : super(const PromoCodesState());
  final PromoCodesRepository _repository;
  Timer? _timer;

  Future<void> load({bool silent = false}) async {
    state = state.copyWith(isLoading: !silent && state.codes.isEmpty, isRefreshing: silent || state.codes.isNotEmpty, clearError: true, clearSuccess: true);
    try {
      final codes = await _repository.fetchPromoCodes();
      if (!mounted) return;
      state = state.copyWith(codes: codes, isLoading: false, isRefreshing: false, lastUpdatedAt: DateTime.now(), clearError: true);
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, isRefreshing: false, errorMessage: _message(error));
    }
  }

  Future<void> refresh() => load(silent: true);
  void setQuery(String value) => state = state.copyWith(query: value.trim(), clearError: true, clearSuccess: true);
  void setActiveFilter(String value) => state = state.copyWith(activeFilter: value, clearError: true, clearSuccess: true);
  void setTypeFilter(String value) => state = state.copyWith(typeFilter: value, clearError: true, clearSuccess: true);

  Future<void> toggleActive(PromoCodeModel code) async {
    state = state.copyWith(actionCodeId: code.id, clearError: true, clearSuccess: true);
    try {
      await _repository.setPromoCodeActive(code.id, !code.active);
      if (!mounted) return;
      state = state.copyWith(actionCodeId: null, successMessage: !code.active ? '${code.code} enabled.' : '${code.code} disabled.');
      await load(silent: true);
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(actionCodeId: null, errorMessage: _message(error));
    }
  }

  Future<void> deletePromoCode(PromoCodeModel code) async {
    state = state.copyWith(actionCodeId: code.id, clearError: true, clearSuccess: true);
    try {
      final deleted = await _repository.deletePromoCode(code.id);
      if (!mounted) return;
      state = state.copyWith(actionCodeId: null, successMessage: deleted ? '${code.code} deleted.' : '${code.code} has orders, so it was disabled instead of deleted.');
      await load(silent: true);
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(actionCodeId: null, errorMessage: _message(error));
    }
  }

  void startAutoRefresh() {
    _timer?.cancel();
    _timer = Timer.periodic(RefreshIntervals.contentManagement, (_) { if (mounted) load(silent: true); });
  }

  String _message(Object error) => error is AppException ? error.message : 'Promo code action failed. Please try again.';

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }
}

class PromoCodesState {
  const PromoCodesState({
    this.codes = const <PromoCodeModel>[],
    this.query = '',
    this.activeFilter = 'ALL',
    this.typeFilter = 'ALL',
    this.isLoading = false,
    this.isRefreshing = false,
    this.actionCodeId,
    this.errorMessage,
    this.successMessage,
    this.lastUpdatedAt,
  });

  final List<PromoCodeModel> codes;
  final String query;
  final String activeFilter;
  final String typeFilter;
  final bool isLoading;
  final bool isRefreshing;
  final String? actionCodeId;
  final String? errorMessage;
  final String? successMessage;
  final DateTime? lastUpdatedAt;

  List<PromoCodeModel> get filteredCodes {
    final text = query.toLowerCase();
    return codes.where((code) {
      final activeOk = activeFilter == 'ALL' || (activeFilter == 'ACTIVE' && code.active) || (activeFilter == 'INACTIVE' && !code.active) || (activeFilter == 'USABLE' && code.canBeUsed) || (activeFilter == 'EXPIRED' && code.isExpired);
      final typeOk = typeFilter == 'ALL' || code.discountType.toUpperCase() == typeFilter;
      final textOk = text.isEmpty || [code.code, code.discountType, code.discountValue.toString(), code.minOrderUsd.toString()].join(' ').toLowerCase().contains(text);
      return activeOk && typeOk && textOk;
    }).toList();
  }

  PromoCodesState copyWith({
    List<PromoCodeModel>? codes,
    String? query,
    String? activeFilter,
    String? typeFilter,
    bool? isLoading,
    bool? isRefreshing,
    String? actionCodeId,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    DateTime? lastUpdatedAt,
  }) => PromoCodesState(
        codes: codes ?? this.codes,
        query: query ?? this.query,
        activeFilter: activeFilter ?? this.activeFilter,
        typeFilter: typeFilter ?? this.typeFilter,
        isLoading: isLoading ?? this.isLoading,
        isRefreshing: isRefreshing ?? this.isRefreshing,
        actionCodeId: actionCodeId,
        errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
        successMessage: clearSuccess ? null : successMessage ?? this.successMessage,
        lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      );
}

final promoCodeEditorProvider = StateNotifierProvider.autoDispose.family<PromoCodeEditorController, PromoCodeEditorState, String?>((ref, promoId) {
  final controller = PromoCodeEditorController(ref.watch(promoCodesRepositoryProvider), promoId);
  controller.load();
  return controller;
});

class PromoCodeEditorController extends StateNotifier<PromoCodeEditorState> {
  PromoCodeEditorController(this._repository, this.promoId) : super(const PromoCodeEditorState());
  final PromoCodesRepository _repository;
  final String? promoId;
  bool get isEditing => promoId != null && promoId!.isNotEmpty;

  Future<void> load() async {
    if (!isEditing) return;
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final code = await _repository.fetchPromoCode(promoId!);
      if (!mounted) return;
      state = state.copyWith(code: code, isLoading: false);
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: _message(error));
    }
  }

  Future<PromoCodeModel?> save(PromoCodePayload payload) async {
    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);
    try {
      final result = isEditing ? await _repository.updatePromoCode(promoId!, payload) : await _repository.createPromoCode(payload);
      if (!mounted) return result;
      state = state.copyWith(code: result, isSaving: false, successMessage: isEditing ? 'Promo code updated.' : 'Promo code created.');
      return result;
    } catch (error) {
      if (!mounted) return null;
      state = state.copyWith(isSaving: false, errorMessage: _message(error));
      return null;
    }
  }

  String _message(Object error) => error is AppException ? error.message : 'Promo code save failed.';
}

class PromoCodeEditorState {
  const PromoCodeEditorState({this.code, this.isLoading = false, this.isSaving = false, this.errorMessage, this.successMessage});
  final PromoCodeModel? code;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  PromoCodeEditorState copyWith({PromoCodeModel? code, bool? isLoading, bool? isSaving, String? errorMessage, String? successMessage, bool clearError = false, bool clearSuccess = false}) => PromoCodeEditorState(
        code: code ?? this.code,
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
        successMessage: clearSuccess ? null : successMessage ?? this.successMessage,
      );
}
