import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/design_system.dart';
import '../../domain/models/habit_model.dart';
import '../viewmodels/habit_viewmodel.dart';
import '../widgets/heatmap_widget.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/empty_state_view.dart';

class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _expandedHabitId;

  void _showAddHabitSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddHabitBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Daily Habits",
                      style: AppTextStyles.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Build compound streaks and habits",
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddHabitSheet(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  label: const Text("Add", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Horizontal Past 7 Days Checker
            _buildWeekCalendarSelector(),
            const SizedBox(height: 20),

            // Main habits content list
            Expanded(
              child: habits.isEmpty
                  ? EmptyStateView(
                      icon: Icons.autorenew,
                      title: "No habits tracked",
                      description: "Habits are the compound interest of self-improvement. Let's create your first habit!",
                      actionText: "Add Habit",
                      onActionTap: () => _showAddHabitSheet(context),
                    )
                  : ListView.builder(
                      itemCount: habits.length,
                      itemBuilder: (context, index) {
                        final habit = habits[index];
                        return _buildHabitInteractiveTile(habit);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Visual week log picker
  Widget _buildWeekCalendarSelector() {
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.glassDecoration(borderRadius: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          final date = now.subtract(Duration(days: 6 - index));
          final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month && date.year == _selectedDate.year;
          final isToday = date.day == now.day && date.month == now.month && date.year == now.year;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
            },
            child: AnimatedContainer(
              duration: AppTransitions.fast,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.primary 
                    : isToday 
                        ? AppColors.primary.withOpacity(0.08) 
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected 
                      ? AppColors.primaryLight.withOpacity(0.3) 
                      : isToday 
                          ? AppColors.primary.withOpacity(0.2) 
                          : Colors.transparent,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('E').format(date).substring(0, 1),
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${date.day}",
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // Habit Tile Card
  Widget _buildHabitInteractiveTile(HabitModel habit) {
    final bool isCompleted = habit.isCompletedOn(_selectedDate);
    final bool isExpanded = _expandedHabitId == habit.id;

    Color categoryColor;
    IconData categoryIcon;
    switch (habit.category) {
      case 'Fitness':
        categoryColor = AppColors.danger;
        categoryIcon = Icons.fitness_center;
        break;
      case 'Mind':
        categoryColor = AppColors.secondary;
        categoryIcon = Icons.psychology;
        break;
      case 'Health':
        categoryColor = AppColors.success;
        categoryIcon = Icons.favorite;
        break;
      case 'Work':
        categoryColor = AppColors.primaryLight;
        categoryIcon = Icons.laptop;
        break;
      default:
        categoryColor = AppColors.primary;
        categoryIcon = Icons.star;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          GlassCard(
            padding: EdgeInsets.zero,
            borderRadius: 16,
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  onTap: () {
                    setState(() {
                      _expandedHabitId = isExpanded ? null : habit.id;
                    });
                  },
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: categoryColor.withOpacity(0.08),
                    ),
                    child: Icon(categoryIcon, color: categoryColor, size: 20),
                  ),
                  title: Text(
                    habit.name,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      color: isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      const Icon(Icons.local_fire_department, size: 14, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text(
                        "${habit.streak} day streak",
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "${(habit.consistencyScore * 100).toInt()}% consistency",
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Trash Icon to delete habit
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.textMuted, size: 20),
                        onPressed: () {
                          ref.read(habitListProvider.notifier).deleteHabit(habit.id);
                        },
                      ),
                      const SizedBox(width: 4),
                      // Interactive Circular Progress Ring / Complete button
                      GestureDetector(
                        onTap: () {
                          ref.read(habitListProvider.notifier).toggleHabitCheckIn(habit.id, _selectedDate);
                        },
                        child: AnimatedContainer(
                          duration: AppTransitions.fast,
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted ? categoryColor : Colors.transparent,
                            border: Border.all(
                              color: isCompleted ? categoryColor : categoryColor.withOpacity(0.4),
                              width: 2.5,
                            ),
                          ),
                          child: isCompleted
                              ? const Icon(Icons.check, color: Colors.white, size: 18)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                // Expandable Heatmap visual block
                AnimatedSize(
                  duration: AppTransitions.medium,
                  curve: Curves.easeInOut,
                  child: isExpanded
                      ? Padding(
                          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                          child: Column(
                            children: [
                              const Divider(height: 1, color: Colors.white10),
                              const SizedBox(height: 12),
                              HabitHeatmapWidget(habit: habit),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Add Habit Bottom Sheet Creator
class AddHabitBottomSheet extends ConsumerStatefulWidget {
  const AddHabitBottomSheet({super.key});

  @override
  ConsumerState<AddHabitBottomSheet> createState() => _AddHabitBottomSheetState();
}

class _AddHabitBottomSheetState extends ConsumerState<AddHabitBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  String _frequency = "Daily";
  String _category = "Health";

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref.read(habitListProvider.notifier).addHabit(
            name: _nameController.text,
            frequency: _frequency,
            category: _category,
          );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 24,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Track a New Habit",
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 18),

            // Habit Name
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Habit Name (e.g. Morning Meds, Cardio)",
                labelStyle: TextStyle(color: AppColors.textSecondary),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryLight)),
              ),
              validator: (val) => val == null || val.isEmpty ? "Please enter a habit name" : null,
            ),
            const SizedBox(height: 24),

            // Category & Frequency Dropdowns
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _category,
                    dropdownColor: AppColors.surface,
                    decoration: const InputDecoration(
                      labelText: "Category",
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (val) {
                      if (val != null) setState(() => _category = val);
                    },
                    items: ['Health', 'Mind', 'Fitness', 'Work', 'Financial']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _frequency,
                    dropdownColor: AppColors.surface,
                    decoration: const InputDecoration(
                      labelText: "Frequency",
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (val) {
                      if (val != null) setState(() => _frequency = val);
                    },
                    items: ['Daily', 'Weekly', 'Custom']
                        .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                        .toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel", style: TextStyle(color: AppColors.textSecondary)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text("Start Habit", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
