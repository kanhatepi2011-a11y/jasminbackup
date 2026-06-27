import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../models/settings_model.dart';
import '../models/settings_payload.dart';
import 'settings_api.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(settingsApiProvider));
});

class SettingsRepository {
  const SettingsRepository(this._api);

  final SettingsApi _api;

  Future<SettingsModel> fetchSettings() async {
    try {
      return await _api.fetchSettings();
    } on DioException catch (error) {
      throw _exceptionFromDio(error, 'Could not load website settings.');
    }
  }

  Future<SettingsModel> updateSettings(SettingsPayload payload) async {
    try {
      return await _api.updateSettings(payload);
    } on DioException catch (error) {
      throw _exceptionFromDio(error, 'Could not update website settings.');
    }
  }

  AppException _exceptionFromDio(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map && data['error'] != null) {
      return AppException(data['error'].toString(),
          statusCode: error.response?.statusCode);
    }
    return AppException(fallback, statusCode: error.response?.statusCode);
  }
}
