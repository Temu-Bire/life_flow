import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/database_service.dart';
import '../../domain/models/habit_model.dart';

final habitListProvider = StateNotifierProvider<HabitViewModel, List<HabitModel>>((ref) {
  return HabitViewModel();
});

class HabitViewModel extends StateNotifier<List<HabitModel>> {
  final DatabaseService _db = DatabaseService.instance;
  final Uuid _uuid = const Uuid();

  HabitViewModel() : super([]) {
    _loadHabits();
  }

  void _loadHabits() {
    final rawHabits = _db.getAllHabits();
    state = rawHabits.map((e) => HabitModel.fromMap(e)).toList();
  }

  Future<void> addHabit({
    required String name,
    String frequency = "Daily",
    String category = "Health",
    bool isPositive = true,
  }) async {
    final newHabit = HabitModel(
      id: _uuid.v4(),
      name: name,
      frequency: frequency,
      category: category,
      isPositive: isPositive,
    );

    state = [...state, newHabit];
    await _db.saveHabit(newHabit.id, newHabit.toMap());
  }

  Future<void> deleteHabit(String id) async {
    state = state.where((h) => h.id != id).toList();
    await _db.deleteHabit(id);
  }

  Future<void> toggleHabitCheckIn(String id, DateTime date) async {
    final habitIndex = state.indexWhere((h) => h.id == id);
    if (habitIndex == -1) return;

    final habit = state[habitIndex];
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    final List<DateTime> updatedHistory = List.from(habit.history);
    final bool alreadyCompleted = updatedHistory.any((d) => 
        d.year == dateOnly.year && d.month == dateOnly.month && d.day == dateOnly.day);

    if (alreadyCompleted) {
      updatedHistory.removeWhere((d) => 
          d.year == dateOnly.year && d.month == dateOnly.month && d.day == dateOnly.day);
    } else {
      updatedHistory.add(dateOnly);
    }

    // Sort history to calculate streaks
    updatedHistory.sort((a, b) => b.compareTo(a)); // Descending order (newest first)

    // Calculate Streak & Consistency
    final streakResults = _calculateStreak(updatedHistory);
    final score = _calculateConsistency(updatedHistory);

    final updatedHabit = habit.copyWith(
      history: updatedHistory,
      streak: streakResults.currentStreak,
      longestStreak: streakResults.longestStreak > habit.longestStreak 
          ? streakResults.longestStreak 
          : habit.longestStreak,
      consistencyScore: score,
    );

    state = [
      for (int i = 0; i < state.length; i++)
        if (i == habitIndex) updatedHabit else state[i]
    ];

    await _db.saveHabit(updatedHabit.id, updatedHabit.toMap());
  }

  // Calculate consecutive check-in days
  _StreakResult _calculateStreak(List<DateTime> history) {
    if (history.isEmpty) return _StreakResult(0, 0);

    // Standardize all dates to date-only
    final Set<String> dateStrings = history
        .map((d) => "${d.year}-${d.month}-${d.day}")
        .toSet();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayStr = "${today.year}-${today.month}-${today.day}";
    final yesterdayStr = "${yesterday.year}-${yesterday.month}-${yesterday.day}";

    // If not checked in today AND not checked in yesterday, the active streak is broken (0)
    bool hasToday = dateStrings.contains(todayStr);
    bool hasYesterday = dateStrings.contains(yesterdayStr);

    int currentStreak = 0;
    if (hasToday || hasYesterday) {
      DateTime checkDate = hasToday ? today : yesterday;
      while (true) {
        final checkStr = "${checkDate.year}-${checkDate.month}-${checkDate.day}";
        if (dateStrings.contains(checkStr)) {
          currentStreak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
    }

    // Calculate historical longest streak
    int longestStreak = 0;
    if (history.isNotEmpty) {
      // Find all unique dates sorted ascending
      final List<DateTime> sorted = history.map((d) => DateTime(d.year, d.month, d.day)).toList();
      sorted.sort();

      int tempStreak = 1;
      longestStreak = 1;

      for (int i = 0; i < sorted.length - 1; i++) {
        final current = sorted[i];
        final next = sorted[i + 1];
        final diff = next.difference(current).inDays;

        if (diff == 1) {
          tempStreak++;
          if (tempStreak > longestStreak) {
            longestStreak = tempStreak;
          }
        } else if (diff > 1) {
          tempStreak = 1;
        }
      }
      if (currentStreak > longestStreak) {
        longestStreak = currentStreak;
      }
    }

    return _StreakResult(currentStreak, longestStreak);
  }

  // Calculate consistency score (completions in the last 30 days)
  double _calculateConsistency(List<DateTime> history) {
    if (history.isEmpty) return 0.0;
    final now = DateTime.now();
    final thirtyDaysAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30));

    final countLast30 = history.where((d) => d.isAfter(thirtyDaysAgo)).length;
    return (countLast30 / 30.0).clamp(0.0, 1.0);
  }
}

class _StreakResult {
  final int currentStreak;
  final int longestStreak;

  _StreakResult(this.currentStreak, this.longestStreak);
}
