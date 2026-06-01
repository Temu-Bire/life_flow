enum ReviewType { weekly, monthly, quarterly }

class ReviewModel {
  final String id;
  final DateTime date;
  final ReviewType type;
  final Map<String, String> answers; // Question -> Answer mapping
  final double growthScore; // 1.0 to 10.0 scale rating
  final String aiInsight; // Rules-based or model summary insights

  ReviewModel({
    required this.id,
    required this.date,
    required this.type,
    this.answers = const {},
    this.growthScore = 5.0,
    this.aiInsight = "",
  });

  ReviewModel copyWith({
    String? id,
    DateTime? date,
    ReviewType? type,
    Map<String, String>? answers,
    double? growthScore,
    String? aiInsight,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      answers: answers ?? this.answers,
      growthScore: growthScore ?? this.growthScore,
      aiInsight: aiInsight ?? this.aiInsight,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'type': type.name,
      'answers': answers,
      'growthScore': growthScore,
      'aiInsight': aiInsight,
    };
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      id: map['id'] as String,
      date: DateTime.tryParse(map['date'] as String) ?? DateTime.now(),
      type: ReviewType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ReviewType.weekly,
      ),
      answers: Map<String, String>.from(map['answers'] as Map? ?? {}),
      growthScore: (map['growthScore'] as num?)?.toDouble() ?? 5.0,
      aiInsight: map['aiInsight'] as String? ?? "",
    );
  }
}
