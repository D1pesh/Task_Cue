class Task {
  final String id;
  final String title;
  final String? description;
  final String category;
  final int priority;
  final DateTime? dueDate;
  final int? estimatedMinutes;
  final String status; // 'pending', 'completed', 'overdue'
  final DateTime createdAt;
  final DateTime? completedAt;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.priority,
    this.dueDate,
    this.estimatedMinutes,
    this.status = 'pending',
    required this.createdAt,
    this.completedAt,
  });

  // Check if task is overdue
  bool get isOverdue {
    if (dueDate == null || status == 'completed') return false;
    return DateTime.now().isAfter(dueDate!);
  }

  // Check if task is completed
  bool get isCompleted => status == 'completed';

  // Copy with method for updates
  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    int? priority,
    DateTime? dueDate,
    int? estimatedMinutes,
    String? status,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'dueDate': dueDate?.toIso8601String(),
      'estimatedMinutes': estimatedMinutes,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  // Create from JSON
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      priority: json['priority'],
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      estimatedMinutes: json['estimatedMinutes'],
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    );
  }
}
