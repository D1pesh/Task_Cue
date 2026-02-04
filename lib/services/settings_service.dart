import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _kNotificationsEnabled = 'notifications_enabled';
  static const _kSoundEnabled = 'sound_enabled';
  static const _kVibrationEnabled = 'vibration_enabled';
  static const _kReminderMinutes = 'reminder_minutes';
  static const _kDefaultDuration = 'default_duration';
  static const _kAutoStartTimer = 'auto_start_timer';
  static const _kDarkMode = 'dark_mode';

  Future<SharedPreferences> _prefs() async => await SharedPreferences.getInstance();

  Future<bool> getNotificationsEnabled() async {
    final p = await _prefs();
    return p.getBool(_kNotificationsEnabled) ?? true;
  }

  Future<void> setNotificationsEnabled(bool v) async {
    final p = await _prefs();
    await p.setBool(_kNotificationsEnabled, v);
  }

  Future<bool> getSoundEnabled() async {
    final p = await _prefs();
    return p.getBool(_kSoundEnabled) ?? true;
  }

  Future<void> setSoundEnabled(bool v) async {
    final p = await _prefs();
    await p.setBool(_kSoundEnabled, v);
  }

  Future<bool> getVibrationEnabled() async {
    final p = await _prefs();
    return p.getBool(_kVibrationEnabled) ?? true;
  }

  Future<void> setVibrationEnabled(bool v) async {
    final p = await _prefs();
    await p.setBool(_kVibrationEnabled, v);
  }

  Future<int> getReminderMinutes() async {
    final p = await _prefs();
    return p.getInt(_kReminderMinutes) ?? 5;
  }

  Future<void> setReminderMinutes(int v) async {
    final p = await _prefs();
    await p.setInt(_kReminderMinutes, v);
  }

  Future<String> getDefaultDuration() async {
    final p = await _prefs();
    return p.getString(_kDefaultDuration) ?? '30';
  }

  Future<void> setDefaultDuration(String v) async {
    final p = await _prefs();
    await p.setString(_kDefaultDuration, v);
  }

  Future<bool> getAutoStartTimer() async {
    final p = await _prefs();
    return p.getBool(_kAutoStartTimer) ?? false;
  }

  Future<void> setAutoStartTimer(bool v) async {
    final p = await _prefs();
    await p.setBool(_kAutoStartTimer, v);
  }

  Future<bool> getDarkMode() async {
    final p = await _prefs();
    return p.getBool(_kDarkMode) ?? false;
  }

  Future<void> setDarkMode(bool v) async {
    final p = await _prefs();
    await p.setBool(_kDarkMode, v);
  }
}
