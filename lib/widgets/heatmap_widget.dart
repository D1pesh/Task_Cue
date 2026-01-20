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
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    
    // Calculate padding (0=Sunday, 1=Monday, etc.)
    final startWeekday = firstDayOfMonth.weekday % 7;
    final totalCells = startWeekday + daysInMonth;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Month name
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            _getMonthName(now.month),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // Weekday headers
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((day) => SizedBox(
                      width: 32,
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        
        // Calendar grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 3,
            crossAxisSpacing: 3,
            childAspectRatio: 1.0,
          ),
          itemCount: totalCells,
          itemBuilder: (context, index) {
            // Empty cells before month starts
            if (index < startWeekday) {
              return const SizedBox();
            }
            
            final dayNumber = index - startWeekday + 1;
            final date = DateTime(now.year, now.month, dayNumber);
            final dateKey = DateTime(date.year, date.month, date.day);
            final points = dailyPoints[dateKey] ?? 0.0;
            final isSelected = selectedDate != null &&
                selectedDate!.year == date.year &&
                selectedDate!.month == date.month &&
                selectedDate!.day == date.day;
            final isToday = date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;
            final isFuture = date.isAfter(now);
            
            return GestureDetector(
              onTap: isFuture ? null : () => onDateTap?.call(date),
              child: Container(
                decoration: BoxDecoration(
                  color: isFuture ? Colors.grey.shade100 : _getColorForPoints(points),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected
                        ? Colors.blue
                        : isToday
                            ? Colors.blue.withValues(alpha: 0.5)
                            : Colors.transparent,
                    width: isSelected ? 2 : isToday ? 1.5 : 0,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$dayNumber',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                      color: isFuture
                          ? Colors.grey.shade400
                          : points > 100
                              ? Colors.white
                              : Colors.grey.shade800,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  
  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
