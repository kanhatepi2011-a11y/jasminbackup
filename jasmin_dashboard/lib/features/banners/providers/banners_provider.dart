import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/constants/refresh_intervals.dart';
import '../data/banners_repository.dart';
import '../models/banner_model.dart';
import '../models/banner_payload.dart';

final bannersProvider =
    StateNotifierProvider.autoDispose<BannersController, BannersState>((ref) {
  final controller = BannersController(ref.watch(bannersRepositoryProvider));
  controller.load();
  controller.startAutoRefresh();
  return controller;
});

class BannersController extends StateNotifier<BannersState> {
  BannersController(this._repository) : super(const BannersState());

  final BannersRepository _repository;
  Timer? _autoRefreshTimer;

  Future<void> load({bool silent = false}) async {
    state = state.copyWith(
      isLoading: !silent && state.banners.isEmpty,
      isRefreshing: silent || state.banners.isNotEmpty,
      clearError: true,
      clearSuccess: true,
    );
    try {
      final banners = await _repository.fetchBanners();
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        banners: banners,
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
          errorMessage: _messageFromError(error));
    }
  }

  Future<void> refresh() => load(silent: true);

  void setQuery(String query) => state =
      state.copyWith(query: query.trim(), clearError: true, clearSuccess: true);
  void setActiveFilter(String activeFilter) => state = state.copyWith(
      activeFilter: activeFilter, clearError: true, clearSuccess: true);

  Future<void> toggleActive(BannerModel banner) async {
    state = state.copyWith(
        actionBannerId: banner.id, clearError: true, clearSuccess: true);
    try {
      await _repository.setBannerActive(banner.id, !banner.active);
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        actionBannerId: null,
        successMessage: !banner.active
            ? '${banner.safeTitle} is now visible.'
            : '${banner.safeTitle} is now hidden.',
      );
      await load(silent: true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      state = state.copyWith(
          actionBannerId: null, errorMessage: _messageFromError(error));
    }
  }

  Future<void> deleteBanner(BannerModel banner) async {
    state = state.copyWith(
        actionBannerId: banner.id, clearError: true, clearSuccess: true);
    try {
      await _repository.deleteBanner(banner.id);
      if (!mounted) {
        return;
      }
      state = state.copyWith(
          actionBannerId: null,
          successMessage: '${banner.safeTitle} was deleted.');
      await load(silent: true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      state = state.copyWith(
          actionBannerId: null, errorMessage: _messageFromError(error));
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
      : 'Banners refresh failed. Please try again.';

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
}

class BannersState {
  const BannersState({
    this.banners = const <BannerModel>[],
    this.query = '',
    this.activeFilter = 'ALL',
    this.isLoading = false,
    this.isRefreshing = false,
    this.actionBannerId,
    this.errorMessage,
    this.successMessage,
    this.lastUpdatedAt,
  });

  final List<BannerModel> banners;
  final String query;
  final String activeFilter;
  final bool isLoading;
  final bool isRefreshing;
  final String? actionBannerId;
  final String? errorMessage;
  final String? successMessage;
  final DateTime? lastUpdatedAt;

  List<BannerModel> get filteredBanners {
    final text = query.trim().toLowerCase();
    return banners.where((banner) {
      final matchesActive = activeFilter == 'ALL' ||
          (activeFilter == 'ACTIVE' ? banner.active : !banner.active);
      if (!matchesActive) {
        return false;
      }
      if (text.isEmpty) {
        return true;
      }
      return [
        banner.title,
        banner.subtitle ?? '',
        banner.linkUrl ?? '',
        banner.ctaLabel ?? ''
      ].join(' ').toLowerCase().contains(text);
    }).toList();
  }

  BannersState copyWith({
    List<BannerModel>? banners,
    String? query,
    String? activeFilter,
    bool? isLoading,
    bool? isRefreshing,
    String? actionBannerId,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    DateTime? lastUpdatedAt,
  }) {
    return BannersState(
      banners: banners ?? this.banners,
      query: query ?? this.query,
      activeFilter: activeFilter ?? this.activeFilter,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      actionBannerId: actionBannerId,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}

final bannerEditorProvider = StateNotifierProvider.autoDispose
    .family<BannerEditorController, BannerEditorState, String?>(
        (ref, bannerId) {
  final controller =
      BannerEditorController(ref.watch(bannersRepositoryProvider), bannerId);
  controller.load();
  return controller;
});

class BannerEditorController extends StateNotifier<BannerEditorState> {
  BannerEditorController(this._repository, this.bannerId)
      : super(const BannerEditorState());

  final BannersRepository _repository;
  final String? bannerId;

  bool get isEditing => bannerId != null && bannerId!.trim().isNotEmpty;

  Future<void> load() async {
    state =
        state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      BannerModel? banner;
      if (isEditing) {
        banner = await _repository.fetchBanner(bannerId!);
      }
      if (!mounted) {
        return;
      }
      state =
          state.copyWith(banner: banner, isLoading: false, clearError: true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      state = state.copyWith(
          isLoading: false, errorMessage: _messageFromError(error));
    }
  }

  Future<BannerModel?> save(BannerPayload payload) async {
    state =
        state.copyWith(isSaving: true, clearError: true, clearSuccess: true);
    try {
      final result = isEditing
          ? await _repository.updateBanner(bannerId!, payload)
          : await _repository.createBanner(payload);
      if (!mounted) {
        return result;
      }
      state = state.copyWith(
        banner: result,
        isSaving: false,
        successMessage: isEditing
            ? 'Banner updated. Homepage will refresh shortly.'
            : 'Banner created. Homepage will refresh shortly.',
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
      : 'Banner action failed. Please try again.';
}

class BannerEditorState {
  const BannerEditorState({
    this.banner,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  final BannerModel? banner;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  BannerEditorState copyWith({
    BannerModel? banner,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return BannerEditorState(
      banner: banner ?? this.banner,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }
}
