class FocusSessionModel {
  final String id;
  final DateTime startTime;
  final int durationSeconds;
  final String? taskId;
  final String? goalId;
  final int qualityScore; // 1 to 5
  final String notes;

  FocusSessionModel({
    required this.id,
    required this.startTime,
    required this.durationSeconds,
    this.taskId,
    this.goalId,
    this.qualityScore = 3,
    this.notes = "",
  });

  FocusSessionModel copyWith({
    String? id,
    DateTime? startTime,
    int? durationSeconds,
    String? taskId,
    String? goalId,
    int? qualityScore,
    String? notes,
  }) {
    return FocusSessionModel(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      taskId: taskId ?? this.taskId,
      goalId: goalId ?? this.goalId,
      qualityScore: qualityScore ?? this.qualityScore,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'durationSeconds': durationSeconds,
      'taskId': taskId,
      'goalId': goalId,
      'qualityScore': qualityScore,
      'notes': notes,
    };
  }

  factory FocusSessionModel.fromMap(Map<String, dynamic> map) {
    return FocusSessionModel(
      id: map['id'] as String,
      startTime: DateTime.tryParse(map['startTime'] as String) ?? DateTime.now(),
      durationSeconds: map['durationSeconds'] as int? ?? 0,
      taskId: map['taskId'] as String?,
      goalId: map['goalId'] as String?,
      qualityScore: map['qualityScore'] as int? ?? 3,
      notes: map['notes'] as String? ?? "",
    );
  }
}
