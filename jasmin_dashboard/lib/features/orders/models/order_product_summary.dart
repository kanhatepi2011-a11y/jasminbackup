class OrderProductSummary {
  const OrderProductSummary({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory OrderProductSummary.fromJson(Map<String, dynamic>? json) {
    return OrderProductSummary(
      id: (json?['id'] ?? '').toString(),
      name: (json?['name'] ?? 'Unknown package').toString(),
    );
  }
}
