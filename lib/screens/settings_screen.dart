import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';

const String _superAdminEmail = 'superadmin@taskcue.com';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settings = SettingsService();

  String _displayName = '';
  String _email = '';

  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  int _reminderMinutes = 5;
  String _defaultDuration = '30';
  bool _autoStartTimer = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadSettings();
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && mounted) {
      setState(() {
        _displayName = user.displayName ?? 'User';
        _email = user.email ?? 'No email';
      });
    }
  }

  Future<void> _loadSettings() async {
    try {
      final values = await Future.wait<Object?>([
        _settings.getNotificationsEnabled(),
        _settings.getSoundEnabled(),
        _settings.getVibrationEnabled(),
        _settings.getReminderMinutes(),
        _settings.getDefaultDuration(),
        _settings.getAutoStartTimer(),
      ]);

      if (!mounted) return;

      setState(() {
        _notificationsEnabled = values[0] as bool;
        _soundEnabled = values[1] as bool;
        _vibrationEnabled = values[2] as bool;
        _reminderMinutes = values[3] as int;
        _defaultDuration = values[4] as String;
        _autoStartTimer = values[5] as bool;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      switch (key) {
        case 'notifications':
          await _settings.setNotificationsEnabled(value as bool);
          break;
        case 'sound':
          await _settings.setSoundEnabled(value as bool);
          break;
        case 'vibration':
          await _settings.setVibrationEnabled(value as bool);
          break;
        case 'autostart':
          await _settings.setAutoStartTimer(value as bool);
          break;
        case 'reminderMinutes':
          await _settings.setReminderMinutes(value as int);
          break;
        case 'defaultDuration':
          await _settings.setDefaultDuration(value as String);
          break;
      }
    } catch (e) {
      debugPrint('Error saving setting "$key": $e');
      _showErrorSnackBar('Unable to save setting.');
    }
  }

  Future<void> _handleSignOut() async {
    final confirmed = await _showConfirmationDialog(
      title: 'Sign Out',
      content: 'Are you sure you want to sign out?',
    );

    if (confirmed == true && mounted) {
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.signOut();
      } catch (e) {
        _showErrorSnackBar('Error signing out: ${e.toString()}');
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await _showConfirmationDialog(
      title: 'Delete Account',
      content:
          'This action cannot be undone. All your tasks and data will be permanently deleted.',
    );

    if (confirmed == true && mounted) {
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.deleteAccount();

        if (mounted) {
          _showSuccessSnackBar('Account deleted successfully');
        }
      } catch (e) {
        _showErrorSnackBar('Error deleting account: ${e.toString()}');
      }
    }
  }

  Future<bool?> _showConfirmationDialog({
    required String title,
    required String content,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _clearTaskHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('task_history');
    await prefs.remove('completed_tasks');
    await prefs.remove('history_items');
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final themeMode = themeProvider.themeMode;
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentEmail = currentUser?.email?.toLowerCase();
    final isSuperAdminEmail = currentEmail == _superAdminEmail.toLowerCase();
    final adminDashboardStream = currentUser != null
        ? FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .snapshots()
        : Stream<DocumentSnapshot<Map<String, dynamic>>>.empty();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildSectionCard(
                  title: 'Profile',
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        child: Text(
                          _displayName.isNotEmpty
                              ? _displayName[0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title:
                          Text(_displayName.isNotEmpty ? _displayName : 'User'),
                      subtitle: Text(_email),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _showEditProfileDialog,
                    ),
                  ],
                ),
                _buildSectionCard(
                  title: 'Notifications',
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_outlined),
                      title: const Text('Enable Notifications'),
                      subtitle: const Text('Get reminders for your tasks'),
                      value: _notificationsEnabled,
                      onChanged: (v) {
                        setState(() => _notificationsEnabled = v);
                        _saveSetting('notifications', v);
                      },
                    ),
                    SwitchListTile(
                      secondary: const Icon(Icons.volume_up_outlined),
                      title: const Text('Sound'),
                      subtitle: const Text('Play sound for notifications'),
                      value: _soundEnabled,
                      onChanged: _notificationsEnabled
                          ? (v) {
                              setState(() => _soundEnabled = v);
                              _saveSetting('sound', v);
                            }
                          : null,
                    ),
                    SwitchListTile(
                      secondary: const Icon(Icons.vibration_outlined),
                      title: const Text('Vibration'),
                      subtitle: const Text('Vibrate for notifications'),
                      value: _vibrationEnabled,
                      onChanged: _notificationsEnabled
                          ? (v) {
                              setState(() => _vibrationEnabled = v);
                              _saveSetting('vibration', v);
                            }
                          : null,
                    ),
                    ListTile(
                      leading: const Icon(Icons.alarm_outlined),
                      title: const Text('Reminder Time'),
                      subtitle: Text('Remind $_reminderMinutes minutes before'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _showReminderTimePicker,
                    ),
                  ],
                ),
                _buildSectionCard(
                  title: 'Task Defaults',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.timer_outlined),
                      title: const Text('Default Duration'),
                      subtitle: Text('$_defaultDuration minutes'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _showDurationPicker,
                    ),
                    SwitchListTile(
                      secondary: const Icon(Icons.play_circle_outline),
                      title: const Text('Auto-start Timer'),
                      subtitle: const Text('Start timer when task begins'),
                      value: _autoStartTimer,
                      onChanged: (v) {
                        setState(() => _autoStartTimer = v);
                        _saveSetting('autostart', v);
                      },
                    ),
                  ],
                ),
                _buildSectionCard(
                  title: 'Appearance',
                  children: [
                    _buildThemeOption(
                      mode: ThemeMode.system,
                      icon: Icons.brightness_auto_outlined,
                      title: 'System Default',
                      subtitle: 'Follow system theme',
                      selected: themeMode == ThemeMode.system,
                      onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                    ),
                    _buildThemeOption(
                      mode: ThemeMode.light,
                      icon: Icons.light_mode_outlined,
                      title: 'Light Mode',
                      subtitle: 'Use light theme',
                      selected: themeMode == ThemeMode.light,
                      onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                    ),
                    _buildThemeOption(
                      mode: ThemeMode.dark,
                      icon: Icons.dark_mode_outlined,
                      title: 'Dark Mode',
                      subtitle: 'Use dark theme',
                      selected: themeMode == ThemeMode.dark,
                      onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                    ),
                  ],
                ),
                _buildSectionCard(
                  title: 'Data & Privacy',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.clean_hands_outlined),
                      title: const Text('Clear Local Cache'),
                      subtitle: const Text('Remove temporary data'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _confirmClearCache,
                    ),
                    ListTile(
                      leading: const Icon(Icons.history_outlined),
                      title: const Text('Clear Task History'),
                      subtitle:
                          const Text('Remove completed tasks and local history'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _confirmClearHistory,
                    ),
                  ],
                ),
                _buildSectionCard(
                  title: 'Account',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.logout_outlined),
                      title: const Text('Sign Out'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _handleSignOut,
                    ),
                    ListTile(
                      leading:
                          Icon(Icons.delete_forever_outlined, color: Colors.red),
                      title: Text(
                        'Delete Account',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                      subtitle: const Text('Permanently delete your account'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _handleDeleteAccount,
                    ),
                    if (isSuperAdminEmail)
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: adminDashboardStream,
                        builder: (context, snapshot) {
                          final role = snapshot.data?.data()?['role']
                                  ?.toString()
                                  .toLowerCase() ??
                              '';
                          final hasDashboardRole =
                              role == 'admin' || role == 'superadmin';
                          if (hasDashboardRole) {
                            return ListTile(
                              leading: const Icon(Icons.admin_panel_settings,
                                  color: Colors.red),
                              title: const Text(
                                'Admin Dashboard',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: const Text('Manage users and settings'),
                              trailing: const Icon(Icons.chevron_right,
                                  color: Colors.red),
                              onTap: () {
                                
                              },
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                  ],
                ),
                _buildSectionCard(
                  title: 'About',
                  children: [
                    const ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('Version'),
                      subtitle: Text('1.0.0'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: const Text('Terms & Conditions'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pushNamed(context, '/terms');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: const Text('Privacy Policy'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pushNamed(context, '/privacy');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildThemeOption({
    required ThemeMode mode,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: selected
          ? const Icon(Icons.check_circle, color: Colors.blue)
          : const SizedBox.shrink(),
      onTap: onTap,
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _displayName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isEmpty) return;

              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              try {
                await FirebaseAuth.instance.currentUser?.updateDisplayName(
                  newName,
                );
                if (!mounted) return;
                setState(() => _displayName = newName);
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully')),
                );
              } catch (e) {
                if (!mounted) return;
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Error updating profile: ${e.toString()}'),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showReminderTimePicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reminder Time'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [5, 10, 15, 30, 60].map((m) {
            return ChoiceChip(
              label: Text('$m min'),
              selected: _reminderMinutes == m,
              onSelected: (sel) {
                if (sel) {
                  setState(() => _reminderMinutes = m);
                  _saveSetting('reminderMinutes', m);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showDurationPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default Task Duration'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['15', '30', '45', '60', '90', '120'].map((d) {
            return ChoiceChip(
              label: Text('$d min'),
              selected: _defaultDuration == d,
              onSelected: (sel) {
                if (sel) {
                  setState(() => _defaultDuration = d);
                  _saveSetting('defaultDuration', d);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _confirmClearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will remove temporary local data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              navigator.pop();
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
              await _loadSettings();
              messenger.showSnackBar(
                const SnackBar(content: Text('Cache cleared successfully')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
            'This will remove all completed tasks from local storage.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              navigator.pop();
              await _clearTaskHistory();
              if (!mounted) return;
              messenger.showSnackBar(
                const SnackBar(content: Text('History cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}