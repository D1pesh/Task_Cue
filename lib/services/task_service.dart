import '../models/task.dart';

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
    
    return _tasks.where((task) {
      if (task.dueDate == null) return false;
      final dueDate = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
      );
      return dueDate == today;
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
    DateTime? dueDate,
    int? estimatedMinutes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate API delay
    
    final task = Task(
      id: _nextId.toString(),
      title: title,
      description: description,
      category: category,
      priority: priority,
      dueDate: dueDate,
      estimatedMinutes: estimatedMinutes,
      status: 'pending',
      createdAt: DateTime.now(),
    );
    
    _tasks.add(task);
    _nextId++;
    
    return task;
  }

  /// Update existing task
  Future<Task> updateTask(
    String id, {
    String? title,
    String? description,
    String? category,
    int? priority,
    DateTime? dueDate,
    int? estimatedMinutes,
    String? status,
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
      dueDate: dueDate,
      estimatedMinutes: estimatedMinutes,
      status: status,
    );
    
    _tasks[index] = updatedTask;
    return updatedTask;
  }

  /// Delete task
  Future<void> deleteTask(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
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
