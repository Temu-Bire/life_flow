import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/design_system.dart';
import '../../../tasks/domain/models/task_model.dart';
import '../../../tasks/presentation/viewmodels/task_viewmodel.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/premium_button.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  DateTime _selectedDate = DateTime.now();
  String _activeView = "Day"; // Day, Week, Agenda
  
  // Hours of the day to render in Day view: 6:00 to 23:00
  final List<int> _dayHours = List.generate(18, (index) => index + 6);

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
  }

  void _nextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
  }

  void _scheduleTaskDialog(BuildContext context, TaskModel task) {
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
    int duration = 60; // 60 minutes default

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text("Schedule Task", style: const TextStyle(color: Colors.white, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(task.title, style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time, color: AppColors.secondaryLight),
                title: Text("Start Time: ${selectedTime.format(context)}", style: const TextStyle(color: Colors.white)),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (picked != null) {
                    setModalState(() => selectedTime = picked);
                  }
                },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Duration (mins):", style: TextStyle(color: AppColors.textSecondary)),
                  DropdownButton<int>(
                    value: duration,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (val) => setModalState(() => duration = val!),
                    items: [15, 30, 45, 60, 90, 120, 180]
                        .map((d) => DropdownMenuItem(value: d, child: Text("$d min")))
                        .toList(),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Cancel", style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                final scheduledTime = DateTime(
                  _selectedDate.year,
                  _selectedDate.month,
                  _selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );
                
                final updated = task.copyWith(
                  scheduledStartTime: scheduledTime,
                  scheduledDuration: duration,
                );
                ref.read(taskListProvider.notifier).updateTask(updated);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Scheduled: ${task.title} at ${selectedTime.format(context)}"),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text("Schedule", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskListProvider);
    
    // Scheduled tasks for the selected date
    final scheduledToday = tasks.where((t) {
      if (t.scheduledStartTime == null) return false;
      final start = t.scheduledStartTime!;
      return start.year == _selectedDate.year &&
          start.month == _selectedDate.month &&
          start.day == _selectedDate.day;
    }).toList();

    // Unscheduled / Pending tasks
    final unscheduledTasks = tasks.where((t) => !t.isCompleted && !t.isArchived && t.scheduledStartTime == null).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar Title bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Daily Schedule", style: AppTextStyles.titleLarge),
                    const SizedBox(height: 4),
                    Text(DateFormat('EEEE, MMMM d, y').format(_selectedDate), style: AppTextStyles.bodyMedium),
                  ],
                ),
                // Toggle view chip
                Row(
                  children: ["Day", "Agenda"].map((view) {
                    final isSelected = _activeView == view;
                    return GestureDetector(
                      onTap: () => setState(() => _activeView = view),
                      child: Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          view,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Date Navigation row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  onPressed: _previousDay,
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedDate = DateTime.now()),
                  child: const Text("Go to Today", style: TextStyle(color: AppColors.primaryLight)),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                  onPressed: _nextDay,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Main body area (Split view: Timeline vs Unscheduled task drawer)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Timeline Area
                  Expanded(
                    flex: 6,
                    child: _activeView == "Day"
                        ? _buildDayTimeline(scheduledToday)
                        : _buildAgendaView(scheduledToday),
                  ),
                  const SizedBox(width: 14),

                  // 2. Unscheduled task picker
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Queue", style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            decoration: AppDecorations.glassDecoration(borderRadius: 16),
                            padding: const EdgeInsets.all(12),
                            child: unscheduledTasks.isEmpty
                                ? const Center(
                                    child: Text(
                                      "All tasks scheduled!",
                                      style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontStyle: FontStyle.italic),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: unscheduledTasks.length,
                                    itemBuilder: (context, index) {
                                      final task = unscheduledTasks[index];
                                      return Card(
                                        color: Colors.white.withOpacity(0.03),
                                        margin: const EdgeInsets.only(bottom: 8),
                                        child: ListTile(
                                          title: Text(task.title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                                          subtitle: Text(task.priority.name.toUpperCase(), style: TextStyle(color: _getPriorityColor(task.priority), fontSize: 8, fontWeight: FontWeight.bold)),
                                          trailing: const Icon(Icons.calendar_today, size: 14, color: AppColors.primaryLight),
                                          onTap: () => _scheduleTaskDialog(context, task),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayTimeline(List<TaskModel> scheduledToday) {
    return Container(
      decoration: AppDecorations.glassDecoration(borderRadius: 20),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _dayHours.length,
        itemBuilder: (context, index) {
          final hour = _dayHours[index];
          final hourText = "${hour.toString().padLeft(2, '0')}:00";

          // Find tasks scheduled during this specific hour
          final tasksInHour = scheduledToday.where((t) {
            final start = t.scheduledStartTime!;
            return start.hour == hour;
          }).toList();

          return Container(
            constraints: const BoxConstraints(minHeight: 64),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white12, width: 0.5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hour Label
                Container(
                  width: 52,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    hourText,
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                
                // Tasks container for this hour
                Expanded(
                  child: tasksInHour.isEmpty
                      ? GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            // User tapped empty hour block to plan/create a quick schedule block
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Tap a task in the Queue to schedule at $hourText"),
                                backgroundColor: AppColors.info,
                              ),
                            );
                          },
                          child: const SizedBox(
                            height: 48,
                            child: Center(
                              child: Text("", style: TextStyle(color: Colors.white10)),
                            ),
                          ),
                        )
                      : Column(
                          children: tasksInHour.map((task) {
                            final duration = task.scheduledDuration ?? 60;
                            return Container(
                              margin: const EdgeInsets.only(top: 4, bottom: 4),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient.colors.first == AppColors.primary ? AppColors.darkCardGradient : AppColors.primaryGradient,
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Row(
                                children: [
                                  // Task title & details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task.title,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "${duration}m • Category: ${task.category}",
                                          style: TextStyle(color: Colors.white70, fontSize: 9),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Checkoff checkbox inside timeline
                                  GestureDetector(
                                    onTap: () {
                                      ref.read(taskListProvider.notifier).toggleTaskCompleted(task.id);
                                    },
                                    child: Icon(
                                      task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                                      color: task.isCompleted ? AppColors.success : Colors.white54,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Reschedule/Delete from schedule icon
                                  GestureDetector(
                                    onTap: () {
                                      // Remove scheduling parameters
                                      final updated = task.copyWith(
                                        scheduledStartTime: null,
                                        scheduledDuration: null,
                                      );
                                      ref.read(taskListProvider.notifier).updateTask(updated);
                                    },
                                    child: const Icon(Icons.close, color: AppColors.danger, size: 16),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAgendaView(List<TaskModel> scheduledToday) {
    if (scheduledToday.isEmpty) {
      return EmptyStateView(
        icon: Icons.event_note,
        title: "Agenda is clear",
        description: "No tasks scheduled for this day. Open the queue to schedule blocks.",
      );
    }

    // Sort scheduled tasks by time
    final sorted = List<TaskModel>.from(scheduledToday)
      ..sort((a, b) => a.scheduledStartTime!.compareTo(b.scheduledStartTime!));

    return ListView.builder(
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final task = sorted[index];
        final timeText = DateFormat('hh:mm a').format(task.scheduledStartTime!);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getPriorityColor(task.priority),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text("Scheduled: $timeText • Duration: ${task.scheduledDuration ?? 60} mins", style: AppTextStyles.caption),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger),
                  onPressed: () {
                    final updated = task.copyWith(
                      scheduledStartTime: null,
                      scheduledDuration: null,
                    );
                    ref.read(taskListProvider.notifier).updateTask(updated);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return AppColors.success;
      case TaskPriority.medium:
        return AppColors.info;
      case TaskPriority.high:
        return AppColors.warning;
      case TaskPriority.critical:
        return AppColors.danger;
    }
  }
}
