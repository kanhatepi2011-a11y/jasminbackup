class GameModel {
  const GameModel({
    required this.id,
    required this.slug,
    required this.name,
    required this.publisher,
    required this.description,
    required this.imageUrl,
    required this.bannerUrl,
    required this.currencyName,
    required this.uidLabel,
    required this.uidExample,
    required this.requiresServer,
    required this.servers,
    required this.featured,
    required this.active,
    required this.sortOrder,
    required this.seoTitle,
    required this.seoDescription,
    required this.createdAt,
    required this.updatedAt,
    required this.productsCount,
    required this.ordersCount,
  });

  final String id;
  final String slug;
  final String name;
  final String publisher;
  final String? description;
  final String imageUrl;
  final String? bannerUrl;
  final String currencyName;
  final String uidLabel;
  final String? uidExample;
  final bool requiresServer;
  final String servers;
  final bool featured;
  final bool active;
  final int sortOrder;
  final String? seoTitle;
  final String? seoDescription;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int productsCount;
  final int ordersCount;

  bool get hasProducts => productsCount > 0;
  bool get hasOrders => ordersCount > 0;
  bool get canDeleteHard => productsCount == 0 && ordersCount == 0;

  String get safeName => name.trim().isEmpty ? 'Untitled game' : name.trim();
  String get safeSlug => slug.trim().isEmpty ? 'no-slug' : slug.trim();
  String get imagePreviewUrl => imageUrl.trim();

  factory GameModel.fromJson(Map<String, dynamic> json) {
    return GameModel(
      id: (json['id'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      publisher: (json['publisher'] ?? '').toString(),
      description: _nullableString(json['description']),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      bannerUrl: _nullableString(json['bannerUrl']),
      currencyName: (json['currencyName'] ?? '').toString(),
      uidLabel: (json['uidLabel'] ?? 'Player ID').toString(),
      uidExample: _nullableString(json['uidExample']),
      requiresServer: json['requiresServer'] == true,
      servers: (json['servers'] ?? '[]').toString(),
      featured: json['featured'] == true,
      active: json['active'] == true,
      sortOrder: _int(json['sortOrder']),
      seoTitle: _nullableString(json['seoTitle']),
      seoDescription: _nullableString(json['seoDescription']),
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
      productsCount: _count(json['_count'], 'products'),
      ordersCount: _count(json['_count'], 'orders'),
    );
  }

  static int _count(dynamic value, String key) {
    if (value is Map && value[key] != null) return _int(value[key]);
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

  static DateTime? _date(dynamic value) {
    final text = value?.toString();
    if (text == null || text.isEmpty) return null;
    return DateTime.tryParse(text)?.toLocal();
  }
}
