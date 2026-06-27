import 'order_game_summary.dart';
import 'order_product_summary.dart';

class OrderModel {
  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.playerUid,
    required this.serverId,
    required this.playerNickname,
    required this.customerEmail,
    required this.customerPhone,
    required this.amountUsd,
    required this.amountKhr,
    required this.currency,
    required this.paymentMethod,
    required this.paymentRef,
    required this.deliveryNote,
    required this.failureReason,
    required this.createdAt,
    required this.updatedAt,
    required this.paidAt,
    required this.deliveredAt,
    required this.game,
    required this.product,
  });

  final String id;
  final String orderNumber;
  final String status;
  final String playerUid;
  final String? serverId;
  final String? playerNickname;
  final String? customerEmail;
  final String? customerPhone;
  final double amountUsd;
  final double? amountKhr;
  final String currency;
  final String paymentMethod;
  final String? paymentRef;
  final String? deliveryNote;
  final String? failureReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? paidAt;
  final DateTime? deliveredAt;
  final OrderGameSummary game;
  final OrderProductSummary product;

  String get customerLabel {
    if (_hasText(playerNickname)) {
      return playerNickname!.trim();
    }
    if (_hasText(customerEmail)) {
      return customerEmail!.trim();
    }
    if (_hasText(customerPhone)) {
      return customerPhone!.trim();
    }
    if (playerUid.trim().isNotEmpty) {
      return playerUid.trim();
    }
    return 'Unknown customer';
  }

  String get uidLabel {
    if (!_hasText(serverId)) {
      return playerUid;
    }
    return '$playerUid ($serverId)';
  }

  bool get hasFailureReason => _hasText(failureReason);
  bool get hasDeliveryNote => _hasText(deliveryNote);

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: (json['id'] ?? '').toString(),
      orderNumber: (json['orderNumber'] ?? '').toString(),
      status: (json['status'] ?? 'PENDING').toString(),
      playerUid: (json['playerUid'] ?? '').toString(),
      serverId: _nullableString(json['serverId']),
      playerNickname: _nullableString(json['playerNickname']),
      customerEmail: _nullableString(json['customerEmail']),
      customerPhone: _nullableString(json['customerPhone']),
      amountUsd: _double(json['amountUsd']),
      amountKhr: _nullableDouble(json['amountKhr']),
      currency: (json['currency'] ?? 'USD').toString(),
      paymentMethod: (json['paymentMethod'] ?? '').toString(),
      paymentRef: _nullableString(json['paymentRef']),
      deliveryNote: _nullableString(json['deliveryNote']),
      failureReason: _nullableString(json['failureReason']),
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
      paidAt: _date(json['paidAt']),
      deliveredAt: _date(json['deliveredAt']),
      game: OrderGameSummary.fromJson(_mapOrNull(json['game'])),
      product: OrderProductSummary.fromJson(_mapOrNull(json['product'])),
    );
  }

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static double _double(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _nullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }

  static DateTime? _date(dynamic value) {
    final text = value?.toString();
    if (text == null || text.isEmpty) {
      return null;
    }
    return DateTime.tryParse(text)?.toLocal();
  }

  static Map<String, dynamic>? _mapOrNull(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }
}
