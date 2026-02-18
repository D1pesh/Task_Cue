import '../models/task.dart';
import 'notification_service.dart';

/// Simple in-memory Task Service with CRUD operations
class TaskService {
  // In-memory storage (replace with API/database later)
  final List<Task> _tasks = [];
  int _nextId = 1;

  /// Get all tasks
  Future<List<Task>> getTasks() async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate API delay
    return List.from(_tasks);
  }

  /// Get today's tasks
  Future<List<Task>> getTodayTasks() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentWeekday = now.weekday; // 1=Mon, 2=Tue, ..., 7=Sun
    
    return _tasks.where((task) {
      // For recurring tasks
      if (task.scheduleType == 'daily') {
        return true; // Daily tasks show every day
      }
      
      if (task.scheduleType == 'weekend') {
        if (task.scheduledDays != null && task.scheduledDays!.isNotEmpty) {
          return task.scheduledDays!.contains(currentWeekday);
        }
        return currentWeekday == DateTime.saturday || currentWeekday == DateTime.sunday;
      }

      if ((task.scheduleType == 'weekly' || task.scheduleType == 'custom') && task.scheduledDays != null) {
        return task.scheduledDays!.contains(currentWeekday);
      }
      
      // For one-time tasks
      if (task.scheduleType == 'one-time' || task.scheduleType == null) {
        // Prioritize scheduledDateTime if available
        if (task.scheduledDateTime != null) {
          final scheduledDate = DateTime(
            task.scheduledDateTime!.year,
            task.scheduledDateTime!.month,
            task.scheduledDateTime!.day,
          );
          return scheduledDate == today;
        }
        
        // Fall back to deadline if no scheduled date
        if (task.deadline != null) {
          final deadlineDate = DateTime(
            task.deadline!.year,
            task.deadline!.month,
            task.deadline!.day,
          );
          return deadlineDate == today;
        }
        
        // Show tasks with no dates (default to today)
        return task.deadline == null && task.scheduledDateTime == null;
      }
      
      return false;
    }).toList();
  }

  /// Get single task by ID
  Future<Task?> getTask(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _tasks.firstWhere((task) => task.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Create new task
  Future<Task> createTask({
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
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate API delay
    
    final task = Task(
      id: _nextId.toString(),
      title: title,
      description: description,
      category: category,
      priority: priority,
      deadline: deadline,
      scheduledDateTime: scheduledDateTime,
      estimatedMinutes: estimatedMinutes,
      status: 'pending',
      createdAt: DateTime.now(),
      scheduleType: scheduleType,
      scheduledTime: scheduledTime,
      scheduledDays: scheduledDays,
    );
    
    _tasks.add(task);
    _nextId++;
    
    // Schedule notification if task has scheduled time
    if (task.scheduledDateTime != null) {
      NotificationService.scheduleTaskReminder(task);
    }
    
    return task;
  }

  /// Update existing task
  Future<Task> updateTask(
    String id, {
    String? title,
    String? description,
    String? category,
    int? priority,
    DateTime? deadline,
    DateTime? scheduledDateTime,
    int? estimatedMinutes,
    String? status,
    String? scheduleType,
    String? scheduledTime,
    List<int>? scheduledDays,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index == -1) {
      throw Exception('Task not found');
    }
    
    final oldTask = _tasks[index];
    final updatedTask = oldTask.copyWith(
      title: title,
      description: description,
      category: category,
      priority: priority,
      deadline: deadline,
      scheduledDateTime: scheduledDateTime,
      estimatedMinutes: estimatedMinutes,
      status: status,
      scheduleType: scheduleType,
      scheduledTime: scheduledTime,
      scheduledDays: scheduledDays,
    );
    
    _tasks[index] = updatedTask;
    
    // Handle notification scheduling for updated task
    if (updatedTask.scheduledDateTime != oldTask.scheduledDateTime) {
      // Cancel old notification
      await NotificationService.cancelTaskNotification(oldTask);
      
      // Schedule new notification if task has scheduled time
      if (updatedTask.scheduledDateTime != null) {
        NotificationService.scheduleTaskReminder(updatedTask);
      }
    }
    
    return updatedTask;
  }

  /// Delete task
  Future<void> deleteTask(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Find task before deleting to cancel notification
    final task = _tasks.where((t) => t.id == id).firstOrNull;
    if (task != null) {
      await NotificationService.cancelTaskNotification(task);
    }
    
    _tasks.removeWhere((task) => task.id == id);
  }

  /// Mark task as completed
  Future<Task> completeTask(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index == -1) {
      throw Exception('Task not found');
    }
    
    final updatedTask = _tasks[index].copyWith(
      status: 'completed',
      completedAt: DateTime.now(),
    );
    
    _tasks[index] = updatedTask;
    return updatedTask;
  }

  /// Get task statistics
  Future<Map<String, int>> getStats() async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final completed = _tasks.where((t) => t.status == 'completed').length;
    final pending = _tasks.where((t) => t.status == 'pending' && !t.isOverdue).length;
    final overdue = _tasks.where((t) => t.isOverdue).length;
    
    return {
      'completed': completed,
      'pending': pending,
      'overdue': overdue,
    };
  }
}
