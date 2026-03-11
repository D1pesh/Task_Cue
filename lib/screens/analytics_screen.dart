import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/task_provider.dart';

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

    final totalTasks = taskProvider.tasks.length;
    final completedTasks = taskProvider.completedCount;
    final completionRate = totalTasks > 0
        ? (completedTasks / totalTasks * 100).toInt()
        : 0;

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
          ],
        ),
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
            '${segment.category} • ${segment.value.toInt()} (${percent}%)',
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
