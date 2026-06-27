import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../models/faq_model.dart';
import '../models/faq_payload.dart';
import 'faqs_api.dart';

final faqsRepositoryProvider = Provider<FaqsRepository>((ref) {
  return FaqsRepository(ref.watch(faqsApiProvider));
});

class FaqsRepository {
  const FaqsRepository(this._api);

  final FaqsApi _api;

  Future<List<FaqModel>> fetchFaqs() async {
    try {
      return await _api.fetchFaqs();
    } on DioException catch (error) {
      throw _exceptionFromDio(error, 'Could not load FAQ items.');
    }
  }

  Future<FaqModel> fetchFaq(String id) async {
    try {
      return await _api.fetchFaq(id);
    } on DioException catch (error) {
      throw _exceptionFromDio(error, 'Could not load this FAQ item.');
    }
  }

  Future<FaqModel> createFaq(FaqPayload payload) async {
    try {
      return await _api.createFaq(payload);
    } on DioException catch (error) {
      throw _exceptionFromDio(error, 'Could not create FAQ item.');
    }
  }

  Future<FaqModel> updateFaq(String id, FaqPayload payload) async {
    try {
      return await _api.updateFaq(id, payload);
    } on DioException catch (error) {
      throw _exceptionFromDio(error, 'Could not update FAQ item.');
    }
  }

  Future<FaqModel> setFaqActive(String id, bool active) async {
    try {
      return await _api.setFaqActive(id, active);
    } on DioException catch (error) {
      throw _exceptionFromDio(error, 'Could not update FAQ visibility.');
    }
  }

  Future<void> deleteFaq(String id) async {
    try {
      await _api.deleteFaq(id);
    } on DioException catch (error) {
      throw _exceptionFromDio(error, 'Could not delete FAQ item.');
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
