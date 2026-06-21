class PromoCodePayload {
  const PromoCodePayload({
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.minOrderUsd,
    required this.maxUses,
    required this.expiresAt,
    required this.active,
  });

  final String code;
  final String discountType;
  final double discountValue;
  final double minOrderUsd;
  final int maxUses;
  final DateTime? expiresAt;
  final bool active;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'code': code.trim().toUpperCase(),
      'discountType': discountType,
      'discountValue': discountValue,
      'minOrderUsd': minOrderUsd,
      'maxUses': maxUses,
      'expiresAt': expiresAt?.toIso8601String(),
      'active': active,
    };
  }
}
