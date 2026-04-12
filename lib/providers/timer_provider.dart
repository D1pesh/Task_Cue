// import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/notification_service.dart';

class TimerProvider extends ChangeNotifier {
  Task? _activeTask;
  bool _isRunning = false;
  bool _isPaused = false;
  int _elapsedSeconds = 0;
  DateTime? _startTime;
  DateTime? _pauseTime;
  Function(String)? _onTaskComplete;

  int _currentXP = 0;
  int _pauseCount = 0;
  int _snoozeCount = 0;

  /// Getters
  Task? get activeTask => _activeTask;
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  int get elapsedSeconds => _elapsedSeconds;
  bool get hasActiveTimer => _activeTask != null;
  int get currentTaskXP => _currentXP;
  int get pauseCount => _pauseCount;
  int get snoozeCount => _snoozeCount;

  // Set callback for task completion
  void setTaskCompleteCallback(Function(String) callback) {
    _onTaskComplete = callback;
  }

  /// Start timer for a task
  void startTimer(Task task) {
    if (_activeTask?.id == task.id && _isPaused) {
      resumeTimer();
      return;
    }

    _activeTask = task;
    _isRunning = true;
    _isPaused = false;
    _elapsedSeconds = 0;
    _startTime = DateTime.now();
    _pauseTime = null;
    _pauseCount = 0;
    _snoozeCount = 0;

    notifyListeners();
  }

  /// Pause the timer
  void pauseTimer() {
    if (_isRunning && !_isPaused) {
      _isPaused = true;
      _isRunning = false;
      _pauseTime = DateTime.now();
      _pauseCount++;
      notifyListeners();
    }
  }

  /// Resume the timer
  void resumeTimer() {
    if (_isPaused && _activeTask != null && _startTime != null) {
      final pauseDuration = DateTime.now().difference(_pauseTime!);
      _startTime = _startTime!.add(pauseDuration);

      _isPaused = false;
      _isRunning = true;
      _pauseTime = null;
      notifyListeners();
    }
  }

  /// Stop the timer and optionally mark the task as completed
  void stopTimer({bool markComplete = true}) {
    if (_activeTask == null) return;

    updateElapsedTime();
    _awardRemainingTimePoints();

    if (markComplete && _onTaskComplete != null) {
      _onTaskComplete!(_activeTask!.id);
      debugPrint(
        'Task "${_activeTask!.title}" completed after ${getFormattedTime()}',
      );
    }

    resetTimerState();
    notifyListeners();
  }

  /// Update elapsed time (called by ticker)
  void updateElapsedTime() {
    if (_isRunning && _startTime != null) {
      _elapsedSeconds = DateTime.now().difference(_startTime!).inSeconds;
      calculateCurrentXP();
      notifyListeners();
    }
  }

  /// Calculate XP based on elapsed time and task attributes
  void calculateCurrentXP() {
    if (_activeTask == null) return;

    final durationMinutes = _elapsedSeconds ~/ 60;
    if (durationMinutes == 0) {
      _currentXP = 0;
      return;
    }

    // Map task priority to difficulty and priority strings
    String difficulty = 'medium';
    String priority = 'medium';

    if (_activeTask!.priority == 1) {
      difficulty = 'easy';
    } else if (_activeTask!.priority == 2) {
      difficulty = 'medium';
    } else if (_activeTask!.priority == 3) {
      difficulty = 'hard';
      priority = 'high';
    }

    // Base XP calculation (simplified, without streak/balance/focus bonuses during timer)
    int baseXP = difficulty == 'easy' ? 10 : (difficulty == 'hard' ? 35 : 20);
    double priorityMultiplier = priority == 'low' ? 1.0 : (priority == 'high' ? 1.5 : 1.2);

    // Duration bonus (capped at +15)
    int durationBonus = 0;
    if (durationMinutes >= 120) {
      durationBonus = 15;
    } else if (durationMinutes >= 60) {
      durationBonus = 10;
    } else if (durationMinutes >= 30) {
      durationBonus = 5;
    }

    // Calculate base XP (actual bonuses applied on completion)
    double rawXP = (baseXP * priorityMultiplier + durationBonus);
    
    // Now update the total XP
    _currentXP = rawXP.round();
  }

  /// Snooze the task for a specified number of minutes
  void snoozeTask(int minutes) {
    if (_activeTask == null) return;

    if (!_isPaused) {
      _isPaused = true;
      _isRunning = false;
      _pauseTime = DateTime.now();
    }

    _snoozeCount++;

    final snoozeTime = DateTime.now().add(Duration(minutes: minutes));
    final snoozedTask = _activeTask!.copyWith(scheduledDateTime: snoozeTime);
    NotificationService.scheduleTaskReminder(snoozedTask);

    debugPrint(
      'Task "${_activeTask!.title}" snoozed for $minutes minutes until ${snoozeTime.toString().substring(11, 16)}',
    );
    notifyListeners();
  }

  /// Toggle between pause and resume
  void toggleTimer() {
    if (_isPaused) {
      resumeTimer();
    } else if (_isRunning) {
      pauseTimer();
    }
  }

  /// Get formatted time string
  String getFormattedTime() {
    final hours = _elapsedSeconds ~/ 3600;
    final minutes = (_elapsedSeconds % 3600) ~/ 60;
    final seconds = _elapsedSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Reset the timer state
  void resetTimerState() {
    _activeTask = null;
    _isRunning = false;
    _isPaused = false;
    _elapsedSeconds = 0;
    _startTime = null;
    _pauseTime = null;
    _currentXP = 0;
    _pauseCount = 0;
    _snoozeCount = 0;
  }

  /// Award remaining time points (placeholder for actual implementation)
  void _awardRemainingTimePoints() {
    // Implement logic to award points for remaining time
  }
}