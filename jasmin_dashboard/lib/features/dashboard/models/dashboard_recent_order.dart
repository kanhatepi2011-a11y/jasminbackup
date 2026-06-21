import 'dashboard_game_summary.dart';
import 'dashboard_product_summary.dart';

class DashboardRecentOrder {
  const DashboardRecentOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.playerUid,
    required this.playerNickname,
    required this.customerEmail,
    required this.customerPhone,
    required this.amountUsd,
    required this.amountKhr,
    required this.currency,
    required this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
    required this.game,
    required this.product,
  });

  final String id;
  final String orderNumber;
  final String status;
  final String playerUid;
  final String? playerNickname;
  final String? customerEmail;
  final String? customerPhone;
  final double amountUsd;
  final double? amountKhr;
  final String currency;
  final String paymentMethod;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DashboardGameSummary game;
  final DashboardProductSummary product;

  String get customerLabel {
    if (playerNickname != null && playerNickname!.trim().isNotEmpty) return playerNickname!.trim();
    if (customerEmail != null && customerEmail!.trim().isNotEmpty) return customerEmail!.trim();
    if (customerPhone != null && customerPhone!.trim().isNotEmpty) return customerPhone!.trim();
    if (playerUid.isNotEmpty) return playerUid;
    return 'Unknown customer';
  }

  factory DashboardRecentOrder.fromJson(Map<String, dynamic> json) {
    return DashboardRecentOrder(
      id: (json['id'] ?? '').toString(),
      orderNumber: (json['orderNumber'] ?? '').toString(),
      status: (json['status'] ?? 'PENDING').toString(),
      playerUid: (json['playerUid'] ?? '').toString(),
      playerNickname: _nullableString(json['playerNickname']),
      customerEmail: _nullableString(json['customerEmail']),
      customerPhone: _nullableString(json['customerPhone']),
      amountUsd: _double(json['amountUsd']),
      amountKhr: _nullableDouble(json['amountKhr']),
      currency: (json['currency'] ?? 'USD').toString(),
      paymentMethod: (json['paymentMethod'] ?? '').toString(),
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
      game: DashboardGameSummary.fromJson(_mapOrNull(json['game'])),
      product: DashboardProductSummary.fromJson(_mapOrNull(json['product'])),
    );
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static double _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _nullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static Map<String, dynamic>? _mapOrNull(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static DateTime? _date(dynamic value) {
    final text = value?.toString();
    if (text == null || text.isEmpty) return null;
    return DateTime.tryParse(text)?.toLocal();
  }
}
