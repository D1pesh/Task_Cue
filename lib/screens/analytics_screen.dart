import 'package:flutter/material.dart';
import '../widgets/heatmap_widget.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  Map<DateTime, double> _getMockData() {
    final now = DateTime.now();
    final data = <DateTime, double>{};
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    
    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(now.year, now.month, i);
      if (!date.isAfter(now)) {
        data[date] = 30.0 + (i % 6) * 35.0;
      }
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activity Heatmap',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            HeatmapWidget(dailyPoints: _getMockData()),
          ],
        ),
      ),
    );
  }
}
