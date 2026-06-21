class BannerPayload {
  const BannerPayload({
    required this.title,
    required this.imageUrl,
    required this.active,
    required this.sortOrder,
    this.subtitle,
    this.linkUrl,
    this.ctaLabel,
  });

  final String title;
  final String? subtitle;
  final String imageUrl;
  final String? linkUrl;
  final String? ctaLabel;
  final bool active;
  final int sortOrder;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title.trim(),
      'subtitle': _clean(subtitle),
      'imageUrl': imageUrl.trim(),
      'linkUrl': _clean(linkUrl),
      'ctaLabel': _clean(ctaLabel),
      'active': active,
      'sortOrder': sortOrder,
    };
  }

  String? _clean(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }
}
