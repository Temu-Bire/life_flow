class HabitModel {
  final String id;
  final String name;
  final String frequency; // Daily, Weekly, Custom
  final String category; // Health, Mind, Fitness, Work, Financial
  final List<DateTime> history; // Check-in log history
  final bool isPositive; // Positive or negative habit
  final int streak;
  final int longestStreak;
  final double consistencyScore;
  final String? goalId;

  HabitModel({
    required this.id,
    required this.name,
    this.frequency = "Daily",
    this.category = "Health",
    this.history = const [],
    this.isPositive = true,
    this.streak = 0,
    this.longestStreak = 0,
    this.consistencyScore = 0.0,
    this.goalId,
  });

  bool isCompletedOn(DateTime date) {
    return history.any((d) => d.year == date.year && d.month == date.month && d.day == date.day);
  }

  HabitModel copyWith({
    String? id,
    String? name,
    String? frequency,
    String? category,
    List<DateTime>? history,
    bool? isPositive,
    int? streak,
    int? longestStreak,
    double? consistencyScore,
    String? goalId,
  }) {
    return HabitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      frequency: frequency ?? this.frequency,
      category: category ?? this.category,
      history: history ?? this.history,
      isPositive: isPositive ?? this.isPositive,
      streak: streak ?? this.streak,
      longestStreak: longestStreak ?? this.longestStreak,
      consistencyScore: consistencyScore ?? this.consistencyScore,
      goalId: goalId ?? this.goalId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'frequency': frequency,
      'category': category,
      'history': history.map((e) => e.toIso8601String()).toList(),
      'isPositive': isPositive,
      'streak': streak,
      'longestStreak': longestStreak,
      'consistencyScore': consistencyScore,
      'goalId': goalId,
    };
  }

  factory HabitModel.fromMap(Map<String, dynamic> map) {
    return HabitModel(
      id: map['id'] as String,
      name: map['name'] as String,
      frequency: map['frequency'] as String? ?? "Daily",
      category: map['category'] as String? ?? "Health",
      history: (map['history'] as List? ?? [])
          .map((e) => DateTime.tryParse(e as String))
          .whereType<DateTime>()
          .toList(),
      isPositive: map['isPositive'] as bool? ?? true,
      streak: map['streak'] as int? ?? 0,
      longestStreak: map['longestStreak'] as int? ?? 0,
      consistencyScore: (map['consistencyScore'] as num?)?.toDouble() ?? 0.0,
      goalId: map['goalId'] as String?,
    );
  }
}
