import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/design_system.dart';
import '../../domain/models/review_model.dart';
import '../viewmodels/review_viewmodel.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/premium_button.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  void _startReviewProcess(BuildContext context, ReviewType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReviewFormBottomSheet(type: type),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reviews = ref.watch(reviewListProvider);

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
                    Text("Reflections", style: AppTextStyles.titleLarge),
                    const SizedBox(height: 4),
                    Text("Assess growth, celebrate wins, and adjust", style: AppTextStyles.bodyMedium),
                  ],
                ),
                Icon(Icons.rate_review, color: AppColors.primaryLight.withOpacity(0.8), size: 28),
              ],
            ),
            const SizedBox(height: 24),

            // Start reflection card quick links
            Text("Launch Reflection Review", style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildReviewTriggerCard(
                    "Weekly",
                    Icons.event_note,
                    AppColors.primary,
                    () => _startReviewProcess(context, ReviewType.weekly),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildReviewTriggerCard(
                    "Monthly",
                    Icons.calendar_month,
                    AppColors.secondary,
                    () => _startReviewProcess(context, ReviewType.monthly),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildReviewTriggerCard(
                    "Quarterly",
                    Icons.diamond,
                    AppColors.success,
                    () => _startReviewProcess(context, ReviewType.quarterly),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Reflection logs history
            Text("Review History Log", style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: reviews.isEmpty
                  ? EmptyStateView(
                      icon: Icons.history_edu,
                      title: "No reviews logged",
                      description: "Taking time to reflect is essential. Launch your first Weekly Review to track growth.",
                    )
                  : ListView.builder(
                      itemCount: reviews.length,
                      itemBuilder: (context, index) {
                        final review = reviews[index];
                        return _buildHistoricalReviewCard(context, review);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewTriggerCard(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Text("Review", style: AppTextStyles.caption.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoricalReviewCard(BuildContext context, ReviewModel review) {
    Color typeColor = AppColors.primary;
    if (review.type == ReviewType.monthly) typeColor = AppColors.secondary;
    if (review.type == ReviewType.quarterly) typeColor = AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row metadata
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    review.type.name.toUpperCase(),
                    style: TextStyle(color: typeColor, fontWeight: FontWeight.bold, fontSize: 9),
                  ),
                ),
                Text(DateFormat('MMMM d, yyyy').format(review.date), style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 12),

            // Growth Score indicator
            Row(
              children: [
                Text("Growth Score: ", style: AppTextStyles.bodyMedium.copyWith(fontSize: 12)),
                Text("${review.growthScore.toInt()}/10", style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 13)),
                const Spacer(),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.delete, color: AppColors.danger, size: 16),
                  onPressed: () {
                    ref.read(reviewListProvider.notifier).deleteReview(review.id);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 12),

            // Short QA highlights
            ...review.answers.entries.take(2).map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: Colors.white70),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.value,
                        style: AppTextStyles.bodyMedium.copyWith(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// Reflection form flow bottom sheet
class ReviewFormBottomSheet extends ConsumerStatefulWidget {
  final ReviewType type;
  const ReviewFormBottomSheet({super.key, required this.type});

  @override
  ConsumerState<ReviewFormBottomSheet> createState() => _ReviewFormBottomSheetState();
}

class _ReviewFormBottomSheetState extends ConsumerState<ReviewFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  double _growthScore = 5.0;

  // Question lists based on reflection tier
  final Map<ReviewType, List<String>> _questions = {
    ReviewType.weekly: [
      "What went well this week?",
      "What failed or fell behind schedule?",
      "What was your biggest distraction?",
      "Identify your single biggest win.",
      "What is one concrete improvement to implement next week?",
    ],
    ReviewType.monthly: [
      "Summarize your monthly progress towards goals.",
      "What habits were easiest to sustain, and why?",
      "Where did you face key friction or setbacks?",
      "Detail your learning discoveries this month.",
      "What is the focus theme of the next month?",
    ],
    ReviewType.quarterly: [
      "Assess your high level goals performance.",
      "What major strategic shifts are required now?",
      "Rate your general life balance over the last 90 days.",
      "How did you grow and challenge yourself?",
      "What is the single top priority for the next quarter?",
    ],
  };

  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (var q in _questions[widget.type]!) {
      _controllers[q] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final Map<String, String> answers = {};
      for (var entry in _controllers.entries) {
        answers[entry.key] = entry.value.text;
      }

      // Quick rules-based automatic insight summaries
      String autoInsight = "Reflection logged.";
      if (_growthScore >= 8) {
        autoInsight = "Superb growth index! You are executing objectives clearly. Maintain current habits.";
      } else if (_growthScore <= 4) {
        autoInsight = "Low growth index. Burnout or distraction detected. Dedicate next block to habits adjustment.";
      }

      ref.read(reviewListProvider.notifier).addReview(
            type: widget.type,
            answers: answers,
            growthScore: _growthScore,
            aiInsight: autoInsight,
          );

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${widget.type.name.toUpperCase()} Reflection Saved! Insights generated."),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final questionsList = _questions[widget.type]!;

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${widget.type.name.toUpperCase()} Reflection Review",
                    style: AppTextStyles.titleMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Growth score slider
              Text(
                "Growth Score: ${_growthScore.toInt()}/10",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Slider(
                value: _growthScore,
                min: 1.0,
                max: 10.0,
                divisions: 9,
                activeColor: AppColors.primaryLight,
                inactiveColor: Colors.white10,
                onChanged: (val) => setState(() => _growthScore = val),
              ),
              const Divider(color: Colors.white10, height: 24),

              // QA Forms
              ...questionsList.map((q) => Padding(
                    padding: const EdgeInsets.only(bottom: 18.0),
                    child: TextFormField(
                      controller: _controllers[q],
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: q,
                        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.primaryLight)),
                        fillColor: Colors.white.withOpacity(0.01),
                        filled: true,
                      ),
                      validator: (val) => val == null || val.isEmpty ? "Please answer this question" : null,
                    ),
                  )),

              const SizedBox(height: 16),
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
                    child: const Text("Save Review", style: TextStyle(color: Colors.white)),
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
