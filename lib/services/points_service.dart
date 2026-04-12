import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PointsService {
  static const _kTotalPoints = 'points_total_v2';
  static const _kTotalPointsLegacy = 'points_total';
  static const _kTasksCompleted = 'points_tasks_completed';
  static const _kLastAward = 'points_last_award_v2';
  static const _kLastAwardLegacy = 'points_last_award';
  static const _kDailyPoints = 'points_daily_v1';

  Future<SharedPreferences> _prefs() async => SharedPreferences.getInstance();

  Future<double> loadTotalPoints() async {
    final prefs = await _prefs();
    final stored = prefs.getDouble(_kTotalPoints);
    if (stored != null) {
      return stored;
    }
    final legacy = prefs.getInt(_kTotalPointsLegacy);
    return legacy != null ? legacy.toDouble() : 0;
  }

  Future<void> saveTotalPoints(double total) async {
    final prefs = await _prefs();
    await prefs.setDouble(_kTotalPoints, total);
  }

  Future<int> loadCompletedTasks() async {
    final prefs = await _prefs();
    return prefs.getInt(_kTasksCompleted) ?? 0;
  }

  Future<void> incrementCompletedTasks() async {
    final prefs = await _prefs();
    final current = prefs.getInt(_kTasksCompleted) ?? 0;
    await prefs.setInt(_kTasksCompleted, current + 1);
  }

  Future<void> storeLastAward(double points) async {
    final prefs = await _prefs();
    await prefs.setDouble(_kLastAward, points);
  }

  Future<double> loadLastAward() async {
    final prefs = await _prefs();
    final stored = prefs.getDouble(_kLastAward);
    if (stored != null) {
      return stored;
    }
    final legacy = prefs.getInt(_kLastAwardLegacy);
    return legacy != null ? legacy.toDouble() : 0;
  }

  Future<Map<DateTime, double>> loadDailyPoints() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_kDailyPoints);
    if (raw == null || raw.isEmpty) {
      return {};
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (key, value) => MapEntry(
        _parseDateKey(key),
        (value as num).toDouble(),
      ),
    );
  }

  Future<void> saveDailyPoints(Map<DateTime, double> dailyPoints) async {
    final prefs = await _prefs();
    final encoded = jsonEncode(
      dailyPoints.map(
        (key, value) => MapEntry(_formatDateKey(key), value),
      ),
    );
    await prefs.setString(_kDailyPoints, encoded);
  }

  Future<void> saveSnapshot({
    required double totalPoints,
    required Map<DateTime, double> dailyPoints,
  }) async {
    final prefs = await _prefs();
    final batch = dailyPoints.map(
      (key, value) => MapEntry(_formatDateKey(key), value),
    );
    await prefs.setDouble(_kTotalPoints, totalPoints);
    await prefs.setString(_kDailyPoints, jsonEncode(batch));
  }

  DateTime _parseDateKey(String key) {
    final parsed = DateTime.tryParse(key);
    if (parsed == null) {
      return DateTime.now();
    }
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  String _formatDateKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.toIso8601String();
  }
}
