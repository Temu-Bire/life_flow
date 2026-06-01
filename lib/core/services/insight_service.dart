import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/tasks/presentation/viewmodels/task_viewmodel.dart';
import '../../features/habits/presentation/viewmodels/habit_viewmodel.dart';
import '../../features/focus/presentation/viewmodels/focus_viewmodel.dart';
import '../../features/goals/presentation/viewmodels/goal_viewmodel.dart';
import '../../features/journal/presentation/viewmodels/journal_viewmodel.dart';

class ProductivityInsight {
  final String title;
  final String description;
  final String type; // 'warning', 'success', 'info', 'burnout'

  ProductivityInsight({
    required this.title,
    required this.description,
    required this.type,
  });
}

final insightProvider = Provider<List<ProductivityInsight>>((ref) {
  final tasks = ref.watch(taskListProvider);
  final habits = ref.watch(habitListProvider);
  final focusState = ref.watch(focusProvider);
  final goals = ref.watch(goalListProvider);
  final journals = ref.watch(journalListProvider);

  final List<ProductivityInsight> insights = [];

  // Rule 1: Streak warning
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  bool hasHabitDueTodayNotDone = false;
  for (var habit in habits) {
    if (habit.streak > 0 && !habit.isCompletedOn(today)) {
      hasHabitDueTodayNotDone = true;
    }
  }
  if (hasHabitDueTodayNotDone) {
    insights.add(ProductivityInsight(
      title: "Streak Risk Detected",
      description: "One or more active habits haven't been completed today. Complete them before midnight to maintain your streak!",
      type: "warning",
    ));
  }

  // Rule 2: Burnout Risk
  double weeklyFocusHours = 0;
  for (var session in focusState.history) {
    if (session.startTime.isAfter(now.subtract(const Duration(days: 7)))) {
      weeklyFocusHours += session.durationSeconds / 3600.0;
    }
  }
  if (weeklyFocusHours > 40) {
    insights.add(ProductivityInsight(
      title: "Burnout Risk Alert",
      description: "You have recorded ${weeklyFocusHours.toStringAsFixed(1)} hours of deep work this week. Remember to rest and recharge.",
      type: "burnout",
    ));
  } else if (weeklyFocusHours > 0) {
    insights.add(ProductivityInsight(
      title: "Solid Focus Performance",
      description: "You've spent ${weeklyFocusHours.toStringAsFixed(1)} hours in deep focus this week. Excellent dedication to your work!",
      type: "success",
    ));
  }

  // Rule 3: Goal Risk
  final activeGoals = goals.where((g) => !g.isCompleted).toList();
  bool goalsBehind = false;
  for (var goal in activeGoals) {
    if (goal.targetDate != null && goal.targetDate!.isBefore(now) && !goal.isCompleted) {
      goalsBehind = true;
    }
  }
  if (goalsBehind) {
    insights.add(ProductivityInsight(
      title: "Goal Completion Delayed",
      description: "Some of your targets have passed their expected target dates. Take time to adjust milestones and reschedule tasks.",
      type: "warning",
    ));
  }

  // Rule 4: Focus Time-of-Day Pattern
  int morningSessions = 0;
  int eveningSessions = 0;
  for (var session in focusState.history) {
    final hour = session.startTime.hour;
    if (hour >= 6 && hour < 12) {
      morningSessions++;
    } else if (hour >= 18 && hour < 24) {
      eveningSessions++;
    }
  }
  if (morningSessions > eveningSessions && morningSessions > 2) {
    insights.add(ProductivityInsight(
      title: "Peak Energy: Morning",
      description: "You complete most focus sessions between 8 AM and 12 PM. Use this block for your most critical/creative tasks.",
      type: "info",
    ));
  } else if (eveningSessions > morningSessions && eveningSessions > 2) {
    insights.add(ProductivityInsight(
      title: "Peak Energy: Night Owl",
      description: "Your focus sessions peak after 6 PM. Schedule high-cognitive tasks later in the day when your mind is most active.",
      type: "info",
    ));
  }

  // Rule 5: Habit Correlation
  final exerciseHabits = habits.where((h) => h.category.toLowerCase().contains("fitness") || h.name.toLowerCase().contains("exercise") || h.name.toLowerCase().contains("gym")).toList();
  final hasCompletedExerciseRecently = exerciseHabits.any((h) => h.history.any((d) => d.isAfter(now.subtract(const Duration(days: 2)))));
  if (hasCompletedExerciseRecently && weeklyFocusHours > 5) {
    insights.add(ProductivityInsight(
      title: "Exercise Focus Boost",
      description: "Nice job! Your exercise habits correlate with higher deep focus hours this week.",
      type: "success",
    ));
  }

  // Rule 6: Emotional Trend
  final recentLogs = journals.take(5).toList();
  final stressedLogs = recentLogs.where((l) => l.mood == "Stressed" || l.mood == "Angry").length;
  if (stressedLogs >= 3) {
    insights.add(ProductivityInsight(
      title: "High Stress Pattern",
      description: "Your recent journal entries reflect stress or frustration. Consider scheduling a dedicated rest block or wind-down habits.",
      type: "warning",
    ));
  }

  // Default fallback if no insights are generated
  if (insights.isEmpty) {
    insights.add(ProductivityInsight(
      title: "Building Momentum",
      description: "Keep tracking your tasks, habits, and focus sessions to unlock personalized productivity trends and suggestions.",
      type: "info",
    ));
  }

  return insights;
});
