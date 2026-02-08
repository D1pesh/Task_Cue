import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/task_provider.dart';
import '../providers/timer_provider.dart';
import '../widgets/floating_stopwatch.dart';
import 'task_form_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _timerTicker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).loadTasks();
      
      // Set up timer provider callbacks
      final timerProvider = Provider.of<TimerProvider>(context, listen: false);
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      
      // Set callback to complete tasks when timer stops
      timerProvider.setTaskCompleteCallback((taskId) {
        taskProvider.completeTask(taskId);
      });
    });
    
    // Start timer ticker for updating elapsed time
    _timerTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      final timerProvider = Provider.of<TimerProvider>(context, listen: false);
      if (timerProvider.isRunning) {
        timerProvider.updateElapsedTime();
      }
    });
  }

  @override
  void dispose() {
    _timerTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TaskProvider, TimerProvider>(
      builder: (context, taskProvider, timerProvider, child) {
        return Scaffold(
          appBar: AppBar(
        title: const Text('TaskCue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events),
            tooltip: 'Badges',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.blue.shade300,
                child: const Text(
                  'U',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
          body: Stack(
            children: [
              // Main content with refresh indicator
              RefreshIndicator(
                onRefresh: () async {
                  await taskProvider.refresh();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeSection(taskProvider),
                      const SizedBox(height: 20),
                      _buildTodayTasksSection(taskProvider),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              
              // Floating Timer
              if (timerProvider.hasActiveTimer)
                DraggableFloatingTimer(
                  child: FloatingStopwatch(
                    taskTitle: timerProvider.activeTask!.title,
                    isPaused: timerProvider.isPaused,
                    elapsedSeconds: timerProvider.elapsedSeconds,
                    onPause: () => timerProvider.pauseTimer(),
                    onResume: () => timerProvider.resumeTimer(),
                    onStop: () => timerProvider.stopTimer(),
                  ),
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => TaskFormScreen(taskProvider: taskProvider),
                ),
              );
              if (result == true) {
                taskProvider.refresh();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Task'),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection(TaskProvider taskProvider) {
    final todayTasks = taskProvider.todayTasks;
    final completedToday = todayTasks.where((task) => task.isCompleted).length;
    final pendingToday = todayTasks.length - completedToday;
    final completionRate = todayTasks.isNotEmpty ? completedToday / todayTasks.length : 0.0;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF3B82F6),
            Color(0xFF2563EB),
            Color(0xFF1D4ED8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row with greeting and time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side - Greeting
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getInteractiveGreeting(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'User! 👋',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Right side - Time
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(DateTime.now().hour > 12 ? DateTime.now().hour - 12 : (DateTime.now().hour == 0 ? 12 : DateTime.now().hour)).toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateTime.now().hour >= 12 ? 'PM' : 'AM',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_getDayName(DateTime.now().weekday)}, ${_getMonthName(DateTime.now().month)} ${DateTime.now().day}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Today's Task Summary
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.today, color: Colors.white, size: 20),
                      const SizedBox(height: 6),
                      Text(
                        todayTasks.length.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 20),
                      const SizedBox(height: 6),
                      Text(
                        completedToday.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Completed',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pending_actions, color: Colors.white, size: 20),
                      const SizedBox(height: 6),
                      Text(
                        pendingToday.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pending',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Progress Bar
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Today\'s Progress',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${(completionRate * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: completionRate,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInteractiveGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning!';
    } else if (hour < 17) {
      return 'Good afternoon!';
    } else {
      return 'Good evening!';
    }
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildTodayTasksSection(TaskProvider taskProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today\'s Tasks',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('View all tasks coming soon!')),
                  );
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          taskProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : taskProvider.todayTasks.isEmpty
                  ? _buildEmptyState()
                  : _buildTaskList(taskProvider),
        ],
      ),
    );
  }

  Widget _buildTaskList(TaskProvider taskProvider) {
    // Separate and sort tasks
    final activeTasks = taskProvider.todayTasks.where((t) => !t.isCompleted).toList();
    final completedTasks = taskProvider.todayTasks.where((t) => t.isCompleted).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Active Tasks Section
        if (activeTasks.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Active (${activeTasks.length})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          ...activeTasks.map((task) => _buildTaskCard(task, taskProvider, false)),
        ],
        
        // Completed Tasks Section
        if (completedTasks.isNotEmpty) ...[
          if (activeTasks.isNotEmpty) const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Completed (${completedTasks.length})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          ...completedTasks.map((task) => _buildTaskCard(task, taskProvider, true)),
        ],
      ],
    );
  }

  Widget _buildTaskCard(task, TaskProvider taskProvider, bool isCompleted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isCompleted ? Colors.green.shade200 : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (value) {
            if (value == true) {
              taskProvider.completeTask(task.id);
            }
          },
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null)
              Text(
                task.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                // Scheduled time
                if (task.scheduledDateTime != null)
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.schedule, size: 14, color: Colors.green.shade600),
                        const SizedBox(width: 4),
                        Text(
                          _formatTaskTime(task.scheduledDateTime!),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Deadline
                if (task.deadline != null)
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.flag, size: 14, color: task.isOverdue ? Colors.red : Colors.orange.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${task.isOverdue ? "Overdue" : "Due"} ${_formatTaskTime(task.deadline!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: task.isOverdue ? Colors.red : Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: Consumer<TimerProvider>(
          builder: (context, timerProvider, child) {
            final isActiveTimer = timerProvider.activeTask?.id == task.id;
            
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (task.isOverdue)
                  const Icon(Icons.warning, color: Colors.red, size: 20),
                
                // Timer Button (only for active tasks)
                if (!isCompleted)
                  IconButton(
                    icon: Icon(
                      isActiveTimer 
                          ? (timerProvider.isPaused ? Icons.play_arrow : Icons.pause)
                          : Icons.play_circle_outline,
                      size: 20,
                      color: isActiveTimer ? Colors.green : Colors.blue,
                    ),
                    tooltip: isActiveTimer
                        ? (timerProvider.isPaused ? 'Resume Timer' : 'Pause Timer')
                        : 'Start Timer',
                    onPressed: () {
                      if (isActiveTimer) {
                        timerProvider.toggleTimer();
                      } else {
                        // Stop any existing timer and start new one
                        if (timerProvider.hasActiveTimer) {
                          timerProvider.stopTimer(markComplete: false);
                        }
                        timerProvider.startTimer(task);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Timer started for "${task.title}"'),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => TaskFormScreen(
                          taskProvider: taskProvider,
                          initialTask: task,
                        ),
                      ),
                    );
                    if (result == true) {
                      taskProvider.refresh();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () {
                    _showDeleteConfirmation(context, taskProvider, task);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, TaskProvider taskProvider, task) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              taskProvider.deleteTask(task.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('"${task.title}" deleted')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  String _formatTaskTime(DateTime dateTime) {
    final now = DateTime.now();
    final taskDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));
    
    String timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    
    if (taskDate == today) {
      return 'Today $timeStr';
    } else if (taskDate == tomorrow) {
      return 'Tomorrow $timeStr';
    } else if (taskDate == yesterday) {
      return 'Yesterday $timeStr';
    } else {
      final difference = taskDate.difference(today).inDays;
      if (difference > 0) {
        return 'In ${difference}d $timeStr';
      } else {
        return '${difference.abs()}d ago $timeStr';
      }
    }
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.task_alt,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first task',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
