import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../data/settings_repository.dart';
import '../models/settings_model.dart';
import '../models/settings_payload.dart';

final settingsProvider =
    StateNotifierProvider.autoDispose<SettingsController, SettingsState>((ref) {
  final controller = SettingsController(ref.watch(settingsRepositoryProvider));
  controller.load();
  return controller;
});

class SettingsController extends StateNotifier<SettingsState> {
  SettingsController(this._repository) : super(const SettingsState());

  final SettingsRepository _repository;

  Future<void> load() async {
    state =
        state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final settings = await _repository.fetchSettings();
      if (!mounted) {
        return;
      }
      state = state.copyWith(
          settings: settings, isLoading: false, clearError: true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      state = state.copyWith(
          isLoading: false, errorMessage: _messageFromError(error));
    }
  }

  Future<SettingsModel?> save(SettingsPayload payload) async {
    state =
        state.copyWith(isSaving: true, clearError: true, clearSuccess: true);
    try {
      final settings = await _repository.updateSettings(payload);
      if (!mounted) {
        return settings;
      }
      state = state.copyWith(
        settings: settings,
        isSaving: false,
        successMessage:
            'Website settings updated. JASMINTOPUP will refresh shortly.',
      );
      return settings;
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
      : 'Settings action failed. Please try again.';
}

class SettingsState {
  const SettingsState({
    this.settings,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  final SettingsModel? settings;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  SettingsState copyWith({
    SettingsModel? settings,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }
}
