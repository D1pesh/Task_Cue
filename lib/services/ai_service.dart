import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/task.dart';

class AIService {
  // Use 10.0.2.2 for Android emulator, localhost for others
  static const String _baseUrl = kIsWeb ? 'http://localhost:8000/api/tasks' : 'http://10.0.2.2:8000/api/tasks';
  
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Call the backend AI endpoint to get a rescheduled list of task IDs
  Future<List<String>> getAIRecommendedOrder(List<Task> tasks) async {
    try {
      final user = _auth.currentUser;
      final token = await user?.getIdToken() ?? '';
      
      // Map tasks to features expected by the AI model
      final taskData = tasks.map((task) => {
        'id': task.id,
        'title': task.title,
        'description': task.description,
        'deadline_time': task.deadline?.toIso8601String(),
        'estimated_duration': task.estimatedMinutes,
        'priority': task.priority,
        'category': _mapCategoryToNumeric(task.category),
      }).toList();

      final response = await http.post(
        Uri.parse('$_baseUrl/reschedule-ai/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'tasks': taskData}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['rescheduled_ids']);
      } else {
        debugPrint('AI Response error: ${response.body}. Falling back to local heuristic.');
        return _provideLocalHeuristicSort(tasks);
      }
    } catch (e) {
      // Backend is unreachable or offline, falling back directly without terminal spam
      return _provideLocalHeuristicSort(tasks);
    }
  }

  /// Fallback sorting algorithm that runs locally
  List<String> _provideLocalHeuristicSort(List<Task> tasks) {
    // Logic: Sort by Priority (Low number = High priority), then Deadline, then Duration
    final sortedTasks = List<Task>.from(tasks);
    
    sortedTasks.sort((a, b) {
      // 1. Priority (1 = High, 3 = Low)
      if (a.priority != b.priority) {
        return a.priority.compareTo(b.priority);
      }
      
      // 2. Deadline (Closer deadline first)
      if (a.deadline != null && b.deadline != null) {
        return a.deadline!.compareTo(b.deadline!);
      } else if (a.deadline != null) {
        return -1;
      } else if (b.deadline != null) {
        return 1;
      }
      
      // 3. Duration (Longer tasks first or vice versa? Let's say shorter first for quick wins)
      return (a.estimatedMinutes ?? 30).compareTo(b.estimatedMinutes ?? 30);
    });
    
    return sortedTasks.map((t) => t.id).toList();
  }

  /// Maps category string names to the numeric IDs expected by the AI Model
  int _mapCategoryToNumeric(String categoryName) {
    // Mapping matches backend/categories/models.py
    switch (categoryName.toLowerCase()) {
      case 'work': return 1;
      case 'personal': return 2;
      case 'health': return 3;
      case 'learning': return 4;
      case 'finance': return 5;
      case 'social': return 6;
      case 'home': return 7;
      default: return 1; // Default to Work if unknown
    }
  }
}
