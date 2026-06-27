class BannerModel {
  const BannerModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.active,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.subtitle,
    this.linkUrl,
    this.ctaLabel,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String imageUrl;
  final String? linkUrl;
  final String? ctaLabel;
  final bool active;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get safeTitle =>
      title.trim().isEmpty ? 'Untitled banner' : title.trim();
  bool get hasLink => linkUrl != null && linkUrl!.trim().isNotEmpty;
  bool get hasCta => ctaLabel != null && ctaLabel!.trim().isNotEmpty;

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: _nullableString(json['subtitle']),
      imageUrl: json['imageUrl']?.toString() ?? '',
      linkUrl: _nullableString(json['linkUrl']),
      ctaLabel: _nullableString(json['ctaLabel']),
      active: json['active'] != false,
      sortOrder: _intFrom(json['sortOrder']),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static int _intFrom(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
