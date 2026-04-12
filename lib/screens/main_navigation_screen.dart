import 'dart:ui';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'analytics_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';
import 'task_form_screen.dart';
import '../services/notification_service.dart';
import '../providers/task_provider.dart';
import 'package:provider/provider.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const AnalyticsScreen(),
    const LeaderboardScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _requestNotificationPermissions();

    NotificationService.setNotificationTapCallback((taskId) {
      setState(() {
        _currentIndex = 0;
      });
    });
  }

  Future<void> _requestNotificationPermissions() async {
    final hasPermission = await NotificationService.areNotificationsEnabled();
    if (!hasPermission) {
      await NotificationService.requestPermissions();
    }
  }

  void _showAddTaskForm() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) =>
                TaskFormScreen(taskProvider: context.read<TaskProvider>()),
          ),
        )
        .then((value) {
          if (!mounted) return;
          if (value == true) {
            context.read<TaskProvider>().refresh();
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 75,
          margin: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B).withValues(alpha: 0.8)
                      : Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(0, Icons.home_rounded, Icons.home_outlined),
                    _buildNavItem(
                      1,
                      Icons.analytics_rounded,
                      Icons.analytics_outlined,
                    ),
                    _buildCenterAddButton(),
                    _buildNavItem(
                      2,
                      Icons.leaderboard_rounded,
                      Icons.leaderboard_outlined,
                    ),
                    _buildNavItem(
                      3,
                      Icons.person_rounded,
                      Icons.person_outlined,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterAddButton() {
    return GestureDetector(
      onTap: _showAddTaskForm,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData selectedIcon,
    IconData unselectedIcon,
  ) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? const Color(0xFF4F46E5).withValues(alpha: 0.2)
                    : const Color(0xFF4F46E5).withValues(alpha: 0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          isSelected ? selectedIcon : unselectedIcon,
          color: isSelected
              ? const Color(0xFF4F46E5)
              : (isDark ? Colors.white70 : Colors.black45),
          size: 26,
        ),
      ),
    );
  }
}
