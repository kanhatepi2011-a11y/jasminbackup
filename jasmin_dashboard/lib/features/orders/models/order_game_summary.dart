class OrderGameSummary {
  const OrderGameSummary({
    required this.id,
    required this.name,
    required this.slug,
  });

  final String id;
  final String name;
  final String slug;

  factory OrderGameSummary.fromJson(Map<String, dynamic>? json) {
    return OrderGameSummary(
      id: (json?['id'] ?? '').toString(),
      name: (json?['name'] ?? 'Unknown game').toString(),
      slug: (json?['slug'] ?? '').toString(),
    );
  }
}
