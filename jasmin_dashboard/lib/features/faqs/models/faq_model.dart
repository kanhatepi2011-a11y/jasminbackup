class FaqModel {
  const FaqModel({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    required this.active,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String question;
  final String answer;
  final String category;
  final bool active;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get safeQuestion => question.trim().isEmpty ? 'Untitled FAQ' : question.trim();

  factory FaqModel.fromJson(Map<String, dynamic> json) {
    return FaqModel(
      id: json['id']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
      category: json['category']?.toString() ?? 'general',
      active: json['active'] != false,
      sortOrder: _intFrom(json['sortOrder']),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  static int _intFrom(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
