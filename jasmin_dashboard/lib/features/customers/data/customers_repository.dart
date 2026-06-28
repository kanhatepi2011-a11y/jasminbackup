import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/api_error_mapper.dart';
import '../models/customer_detail_model.dart';
import '../models/customers_response.dart';
import 'customers_api.dart';

final customersRepositoryProvider = Provider<CustomersRepository>(
    (ref) => CustomersRepository(ref.watch(customersApiProvider)));

class CustomersRepository {
  const CustomersRepository(this._api);
  final CustomersApi _api;

  Future<CustomersResponse> fetchCustomers({String? query}) async {
    try {
      return await _api.fetchCustomers(query: query);
    } on DioException catch (e) {
      throw _exception(e, 'Could not load customers.');
    }
  }

  Future<CustomerDetailModel> fetchCustomer(String key) async {
    try {
      return await _api.fetchCustomer(key);
    } on DioException catch (e) {
      throw _exception(e, 'Could not load customer detail.');
    }
  }

  Future<void> setBan(String key,
      {required bool banned, String? reason}) async {
    try {
      await _api.setBan(key, banned: banned, reason: reason);
    } on DioException catch (e) {
      throw _exception(
          e, banned ? 'Could not ban customer.' : 'Could not unban customer.');
    }
  }

  AppException _exception(DioException error, String fallback) {
    return mapDioError(error, fallback: fallback);
  }
}
