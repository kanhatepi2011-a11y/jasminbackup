import 'product_game_summary.dart';

class ProductModel {
  const ProductModel({
    required this.id,
    required this.gameId,
    required this.name,
    required this.amount,
    required this.bonus,
    required this.priceUsd,
    required this.priceKhr,
    required this.badge,
    required this.imageUrl,
    required this.active,
    required this.sortOrder,
    required this.supplierCode,
    required this.createdAt,
    required this.updatedAt,
    required this.game,
    required this.ordersCount,
  });

  final String id;
  final String gameId;
  final String name;
  final int amount;
  final int bonus;
  final double priceUsd;
  final double? priceKhr;
  final String? badge;
  final String? imageUrl;
  final bool active;
  final int sortOrder;
  final String? supplierCode;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final ProductGameSummary game;
  final int ordersCount;

  String get amountLabel {
    if (bonus <= 0) return amount.toString();
    return '$amount + $bonus bonus';
  }

  bool get hasOrders => ordersCount > 0;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: (json['id'] ?? '').toString(),
      gameId: (json['gameId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      amount: _int(json['amount']),
      bonus: _int(json['bonus']),
      priceUsd: _double(json['priceUsd']),
      priceKhr: _nullableDouble(json['priceKhr']),
      badge: _nullableString(json['badge']),
      imageUrl: _nullableString(json['imageUrl']),
      active: json['active'] == true,
      sortOrder: _int(json['sortOrder']),
      supplierCode: _nullableString(json['supplierCode']),
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
      game: ProductGameSummary.fromJson(_mapOrNull(json['game'])),
      ordersCount: _ordersCount(json['_count']),
    );
  }

  static int _ordersCount(dynamic value) {
    if (value is Map && value['orders'] != null) return _int(value['orders']);
    return 0;
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
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

  static DateTime? _date(dynamic value) {
    final text = value?.toString();
    if (text == null || text.isEmpty) return null;
    return DateTime.tryParse(text)?.toLocal();
  }

  static Map<String, dynamic>? _mapOrNull(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}
