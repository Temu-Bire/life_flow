import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/database_service.dart';
import '../../../tasks/presentation/viewmodels/task_viewmodel.dart';
import '../../domain/models/focus_session_model.dart';

class FocusTimerState {
  final int durationSeconds; // Default 25 min = 1500 sec
  final int remainingSeconds;
  final bool isRunning;
  final bool isBreak;
  final String? activeTaskId;
  final String? activeGoalId;
  final String activeAmbientSound; // None, Rain, Waves, Forest, Binaural
  final int focusStreak;
  final List<FocusSessionModel> history;

  FocusTimerState({
    this.durationSeconds = 1500,
    this.remainingSeconds = 1500,
    this.isRunning = false,
    this.isBreak = false,
    this.activeTaskId,
    this.activeGoalId,
    this.activeAmbientSound = "None",
    this.focusStreak = 0,
    this.history = const [],
  });

  FocusTimerState copyWith({
    int? durationSeconds,
    int? remainingSeconds,
    bool? isRunning,
    bool? isBreak,
    String? activeTaskId,
    String? activeGoalId,
    String? activeAmbientSound,
    int? focusStreak,
    List<FocusSessionModel>? history,
  }) {
    return FocusTimerState(
      durationSeconds: durationSeconds ?? this.durationSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      isBreak: isBreak ?? this.isBreak,
      activeTaskId: activeTaskId ?? this.activeTaskId,
      activeGoalId: activeGoalId ?? this.activeGoalId,
      activeAmbientSound: activeAmbientSound ?? this.activeAmbientSound,
      focusStreak: focusStreak ?? this.focusStreak,
      history: history ?? this.history,
    );
  }
}

final focusProvider = StateNotifierProvider<FocusViewModel, FocusTimerState>((ref) {
  return FocusViewModel(ref);
});

class FocusViewModel extends StateNotifier<FocusTimerState> {
  final Ref _ref;
  final DatabaseService _db = DatabaseService.instance;
  final Uuid _uuid = const Uuid();
  Timer? _timer;

  FocusViewModel(this._ref) : super(FocusTimerState()) {
    _loadHistory();
  }

  void _loadHistory() {
    final raw = _db.getAllFocusSessions();
    final list = raw.map((e) => FocusSessionModel.fromMap(e)).toList();
    list.sort((a, b) => b.startTime.compareTo(a.startTime));
    
    // Calculate focus streak
    int streak = _calculateFocusStreak(list);
    state = state.copyWith(history: list, focusStreak: streak);
  }

  int _calculateFocusStreak(List<FocusSessionModel> list) {
    if (list.isEmpty) return 0;
    
    final days = list.map((s) => DateTime(s.startTime.year, s.startTime.month, s.startTime.day)).toSet().toList();
    days.sort((a, b) => b.compareTo(a)); // Descending
    
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (days.isEmpty || (days.first != today && days.first != yesterday)) {
      return 0;
    }

    int streak = 1;
    for (int i = 0; i < days.length - 1; i++) {
      if (days[i].difference(days[i + 1]).inDays == 1) {
        streak++;
      } else if (days[i].difference(days[i + 1]).inDays > 1) {
        break;
      }
    }
    return streak;
  }

  void selectTask(String? taskId, String? goalId) {
    state = state.copyWith(activeTaskId: taskId, activeGoalId: goalId);
  }

  void selectAmbientSound(String sound) {
    state = state.copyWith(activeAmbientSound: sound);
  }

  void configureTimer(int minutes) {
    final seconds = minutes * 60;
    state = state.copyWith(
      durationSeconds: seconds,
      remainingSeconds: seconds,
      isRunning: false,
    );
    _timer?.cancel();
  }

  void startTimer() {
    if (state.isRunning) return;

    state = state.copyWith(isRunning: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 0) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        _onTimerComplete();
      }
    });
  }

  void pauseTimer() {
    state = state.copyWith(isRunning: false);
    _timer?.cancel();
  }

  void resetTimer() {
    state = state.copyWith(
      remainingSeconds: state.durationSeconds,
      isRunning: false,
    );
    _timer?.cancel();
  }

  Future<void> _onTimerComplete() async {
    _timer?.cancel();
    
    if (!state.isBreak) {
      // Completed Focus Session!
      final completedSeconds = state.durationSeconds;
      final session = FocusSessionModel(
        id: _uuid.v4(),
        startTime: DateTime.now().subtract(Duration(seconds: completedSeconds)),
        durationSeconds: completedSeconds,
        taskId: state.activeTaskId,
        goalId: state.activeGoalId,
        qualityScore: 4, // Default quality rating, can be modified post-session
      );

      // Save to DB
      await _db.saveFocusSession(session.id, session.toMap());

      // If linked to a task, update task's focus time
      if (state.activeTaskId != null) {
        await _ref.read(taskListProvider.notifier).addFocusTime(state.activeTaskId!, completedSeconds);
      }

      final updatedHistory = [session, ...state.history];
      final streak = _calculateFocusStreak(updatedHistory);

      state = state.copyWith(
        history: updatedHistory,
        focusStreak: streak,
        isBreak: true, // Go to break mode
        isRunning: false,
        durationSeconds: 300, // 5 min break
        remainingSeconds: 300,
      );
    } else {
      // Completed Break!
      state = state.copyWith(
        isBreak: false,
        isRunning: false,
        durationSeconds: 1500, // back to 25 mins
        remainingSeconds: 1500,
      );
    }
  }

  Future<void> logManualSession({
    required int durationMinutes,
    String? taskId,
    String? goalId,
    int qualityScore = 3,
    String notes = "",
  }) async {
    final session = FocusSessionModel(
      id: _uuid.v4(),
      startTime: DateTime.now().subtract(Duration(minutes: durationMinutes)),
      durationSeconds: durationMinutes * 60,
      taskId: taskId,
      goalId: goalId,
      qualityScore: qualityScore,
      notes: notes,
    );

    await _db.saveFocusSession(session.id, session.toMap());

    if (taskId != null) {
      await _ref.read(taskListProvider.notifier).addFocusTime(taskId, durationMinutes * 60);
    }

    _loadHistory();
  }

  Future<void> deleteSession(String id) async {
    await _db.deleteFocusSession(id);
    _loadHistory();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
