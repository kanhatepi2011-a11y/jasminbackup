class PromoCodeModel {
  const PromoCodeModel({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.minOrderUsd,
    required this.maxUses,
    required this.usedCount,
    required this.active,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    required this.orderCount,
  });

  final String id;
  final String code;
  final String discountType;
  final double discountValue;
  final double minOrderUsd;
  final int maxUses;
  final int usedCount;
  final bool active;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int orderCount;

  bool get isPercent => discountType.toUpperCase() == 'PERCENT';
  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
  bool get isUsageLimited => maxUses > 0;
  bool get isFullyUsed => isUsageLimited && usedCount >= maxUses;
  bool get canBeUsed => active && !isExpired && !isFullyUsed;

  String get discountLabel => isPercent ? '${discountValue.toStringAsFixed(discountValue % 1 == 0 ? 0 : 2)}%' : r'$' '${discountValue.toStringAsFixed(2)}';

  factory PromoCodeModel.fromJson(Map<String, dynamic> json) {
    final count = json['_count'];
    return PromoCodeModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      discountType: json['discountType']?.toString() ?? 'PERCENT',
      discountValue: _doubleFrom(json['discountValue']),
      minOrderUsd: _doubleFrom(json['minOrderUsd']),
      maxUses: _intFrom(json['maxUses']),
      usedCount: _intFrom(json['usedCount']),
      active: json['active'] != false,
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
      orderCount: count is Map ? _intFrom(count['orders']) : _intFrom(json['orderCount']),
    );
  }

  static int _intFrom(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _doubleFrom(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
