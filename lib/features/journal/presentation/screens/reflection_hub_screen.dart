import 'package:flutter/material.dart';
import '../../../../core/theme/design_system.dart';
import 'journal_screen.dart';
import 'review_screen.dart';

class ReflectionHubScreen extends StatefulWidget {
  const ReflectionHubScreen({super.key});

  @override
  State<ReflectionHubScreen> createState() => _ReflectionHubScreenState();
}

class _ReflectionHubScreenState extends State<ReflectionHubScreen> with SingleTickerProviderStateMixin {
  late TabController _reflectTabController;

  @override
  void initState() {
    super.initState();
    _reflectTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _reflectTabController.dispose();
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
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.history_edu, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              "Reflection Hub",
              style: AppTextStyles.titleMedium.copyWith(fontSize: 20, letterSpacing: -0.5),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _reflectTabController,
          indicatorColor: AppColors.secondary,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: "Daily Journal"),
            Tab(text: "Structured Review"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _reflectTabController,
        children: const [
          JournalScreen(),
          ReviewScreen(),
        ],
      ),
    );
  }
}
