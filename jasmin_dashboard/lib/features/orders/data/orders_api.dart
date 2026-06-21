import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_client.dart';
import '../models/order_list_response.dart';
import '../models/order_model.dart';

final ordersApiProvider = Provider<OrdersApi>((ref) {
  return OrdersApi(ref.watch(dioProvider));
});

class OrdersApi {
  const OrdersApi(this._dio);

  final Dio _dio;

  Future<OrderListResponse> fetchOrders({
    required int page,
    required int perPage,
    String status = 'ALL',
    String query = '',
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.orders,
      queryParameters: {
        'page': page,
        'perPage': perPage,
        if (status != 'ALL') 'status': status,
        if (query.trim().isNotEmpty) 'q': query.trim(),
      },
    );

    return OrderListResponse.fromJson(response.data ?? const <String, dynamic>{});
  }

  Future<OrderModel> fetchOrder(String orderNumber) async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.orderDetail(orderNumber));
    return OrderModel.fromJson(response.data ?? const <String, dynamic>{});
  }

  Future<OrderModel> updateOrder({
    required String orderNumber,
    String? status,
    String? deliveryNote,
    String? failureReason,
    String? adminNote,
  }) async {
    final body = <String, dynamic>{
      if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
      if (deliveryNote != null) 'deliveryNote': deliveryNote.trim(),
      if (failureReason != null) 'failureReason': failureReason.trim(),
      if (adminNote != null && adminNote.trim().isNotEmpty) 'adminNote': adminNote.trim(),
    };

    final response = await _dio.patch<Map<String, dynamic>>(
      ApiPaths.orderDetail(orderNumber),
      data: body,
    );

    return OrderModel.fromJson(response.data ?? const <String, dynamic>{});
  }
}
