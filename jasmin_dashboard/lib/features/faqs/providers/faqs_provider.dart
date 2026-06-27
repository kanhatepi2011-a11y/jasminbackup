import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/constants/refresh_intervals.dart';
import '../data/faqs_repository.dart';
import '../models/faq_model.dart';
import '../models/faq_payload.dart';

final faqsProvider =
    StateNotifierProvider.autoDispose<FaqsController, FaqsState>((ref) {
  final controller = FaqsController(ref.watch(faqsRepositoryProvider));
  controller.load();
  controller.startAutoRefresh();
  return controller;
});

class FaqsController extends StateNotifier<FaqsState> {
  FaqsController(this._repository) : super(const FaqsState());

  final FaqsRepository _repository;
  Timer? _autoRefreshTimer;

  Future<void> load({bool silent = false}) async {
    state = state.copyWith(
      isLoading: !silent && state.faqs.isEmpty,
      isRefreshing: silent || state.faqs.isNotEmpty,
      clearError: true,
      clearSuccess: true,
    );
    try {
      final faqs = await _repository.fetchFaqs();
      if (!mounted) {
        return;
      }
      state = state.copyWith(
          faqs: faqs,
          isLoading: false,
          isRefreshing: false,
          lastUpdatedAt: DateTime.now(),
          clearError: true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          errorMessage: _messageFromError(error));
    }
  }

  Future<void> refresh() => load(silent: true);
  void setQuery(String query) => state =
      state.copyWith(query: query.trim(), clearError: true, clearSuccess: true);
  void setCategory(String category) => state = state.copyWith(
      categoryFilter: category, clearError: true, clearSuccess: true);
  void setActiveFilter(String activeFilter) => state = state.copyWith(
      activeFilter: activeFilter, clearError: true, clearSuccess: true);

  Future<void> toggleActive(FaqModel faq) async {
    state = state.copyWith(
        actionFaqId: faq.id, clearError: true, clearSuccess: true);
    try {
      await _repository.setFaqActive(faq.id, !faq.active);
      if (!mounted) {
        return;
      }
      state = state.copyWith(
          actionFaqId: null,
          successMessage:
              !faq.active ? 'FAQ is now visible.' : 'FAQ is now hidden.');
      await load(silent: true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      state = state.copyWith(
          actionFaqId: null, errorMessage: _messageFromError(error));
    }
  }

  Future<void> deleteFaq(FaqModel faq) async {
    state = state.copyWith(
        actionFaqId: faq.id, clearError: true, clearSuccess: true);
    try {
      await _repository.deleteFaq(faq.id);
      if (!mounted) {
        return;
      }
      state = state.copyWith(
          actionFaqId: null, successMessage: 'FAQ item was deleted.');
      await load(silent: true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      state = state.copyWith(
          actionFaqId: null, errorMessage: _messageFromError(error));
    }
  }

  void startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(RefreshIntervals.contentManagement, (_) {
      if (mounted) {
        load(silent: true);
      }
    });
  }

  String _messageFromError(Object error) => error is AppException
      ? error.message
      : 'FAQ refresh failed. Please try again.';

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
}

class FaqsState {
  const FaqsState({
    this.faqs = const <FaqModel>[],
    this.query = '',
    this.categoryFilter = 'ALL',
    this.activeFilter = 'ALL',
    this.isLoading = false,
    this.isRefreshing = false,
    this.actionFaqId,
    this.errorMessage,
    this.successMessage,
    this.lastUpdatedAt,
  });

  final List<FaqModel> faqs;
  final String query;
  final String categoryFilter;
  final String activeFilter;
  final bool isLoading;
  final bool isRefreshing;
  final String? actionFaqId;
  final String? errorMessage;
  final String? successMessage;
  final DateTime? lastUpdatedAt;

  List<String> get categories {
    final values = faqs
        .map((faq) =>
            faq.category.trim().isEmpty ? 'general' : faq.category.trim())
        .toSet()
        .toList()
      ..sort();
    return values;
  }

  List<FaqModel> get filteredFaqs {
    final text = query.trim().toLowerCase();
    return faqs.where((faq) {
      final matchesActive = activeFilter == 'ALL' ||
          (activeFilter == 'ACTIVE' ? faq.active : !faq.active);
      final matchesCategory =
          categoryFilter == 'ALL' || faq.category == categoryFilter;
      if (!matchesActive || !matchesCategory) {
        return false;
      }
      if (text.isEmpty) {
        return true;
      }
      return [faq.question, faq.answer, faq.category]
          .join(' ')
          .toLowerCase()
          .contains(text);
    }).toList();
  }

  FaqsState copyWith({
    List<FaqModel>? faqs,
    String? query,
    String? categoryFilter,
    String? activeFilter,
    bool? isLoading,
    bool? isRefreshing,
    String? actionFaqId,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    DateTime? lastUpdatedAt,
  }) {
    return FaqsState(
      faqs: faqs ?? this.faqs,
      query: query ?? this.query,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      activeFilter: activeFilter ?? this.activeFilter,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      actionFaqId: actionFaqId,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}

final faqEditorProvider = StateNotifierProvider.autoDispose
    .family<FaqEditorController, FaqEditorState, String?>((ref, faqId) {
  final controller =
      FaqEditorController(ref.watch(faqsRepositoryProvider), faqId);
  controller.load();
  return controller;
});

class FaqEditorController extends StateNotifier<FaqEditorState> {
  FaqEditorController(this._repository, this.faqId)
      : super(const FaqEditorState());

  final FaqsRepository _repository;
  final String? faqId;

  bool get isEditing => faqId != null && faqId!.trim().isNotEmpty;

  Future<void> load() async {
    state =
        state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      FaqModel? faq;
      if (isEditing) {
        faq = await _repository.fetchFaq(faqId!);
      }
      if (!mounted) {
        return;
      }
      state = state.copyWith(faq: faq, isLoading: false, clearError: true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      state = state.copyWith(
          isLoading: false, errorMessage: _messageFromError(error));
    }
  }

  Future<FaqModel?> save(FaqPayload payload) async {
    state =
        state.copyWith(isSaving: true, clearError: true, clearSuccess: true);
    try {
      final result = isEditing
          ? await _repository.updateFaq(faqId!, payload)
          : await _repository.createFaq(payload);
      if (!mounted) {
        return result;
      }
      state = state.copyWith(
        faq: result,
        isSaving: false,
        successMessage: isEditing
            ? 'FAQ updated. FAQ page will refresh shortly.'
            : 'FAQ created. FAQ page will refresh shortly.',
      );
      return result;
    } catch (error) {
      if (!mounted) {
        return null;
      }
      state = state.copyWith(
          isSaving: false, errorMessage: _messageFromError(error));
      return null;
    }
  }

  String _messageFromError(Object error) => error is AppException
      ? error.message
      : 'FAQ action failed. Please try again.';
}

class FaqEditorState {
  const FaqEditorState(
      {this.faq,
      this.isLoading = false,
      this.isSaving = false,
      this.errorMessage,
      this.successMessage});

  final FaqModel? faq;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  FaqEditorState copyWith(
      {FaqModel? faq,
      bool? isLoading,
      bool? isSaving,
      String? errorMessage,
      String? successMessage,
      bool clearError = false,
      bool clearSuccess = false}) {
    return FaqEditorState(
      faq: faq ?? this.faq,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }
}
