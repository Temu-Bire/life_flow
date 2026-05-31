import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../tasks/presentation/viewmodels/task_viewmodel.dart';
import '../../../habits/presentation/viewmodels/habit_viewmodel.dart';
import '../../../journal/presentation/viewmodels/journal_viewmodel.dart';

class ProductivityStats {
  final int completedTasksCount;
  final int totalTasksCount;
  final double taskCompletionRate;
  
  final int completedHabitsToday;
  final int totalHabitsCount;
  final double habitCompletionRate;

  final int activeHabitStreak;
  final double productivityScore; // 0 to 100
  
  final double weeklyFocusHours;
  final Map<String, int> moodDistribution; // Mood to count

  ProductivityStats({
    required this.completedTasksCount,
    required this.totalTasksCount,
    required this.taskCompletionRate,
    required this.completedHabitsToday,
    required this.totalHabitsCount,
    required this.habitCompletionRate,
    required this.activeHabitStreak,
    required this.productivityScore,
    required this.weeklyFocusHours,
    required this.moodDistribution,
  });
}

final analyticsProvider = Provider<ProductivityStats>((ref) {
  final tasks = ref.watch(taskListProvider);
  final habits = ref.watch(habitListProvider);
  final journalEntries = ref.watch(journalListProvider);

  // 1. Task Metrics
  final activeTasks = tasks.where((t) => !t.isArchived).toList();
  final completedTasks = activeTasks.where((t) => t.isCompleted).toList();
  final totalTasksCount = activeTasks.length;
  final completedTasksCount = completedTasks.length;
  final taskCompletionRate = totalTasksCount > 0 ? completedTasksCount / totalTasksCount : 0.0;

  // 2. Habit Metrics
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final completedHabits = habits.where((h) => h.isCompletedOn(today)).toList();
  final totalHabitsCount = habits.length;
  final completedHabitsToday = completedHabits.length;
  final habitCompletionRate = totalHabitsCount > 0 ? completedHabitsToday / totalHabitsCount : 0.0;

  int activeHabitStreak = 0;
  if (habits.isNotEmpty) {
    activeHabitStreak = habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b);
  }

  // 3. Weekly Focus Hours (from Pomodoro focusTimeSpent on tasks)
  int totalFocusSeconds = 0;
  for (var task in tasks) {
    totalFocusSeconds += task.focusTimeSpent;
  }
  final double weeklyFocusHours = totalFocusSeconds / 3600.0;

  // 4. Mood distribution (from journal logs)
  final Map<String, int> moodDistribution = {
    'Happy': 0, 'Calm': 0, 'Neutral': 0, 'Sad': 0, 'Angry': 0, 'Stressed': 0
  };
  for (var entry in journalEntries) {
    if (moodDistribution.containsKey(entry.mood)) {
      moodDistribution[entry.mood] = moodDistribution[entry.mood]! + 1;
    }
  }

  // 5. Composite Productivity Score Formula (0 to 100)
  // Weighting: 40% task rate, 40% habits, 20% journaling activity
  double taskWeight = taskCompletionRate * 40;
  double habitWeight = habitCompletionRate * 40;
  
  // Journaling: completed at least 3 logs in last week
  final sevenDaysAgo = today.subtract(const Duration(days: 7));
  final logsLastWeek = journalEntries.where((e) => e.date.isAfter(sevenDaysAgo)).length;
  double journalWeight = (logsLastWeek / 3.0).clamp(0.0, 1.0) * 20;

  double productivityScore = taskWeight + habitWeight + journalWeight;
  if (totalTasksCount == 0 && totalHabitsCount == 0 && journalEntries.isEmpty) {
    productivityScore = 0.0;
  }

  return ProductivityStats(
    completedTasksCount: completedTasksCount,
    totalTasksCount: totalTasksCount,
    taskCompletionRate: taskCompletionRate,
    completedHabitsToday: completedHabitsToday,
    totalHabitsCount: totalHabitsCount,
    habitCompletionRate: habitCompletionRate,
    activeHabitStreak: activeHabitStreak,
    productivityScore: productivityScore,
    weeklyFocusHours: weeklyFocusHours,
    moodDistribution: moodDistribution,
  );
});
