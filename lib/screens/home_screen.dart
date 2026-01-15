import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import 'task_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
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
            onPressed: () {},
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
          body: RefreshIndicator(
            onRefresh: () async {
              await taskProvider.refresh();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeSection(),
                  const SizedBox(height: 20),
                  _buildStatsSection(taskProvider),
                  const SizedBox(height: 20),
                  _buildTodayTasksSection(taskProvider),
                  const SizedBox(height: 20),
                ],
              ),
            ),
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

  Widget _buildWelcomeSection() {
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
          Text(
            'Hello, User! 👋',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Let\'s make today productive!',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          _buildCurrentTime(),
        ],
      ),
    );
  }

  Widget _buildCurrentTime() {
    final now = DateTime.now();
    final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            timeString,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(TaskProvider taskProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Completed',
              taskProvider.completedCount.toString(),
              Icons.check_circle,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Pending',
              taskProvider.pendingCount.toString(),
              Icons.pending_actions,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Overdue',
              taskProvider.overdueCount.toString(),
              Icons.warning,
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
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
    return Column(
      children: taskProvider.todayTasks.map((task) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
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
            subtitle: task.description != null
                ? Text(
                    task.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (task.isOverdue)
                  const Icon(Icons.warning, color: Colors.red, size: 20),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () {
                    taskProvider.deleteTask(task.id);
                  },
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
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
