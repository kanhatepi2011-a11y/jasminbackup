import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_client.dart';
import '../models/customer_detail_model.dart';
import '../models/customers_response.dart';

final customersApiProvider = Provider<CustomersApi>((ref) => CustomersApi(ref.watch(dioProvider)));

class CustomersApi {
  const CustomersApi(this._dio);
  final Dio _dio;

  Future<CustomersResponse> fetchCustomers({String? query}) async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.customers, queryParameters: <String, dynamic>{if (query != null && query.trim().isNotEmpty) 'q': query.trim()});
    return CustomersResponse.fromJson(response.data ?? const <String, dynamic>{});
  }

  Future<CustomerDetailModel> fetchCustomer(String key) async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.customerDetail(key));
    return CustomerDetailModel.fromJson(response.data ?? const <String, dynamic>{});
  }

  Future<void> setBan(String key, {required bool banned, String? reason}) async {
    await _dio.patch<Map<String, dynamic>>(ApiPaths.customerDetail(key), data: <String, dynamic>{'ban': banned, if (banned) 'reason': reason ?? ''});
  }
}
