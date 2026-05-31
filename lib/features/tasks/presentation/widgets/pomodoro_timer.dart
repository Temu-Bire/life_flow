import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/design_system.dart';
import '../../domain/models/task_model.dart';
import '../viewmodels/task_viewmodel.dart';

class PomodoroTimerWidget extends ConsumerStatefulWidget {
  final TaskModel? associatedTask;
  final VoidCallback? onTimerFinished;

  const PomodoroTimerWidget({
    super.key,
    this.associatedTask,
    this.onTimerFinished,
  });

  @override
  ConsumerState<PomodoroTimerWidget> createState() => _PomodoroTimerWidgetState();
}

class _PomodoroTimerWidgetState extends ConsumerState<PomodoroTimerWidget> {
  static const int _workDuration = 25 * 60; // 25 minutes
  static const int _breakDuration = 5 * 60; // 5 minutes

  Timer? _timer;
  int _secondsRemaining = _workDuration;
  bool _isActive = false;
  bool _isWorkSession = true;
  double _progressValue = 1.0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isActive) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    setState(() {
      _isActive = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
          final total = _isWorkSession ? _workDuration : _breakDuration;
          _progressValue = _secondsRemaining / total;
        });

        // Add progress to task if work session is active
        if (_isWorkSession && widget.associatedTask != null && _secondsRemaining % 60 == 0) {
          ref.read(taskListProvider.notifier).addFocusTime(widget.associatedTask!.id, 60);
        }
      } else {
        _timerFinished();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isActive = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isActive = false;
      _secondsRemaining = _isWorkSession ? _workDuration : _breakDuration;
      _progressValue = 1.0;
    });
  }

  void _timerFinished() {
    _timer?.cancel();
    // Vibrate/Sound triggers should go here
    if (widget.onTimerFinished != null) {
      widget.onTimerFinished!();
    }

    setState(() {
      _isActive = false;
      _isWorkSession = !_isWorkSession;
      _secondsRemaining = _isWorkSession ? _workDuration : _breakDuration;
      _progressValue = 1.0;
    });

    // Alert feedback dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          _isWorkSession ? "Break is Over!" : "Session Completed!",
          style: AppTextStyles.titleMedium,
        ),
        content: Text(
          _isWorkSession
              ? "Time to focus and crush another task."
              : "Fantastic work! Take 5 minutes to relax.",
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Awesome", style: TextStyle(color: AppColors.primaryLight)),
          ),
        ],
      ),
    );
  }

  String _formatTime() {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _isWorkSession ? AppColors.primaryLight : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppDecorations.glassDecoration(borderRadius: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isWorkSession ? "Deep Focus Blocks" : "Rest Period",
                    style: AppTextStyles.titleMedium.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.associatedTask != null
                        ? "Task: ${widget.associatedTask!.title}"
                        : "No Task Linked",
                    style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              Chip(
                backgroundColor: activeColor.withOpacity(0.12),
                side: BorderSide(color: activeColor.withOpacity(0.3)),
                label: Text(
                  _isWorkSession ? "Focus Session" : "Short Break",
                  style: TextStyle(color: activeColor, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),
          // Ring Clock Gauge Layout
          Stack(
            alignment: Alignment.center,
            children: [
              // Glowing Outer shadow circles
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withOpacity(0.06),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ),
              // Gauge Progress Track
              SizedBox(
                width: 170,
                height: 170,
                child: CircularProgressIndicator(
                  value: _progressValue,
                  strokeWidth: 8,
                  backgroundColor: Colors.white10,
                  color: activeColor,
                ),
              ),
              // Inside Digital counter
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(),
                    style: AppTextStyles.titleLarge.copyWith(fontSize: 42, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isActive ? "ACTIVE" : "PAUSED",
                    style: AppTextStyles.caption.copyWith(
                      color: _isActive ? activeColor : AppColors.textMuted,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 36),
          // Timer controls buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Reset Button
              IconButton.filledTonal(
                onPressed: _resetTimer,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.04),
                  padding: const EdgeInsets.all(12),
                ),
                icon: const Icon(Icons.replay, color: Colors.white),
              ),
              const SizedBox(width: 24),
              // Play/Pause Floating Action Button
              GestureDetector(
                onTap: _toggleTimer,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [activeColor, activeColor.withAlpha(200)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isActive ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Skip Break or Complete early
              IconButton.filledTonal(
                onPressed: _timerFinished,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.04),
                  padding: const EdgeInsets.all(12),
                ),
                icon: const Icon(Icons.skip_next, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
