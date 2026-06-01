import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/database_service.dart';
import '../../domain/models/goal_model.dart';

final goalListProvider = StateNotifierProvider<GoalViewModel, List<GoalModel>>((ref) {
  return GoalViewModel();
});

class GoalViewModel extends StateNotifier<List<GoalModel>> {
  final DatabaseService _db = DatabaseService.instance;
  final Uuid _uuid = const Uuid();

  GoalViewModel() : super([]) {
    _loadGoals();
  }

  void _loadGoals() {
    final raw = _db.getAllGoals();
    final goals = raw.map((e) => GoalModel.fromMap(e)).toList();
    state = goals;
  }

  Future<void> addGoal({
    required String title,
    String description = "",
    GoalCategory category = GoalCategory.personalGrowth,
    GoalTimeframe timeframe = GoalTimeframe.monthly,
    String? parentId,
    DateTime? targetDate,
    List<GoalMilestone> milestones = const [],
    List<String> linkedHabitIds = const [],
    List<String> linkedTaskIds = const [],
    List<String> imagePaths = const [],
    String notes = "",
  }) async {
    final newGoal = GoalModel(
      id: _uuid.v4(),
      title: title,
      description: description,
      category: category,
      timeframe: timeframe,
      parentId: parentId,
      targetDate: targetDate,
      milestones: milestones,
      linkedHabitIds: linkedHabitIds,
      linkedTaskIds: linkedTaskIds,
      imagePaths: imagePaths,
      notes: notes,
    );

    state = [...state, newGoal];
    await _db.saveGoal(newGoal.id, newGoal.toMap());
  }

  Future<void> updateGoal(GoalModel updatedGoal) async {
    state = [
      for (final goal in state)
        if (goal.id == updatedGoal.id) updatedGoal else goal
    ];
    await _db.saveGoal(updatedGoal.id, updatedGoal.toMap());
  }

  Future<void> deleteGoal(String id) async {
    // If deleted goal has children, remove their parentId pointer
    state = state.map((g) => g.parentId == id ? g.copyWith(parentId: null) : g).toList();
    for (final g in state) {
      if (g.parentId == null) {
        await _db.saveGoal(g.id, g.toMap());
      }
    }

    state = state.where((goal) => goal.id != id).toList();
    await _db.deleteGoal(id);
  }

  Future<void> toggleMilestone(String goalId, int milestoneIndex) async {
    final goalIdx = state.indexWhere((g) => g.id == goalId);
    if (goalIdx != -1) {
      final goal = state[goalIdx];
      final updatedMilestones = List<GoalMilestone>.from(goal.milestones);
      final milestone = updatedMilestones[milestoneIndex];
      
      updatedMilestones[milestoneIndex] = milestone.copyWith(
        isCompleted: !milestone.isCompleted,
      );

      // If all milestones completed, mark the goal completed
      final bool allCompleted = updatedMilestones.every((m) => m.isCompleted);

      final updatedGoal = goal.copyWith(
        milestones: updatedMilestones,
        isCompleted: allCompleted ? true : goal.isCompleted,
      );

      state = [
        for (int i = 0; i < state.length; i++)
          if (i == goalIdx) updatedGoal else state[i]
      ];
      await _db.saveGoal(updatedGoal.id, updatedGoal.toMap());
    }
  }

  Future<void> addMilestone(String goalId, String milestoneTitle) async {
    final goalIdx = state.indexWhere((g) => g.id == goalId);
    if (goalIdx != -1) {
      final goal = state[goalIdx];
      final updatedMilestones = [
        ...goal.milestones,
        GoalMilestone(title: milestoneTitle, isCompleted: false),
      ];

      final updatedGoal = goal.copyWith(milestones: updatedMilestones);
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == goalIdx) updatedGoal else state[i]
      ];
      await _db.saveGoal(updatedGoal.id, updatedGoal.toMap());
    }
  }

  Future<void> toggleGoalCompleted(String goalId) async {
    final goalIdx = state.indexWhere((g) => g.id == goalId);
    if (goalIdx != -1) {
      final goal = state[goalIdx];
      final toggled = goal.copyWith(isCompleted: !goal.isCompleted);
      
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == goalIdx) toggled else state[i]
      ];
      await _db.saveGoal(toggled.id, toggled.toMap());
    }
  }

  Future<void> linkTaskToGoal(String goalId, String taskId) async {
    final goalIdx = state.indexWhere((g) => g.id == goalId);
    if (goalIdx != -1) {
      final goal = state[goalIdx];
      if (!goal.linkedTaskIds.contains(taskId)) {
        final updatedGoal = goal.copyWith(
          linkedTaskIds: [...goal.linkedTaskIds, taskId],
        );
        state = [
          for (int i = 0; i < state.length; i++)
            if (i == goalIdx) updatedGoal else state[i]
        ];
        await _db.saveGoal(updatedGoal.id, updatedGoal.toMap());
      }
    }
  }

  Future<void> linkHabitToGoal(String goalId, String habitId) async {
    final goalIdx = state.indexWhere((g) => g.id == goalId);
    if (goalIdx != -1) {
      final goal = state[goalIdx];
      if (!goal.linkedHabitIds.contains(habitId)) {
        final updatedGoal = goal.copyWith(
          linkedHabitIds: [...goal.linkedHabitIds, habitId],
        );
        state = [
          for (int i = 0; i < state.length; i++)
            if (i == goalIdx) updatedGoal else state[i]
        ];
        await _db.saveGoal(updatedGoal.id, updatedGoal.toMap());
      }
    }
  }
}
