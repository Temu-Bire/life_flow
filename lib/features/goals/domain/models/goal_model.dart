class GoalMilestone {
  final String title;
  final bool isCompleted;

  GoalMilestone({
    required this.title,
    this.isCompleted = false,
  });

  GoalMilestone copyWith({
    String? title,
    bool? isCompleted,
  }) {
    return GoalMilestone(
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'isCompleted': isCompleted,
    };
  }

  factory GoalMilestone.fromMap(Map<String, dynamic> map) {
    return GoalMilestone(
      title: map['title'] as String,
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }
}

enum GoalTimeframe { vision, fiveYear, oneYear, quarterly, monthly, weekly }

enum GoalCategory {
  career,
  learning,
  finance,
  health,
  fitness,
  business,
  spiritual,
  relationships,
  personalGrowth
}

class GoalModel {
  final String id;
  final String title;
  final String description;
  final GoalCategory category;
  final GoalTimeframe timeframe;
  final String? parentId; // For tree hierarchy (e.g. 5-year goal parent of 1-year goal)
  final DateTime? targetDate;
  final bool isCompleted;
  final List<GoalMilestone> milestones;
  final List<String> linkedHabitIds;
  final List<String> linkedTaskIds;
  final List<String> imagePaths;
  final String notes;

  GoalModel({
    required this.id,
    required this.title,
    this.description = "",
    this.category = GoalCategory.personalGrowth,
    this.timeframe = GoalTimeframe.monthly,
    this.parentId,
    this.targetDate,
    this.isCompleted = false,
    this.milestones = const [],
    this.linkedHabitIds = const [],
    this.linkedTaskIds = const [],
    this.imagePaths = const [],
    this.notes = "",
  });

  double get milestoneProgress {
    if (milestones.isEmpty) return isCompleted ? 1.0 : 0.0;
    final completed = milestones.where((m) => m.isCompleted).length;
    return completed / milestones.length;
  }

  GoalModel copyWith({
    String? id,
    String? title,
    String? description,
    GoalCategory? category,
    GoalTimeframe? timeframe,
    String? parentId,
    DateTime? targetDate,
    bool? isCompleted,
    List<GoalMilestone>? milestones,
    List<String>? linkedHabitIds,
    List<String>? linkedTaskIds,
    List<String>? imagePaths,
    String? notes,
  }) {
    return GoalModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      timeframe: timeframe ?? this.timeframe,
      parentId: parentId ?? this.parentId,
      targetDate: targetDate ?? this.targetDate,
      isCompleted: isCompleted ?? this.isCompleted,
      milestones: milestones ?? this.milestones,
      linkedHabitIds: linkedHabitIds ?? this.linkedHabitIds,
      linkedTaskIds: linkedTaskIds ?? this.linkedTaskIds,
      imagePaths: imagePaths ?? this.imagePaths,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'timeframe': timeframe.name,
      'parentId': parentId,
      'targetDate': targetDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'milestones': milestones.map((e) => e.toMap()).toList(),
      'linkedHabitIds': linkedHabitIds,
      'linkedTaskIds': linkedTaskIds,
      'imagePaths': imagePaths,
      'notes': notes,
    };
  }

  factory GoalModel.fromMap(Map<String, dynamic> map) {
    return GoalModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? "",
      category: GoalCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => GoalCategory.personalGrowth,
      ),
      timeframe: GoalTimeframe.values.firstWhere(
        (e) => e.name == map['timeframe'],
        orElse: () => GoalTimeframe.monthly,
      ),
      parentId: map['parentId'] as String?,
      targetDate: map['targetDate'] != null ? DateTime.tryParse(map['targetDate'] as String) : null,
      isCompleted: map['isCompleted'] as bool? ?? false,
      milestones: (map['milestones'] as List? ?? [])
          .map((e) => GoalMilestone.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      linkedHabitIds: List<String>.from(map['linkedHabitIds'] as List? ?? []),
      linkedTaskIds: List<String>.from(map['linkedTaskIds'] as List? ?? []),
      imagePaths: List<String>.from(map['imagePaths'] as List? ?? []),
      notes: map['notes'] as String? ?? "",
    );
  }
}
