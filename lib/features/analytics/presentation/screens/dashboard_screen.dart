import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/design_system.dart';
import '../../../tasks/presentation/viewmodels/task_viewmodel.dart';
import '../../../tasks/domain/models/task_model.dart';
import '../viewmodels/analytics_viewmodel.dart';
import '../../../../shared/widgets/glass_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getDynamicGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good Morning, Achiever";
    } else if (hour < 17) {
      return "Good Afternoon, Achiever";
    } else {
      return "Good Evening, Achiever";
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(analyticsProvider);
    final tasks = ref.watch(taskListProvider);
    
    // Get high priority pending tasks
    final pendingHighTasks = tasks
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
                        style: AppTextStyles.titleLarge.copyWith(fontSize: 26),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Here's your productivity overview for today",
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                  // User Avatar preview
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryLight, width: 1.5),
                      gradient: AppColors.accentGradient,
                    ),
                    child: const Center(
                      child: Icon(Icons.person, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // KPI Dashboard Telemetries
              Row(
                children: [
                  // Productivity Score Circular Card
                  Expanded(
                    flex: 4,
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            "Productivity Score",
                            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 90,
                                height: 90,
                                child: CircularProgressIndicator(
                                  value: stats.productivityScore / 100,
                                  strokeWidth: 6,
                                  backgroundColor: Colors.white10,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                              Text(
                                "${stats.productivityScore.toInt()}%",
                                style: AppTextStyles.titleMedium.copyWith(fontSize: 20),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            stats.productivityScore >= 80
                                ? "Unstoppable!"
                                : stats.productivityScore >= 50
                                    ? "Good Pace"
                                    : "Keep Moving",
                            style: AppTextStyles.caption.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Other fast metrics
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        _buildQuickMetricCard(
                          Icons.local_fire_department,
                          AppColors.warning,
                          "Max Streaks",
                          "${stats.activeHabitStreak} Days",
                        ),
                        const SizedBox(height: 10),
                        _buildQuickMetricCard(
                          Icons.hourglass_bottom,
                          AppColors.secondary,
                          "Focus Timer",
                          "${stats.weeklyFocusHours.toStringAsFixed(1)} hrs",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Deep Work Focus Graph (Curved Chart)
              Text("Focus Trends", style: AppTextStyles.titleMedium.copyWith(fontSize: 18)),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: GlassCard(
                  padding: const EdgeInsets.only(top: 20, right: 24, bottom: 8, left: 8),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              switch (value.toInt()) {
                                case 0:
                                  return const Text("M", style: TextStyle(color: Colors.white24, fontSize: 10));
                                case 2:
                                  return const Text("W", style: TextStyle(color: Colors.white24, fontSize: 10));
                                case 4:
                                  return const Text("F", style: TextStyle(color: Colors.white24, fontSize: 10));
                                case 6:
                                  return const Text("S", style: TextStyle(color: Colors.white24, fontSize: 10));
                                default:
                                  return const Text("");
                              }
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            const FlSpot(0, 1.5),
                            const FlSpot(1, 2.0),
                            const FlSpot(2, 1.2),
                            FlSpot(3, stats.weeklyFocusHours > 0 ? stats.weeklyFocusHours : 2.5),
                            const FlSpot(4, 1.8),
                            const FlSpot(5, 3.2),
                            const FlSpot(6, 1.0),
                          ],
                          isCurved: true,
                          color: AppColors.primaryLight,
                          barWidth: 4,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.primaryLight.withOpacity(0.12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // High Priority Task Panel & Mood Insights
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // High Priority Tasks
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Critical Items", style: AppTextStyles.titleMedium.copyWith(fontSize: 18)),
                        const SizedBox(height: 12),
                        if (pendingHighTasks.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: AppDecorations.glassDecoration(borderRadius: 16),
                            child: Center(
                              child: Text(
                                "No critical tasks pending!",
                                style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic),
                              ),
                            ),
                          )
                        else
                          Column(
                            children: pendingHighTasks.map((task) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.03),
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
                                        task.title,
                                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Mood Chart summary panel
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Mood Tracker", style: AppTextStyles.titleMedium.copyWith(fontSize: 18)),
                        const SizedBox(height: 12),
                        GlassCard(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMoodInsightRow("😊 Happy", stats.moodDistribution['Happy'] ?? 0),
                              const SizedBox(height: 6),
                              _buildMoodInsightRow("😌 Calm", stats.moodDistribution['Calm'] ?? 0),
                              const SizedBox(height: 6),
                              _buildMoodInsightRow("😐 Neutral", stats.moodDistribution['Neutral'] ?? 0),
                              const SizedBox(height: 6),
                              _buildMoodInsightRow("🤯 Stressed", stats.moodDistribution['Stressed'] ?? 0),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickMetricCard(IconData icon, Color color, String title, String value) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: AppTextStyles.caption),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodInsightRow(String moodName, int count) {
    return Row(
      children: [
        Expanded(
          child: Text(
            moodName,
            style: AppTextStyles.caption.copyWith(fontSize: 10, color: Colors.white),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            "$count",
            style: AppTextStyles.caption.copyWith(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
          ),
        ),
      ],
    );
  }
}
