class SettingsModel {
  const SettingsModel({
    required this.siteName,
    required this.exchangeRate,
    required this.maintenanceMode,
    required this.updatedAt,
    this.supportTelegram,
    this.supportEmail,
    this.maintenanceMessage,
    this.announcement,
    this.announcementTone,
    this.logoUrl,
    this.logoText,
    this.logoTagline,
    this.telegramBotToken,
    this.telegramChatId,
  });

  final String siteName;
  final double exchangeRate;
  final String? supportTelegram;
  final String? supportEmail;
  final bool maintenanceMode;
  final String? maintenanceMessage;
  final String? announcement;
  final String? announcementTone;
  final String? logoUrl;
  final String? logoText;
  final String? logoTagline;
  final String? telegramBotToken;
  final String? telegramChatId;
  final DateTime? updatedAt;

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      siteName: json['siteName']?.toString() ?? 'JASMINTOPUP',
      exchangeRate: _doubleFrom(json['exchangeRate'], fallback: 4100),
      supportTelegram: _nullableString(json['supportTelegram']),
      supportEmail: _nullableString(json['supportEmail']),
      maintenanceMode: json['maintenanceMode'] == true,
      maintenanceMessage: _nullableString(json['maintenanceMessage']),
      announcement: _nullableString(json['announcement']),
      announcementTone: _nullableString(json['announcementTone']),
      logoUrl: _nullableString(json['logoUrl']),
      logoText: _nullableString(json['logoText']),
      logoTagline: _nullableString(json['logoTagline']),
      telegramBotToken: _nullableString(json['telegramBotToken']),
      telegramChatId: _nullableString(json['telegramChatId']),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  static double _doubleFrom(dynamic value, {required double fallback}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
