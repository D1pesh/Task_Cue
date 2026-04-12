import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/timer_provider.dart';
import '../widgets/floating_stopwatch.dart';
import '../widgets/xp_reward_animation.dart';
// import 'profile_screen.dart';
import 'badges_screen.dart';
import 'settings_screen.dart';
import 'task_form_screen.dart';
import 'tasks_list_screen.dart';
import '../widgets/achievement_dialog.dart';

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
      timerProvider.setTaskCompleteCallback((taskId) async {
        final rewardData = await taskProvider.completeTask(taskId);
        if (rewardData != null && mounted) {
          showXPRewardDialog(context, rewardData);
        }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F4F6);
    final topBarColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);

    final userDisplayName = _getUserDisplayName();
    final trimmedName = userDisplayName.trim();
    final userInitial = trimmedName.isNotEmpty
        ? trimmedName.substring(0, 1).toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'TaskCue',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        backgroundColor: topBarColor,
        foregroundColor: textColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events),
            tooltip: 'Badges',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BadgesScreen()),
              );
            },
          ).animate().scale(
            delay: 200.ms,
            duration: 400.ms,
            curve: Curves.easeOutBack,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ).animate().scale(
            delay: 300.ms,
            duration: 400.ms,
            curve: Curves.easeOutBack,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child:
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF3B82F6),
                  child: Text(
                    userInitial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ).animate().scale(
                  delay: 400.ms,
                  duration: 400.ms,
                  curve: Curves.easeOutBack,
                ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content with refresh indicator
          RefreshIndicator(
            color: const Color(0xFF3B82F6),
            onRefresh: () async {
              await context.read<TaskProvider>().refresh();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeSection(userDisplayName),
                  const SizedBox(height: 24),
                  const _TodayTasksSection(),
                  const SizedBox(
                    height: 180,
                  ), // Padding for floating navigation bar and FAB
                ],
              ),
            ),
          ),

          // Floating Timer - Only this part rebuilds every second
          Consumer<TimerProvider>(
            builder: (context, timerProvider, child) {
              if (!timerProvider.hasActiveTimer) return const SizedBox.shrink();

              return DraggableFloatingTimer(
                child:
                    FloatingStopwatch(
                          taskTitle: timerProvider.activeTask!.title,
                          isPaused: timerProvider.isPaused,
                          elapsedSeconds: timerProvider.elapsedSeconds,
                          currentXP: timerProvider.currentTaskXP,
                          pauseCount: timerProvider.pauseCount,
                          snoozeCount: timerProvider.snoozeCount,
                          onPause: () => timerProvider.pauseTimer(),
                          onResume: () => timerProvider.resumeTimer(),
                          onStop: () {
                            timerProvider.stopTimer();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Task completed!',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          onSnooze: (minutes) =>
                              timerProvider.snoozeTask(minutes),
                        )
                        .animate()
                        .slideY(
                          begin: 1.0,
                          end: 0.0,
                          curve: Curves.easeOutCubic,
                        )
                        .fadeIn(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(String userDisplayName) {
    return Selector<TaskProvider, double>(
      selector: (context, provider) {
        final todayTasks = provider.todayTasks;
        if (todayTasks.isEmpty) return 0.0;
        final completed = todayTasks.where((t) => t.isCompleted).length;
        return completed / todayTasks.length;
      },
      builder: (context, completionRate, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(36),
              bottomRight: Radius.circular(36),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withAlpha((255 * 0.4).toInt()),
                blurRadius: 24,
                offset: const Offset(0, 12),
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
                              'Welcome back to TaskCue',
                              style: TextStyle(
                                color: Colors.white.withAlpha(
                                  (255 * 0.85).toInt(),
                                ),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideX(begin: -0.2, end: 0),
                        const SizedBox(height: 6),
                        Text(
                              '${_getInteractiveGreeting()},\n$userDisplayName 👋',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                height: 1.2,
                                fontWeight: FontWeight.w800,
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 200.ms, duration: 400.ms)
                            .slideX(begin: -0.2, end: 0),
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
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2.0),
                                child: Text(
                                  DateTime.now().hour >= 12 ? 'PM' : 'AM',
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(
                                      (255 * 0.9).toInt(),
                                    ),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(
                                (255 * 0.15).toInt(),
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_getDayName(DateTime.now().weekday)}, ${_getMonthName(DateTime.now().month)} ${DateTime.now().day}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 400.ms)
                      .slideX(begin: 0.2, end: 0),
                ],
              ),
              // Progress Bar
              const SizedBox(height: 28),
              Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((255 * 0.1).toInt()),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withAlpha((255 * 0.15).toInt()),
                      ),
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
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              '${(completionRate * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: completionRate,
                            minHeight: 8,
                            backgroundColor: Colors.white.withAlpha(
                              (255 * 0.2).toInt(),
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ).animate().scaleX(
                          begin: 0.0,
                          end: 1.0,
                          duration: 600.ms,
                          curve: Curves.easeOutCubic,
                          delay: 400.ms,
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 500.ms)
                  .slideY(begin: 0.2, end: 0),
            ],
          ),
        );
      },
    );
  }

  String _getUserDisplayName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return 'User';
    }

    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final email = user.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }

    return 'User';
  }

  void _openSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  String _getInteractiveGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

class _TodayTasksSection extends StatelessWidget {
  const _TodayTasksSection();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Today\'s Tasks',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TasksListScreen()),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF3B82F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'View All',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 500.ms),

          Consumer<TaskProvider>(
            builder: (context, taskProvider, child) {
              return AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text(
                              'Default Plan',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            selected: !taskProvider.showAISorted,
                            selectedColor: const Color(0xFFE0E7FF),
                            labelStyle: TextStyle(
                              color: !taskProvider.showAISorted
                                  ? const Color(0xFF4338CA)
                                  : Colors.grey.shade700,
                            ),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onSelected: (val) {
                              if (val) taskProvider.toggleAISorting(false);
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 16,
                                  color: Color(0xFF9333EA),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'AI Smart Order',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            selected: taskProvider.showAISorted,
                            labelStyle: TextStyle(
                              color: taskProvider.showAISorted
                                  ? const Color(0xFF7E22CE)
                                  : Colors.grey.shade700,
                            ),
                            selectedColor: const Color(0xFFF3E8FF),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onSelected: (val) {
                              if (val) taskProvider.toggleAISorting(true);
                            },
                            avatar:
                                taskProvider.isLoading &&
                                    taskProvider.showAISorted
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF9333EA),
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ).animate().fadeIn(delay: 550.ms),
                    ),
                    taskProvider.todayTasks.isEmpty
                        ? _buildEmptyState(context)
                        : _buildTaskList(context, taskProvider),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(
              (255 * (isDark ? 0.3 : 0.05)).toInt(),
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              size: 48,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'All caught up!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the + button to queue up some new tasks for today.',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().scale(curve: Curves.easeOutBack, duration: 500.ms).fadeIn();
  }

  Widget _buildTaskList(BuildContext context, TaskProvider taskProvider) {
    final activeTasks = taskProvider.todayTasks
        .where((t) => !t.isCompleted)
        .toList();
    final completedTasks = taskProvider.todayTasks
        .where((t) => t.isCompleted)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (activeTasks.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4),
            child: Text(
              'Active (${activeTasks.length})',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF4B5563),
              ),
            ),
          ).animate().fadeIn(),
          ...activeTasks.asMap().entries.map((entry) {
            return _buildTaskCard(context, entry.value, taskProvider, false)
                .animate(key: ValueKey(entry.value.id))
                .fadeIn(delay: Duration(milliseconds: 100 * entry.key))
                .slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
          }),
        ],
        if (completedTasks.isNotEmpty) ...[
          if (activeTasks.isNotEmpty) const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4),
            child: Text(
              'Completed (${completedTasks.length})',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF4B5563),
              ),
            ),
          ).animate().fadeIn(),
          ...completedTasks.asMap().entries.map((entry) {
            return _buildTaskCard(context, entry.value, taskProvider, true)
                .animate(key: ValueKey('${entry.value.id}_completed'))
                .fadeIn()
                .scaleXY(begin: 0.95, end: 1.0, curve: Curves.easeOut);
          }),
        ],
      ],
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    dynamic task,
    TaskProvider taskProvider,
    bool isCompleted,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final completedBg = isDark
        ? const Color(0xFF064E3B).withValues(alpha: 0.2)
        : const Color(0xFFF0FDF4);
    final borderColor = isCompleted
        ? (isDark ? const Color(0xFF059669) : const Color(0xFFBBF7D0))
        : Colors.transparent;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isCompleted ? completedBg : cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(
              (255 * (isDark ? 0.2 : 0.03)).toInt(),
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: borderColor),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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
                        if (!context.mounted) return;
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
                    decorationColor: Colors.grey.shade500,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: isCompleted
                        ? Colors.grey.shade500
                        : (isDark ? Colors.white : const Color(0xFF1F2937)),
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (task.description != null && !isCompleted) ...[
                      const SizedBox(height: 6),
                      Text(
                        task.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (task.scheduledDateTime != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.schedule,
                                  size: 14,
                                  color: Color(0xFF4B5563),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  formatTaskTime(task.scheduledDateTime!),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF4B5563),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (task.deadline != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: task.isOverdue
                                  ? const Color(0xFFFEF2F2)
                                  : const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.flag_rounded,
                                  size: 14,
                                  color: task.isOverdue
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${task.isOverdue ? "Overdue" : "Due"} ${formatTaskTime(task.deadline!)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: task.isOverdue
                                        ? const Color(0xFFB91C1C)
                                        : const Color(0xFFB45309),
                                    fontWeight: FontWeight.w700,
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
                    final isActiveTimer =
                        timerProvider.activeTask?.id == task.id;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isCompleted)
                          IconButton(
                            icon: Icon(
                              isActiveTimer
                                  ? (timerProvider.isPaused
                                        ? Icons.play_arrow_rounded
                                        : Icons.pause_rounded)
                                  : Icons.play_circle_fill_rounded,
                              size: 28,
                              color: isActiveTimer
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF3B82F6),
                            ),
                            onPressed: () {
                              if (isActiveTimer) {
                                timerProvider.toggleTimer();
                              } else {
                                if (timerProvider.hasActiveTimer) {
                                  timerProvider.stopTimer(markComplete: false);
                                }
                                timerProvider.startTimer(task);
                              }
                            },
                          ),
                        PopupMenuButton(
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            color: Color(0xFF9CA3AF),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              onTap: () async {
                                // Defer execution to allow popup to close
                                Future.delayed(
                                  const Duration(milliseconds: 10),
                                  () async {
                                    if (!context.mounted) return;
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => TaskFormScreen(
                                          taskProvider: taskProvider,
                                          initialTask: task,
                                        ),
                                      ),
                                    );
                                    taskProvider.refresh();
                                  },
                                );
                              },
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.edit_rounded,
                                    size: 20,
                                    color: Color(0xFF3B82F6),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Edit Task'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              onTap: () {
                                Future.delayed(
                                  const Duration(milliseconds: 10),
                                  () {
                                    if (!context.mounted) return;
                                    _showDeleteConfirmation(
                                      context,
                                      taskProvider,
                                      task,
                                    );
                                  },
                                );
                              },
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.delete_rounded,
                                    size: 20,
                                    color: Color(0xFFEF4444),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: Color(0xFFEF4444)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    TaskProvider taskProvider,
    dynamic task,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Task',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${task.title}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              taskProvider.deleteTask(task.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

String formatTaskTime(DateTime dateTime) {
  final now = DateTime.now();
  final taskDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final yesterday = today.subtract(const Duration(days: 1));

  String timeStr =
      '${dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour)}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'PM' : 'AM'}';

  if (taskDate == today) return 'Today $timeStr';
  if (taskDate == tomorrow) return 'Tomorrow $timeStr';
  if (taskDate == yesterday) return 'Yesterday $timeStr';

  final difference = taskDate.difference(today).inDays;
  return difference > 0
      ? 'In ${difference}d $timeStr'
      : '${difference.abs()}d ago $timeStr';
}

void showXPRewardDialog(BuildContext context, Map<String, dynamic> rewardData) {
  final achievements = (rewardData['newAchievements'] as List?)
      ?.map((a) => Map<String, String>.from(a as Map))
      .toList();

  if (achievements != null && achievements.isNotEmpty) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AchievementCongratulationsDialog(
        achievements: achievements,
        onContinue: () {
          Navigator.pop(context);
          _showBaseXPReward(context, rewardData);
        },
      ),
    );
  } else {
    _showBaseXPReward(context, rewardData);
  }
}

void _showBaseXPReward(BuildContext context, Map<String, dynamic> rewardData) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => XPRewardAnimation(
      xpEarned: rewardData['xpEarned'] ?? 0,
      bonuses: List<String>.from(rewardData['bonuses'] ?? []),
      rankedUp: rewardData['rankedUp'] as bool? ?? false,
      newRank: rewardData['newRank'] as String?,
      newAchievements: [],
    ),
  );
}
