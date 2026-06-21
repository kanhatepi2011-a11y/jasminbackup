class AdminNotificationModel {
  const AdminNotificationModel({required this.id, required this.type, required this.title, required this.message, this.targetType, this.targetId, this.readAt, this.createdAt, this.updatedAt});
  final String id;
  final String type;
  final String title;
  final String message;
  final String? targetType;
  final String? targetId;
  final DateTime? readAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isRead => readAt != null;

  factory AdminNotificationModel.fromJson(Map<String, dynamic> json) => AdminNotificationModel(
        id: json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? 'notification',
        title: json['title']?.toString() ?? 'Notification',
        message: json['message']?.toString() ?? '',
        targetType: _nullable(json['targetType']),
        targetId: _nullable(json['targetId']),
        readAt: DateTime.tryParse(json['readAt']?.toString() ?? ''),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
      );
  static String? _nullable(dynamic value) { final text = value?.toString().trim() ?? ''; return text.isEmpty ? null : text; }
}
