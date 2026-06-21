class DashboardGameSummary {
  const DashboardGameSummary({
    required this.id,
    required this.name,
    required this.slug,
  });

  final String id;
  final String name;
  final String slug;

  factory DashboardGameSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DashboardGameSummary(id: '', name: 'Unknown game', slug: '');
    return DashboardGameSummary(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Unknown game').toString(),
      slug: (json['slug'] ?? '').toString(),
    );
  }
}
