import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_client.dart';
import '../models/promo_code_model.dart';
import '../models/promo_code_payload.dart';

final promoCodesApiProvider = Provider<PromoCodesApi>((ref) => PromoCodesApi(ref.watch(dioProvider)));

class PromoCodesApi {
  const PromoCodesApi(this._dio);
  final Dio _dio;

  Future<List<PromoCodeModel>> fetchPromoCodes() async {
    final response = await _dio.get<List<dynamic>>(ApiPaths.promoCodes);
    return (response.data ?? const <dynamic>[])
        .whereType<Map>()
        .map((item) => PromoCodeModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<PromoCodeModel> fetchPromoCode(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.promoCodeDetail(id));
    return PromoCodeModel.fromJson(response.data ?? const <String, dynamic>{});
  }

  Future<PromoCodeModel> createPromoCode(PromoCodePayload payload) async {
    final response = await _dio.post<Map<String, dynamic>>(ApiPaths.promoCodes, data: payload.toJson());
    return PromoCodeModel.fromJson(response.data ?? const <String, dynamic>{});
  }

  Future<PromoCodeModel> updatePromoCode(String id, PromoCodePayload payload) async {
    final response = await _dio.patch<Map<String, dynamic>>(ApiPaths.promoCodeDetail(id), data: payload.toJson());
    return PromoCodeModel.fromJson(response.data ?? const <String, dynamic>{});
  }

  Future<PromoCodeModel> setPromoCodeActive(String id, bool active) async {
    final response = await _dio.patch<Map<String, dynamic>>(ApiPaths.promoCodeDetail(id), data: <String, dynamic>{'active': active});
    return PromoCodeModel.fromJson(response.data ?? const <String, dynamic>{});
  }

  Future<bool> deletePromoCode(String id) async {
    final response = await _dio.delete<Map<String, dynamic>>(ApiPaths.promoCodeDetail(id));
    return response.data?['deleted'] == true;
  }
}
