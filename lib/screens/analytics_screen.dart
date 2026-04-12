import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/task_provider.dart';
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
  Color(0xFF4F46E5), // Indigo
  Color(0xFF10B981), // Emerald
  Color(0xFF06B6D4), // Cyan
  Color(0xFF8B5CF6), // Violet
  Color(0xFFF59E0B), // Amber
  Color(0xFF6366F1), // Indigo-Light
  Color(0xFF94A3B8), // Slate
];

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();

    final totalTasks = taskProvider.tasks.length;
    final completedTasks = taskProvider.completedCount;
    final completionRate = totalTasks > 0
        ? (completedTasks / totalTasks * 100).toInt()
        : 0;

    final completedByCategory = taskProvider.completedByCategory;
    final double totalCategoryDone = completedByCategory.values
        .fold<int>(0, (sum, value) => sum + value)
        .toDouble();

    final pieSegments = <CategoryPieSegment>[];
    var paletteIndex = 0;
    for (final category in _taskCategories) {
      pieSegments.add(
        CategoryPieSegment(
          category: category,
          value: (completedByCategory[category] ?? 0).toDouble(),
          color: _categoryPalette[paletteIndex % _categoryPalette.length],
        ),
      );
      paletteIndex++;
    }

    final dailyPoints = taskProvider.dailyPoints;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overview',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildOverviewStat(
                    'Total Tasks',
                    '$totalTasks',
                    Icons.task_alt,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildOverviewStat(
                    'Completed',
                    '$completedTasks',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildOverviewStat(
                    'Completion',
                    '$completionRate%',
                    Icons.percent,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Monthly Completion Heatmap',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            HeatmapWidget(
              dailyPoints: dailyPoints,
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 24),
            const Text(
              'Pro Tips for You',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildProductivityTipsCarousel(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProductivityTipsCarousel(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tips = [
      {
        'title': 'The 2-Minute Rule',
        'desc': 'If a task takes less than 2 minutes, do it immediately to avoid mental clutter.',
        'icon': Icons.bolt_rounded,
        'color': const Color(0xFFF59E0B),
      },
      {
        'title': 'Eat the Frog',
        'desc': 'Handle your most complex or daunting task first thing in the morning when focus is highest.',
        'icon': Icons.restaurant_rounded,
        'color': const Color(0xFFEF4444),
      },
      {
        'title': 'Pomodoro Flow',
        'desc': 'Work for 25 mins, then take 5. Repeat 4 times then take a long break to avoid burnout.',
        'icon': Icons.timer_rounded,
        'color': const Color(0xFF10B981),
      },
      {
        'title': 'Category Harmony',
        'desc': 'A balanced segment distribution indicates a well-rounded lifestyle. Aim for no "zero" slices today!',
        'icon': Icons.pie_chart_rounded,
        'color': const Color(0xFF6366F1),
      },
      {
        'title': 'The 80/20 Slice',
        'desc': 'Notice which 20% of categories contribute to 80% of your growth. Double down on what works.',
        'icon': Icons.analytics_rounded,
        'color': const Color(0xFF06B6D4),
      },
      {
        'title': 'Micro-Consistency',
        'desc': 'Small slivers in a new category like "Mental Wellbeing" are the seeds of powerful future habits.',
        'icon': Icons.trending_up_rounded,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'title': 'Gap Analysis',
        'desc': 'Large gaps between categories might indicate burnout in one area. Take a break and re-balance.',
        'icon': Icons.space_dashboard_rounded,
        'color': const Color(0xFF4F46E5),
      },
      {
        'title': 'Color Recognition',
        'desc': 'Use consistent colors for categories to build faster mental recognition in your analytics.',
        'icon': Icons.palette_rounded,
        'color': const Color(0xFF94A3B8),
      },
    ];

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tips.length,
        itemBuilder: (context, index) {
          final tip = tips[index];
          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: (tip['color'] as Color).withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (tip['color'] as Color).withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (tip['color'] as Color).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(tip['icon'] as IconData, color: tip['color'] as Color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        tip['title'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tip['desc'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black54,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
            '${segment.category} • ${segment.value.toInt()} ($percent%)',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
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
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Complete a task to populate the chart.',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ),
      );
    }

    return SizedBox(
      width: 240,
      height: 240,
      child: CustomPaint(
        painter: _PieChartPainter(segments, total, Theme.of(context).colorScheme.surface),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${total.toInt()}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              Text(
                'TASKS DONE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<CategoryPieSegment> segments;
  final double total;
  final Color backgroundColor;

  _PieChartPainter(this.segments, this.total, this.backgroundColor);

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
        ..style = PaintingStyle.stroke
        ..strokeWidth = 32
        ..strokeCap = StrokeCap.butt;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 16),
        startAngle,
        sweep,
        false,
        paint,
      );
      startAngle += sweep;
    }

    // Border around the donut
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius, borderPaint);
    canvas.drawCircle(center, radius - 32, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter old) {
    return old.total != total || !listEquals(old.segments, segments);
  }
}
