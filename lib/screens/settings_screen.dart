import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settings = SettingsService();

  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  int _reminderMinutes = 5;
  String _defaultDuration = '30';
  bool _autoStartTimer = false;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final n = await _settings.getNotificationsEnabled();
    final s = await _settings.getSoundEnabled();
    final v = await _settings.getVibrationEnabled();
    final r = await _settings.getReminderMinutes();
    final d = await _settings.getDefaultDuration();
    final a = await _settings.getAutoStartTimer();
    final dm = await _settings.getDarkMode();

    setState(() {
      _notificationsEnabled = n;
      _soundEnabled = s;
      _vibrationEnabled = v;
      _reminderMinutes = r;
      _defaultDuration = d;
      _autoStartTimer = a;
      _darkMode = dm;
    });
  }

  void _saveBool(String key, bool value) async {
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
      case 'darkmode':
        await _settings.setDarkMode(value);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(title: const Text('Notifications')),
          SwitchListTile(
            title: const Text('Enable notifications'),
            value: _notificationsEnabled,
            onChanged: (v) {
              setState(() => _notificationsEnabled = v);
              _saveBool('notifications', v);
            },
          ),
          SwitchListTile(
            title: const Text('Sound'),
            value: _soundEnabled,
            onChanged: _notificationsEnabled
                ? (v) {
                    setState(() => _soundEnabled = v);
                    _saveBool('sound', v);
                  }
                : null,
          ),
          SwitchListTile(
            title: const Text('Vibration'),
            value: _vibrationEnabled,
            onChanged: _notificationsEnabled
                ? (v) {
                    setState(() => _vibrationEnabled = v);
                    _saveBool('vibration', v);
                  }
                : null,
          ),
          ListTile(
            title: const Text('Reminder Time'),
            subtitle: Text('$_reminderMinutes minutes before'),
            onTap: () => _showReminderPicker(),
          ),
          const Divider(),
          ListTile(title: const Text('Task Defaults')),
          ListTile(
            title: const Text('Default duration'),
            subtitle: Text('$_defaultDuration minutes'),
            onTap: () => _showDurationPicker(),
          ),
          SwitchListTile(
            title: const Text('Auto-start timer'),
            value: _autoStartTimer,
            onChanged: (v) {
              setState(() => _autoStartTimer = v);
              _saveBool('autostart', v);
            },
          ),
          const Divider(),
          ListTile(title: const Text('Appearance')),
          SwitchListTile(
            title: const Text('Dark mode'),
            value: _darkMode,
            onChanged: (v) {
              setState(() => _darkMode = v);
              _saveBool('darkmode', v);
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Clear local cache'),
            onTap: () => _confirmClear(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showReminderPicker() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reminder time'),
        content: Wrap(
          spacing: 8,
          children: [5, 10, 15, 30, 60].map((m) {
            return ChoiceChip(
              label: Text('$m min'),
              selected: _reminderMinutes == m,
              onSelected: (sel) {
                if (sel) {
                  setState(() => _reminderMinutes = m);
                  _settings.setReminderMinutes(m);
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
      builder: (_) => AlertDialog(
        title: const Text('Default task duration'),
        content: Wrap(
          spacing: 8,
          children: ['15', '30', '45', '60', '90', '120'].map((d) {
            return ChoiceChip(
              label: Text('$d min'),
              selected: _defaultDuration == d,
              onSelected: (sel) {
                if (sel) {
                  setState(() => _defaultDuration = d);
                  _settings.setDefaultDuration(d);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _confirmClear() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear cache'),
        content: const Text('This will remove temporary local data.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              await _load();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cleared local data')),
                );
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
