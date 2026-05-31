import 'package:flutter/material.dart';
import '../../../../core/theme/design_system.dart';
import '../../domain/models/habit_model.dart';

class HabitHeatmapWidget extends StatelessWidget {
  final HabitModel habit;

  const HabitHeatmapWidget({
    super.key,
    required this.habit,
  });

  @override
  Widget build(BuildContext context) {
    // We want to show a 14-week (14 * 7 = 98 days) horizontal grid
    const int weeksToShow = 15;
    final DateTime now = DateTime.now();
    
    // Find the starting date (Sunday of 14 weeks ago)
    final int daysToSubtract = (now.weekday % 7) + (weeksToShow - 1) * 7;
    final DateTime startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysToSubtract));

    Color completedColor;
    switch (habit.category) {
      case 'Fitness':
        completedColor = AppColors.danger;
        break;
      case 'Mind':
        completedColor = AppColors.secondary;
        break;
      case 'Health':
        completedColor = AppColors.success;
        break;
      case 'Work':
        completedColor = AppColors.primaryLight;
        break;
      default:
        completedColor = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.glassDecoration(borderRadius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.grid_on, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                "Contribution Heatmap (Last 15 Weeks)",
                style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Horizontal scrolling grid
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Weekday initials labels
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    SizedBox(height: 12),
                    _DayLabel("M"),
                    SizedBox(height: 12),
                    _DayLabel("W"),
                    SizedBox(height: 12),
                    _DayLabel("F"),
                  ],
                ),
                const SizedBox(width: 8),
                // The Grid Column per week
                Row(
                  children: List.generate(weeksToShow, (weekIdx) {
                    return Column(
                      children: List.generate(7, (dayIdx) {
                        final int offsetDays = (weekIdx * 7) + dayIdx;
                        final DateTime blockDate = startDate.add(Duration(days: offsetDays));
                        final bool isCompleted = habit.isCompletedOn(blockDate);
                        final bool isFuture = blockDate.isAfter(now);

                        Color blockColor;
                        if (isFuture) {
                          blockColor = Colors.transparent;
                        } else if (isCompleted) {
                          blockColor = completedColor;
                        } else {
                          blockColor = Colors.white.withOpacity(0.04);
                        }

                        return Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: blockColor,
                            borderRadius: BorderRadius.circular(2.5),
                            border: Border.all(
                              color: isCompleted 
                                  ? Colors.white10 
                                  : Colors.white.withOpacity(0.02),
                              width: 0.5,
                            ),
                            boxShadow: isCompleted
                                ? [
                                    BoxShadow(
                                      color: completedColor.withOpacity(0.4),
                                      blurRadius: 4,
                                      spreadRadius: 0.5,
                                    ),
                                  ]
                                : [],
                          ),
                        );
                      }),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayLabel extends StatelessWidget {
  final String label;
  const _DayLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 12,
      child: Center(
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(fontSize: 8, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
