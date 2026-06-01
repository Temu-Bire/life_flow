import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/design_system.dart';
import '../../../tasks/presentation/viewmodels/task_viewmodel.dart';
import '../../../goals/presentation/viewmodels/goal_viewmodel.dart';
import '../viewmodels/focus_viewmodel.dart';
import '../../domain/models/focus_session_model.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/premium_button.dart';

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> with SingleTickerProviderStateMixin {
  AnimationController? _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _waveController?.dispose();
    super.dispose();
  }

  void _triggerWaveAnimation(bool isRunning) {
    if (isRunning) {
      _waveController?.repeat();
    } else {
      _waveController?.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final focusState = ref.watch(focusProvider);
    final tasks = ref.watch(taskListProvider);
    final goals = ref.watch(goalListProvider);

    _triggerWaveAnimation(focusState.isRunning);

    // Format time remaining
    final minutes = (focusState.remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (focusState.remainingSeconds % 60).toString().padLeft(2, '0');

    // Total hours logged today
    final double todayFocusHours = focusState.history
        .where((s) {
          final now = DateTime.now();
          return s.startTime.year == now.year &&
              s.startTime.month == now.month &&
              s.startTime.day == now.day;
        })
        .map((s) => s.durationSeconds)
        .fold(0.0, (prev, element) => prev + (element / 3600.0));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text("Focus Engine", style: AppTextStyles.titleLarge),
              const SizedBox(height: 4),
              Text("Enter deep focus block state and mute distractions", style: AppTextStyles.bodyMedium),
              const SizedBox(height: 24),

              // KPI Stats
              Row(
                children: [
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.local_fire_department, color: AppColors.warning, size: 24),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Focus Streak", style: AppTextStyles.caption),
                              Text("${focusState.focusStreak} Days", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.hourglass_empty, color: AppColors.secondary, size: 24),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Focused Today", style: AppTextStyles.caption),
                              Text("${todayFocusHours.toStringAsFixed(1)} hrs", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Fullscreen-like Focus countdown circle
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.02),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                    boxShadow: [
                      BoxShadow(
                        color: focusState.isRunning
                            ? AppColors.primary.withOpacity(0.12)
                            : Colors.transparent,
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Radial wave overlay
                      if (focusState.isRunning)
                        AnimatedBuilder(
                          animation: _waveController!,
                          builder: (context, child) {
                            return Container(
                              width: 150 + (60 * _waveController!.value),
                              height: 150 + (60 * _waveController!.value),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primaryLight.withOpacity((1.0 - _waveController!.value) * 0.3),
                                  width: 2,
                                ),
                              ),
                            );
                          },
                        ),
                      
                      // Progress indicators
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: CircularProgressIndicator(
                          value: focusState.remainingSeconds / focusState.durationSeconds,
                          strokeWidth: 8,
                          backgroundColor: Colors.white.withOpacity(0.04),
                          color: focusState.isBreak ? AppColors.success : AppColors.primaryLight,
                        ),
                      ),
                      
                      // Text Timer
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "$minutes:$seconds",
                            style: AppTextStyles.titleLarge.copyWith(fontSize: 48, letterSpacing: -1),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            focusState.isBreak ? "REST BREAK" : "DEEP WORK FOCUS",
                            style: TextStyle(
                              color: focusState.isBreak ? AppColors.success : AppColors.primaryLight,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons (Play, pause, stop, select minutes)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Presets
                  _buildPresetButton(15),
                  const SizedBox(width: 8),
                  _buildPresetButton(25),
                  const SizedBox(width: 8),
                  _buildPresetButton(45),
                  const SizedBox(width: 8),
                  _buildPresetButton(60),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppColors.textSecondary, size: 28),
                    onPressed: () => ref.read(focusProvider.notifier).resetTimer(),
                  ),
                  const SizedBox(width: 24),
                  GestureDetector(
                    onTap: () {
                      final notifier = ref.read(focusProvider.notifier);
                      if (focusState.isRunning) {
                        notifier.pauseTimer();
                      } else {
                        notifier.startTimer();
                      }
                    },
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                      ),
                      child: Icon(
                        focusState.isRunning ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    icon: const Icon(Icons.stop_circle_outlined, color: AppColors.danger, size: 28),
                    onPressed: () {
                      ref.read(focusProvider.notifier).pauseTimer();
                      ref.read(focusProvider.notifier).resetTimer();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Ambient sound machine placeholder
              Text("Ambient Noise Machine", style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildAmbientSoundCard("None", Icons.volume_off),
                    _buildAmbientSoundCard("Rain", Icons.umbrella),
                    _buildAmbientSoundCard("Ocean Waves", Icons.waves),
                    _buildAmbientSoundCard("Forest Flow", Icons.forest),
                    _buildAmbientSoundCard("Binaural Beats", Icons.graphic_eq),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Task context linking selector
              Text("Deep Work Objective", style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: AppDecorations.glassDecoration(borderRadius: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: focusState.activeTaskId,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: Colors.white),
                    hint: const Text("Select active task to link Focus time...", style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    onChanged: (val) {
                      if (val == null) {
                        ref.read(focusProvider.notifier).selectTask(null, null);
                      } else {
                        final task = tasks.firstWhere((t) => t.id == val);
                        ref.read(focusProvider.notifier).selectTask(task.id, task.goalId);
                      }
                    },
                    items: [
                      const DropdownMenuItem(value: null, child: Text("No Associated Task — Focus freely")),
                      ...tasks.where((t) => !t.isCompleted).map((t) => DropdownMenuItem(value: t.id, child: Text(t.title))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Custom premium heat grid calendar
              Text("Focus Heatmap Grid", style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildFocusHeatmap(focusState.history),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetButton(int mins) {
    final active = ref.watch(focusProvider).durationSeconds == mins * 60;
    return GestureDetector(
      onTap: () {
        ref.read(focusProvider.notifier).configureTimer(mins);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? AppColors.primaryLight : Colors.white.withOpacity(0.05)),
        ),
        child: Text(
          "${mins}m",
          style: TextStyle(
            color: active ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildAmbientSoundCard(String soundName, IconData icon) {
    final focusState = ref.watch(focusProvider);
    final isSelected = focusState.activeAmbientSound == soundName;

    return GestureDetector(
      onTap: () {
        ref.read(focusProvider.notifier).selectAmbientSound(soundName);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 100,
        height: 80,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary.withOpacity(0.12) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.secondary : Colors.white.withOpacity(0.05),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? AppColors.secondaryLight : AppColors.textSecondary, size: 24),
            const SizedBox(height: 8),
            Text(
              soundName,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusHeatmap(List<FocusSessionModel> history) {
    // Generate a 7x8 matrix of mock days representing last 8 weeks.
    // Index 0 represents today, index 55 represents 8 weeks ago.
    final today = DateTime.now();
    
    // Map dates to completed focus count
    final Map<String, int> sessionCountByDate = {};
    for (var session in history) {
      final key = DateFormat('yyyy-MM-dd').format(session.startTime);
      sessionCountByDate[key] = (sessionCountByDate[key] ?? 0) + 1;
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Last 8 Weeks of Focus Blocks", style: AppTextStyles.caption),
              Row(
                children: [
                  Text("Less  ", style: AppTextStyles.caption.copyWith(fontSize: 9)),
                  _buildColorLegendBox(Colors.white.withOpacity(0.05)),
                  const SizedBox(width: 3),
                  _buildColorLegendBox(AppColors.primary.withOpacity(0.3)),
                  const SizedBox(width: 3),
                  _buildColorLegendBox(AppColors.primary.withOpacity(0.6)),
                  const SizedBox(width: 3),
                  _buildColorLegendBox(AppColors.primary),
                  Text("  More", style: AppTextStyles.caption.copyWith(fontSize: 9)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, // 7 days in a week
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
            ),
            itemCount: 56, // 8 weeks
            itemBuilder: (context, index) {
              // Calculate date for this slot (reverse order)
              final date = today.subtract(Duration(days: 55 - index));
              final dateKey = DateFormat('yyyy-MM-dd').format(date);
              final sessionCount = sessionCountByDate[dateKey] ?? 0;

              Color cellColor = Colors.white.withOpacity(0.04);
              if (sessionCount > 0) {
                if (sessionCount == 1) {
                  cellColor = AppColors.primary.withOpacity(0.35);
                } else if (sessionCount == 2) {
                  cellColor = AppColors.primary.withOpacity(0.65);
                } else {
                  cellColor = AppColors.primary;
                }
              }

              return Tooltip(
                message: "${DateFormat('MMM d').format(date)}: $sessionCount focus sessions",
                child: Container(
                  decoration: BoxDecoration(
                    color: cellColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildColorLegendBox(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
