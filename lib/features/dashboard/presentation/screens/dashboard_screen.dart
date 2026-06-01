import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/services/insight_service.dart';
import '../../../tasks/presentation/viewmodels/task_viewmodel.dart';
import '../../../tasks/domain/models/task_model.dart';
import '../../../analytics/presentation/viewmodels/analytics_viewmodel.dart';
import '../viewmodels/gamification_provider.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/premium_button.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getDynamicGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good morning,";
    } else if (hour < 17) {
      return "Good afternoon,";
    } else {
      return "Good evening,";
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamState = ref.watch(gamificationProvider);
    final insights = ref.watch(insightProvider);
    final tasks = ref.watch(taskListProvider);
    final stats = ref.watch(analyticsProvider);

    // Filter critical high priority tasks
    final criticalTasks = tasks
        .where((t) => !t.isCompleted && !t.isArchived && (t.priority == TaskPriority.high || t.priority == TaskPriority.critical))
        .take(3)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getDynamicGreeting(),
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Achiever",
                        style: AppTextStyles.titleLarge.copyWith(fontSize: 30, letterSpacing: -0.5),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.go('/settings'),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: AppDecorations.glassDecoration(borderRadius: 12),
                      child: const Icon(Icons.settings, color: Colors.white70, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Gamification XP Level Progress Card
              _buildGamificationCard(context, gamState),
              const SizedBox(height: 24),

              // Quick Actions Hub
              Text("Systems Actions", style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context,
                      Icons.hourglass_empty,
                      AppColors.primaryLight,
                      "Start Focus",
                      () => context.go('/focus'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      Icons.history_edu,
                      AppColors.secondaryLight,
                      "Reflect Review",
                      () => context.go('/journal'), // Navigates to journal/reflection shell
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      Icons.psychology,
                      AppColors.success,
                      "Capture Idea",
                      () => context.go('/habits'), // Temporarily redirects to growth hub/habits
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Smart Productivity Insights Carousal Slider
              Text("Productivity Insights", style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                height: 124,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: insights.length,
                  itemBuilder: (context, index) {
                    final ins = insights[index];
                    return _buildInsightCard(ins);
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Split panel: Critical Items & Unlocked Badges
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Critical Items
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Critical Tasks", style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        if (criticalTasks.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                            decoration: AppDecorations.glassDecoration(borderRadius: 16),
                            child: const Center(
                              child: Text(
                                "No critical tasks pending! ✅",
                                style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontStyle: FontStyle.italic),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        else
                          Column(
                            children: criticalTasks.map((t) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.02),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.danger,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        t.title,
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        ref.read(taskListProvider.notifier).toggleTaskCompleted(t.id);
                                      },
                                      child: const Icon(Icons.circle_outlined, color: AppColors.textMuted, size: 16),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Unlocked Badges Mini Showcase
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Badges", style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        GlassCard(
                          padding: const EdgeInsets.all(12),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: gamState.badges.map((badge) {
                              return Opacity(
                                opacity: badge.isUnlocked ? 1.0 : 0.2,
                                child: Tooltip(
                                  message: "${badge.title}: ${badge.description}",
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: badge.isUnlocked ? AppColors.primary.withOpacity(0.12) : Colors.white.withOpacity(0.02),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: badge.isUnlocked ? AppColors.primaryLight : Colors.transparent,
                                      ),
                                    ),
                                    child: Text(badge.icon, style: const TextStyle(fontSize: 18)),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGamificationCard(BuildContext context, GamificationState gamState) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.12),
                ),
                child: const Text("⚡", style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gamState.rankName,
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      "Level ${gamState.level}",
                      style: AppTextStyles.caption.copyWith(color: Colors.white70, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Text(
                "${gamState.totalXp} XP",
                style: AppTextStyles.titleMedium.copyWith(color: Colors.white, fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: 18),
          
          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: gamState.xpInCurrentLevel / (gamState.xpInCurrentLevel + gamState.xpNeededForNextLevel),
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${gamState.xpInCurrentLevel} / ${(gamState.xpInCurrentLevel + gamState.xpNeededForNextLevel)} XP",
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
              Text(
                "${gamState.xpNeededForNextLevel} XP to Level UP",
                style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, Color color, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(ProductivityInsight ins) {
    Color typeColor = AppColors.info;
    IconData icon = Icons.info_outline;

    if (ins.type == "warning") {
      typeColor = AppColors.warning;
      icon = Icons.warning_amber_rounded;
    } else if (ins.type == "success") {
      typeColor = AppColors.success;
      icon = Icons.check_circle_outline;
    } else if (ins.type == "burnout") {
      typeColor = AppColors.danger;
      icon = Icons.local_fire_department;
    }

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: typeColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ins.title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      ins.description,
                      style: AppTextStyles.caption.copyWith(fontSize: 10, height: 1.3),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
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
}
