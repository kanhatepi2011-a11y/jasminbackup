class FaqPayload {
  const FaqPayload({
    required this.question,
    required this.answer,
    required this.category,
    required this.active,
    required this.sortOrder,
  });

  final String question;
  final String answer;
  final String category;
  final bool active;
  final int sortOrder;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'question': question.trim(),
      'answer': answer.trim(),
      'category': category.trim().isEmpty ? 'general' : category.trim(),
      'active': active,
      'sortOrder': sortOrder,
    };
  }
}
