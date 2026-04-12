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
  Color _getColorForPoints(double points, bool isDark) {
    if (points == 0) return isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    
    // Professional Scale (Teal to Indigo) tuned for XP accumulation
    if (points < 20) return const Color(0xFFF1F5F9);
    if (points < 50) return const Color(0xFFCCFBF1); 
    if (points < 100) return const Color(0xFF99F6E4);
    if (points < 200) return const Color(0xFF5EEAD4);
    if (points < 350) return const Color(0xFF2DD4BF);
    if (points < 500) return const Color(0xFF0D9488);
    return const Color(0xFF0F766E); // Darkest teal for > 500 XP
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    
    // Calculate padding (0=Sunday, 1=Monday, etc.)
    final startWeekday = firstDayOfMonth.weekday % 7;
    final totalCells = startWeekday + daysInMonth;

    // Pre-calculate all dates for the grid to avoid heavy logic in itemBuilder
    final List<Map<String, dynamic>> gridData = List.generate(totalCells, (index) {
      if (index < startWeekday) return {'isEmpty': true};
      
      final int dayNumber = (index - startWeekday + 1).toInt();
      final date = DateTime(now.year, now.month, dayNumber);
      final dateKey = DateTime(date.year, date.month, date.day);
      
      return {
        'isEmpty': false,
        'dayNumber': dayNumber,
        'date': date,
        'points': dailyPoints[dateKey] ?? 0.0,
        'isToday': date.year == now.year && date.month == now.month && date.day == now.day,
        'isFuture': date.isAfter(now),
        'isSelected': selectedDate != null &&
            selectedDate!.year == date.year &&
            selectedDate!.month == date.month &&
            selectedDate!.day == date.day,
      };
    });
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Month name
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            '${_getMonthName(now.month)} ${now.year}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
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
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.0,
          ),
          itemCount: totalCells,
          itemBuilder: (context, index) {
            final data = gridData[index];
            if (data['isEmpty'] == true) {
              return const SizedBox();
            }
            
            final dayNumber = data['dayNumber'] as int;
            final date = data['date'] as DateTime;
            final points = data['points'] as double;
            final isSelected = data['isSelected'] as bool;
            final isToday = data['isToday'] as bool;
            final isFuture = data['isFuture'] as bool;
            
            return GestureDetector(
              onTap: isFuture ? null : () => onDateTap?.call(date),
              child: Container(
                decoration: BoxDecoration(
                  color: isFuture 
                      ? (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC))
                      : _getColorForPoints(points, isDark),
                  borderRadius: BorderRadius.circular(6),
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
                          ? (isDark ? Colors.grey.shade600 : Colors.grey.shade400)
                          : points >= 200
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.grey.shade800),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 12),
        
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '0 XP',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 8),
            ...List.generate(5, (index) {
              // Create scale increments roughly matching (0, 50, 150, 300, 500)
              final xpScalePoints = [0.0, 60.0, 150.0, 300.0, 600.0];
              final samplePoints = xpScalePoints[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _getColorForPoints(samplePoints, isDark),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                      width: 0.5,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(width: 8),
            Text(
              '500+ XP',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
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