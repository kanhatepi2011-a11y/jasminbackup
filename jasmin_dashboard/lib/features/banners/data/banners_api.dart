import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_client.dart';
import '../models/banner_model.dart';
import '../models/banner_payload.dart';

final bannersApiProvider = Provider<BannersApi>((ref) {
  return BannersApi(ref.watch(dioProvider));
});

class BannersApi {
  const BannersApi(this._dio);

  final Dio _dio;

  Future<List<BannerModel>> fetchBanners() async {
    final response = await _dio.get<List<dynamic>>(ApiPaths.banners);
    return (response.data ?? const <dynamic>[])
        .whereType<Map>()
        .map((item) => BannerModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<BannerModel> fetchBanner(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.bannerDetail(id));
    return BannerModel.fromJson(response.data ?? const <String, dynamic>{});
  }

  Future<BannerModel> createBanner(BannerPayload payload) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.banners,
      data: payload.toJson(),
    );
    return BannerModel.fromJson(response.data ?? const <String, dynamic>{});
  }

  Future<BannerModel> updateBanner(String id, BannerPayload payload) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      ApiPaths.bannerDetail(id),
      data: payload.toJson(),
    );
    return BannerModel.fromJson(response.data ?? const <String, dynamic>{});
  }

  Future<BannerModel> setBannerActive(String id, bool active) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      ApiPaths.bannerDetail(id),
      data: <String, dynamic>{'active': active},
    );
    return BannerModel.fromJson(response.data ?? const <String, dynamic>{});
  }

  Future<void> deleteBanner(String id) async {
    await _dio.delete<Map<String, dynamic>>(ApiPaths.bannerDetail(id));
  }
}
