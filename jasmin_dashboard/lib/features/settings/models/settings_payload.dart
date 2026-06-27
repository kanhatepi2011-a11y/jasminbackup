class SettingsPayload {
  const SettingsPayload({
    required this.siteName,
    required this.exchangeRate,
    required this.maintenanceMode,
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

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'siteName': siteName.trim(),
      'exchangeRate': exchangeRate,
      'supportTelegram': _clean(supportTelegram),
      'supportEmail': _clean(supportEmail),
      'maintenanceMode': maintenanceMode,
      'maintenanceMessage': _clean(maintenanceMessage),
      'announcement': _clean(announcement),
      'announcementTone': _clean(announcementTone),
      'logoUrl': _clean(logoUrl),
      'logoText': _clean(logoText),
      'logoTagline': _clean(logoTagline),
      if (telegramBotToken != null && telegramBotToken!.trim().isNotEmpty)
        'telegramBotToken': telegramBotToken!.trim(),
      'telegramChatId': _clean(telegramChatId),
    };
  }

  String? _clean(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }
}
