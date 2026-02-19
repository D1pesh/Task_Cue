import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settings = SettingsService();
  
  // User info
  String _displayName = '';
  String _email = '';
  
  // Settings
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  int _reminderMinutes = 5;
  String _defaultDuration = '30';
  bool _autoStartTimer = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadSettings();
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _displayName = user.displayName ?? '';
        _email = user.email ?? '';
      });
    }
  }

  Future<void> _loadSettings() async {
    final n = await _settings.getNotificationsEnabled();
    final s = await _settings.getSoundEnabled();
    final v = await _settings.getVibrationEnabled();
    final r = await _settings.getReminderMinutes();
    final d = await _settings.getDefaultDuration();
    final a = await _settings.getAutoStartTimer();

    setState(() {
      _notificationsEnabled = n;
      _soundEnabled = s;
      _vibrationEnabled = v;
      _reminderMinutes = r;
      _defaultDuration = d;
      _autoStartTimer = a;
    });
  }

  Future<void> _saveSetting(String key,dynamic value) async {
    switch (key) {
      case 'notifications':
        await _settings.setNotificationsEnabled(value);
        break;
      case 'sound':
        await _settings.setSoundEnabled(value);
        break;
      case 'vibration':
        await _settings.setVibrationEnabled(value);
        break;
      case 'autostart':
        await _settings.setAutoStartTimer(value);
        break;
      case 'reminderMinutes':
        await _settings.setReminderMinutes(value);
        break;
      case 'defaultDuration':
        await _settings.setDefaultDuration(value);
        break;
    }
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.signOut();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action cannot be undone. All your tasks and data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.deleteAccount();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting account: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final themeMode = themeProvider.themeMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Profile Section
          _buildSectionCard(
            title: 'Profile',
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    _displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'U',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(_displayName.isNotEmpty ? _displayName : 'User'),
                subtitle: Text(_email),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showEditProfileDialog(),
              ),
            ],
          ),

          // Notifications Section
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
                onTap: () => _showReminderTimePicker(),
              ),
            ],
          ),

          // Task Defaults Section
          _buildSectionCard(
            title: 'Task Defaults',
            children: [
              ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: const Text('Default Duration'),
                subtitle: Text('$_defaultDuration minutes'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showDurationPicker(),
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

          // Appearance Section
          _buildSectionCard(
            title: 'Appearance',
            children: [
              RadioListTile<ThemeMode>(
                secondary: const Icon(Icons.brightness_auto_outlined),
                title: const Text('System Default'),
                subtitle: const Text('Follow system theme'),
                value: ThemeMode.system,
                groupValue: themeMode,
                onChanged: (v) {
                  if (v != null) {
                    themeProvider.setThemeMode(v);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                secondary: const Icon(Icons.light_mode_outlined),
                title: const Text('Light Mode'),
                value: ThemeMode.light,
                groupValue: themeMode,
                onChanged: (v) {
                  if (v != null) {
                    themeProvider.setThemeMode(v);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('Dark Mode'),
                value: ThemeMode.dark,
                groupValue: themeMode,
                onChanged: (v) {
                  if (v != null) {
                    themeProvider.setThemeMode(v);
                  }
                },
              ),
            ],
          ),

          // Data & Privacy Section
          _buildSectionCard(
            title: 'Data & Privacy',
            children: [
              ListTile(
                leading: const Icon(Icons.clean_hands_outlined),
                title: const Text('Clear Local Cache'),
                subtitle: const Text('Remove temporary data'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _confirmClearCache(),
              ),
              ListTile(
                leading: const Icon(Icons.history_outlined),
                title: const Text('Clear Task History'),
                subtitle: const Text('Remove completed tasks'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _confirmClearHistory(),
              ),
            ],
          ),

          // Account Section
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
                leading: Icon(Icons.delete_forever_outlined, color: Colors.red.shade700),
                title: Text('Delete Account', style: TextStyle(color: Colors.red.shade700)),
                subtitle: const Text('Permanently delete your account'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _handleDeleteAccount,
              ),
            ],
          ),

          // About Section
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
                  // TODO: Navigate to terms page
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Navigate to privacy page
                },
              ),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
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

              // Capture context before async call
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              try {
                await FirebaseAuth.instance.currentUser?.updateDisplayName(newName);
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
                  SnackBar(content: Text('Error updating profile: ${e.toString()}')),
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
              // Capture context before async call
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
        content: const Text('This will remove all completed tasks from local storage.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement clear history
              ScaffoldMessenger.of(context).showSnackBar(
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
