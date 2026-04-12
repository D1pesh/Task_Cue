import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import 'home_screen.dart'; // For showXPRewardDialog

class TasksListScreen extends StatefulWidget {
  const TasksListScreen({super.key});

  @override
  State<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends State<TasksListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).loadTasks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgColor = isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFFF8FAFC);
        final topBarColor = isDark ? const Color(0xFF1E293B) : Colors.white;
        final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

        final filteredTasks = taskProvider.tasks.where((task) {
          if (_searchQuery.isNotEmpty &&
              !task.title.toLowerCase().contains(_searchQuery.toLowerCase())) {
            return false;
          }
          return true;
        }).toList();

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            title: const Text(
              'All Tasks',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
            ),
            backgroundColor: topBarColor,
            foregroundColor: textColor,
            elevation: 0,
          ),
          body: Column(
            children: [
              // Search Bar
              Container(
                    color: topBarColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'Search tasks...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.normal,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF9CA3AF),
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear_rounded,
                                  color: Color(0xFF9CA3AF),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFF3F4F6),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                    ),
                  )
                  .animate()
                  .slideY(begin: -0.2, end: 0, curve: Curves.easeOutCubic)
                  .fadeIn(),

              // AI Reschedule Toggle
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: topBarColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(
                        (255 * (isDark ? 0.3 : 0.05)).toInt(),
                      ),
                      blurRadius: 4,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text(
                        'Default Plan',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      selected: !taskProvider.showAISorted,
                      selectedColor: isDark
                          ? const Color(0xFF312E81)
                          : const Color(0xFFE0E7FF),
                      labelStyle: TextStyle(
                        color: !taskProvider.showAISorted
                            ? (isDark
                                  ? const Color(0xFFA5B4FC)
                                  : const Color(0xFF4338CA))
                            : Colors.grey.shade500,
                      ),
                      backgroundColor: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFF3F4F6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide.none,
                      ),
                      onSelected: (val) {
                        if (val) taskProvider.toggleAISorting(false);
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 16,
                            color: isDark
                                ? const Color(0xFFD8B4FE)
                                : const Color(0xFF9333EA),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'AI Smart Order',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      selected: taskProvider.showAISorted,
                      labelStyle: TextStyle(
                        color: taskProvider.showAISorted
                            ? (isDark
                                  ? const Color(0xFFD8B4FE)
                                  : const Color(0xFF7E22CE))
                            : Colors.grey.shade500,
                      ),
                      selectedColor: isDark
                          ? const Color(0xFF4C1D95)
                          : const Color(0xFFF3E8FF),
                      backgroundColor: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFF3F4F6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide.none,
                      ),
                      onSelected: (val) {
                        if (val) taskProvider.toggleAISorting(true);
                      },
                      avatar:
                          taskProvider.isLoading && taskProvider.showAISorted
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDark
                                    ? const Color(0xFFD8B4FE)
                                    : const Color(0xFF9333EA),
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 8),

              // Task List
              Expanded(
                child: filteredTasks.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 20,
                          top: 16,
                          bottom: 180,
                        ), // Bottom padding for floating nav and FAB
                        itemCount: filteredTasks.length,
                        itemBuilder: (context, index) {
                          final task = filteredTasks[index];
                          return Dismissible(
                            key: Key(task.id),
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              child: const Icon(
                                Icons.delete_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) async {
                              await taskProvider.deleteTask(task.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '"${task.title}" deleted',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    backgroundColor: const Color(0xFF1F2937),
                                  ),
                                );
                              }
                              return true;
                            },
                            child: _buildTaskCard(task, taskProvider)
                                .animate(key: ValueKey(task.id))
                                .fadeIn(
                                  delay: Duration(
                                    milliseconds: 50 * index.clamp(0, 10),
                                  ),
                                )
                                .slideX(
                                  begin: 0.1,
                                  end: 0,
                                  curve: Curves.easeOutCubic,
                                ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskCard(task, TaskProvider taskProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final completedBg = isDark
        ? const Color(0xFF064E3B).withValues(alpha: 0.2)
        : const Color(0xFFF0FDF4);
    final borderColor = task.isCompleted
        ? (isDark ? const Color(0xFF059669) : const Color(0xFFBBF7D0))
        : Colors.transparent;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: task.isCompleted ? completedBg : cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: task.isCompleted
              ? borderColor
              : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.02)),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                leading: Transform.scale(
                  scale: 1.1,
                  child: Checkbox(
                    value: task.isCompleted,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    activeColor: const Color(0xFF22C55E),
                    side: BorderSide(color: Colors.grey.shade300, width: 2),
                    onChanged: (value) async {
                      if (value == true) {
                        final rewardData = await taskProvider.completeTask(
                          task.id,
                        );
                        if (!mounted) return;
                        if (rewardData != null) {
                          showXPRewardDialog(context, rewardData);
                        }
                      }
                    },
                  ),
                ),
                title: Text(
                  task.title,
                  style: TextStyle(
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: task.isCompleted
                        ? Colors.grey.shade500
                        : (isDark ? Colors.white : const Color(0xFF1F2937)),
                  ),
                ),
                subtitle: task.category.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            task.category,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                  : const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              size: 64,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty ? 'No tasks found' : 'No tasks yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different search'
                : 'Add a task from the home screen',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    ).animate().scale(curve: Curves.easeOutBack, duration: 500.ms).fadeIn();
  }
}
