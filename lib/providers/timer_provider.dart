import 'package:flutter/foundation.dart';
import '../models/task.dart';

class TimerProvider extends ChangeNotifier {
  Task? _activeTask;
  bool _isRunning = false;
  bool _isPaused = false;
  int _elapsedSeconds = 0;
  DateTime? _startTime;
  DateTime? _pauseTime;

  // Getters
  Task? get activeTask => _activeTask;
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  int get elapsedSeconds => _elapsedSeconds;
  bool get hasActiveTimer => _activeTask != null;

  /// Start timer for a task
  void startTimer(Task task) {
    if (_activeTask?.id == task.id && _isPaused) {
      // Resume existing timer
      resumeTimer();
      return;
    }
    
    // Start new timer
    _activeTask = task;
    _isRunning = true;
    _isPaused = false;
    _elapsedSeconds = 0;
    _startTime = DateTime.now();
    _pauseTime = null;
    
    notifyListeners();
  }

  /// Pause the timer
  void pauseTimer() {
    if (_isRunning && !_isPaused) {
      _isPaused = true;
      _isRunning = false;
      _pauseTime = DateTime.now();
      notifyListeners();
    }
  }

  /// Resume the timer
  void resumeTimer() {
    if (_isPaused && _activeTask != null) {
      _isPaused = false;
      _isRunning = true;
      
      // Adjust start time to account for pause duration
      if (_pauseTime != null && _startTime != null) {
        final pauseDuration = DateTime.now().difference(_pauseTime!);
        _startTime = _startTime!.add(pauseDuration);
      }
      
      _pauseTime = null;
      notifyListeners();
    }
  }

  /// Stop the timer and mark task as completed
  void stopTimer({bool markComplete = true}) {
    if (_activeTask != null) {
      final task = _activeTask!;
      
      // Calculate total time worked
      final totalTime = _elapsedSeconds;
      
      if (markComplete) {
        // TODO: Mark task as completed and save work time
        // This could integrate with TaskProvider to update the task
      }
      
      // Reset timer state
      _activeTask = null;
      _isRunning = false;
      _isPaused = false;
      _elapsedSeconds = 0;
      _startTime = null;
      _pauseTime = null;
      
      notifyListeners();
    }
  }

  /// Update elapsed time (called by timer)
  void updateElapsedTime() {
    if (_isRunning && _startTime != null) {
      _elapsedSeconds = DateTime.now().difference(_startTime!).inSeconds;
      notifyListeners();
    }
  }

  /// Snooze the current task
  void snoozeTask(int minutes) {
    if (_activeTask != null) {
      // Pause current timer
      pauseTimer();
      
      // TODO: Schedule notification to remind in X minutes
      // This could integrate with NotificationService
      
      debugPrint('Task snoozed for $minutes minutes');
    }
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
}