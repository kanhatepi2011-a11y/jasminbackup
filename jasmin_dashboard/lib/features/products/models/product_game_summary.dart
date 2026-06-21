class ProductGameSummary {
  const ProductGameSummary({
    required this.id,
    required this.name,
    required this.slug,
    required this.active,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final String slug;
  final bool active;
  final int sortOrder;

  factory ProductGameSummary.fromJson(Map<String, dynamic>? json) {
    final data = json ?? const <String, dynamic>{};
    return ProductGameSummary(
      id: (data['id'] ?? '').toString(),
      name: (data['name'] ?? 'Unknown game').toString(),
      slug: (data['slug'] ?? '').toString(),
      active: data['active'] == null ? true : data['active'] == true,
      sortOrder: _int(data['sortOrder']),
    );
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
