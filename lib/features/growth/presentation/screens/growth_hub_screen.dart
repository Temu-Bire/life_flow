import 'package:flutter/material.dart';
import '../../../../core/theme/design_system.dart';
import '../../../goals/presentation/screens/goals_screen.dart';
import '../../../habits/presentation/screens/habits_screen.dart';
import '../../../knowledge/presentation/screens/knowledge_screen.dart';

class GrowthHubScreen extends StatefulWidget {
  const GrowthHubScreen({super.key});

  @override
  State<GrowthHubScreen> createState() => _GrowthHubScreenState();
}

class _GrowthHubScreenState extends State<GrowthHubScreen> with SingleTickerProviderStateMixin {
  late TabController _hubTabController;

  @override
  void initState() {
    super.initState();
    _hubTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _hubTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.insights, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              "Growth Systems Hub",
              style: AppTextStyles.titleMedium.copyWith(fontSize: 20, letterSpacing: -0.5),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _hubTabController,
          indicatorColor: AppColors.primaryLight,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: "Goals & Vision"),
            Tab(text: "Habits Daily"),
            Tab(text: "Second Brain"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _hubTabController,
        children: const [
          GoalsScreen(),
          HabitsScreen(),
          KnowledgeScreen(),
        ],
      ),
    );
  }
}
