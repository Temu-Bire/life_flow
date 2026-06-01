import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/design_system.dart';
import '../../../habits/presentation/viewmodels/habit_viewmodel.dart';
import '../../../tasks/presentation/viewmodels/task_viewmodel.dart';
import '../../domain/models/goal_model.dart';
import '../viewmodels/goal_viewmodel.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/premium_button.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  GoalTimeframe _selectedTimeframe = GoalTimeframe.monthly;
  GoalCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddGoalSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddGoalBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goals = ref.watch(goalListProvider);

    // Filters
    final filteredGoals = goals.where((g) {
      final matchesTimeframe = g.timeframe == _selectedTimeframe;
      final matchesCategory = _selectedCategory == null || g.category == _selectedCategory;
      return matchesTimeframe && matchesCategory;
    }).toList();

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
                    Text("Growth Goals", style: AppTextStyles.titleLarge),
                    const SizedBox(height: 4),
                    Text("Define your path and track milestones", style: AppTextStyles.bodyMedium),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.primaryLight, size: 36),
                  onPressed: () => _showAddGoalSheet(context),
                  tooltip: "Create Goal",
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tabs: Board vs Tree Hierarchy
            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: const [
                Tab(text: "Growth Board"),
                Tab(text: "Tree Roadmap"),
              ],
            ),
            const SizedBox(height: 16),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Board view
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timeframe filter chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: GoalTimeframe.values.map((tf) {
                            final isSelected = _selectedTimeframe == tf;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedTimeframe = tf),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primaryLight : Colors.white.withOpacity(0.05),
                                  ),
                                ),
                                child: Text(
                                  tf.name.substring(0, 1).toUpperCase() + tf.name.substring(1),
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
                      ),
                      const SizedBox(height: 12),

                      // Category filter chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _selectedCategory = null),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _selectedCategory == null ? AppColors.secondary : Colors.white.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _selectedCategory == null ? AppColors.secondaryLight : Colors.white.withOpacity(0.05),
                                  ),
                                ),
                                child: Text(
                                  "All Categories",
                                  style: TextStyle(
                                    color: _selectedCategory == null ? Colors.white : AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            ...GoalCategory.values.map((cat) {
                              final isSelected = _selectedCategory == cat;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedCategory = cat),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.secondary : Colors.white.withOpacity(0.04),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected ? AppColors.secondaryLight : Colors.white.withOpacity(0.05),
                                    ),
                                  ),
                                  child: Text(
                                    cat.name.substring(0, 1).toUpperCase() + cat.name.substring(1),
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Goals Grid / List
                      Expanded(
                        child: filteredGoals.isEmpty
                            ? EmptyStateView(
                                icon: Icons.insights,
                                title: "No goals found",
                                description: "Ready to focus your life direction? Tap the icon above to define a new growth goal.",
                              )
                            : ListView.builder(
                                itemCount: filteredGoals.length,
                                itemBuilder: (context, index) {
                                  final goal = filteredGoals[index];
                                  return _buildGoalCard(context, goal);
                                },
                              ),
                      ),
                    ],
                  ),

                  // Tree Hierarchy view
                  _buildTreeHierarchyView(goals),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, GoalModel goal) {
    final habits = ref.watch(habitListProvider);
    final tasks = ref.watch(taskListProvider);

    // Calculate aggregated status from linked items
    final linkedTasks = tasks.where((t) => goal.linkedTaskIds.contains(t.id)).toList();
    final completedLinkedTasks = linkedTasks.where((t) => t.isCompleted).length;
    
    double progress = goal.milestoneProgress;
    if (linkedTasks.isNotEmpty) {
      // average progress of tasks + milestones
      final double taskProgress = completedLinkedTasks / linkedTasks.length;
      progress = (progress + taskProgress) / 2.0;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        borderRadius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category & Timeframe tags
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Text(
                    goal.category.name.toUpperCase(),
                    style: const TextStyle(color: AppColors.primaryLight, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  goal.targetDate != null ? DateFormat('MMM d, y').format(goal.targetDate!) : "No deadline",
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Title & Description
            Text(
              goal.title,
              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (goal.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                goal.description,
                style: AppTextStyles.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),

            // Progress Indicators
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.white10,
                      color: AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "${(progress * 100).toInt()}%",
                  style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.success),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Expandable Milestones checklist
            if (goal.milestones.isNotEmpty) ...[
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 12),
              Text("Milestones", style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...List.generate(goal.milestones.length, (milestoneIdx) {
                final milestone = goal.milestones[milestoneIdx];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          ref.read(goalListProvider.notifier).toggleMilestone(goal.id, milestoneIdx);
                        },
                        child: Icon(
                          milestone.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: milestone.isCompleted ? AppColors.success : AppColors.textSecondary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        milestone.title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 13,
                          decoration: milestone.isCompleted ? TextDecoration.lineThrough : null,
                          color: milestone.isCompleted ? AppColors.textSecondary : Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            // Add Milestone button & Link counters
            const SizedBox(height: 12),
            Row(
              children: [
                if (linkedTasks.isNotEmpty) ...[
                  Icon(Icons.checklist, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text("$completedLinkedTasks/${linkedTasks.length} Tasks", style: AppTextStyles.caption),
                  const SizedBox(width: 12),
                ],
                if (goal.linkedHabitIds.isNotEmpty) ...[
                  Icon(Icons.autorenew, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text("${goal.linkedHabitIds.length} Habits", style: AppTextStyles.caption),
                ],
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    _showAddMilestoneDialog(context, goal.id);
                  },
                  icon: const Icon(Icons.add, size: 14, color: AppColors.primaryLight),
                  label: Text("Milestone", style: TextStyle(color: AppColors.primaryLight, fontSize: 12)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: AppColors.danger),
                  onPressed: () {
                    ref.read(goalListProvider.notifier).deleteGoal(goal.id);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMilestoneDialog(BuildContext context, String goalId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("New Milestone", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter milestone title...",
            hintStyle: TextStyle(color: AppColors.textMuted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel", style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(goalListProvider.notifier).addMilestone(goalId, controller.text);
                Navigator.of(ctx).pop();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text("Add", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeHierarchyView(List<GoalModel> goals) {
    // Show goals mapped hierarchically. e.g. Vision -> 5-Year -> 1-Year -> Quarterly
    // Find top levels (parentId is null)
    final topLevelGoals = goals.where((g) => g.parentId == null).toList();

    if (goals.isEmpty) {
      return EmptyStateView(
        icon: Icons.account_tree,
        title: "Roadmap is empty",
        description: "Add goals and link child goals to structure your personal growth tree roadmap.",
      );
    }

    return ListView.builder(
      itemCount: topLevelGoals.length,
      itemBuilder: (context, index) {
        final parent = topLevelGoals[index];
        final children = goals.where((g) => g.parentId == parent.id).toList();

        return Card(
          color: Colors.white.withOpacity(0.02),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white10),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            title: Text(parent.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(
              "${parent.timeframe.name.toUpperCase()} • ${parent.category.name}",
              style: TextStyle(color: AppColors.primaryLight, fontSize: 10, fontWeight: FontWeight.bold),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: parent.isCompleted ? AppColors.success.withOpacity(0.12) : Colors.white10,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                parent.isCompleted ? "COMPLETED" : "ACTIVE",
                style: TextStyle(
                  color: parent.isCompleted ? AppColors.success : AppColors.textSecondary,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            children: [
              if (children.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "No sub-goals linked to this goal yet.",
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                )
              else
                ...children.map((child) {
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    leading: const Icon(Icons.subdirectory_arrow_right, color: AppColors.primaryLight, size: 16),
                    title: Text(child.title, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    subtitle: Text("${child.timeframe.name.toUpperCase()} • Milestone: ${(child.milestoneProgress * 100).toInt()}%", style: const TextStyle(fontSize: 10)),
                    trailing: Icon(
                      child.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                      color: child.isCompleted ? AppColors.success : AppColors.textMuted,
                      size: 16,
                    ),
                    onTap: () {
                      ref.read(goalListProvider.notifier).toggleGoalCompleted(child.id);
                    },
                  );
                }).toList(),
            ],
          ),
        );
      },
    );
  }
}

// Add Goal Bottom Sheet Modal
class AddGoalBottomSheet extends ConsumerStatefulWidget {
  const AddGoalBottomSheet({super.key});

  @override
  ConsumerState<AddGoalBottomSheet> createState() => _AddGoalBottomSheetState();
}

class _AddGoalBottomSheetState extends ConsumerState<AddGoalBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _notesController = TextEditingController();

  GoalCategory _category = GoalCategory.personalGrowth;
  GoalTimeframe _timeframe = GoalTimeframe.monthly;
  String? _parentId;
  DateTime? _targetDate;

  final List<GoalMilestone> _milestones = [];
  final _milestoneController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _notesController.dispose();
    _milestoneController.dispose();
    super.dispose();
  }

  void _addMilestone() {
    if (_milestoneController.text.isNotEmpty) {
      setState(() {
        _milestones.add(GoalMilestone(title: _milestoneController.text));
        _milestoneController.clear();
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref.read(goalListProvider.notifier).addGoal(
            title: _titleController.text,
            description: _descController.text,
            category: _category,
            timeframe: _timeframe,
            parentId: _parentId,
            targetDate: _targetDate,
            milestones: _milestones,
            notes: _notesController.text,
          );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final allGoals = ref.watch(goalListProvider);

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
              Text("Create Growth Goal", style: AppTextStyles.titleMedium),
              const SizedBox(height: 18),

              // Title
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Goal Title",
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                ),
                validator: (val) => val == null || val.isEmpty ? "Goal title is required" : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Description",
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                ),
              ),
              const SizedBox(height: 24),

              // Dropdowns: Category, Timeframe
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<GoalCategory>(
                      value: _category,
                      dropdownColor: AppColors.surface,
                      decoration: const InputDecoration(labelText: "Category", border: InputBorder.none),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (val) => setState(() => _category = val!),
                      items: GoalCategory.values
                          .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                          .toList(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<GoalTimeframe>(
                      value: _timeframe,
                      dropdownColor: AppColors.surface,
                      decoration: const InputDecoration(labelText: "Timeframe", border: InputBorder.none),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (val) => setState(() => _timeframe = val!),
                      items: GoalTimeframe.values
                          .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                          .toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Parent goal mapping dropdown (if we want hierarchy)
              DropdownButtonFormField<String?>(
                value: _parentId,
                dropdownColor: AppColors.surface,
                decoration: const InputDecoration(labelText: "Parent Goal (Optional Roadmap Hierarchy)", border: InputBorder.none),
                style: const TextStyle(color: Colors.white),
                onChanged: (val) => setState(() => _parentId = val),
                items: [
                  const DropdownMenuItem(value: null, child: Text("None — Top level Goal")),
                  ...allGoals.map((g) => DropdownMenuItem(value: g.id, child: Text("${g.title} (${g.timeframe.name})"))),
                ],
              ),
              const SizedBox(height: 12),

              // Target Date Selector
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month, color: AppColors.primaryLight),
                title: Text(
                  _targetDate == null
                      ? "Set Target Date"
                      : "Target: ${DateFormat('EEE, MMM d, y').format(_targetDate!)}",
                  style: TextStyle(color: _targetDate == null ? AppColors.textSecondary : Colors.white),
                ),
                trailing: _targetDate != null
                    ? IconButton(
                        icon: const Icon(Icons.close, color: AppColors.danger),
                        onPressed: () => setState(() => _targetDate = null),
                      )
                    : null,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (picked != null) {
                    setState(() => _targetDate = picked);
                  }
                },
              ),
              const Divider(color: Colors.white10),

              // Milestones
              Text("SMART Milestones (${_milestones.length})", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              if (_milestones.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  children: _milestones
                      .map((m) => Chip(
                            backgroundColor: Colors.white10,
                            label: Text(m.title, style: const TextStyle(color: Colors.white, fontSize: 11)),
                            onDeleted: () => setState(() => _milestones.remove(m)),
                            deleteIcon: const Icon(Icons.close, size: 14, color: AppColors.danger),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _milestoneController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: "Add milestone...",
                        hintStyle: TextStyle(color: AppColors.textMuted),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _addMilestone(),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.add_circle, color: AppColors.primaryLight), onPressed: _addMilestone),
                ],
              ),
              const Divider(color: Colors.white10),
              const SizedBox(height: 24),

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
                    child: const Text("Save Goal", style: TextStyle(color: Colors.white)),
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
