class ProductPayload {
  const ProductPayload({
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
  });

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

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'gameId': gameId,
      'name': name,
      'amount': amount,
      'bonus': bonus,
      'priceUsd': priceUsd,
      'priceKhr': priceKhr,
      'badge': badge,
      'imageUrl': imageUrl,
      'active': active,
      'sortOrder': sortOrder,
      'supplierCode': supplierCode,
    };
  }
}
