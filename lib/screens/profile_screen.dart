import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Profile & Settings\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }
}
