import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/design_system.dart';
import '../../domain/models/task_model.dart';
import '../viewmodels/task_viewmodel.dart';
import '../widgets/kanban_view.dart';
import '../widgets/pomodoro_timer.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/empty_state_view.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isKanbanMode = false;
  bool _isPomodoroMode = false;
  TaskModel? _focusedTask;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTaskBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = ref.watch(filteredTasksProvider);
    final activeFilter = ref.watch(taskFilterProvider);
    final textSearch = ref.watch(taskSearchProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header + Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Flow Tasks",
                      style: AppTextStyles.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Organize and accomplish your goals",
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
                // Toggle mode icons
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isPomodoroMode ? Icons.timer : Icons.timer_outlined,
                        color: _isPomodoroMode ? AppColors.primaryLight : AppColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPomodoroMode = !_isPomodoroMode;
                        });
                      },
                      tooltip: "Toggle Focus Timer",
                    ),
                    IconButton(
                      icon: Icon(
                        _isKanbanMode ? Icons.dashboard : Icons.view_kanban_outlined,
                        color: _isKanbanMode ? AppColors.primaryLight : AppColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _isKanbanMode = !_isKanbanMode;
                          if (_isKanbanMode) _isPomodoroMode = false;
                        });
                      },
                      tooltip: "Toggle Kanban Board",
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Focus Pomodoro Container (if toggled)
            if (_isPomodoroMode) ...[
              PomodoroTimerWidget(associatedTask: _focusedTask),
              const SizedBox(height: 20),
            ],

            // Search Bar & Filter Buttons
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: AppDecorations.glassDecoration(borderRadius: 14),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        ref.read(taskSearchProvider.notifier).state = val;
                      },
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Search tasks...",
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Smart filter Tabs
            if (!_isKanbanMode) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Today', 'Upcoming', 'Completed', 'Overdue'].map((filter) {
                    final isSelected = activeFilter == filter;
                    return GestureDetector(
                      onTap: () {
                        ref.read(taskFilterProvider.notifier).state = filter;
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryLight.withOpacity(0.4) : Colors.white.withOpacity(0.05),
                          ),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Tasks List / Kanban Board View
            Expanded(
              child: _isKanbanMode
                  ? const KanbanBoardWidget()
                  : filteredTasks.isEmpty
                      ? EmptyStateView(
                          icon: Icons.checklist,
                          title: "No tasks found",
                          description: textSearch.isEmpty
                              ? "Looks like you have clean sheets! Add tasks to start tracking."
                              : "No tasks match your search filter criteria.",
                          actionText: textSearch.isEmpty ? "Create Task" : null,
                          onActionTap: textSearch.isEmpty ? () => _showAddTaskSheet(context) : null,
                        )
                      : ReorderableListView.builder(
                          onReorder: (oldIdx, newIdx) {
                            ref.read(taskListProvider.notifier).reorderTasks(oldIdx, newIdx);
                          },
                          itemCount: filteredTasks.length,
                          itemBuilder: (context, index) {
                            final task = filteredTasks[index];
                            return _buildSlidableTaskTile(context, task, index);
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskSheet(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildSlidableTaskTile(BuildContext context, TaskModel task, int index) {
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

    return KeyedSubtree(
      key: ValueKey(task.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Slidable(
          key: ValueKey(task.id),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: [
              SlidableAction(
                onPressed: (context) {
                  ref.read(taskListProvider.notifier).deleteTask(task.id);
                },
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: 'Delete',
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
              ),
            ],
          ),
          child: GlassCard(
            padding: EdgeInsets.zero,
            borderRadius: 16,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _focusedTask = task;
                    _isPomodoroMode = true; // Auto open focus timer when selecting task
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      // Reorder Handle drag visual indicator
                      ReorderableDragStartListener(
                        index: index,
                        child: Icon(Icons.drag_indicator, color: AppColors.textMuted.withOpacity(0.5)),
                      ),
                      const SizedBox(width: 12),

                      // Checkbox
                      GestureDetector(
                        onTap: () {
                          ref.read(taskListProvider.notifier).toggleTaskCompleted(task.id);
                        },
                        child: AnimatedContainer(
                          duration: AppTransitions.fast,
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: task.isCompleted ? AppColors.success : Colors.transparent,
                            border: Border.all(
                              color: task.isCompleted ? AppColors.success : AppColors.textMuted.withOpacity(0.8),
                              width: 2,
                            ),
                          ),
                          child: task.isCompleted
                              ? const Icon(Icons.check, color: Colors.white, size: 16)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Title & Notes
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                color: task.isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                              ),
                            ),
                            if (task.notes.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                task.notes,
                                style: AppTextStyles.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (task.subtasks.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              // Subtasks tiny progress indicator bar
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: LinearProgressIndicator(
                                        value: task.progressPercentage,
                                        minHeight: 4,
                                        backgroundColor: Colors.white12,
                                        color: AppColors.primaryLight,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "${(task.progressPercentage * 100).toInt()}%",
                                    style: AppTextStyles.caption.copyWith(fontSize: 10),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Indicators (Priority & Due date)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: priorityColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              task.priority.name.toUpperCase(),
                              style: TextStyle(
                                color: priorityColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (task.dueDate != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              DateFormat('MMM d').format(task.dueDate!),
                              style: AppTextStyles.caption.copyWith(fontSize: 10),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Add Task Modal bottom sheet
class AddTaskBottomSheet extends ConsumerStatefulWidget {
  const AddTaskBottomSheet({super.key});

  @override
  ConsumerState<AddTaskBottomSheet> createState() => _AddTaskBottomSheetState();
}

class _AddTaskBottomSheetState extends ConsumerState<AddTaskBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  
  TaskPriority _priority = TaskPriority.medium;
  String _category = "Inbox";
  DateTime? _dueDate;
  
  final List<SubTask> _subtasks = [];
  final _subtaskController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  void _addSubtask() {
    if (_subtaskController.text.isNotEmpty) {
      setState(() {
        _subtasks.add(SubTask(title: _subtaskController.text));
        _subtaskController.clear();
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref.read(taskListProvider.notifier).addTask(
            title: _titleController.text,
            notes: _notesController.text,
            priority: _priority,
            category: _category,
            dueDate: _dueDate,
            subtasks: _subtasks,
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
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Create New Task",
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: 18),

              // Title input
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Task Title",
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryLight)),
                ),
                validator: (val) => val == null || val.isEmpty ? "Please enter a title" : null,
              ),
              const SizedBox(height: 16),

              // Notes input
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Notes / Description",
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryLight)),
                ),
              ),
              const SizedBox(height: 24),

              // Selection options: Priority, Category, Date
              Row(
                children: [
                  // Priority
                  Expanded(
                    child: DropdownButtonFormField<TaskPriority>(
                      value: _priority,
                      dropdownColor: AppColors.surface,
                      decoration: const InputDecoration(
                        labelText: "Priority",
                        labelStyle: TextStyle(color: AppColors.textSecondary),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (val) {
                        if (val != null) setState(() => _priority = val);
                      },
                      items: TaskPriority.values
                          .map((p) => DropdownMenuItem(value: p, child: Text(p.name.toUpperCase())))
                          .toList(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Category
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
                      items: ['Inbox', 'Work', 'Personal', 'Health', 'Learning']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Due Date Selector
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month, color: AppColors.primaryLight),
                title: Text(
                  _dueDate == null
                      ? "Set Due Date"
                      : "Due: ${DateFormat('EEE, MMM d, y').format(_dueDate!)}",
                  style: TextStyle(color: _dueDate == null ? AppColors.textSecondary : Colors.white),
                ),
                trailing: _dueDate != null
                    ? IconButton(
                        icon: const Icon(Icons.close, color: AppColors.danger),
                        onPressed: () => setState(() => _dueDate = null),
                      )
                    : null,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppColors.primary,
                            onPrimary: Colors.white,
                            surface: AppColors.surface,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() => _dueDate = picked);
                  }
                },
              ),
              const Divider(color: Colors.white10),

              // Subtasks Creator
              Text(
                "Subtasks (${_subtasks.length})",
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_subtasks.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  children: _subtasks
                      .map((st) => Chip(
                            backgroundColor: Colors.white.withOpacity(0.04),
                            label: Text(st.title, style: const TextStyle(color: Colors.white, fontSize: 11)),
                            deleteIcon: const Icon(Icons.close, size: 14, color: AppColors.danger),
                            onDeleted: () {
                              setState(() {
                                _subtasks.remove(st);
                              });
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _subtaskController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: "Add a subtask...",
                        hintStyle: TextStyle(color: AppColors.textMuted),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _addSubtask(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryLight),
                    onPressed: _addSubtask,
                  ),
                ],
              ),
              const Divider(color: Colors.white10),
              const SizedBox(height: 20),

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
                    child: const Text("Save Task", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
