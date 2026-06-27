import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_client.dart';
import '../models/faq_model.dart';
import '../models/faq_payload.dart';

final faqsApiProvider = Provider<FaqsApi>((ref) {
  return FaqsApi(ref.watch(dioProvider));
});

class FaqsApi {
  const FaqsApi(this._dio);

  final Dio _dio;

  Future<List<FaqModel>> fetchFaqs() async {
    final response = await _dio.get<List<dynamic>>(ApiPaths.faqs);
    return (response.data ?? const <dynamic>[])
        .whereType<Map>()
        .map((item) => FaqModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<FaqModel> fetchFaq(String id) async {
    final response =
        await _dio.get<Map<String, dynamic>>(ApiPaths.faqDetail(id));
    return FaqModel.fromJson(response.data ?? const <String, dynamic>{});
  }

  Future<FaqModel> createFaq(FaqPayload payload) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.faqs,
      data: payload.toJson(),
    );
    return FaqModel.fromJson(response.data ?? const <String, dynamic>{});
  }

  Future<FaqModel> updateFaq(String id, FaqPayload payload) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      ApiPaths.faqDetail(id),
      data: payload.toJson(),
    );
    return FaqModel.fromJson(response.data ?? const <String, dynamic>{});
  }

  Future<FaqModel> setFaqActive(String id, bool active) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      ApiPaths.faqDetail(id),
      data: <String, dynamic>{'active': active},
    );
    return FaqModel.fromJson(response.data ?? const <String, dynamic>{});
  }

  Future<void> deleteFaq(String id) async {
    await _dio.delete<Map<String, dynamic>>(ApiPaths.faqDetail(id));
  }
}
