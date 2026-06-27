class CustomerSummaryModel {
  const CustomerSummaryModel({
    required this.key,
    required this.email,
    required this.phone,
    required this.nickname,
    required this.totalOrders,
    required this.paidOrders,
    required this.lifetimeUsd,
    required this.lastOrderAt,
    required this.uidCount,
  });

  final String key;
  final String? email;
  final String? phone;
  final String? nickname;
  final int totalOrders;
  final int paidOrders;
  final double lifetimeUsd;
  final DateTime? lastOrderAt;
  final int uidCount;

  String get displayName => nickname?.trim().isNotEmpty == true
      ? nickname!.trim()
      : email ?? phone ?? key;
  String get subtitle =>
      [email, phone].where((v) => v != null && v.trim().isNotEmpty).join(' • ');

  factory CustomerSummaryModel.fromJson(Map<String, dynamic> json) =>
      CustomerSummaryModel(
        key: json['key']?.toString() ?? '',
        email: _nullable(json['email']),
        phone: _nullable(json['phone']),
        nickname: _nullable(json['nickname']),
        totalOrders: _intFrom(json['totalOrders']),
        paidOrders: _intFrom(json['paidOrders']),
        lifetimeUsd: _doubleFrom(json['lifetimeUsd']),
        lastOrderAt: DateTime.tryParse(json['lastOrderAt']?.toString() ?? ''),
        uidCount: _intFrom(json['uidCount']),
      );

  static String? _nullable(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static int _intFrom(dynamic value) => value is int
      ? value
      : value is num
          ? value.toInt()
          : int.tryParse(value?.toString() ?? '') ?? 0;
  static double _doubleFrom(dynamic value) => value is double
      ? value
      : value is num
          ? value.toDouble()
          : double.tryParse(value?.toString() ?? '') ?? 0;
}
