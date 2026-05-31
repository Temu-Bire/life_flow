import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/design_system.dart';
import '../../domain/models/task_model.dart';
import '../viewmodels/task_viewmodel.dart';

enum KanbanLane { todo, inProgress, review, completed }

class KanbanBoardWidget extends ConsumerWidget {
  const KanbanBoardWidget({super.key});

  List<TaskModel> _getTasksForLane(List<TaskModel> tasks, KanbanLane lane) {
    switch (lane) {
      case KanbanLane.todo:
        return tasks.where((t) => !t.isCompleted && t.focusTimeSpent == 0 && t.priority != TaskPriority.critical).toList();
      case KanbanLane.inProgress:
        return tasks.where((t) => !t.isCompleted && t.focusTimeSpent > 0).toList();
      case KanbanLane.review:
        return tasks.where((t) => !t.isCompleted && t.focusTimeSpent == 0 && t.priority == TaskPriority.critical).toList();
      case KanbanLane.completed:
        return tasks.where((t) => t.isCompleted).toList();
    }
  }

  String _getLaneTitle(KanbanLane lane) {
    switch (lane) {
      case KanbanLane.todo:
        return "To Do";
      case KanbanLane.inProgress:
        return "In Progress";
      case KanbanLane.review:
        return "Critical Review";
      case KanbanLane.completed:
        return "Completed";
    }
  }

  Color _getLaneColor(KanbanLane lane) {
    switch (lane) {
      case KanbanLane.todo:
        return AppColors.primaryLight;
      case KanbanLane.inProgress:
        return AppColors.secondary;
      case KanbanLane.review:
        return AppColors.danger;
      case KanbanLane.completed:
        return AppColors.success;
    }
  }

  Future<void> _handleMoveTask(WidgetRef ref, TaskModel task, KanbanLane targetLane) async {
    TaskModel updated = task;
    switch (targetLane) {
      case KanbanLane.todo:
        updated = task.copyWith(
          isCompleted: false,
          focusTimeSpent: 0,
          priority: task.priority == TaskPriority.critical ? TaskPriority.medium : task.priority,
        );
        break;
      case KanbanLane.inProgress:
        updated = task.copyWith(
          isCompleted: false,
          focusTimeSpent: task.focusTimeSpent == 0 ? 60 : task.focusTimeSpent, // set progress active
        );
        break;
      case KanbanLane.review:
        updated = task.copyWith(
          isCompleted: false,
          focusTimeSpent: 0,
          priority: TaskPriority.critical,
        );
        break;
      case KanbanLane.completed:
        updated = task.copyWith(
          isCompleted: true,
        );
        break;
    }
    await ref.read(taskListProvider.notifier).updateTask(updated);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTasks = ref.watch(taskListProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = constraints.maxWidth >= 900 ? (constraints.maxWidth - 48) / 4 : 280;

        return SizedBox(
          height: 520,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: KanbanLane.values.map((lane) {
              final laneTasks = _getTasksForLane(allTasks, lane);

              return DragTarget<TaskModel>(
                onWillAccept: (data) => data != null,
                onAcceptWithDetails: (details) => _handleMoveTask(ref, details.data, lane),
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    width: cardWidth,
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: candidateData.isNotEmpty
                          ? _getLaneColor(lane).withOpacity(0.08)
                          : AppColors.surface.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: candidateData.isNotEmpty
                            ? _getLaneColor(lane).withOpacity(0.3)
                            : Colors.white.withOpacity(0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Column Header
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _getLaneColor(lane),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getLaneTitle(lane),
                              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "${laneTasks.length}",
                                style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20, color: Colors.white10),
                        // Lanes Cards list
                        Expanded(
                          child: laneTasks.isEmpty
                              ? _buildEmptyLane()
                              : ListView.builder(
                                  itemCount: laneTasks.length,
                                  itemBuilder: (context, idx) {
                                    final task = laneTasks[idx];
                                    return _buildDraggableCard(ref, task);
                                  },
                                ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildEmptyLane() {
    return Center(
      child: Text(
        "Drop tasks here",
        style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _buildDraggableCard(WidgetRef ref, TaskModel task) {
    return LongPressDraggable<TaskModel>(
      data: task,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 250,
          padding: const EdgeInsets.all(12),
          decoration: AppDecorations.glassDecoration(borderRadius: 14),
          child: Text(
            task.title,
            style: AppTextStyles.bodyLarge,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: _buildLaneCard(ref, task),
      ),
      child: _buildLaneCard(ref, task),
    );
  }

  Widget _buildLaneCard(WidgetRef ref, TaskModel task) {
    Color priorityColor;
    switch (task.priority) {
      case TaskPriority.low:
        priorityColor = AppColors.success;
        break;
      case TaskPriority.medium:
        priorityColor = AppColors.info;
        break;
      case TaskPriority.high:
        priorityColor = AppColors.warning;
        break;
      case TaskPriority.critical:
        priorityColor = AppColors.danger;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  task.priority.name.toUpperCase(),
                  style: TextStyle(color: priorityColor, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              if (task.subtasks.isNotEmpty)
                Icon(
                  Icons.align_horizontal_left_outlined,
                  size: 14,
                  color: AppColors.textMuted.withOpacity(0.7),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            task.title,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (task.notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              task.notes,
              style: AppTextStyles.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (task.dueDate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 10, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  "${task.dueDate!.month}/${task.dueDate!.day}",
                  style: AppTextStyles.caption.copyWith(fontSize: 10),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }
}
