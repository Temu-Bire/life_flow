import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/database_service.dart';
import '../../domain/models/review_model.dart';

final reviewListProvider = StateNotifierProvider<ReviewViewModel, List<ReviewModel>>((ref) {
  return ReviewViewModel();
});

class ReviewViewModel extends StateNotifier<List<ReviewModel>> {
  final DatabaseService _db = DatabaseService.instance;
  final Uuid _uuid = const Uuid();

  ReviewViewModel() : super([]) {
    _loadReviews();
  }

  void _loadReviews() {
    final raw = _db.getAllReviews();
    final reviews = raw.map((e) => ReviewModel.fromMap(e)).toList();
    reviews.sort((a, b) => b.date.compareTo(a.date));
    state = reviews;
  }

  Future<void> addReview({
    required ReviewType type,
    required Map<String, String> answers,
    required double growthScore,
    String aiInsight = "",
  }) async {
    final newReview = ReviewModel(
      id: _uuid.v4(),
      date: DateTime.now(),
      type: type,
      answers: answers,
      growthScore: growthScore,
      aiInsight: aiInsight,
    );

    state = [newReview, ...state];
    await _db.saveReview(newReview.id, newReview.toMap());
  }

  Future<void> deleteReview(String id) async {
    state = state.where((review) => review.id != id).toList();
    await _db.deleteReview(id);
  }

  // Get reflection consistency streaks
  int getReviewStreak() {
    if (state.isEmpty) return 0;
    
    // Sort ascending
    final sorted = List<ReviewModel>.from(state)..sort((a, b) => a.date.compareTo(b.date));
    
    // Count consecutive weeks or simply review entry count as a general streak indicator
    // For premium simplicity: count total reviews completed in the last 6 months
    final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
    return sorted.where((r) => r.date.isAfter(sixMonthsAgo)).length;
  }
}
