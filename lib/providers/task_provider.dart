import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/task_service.dart';

/// Task Provider for state management
class TaskProvider extends ChangeNotifier {
  final TaskService _taskService = TaskService();
  
  List<Task> _tasks = [];
  List<Task> _todayTasks = [];
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<Task> get tasks => _tasks;
  List<Task> get todayTasks => _todayTasks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Stats
  int get completedCount => _tasks.where((t) => t.isCompleted).length;
  int get pendingCount => _tasks.where((t) => t.status == 'pending' && !t.isOverdue).length;
  int get overdueCount => _tasks.where((t) => t.isOverdue).length;
  
  /// Load all tasks
  Future<void> loadTasks() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      _tasks = await _taskService.getTasks();
      _todayTasks = await _taskService.getTodayTasks();
      
      _isLoading = false;
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
    DateTime? dueDate,
    int? estimatedMinutes,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      await _taskService.createTask(
        title: title,
        description: description,
        category: category,
        priority: priority,
        dueDate: dueDate,
        estimatedMinutes: estimatedMinutes,
      );
      
      await loadTasks();
      return true;
    } catch (e) {
      _error = 'Failed to create task: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Update task
  Future<bool> updateTask(
    String id, {
    String? title,
    String? description,
    String? category,
    int? priority,
    DateTime? dueDate,
    int? estimatedMinutes,
    String? status,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      await _taskService.updateTask(
        id,
        title: title,
        description: description,
        category: category,
        priority: priority,
        dueDate: dueDate,
        estimatedMinutes: estimatedMinutes,
        status: status,
      );
      
      await loadTasks();
      return true;
    } catch (e) {
      _error = 'Failed to update task: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Delete task
  Future<bool> deleteTask(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      await _taskService.deleteTask(id);
      await loadTasks();
      return true;
    } catch (e) {
      _error = 'Failed to delete task: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Complete task
  Future<bool> completeTask(String id) async {
    try {
      await _taskService.completeTask(id);
      await loadTasks();
      return true;
    } catch (e) {
      _error = 'Failed to complete task: $e';
      notifyListeners();
      return false;
    }
  }
  
  /// Refresh tasks
  Future<void> refresh() async {
    await loadTasks();
  }
}
