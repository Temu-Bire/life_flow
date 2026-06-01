import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/design_system.dart';
import '../../../tasks/presentation/viewmodels/task_viewmodel.dart';
import '../../../habits/presentation/viewmodels/habit_viewmodel.dart';
import '../viewmodels/analytics_viewmodel.dart';
import '../../../../shared/widgets/glass_card.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(analyticsProvider);
    final tasks = ref.watch(taskListProvider);
    final habits = ref.watch(habitListProvider);

    // Calculate Life Balance metrics dynamically based on task & habit categories:
    // Dimensions: Career (Work), Health, Learning, Social (Relationships), Spiritual, Fitness, Rest
    final double workScore = _calcCategoryScore(tasks, habits, ["work", "career"]);
    final double healthScore = _calcCategoryScore(tasks, habits, ["health", "mind"]);
    final double learningScore = _calcCategoryScore(tasks, habits, ["learning", "study", "books"]);
    final double socialScore = _calcCategoryScore(tasks, habits, ["social", "relationships", "family"]);
    final double spiritualScore = _calcCategoryScore(tasks, habits, ["spiritual", "meditate"]);
    final double fitnessScore = _calcCategoryScore(tasks, habits, ["fitness", "gym", "exercise"]);
    final double restScore = _calcCategoryScore(tasks, habits, ["rest", "sleep"]);

    final radarData = [
      workScore,
      healthScore,
      learningScore,
      socialScore,
      spiritualScore,
      fitnessScore,
      restScore
    ];

    // Compute composite Life Balance index
    final double lifeBalanceScore = (radarData.reduce((a, b) => a + b) / radarData.length) * 100.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text("Analytics Board", style: AppTextStyles.titleLarge),
              const SizedBox(height: 4),
              Text("In-depth metrics of your cognitive performance", style: AppTextStyles.bodyMedium),
              const SizedBox(height: 24),

              // Life Balance Composite Score Header
              GlassCard(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 68,
                          height: 68,
                          child: CircularProgressIndicator(
                            value: lifeBalanceScore / 100.0,
                            strokeWidth: 5,
                            backgroundColor: Colors.white10,
                            color: AppColors.secondary,
                          ),
                        ),
                        Text(
                          "${lifeBalanceScore.toInt()}%",
                          style: AppTextStyles.titleMedium.copyWith(fontSize: 16, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Life Balance Score", style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(
                            lifeBalanceScore >= 75
                                ? "Your routines are extremely balanced! Great job."
                                : "Add habits in learning or spiritual areas to raise balance.",
                            style: AppTextStyles.caption.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Life Balance Radar Chart Widget
              Text("Life Balance Dimensions", style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                height: 240,
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: CustomPaint(
                    painter: LifeBalanceRadarPainter(
                      dataPoints: radarData,
                      labels: const ["Career", "Health", "Learn", "Social", "Spirit", "Fit", "Rest"],
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Focus trends line chart
              Text("Deep Focus Trends (Hours)", style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: GlassCard(
                  padding: const EdgeInsets.only(top: 20, right: 20, bottom: 8, left: 8),
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
                                case 0: return const Text("Mon", style: TextStyle(color: Colors.white24, fontSize: 9));
                                case 1: return const Text("Tue", style: TextStyle(color: Colors.white24, fontSize: 9));
                                case 2: return const Text("Wed", style: TextStyle(color: Colors.white24, fontSize: 9));
                                case 3: return const Text("Thu", style: TextStyle(color: Colors.white24, fontSize: 9));
                                case 4: return const Text("Fri", style: TextStyle(color: Colors.white24, fontSize: 9));
                                case 5: return const Text("Sat", style: TextStyle(color: Colors.white24, fontSize: 9));
                                case 6: return const Text("Sun", style: TextStyle(color: Colors.white24, fontSize: 9));
                                default: return const Text("");
                              }
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            const FlSpot(0, 1.2),
                            const FlSpot(1, 2.5),
                            const FlSpot(2, 0.8),
                            FlSpot(3, stats.weeklyFocusHours > 0 ? stats.weeklyFocusHours : 3.0),
                            const FlSpot(4, 2.1),
                            const FlSpot(5, 4.0),
                            const FlSpot(6, 1.5),
                          ],
                          isCurved: true,
                          color: AppColors.secondaryLight,
                          barWidth: 4,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.secondary.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Mood distributions
              Text("Emotional Energy Log", style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: stats.moodDistribution.entries.map((entry) {
                    final int count = entry.value;
                    final double ratio = stats.moodDistribution.values.isEmpty
                        ? 0.0
                        : (count / stats.moodDistribution.values.reduce((a, b) => a > b ? a : b)).clamp(0.0, 1.0);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          SizedBox(width: 76, child: Text(entry.key, style: const TextStyle(color: Colors.white, fontSize: 12))),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: ratio == 0 && count > 0 ? 0.1 : ratio,
                                minHeight: 8,
                                backgroundColor: Colors.white05,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text("$count", style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  double _calcCategoryScore(dynamic tasks, dynamic habits, List<String> matchWords) {
    // Return a ratio of completed items in these categories between 0.3 (default baseline) and 1.0
    int totalCount = 0;
    int completedCount = 0;

    for (var t in tasks) {
      if (matchWords.any((word) => t.category.toLowerCase().contains(word) || t.title.toLowerCase().contains(word))) {
        totalCount++;
        if (t.isCompleted) completedCount++;
      }
    }
    for (var h in habits) {
      if (matchWords.any((word) => h.category.toLowerCase().contains(word) || h.name.toLowerCase().contains(word))) {
        totalCount++;
        if (h.history.isNotEmpty) completedCount++;
      }
    }

    if (totalCount == 0) return 0.4; // Default balanced score if no data matches
    return (completedCount / totalCount).clamp(0.2, 1.0);
  }
}

// Custom Painter for Radar Chart
class LifeBalanceRadarPainter extends CustomPainter {
  final List<double> dataPoints;
  final List<String> labels;

  LifeBalanceRadarPainter({required this.dataPoints, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double maxRadius = math.min(size.width, size.height) / 2.3;

    final paintLine = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final paintWeb = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final paintFill = Paint()
      ..color = AppColors.secondary.withOpacity(0.18)
      ..style = PaintingStyle.fill;

    final paintStroke = Paint()
      ..color = AppColors.secondaryLight
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final int sides = dataPoints.length;
    final double angle = (2 * math.pi) / sides;

    // 1. Draw web grid levels (3 concentric polygons)
    for (int i = 1; i <= 3; i++) {
      final double currentRadius = maxRadius * (i / 3.0);
      final path = Path();
      for (int j = 0; j < sides; j++) {
        final x = center.dx + currentRadius * math.cos(j * angle - math.pi / 2);
        final y = center.dy + currentRadius * math.sin(j * angle - math.pi / 2);
        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, paintWeb);
    }

    // 2. Draw axis lines & labels
    final textStyle = const TextStyle(color: AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.bold);
    for (int j = 0; j < sides; j++) {
      final x = center.dx + maxRadius * math.cos(j * angle - math.pi / 2);
      final y = center.dy + maxRadius * math.sin(j * angle - math.pi / 2);
      canvas.drawLine(center, Offset(x, y), paintLine);

      // Label text
      final textSpan = TextSpan(text: labels[j], style: textStyle);
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout();

      // Position label slightly outward
      final lx = center.dx + (maxRadius + 14) * math.cos(j * angle - math.pi / 2) - textPainter.width / 2;
      final ly = center.dy + (maxRadius + 10) * math.sin(j * angle - math.pi / 2) - textPainter.height / 2;
      textPainter.paint(canvas, Offset(lx, ly));
    }

    // 3. Draw data polygon
    final dataPath = Path();
    for (int j = 0; j < sides; j++) {
      final double valueRadius = maxRadius * dataPoints[j];
      final x = center.dx + valueRadius * math.cos(j * angle - math.pi / 2);
      final y = center.dy + valueRadius * math.sin(j * angle - math.pi / 2);
      if (j == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();
    canvas.drawPath(dataPath, paintFill);
    canvas.drawPath(dataPath, paintStroke);

    // 4. Draw data point dots
    final paintDot = Paint()..color = Colors.white;
    for (int j = 0; j < sides; j++) {
      final double valueRadius = maxRadius * dataPoints[j];
      final x = center.dx + valueRadius * math.cos(j * angle - math.pi / 2);
      final y = center.dy + valueRadius * math.sin(j * angle - math.pi / 2);
      canvas.drawCircle(Offset(x, y), 3, paintDot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
