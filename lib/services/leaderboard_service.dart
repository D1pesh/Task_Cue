import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeaderboardEntry {
  final String uid;
  final String displayName;
  final int totalPoints;
  final int lifetimePoints;
  final int weeklyPoints;
  final int monthlyPoints;
  final int currentLevel;
  final int rank;
  final String? medal; // 'gold', 'silver', 'bronze', 'none'
  final bool isCurrentUser;
  final DateTime updatedAt;

  LeaderboardEntry({
    required this.uid,
    required this.displayName,
    required this.totalPoints,
    required this.lifetimePoints,
    required this.weeklyPoints,
    required this.monthlyPoints,
    required this.currentLevel,
    required this.rank,
    this.medal,
    required this.isCurrentUser,
    required this.updatedAt,
  });

  factory LeaderboardEntry.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
    int rank, {
    String? currentUserId,
  }) {
    final data = doc.data() ?? {};
    return LeaderboardEntry(
      uid: doc.id,
      displayName: (data['displayName'] as String?) ?? 'User',
      totalPoints: (data['totalPoints'] as num?)?.toInt() ?? 0,
      lifetimePoints: (data['lifetimePoints'] as num?)?.toInt() ?? 0,
      weeklyPoints: (data['weeklyPoints'] as num?)?.toInt() ?? 0,
      monthlyPoints: (data['monthlyPoints'] as num?)?.toInt() ?? 0,
      currentLevel: (data['currentLevel'] as num?)?.toInt() ?? 1,
      rank: rank,
      medal: _getMedalFromRank(rank),
      isCurrentUser: currentUserId != null && doc.id == currentUserId,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static String? _getMedalFromRank(int rank) {
    if (rank == 1) return 'gold';
    if (rank == 2) return 'silver';
    if (rank == 3) return 'bronze';
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'totalPoints': totalPoints,
      'lifetimePoints': lifetimePoints,
      'weeklyPoints': weeklyPoints,
      'monthlyPoints': monthlyPoints,
      'currentLevel': currentLevel,
      'rank': rank,
      'medal': medal,
      'isCurrentUser': isCurrentUser,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    return LeaderboardEntry(
      uid: json['uid'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'User',
      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
      lifetimePoints: (json['lifetimePoints'] as num?)?.toInt() ?? 0,
      weeklyPoints: (json['weeklyPoints'] as num?)?.toInt() ?? 0,
      monthlyPoints: (json['monthlyPoints'] as num?)?.toInt() ?? 0,
      currentLevel: (json['currentLevel'] as num?)?.toInt() ?? 1,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      medal: json['medal'] as String?,
      isCurrentUser: json['uid'] == currentUserId,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class LeaderboardService {
  final _col = FirebaseFirestore.instance.collection('leaderboard');
  static const String _cachePrefix = 'leaderboard_cache_';

  /// Fetch leaderboard from Firestore with offline cache fallback
  Future<List<LeaderboardEntry>> fetchTopUsers({
    String type = 'total',
    int limit = 50,
    String? currentUserId,
  }) async {
    final orderField = _getPointsField(type);

    try {
      final snapshot = await _col
          .orderBy(orderField, descending: true)
          .limit(limit)
          .get(const GetOptions(source: Source.serverAndCache));

      final entries = snapshot.docs
          .asMap()
          .entries
          .map((entry) => LeaderboardEntry.fromSnapshot(
                entry.value,
                entry.key + 1,
                currentUserId: currentUserId,
              ))
          .toList();

      await _saveCachedLeaderboard(type, entries);
      return entries;
    } catch (error) {
      debugPrint('Leaderboard fetch error: $error. Falling back to cache.');
      try {
        // Explicitly try cache if server fails
        final snapshot = await _col
            .orderBy(orderField, descending: true)
            .limit(limit)
            .get(const GetOptions(source: Source.cache));
        
        final entries = snapshot.docs
            .asMap()
            .entries
            .map((entry) => LeaderboardEntry.fromSnapshot(
                  entry.value,
                  entry.key + 1,
                  currentUserId: currentUserId,
                ))
            .toList();
        
        // Update SharedPreferences cache in the background
        _saveCachedLeaderboard(type, entries);
        return entries;
      } catch (cacheError) {
        // Fallback to SharedPreferences JSON cache if Firestore cache fails
        final cached = await _loadCachedLeaderboard(type, currentUserId: currentUserId);
        if (cached.isNotEmpty) {
          return cached;
        }
        rethrow;
      }
    }
  }

  /// Update user points in Firestore (for real-time sync)
  Future<void> updateUserPoints({
    required String uid,
    required String displayName,
    required int totalPoints,
    required int currentLevel,
    int? weeklyPoints,
    int? monthlyPoints,
  }) async {
    try {
      await _col.doc(uid).set({
        'displayName': displayName,
        'totalPoints': totalPoints,
        'currentLevel': currentLevel,
        'weeklyPoints': weeklyPoints ?? totalPoints,
        'monthlyPoints': monthlyPoints ?? totalPoints,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error updating user points: $e');
    }
  }

  /// Sync user stats from their primary profile to the leaderboard
  Future<void> syncUserStats(String uid) async {
    try {
      // Allow Firestore to handle the cache fallback natively
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists) return;

      final userData = userDoc.data() ?? {};
      final stats = userData['gamification'] as Map<String, dynamic>? ?? {};
      
      final displayName = userData['displayName'] as String? ?? 'User';
      final totalPoints = (stats['currentMonthXP'] as num?)?.toInt() ?? 0;
      // Level logic: every 1000 XP is a level, starting at level 1
      final currentLevel = (totalPoints / 1000).floor() + 1;

      // updateUserPoints uses .set() which Firestore automatically queues for offline
      await updateUserPoints(
        uid: uid,
        displayName: displayName,
        totalPoints: totalPoints,
        currentLevel: currentLevel,
        weeklyPoints: (stats['weeklyXP'] as num?)?.toInt() ?? totalPoints,
        monthlyPoints: totalPoints,
      );
    } catch (e) {
      debugPrint('Sync user stats failed: $e');
    }
  }

  /// Listen to top users stream from Firestore (real-time)
  Stream<List<LeaderboardEntry>> topUsersStream({int limit = 50}) {
    return _col
        .orderBy('totalPoints', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .asMap()
            .entries
            .map((entry) => LeaderboardEntry.fromSnapshot(entry.value, entry.key + 1))
            .toList());
  }

  String _getPointsField(String type) {
    switch (type) {
      case 'weekly':
        return 'weeklyPoints';
      case 'monthly':
        return 'monthlyPoints';
      default:
        return 'totalPoints';
    }
  }

  /// Get user's current leaderboard rank
  Future<int?> getUserRank({required String uid, String type = 'total'}) async {
    try {
      final orderField = _getPointsField(type);

      final userDoc = await _col.doc(uid).get();
      if (!userDoc.exists) return null;

      final userData = userDoc.data() ?? {};
      final userPoints = userData[orderField] as num? ?? 0;

      final higherScoreCount = await _col
          .where(orderField, isGreaterThan: userPoints)
          .count()
          .get();

      return (higherScoreCount.count ?? 0) + 1;
    } catch (e) {
      final cachedRank = await _getCachedUserRank(uid, type);
      if (cachedRank != null) {
        return cachedRank;
      }
      // If truly disconnected and no cache, return null instead of throwing Exception
      return null;
    }
  }

  Future<void> _saveCachedLeaderboard(String type, List<LeaderboardEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(entries.map((e) => e.toJson()).toList());
    await prefs.setString('$_cachePrefix$type', jsonString);
    await prefs.setString('$_cachePrefix${type}_timestamp', DateTime.now().toIso8601String());
  }

  Future<List<LeaderboardEntry>> _loadCachedLeaderboard(
    String type, {
    String? currentUserId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_cachePrefix$type');
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final data = json.decode(raw) as List<dynamic>;
    return data
        .map((item) => LeaderboardEntry.fromJson(
              item as Map<String, dynamic>,
              currentUserId: currentUserId,
            ))
        .toList();
  }

  Future<int?> _getCachedUserRank(String uid, String type) async {
    return null;
  }

  /// Seed mock users for demonstration
  Future<void> seedMockUsers() async {
    final mockUsers = [
      {
        'uid': 'mock_user_dipson',
        'displayName': 'Dipson',
        'totalPoints': 401,
        'currentLevel': 5,
      },
      {
        'uid': 'mock_user_prakashh',
        'displayName': 'PraKashh',
        'totalPoints': 335,
        'currentLevel': 4,
      },
      {
        'uid': 'mock_user_rajesh',
        'displayName': 'rajesh',
        'totalPoints': 226,
        'currentLevel': 3,
      },
      {
        'uid': 'mock_user_balkrishna',
        'displayName': 'Balkrishna',
        'totalPoints': 134,
        'currentLevel': 4,
      },
      {
        'uid': 'mock_user_sujan',
        'displayName': 'Sujan Khadka',
        'totalPoints': 50,
        'currentLevel': 3,
      },
      {
        'uid': 'mock_user_prabesh',
        'displayName': 'Prabesh',
        'totalPoints': 24,
        'currentLevel': 2,
      },
    ];

    await Future.wait(mockUsers.map((user) => updateUserPoints(
      uid: user['uid'] as String,
      displayName: user['displayName'] as String,
      totalPoints: user['totalPoints'] as int,
      currentLevel: user['currentLevel'] as int,
      weeklyPoints: (user['totalPoints'] as int) ~/ 2,
      monthlyPoints: user['totalPoints'] as int,
    )));
  }
}

