import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../tasks/presentation/viewmodels/task_viewmodel.dart';
import '../../../habits/presentation/viewmodels/habit_viewmodel.dart';
import '../../../focus/presentation/viewmodels/focus_viewmodel.dart';
import '../../../journal/presentation/viewmodels/journal_viewmodel.dart';
import '../../../journal/presentation/viewmodels/review_viewmodel.dart';
import '../../../knowledge/presentation/viewmodels/knowledge_viewmodel.dart';

class BadgeAchievement {
  final String title;
  final String description;
  final String icon;
  final bool isUnlocked;

  BadgeAchievement({
    required this.title,
    required this.description,
    required this.icon,
    this.isUnlocked = false,
  });
}

class GamificationState {
  final int totalXp;
  final int level;
  final int xpInCurrentLevel;
  final int xpNeededForNextLevel;
  final String rankName;
  final List<BadgeAchievement> badges;

  GamificationState({
    required this.totalXp,
    required this.level,
    required this.xpInCurrentLevel,
    required this.xpNeededForNextLevel,
    required this.rankName,
    required this.badges,
  });
}

final gamificationProvider = Provider<GamificationState>((ref) {
  final tasks = ref.watch(taskListProvider);
  final habits = ref.watch(habitListProvider);
  final focusState = ref.watch(focusProvider);
  final journals = ref.watch(journalListProvider);
  final reviews = ref.watch(reviewListProvider);

  // 1. Calculate XP
  int xp = 0;
  
  // Tasks: 20 XP each completed task
  final completedTasksCount = tasks.where((t) => t.isCompleted).length;
  xp += completedTasksCount * 20;

  // Habits: 10 XP for each completed check-in day log in history
  int totalHabitCheckins = 0;
  for (var h in habits) {
    totalHabitCheckins += h.history.length;
  }
  xp += totalHabitCheckins * 10;

  // Focus: 50 XP per session
  xp += focusState.history.length * 50;

  // Journal: 30 XP per entry
  xp += journals.length * 30;

  // Review: 100 XP per Weekly/Monthly review
  xp += reviews.length * 100;

  // 2. Levels logic: 500 XP per level
  const int xpPerLevel = 500;
  final int level = xp ~/ xpPerLevel;
  final int xpInCurrentLevel = xp % xpPerLevel;
  final int xpNeededForNextLevel = xpPerLevel - xpInCurrentLevel;

  // 3. Ranks logic
  String rankName = "Novice Practitioner";
  if (level >= 15) {
    rankName = "Zen Architect";
  } else if (level >= 10) {
    rankName = "Productivity Master";
  } else if (level >= 6) {
    rankName = "Focus Enthusiast";
  } else if (level >= 3) {
    rankName = "Flow Cadet";
  }

  // 4. Badges logic
  final List<BadgeAchievement> badgesList = [
    // Streak badges
    BadgeAchievement(
      title: "Streak Starter",
      description: "Achieve a habit streak of 7 days",
      icon: "🔥",
      isUnlocked: habits.any((h) => h.streak >= 7),
    ),
    BadgeAchievement(
      title: "Streak Master",
      description: "Achieve a habit streak of 21 days",
      icon: "⚡",
      isUnlocked: habits.any((h) => h.streak >= 21),
    ),
    
    // Focus badges
    BadgeAchievement(
      title: "Focus Cadet",
      description: "Log 5 deep work focus sessions",
      icon: "🧠",
      isUnlocked: focusState.history.length >= 5,
    ),
    BadgeAchievement(
      title: "Deep Work Ninja",
      description: "Log 30 deep work focus sessions",
      icon: "🥷",
      isUnlocked: focusState.history.length >= 30,
    ),

    // Goal achievements
    BadgeAchievement(
      title: "Goal Crusher",
      description: "Log at least 3 completed reflection reviews",
      icon: "🏆",
      isUnlocked: reviews.length >= 3,
    ),
    BadgeAchievement(
      title: "Obsidian Mind",
      description: "Create 10 knowledge vault pages",
      icon: "🔮",
      isUnlocked: ref.read(noteListProvider).length >= 10,
    ),
  ];

  return GamificationState(
    totalXp: xp,
    level: level,
    xpInCurrentLevel: xpInCurrentLevel,
    xpNeededForNextLevel: xpNeededForNextLevel,
    rankName: rankName,
    badges: badgesList,
  );
});
