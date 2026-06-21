import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../models/banner_model.dart';
import '../models/banner_payload.dart';
import 'banners_api.dart';

final bannersRepositoryProvider = Provider<BannersRepository>((ref) {
  return BannersRepository(ref.watch(bannersApiProvider));
});

class BannersRepository {
  const BannersRepository(this._api);

  final BannersApi _api;

  Future<List<BannerModel>> fetchBanners() async {
    try {
      return await _api.fetchBanners();
    } on DioException catch (error) {
      throw _exceptionFromDio(error, 'Could not load banners. Check your connection and try again.');
    }
  }

  Future<BannerModel> fetchBanner(String id) async {
    try {
      return await _api.fetchBanner(id);
    } on DioException catch (error) {
      throw _exceptionFromDio(error, 'Could not load this banner.');
    }
  }

  Future<BannerModel> createBanner(BannerPayload payload) async {
    try {
      return await _api.createBanner(payload);
    } on DioException catch (error) {
      throw _exceptionFromDio(error, 'Could not create banner.');
    }
  }

  Future<BannerModel> updateBanner(String id, BannerPayload payload) async {
    try {
      return await _api.updateBanner(id, payload);
    } on DioException catch (error) {
      throw _exceptionFromDio(error, 'Could not update banner.');
    }
  }

  Future<BannerModel> setBannerActive(String id, bool active) async {
    try {
      return await _api.setBannerActive(id, active);
    } on DioException catch (error) {
      throw _exceptionFromDio(error, 'Could not update banner visibility.');
    }
  }

  Future<void> deleteBanner(String id) async {
    try {
      await _api.deleteBanner(id);
    } on DioException catch (error) {
      throw _exceptionFromDio(error, 'Could not delete banner.');
    }
  }

  AppException _exceptionFromDio(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map && data['error'] != null) {
      return AppException(data['error'].toString(), statusCode: error.response?.statusCode);
    }
    return AppException(fallback, statusCode: error.response?.statusCode);
  }
}
