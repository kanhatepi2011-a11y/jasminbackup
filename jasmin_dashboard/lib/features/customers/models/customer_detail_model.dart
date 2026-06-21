class CustomerDetailModel {
  const CustomerDetailModel({required this.customer, required this.orders});
  final CustomerDetail customer;
  final List<CustomerOrderModel> orders;

  factory CustomerDetailModel.fromJson(Map<String, dynamic> json) => CustomerDetailModel(
        customer: CustomerDetail.fromJson(Map<String, dynamic>.from(json['customer'] as Map? ?? const {})),
        orders: (json['orders'] as List? ?? const <dynamic>[])
            .whereType<Map>()
            .map((item) => CustomerOrderModel.fromJson(Map<String, dynamic>.from(item)))
            .toList(),
      );
}

class CustomerDetail {
  const CustomerDetail({required this.key, this.email, this.phone, required this.totalOrders, required this.paidOrders, required this.lifetimeUsd, required this.banned, this.banReason});
  final String key;
  final String? email;
  final String? phone;
  final int totalOrders;
  final int paidOrders;
  final double lifetimeUsd;
  final bool banned;
  final String? banReason;

  String get label => email ?? phone ?? key;

  factory CustomerDetail.fromJson(Map<String, dynamic> json) => CustomerDetail(
        key: json['key']?.toString() ?? '',
        email: _nullable(json['email']),
        phone: _nullable(json['phone']),
        totalOrders: _intFrom(json['totalOrders']),
        paidOrders: _intFrom(json['paidOrders']),
        lifetimeUsd: _doubleFrom(json['lifetimeUsd']),
        banned: json['banned'] == true,
        banReason: _nullable(json['banReason']),
      );
}

class CustomerOrderModel {
  const CustomerOrderModel({required this.orderNumber, required this.status, required this.amountUsd, required this.playerUid, required this.playerNickname, required this.createdAt, required this.gameName, required this.productName});
  final String orderNumber;
  final String status;
  final double amountUsd;
  final String playerUid;
  final String? playerNickname;
  final DateTime? createdAt;
  final String? gameName;
  final String? productName;

  factory CustomerOrderModel.fromJson(Map<String, dynamic> json) {
    final game = json['game'];
    final product = json['product'];
    return CustomerOrderModel(
      orderNumber: json['orderNumber']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      amountUsd: _doubleFrom(json['amountUsd']),
      playerUid: json['playerUid']?.toString() ?? '',
      playerNickname: _nullable(json['playerNickname']),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      gameName: game is Map ? _nullable(game['name']) : null,
      productName: product is Map ? _nullable(product['name']) : null,
    );
  }
}

String? _nullable(dynamic value) { final text = value?.toString().trim() ?? ''; return text.isEmpty ? null : text; }
int _intFrom(dynamic value) => value is int ? value : value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
double _doubleFrom(dynamic value) => value is double ? value : value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;
