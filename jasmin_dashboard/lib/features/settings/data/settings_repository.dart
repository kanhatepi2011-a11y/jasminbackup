import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/api_error_mapper.dart';
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
    return mapDioError(error, fallback: fallback);
  }
}
