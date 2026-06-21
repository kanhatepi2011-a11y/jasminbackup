import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_client.dart';
import '../models/settings_model.dart';
import '../models/settings_payload.dart';

final settingsApiProvider = Provider<SettingsApi>((ref) {
  return SettingsApi(ref.watch(dioProvider));
});

class SettingsApi {
  const SettingsApi(this._dio);

  final Dio _dio;

  Future<SettingsModel> fetchSettings() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.settings);
    return SettingsModel.fromJson(response.data ?? const <String, dynamic>{});
  }

  Future<SettingsModel> updateSettings(SettingsPayload payload) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      ApiPaths.settings,
      data: payload.toJson(),
    );
    return SettingsModel.fromJson(response.data ?? const <String, dynamic>{});
  }
}
