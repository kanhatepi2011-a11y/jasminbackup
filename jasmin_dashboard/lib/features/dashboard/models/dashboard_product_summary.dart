class DashboardProductSummary {
  const DashboardProductSummary({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory DashboardProductSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DashboardProductSummary(id: '', name: 'Unknown package');
    return DashboardProductSummary(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Unknown package').toString(),
    );
  }
}
