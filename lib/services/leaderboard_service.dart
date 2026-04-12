import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

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

  factory LeaderboardEntry.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc, int rank) {
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
      isCurrentUser: data['isCurrentUser'] as bool? ?? false,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json, bool isCurrentUser) {
    return LeaderboardEntry(
      uid: json['userId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'User',
      totalPoints: json['totalPoints'] as int? ?? 0,
      lifetimePoints: json['lifetimePoints'] as int? ?? 0,
      weeklyPoints: json['weeklyPoints'] as int? ?? 0,
      monthlyPoints: json['monthlyPoints'] as int? ?? 0,
      currentLevel: json['currentLevel'] as int? ?? 1,
      rank: json['rank'] as int? ?? 0,
      medal: json['medal'] as String?,
      isCurrentUser: isCurrentUser,
      updatedAt: DateTime.now(),
    );
  }

  static String? _getMedalFromRank(int rank) {
    if (rank == 1) return 'gold';
    if (rank == 2) return 'silver';
    if (rank == 3) return 'bronze';
    return null;
  }
}

class LeaderboardService {
  final _firestore = FirebaseFirestore.instance;
  final _col = FirebaseFirestore.instance.collection('leaderboard');

  /// Fetch leaderboard from Django backend
  Future<List<LeaderboardEntry>> fetchLeaderboardFromBackend({
    String type = 'total',
    String authToken = '',
  }) async {
    try {
      final url = Uri.parse(ApiConfig.buildUrl(
        ApiConfig.leaderboardEndpoint,
        queryParams: {'type': type},
      ));
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        final leaderboardArray = jsonData['leaderboard'] as List<dynamic>? ?? [];
        final currentUserData = jsonData['currentUser'] as Map<String, dynamic>?;
        
        final entries = leaderboardArray.map<LeaderboardEntry>((entry) {
          return LeaderboardEntry.fromJson(
            entry as Map<String, dynamic>,
            (entry['isCurrentUser'] as bool?) ?? false,
          );
        }).toList();

        return entries;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login');
      } else {
        throw Exception('Failed to fetch leaderboard: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching leaderboard: $e');
    }
  }

  /// Update user points in Firestore (for real-time sync)
  Future<void> updateUserPoints({
    required String uid,
    required String displayName,
    required int totalPoints,
    required int currentLevel,
  }) async {
    try {
      await _col.doc(uid).set({
        'displayName': displayName,
        'totalPoints': totalPoints,
        'currentLevel': currentLevel,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error updating user points: $e');
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

  /// Get user's current leaderboard rank
  Future<int?> getUserRank({required String uid, String type = 'total'}) async {
    try {
      final String orderField;
      switch (type) {
        case 'weekly':
          orderField = 'weeklyPoints';
          break;
        case 'monthly':
          orderField = 'monthlyPoints';
          break;
        default:
          orderField = 'totalPoints';
      }

      final userDoc = await _col.doc(uid).get();
      if (!userDoc.exists) return null;

      final userData = userDoc.data() ?? {};
      final userPoints = userData[orderField] as num? ?? 0;

      final higherScoreCount = await _col
          .where(orderField, isGreaterThan: userPoints)
          .count()
          .get();

      return higherScoreCount.count + 1;
    } catch (e) {
      throw Exception('Error getting user rank: $e');
    }
  }

  /// Set the backend URL dynamically
  static void setBackendUrl(String url) {
    // This would require making _backendBaseUrl non-static if you want to change it
    // For now, update the constant or use dependency injection
  }
}

