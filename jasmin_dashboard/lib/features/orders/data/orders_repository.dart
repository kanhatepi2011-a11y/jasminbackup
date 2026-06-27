import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../models/order_list_response.dart';
import '../models/order_model.dart';
import 'orders_api.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository(ref.watch(ordersApiProvider));
});

class OrdersRepository {
  const OrdersRepository(this._api);

  final OrdersApi _api;

  Future<OrderListResponse> fetchOrders({
    required int page,
    required int perPage,
    required String status,
    required String query,
  }) async {
    try {
      return await _api.fetchOrders(
          page: page, perPage: perPage, status: status, query: query);
    } on DioException catch (error) {
      throw _exceptionFromDio(
          error, 'Could not load orders. Check your connection and try again.');
    }
  }

  Future<OrderModel> fetchOrder(String orderNumber) async {
    try {
      return await _api.fetchOrder(orderNumber);
    } on DioException catch (error) {
      throw _exceptionFromDio(
          error, 'Could not load this order. Pull to refresh and try again.');
    }
  }

  Future<OrderModel> updateOrder({
    required String orderNumber,
    String? status,
    String? deliveryNote,
    String? failureReason,
    String? adminNote,
  }) async {
    try {
      return await _api.updateOrder(
        orderNumber: orderNumber,
        status: status,
        deliveryNote: deliveryNote,
        failureReason: failureReason,
        adminNote: adminNote,
      );
    } on DioException catch (error) {
      throw _exceptionFromDio(
          error, 'Could not update this order. Please try again.');
    }
  }

  AppException _exceptionFromDio(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['error'] ?? data['message'];
      if (message != null) {
        return AppException(message.toString(),
            statusCode: error.response?.statusCode);
      }
    }
    return AppException(fallback, statusCode: error.response?.statusCode);
  }
}
