import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import 'notification_service.dart';

/// Task Service heavily optimized for Firestore (with its built-in offline persistence)
class TaskService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  bool get _isFirebaseReady {
    try {
      FirebaseFirestore.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference? get _taskCollection {
    if (_userId == null || !_isFirebaseReady) return null;
    return _firestore.collection('users').doc(_userId).collection('tasks');
  }

  /// Get tasks from Firestore (automatically serves from the local cache if offline)
  Future<List<Task>> getTasks({bool includeCompleted = true}) async {
    if (_taskCollection == null) return [];

    try {
      Query query = _taskCollection!;
      if (!includeCompleted) {
        query = query.where('status', isNotEqualTo: 'completed');
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = data['id'] ?? doc.id; 
        return Task.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('Error getting tasks from Firestore: $e');
      return [];
    }
  }

  /// Get today's tasks - Optimized to only fetch non-completed tasks
  Future<List<Task>> getTodayTasks() async {
    // Only fetch non-completed tasks for the daily view (HUGE performance boost)
    final tasks = await getTasks(includeCompleted: false);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentWeekday = now.weekday;
    
    return tasks.where((task) {
      if (task.scheduleType == 'daily') return true;
      
      if (task.scheduleType == 'weekend') {
        if (task.scheduledDays != null && task.scheduledDays!.isNotEmpty) {
          return task.scheduledDays!.contains(currentWeekday);
        }
        return currentWeekday == DateTime.saturday || currentWeekday == DateTime.sunday;
      }

      if ((task.scheduleType == 'weekly' || task.scheduleType == 'custom') && task.scheduledDays != null) {
        return task.scheduledDays!.contains(currentWeekday);
      }
      
      if (task.scheduleType == 'one-time' || task.scheduleType == null) {
        if (task.scheduledDateTime != null) {
          final scheduledDate = DateTime(
            task.scheduledDateTime!.year,
            task.scheduledDateTime!.month,
            task.scheduledDateTime!.day,
          );
          return scheduledDate == today;
        }
        
        if (task.deadline != null) {
          final deadlineDate = DateTime(
            task.deadline!.year,
            task.deadline!.month,
            task.deadline!.day,
          );
          return deadlineDate == today;
        }
        
        return task.deadline == null && task.scheduledDateTime == null;
      }
      
      return false;
    }).toList();
  }

  /// Get single task by ID
  Future<Task?> getTask(String id) async {
    if (_taskCollection == null) return null;
    try {
      final doc = await _taskCollection!.doc(id).get();
      if (!doc.exists) return null;
      
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return Task.fromJson(data);
    } catch (e) {
      debugPrint('Error getting single task from Firestore: $e');
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
    final docRef = _taskCollection?.doc();
    final id = docRef?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

    final task = Task(
      id: id,
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
    
    // Save to Firestore optimistically (NOT awaited, handles offline persistence gracefully)
    if (_userId != null) {
      _taskCollection?.doc(task.id).set(task.toJson()).catchError((e) {
        debugPrint('Firestore createTask error: $e');
      });
    }
    
    if (task.scheduledDateTime != null) {
      NotificationService.scheduleTaskReminder(task);
    }
    
    return task;
  }

  /// Update existing task
  Future<Task> updateTask({
    required String taskId,
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
    final oldTask = await getTask(taskId);
    if (oldTask == null) throw Exception('Task not found');
    
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
    
    if (_userId != null) {
      _taskCollection?.doc(taskId).update(updatedTask.toJson()).catchError((e) {
        debugPrint('Firestore updateTask error: $e');
      });
    }
    
    if (updatedTask.scheduledDateTime != oldTask.scheduledDateTime) {
      await NotificationService.cancelTaskNotification(oldTask);
      if (updatedTask.scheduledDateTime != null) {
        NotificationService.scheduleTaskReminder(updatedTask);
      }
    }
    
    return updatedTask;
  }

  /// Delete task
  Future<void> deleteTask(String id) async {
    final task = await getTask(id);
    if (task != null) {
      await NotificationService.cancelTaskNotification(task);
    }
    
    if (_userId != null) {
      _taskCollection?.doc(id).delete().catchError((e) {
        debugPrint('Firestore deleteTask error: $e');
      });
    }
  }

  /// Mark task as completed
  Future<Task> completeTask(String id) async {
    final task = await getTask(id);
    if (task == null) throw Exception('Task not found');
    
    final updatedTask = task.copyWith(
      status: 'completed',
      completedAt: DateTime.now(),
    );
    
    if (_userId != null) {
      _taskCollection?.doc(id).update(updatedTask.toJson()).catchError((e) {
        debugPrint('Firestore completeTask error: $e');
      });
    }
    
    return updatedTask;
  }

  /// Get task statistics
  Future<Map<String, int>> getStats() async {
    final tasks = await getTasks();
    
    final completed = tasks.where((t) => t.status == 'completed').length;
    final pending = tasks.where((t) => t.status == 'pending' && !t.isOverdue).length;
    final overdue = tasks.where((t) => t.isOverdue).length;
    
    return {
      'completed': completed,
      'pending': pending,
      'overdue': overdue,
    };
  }
}