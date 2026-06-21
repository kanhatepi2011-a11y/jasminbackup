class GamePayload {
  const GamePayload({
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
  });

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

  Map<String, dynamic> toJson() => <String, dynamic>{
        'slug': slug.trim(),
        'name': name.trim(),
        'publisher': publisher.trim(),
        'description': _nullable(description),
        'imageUrl': imageUrl.trim(),
        'bannerUrl': _nullable(bannerUrl) ?? '',
        'currencyName': currencyName.trim(),
        'uidLabel': uidLabel.trim().isEmpty ? 'Player ID' : uidLabel.trim(),
        'uidExample': _nullable(uidExample),
        'requiresServer': requiresServer,
        'servers': servers.trim().isEmpty ? '[]' : servers.trim(),
        'featured': featured,
        'active': active,
        'sortOrder': sortOrder,
        'seoTitle': _nullable(seoTitle),
        'seoDescription': _nullable(seoDescription),
      };

  static String? _nullable(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }
}
