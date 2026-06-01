class SubTask {
  final String title;
  final bool isCompleted;

  SubTask({
    required this.title,
    this.isCompleted = false,
  });

  SubTask copyWith({
    String? title,
    bool? isCompleted,
  }) {
    return SubTask(
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

  factory SubTask.fromMap(Map<String, dynamic> map) {
    return SubTask(
      title: map['title'] as String,
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }
}

enum TaskPriority { low, medium, high, critical }

class TaskModel {
  final String id;
  final String title;
  final String notes;
  final TaskPriority priority;
  final String category;
  final DateTime? dueDate;
  final bool isCompleted;
  final bool isArchived;
  final List<SubTask> subtasks;
  final bool isRecurring;
  final String recurrence; // None, Daily, Weekly, Monthly
  final int focusTimeSpent; // in seconds
  final int position;
  final String? goalId;
  final DateTime? scheduledStartTime;
  final int? scheduledDuration; // in minutes

  TaskModel({
    required this.id,
    required this.title,
    this.notes = "",
    this.priority = TaskPriority.medium,
    this.category = "Inbox",
    this.dueDate,
    this.isCompleted = false,
    this.isArchived = false,
    this.subtasks = const [],
    this.isRecurring = false,
    this.recurrence = "None",
    this.focusTimeSpent = 0,
    this.position = 0,
    this.goalId,
    this.scheduledStartTime,
    this.scheduledDuration,
  });

  double get progressPercentage {
    if (subtasks.isEmpty) return isCompleted ? 1.0 : 0.0;
    final completedCount = subtasks.where((e) => e.isCompleted).length;
    return completedCount / subtasks.length;
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? notes,
    TaskPriority? priority,
    String? category,
    DateTime? dueDate,
    bool? isCompleted,
    bool? isArchived,
    List<SubTask>? subtasks,
    bool? isRecurring,
    String? recurrence,
    int? focusTimeSpent,
    int? position,
    String? goalId,
    DateTime? scheduledStartTime,
    int? scheduledDuration,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      isArchived: isArchived ?? this.isArchived,
      subtasks: subtasks ?? this.subtasks,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrence: recurrence ?? this.recurrence,
      focusTimeSpent: focusTimeSpent ?? this.focusTimeSpent,
      position: position ?? this.position,
      goalId: goalId ?? this.goalId,
      scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
      scheduledDuration: scheduledDuration ?? this.scheduledDuration,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'notes': notes,
      'priority': priority.name,
      'category': category,
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'isArchived': isArchived,
      'subtasks': subtasks.map((e) => e.toMap()).toList(),
      'isRecurring': isRecurring,
      'recurrence': recurrence,
      'focusTimeSpent': focusTimeSpent,
      'position': position,
      'goalId': goalId,
      'scheduledStartTime': scheduledStartTime?.toIso8601String(),
      'scheduledDuration': scheduledDuration,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      title: map['title'] as String,
      notes: map['notes'] as String? ?? "",
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => TaskPriority.medium,
      ),
      category: map['category'] as String? ?? "Inbox",
      dueDate: map['dueDate'] != null ? DateTime.tryParse(map['dueDate'] as String) : null,
      isCompleted: map['isCompleted'] as bool? ?? false,
      isArchived: map['isArchived'] as bool? ?? false,
      subtasks: (map['subtasks'] as List? ?? [])
          .map((e) => SubTask.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      isRecurring: map['isRecurring'] as bool? ?? false,
      recurrence: map['recurrence'] as String? ?? "None",
      focusTimeSpent: map['focusTimeSpent'] as int? ?? 0,
      position: map['position'] as int? ?? 0,
      goalId: map['goalId'] as String?,
      scheduledStartTime: map['scheduledStartTime'] != null
          ? DateTime.tryParse(map['scheduledStartTime'] as String)
          : null,
      scheduledDuration: map['scheduledDuration'] as int?,
    );
  }
}
