import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardEntry {
  final String uid;
  final String displayName;
  final double totalPoints;
  final DateTime updatedAt;

  LeaderboardEntry({
    required this.uid,
    required this.displayName,
    required this.totalPoints,
    required this.updatedAt,
  });

  factory LeaderboardEntry.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return LeaderboardEntry(
      uid: doc.id,
      displayName: (data['displayName'] as String?) ?? 'User',
      totalPoints: (data['totalPoints'] as num?)?.toDouble() ?? 0.0,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class LeaderboardService {
  final _col = FirebaseFirestore.instance.collection('leaderboard');

  Future<void> updateUserPoints({
    required String uid,
    required String displayName,
    required double totalPoints,
  }) async {
    await _col.doc(uid).set({
      'displayName': displayName,
      'totalPoints': totalPoints,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<LeaderboardEntry>> topUsersStream({int limit = 50}) {
    return _col
        .orderBy('totalPoints', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => LeaderboardEntry.fromSnapshot(d)).toList());
  }
}
