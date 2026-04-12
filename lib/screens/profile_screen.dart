import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../providers/task_provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../widgets/prestige_display_widget.dart';
import '../widgets/rank_card_widget.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = FirebaseAuth.instance.currentUser;

    final displayName = _resolveDisplayName(user);
    final email = user?.email ?? 'No email linked';
    final initial = displayName.isNotEmpty
        ? displayName.substring(0, 1).toUpperCase()
        : (email.isNotEmpty ? email.substring(0, 1).toUpperCase() : 'U');
    final memberSince = _formatMemberSince(user);

    final totalTasks = taskProvider.tasks.length;
    final completedTasks = _countCompletedTasks(taskProvider);
    final pendingTasks = totalTasks - completedTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _openSettings(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: 120,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(
                context: context,
                initial: initial,
                name: displayName,
                email: email,
                memberSince: memberSince,
              ),
              const SizedBox(height: 24),
              // Gamification Section
              if (user != null) ...[
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final userData =
                        snapshot.data?.data() as Map<String, dynamic>?;
                    final stats =
                        userData?['gamification'] as Map<String, dynamic>? ??
                        {};

                    final currentRank = stats['currentRank'] ?? 'Aether';
                    final currentXP = stats['currentMonthXP'] ?? 0;
                    final totalTasksCompleted =
                        stats['totalTasksCompleted'] ?? 0;
                    final currentStreak = stats['currentStreak'] ?? 0;
                    final prestigeRanks = Map<String, int>.from(
                      stats['prestigeRanks'] ?? {},
                    );

                    return Column(
                      children: [
                        RankCardWidget(
                          currentRank: currentRank,
                          currentXP: currentXP,
                          totalTasksCompleted: totalTasksCompleted,
                          currentStreak: currentStreak,
                        ),
                        const SizedBox(height: 16),
                        if (prestigeRanks.isNotEmpty)
                          PrestigeDisplayWidget(prestigeRanks: prestigeRanks),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
              _buildCompletionCard(context, taskProvider),
              const SizedBox(height: 24),
              _buildTaskStatsRow(
                context,
                totalTasks,
                completedTasks,
                pendingTasks,
              ),
              const SizedBox(height: 32),
              _buildPreferencesSection(context, themeProvider),
              const SizedBox(height: 16),
              _buildAccountSection(context),
            ],
          ),
        ),
      ),
    );
  }

  int _countCompletedTasks(TaskProvider taskProvider) {
    return taskProvider.tasks.where((task) => task.isCompleted == true).length;
  }

  Widget _buildProfileHeader({
    required BuildContext context,
    required String initial,
    required String name,
    required String email,
    required String memberSince,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  child: Text(
                    initial,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              memberSince.toUpperCase(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionCard(BuildContext context, TaskProvider taskProvider) {
    final theme = Theme.of(context);
    final total = taskProvider.tasks.length;
    final completed = _countCompletedTasks(taskProvider);
    final percentage = total > 0 ? (completed / total) : 0.0;

    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: percentage,
                    strokeWidth: 10,
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: 0.1,
                    ),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  '${(percentage * 100).toInt()}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MASTERY',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completed / $total',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Tasks Finished',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskStatsRow(
    BuildContext context,
    int totalTasks,
    int completedTasks,
    int pendingTasks,
  ) {
    final theme = Theme.of(context);
    final stats = [
      _StatMetric(
        label: 'Total Tasks',
        value: totalTasks,
        icon: Icons.list_alt_outlined,
      ),
      _StatMetric(
        label: 'Completed',
        value: completedTasks,
        icon: Icons.check_circle_outline,
      ),
      _StatMetric(
        label: 'Pending',
        value: pendingTasks,
        icon: Icons.pending_actions_outlined,
      ),
    ];

    return Row(
      children: stats
          .map(
            (stat) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: stat == stats.last ? 0 : 12),
                child: _buildStatTile(stat, theme),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildStatTile(_StatMetric stat, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(stat.icon, size: 22, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 12),
          Text(
            stat.value.toString(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            stat.label.toUpperCase(),
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    final theme = Theme.of(context);
    final mode = themeProvider.themeMode;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(
        (255 * (theme.brightness == Brightness.dark ? 0.35 : 0.9)).toInt(),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.color_lens_outlined,
              color: theme.colorScheme.primary,
            ),
            title: const Text('Theme'),
            subtitle: Text(_describeThemeMode(mode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemePicker(context, themeProvider),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.settings_applications_outlined,
              color: theme.colorScheme.primary,
            ),
            title: const Text('App Settings'),
            subtitle: const Text('Notifications, defaults, appearance'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openSettings(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(
        (255 * (theme.brightness == Brightness.dark ? 0.35 : 0.9)).toInt(),
      ),
      child: ListTile(
        leading: Icon(Icons.logout_outlined, color: theme.colorScheme.error),
        title: Text(
          'Sign Out',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: const Text('Sign out of your TaskCue account'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _confirmSignOut(context),
      ),
    );
  }

  Future<void> _showThemePicker(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withAlpha((255 * 0.2).toInt()),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Choose Theme',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...ThemeMode.values.map((mode) {
                return ListTile(
                  leading: Icon(_themeModeIcon(mode)),
                  title: Text(_describeThemeMode(mode)),
                  trailing: themeProvider.themeMode == mode
                      ? const Icon(Icons.check_circle, color: Colors.blue)
                      : null,
                  onTap: () {
                    themeProvider.setThemeMode(mode);
                    Navigator.of(context).pop();
                  },
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  IconData _themeModeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
      case ThemeMode.system:
        return Icons.brightness_auto_outlined;
    }
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final auth = context.read<AuthService>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await auth.signOut();
        if (navigator.mounted) {
          navigator.popUntil((route) => route.isFirst);
        }
      } catch (e) {
        if (messenger.mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Failed to sign out. Please try again.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _openSettings(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  String _resolveDisplayName(User? user) {
    final displayName = user?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }
    final email = user?.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    return 'User';
  }

  String _formatMemberSince(User? user) {
    final created = user?.metadata.creationTime;
    if (created == null) {
      return 'Member since —';
    }

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final label = '${months[created.month - 1]} ${created.year}';
    return 'Member since $label';
  }

  String _describeThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System default';
    }
  }
}

class _StatMetric {
  final String label;
  final int value;
  final IconData icon;

  _StatMetric({required this.label, required this.value, required this.icon});
}
