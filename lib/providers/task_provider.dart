import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/ai_service.dart';
import '../services/gamification_service.dart';

/// Task Provider for state management
class TaskProvider extends ChangeNotifier {
  final TaskService _taskService = TaskService();
  final AIService _aiService = AIService();

  List<Task> _tasks = [];
  List<Task> _todayTasks = [];
  bool _isLoading = false;
  bool _showAISorted = false;
  String? _error;

  // Analytics cache
  Map<String, int> _completedByCategoryCache = {};
  Map<DateTime, double> _dailyPointsCache = {};
  int _completedCountCache = 0;

  // Getters
  List<Task> get tasks => _tasks;
  List<Task> get todayTasks => _todayTasks;
  bool get showAISorted => _showAISorted;

  int get completedCount => _completedCountCache;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Optimized Analytics Data
  Map<String, int> get completedByCategory => _completedByCategoryCache;
  Map<DateTime, double> get dailyPoints => _dailyPointsCache;

  void _updateAnalyticsCache() {
    // 1. Update completed count
    _completedCountCache = _tasks.where((task) => task.isCompleted).length;

    // 2. Update category distribution
    final Map<String, int> distribution = {};
    for (final task in _tasks) {
      if (task.isCompleted) {
        distribution[task.category] = (distribution[task.category] ?? 0) + 1;
      }
    }
    _completedByCategoryCache = distribution;

    // 3. Update daily achievement points
    final Map<DateTime, double> points = {};
    for (final task in _tasks) {
      if (task.isCompleted && task.completedAt != null) {
        final date = DateTime(
          task.completedAt!.year,
          task.completedAt!.month,
          task.completedAt!.day,
        );
        int baseXP = 15;
        if ((task.estimatedMinutes ?? 0) >= 60) {
          baseXP = 25;
        } else if ((task.estimatedMinutes ?? 0) <= 20) {
          baseXP = 10;
        }

        double multiplier = 1.0;
        if (task.priority == 1) {
          multiplier = 1.5;
        } else if (task.priority == 3) {
          multiplier = 0.8;
        }

        int taskXP = (baseXP * multiplier).round();
        points[date] = (points[date] ?? 0) + taskXP.toDouble();
      }
    }
    _dailyPointsCache = points;
  }

  /// Load all tasks
  Future<void> loadTasks() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Start both fetches but prioritize today's tasks for the home screen
      final todayTasksFuture = _taskService.getTodayTasks();
      final allTasksFuture = _taskService.getTasks();

      // Home Screen optimization: Show today's tasks as soon as they are ready
      _todayTasks = await todayTasksFuture;
      _isLoading = false;
      notifyListeners();

      // Continue loading all tasks and analytics in the background
      _tasks = await allTasksFuture;
      _updateAnalyticsCache();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load tasks: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create new task
  Future<bool> createTask({
    required String title,
    String? description,
    required String category,
    required int priority,
    DateTime? deadline,
    DateTime? scheduledDateTime,
    int? estimatedMinutes,
    String? scheduleType,
    String? scheduledTime,
    List<int>? scheduledDays,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final newTask = await _taskService.createTask(
        title: title,
        description: description,
        category: category,
        priority: priority,
        deadline: deadline,
        scheduledDateTime: scheduledDateTime,
        estimatedMinutes: estimatedMinutes,
        scheduleType: scheduleType,
        scheduledTime: scheduledTime,
        scheduledDays: scheduledDays,
      );

      // Instantly insert into local state without fetching from network
      _tasks.add(newTask);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      bool isToday = false;

      if (newTask.scheduledDateTime != null) {
        final sDate = DateTime(
          newTask.scheduledDateTime!.year,
          newTask.scheduledDateTime!.month,
          newTask.scheduledDateTime!.day,
        );
        if (sDate == today) isToday = true;
      } else if (newTask.deadline != null) {
        final dDate = DateTime(
          newTask.deadline!.year,
          newTask.deadline!.month,
          newTask.deadline!.day,
        );
        if (dDate == today) isToday = true;
      } else if (newTask.deadline == null &&
          newTask.scheduledDateTime == null) {
        isToday = true;
      }

      if (isToday) {
        _todayTasks.add(newTask);
      }

      _isLoading = false;
      _updateAnalyticsCache();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to create task: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update existing task
  Future<bool> updateTask({
    required String taskId,
    required String title,
    String? description,
    required String category,
    required int priority,
    DateTime? deadline,
    DateTime? scheduledDateTime,
    int? estimatedMinutes,
    String? scheduleType,
    String? scheduledTime,
    List<int>? scheduledDays,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final updatedTask = await _taskService.updateTask(
        taskId: taskId,
        title: title,
        description: description,
        category: category,
        priority: priority,
        deadline: deadline,
        scheduledDateTime: scheduledDateTime,
        estimatedMinutes: estimatedMinutes,
        scheduleType: scheduleType,
        scheduledTime: scheduledTime,
        scheduledDays: scheduledDays,
      );

      // Update locally
      final idx = _tasks.indexWhere((t) => t.id == taskId);
      if (idx != -1) {
        _tasks[idx] = updatedTask;
      }

      final idxToday = _todayTasks.indexWhere((t) => t.id == taskId);
      if (idxToday != -1) {
        _todayTasks[idxToday] = updatedTask;
      }

      _isLoading = false;
      _updateAnalyticsCache();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> refresh() async {
    await loadTasks();
  }

  Future<Map<String, dynamic>?> completeTask(String taskId) async {
    try {
      final index = _tasks.indexWhere((task) => task.id == taskId);
      if (index < 0) return null;

      final task = _tasks[index];
      if (task.isCompleted) return null;

      // OPTIMISTIC UPDATE: Mark as completed locally first
      final optimisticTask = task.copyWith(
        status: 'completed',
        completedAt: DateTime.now(),
      );
      _tasks[index] = optimisticTask;
      _todayTasks = _todayTasks
          .map<Task>((t) => t.id == taskId ? optimisticTask : t)
          .toList();
      _updateAnalyticsCache();
      notifyListeners();

      // 1. Mark as completed in backend
      final updatedTask = await _taskService.completeTask(taskId);

      // 2. Award XP through GamificationService
      final gamificationService = GamificationService();

      // Map priority (1-3) to string (High, Medium, Low)
      String priorityStr = 'Medium';
      if (task.priority == 1) {
        priorityStr = 'High';
      } else if (task.priority == 3) {
        priorityStr = 'Low';
      }

      String difficulty = 'Medium';
      if ((task.estimatedMinutes ?? 0) >= 60) {
        difficulty = 'High';
      } else if ((task.estimatedMinutes ?? 0) <= 20) {
        difficulty = 'Low';
      }

      final result = await gamificationService.awardTaskCompletion(
        difficulty: difficulty,
        priority: priorityStr,
        durationMinutes: task.estimatedMinutes ?? 30,
        category: task.category,
      );

      // 3. Final sync (in case backend returned slightly different data)
      _tasks[index] = updatedTask;
      _todayTasks = _todayTasks
          .map((t) => t.id == taskId ? updatedTask : t)
          .toList();
      _updateAnalyticsCache();
      notifyListeners();

      return result;
    } catch (e) {
      debugPrint('Error completing task: $e');
      _error = 'Failed to complete task: $e';
      notifyListeners();
      return null;
    }
  }

  Future<void> deleteTask(String taskId) async {
    await _taskService.deleteTask(taskId);
    _tasks.removeWhere((task) => task.id == taskId);
    _todayTasks.removeWhere((task) => task.id == taskId);
    notifyListeners();
  }

  /// Toggle between AI sorted view and default view
  void toggleAISorting(bool value) {
    _showAISorted = value;
    if (!value) {
      // Re-load to get default order
      loadTasks();
    } else {
      rescheduleWithAI();
    }
  }

  /// Use AI model to reschedule (sort) today's tasks
  Future<void> rescheduleWithAI() async {
    if (_todayTasks.isEmpty) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final rescheduledIds = await _aiService.getAIRecommendedOrder(
        _todayTasks,
      );

      // Sort _todayTasks based on the IDs returned by AI
      final sortedTasks = <Task>[];
      for (var id in rescheduledIds) {
        try {
          final task = _todayTasks.firstWhere((t) => t.id == id);
          sortedTasks.add(task);
        } catch (_) {
          // Task might have been deleted or filtered out
        }
      }

      // Add any filtered tasks that were missing from AI response (safety)
      final missingTasks = _todayTasks
          .where((t) => !rescheduledIds.contains(t.id))
          .toList();
      sortedTasks.addAll(missingTasks);

      _todayTasks = sortedTasks;
      _showAISorted = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('AI Reschedule failed: $e');
      _error = 'AI Reschedule failed. Make sure server is running.';
      _isLoading = false;
      _showAISorted = false;
      notifyListeners();
    }
  }
}
