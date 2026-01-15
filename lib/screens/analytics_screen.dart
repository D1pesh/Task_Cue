import 'package:flutter/material.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Analytics & Stats\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }
}
