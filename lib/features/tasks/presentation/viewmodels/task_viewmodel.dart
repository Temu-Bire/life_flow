import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/database_service.dart';
import '../../domain/models/task_model.dart';

final taskListProvider = StateNotifierProvider<TaskViewModel, List<TaskModel>>((ref) {
  return TaskViewModel();
});

class TaskViewModel extends StateNotifier<List<TaskModel>> {
  final DatabaseService _db = DatabaseService.instance;
  final Uuid _uuid = const Uuid();

  TaskViewModel() : super([]) {
    _loadTasks();
  }

  void _loadTasks() {
    final rawTasks = _db.getAllTasks();
    final tasks = rawTasks.map((e) => TaskModel.fromMap(e)).toList();
    // Sort by position
    tasks.sort((a, b) => a.position.compareTo(b.position));
    state = tasks;
  }

  Future<void> addTask({
    required String title,
    String notes = "",
    TaskPriority priority = TaskPriority.medium,
    String category = "Inbox",
    DateTime? dueDate,
    List<SubTask> subtasks = const [],
    bool isRecurring = false,
    String recurrence = "None",
  }) async {
    final newTask = TaskModel(
      id: _uuid.v4(),
      title: title,
      notes: notes,
      priority: priority,
      category: category,
      dueDate: dueDate,
      subtasks: subtasks,
      isRecurring: isRecurring,
      recurrence: recurrence,
      position: state.length,
    );

    state = [...state, newTask];
    await _db.saveTask(newTask.id, newTask.toMap());
  }

  Future<void> updateTask(TaskModel updatedTask) async {
    state = [
      for (final task in state)
        if (task.id == updatedTask.id) updatedTask else task
    ];
    await _db.saveTask(updatedTask.id, updatedTask.toMap());
  }

  Future<void> deleteTask(String id) async {
    state = state.where((task) => task.id != id).toList();
    await _db.deleteTask(id);
  }

  Future<void> toggleTaskCompleted(String id) async {
    final taskIndex = state.indexWhere((task) => task.id == id);
    if (taskIndex != -1) {
      final task = state[taskIndex];
      final toggledTask = task.copyWith(
        isCompleted: !task.isCompleted,
        // Mark all subtasks completed if parent is completed
        subtasks: !task.isCompleted
            ? task.subtasks.map((st) => st.copyWith(isCompleted: true)).toList()
            : task.subtasks,
      );
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == taskIndex) toggledTask else state[i]
      ];
      await _db.saveTask(toggledTask.id, toggledTask.toMap());
    }
  }

  Future<void> toggleSubtaskCompleted(String taskId, int subtaskIndex) async {
    final taskIndex = state.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      final task = state[taskIndex];
      final updatedSubtasks = List<SubTask>.from(task.subtasks);
      final st = updatedSubtasks[subtaskIndex];
      updatedSubtasks[subtaskIndex] = st.copyWith(isCompleted: !st.isCompleted);

      // If all subtasks completed, auto-complete parent?
      // Or just keep it separate. Let's keep it separate but compute progress.
      final bool allDone = updatedSubtasks.every((st) => st.isCompleted);

      final updatedTask = task.copyWith(
        subtasks: updatedSubtasks,
        isCompleted: allDone ? true : task.isCompleted,
      );

      state = [
        for (int i = 0; i < state.length; i++)
          if (i == taskIndex) updatedTask else state[i]
      ];
      await _db.saveTask(updatedTask.id, updatedTask.toMap());
    }
  }

  Future<void> reorderTasks(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final List<TaskModel> items = List.from(state);
    final TaskModel item = items.removeAt(oldIndex);
    items.insert(newIndex, item);

    // Update positions
    final List<TaskModel> updatedItems = [];
    for (int i = 0; i < items.length; i++) {
      final updated = items[i].copyWith(position: i);
      updatedItems.add(updated);
      await _db.saveTask(updated.id, updated.toMap());
    }
    state = updatedItems;
  }

  Future<void> addFocusTime(String taskId, int seconds) async {
    final taskIndex = state.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      final task = state[taskIndex];
      final updatedTask = task.copyWith(
        focusTimeSpent: task.focusTimeSpent + seconds,
      );
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == taskIndex) updatedTask else state[i]
      ];
      await _db.saveTask(updatedTask.id, updatedTask.toMap());
    }
  }
}

// Extra Providers for smart filtering
final taskFilterProvider = StateProvider<String>((ref) => 'Today');
final taskSearchProvider = StateProvider<String>((ref) => '');

final filteredTasksProvider = Provider<List<TaskModel>>((ref) {
  final tasks = ref.watch(taskListProvider);
  final filter = ref.watch(taskFilterProvider);
  final search = ref.watch(taskSearchProvider);

  final List<TaskModel> activeTasks = tasks.where((task) => !task.isArchived).toList();

  List<TaskModel> filtered = [];

  final DateTime now = DateTime.now();
  final DateTime todayDate = DateTime(now.year, now.month, now.day);

  switch (filter) {
    case 'Today':
      filtered = activeTasks.where((task) {
        if (task.dueDate == null) return false;
        final due = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
        return due.isAtSameMomentAs(todayDate) && !task.isCompleted;
      }).toList();
      break;
    case 'Upcoming':
      filtered = activeTasks.where((task) {
        if (task.dueDate == null) return true; // Undated goes to upcoming
        final due = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
        return due.isAfter(todayDate) && !task.isCompleted;
      }).toList();
      break;
    case 'Completed':
      filtered = activeTasks.where((task) => task.isCompleted).toList();
      break;
    case 'Overdue':
      filtered = activeTasks.where((task) {
        if (task.dueDate == null) return false;
        final due = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
        return due.isBefore(todayDate) && !task.isCompleted;
      }).toList();
      break;
    default:
      filtered = activeTasks;
  }

  if (search.isNotEmpty) {
    filtered = filtered
        .where((task) => task.title.toLowerCase().contains(search.toLowerCase()))
        .toList();
  }

  return filtered;
});
