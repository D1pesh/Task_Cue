import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/task_provider.dart';
import '../providers/timer_provider.dart';
import '../widgets/heatmap_widget.dart';

const List<String> _taskCategories = [
  'Intellectual',
  'Physical Health',
  'Mental Wellbeing',
  'Social Growth',
  'Skill Development & Career',
  'Hobbies/Passion',
  'Financial',
];

const List<Color> _categoryPalette = [
  Colors.indigo,
  Colors.teal,
  Colors.green,
  Colors.deepOrange,
  Colors.pink,
  Colors.amber,
  Colors.blueGrey,
];

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final timerProvider = context.watch<TimerProvider>();

    final totalTasks = taskProvider.tasks.length;
    final completedTasks = taskProvider.completedCount;
    final completionRate = totalTasks > 0
        ? (completedTasks / totalTasks * 100).toInt()
        : 0;

    final dailyPoints = timerProvider.dailyPoints;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(const Duration(days: 6));

    double weekPoints = 0;
    int weekActiveDays = 0;
    double bestWeekDayPoints = 0;
    double bestOverallPoints = 0.0;
    DateTime? bestWeekDay;
    DateTime? bestOverallDay;

    dailyPoints.forEach((date, points) {
      if (points > bestOverallPoints) {
        bestOverallPoints = points;
        bestOverallDay = date;
      }
      if (!date.isBefore(weekStart) && !date.isAfter(today)) {
        weekPoints += points;
        if (points > 0) {
          weekActiveDays++;
          if (points > bestWeekDayPoints) {
            bestWeekDayPoints = points;
            bestWeekDay = date;
          }
        }
      }
    });

    final weekHours = weekPoints / 60;
    final averageWeekPerActiveDay = weekActiveDays > 0
        ? weekPoints / weekActiveDays
        : 0.0;
    final streak = _calculateStreak(dailyPoints, today);
    final totalPoints = timerProvider.totalPoints;
    final averageMinutesPerTask = completedTasks > 0
        ? totalPoints / completedTasks
        : 0.0;

    final completedByCategory = {
      for (var category in _taskCategories) category: 0,
    };
    for (final task in taskProvider.tasks) {
      if (!task.isCompleted) continue;
      final category = task.category;
      if (!completedByCategory.containsKey(category)) continue;
      completedByCategory[category] = completedByCategory[category]! + 1;
    }
    final double totalCategoryDone = completedByCategory.values
        .fold<int>(0, (sum, value) => sum + value)
        .toDouble();
    final pieSegments = <CategoryPieSegment>[];
    var paletteIndex = 0;
    for (final category in _taskCategories) {
      pieSegments.add(
        CategoryPieSegment(
          category: category,
          value: completedByCategory[category]!.toDouble(),
          color: _categoryPalette[paletteIndex % _categoryPalette.length],
        ),
      );
      paletteIndex++;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThisWeekCard(
              context,
              weekPoints: weekPoints,
              weekHours: weekHours,
              activeDays: weekActiveDays,
              averagePerActiveDay: averageWeekPerActiveDay,
              bestDay: bestWeekDay,
              bestDayPoints: bestWeekDayPoints,
            ),
            const SizedBox(height: 32),
            const Text(
              'Overview',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildOverviewStat(
                    'Total Points',
                    _formatPoints(totalPoints),
                    Icons.emoji_events,
                    Colors.amber,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildOverviewStat(
                    'Avg min/task',
                    _formatMinutes(averageMinutesPerTask),
                    Icons.timer_outlined,
                    Colors.teal,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildOverviewStat(
                    'Streak',
                    '${streak}d',
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildOverviewStat(
                    'Completion Rate',
                    '$completionRate%',
                    Icons.percent,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Activity Heatmap',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            HeatmapWidget(dailyPoints: dailyPoints),
            const SizedBox(height: 32),
            const Text(
              'Completed Tasks by Category',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Center(
              child: CategoryPieChart(
                segments: pieSegments,
                total: totalCategoryDone,
              ),
            ),
            const SizedBox(height: 12),
            _buildCategoryLegend(pieSegments, totalCategoryDone),
            const SizedBox(height: 32),
            const Text(
              'Productivity Insights',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInsightCard(
              context,
              icon: Icons.trending_up,
              title: 'Top Earning Day',
              value: bestOverallDay != null
                  ? _formatDayLabel(bestOverallDay!)
                  : 'No data yet',
              subtitle: bestOverallDay != null
                  ? '${_formatPoints(bestOverallPoints)} points earned'
                  : 'Start a focus session to see insights',
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _buildInsightCard(
              context,
              icon: Icons.access_time,
              title: 'Avg Minutes per Task',
              value: '${_formatMinutes(averageMinutesPerTask)} min',
              subtitle: completedTasks > 0
                  ? 'Across $completedTasks completed tasks'
                  : 'Complete a task to unlock this insight',
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildInsightCard(
              context,
              icon: Icons.calendar_today_outlined,
              title: 'Weekly Active Days',
              value: '$weekActiveDays days',
              subtitle: weekActiveDays > 0
                  ? 'Average ${_formatPoints(averageWeekPerActiveDay)} pts on active days'
                  : 'No activity recorded this week',
              color: Colors.purple,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildThisWeekCard(
    BuildContext context, {
    required double weekPoints,
    required double weekHours,
    required int activeDays,
    required double averagePerActiveDay,
    required DateTime? bestDay,
    required double bestDayPoints,
  }) {
    final bestDayLabel = bestDay != null
        ? '${_formatDayLabel(bestDay)} • ${_formatPoints(bestDayPoints)} pts'
        : 'No sessions yet';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'This Week',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.blue.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((255 * 0.15).toInt()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.rocket_launch, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Great progress this week!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildWeekStat('Points', _formatPoints(weekPoints)),
                  _buildWeekStat('Minutes', _formatMinutes(weekPoints)),
                  _buildWeekStat('Hours', _formatHours(weekHours)),
                  _buildWeekStat('Active Days', activeDays.toString()),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                activeDays > 0
                    ? 'Best day: $bestDayLabel • Avg ${_formatPoints(averagePerActiveDay)} pts per active day'
                    : 'No focus sessions recorded yet this week.',
                style: TextStyle(
                  color: Colors.white.withAlpha((255 * 0.9).toInt()),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha((255 * 0.1).toInt()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha((255 * 0.1).toInt()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha((255 * 0.3).toInt())),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeekStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((255 * 0.15).toInt()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha((255 * 0.2).toInt())),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withAlpha((255 * 0.9).toInt()),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryLegend(List<CategoryPieSegment> segments, double total) {
    if (total <= 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Complete tasks to unlock category insights.',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }
    final visibleSegments = segments
        .where((segment) => segment.value > 0)
        .toList();
    if (visibleSegments.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: visibleSegments
          .map((segment) => _buildCategoryLegendItem(segment, total))
          .toList(),
    );
  }

  Widget _buildCategoryLegendItem(CategoryPieSegment segment, double total) {
    final percent = total > 0
        ? (segment.value / total * 100).toStringAsFixed(1)
        : '0';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: segment.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${segment.category} • ${segment.value.toInt()} (${percent}%)',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  static int _calculateStreak(
    Map<DateTime, double> dailyPoints,
    DateTime today,
  ) {
    int streak = 0;
    DateTime cursor = today;
    while (true) {
      final points = dailyPoints[cursor] ?? 0;
      if (points <= 0) {
        break;
      }
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static String _formatPoints(double value) {
    if (value.isNaN || value.isInfinite) {
      return '0';
    }
    if (value.roundToDouble() == value) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(value >= 10 ? 1 : 2);
  }

  static String _formatMinutes(double value) {
    if (value.isNaN || value.isInfinite) {
      return '0';
    }
    return value.round().toString();
  }

  static String _formatHours(double hours) {
    if (hours.isNaN || hours.isInfinite) {
      return '0';
    }
    return hours >= 10 ? hours.toStringAsFixed(0) : hours.toStringAsFixed(1);
  }

  static String _formatDayLabel(DateTime date) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[(date.weekday - 1) % days.length];
  }
}

class CategoryPieSegment {
  final String category;
  final double value;
  final Color color;

  const CategoryPieSegment({
    required this.category,
    required this.value,
    required this.color,
  });
}

class CategoryPieChart extends StatelessWidget {
  final List<CategoryPieSegment> segments;
  final double total;

  const CategoryPieChart({
    super.key,
    required this.segments,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    if (total <= 0) {
      return Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Complete a task to populate the chart.',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return SizedBox(
      width: 220,
      height: 220,
      child: CustomPaint(
        painter: _PieChartPainter(segments, total),
        child: Center(
          child: Text(
            '${total.toInt()} done',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<CategoryPieSegment> segments;
  final double total;

  _PieChartPainter(this.segments, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    double startAngle = -math.pi / 2;

    for (final segment in segments) {
      if (segment.value <= 0) continue;
      final sweep = segment.value / total * math.pi * 2;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        true,
        paint,
      );
      startAngle += sweep;
    }

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter old) {
    return old.total != total || !listEquals(old.segments, segments);
  }
}
