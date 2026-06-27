import 'order_model.dart';

class OrderListResponse {
  const OrderListResponse({
    required this.orders,
    required this.total,
    required this.page,
    required this.perPage,
    required this.totalPages,
  });

  final List<OrderModel> orders;
  final int total;
  final int page;
  final int perPage;
  final int totalPages;

  factory OrderListResponse.fromJson(Map<String, dynamic> json) {
    final rawOrders = json['orders'];
    final orders = rawOrders is List
        ? rawOrders
            .whereType<Map>()
            .map((item) => OrderModel.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: false)
        : const <OrderModel>[];

    return OrderListResponse(
      orders: orders,
      total: _int(json['total']),
      page: _int(json['page'], fallback: 1),
      perPage: _int(json['perPage'], fallback: 25),
      totalPages: _int(json['totalPages'], fallback: 1),
    );
  }

  static int _int(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
