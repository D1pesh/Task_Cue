import 'package:flutter/material.dart';

/// A heatmap widget to visualize daily task completion points
class HeatmapWidget extends StatelessWidget {
  final Map<DateTime, double> dailyPoints;
  final DateTime? selectedDate;
  final Function(DateTime)? onDateTap;
  
  const HeatmapWidget({
    super.key,
    required this.dailyPoints,
    this.selectedDate,
    this.onDateTap,
  });
  
  /// Get color intensity based on points earned
  Color _getColorForPoints(double points) {
    if (points == 0) return Colors.grey.shade200;
    if (points < 30) return const Color(0xFFDCFCE7); // Very light green
    if (points < 60) return const Color(0xFFA7F3D0); // Light green
    if (points < 100) return const Color(0xFF6EE7B7); // Medium green
    if (points < 150) return const Color(0xFF34D399); // Green
    if (points < 200) return const Color(0xFF10B981); // Dark green
    return const Color(0xFF059669); // Darkest green
  }
  
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Show last 35 days (5 weeks)
    final startDate = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 34));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Grid of days
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1.0,
          ),
          itemCount: 35,
          itemBuilder: (context, index) {
            final date = startDate.add(Duration(days: index));
            final dateKey = DateTime(date.year, date.month, date.day);
            final points = dailyPoints[dateKey] ?? 0.0;
            
            return Container(
              decoration: BoxDecoration(
                color: _getColorForPoints(points),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          },
        ),
      ],
    );
  }
}
