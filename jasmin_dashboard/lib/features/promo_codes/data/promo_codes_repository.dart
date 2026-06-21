import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../models/promo_code_model.dart';
import '../models/promo_code_payload.dart';
import 'promo_codes_api.dart';

final promoCodesRepositoryProvider = Provider<PromoCodesRepository>((ref) => PromoCodesRepository(ref.watch(promoCodesApiProvider)));

class PromoCodesRepository {
  const PromoCodesRepository(this._api);
  final PromoCodesApi _api;

  Future<List<PromoCodeModel>> fetchPromoCodes() async {
    try { return await _api.fetchPromoCodes(); } on DioException catch (e) { throw _exception(e, 'Could not load promo codes.'); }
  }
  Future<PromoCodeModel> fetchPromoCode(String id) async {
    try { return await _api.fetchPromoCode(id); } on DioException catch (e) { throw _exception(e, 'Could not load promo code.'); }
  }
  Future<PromoCodeModel> createPromoCode(PromoCodePayload payload) async {
    try { return await _api.createPromoCode(payload); } on DioException catch (e) { throw _exception(e, 'Could not create promo code.'); }
  }
  Future<PromoCodeModel> updatePromoCode(String id, PromoCodePayload payload) async {
    try { return await _api.updatePromoCode(id, payload); } on DioException catch (e) { throw _exception(e, 'Could not update promo code.'); }
  }
  Future<PromoCodeModel> setPromoCodeActive(String id, bool active) async {
    try { return await _api.setPromoCodeActive(id, active); } on DioException catch (e) { throw _exception(e, 'Could not update promo code status.'); }
  }
  Future<bool> deletePromoCode(String id) async {
    try { return await _api.deletePromoCode(id); } on DioException catch (e) { throw _exception(e, 'Could not delete promo code.'); }
  }

  AppException _exception(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map && data['error'] != null) return AppException(data['error'].toString(), statusCode: error.response?.statusCode);
    return AppException(fallback, statusCode: error.response?.statusCode);
  }
}
